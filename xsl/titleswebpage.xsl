<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:marc="http://www.loc.gov/MARC21/slim"
    xmlns:oai="http://www.openarchives.org/OAI/2.0/"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tre="http://www.paregorios.org"
    xmlns:saxon="http://saxon.sf.net/"
    xmlns="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="xs tre oai marc saxon"
    version="2.0">
    
    <!-- 
    titleswebpage.xsl
    
    This stylesheet takes as input an XML file presumed to contain a MARCXML collection of records describing
    new books accessioned during a particular period (such as that produced by titles2marc.xsl). It produces
    an HTML, suitable for insertion as page content on the ISAW website and including summary information and
    stub links to Zotero etc.
    -->
    <!-- recognized levels: "warning", "info", "debug" -->
    <xsl:param name="loglevel">warning</xsl:param>
    <xsl:output method="xhtml" indent="yes" name="webpage"/>
    
    <xsl:param name="startdate">2014-02-01</xsl:param>
    <xsl:param name="enddate">2014-02-28</xsl:param>
    <xsl:param name="zotliblink"/>
    <xsl:variable name="starting-date" select="xs:date($startdate)"/>
    <xsl:variable name="ending-date" select="xs:date($enddate)"/>
    
    <xsl:variable name="marc-authors">100</xsl:variable>
    <xsl:variable name="marc-edition">250</xsl:variable>
    <xsl:variable name="marc-title">245</xsl:variable>
    <xsl:variable name="marc-series">490</xsl:variable>
    <xsl:variable name="marc-imprint">260</xsl:variable>
    <xsl:variable name="marc-production">264</xsl:variable>
    <xsl:variable name="marc-holdings">AVA</xsl:variable>
    <xsl:variable name="marc-origin">500</xsl:variable>
    <xsl:variable name="marc-persname">700</xsl:variable>
    <xsl:variable name="marc-scn">035</xsl:variable>
    <xsl:variable name="marc-parallel">880</xsl:variable>
    
    
    <xsl:param name="destdir">../result/</xsl:param>
    <xsl:variable name="fnslug">
        <xsl:text>newtitles-</xsl:text>
        <xsl:value-of select="$startdate"/>
        <xsl:text>-</xsl:text>
        <xsl:value-of select="$enddate"/>
        <xsl:text>-</xsl:text>
    </xsl:variable>

    <xsl:variable name="dateformat" as="xs:string">
        <xsl:text>[MNn] [D], [Y]</xsl:text>
    </xsl:variable>
    
    <xsl:variable name="n">
        <xsl:text>
