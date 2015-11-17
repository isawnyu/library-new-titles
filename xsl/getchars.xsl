<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:marc="http://www.loc.gov/MARC21/slim"
    xmlns:oai="http://www.openarchives.org/OAI/2.0/"
    xmlns:tre="http://www.pareogrios.org"
    exclude-result-prefixes="xs marc oai"
    version="2.0">
    
    <xsl:output method="text" indent="no"/>
    
    <xsl:variable name="marc-title">245</xsl:variable>
    
    <xsl:template match="/">
        <xsl:apply-templates select="//marc:datafield[@tag=$marc-title]" />
    </xsl:template>
    
    <xsl:template match="marc:datafield[@tag=$marc-title]">
        <xsl:apply-templates select="marc:subfield[@code='a' or @code='c']"/>
    </xsl:template>
    
    <xsl:template match="marc:subfield[@code='a' or @code='c']">
            <xsl:value-of select="tre:strippunct(replace(normalize-space(normalize-unicode(.)), ' ', ''))"/>
        <!-- <xsl:call-template name="charify">
            <xsl:with-param name="victim" select="replace(normalize-space(normalize-unicode(text())), ' ', '')" as="xs:string"/>
        </xsl:call-template>
        -->
    </xsl:template>
    
    <xsl:template match="marc:*"/>
    
    <xsl:template name="charify">
        <xsl:param name="victim" as="xs:string"/>
        <xsl:value-of select="substring($victim, 1, 1)"/>
        <xsl:call-template name="charify">
            <xsl:with-param name="victim" select="substring($victim, 2)"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:function name="tre:strippunct" as="xs:string">
        <xsl:param name="raw" as="xs:string"/>
        <xsl:variable name="result" select="translate($raw, '.,/?;:[]{}\|-_=+()*&amp;&quot;!@#$%^', '')"/>
        <xsl:sequence select="$result"/>
    </xsl:function>
    
</xsl:stylesheet>