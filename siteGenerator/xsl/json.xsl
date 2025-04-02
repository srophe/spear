<xsl:stylesheet  
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:t="http://www.tei-c.org/ns/1.0"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:x="http://www.w3.org/1999/xhtml" 
    xmlns:srophe="https://srophe.app" 
    xmlns:saxon="http://saxon.sf.net/" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:local="http://syriaca.org/ns" 
    exclude-result-prefixes="xs t x saxon local" version="3.0">
    
    <!-- ================================================================== 
      json.xsl - Customized for SPEAR
       
       Generate openSearch index data as json
       Uses /siteGenerator/components/repo-config.xml to build fields. If fields are not specified in repo-config.xml it will not be transformed. 
      
       code by: 
        + Winona Salesky (wsalesky@gmail.com)
          
       funding provided by:
        + National Endowment for the Humanities (http://www.neh.gov). Any 
          views, findings, conclusions, or recommendations expressed in 
          this code do not necessarily reflect those of the National 
          Endowment for the Humanities.
       
       ================================================================== -->
    
    <xsl:output method="text" encoding="utf-8"/>
    
    <xsl:param name="applicationPath" select="'/Users/wsalesky/syriaca/syriaca/syriaca'"/>
    <xsl:param name="staticSitePath" select="'/Users/wsalesky/syriaca/syriaca/syriaca'"/>
    <xsl:param name="dataPath" select="'/Users/wsalesky/syriaca/syriaca/syriaca-data/data/'"/>
    <xsl:param name="configPath" select="concat($staticSitePath, '/siteGenerator/components/repo-config.xml')"/>
    <xsl:variable name="config">
        <xsl:if test="doc-available(xs:anyURI($configPath))">
            <xsl:sequence select="document(xs:anyURI($configPath))"/>
        </xsl:if>
    </xsl:variable>
    
    <xsl:function name="local:sortStringEn">
        <xsl:param name="string"/>
        <xsl:variable name="title" select="normalize-space($string)"/>
        <xsl:value-of select="replace($title,'^[tT]he\s+|^\s+|^[‘|ʻ|ʿ|ʾ]|^[tT]he\s+[^\p{L}]+|^[dD]e\s+|^[dD]e-|^[oO]n\s+[aA]\s+|^[oO]n\s+|^[aA]l-|^[aA]n\s|^[aA]\s+|^\d*\W|^[^\p{L}]','')"/>
    </xsl:function>
    <xsl:function name="local:sortStringAr">
        <xsl:param name="string"/>
        <xsl:value-of select="replace(
            replace(
            replace(
            replace(
            replace($string[1],'^\s+',''), 
            '[ً-ٖ]',''), 
            '(^|\s)(ال|أل|ٱل)',''), 
            'آ|إ|أ|ٱ','ا'), 
            '^(ابن|إبن|بن)','')"/>
    </xsl:function>
    <xsl:function name="local:buildDate">
        <xsl:param name="element" as="node()"/>
        <xsl:if test="$element/@when or $element/@notBefore or $element/@notAfter or $element/@from or $element/@to">
            <xsl:choose>
                <!-- Formats to and from dates -->
                <xsl:when test="$element/@from">
                    <xsl:choose>
                        <xsl:when test="$element/@to">
                            <xsl:value-of select="local:trim-date($element/@from)"/>-<xsl:value-of select="local:trim-date($element/@to)"/>
                        </xsl:when>
                        <xsl:otherwise>from <xsl:value-of select="local:trim-date($element/@from)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:when test="$element/@to">to <xsl:value-of select="local:trim-date($element/@to)"/>
                </xsl:when>
            </xsl:choose>
            <!-- Formats notBefore and notAfter dates -->
            <xsl:if test="$element/@notBefore">
                <!-- Adds comma if there are other dates -->
                <xsl:if test="$element/@to or $element/@from">, </xsl:if>not before <xsl:value-of select="local:trim-date($element/@notBefore)"/>
            </xsl:if>
            <xsl:if test="$element/@notAfter">
                <!-- Adds comma if there are other dates -->
                <xsl:if test="$element/@to or $element/@from or $element/@notBefore">, </xsl:if>not after <xsl:value-of select="local:trim-date($element/@notAfter)"/>
            </xsl:if>
            <!-- Formats when, single date -->
            <xsl:if test="$element/@when">
                <!-- Adds comma if there are other dates -->
                <xsl:if test="$element/@to or $element/@from or $element/@notBefore or $element/@notAfter">, </xsl:if>
                <xsl:value-of select="local:trim-date($element/@when)"/>
            </xsl:if>
        </xsl:if>
    </xsl:function>
    
    <!-- Date function to remove leading 0s -->
    <xsl:function name="local:trim-date">
        <xsl:param name="date"/>
        <xsl:choose>
            <!-- NOTE: This can easily be changed to display BCE instead -->
            <!-- removes leading 0 but leaves -  -->
            <xsl:when test="starts-with($date,'-0')">
                <xsl:value-of select="concat(substring($date,3),' BCE')"/>
            </xsl:when>
            <!-- removes leading 0 -->
            <xsl:when test="starts-with($date,'0')">
                <xsl:value-of select="local:trim-date(substring($date,2))"/>
            </xsl:when>
            <!-- passes value through without changing it -->
            <xsl:otherwise>
                <xsl:value-of select="$date"/>
            </xsl:otherwise>
        </xsl:choose>
        <!--  <xsl:value-of select="string(number($date))"/>-->
    </xsl:function>
    
    <xsl:template match="/">
        <xsl:variable name="doc">
            <xsl:sequence select="."/>
        </xsl:variable>
        <xsl:variable name="id" select="replace($doc/descendant::tei:publicationStmt/tei:idno[@type='URI'][1],'/tei','')"/>
        <xsl:variable name="xml">
            <map xmlns="http://www.w3.org/2005/xpath-functions">
                <xsl:for-each select="$config/descendant::*:searchFields/*:fields">
                    <xsl:choose>
                        <xsl:when test="@function != ''">
                            <xsl:variable name="function" select="@function"/>
                                <xsl:apply-templates select=".[@function = $function]">
                                    <xsl:with-param select="$doc" name="doc"/>
                                    <xsl:with-param select="$id" name="id"/>
                                </xsl:apply-templates>
                        </xsl:when>
                        <xsl:when test="@xpath != ''">
                            <string key="{.}" xmlns="http://www.w3.org/2005/xpath-functions">Test xpath function</string> 
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:message>Incorrect field formatting</xsl:message>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </map>
        </xsl:variable>
        <xsl:value-of select="xml-to-json($xml, map { 'indent' : true() })"/>
    </xsl:template>
    
    <!-- Named functions, should match search fields in repo-config.xml -->
    <xsl:template match="*:fields[@function = 'fullText']">
        <xsl:param name="doc"/>
        <xsl:variable name="field">
            <xsl:value-of select="normalize-space(string-join($doc/descendant::tei:body/descendant::text(),' '))"/>
        </xsl:variable>
        <xsl:if test="$field != ''">
            <string key="{.}" xmlns="http://www.w3.org/2005/xpath-functions">
                <xsl:value-of select="$field"/>
            </string>    
        </xsl:if>
    </xsl:template>
    <xsl:template name="persNameSort">
        <xsl:param name="element"/>
        <xsl:choose>
            <xsl:when test="local-name($element) = 'persName'">
                <xsl:choose>
                    <xsl:when test="$element/child::*[@sort]">
                        <xsl:variable name="sortName">
                            <xsl:for-each select="$element/child::*">
                                <xsl:sort select="@sort"/>
                                <xsl:value-of select="."/><xsl:text> </xsl:text>
                            </xsl:for-each>
                        </xsl:variable>
                        <xsl:value-of select="normalize-space($sortName)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="local:sortStringEn(normalize-space(string-join($element/descendant-or-self::text(),' ')))"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="local:sortStringEn(normalize-space(string-join($element/descendant-or-self::text(),' ')))"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="*:fields[@function = 'idno']">
        <xsl:param name="doc"/>
        <xsl:variable name="field">
        <xsl:value-of select="replace($doc/descendant::tei:publicationStmt/tei:idno[@type='URI'][1],'/tei','')"/>
        </xsl:variable>
        <xsl:if test="$field != ''">
            <string key="{.}" xmlns="http://www.w3.org/2005/xpath-functions">
                <xsl:value-of select="$field"/>
            </string>    
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="*:fields[@function = 'type']">
        <xsl:param name="doc"/>
        <xsl:param name="id"/>
        <xsl:choose>
            <xsl:when test="contains($id, '/place')">
                <xsl:variable name="field">
                    <xsl:value-of select="$doc/descendant::tei:place/@ana"/>
                </xsl:variable>
                <xsl:for-each select="tokenize($field,' ')">
                    <string key="{.}" xmlns="http://www.w3.org/2005/xpath-functions">
                        <xsl:value-of select="tokenize(.,'/')[last()]"/>
                    </string>
                </xsl:for-each>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="*:fields"/>
    <!--
    <xsl:template match="*:fields[@function = 'fullText']">
        <xsl:param name="doc"/>
        <xsl:apply-templates select="$doc/descendant::text()"/> 
    </xsl:template>
    -->
    
    <xsl:template match="t:TEI" mode="fullText">
        <xsl:value-of select="normalize-space(string-join(descendant::tei:body/descendant::text(),' '))"/>
    </xsl:template>
    <xsl:template match="t:TEI" mode="title">
        <xsl:choose>
            <xsl:when test="descendant::t:title"><xsl:value-of select="descendant::t:title[1]"/></xsl:when>
        </xsl:choose>
    </xsl:template>
    <!-- Output Data as json for OpenSearch  -->
    <!-- Indexes, use facet-config files -->
    <xsl:template name="docJSON">
        <xsl:param name="doc"/>
        <xsl:variable name="xml">
            <map xmlns="http://www.w3.org/2005/xpath-functions">
                <xsl:for-each select="$config/descendant::*:searchFields/*:fields">
                    <xsl:choose>
                        <xsl:when test="@function != ''">Function
                        <string key="{.}" xmlns="http://www.w3.org/2005/xpath-functions">Test Function here</string>
                        </xsl:when>
                        <xsl:when test="@xpath != ''">
                            <string key="{.}" xmlns="http://www.w3.org/2005/xpath-functions">
                                <xsl:variable name="xpath" select="string(@xpath)"/>