</xsl:text>
    </xsl:variable>
    
    <xsl:variable name="internal-punct" as="node()">
        <span dir="ltr">. </span>
    </xsl:variable>
    
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="marc:collection">
        <xsl:call-template name="webpage"/>
    </xsl:template>
    
    <xsl:template match="marc:record">
        <p class="citation">
            <xsl:attribute name="id">seq<xsl:value-of select="count(preceding-sibling::marc:record)+1"/></xsl:attribute>
            <!-- 
                <xsl:apply-templates select="marc:datafield[@tag=$marc-title]"/>
                -->
            <xsl:call-template name="do-title"/>
            <!-- 
            <xsl:if test="not(marc:datafield[@tag=$marc-title]/marc:subfield[@code='c'])">
                <xsl:apply-templates select="marc:datafield[@tag=$marc-authors] | marc:datafield[@tag='700']"/>
            </xsl:if>
            -->
            <xsl:apply-templates select="marc:datafield[@tag=$marc-edition]"/>
            <xsl:apply-templates select="marc:datafield[@tag=$marc-series]"/>
            <xsl:apply-templates select="marc:datafield[@tag=$marc-imprint or (@tag=$marc-production and @ind2!='4')]"/>
            <xsl:apply-templates select="marc:datafield[@tag=$marc-holdings]"/>
            <xsl:apply-templates select="marc:datafield[@tag=$marc-origin]"/>
            <!-- <xsl:apply-templates select="marc:datafield[@tag=$marc-scn]"/> -->
        </p>
    </xsl:template>    
    
    <!-- authors etc. -->
    
    <xsl:template match="marc:datafield[@tag=$marc-authors or @tag=$marc-persname]">
        
        <xsl:variable name="this" select="tre:strippunct(tre:normalize-punctuation(marc:subfield[@code='a']))"/>
        <xsl:if test="$loglevel='debug'">
            <xsl:message>marc:datafield tag=<xsl:value-of select="@tag"/> "<xsl:value-of select="$this"/>"</xsl:message>
        </xsl:if>
        <xsl:variable name="creatortype">
            <xsl:choose>
                <xsl:when test="./@tag=$marc-authors">author</xsl:when>
                <xsl:when test="marc:subfield[@code='e' and (contains(., 'ed.') or contains(., 'editor'))]">editor</xsl:when>
                <xsl:when test="marc:subfield[@code='e' and (contains(., 'tr.') or contains(., 'translator'))]">translator</xsl:when>
                <xsl:when test="preceding-sibling::marc:datafield[@tag=$marc-authors and not(marc:subfield[@code='b']) and tre:strippunct(tre:normalize-punctuation(marc:subfield[@code='a']))!=$this]">modern-editor</xsl:when>
                <xsl:otherwise>uncertain</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:if test="$loglevel='debug'">
            <xsl:message>creatortype='<xsl:value-of select="$creatortype"/>'</xsl:message>
        </xsl:if>
        <xsl:if test="$creatortype='author' or $creatortype='translator' or $creatortype='modern-editor' or ($creatortype='editor' and not(../marc:datafield[@tag=$marc-authors]))">
            <xsl:variable name="quantity" as="xs:integer">
                <xsl:choose>
                    <xsl:when test="$creatortype='author'">
                        <xsl:value-of select="count(../marc:datafield[@tag=$marc-authors])"/>
                    </xsl:when>
                    <xsl:when test="$creatortype='editor'">
                        <xsl:value-of select="count(../marc:datafield[@tag=$marc-persname and marc:subfield[@code='e' and (contains(., 'ed.') or contains(., 'editor'))]])"/>
                    </xsl:when>
                    <xsl:when test="$creatortype='translator'">
                        <xsl:value-of select="count(../marc:datafield[@tag=$marc-persname and marc:subfield[@code='e' and (contains(., 'tr.') or contains(., 'translator'))]])"/>
                    </xsl:when>
                    <xsl:when test="$creatortype='modern-editor'">
                        <xsl:value-of select="count(../marc:datafield[@tag=$marc-persname and not(marc:subfield[@code='e'])])"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="subsequent" as="xs:integer">
                <xsl:choose>
                    <xsl:when test="$creatortype='author'">
                        <xsl:value-of select="count(following-sibling::marc:datafield[@tag=$marc-authors])"/>
                    </xsl:when>
                    <xsl:when test="$creatortype='editor'">
                        <xsl:value-of select="count(following-sibling::marc:datafield[@tag=$marc-persname and marc:subfield[@code='e' and (contains(., 'ed.') or contains(., 'editor'))]])"/>
                    </xsl:when>
                    <xsl:when test="$creatortype='translator'">
                        <xsl:value-of select="count(following-sibling::marc:datafield[@tag=$marc-persname and marc:subfield[@code='e' and (contains(., 'tr.') or contains(., 'translator'))]])"/>
                    </xsl:when>
                    <xsl:when test="$creatortype='modern-editor'">
                        <xsl:value-of select="count(following-sibling/marc:datafield[@tag=$marc-persname and not(marc:subfield[@code='e'])])"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:variable>
        
            <xsl:if test="$creatortype='translator' and not(preceding-sibling::marc:datafield[@tag=$marc-persname and marc:subfield[@code='e' and (contains(., 'tr.') or contains(., 'translator'))]])">
                <xsl:text>Translated by </xsl:text>
            </xsl:if>
            <span>
                <xsl:attribute name="class" select="$creatortype"/>
                <xsl:apply-templates/>
            </span>
            <xsl:choose>
                <xsl:when test="$quantity = 2 and $subsequent = 1">
                    <xsl:text> and </xsl:text>
                </xsl:when>
                <xsl:when test="$quantity &gt; 2 and $subsequent = 1">
                    <xsl:text>; and </xsl:text>
                </xsl:when>
                <xsl:when test="$quantity &gt; 2 and $subsequent &gt; 1">
                    <xsl:text>; </xsl:text>
                </xsl:when>
            </xsl:choose>
            <xsl:choose>
                <xsl:when test="contains($creatortype, 'editor') and $quantity=1">
                    <xsl:text> (ed.). </xsl:text>
                </xsl:when>
                <xsl:when test="contains($creatortype, 'editor') and $quantity &gt; 1 and $subsequent=0">
                    <xsl:text> (eds.). </xsl:text>
                </xsl:when>
                <xsl:when test="$subsequent=0">
                    <xsl:text>. </xsl:text>
                </xsl:when>
            </xsl:choose>
        </xsl:if>
        
        <xsl:if test="$creatortype='uncertain' 
            and not(following-sibling::marc:datafield[@tag=$marc-persname]) 
            and ../marc:datafield[@tag=$marc-title]/marc:subfield[@code='c'] 
            and (not(../marc:datafield[@tag=$marc-authors]) or count(tokenize(../marc:datafield[@tag=$marc-authors]/marc:subfield[@code='a'], ' '))=1) 
            and not(../marc:datafield[@tag=$marc-persname]/marc:subfield[@code='e' and (contains(., 'ed.') or contains(., 'editor') or contains(., 'tr.') or contains(., 'translator'))])">
            <span class="creator">
                <xsl:value-of select="tre:capfirst(replace(tre:normalize-punctuation(../marc:datafield[@tag=$marc-title]/marc:subfield[@code='c'][1]), '\s*;', ','))"/>
            </span>
            <xsl:text>. </xsl:text>
        </xsl:if>
    </xsl:template>
    <xsl:template match="marc:subfield[@code='a' and ancestor::marc:datafield[@tag=$marc-authors or @tag=$marc-persname]]">
        <xsl:variable name="normal" select="tre:normalize-punctuation(.)"/>
        <xsl:choose>
            <xsl:when test="contains($normal, ',')">
                <xsl:value-of select="substring-after($normal, ',')"/>
                <xsl:text> </xsl:text>
                <xsl:value-of select="substring-before($normal, ',')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$normal"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- titles -->
    <xsl:template name="do-title">
        <xsl:variable name="title-node" as="node()">
            <xsl:choose>
                <xsl:when test="marc:datafield[@tag=$marc-parallel and starts-with(marc:subfield[@code='6'], $marc-title)]">
                    <xsl:sequence select="marc:datafield[@tag=$marc-parallel and starts-with(marc:subfield[@code='6'], $marc-title)][1]"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="marc:datafield[@tag=$marc-title][1]"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:for-each select="$title-node">
            <xsl:if test="marc:subfield[@code='a' or @code='b']">
                <p class="title">
                    <xsl:apply-templates select="marc:subfield[@code='a' or @code='b']" mode="titles"/>
                </p><xsl:copy-of select="$internal-punct"/>
            </xsl:if>
            <xsl:if test="marc:subfield[@code='c']">
                <span class="byline">
                    <xsl:apply-templates select="marc:subfield[@code='c']" mode="titles"/>
                </span><xsl:copy-of select="$internal-punct"/>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="marc:subfield[@code='a' or @code='b' or @code='c']" mode="titles">
        <xsl:variable name="normed" select="normalize-unicode(., 'NFC')"/>
        <xsl:variable name="clean" select="tre:normalize-punctuation($normed)"/>
        <xsl:if test="@code='b' and ../marc:subfield[@code='a']">
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:variable name="ready">
            <xsl:choose>
                <xsl:when test="@code='c'">
                    <xsl:value-of select="tre:capfirst($clean)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$clean"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="$ready"/>
    </xsl:template>
    
    <!-- series -->
    <xsl:template match="marc:datafield[@tag=$marc-series]">
        <span class="series">
            <xsl:apply-templates/>
        </span>
        <xsl:text>. </xsl:text>
    </xsl:template>
    <xsl:template match="marc:subfield[@code='a' and ancestor::marc:datafield[@tag=$marc-series]]">
        <xsl:value-of select="tre:normalize-punctuation(.)"/>
    </xsl:template>
    <xsl:template match="marc:subfield[@code='x' and ancestor::marc:datafield[@tag=$marc-series]]">
        <xsl:text> (ISSN: </xsl:text>
        <xsl:value-of select="tre:normalize-punctuation(.)"/>
        <xsl:text>)</xsl:text>
    </xsl:template>
    <xsl:template match="marc:subfield[@code='v' and ancestor::marc:datafield[@tag=$marc-series]]">
        <xsl:variable name="raw" select="tre:normalize-punctuation(.)"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="tre:clean-volumes($raw)"/>
    </xsl:template>
    
    <!-- imprint or production -->
    <xsl:template match="marc:datafield[@tag=$marc-imprint or @tag=$marc-production]">
        <span class="imprint">
            <xsl:apply-templates/>
        </span>
        <xsl:text>. </xsl:text>
    </xsl:template>
    <xsl:template match="marc:subfield[@code='a'and ancestor::marc:datafield[@tag=$marc-imprint or @tag=$marc-production]]">
        <xsl:variable name="normal" select="tre:normalize-punctuation(.)"/>
        <xsl:value-of select="$normal"/>
        <xsl:choose>
            <xsl:when test="following-sibling::marc:subfield[@code='a']">
                <xsl:text>,</xsl:text>
            </xsl:when>
            <xsl:when test="not(ends-with($normal, ':')) and following-sibling::marc:subfield[@code='b']">
                <xsl:text>:</xsl:text>
            </xsl:when>
        </xsl:choose>
        <xsl:text> </xsl:text>
    </xsl:template>
    <xsl:template match="marc:subfield[@code='b'and ancestor::marc:datafield[@tag=$marc-imprint or @tag=$marc-production]]">
        <xsl:variable name="normal" select="tre:normalize-punctuation(.)"/>
        <xsl:value-of select="$normal"/>
        <xsl:choose>
            <xsl:when test="following-sibling::marc:subfield[@code='c'] and not(ends-with($normal, ','))">
                <xsl:text>,</xsl:text>
            </xsl:when>
            <xsl:when test="not(ends-with($normal, ';')) and following-sibling::marc:subfield[@code='b']">
                <xsl:text>;</xsl:text>
            </xsl:when>
        </xsl:choose>
        <xsl:text> </xsl:text>
    </xsl:template>
    <xsl:template match="marc:subfield[@code='c'and ancestor::marc:datafield[@tag=$marc-imprint or @tag=$marc-production]]">
        <xsl:value-of select="tre:normalize-punctuation(.)"/>
    </xsl:template>
    <xsl:template match="marc:subfield[@code='a' and ancestor::marc:datafield[@tag=$marc-production and preceding-sibling::marc:datafield[@tag=$marc-production]] and not(../preceding-sibling::marc:datafield[@tag=$marc-production]/marc:subfield[@code='c'])]">
        <!-- avoid repeating copyright/publication date when both are specified in marc record -->
        <xsl:if test="$loglevel='debug'">
            <xsl:message>normalizing punctuation for: <xsl:value-of select="."/></xsl:message>
        </xsl:if>
        <xsl:value-of select="tre:normalize-punctuation(.)"/>
    </xsl:template>
    
    <!-- holdings -->
    <xsl:template match="marc:datafield[@tag=$marc-holdings and marc:subfield[@code='b']='NISAW']">
        <span class="holdings">
            <xsl:apply-templates/>
        </span>
        <xsl:text>. </xsl:text>
    </xsl:template>
    <xsl:template match="marc:subfield[@code='c' and ancestor::marc:datafield[@tag=$marc-holdings]]">
        <xsl:variable name="normal" select="tre:normalize-punctuation(.)"/>
        <xsl:value-of select="$normal"/>
        <xsl:if test="not(ends-with($normal, ':')) and following-sibling::marc:subfield[@code='d']">
            <xsl:text>:</xsl:text>
        </xsl:if>
        <xsl:text> </xsl:text>
    </xsl:template>
    <xsl:template match="marc:subfield[@code='d' and ancestor::marc:datafield[@tag=$marc-holdings]]">
        <xsl:value-of select="normalize-space(.)"/>
    </xsl:template>
    
    <!-- origins -->
    <xsl:template match="marc:datafield[@tag=$marc-origin and starts-with(marc:subfield[@code='a'], 'ISAW')]">
        <span class="origin">
            <xsl:value-of select="tre:capfirst(substring-after(tre:normalize-punctuation(marc:subfield[@code='a']), 'ISAW '))"/>
        </span>
        <xsl:text>. </xsl:text>
    </xsl:template>
    
    <!-- oclc -->
    <xsl:template match="marc:datafield[@tag=$marc-scn and starts-with(marc:subfield[@code='a'], '(OCoLC)')]">
        <a href="http://www.worldcat.org/oclc/{substring-after(marc:subfield[@code='a'], '(OCoLC)')}">OCLC WorldCat record</a>
        <span><xsl:text>. </xsl:text></span>
    </xsl:template>
    
    <!-- edition -->
    <xsl:template match="marc:datafield[@tag=$marc-edition]">
        <span class="edition">
            <xsl:apply-templates/>
        </span>
        <xsl:text>. </xsl:text>
    </xsl:template>
    <xsl:template match="marc:subfield[@code='a' and ancestor::marc:datafield[@tag=$marc-edition]]">
        <xsl:value-of select="tre:normalize-punctuation(.)"/>
    </xsl:template>
    
    <!-- capture stray content not handled elsewhere -->
    <xsl:template match="marc:*"/>
    <xsl:template match="text()"/>
    
    <!-- produce the webpage itself from template -->
    <xsl:template name="webpage">        
        <xsl:variable name="start-date-string">
            <xsl:value-of select="format-date($starting-date, $dateformat)"/>
        </xsl:variable>
        <xsl:variable name="end-date-string">
            <xsl:value-of select="format-date($ending-date, $dateformat)"/>
        </xsl:variable>
        
        <xsl:variable name="titlestring">
            <xsl:text>New Titles: </xsl:text>
            <xsl:value-of select="$start-date-string"/>
            <xsl:text> - </xsl:text>
            <xsl:value-of select="$end-date-string"/>
        </xsl:variable>
        <xsl:message>saving in <xsl:value-of select="$destdir"/></xsl:message>
        <xsl:result-document format="webpage" href="{$destdir}{$fnslug}webpage.html"> 
            <xsl:value-of select="$n"/>
            <xsl:text disable-output-escaping="yes">&lt;!DOCTYPE html&gt;</xsl:text>
            <xsl:value-of select="$n"/>
            <html xmlns="http://www.w3.org/1999/xhtml" dir="ltr">
                <head>
                    <title>
                        <xsl:value-of select="$titlestring"/>
                    </title>
                    <style type="text/css">
                        .title {color: blue;}
                        .byline {color: red;}                        
                    </style>
                </head>
                <body>
                    <h1>
                        <xsl:value-of select="$titlestring"/>
                    </h1>
                    <p>The following books were acquired and accessioned by the <a href="http://isaw.nyu.edu/library/">ISAW Library</a> between <xsl:value-of select="$start-date-string"/> and <xsl:value-of select="$end-date-string"/>. Items are sorted alphabetically by title.
                    <xsl:choose>
                        <xsl:when test="tre:strip($zotliblink)!=''">
                            This information is <a href="{tre:strip($zotliblink)}">available in a Zotero library</a>.
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:message>ERROR: NO ZOTERO LIBRARY LINK WAS SUPPLIED AS A PARAMETER!</xsl:message>
                        </xsl:otherwise>
                    </xsl:choose>
                    </p>
                    <p>We build a single Zotero library for the entire academic year, with each month representing a Zotero collection. One may therefore view or search just that collection or the entire library. Note that the tags are drawn from pre-existing metadata (i.e., the ISAW Library staff does not tag entries) and represents the contents of the entire library. That is, you will see tags for all works in the Zotero library, but not necessarily associated with anything accessioned in the particular monthly collection you are viewing. For example, if you review acquisitions for January 2015 and select a tag for "Hittite," nothing may come up. This means that nothing accessioned in January 2015 was tagged as "Hittite." However, it does mean that something that academic year was tagged as "Hittite." So, if you move up the hierarchy from the collection "January 2015" to library for the 2014-2015 academic year and then click on "Hittite," you will find items so tagged from previous months, e.g., October 2014. <a href="http://www.zotero.org">Click here for information about Zotero</a>.</p>
                    
                    <xsl:variable name="mixed-collation" select=" concat('http://saxon.sf.net/collation?rules=', encode-for-uri('&lt;  0 &lt; 1 &lt; 2 &lt; 3 &lt; 4 &lt; 5 &lt; 6 &lt; 7 &lt; 8 &lt; 9 &lt; a,A &lt; b,B &lt; c,C &lt; d,D &lt; e,E &lt; f,F &lt; g,G &lt; h,H &lt; i,I &lt; j,J &lt; k,K &lt; l,L &lt; m,M &lt; n,N &lt; o,O &lt; p,P &lt; q,Q &lt; r,R &lt; s,S &lt; t,T &lt; u,U &lt; v,V &lt; w,W &lt; x,X &lt; y,Y &lt; z,Z &amp; A = Á &amp; A = Ä &amp; A = Ẵ &amp; A = Ằ &amp; C = Ç &amp; D = Đ &amp; E = É &amp; E = Ễ &amp; O = Ö &amp; a = à &amp; a = á &amp; a = â &amp; a = ä &amp; ae = æ &amp; c = ç &amp; e = è &amp; e = é &amp; e = ê &amp; i = í &amp; i = î &amp; i = ï &amp; n = ñ &amp; o = ó &amp; o = ô &amp; o = ö &amp; o = ø &amp; u = û &amp; u = ü &amp; c = č &amp; e = ē &amp; g = ğ &amp; i = ĭ &amp; i = İ &amp; i = ı &amp; l = ł &amp; n = ń &amp; o = ō &amp; s = ś &amp; s = ş &amp; S = Š &amp; s = š &amp; H = Ḥ &amp; h = ḥ &amp; H = Ḫ &amp; h = ḫ &amp; K = Ḳ &amp; k = ḳ &amp; s = ṣ &amp; T = Ṭ &amp; t = ṭ &amp; v = ṿ &amp; z = ẓ'))"/>
                    <xsl:for-each select="marc:record[marc:datafield[@tag='AVA']/marc:subfield[@code='b']='NISAW']">
                        <xsl:sort select="marc:datafield[@tag='AVA' and marc:subfield[@code='b']='NISAW']/marc:subfield[@code='d']"/>
                        <xsl:sort select="tre:titlesort(marc:datafield[@tag=$marc-title])"  collation="{$mixed-collation}"  />
                        <xsl:sort select="tre:creatorsort(.)" collation="{$mixed-collation}"/>
                        <xsl:apply-templates select="."/>
                    </xsl:for-each>
                                        
                    <xsl:for-each select="marc:record[not(marc:datafield[@tag='AVA']/marc:subfield[@code='b']='NISAW')]">
                        <xsl:message>WARNING: no holdings info found; item repressed: <xsl:for-each select="marc:*"><xsl:value-of select="normalize-space(.)"/> | </xsl:for-each></xsl:message>
                    </xsl:for-each>       
                    
                    
                    
                    
                </body>
            </html>
        </xsl:result-document>
    </xsl:template>
    
    
    
    <xsl:template name="multicat">
        <xsl:param name="seq" as="item()*"/>
        <!-- <xsl:message>multicat:seq='<xsl:value-of select="$seq"/>'</xsl:message>
        <xsl:message>multicat:count(seq)=<xsl:value-of select="count($seq)"/></xsl:message> -->
        <xsl:choose>
            <xsl:when test="count($seq) &lt; 1">
                <xsl:text></xsl:text>
            </xsl:when>
            <xsl:when test="count($seq)=1">
                <xsl:value-of select="xs:string($seq[1])"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="this" select="xs:string($seq[1])"/>
                <xsl:variable name="notthis" select="subsequence($this, 2)"/>
                <xsl:variable name="that">
                    <xsl:call-template name="multicat">
                        <xsl:with-param name="seq" select="$notthis"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:value-of select="concat($this, $that)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:function name="tre:multicat" as="xs:string">
        <xsl:param name="seq" as="item()*"/>
        <xsl:variable name="result">
            <xsl:call-template name="multicat">
                <xsl:with-param name="seq" select="$seq"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:sequence select="$result"/>
    </xsl:function>
    
    <xsl:function name="tre:creatorsort" as="xs:string">
        <xsl:param name="record" as="node()"/>
        <xsl:variable name="names" select="tre:multicat(($record/marc:datafield[@tag=$marc-authors]/marc:subfield[@code='a'], $record/marc:datafield[@tag='700' and marc:subfield[@code='e' and (contains(., 'ed.') or contains(., 'editor') or contains(., 'tr.'))]]/marc:subfield[@code='a']))"/>
        <xsl:variable name="stripped" select="tre:strippunct($names)"/>
        <xsl:variable name="result" select="replace(lower-case($stripped), '\s+', '')"/>
        <!-- <xsl:message>creatorsort:'<xsl:value-of select="$result"/>'</xsl:message> -->
        <xsl:sequence select="$result"/>
    </xsl:function>
    
    <xsl:function name="tre:titlesort" as="xs:string">
        <xsl:param name="title" as="node()"/>
        <xsl:variable name="start" as="xs:integer">
            <xsl:choose>
                <xsl:when test="xs:integer($title/@ind2) != 0">
                    <xsl:value-of select="xs:integer($title/@ind2) + 1"/>
                </xsl:when>
                <xsl:otherwise>1</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="victim">
            <xsl:call-template name="multicat">
                <xsl:with-param name="seq" select="$title/marc:subfield[@code='a'], $title/marc:subfield[@code='b']"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="normed" select="normalize-space(normalize-unicode($victim))"/>
        <xsl:variable name="dedefed" select="substring($normed, $start)"/>
        <xsl:variable name="stripped" select="tre:strippunct($dedefed)"/>
        <xsl:variable name="low" select="lower-case($stripped)"/>
        <xsl:variable name="despaced" select="replace($low, ' ', '')"/>
        <xsl:sequence select="$despaced"/>
    </xsl:function>
    
    <xsl:function name="tre:strippunct" as="xs:string">
        <xsl:param name="raw" as="xs:string"/>
        <xsl:variable name="result" select="translate($raw, '.,/?;:[]{}\|-_=+()*&amp;&quot;!@#$%^', '')"/>
        <xsl:sequence select="$result"/>
    </xsl:function>
    
    <xsl:function name="tre:clean-volumes" as="xs:string">
        <xsl:param name="raw" as="xs:string"/>
        <xsl:variable name="v" select="replace($raw, 'v. ', '')"/>
        <xsl:variable name="vol" select="replace($v, 'vol. ', '')"/>
        <xsl:variable name="Bd" select="replace($vol, 'Bd. ', '')"/>
        <xsl:variable name="fasc" select="replace($Bd, 'fasc. ', '')"/>
        <xsl:variable name="no" select="replace($fasc, 'no. ', '')"/>
        <xsl:variable name="number" select="replace($no, 'number ', '')"/>
        <xsl:variable name="volume" select="replace($number, 'volume ', '')"/>
        <xsl:sequence select="normalize-space($volume)"/>
    </xsl:function>
    
    <xsl:function name="tre:normalize-punctuation" as="xs:string">
        <xsl:param name="raw" as="xs:string"/>
        <xsl:message>raw="<xsl:value-of select="$raw"/>"</xsl:message>
        <xsl:variable name="cooked">
            <xsl:variable name="almost" select="normalize-space($raw)"/>
            <xsl:variable name="normal" select="replace(replace($almost, '\s+:', ':'), '\s+;', ';')"/>
            
            <!-- clean up end of string -->
            <xsl:variable name="length" select="string-length($normal)"/>
            <xsl:variable name="words" select="tokenize($normal, '[\s\-]+')"/>
            <xsl:variable name="lastword" select="$words[count($words)]"/>
            <xsl:choose>
                <!-- leave ellipsis in place -->
                <xsl:when test="$lastword = '...'">
                    <xsl:value-of select="$normal"/>
                </xsl:when>
                <!-- <xsl:when test="ends-with($lastword, '.,') and string-length($lastword)=3">
                    <xsl:value-of select="substring($normal, 1, $length -1)"/>
                </xsl:when> -->
                
                <!--<xsl:when test="ends-with($lastword, '.') and string-length($lastword)=2">
                    <xsl:value-of select="$normal"/>
                </xsl:when> -->
                <xsl:when test="ends-with($lastword, '.') or ends-with($lastword, ',') or ends-with($lastword, '/')">
                    <xsl:value-of select="substring($normal, 1, $length -1)"/>
                </xsl:when>
                <xsl:when test="$lastword = ':'">
                    <xsl:value-of select="substring($normal, 1, $length -2)"/>
                    <xsl:text>:</xsl:text>
                </xsl:when>
                <xsl:when test="$lastword = ';'">
                    <xsl:value-of select="substring($normal, 1, $length -2)"/>
                </xsl:when>
                <xsl:when test="$lastword = '='">
                    <xsl:value-of select="substring($normal, 1, $length -2)"/>
                    <xsl:text> = </xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$normal"/>
                </xsl:otherwise>
            </xsl:choose>            
        </xsl:variable>
        <xsl:message>cooked="<xsl:value-of select="$cooked"/>"</xsl:message>
        <xsl:variable name="plated" select="normalize-space($cooked)"/>
        <xsl:message>plated="<xsl:value-of select="$plated"/>"</xsl:message>
        <xsl:sequence select="$plated"/>
    </xsl:function>
    
    <xsl:function name="tre:capfirst">
        <xsl:param name="raw"/>
        <xsl:value-of select="upper-case(substring($raw, 1, 1))"/>
        <xsl:value-of select="substring($raw, 2)"/>
    </xsl:function>
    
    <xsl:function name="tre:strip">
        <xsl:param name="raw"/>
        <xsl:variable name="normal" select="normalize-space($raw)"/>
        <xsl:variable name="words" select="tokenize($normal, ' ')"/>
        <xsl:sequence select="tre:multicat($words)"/>        
    </xsl:function>    
    
</xsl:stylesheet>