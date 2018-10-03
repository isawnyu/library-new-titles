<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:marc="http://www.loc.gov/MARC21/slim"
    xmlns:oai="http://www.openarchives.org/OAI/2.0/"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tre="http://www.paregorios.org"
    xmlns="http://www.loc.gov/MARC21/slim" 
    exclude-result-prefixes="xs tre" 
    version="2.0">
    
    <!-- 
    titles2marc.xsl
    
    This stylesheet takes as input an XML file commonly produced for the ISAW Libraries that contains summary
    information about new books accessioned during a particular period. It parses that file for BSN numbers
    and then does a query against NYU's Aleph system to get modified MARC records for all those books that
    include holdings information. It then filters and augments those MARC records and produces a MARC XML
    collection file suitable for archiving, distribution, and upload/conversion into Zotero -->
    
    <xsl:output method="xml" indent="yes" name="marcxml"/>
    
    <!-- start and end date parameters are inclusive, just like the Romans, but for easy comparison with the 
        content of the DATE_ADDED element as provided in the source XML, we need to find the next lower and 
        next higher numbers -->
    <xsl:param name="startdate">2018-08-01</xsl:param>
    <xsl:param name="enddate">2018-08-31</xsl:param>
    <xsl:variable name="lowerDATE_ADDED" select="number(replace($startdate, '-', ''))-1"/>
    <xsl:variable name="higherDATE_ADDED" select="number(replace($enddate, '-', ''))+1"/>
    
    <xsl:param name="destdir">../result/</xsl:param>
    <xsl:variable name="fnslug">
        <xsl:text>newtitles-</xsl:text>
        <xsl:value-of select="$startdate"/>
        <xsl:text>-</xsl:text>
        <xsl:value-of select="$enddate"/>
        <xsl:text>-</xsl:text>
    </xsl:variable>
    
    <!-- how many words of a title should we emit in our debug/status output? -->
    <xsl:param name="titletrunc">8</xsl:param>

    <xsl:template match="/">
        <xsl:if test="$lowerDATE_ADDED &gt; $higherDATE_ADDED">
            <xsl:message>Starting date (<xsl:value-of select="$startdate"/>) is more recent than ending date (<xsl:value-of select="$enddate"/>. No records will be processed.</xsl:message>
        </xsl:if>
        
        <!-- get marc data from aleph and write to marc.xml file -->
        <xsl:result-document format="marcxml" href="{$destdir}{$fnslug}marc.xml">
            <collection xmlns="http://www.loc.gov/MARC21/slim"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd">
                <xsl:for-each select="descendant::ROW">
                    <xsl:sort select="tre:make-date(DATE_ADDED)"/>
                    <xsl:message>date added: <xsl:value-of select="tre:make-date(DATE_ADDED)"/></xsl:message>
                    <xsl:variable name="da" select="number(DATE_ADDED)"/>
                    <xsl:if test="$da &gt; $lowerDATE_ADDED and $da &lt; $higherDATE_ADDED">
                        <xsl:message>processing ROW with BSN=<xsl:value-of select="BSN"/>
                            <xsl:text>: </xsl:text>
                            <xsl:for-each select="tokenize(normalize-space(BIB_TITLE), ' ')">
                                <xsl:if test="position() &lt; $titletrunc">
                                    <xsl:text> </xsl:text>
                                    <xsl:value-of select="."/>
                                </xsl:if>
                            </xsl:for-each>
                            <xsl:text> ...</xsl:text>
                        </xsl:message>
                        <xsl:apply-templates select="."/>
                    </xsl:if>
                </xsl:for-each>
            </collection>
        </xsl:result-document>
        
    </xsl:template>

    <xsl:template match="ROW">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="BSN">
        <xsl:variable name="alephquery">
<!--            <xsl:text>http://aleph.library.nyu.edu/OAI-script?verb=GetRecord&amp;identifier=NYU01-</xsl:text>
            <xsl:value-of select="normalize-space(.)"/>
            <xsl:text>&amp;metadataPrefix=marc21</xsl:text> -->
            <xsl:text>http://aleph.library.nyu.edu/X?op=publish_avail&amp;doc_num=</xsl:text>
            <xsl:value-of select="normalize-space(.)"/>
            <xsl:text>&amp;library=nyu01</xsl:text>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="doc-available($alephquery)">
                <xsl:for-each select="doc($alephquery)/*">
                    <xsl:apply-templates select="descendant-or-self::marc:record"/>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>document not available: <xsl:value-of select="$alephquery"/></xsl:message>
            </xsl:otherwise>
      </xsl:choose>
    </xsl:template>
    
    <xsl:template match="marc:record">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="marc:datafield[@tag='AVA' and marc:subfield[@code='b'] = 'NISAW']">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates/>
        </xsl:copy>
        <marc:datafield tag="852" ind1=" " ind2=" ">
            <!-- <marc:subfield code="a">New York University</marc:subfield> we don't want to see this in Zotero -->
            <marc:subfield code="b">Institute for the Study of the Ancient World, </marc:subfield>
            <marc:subfield code="c">
                <xsl:value-of select="marc:subfield[@code='c']"/>
            </marc:subfield>
            <marc:subfield code="e">15 East 84th St., </marc:subfield>
            <marc:subfield code="e">New York, NY  10028</marc:subfield>
        </marc:datafield>
        
    </xsl:template>
    
    <xsl:template match="marc:*">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>    
    
    <xsl:template match="*"/>
    
    <xsl:function name="tre:make-date" as="xs:date">
        <xsl:param name="libdate"/>
        <xsl:variable name="delimdatestring">
            <xsl:text></xsl:text>
            <xsl:value-of select="substring($libdate, 1, 4)"/>
            <xsl:text>-</xsl:text>
            <xsl:value-of select="substring($libdate, 5, 2)"/>
            <xsl:text>-</xsl:text>
            <xsl:value-of select="substring($libdate, 7, 2)"/>
            <xsl:text></xsl:text>
        </xsl:variable>
        <xsl:sequence select="xs:date($delimdatestring)"/>
    </xsl:function>

</xsl:stylesheet>
