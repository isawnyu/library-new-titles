<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:marc="http://www.loc.gov/MARC21/slim"
    xmlns:oai="http://www.openarchives.org/OAI/2.0/"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns="http://www.loc.gov/MARC21/slim" 
    exclude-result-prefixes="xs" 
    version="2.0">

    <xsl:output method="xml" indent="yes"/>

    <xsl:template match="/">
        <collection xmlns="http://www.loc.gov/MARC21/slim"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd">
            <xsl:apply-templates select="descendant::ROW"/>
        </collection>
    </xsl:template>

    <xsl:template match="ROW">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="BSN">
        <xsl:variable name="alephquery">
<!--            <xsl:text>http://aleph.library.nyu.edu/OAI-script?verb=GetRecord&amp;identifier=NYU01-</xsl:text>
            <xsl:value-of select="normalize-space(.)"/>
            <xsl:text>&amp;metadataPrefix=marc21</xsl:text> -->
            <xsl:text>http://aleph.library.nyu.edu:8991/X?op=publish_avail&amp;doc_num=</xsl:text>
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
            <marc:subfield code="a">New York University</marc:subfield>
            <marc:subfield code="b">Institute for the Study of the Ancient World</marc:subfield>
            <marc:subfield code="c">
                <xsl:value-of select="marc:subfield[@code='c']"/>
            </marc:subfield>
            <marc:subfield code="e">15 East 84th Street</marc:subfield>
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

</xsl:stylesheet>
