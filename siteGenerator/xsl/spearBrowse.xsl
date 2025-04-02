<xsl:stylesheet  
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:t="http://www.tei-c.org/ns/1.0" 
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:x="http://www.w3.org/1999/xhtml" 
    xmlns:srophe="https://srophe.app" 
    xmlns:saxon="http://saxon.sf.net/" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:local="http://syriaca.org/ns" 
    exclude-result-prefixes="xs t x saxon local" version="3.0">

 <!-- ================================================================== 
      Adapted for SPEAR - staticHTML.xsl
       
       Generate Static HTML pages for TEI display of each factoid. 
       Code can be used to convert from an old Srophe based application. Or to start an entierly new application.
       
       To convert an existing Srophe application:
       1. Include the path to the existing application under @applicationPath
       2. Include path to new app location, to copy @staticSitePath
       3. Set @convert parameter to 'true'
       
       To start a new application:
       1. Set @convert parameter to 'false'
       2. Run TEI through xslt. Make sure there are matching HTML templates in the ../components directory 
          for each collection that has been declared in your repo-config.xml 
       
       
       
        
       code by: 
        + Winona Salesky (wsalesky@gmail.com)
          
       funding provided by:
        + National Endowment for the Humanities (http://www.neh.gov). Any 
          views, findings, conclusions, or recommendations expressed in 
          this code do not necessarily reflect those of the National 
          Endowment for the Humanities.
       
       ================================================================== -->

    
 <!-- =================================================================== -->
 <!-- set output so we get (mostly) indented HTML -->
 <!-- =================================================================== -->
    <xsl:output name="html" encoding="UTF-8" method="xhtml" indent="no" omit-xml-declaration="yes"/>    
 
    <!-- =================================================================== -->
    <!-- Parameters for tei2HTML -->
    <!-- =================================================================== -->
    
    <!--
    Examples for converting the syriaca application to Gaddel    
    <xsl:param name="applicationPath" select="'/Users/wsalesky/syriaca/syriaca/syriaca'"/>
    <xsl:param name="staticSitePath" select="'/Users/wsalesky/syriaca/syriaca/syriacaStatic'"/>
    <xsl:param name="dataPath" select="'/Users/wsalesky/syriaca/syriaca/syriaca-data-test/data/'"/>
    <xsl:param name="applicationPath" select="'../../'"/>
    <xsl:param name="staticSitePath" select="'../../'"/>
    <xsl:param name="convert" select="'true'"/>
    -->
    
    <xsl:param name="applicationPath" select="'../../../spear'"/>
    <xsl:param name="staticSitePath" select="'../../'"/>
    <xsl:param name="dataPath" select="'./data/'"/>
    
    <!-- Figure out if document is HTML or TEI -->
    <xsl:template match="/">
        <!-- Find unique ids -->
        <!-- Create a document for unique ids plus title for those, via RDF?  -->
        <xsl:variable name="dataCollection" select="'../../../spear-data/data/tei'"/>
        
        <people>
            <!--
            <xsl:for-each-group select="collection(concat($dataCollection,'/.?select=*.xml'))//t:persName" group-by="@ref">
                <person ref="{current-grouping-key()}" count="{count(current-group())}"><xsl:value-of select="."/></person>
            </xsl:for-each-group> 
            -->
        </people>
        <places>
            <!--
            <xsl:for-each-group select="collection(concat($dataCollection,'/.?select=*.xml'))//t:placeName" group-by="@ref">
                <person ref="{current-grouping-key()}" count="{count(current-group())}"><xsl:value-of select="."/></person>
            </xsl:for-each-group> 
            -->
        </places>
        <keywords><!-- <event ana="http://syriaca.org/taxonomy/emperors http://syriaca.org/taxonomy/accession" when="-0044"> --></keywords>
    </xsl:template>
    
    
</xsl:stylesheet>
