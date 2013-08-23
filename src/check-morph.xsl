<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0" 
    exclude-result-prefixes="xs"
    version="3.0">
    
    <xsl:param name="e_lang" select="'lat'"/>
    <xsl:param name="e_morphQueryUrl" select="'http://sosol.perseus.tufts.edu/bsp/morphologyservice/analysis/word?lang=REPLACE_LANG&amp;word=REPLACE_WORD&amp;engine=morpheus'"/>
        
    <xsl:output media-type="text/xml" omit-xml-declaration="no" method="xml" indent="yes"/>
    
    <xsl:variable name="nontext">
        <nontext xml:lang="grc"> “”—&quot;‘’,.:;&#x0387;&#x00B7;?!\[\]\{\}\-</nontext>
        <nontext xml:lang="greek"> “”—&quot;‘’,.:;&#x0387;&#x00B7;?!\[\]\{\}\-</nontext>
        <nontext xml:lang="ara"> “”—&quot;‘’,.:;?!\[\]\{\}\-&#x060C;&#x060D;</nontext>
        <nontext xml:lang="lat"> “”—&quot;‘’,.:;&#x0387;&#x00B7;?!\[\]()\{\}\-</nontext>
        <nontext xml:lang="*"> “”—&quot;‘’,.:;&#x0387;&#x00B7;?!\[\]()\{\}\-</nontext>
    </xsl:variable>
    
    <xsl:template match="/">
        <xsl:apply-templates />
    </xsl:template>

    <xsl:template match="node()">
        <xsl:choose>
            <xsl:when test="self::text()">
                <xsl:call-template name="text"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:apply-templates select="@*|node()"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="text">
        <xsl:variable name="lang" select="ancestor-or-self::*[@xml:lang][1]/@xml:lang"/>
        <xsl:variable name="text" select="."/>
        <xsl:choose>
            <xsl:when test="$lang='lat' or $lang='grc'">
                <xsl:variable name="match-nontext">
                    <xsl:choose>
                        <xsl:when test="$lang and $nontext/nontext[@xml:lang=$lang]">
                            <xsl:value-of select="$nontext/nontext[@xml:lang=$lang]"/>
                        </xsl:when>
                        <xsl:otherwise><xsl:value-of select="$nontext/nontext[@xml:lang='*']"/></xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="tokenized">
                    <xsl:call-template name="tokenize-text">
                        <xsl:with-param name="remainder" select="normalize-space($text)"/>
                        <xsl:with-param name="match-nontext" select="$match-nontext"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:for-each select="$tokenized/token">
                    <xsl:choose>
                        <xsl:when test="current()/@type='text' and current()/text() != ''  ">
                        <xsl:variable name="toktext" select="current()/text()"/>
                        <xsl:variable name="url">
                            <xsl:try select="replace(replace($e_morphQueryUrl,'REPLACE_LANG',$lang),'REPLACE_WORD',$toktext)">
                                <xsl:catch><xsl:message>Failed to create request for <xsl:value-of select="$toktext"/></xsl:message></xsl:catch>
                            </xsl:try>
                        </xsl:variable>
                        <xsl:choose>
                            <xsl:when test="$url">
                                <xsl:variable name="results">
                                    <xsl:try select="doc($url)">
                                        <xsl:catch>
                                            <xsl:message>Failed to get response from <xsl:value-of select="$url"/></xsl:message>
                                            <response><error/></response>
                                        </xsl:catch>
                                    </xsl:try>
                                </xsl:variable>
                                <xsl:choose>
                                    <xsl:when test="$results//error">
                                        <xsl:copy-of select="current()/text()"/>
                                    </xsl:when>
                                    <xsl:when test="not($results//entry)">
                                        <xsl:element name="choice" namespace="http://www.tei-c.org/ns/1.0"><xsl:element name="sic" namespace="http://www.tei-c.org/ns/1.0"><xsl:value-of select="$toktext"/></xsl:element><xsl:element name="corr" namespace="http://www.tei-c.org/ns/1.0"/></xsl:element>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:copy-of select="current()/text()"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:when>
                            <xsl:otherwise> <xsl:copy-of select="current()/text()"/></xsl:otherwise>
                        </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:copy-of select="current()/text()"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="@*">
        <xsl:copy/>
    </xsl:template>
    

    
    <xsl:template name="tokenize-text">
        <xsl:param name="tokenized"/>
        <xsl:param name="remainder"/>
        <xsl:param name="match-nontext"/>
        <xsl:choose>
            <xsl:when test="$remainder">
                <xsl:variable name="match_string" select="concat('^([^', $match-nontext, ']+)?([', $match-nontext, ']+)(.*)$')"/>
                <xsl:variable name="tokens">
                    <xsl:analyze-string select="$remainder" regex="{$match_string}">
                        <xsl:matching-substring>
                            <token type="text"><xsl:value-of select="regex-group(1)"/></token>
                            <token type="punc"><xsl:value-of select="regex-group(2)"/></token>
                            <rest><xsl:value-of select="regex-group(3)"/></rest>
                        </xsl:matching-substring>
                        <xsl:non-matching-substring></xsl:non-matching-substring>
                    </xsl:analyze-string>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="$tokens/*">
                        <xsl:call-template name="tokenize-text">
                            <xsl:with-param name="match-nontext" select="$match-nontext"/>
                            <xsl:with-param name="tokenized" select="($tokenized,$tokens/token)"/>
                            <xsl:with-param name="remainder" select="$tokens/rest/text()"></xsl:with-param>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:copy-of select="$tokenized"/>
                        <token type="text"><xsl:value-of select="$remainder"/></token>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="$tokenized"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>