<!--                                <xsl:evaluate xpath="$xpath"/>-->
                                <xsl:apply-templates select="$doc" mode="index">
                                    <xsl:with-param name="xpath" select="$xpath"></xsl:with-param>
                                </xsl:apply-templates>
                                <!--
                                <xsl:for-each select="$doc/descendant-or-self::t:TEI">
                                    <xsl:evaluate xpath="$xpath"/>
                                    <xsl:value-of select="local-name(.)"/> :: <xsl:value-of select="local-name(child::*[1])"/>
                                </xsl:for-each>
                                -->
                            </string> 
                        </xsl:when>
                        <xsl:otherwise>
                              <xsl:message>Incorrect field formatting</xsl:message>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </map>
            <!-- 
                <map xmlns="http://www.w3.org/2005/xpath-functions">
                    <map key="mappings">
                        <map key="properties">
                            <xsl:for-each select="$config/descendant::*:searchFields/*:fields">
                                <map key="{.}">
                                    <string key="type">
                                        <xsl:choose>
                                            <xsl:when test="@type"><xsl:value-of select="string(@type)"/></xsl:when>
                                            <xsl:otherwise>text</xsl:otherwise>
                                        </xsl:choose>
                                    </string>
                                </map>
                            </xsl:for-each>
                        </map>
                    </map>
                </map>
            -->
        </xsl:variable>
        <xsl:value-of select="xml-to-json($xml, map { 'indent' : true() })"/>
    </xsl:template>
    
    <xsl:template mode="index" match="/t:TEI">
        <xsl:param name="xpath"></xsl:param>
        <xsl:variable name="string">    
            <xsl:evaluate xpath="$xpath"/>
        </xsl:variable>
        <xsl:value-of select="$string"/>
    </xsl:template>
    
</xsl:stylesheet>