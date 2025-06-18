<xsl:stylesheet xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:t="http://www.tei-c.org/ns/1.0"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:x="http://www.w3.org/1999/xhtml"
    xmlns:srophe="https://srophe.app"
    xmlns:saxon="http://saxon.sf.net/"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:local="http://syriaca.org/ns" exclude-result-prefixes="xs t x saxon local" version="3.0">

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
    <!-- import component stylesheets for HTML page portions -->
    <!-- =================================================================== -->
    <xsl:import href="tei2html.xsl"/>
    <!--    <xsl:import href="helper-functions.xsl"/>-->
    <xsl:import href="maps.xsl"/>
    <!--    <xsl:import href="json.xsl"/>-->
    <!--    <xsl:import href="relationships.xsl"/>-->

    <!-- =================================================================== -->
    <!-- set output so we get (mostly) indented HTML -->
    <!-- =================================================================== -->
    <xsl:output name="html" encoding="UTF-8" method="xhtml" indent="no" omit-xml-declaration="yes"/>

    <!-- 
    Step 1: 
    create HTML page outline
        include header
        include nav for submodule
        transform HTML
        Add Footer
        
        Add dynamic (javascript calls to RDF or other related items)
        
        -->

    <!-- =================================================================== -->
    <!-- Parameters for tei2HTML -->
    <!-- =================================================================== -->

    <xsl:param name="applicationPath" select="'../../../spear'"/>
    <xsl:param name="staticSitePath" select="'../../'"/>
    <xsl:param name="dataPath" select="'../../../spear-data/data'"/>

    <!-- Example: generate new index.html page for places collection -->
    <xsl:param name="outputFile" select="''"/>
    <xsl:param name="outputCollection" select="''"/>

    <!-- Find repo-config to find collection style values and page stubs -->
    <xsl:variable name="configPath">
        <xsl:choose>
            <xsl:when test="$staticSitePath != ''">
                <xsl:value-of select="concat($staticSitePath, '/siteGenerator/components/repo-config.xml')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="'../components/repo-config.xml'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- Get configuration file.  -->
    <xsl:variable name="config">
        <xsl:if test="doc-available(xs:anyURI($configPath))">
            <xsl:sequence select="document(xs:anyURI($configPath))"/>
        </xsl:if>
    </xsl:variable>

    <!-- Root of app for building dynamic links. Default is eXist app root -->
    <!-- Not needed? -->
    <xsl:variable name="nav-base" select="'/'"/>

    <!-- Base URI for identifiers in app data -->
    <xsl:variable name="base-uri">
        <xsl:choose>
            <xsl:when test="$config/descendant::*:base_uri">
                <xsl:value-of select="$config/descendant::*:base_uri"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="'http://syriaca.org'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- Hard coded values-->
    <xsl:param name="normalization">NFKC</xsl:param>

    <!-- Variables for building HTML from TEI records -->
    <!-- Repository Title -->
    <xsl:variable name="repository-title">
        <xsl:choose>
            <xsl:when test="$config/child::*">
                <xsl:value-of select="$config/descendant::*:title[1]"/>
            </xsl:when>
            <xsl:otherwise>The Gaddel Application</xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="collection-title">
        <xsl:choose>
            <xsl:when test="$config/child::*">
                <xsl:choose>
                    <xsl:when test="$config/descendant::*:collection[@name = $collection]">
                        <xsl:value-of select="$config/descendant::*:collection[@name = $collection]/@title"/>
                    </xsl:when>
                    <xsl:when test="$config/descendant::*:collection[@title = $collection]">
                        <xsl:value-of select="$config/descendant::*:collection[@title = $collection]/@title"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$repository-title"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$repository-title"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- Resource title -->
    <xsl:variable name="resource-title">
        <xsl:choose>
            <xsl:when test="/descendant::t:text/t:body[descendant::*[@srophe:tags = '#syriaca-headword']]">
                <xsl:apply-templates select="/descendant::t:text/t:body[descendant::*[@srophe:tags = '#syriaca-headword']][@xml:lang = 'en']/text()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="/descendant-or-self::t:titleStmt/t:title[1]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- Resource id -->
    <xsl:variable name="resource-path" select="substring-after(document-uri(.), ':')"/>

    <!-- Find index files -->
    <xsl:variable name="personsIndex">
        <xsl:variable name="personsIndexPath" select="concat($dataPath, '/personsIndex.xml')"/>
        <xsl:if test="doc-available(xs:anyURI($personsIndexPath))">
            <xsl:sequence select="document(xs:anyURI($personsIndexPath))"/>
        </xsl:if>
    </xsl:variable>
    <xsl:variable name="placesIndex">
        <xsl:variable name="placesIndexPath" select="concat($dataPath, '/placesIndex.xml')"/>
        <xsl:if test="doc-available(xs:anyURI($placesIndexPath))">
            <xsl:sequence select="document(xs:anyURI($placesIndexPath))"/>
        </xsl:if>
    </xsl:variable>
    <xsl:variable name="keywordsIndex">
        <xsl:variable name="keywordsIndexPath" select="concat($dataPath, '/keywordsIndex.xml')"/>
        <xsl:if test="doc-available(xs:anyURI($keywordsIndexPath))">
            <xsl:sequence select="document(xs:anyURI($keywordsIndexPath))"/>
        </xsl:if>
    </xsl:variable>
    <xsl:variable name="collection" select="collection(concat($dataPath,'?recurse=yes;select=*.xml'))/*"/>
    <xsl:variable name="refs" select="distinct-values($collection/descendant::tei:ab/@ref | $collection/descendant::tei:ab/@ana)"/>
    <!-- Figure out if document is HTML or TEI -->
    <xsl:template match="/">

        <!--<xsl:call-template name="buildBrowsePage"/>-->
        <xsl:for-each select="$refs">
            <xsl:variable name="filename"/>
            <xsl:result-document href="{$applicationPath}/browse.html">
            </xsl:result-document>
        </xsl:for-each>
        <xsl:call-template name="buildPersons"/>
        <xsl:call-template name="buildPlaces"/>
        <xsl:call-template name="buildKeywords"/>
        <!-- 
            1. Create browse page for each person/place/keyword with a spear match
            2. Create a page for each unique entity with a spear match (person,place,keyword)
                - consolidate factoids relating to entity
                - link to related
        -->

    </xsl:template>
    <xsl:template name="buildBrowsePage">
        <xsl:result-document href="{$applicationPath}/browse.html">
            <html xmlns="http://www.w3.org/1999/xhtml">
                <xsl:variable name="collectionTemplate">
                    <xsl:variable name="templatePath" select="replace(concat($staticSitePath, '/siteGenerator/components/', string($config/descendant::*:collection[1]/@template), '.html'), '//', '/')"/>
                    <xsl:if test="doc-available(xs:anyURI($templatePath))">
                        <xsl:sequence select="document(xs:anyURI($templatePath))"/>
                    </xsl:if>
                </xsl:variable>
                <xsl:variable name="template">
                    <xsl:choose>
                        <xsl:when test="$collectionTemplate/child::*">
                            <xsl:sequence select="$collectionTemplate"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:message>Error Can not find matching template for HTML page
                                <xsl:value-of select="replace(concat($staticSitePath, '/siteGenerator/components/', string($config/descendant::*:collection[1]/@template), '.html'), '//', '/')"/>
                            </xsl:message>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="$template/descendant::*:head">
                        <xsl:choose>
                            <xsl:when test="$template/descendant::*:head">
                                <xsl:copy-of select="$template/descendant::*:head"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:message>Error in template, check template for html:head
                                </xsl:message>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:message>No template found for html:head element</xsl:message>
                    </xsl:otherwise>
                </xsl:choose>
                <body id="body">

                    <xsl:choose>
                        <xsl:when test="not(empty($template))">
                            <xsl:choose>
                                <xsl:when test="$template/descendant::html:nav">
                                    <xsl:copy-of select="$template/descendant::html:nav"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:message>No template found for html:head element</xsl:message>
                                    <xsl:call-template name="genericNav"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:message>No template found for html:head element</xsl:message>
                            <xsl:call-template name="genericNav"/>
                        </xsl:otherwise>
                    </xsl:choose>
                    <!-- Main browse functions -->
                    <div class="main-content top-padding">
                        <h1>Browse</h1>
                        <p class="indent">Listings of records.</p>
                        <div class="panel panel-default">
                            <div class="panel-heading panel-heading-nav">
                                <ul class="nav nav-tabs">
                                    <li role="presentation" class="active">
                                        <a href="#personsPanel" aria-controls="one" role="tab" data-toggle="tab">Persons</a>
                                    </li>
                                    <li role="presentation">
                                        <a href="#placesPanel" aria-controls="two" role="tab" data-toggle="tab">Places</a>
                                    </li>
                                    <li role="presentation">
                                        <a href="#keywordsPanel" aria-controls="three" role="tab" data-toggle="tab">Keywords</a>
                                    </li>
                                </ul>
                            </div>
                            <div class="panel-body">
                                <div class="tab-content">
                                    <div role="tabpanel" class="tab-pane fade in active" id="personsPanel">
                                        <xsl:call-template name="browsePersons"/>
                                    </div>
                                    <div role="tabpanel" class="tab-pane fade" id="placesPanel">
                                        <xsl:call-template name="browsePlaces"/>
                                    </div>
                                    <div role="tabpanel" class="tab-pane fade" id="keywordsPanel">
                                        <xsl:call-template name="browseKeywords"/>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </body>
            </html>
        </xsl:result-document>
    </xsl:template>
    <xsl:template name="buildBrowsePage">
        <xsl:result-document href="{$applicationPath}/browse.html">
            <html xmlns="http://www.w3.org/1999/xhtml">
                <xsl:variable name="collectionTemplate">
                    <xsl:variable name="templatePath" select="replace(concat($staticSitePath, '/siteGenerator/components/', string($config/descendant::*:collection[1]/@template), '.html'), '//', '/')"/>
                    <xsl:if test="doc-available(xs:anyURI($templatePath))">
                        <xsl:sequence select="document(xs:anyURI($templatePath))"/>
                    </xsl:if>
                </xsl:variable>
                <xsl:variable name="template">
                    <xsl:choose>
                        <xsl:when test="$collectionTemplate/child::*">
                            <xsl:sequence select="$collectionTemplate"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:message>Error Can not find matching template for HTML page
                                <xsl:value-of select="replace(concat($staticSitePath, '/siteGenerator/components/', string($config/descendant::*:collection[1]/@template), '.html'), '//', '/')"/>
                            </xsl:message>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="$template/descendant::*:head">
                        <xsl:choose>
                            <xsl:when test="$template/descendant::*:head">
                                <xsl:copy-of select="$template/descendant::*:head"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:message>Error in template, check template for html:head
                                </xsl:message>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:message>No template found for html:head element</xsl:message>
                    </xsl:otherwise>
                </xsl:choose>
                <body id="body">

                    <xsl:choose>
                        <xsl:when test="not(empty($template))">
                            <xsl:choose>
                                <xsl:when test="$template/descendant::html:nav">
                                    <xsl:copy-of select="$template/descendant::html:nav"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:message>No template found for html:head element</xsl:message>
                                    <xsl:call-template name="genericNav"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:message>No template found for html:head element</xsl:message>
                            <xsl:call-template name="genericNav"/>
                        </xsl:otherwise>
                    </xsl:choose>
                    <!-- Main browse functions -->
                    <div class="main-content top-padding">
                        <h1>Browse</h1>
                        <p class="indent">Listings of records.</p>
                        <div class="panel panel-default">
                            <div class="panel-heading panel-heading-nav">
                                <ul class="nav nav-tabs">
                                    <li role="presentation" class="active">
                                        <a href="#personsPanel" aria-controls="one" role="tab" data-toggle="tab">Persons</a>
                                    </li>
                                    <li role="presentation">
                                        <a href="#placesPanel" aria-controls="two" role="tab" data-toggle="tab">Places</a>
                                    </li>
                                    <li role="presentation">
                                        <a href="#keywordsPanel" aria-controls="three" role="tab" data-toggle="tab">Keywords</a>
                                    </li>
                                </ul>
                            </div>
                            <div class="panel-body">
                                <div class="tab-content">
                                    <div role="tabpanel" class="tab-pane fade in active" id="personsPanel">
                                        <xsl:call-template name="browsePersons"/>
                                    </div>
                                    <div role="tabpanel" class="tab-pane fade" id="placesPanel">
                                        <xsl:call-template name="browsePlaces"/>
                                    </div>
                                    <div role="tabpanel" class="tab-pane fade" id="keywordsPanel">
                                        <xsl:call-template name="browseKeywords"/>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </body>
            </html>
        </xsl:result-document>
    </xsl:template>
    <xsl:template name="browsePersons">


        <div class="col-md-12">
            <div class="browse-alpha tabbable">
                <ul class="list-inline">
                    <li>
                        <a href="#personsA">A</a>
                    </li>
                    <li>
                        <a href="#personsB">B</a>
                    </li>
                    <li>
                        <a href="#personsC">C</a>
                    </li>
                    <li>
                        <a href="#personsD">D</a>
                    </li>
                    <li>
                        <a href="#personsE">E</a>
                    </li>
                    <li>
                        <a href="#personsF">F</a>
                    </li>
                    <li>
                        <a href="#personsG">G</a>
                    </li>
                    <li>
                        <a href="#personsH">H</a>
                    </li>
                    <li>
                        <a href="#personsI">I</a>
                    </li>
                    <li>
                        <a href="#personsJ">J</a>
                    </li>
                    <li>
                        <a href="#personsK">K</a>
                    </li>
                    <li>
                        <a href="#personsL">L</a>
                    </li>
                    <li>
                        <a href="#personsM">M</a>
                    </li>
                    <li>
                        <a href="#personsN">N</a>
                    </li>
                    <li>
                        <a href="#personsO">O</a>
                    </li>
                    <li>
                        <a href="#personsP">P</a>
                    </li>
                    <li>
                        <a href="#personsQ">Q</a>
                    </li>
                    <li>
                        <a href="#personsR">R</a>
                    </li>
                    <li>
                        <a href="#personsS">S</a>
                    </li>
                    <li>
                        <a href="#personsT">T</a>
                    </li>
                    <li>
                        <a href="#personsU">U</a>
                    </li>
                    <li>
                        <a href="#personsV">V</a>
                    </li>
                    <li>
                        <a href="#personsW">W</a>
                    </li>
                    <li>
                        <a href="#personsX">X</a>
                    </li>
                    <li>
                        <a href="#personsY">Y</a>
                    </li>
                    <li>
                        <a href="#personsZ">Z</a>
                    </li>
                </ul>
            </div>

        </div>
    </xsl:template>
    <xsl:template name="browsePlaces">
        <div class="browse-alpha tabbable">
            <ul class="list-inline">
                <li>
                    <a href="#placesA">A</a>
                </li>
                <li>
                    <a href="#placesB">B</a>
                </li>
                <li>
                    <a href="#placesC">C</a>
                </li>
                <li>
                    <a href="#placesD">D</a>
                </li>
                <li>
                    <a href="#placesE">E</a>
                </li>
                <li>
                    <a href="#placesF">F</a>
                </li>
                <li>
                    <a href="#placesG">G</a>
                </li>
                <li>
                    <a href="#placesH">H</a>
                </li>
                <li>
                    <a href="#placesI">I</a>
                </li>
                <li>
                    <a href="#placesJ">J</a>
                </li>
                <li>
                    <a href="#placesK">K</a>
                </li>
                <li>
                    <a href="#placesL">L</a>
                </li>
                <li>
                    <a href="#placesM">M</a>
                </li>
                <li>
                    <a href="#placesN">N</a>
                </li>
                <li>
                    <a href="#placesO">O</a>
                </li>
                <li>
                    <a href="#placesP">P</a>
                </li>
                <li>
                    <a href="#placesQ">Q</a>
                </li>
                <li>
                    <a href="#placesR">R</a>
                </li>
                <li>
                    <a href="#placesS">S</a>
                </li>
                <li>
                    <a href="#placesT">T</a>
                </li>
                <li>
                    <a href="#placesU">U</a>
                </li>
                <li>
                    <a href="#placesV">V</a>
                </li>
                <li>
                    <a href="#placesW">W</a>
                </li>
                <li>
                    <a href="#placesX">X</a>
                </li>
                <li>
                    <a href="#placesY">Y</a>
                </li>
                <li>
                    <a href="#placesZ">Z</a>
                </li>
            </ul>
        </div>
    </xsl:template>
    <xsl:template name="browseKeywords">
        <div class="browse-alpha tabbable">
            <ul class="list-inline">
                <li>
                    <a href="#keywordsA">A</a>
                </li>
                <li>
                    <a href="#keywordsB">B</a>
                </li>
                <li>
                    <a href="#keywordsC">C</a>
                </li>
                <li>
                    <a href="#keywordsD">D</a>
                </li>
                <li>
                    <a href="#keywordsE">E</a>
                </li>
                <li>
                    <a href="#keywordsF">F</a>
                </li>
                <li>
                    <a href="#keywordsG">G</a>
                </li>
                <li>
                    <a href="#keywordsH">H</a>
                </li>
                <li>
                    <a href="#keywordsI">I</a>
                </li>
                <li>
                    <a href="#keywordsJ">J</a>
                </li>
                <li>
                    <a href="#keywordsK">K</a>
                </li>
                <li>
                    <a href="#keywordsL">L</a>
                </li>
                <li>
                    <a href="#keywordsM">M</a>
                </li>
                <li>
                    <a href="#keywordsN">N</a>
                </li>
                <li>
                    <a href="#keywordsO">O</a>
                </li>
                <li>
                    <a href="#keywordsP">P</a>
                </li>
                <li>
                    <a href="#keywordsQ">Q</a>
                </li>
                <li>
                    <a href="#keywordsR">R</a>
                </li>
                <li>
                    <a href="#keywordsS">S</a>
                </li>
                <li>
                    <a href="#keywordsT">T</a>
                </li>
                <li>
                    <a href="#keywordsU">U</a>
                </li>
                <li>
                    <a href="#keywordsV">V</a>
                </li>
                <li>
                    <a href="#keywordsW">W</a>
                </li>
                <li>
                    <a href="#keywordsX">X</a>
                </li>
                <li>
                    <a href="#keywordsY">Y</a>
                </li>
                <li>
                    <a href="#keywordsZ">Z</a>
                </li>
            </ul>
        </div>
    </xsl:template>
    <xsl:template name="htmlPage">
        <xsl:param name="pageType"/>
        <xsl:param name="nodes"/>
        <xsl:param name="idno"/>
        <!-- Collection variables from repo-config -->
        <xsl:variable name="collectionURIPattern">
            <xsl:if test="$idno != ''">
                <xsl:for-each select="tokenize($idno, '/')">
                    <xsl:if test="position() != last()">
                        <xsl:value-of select="concat(., '/')"/>
                    </xsl:if>
                </xsl:for-each>
            </xsl:if>
        </xsl:variable>
        <xsl:variable name="collectionValues" select="$config/descendant::*:collection[@record-URI-pattern = $collectionURIPattern][1]"/>
        <xsl:variable name="collectionTemplate">
            <xsl:choose>
                <xsl:when test="$idno != ''">
                    <!--                    <xsl:message> TEI record with an idno: <xsl:value-of select="$idno"/></xsl:message>-->
                    <xsl:variable name="templatePath" select="replace(concat($staticSitePath, '/siteGenerator/components/', string($collectionValues/@template), '.html'), '//', '/')"/>
                    <xsl:if test="doc-available(xs:anyURI($templatePath))">
                        <xsl:sequence select="document(xs:anyURI($templatePath))"/>
                    </xsl:if>
                </xsl:when>
                <xsl:when test="$convert = 'false' and $outputFile != ''">
                    <!--                    <xsl:message>Generate new HTML page</xsl:message>-->
                    <xsl:variable name="templatePath">
                        <xsl:choose>
                            <xsl:when test="$config/descendant::*:collection[@name = $outputCollection]/@template">
                                <xsl:value-of select="concat($config/descendant::*:collection[@name = $outputCollection]/@template, '.html')" />
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="'page.html'"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:variable name="fullTemplatePath">
                        <xsl:value-of select="concat($staticSitePath, '/', replace($templatePath, 'templates/', 'siteGenerator/components/'))" />
                    </xsl:variable>
                    <xsl:if test="doc-available($fullTemplatePath)">
                        <xsl:sequence select="document($fullTemplatePath)"/>
                    </xsl:if>
                </xsl:when>
                <xsl:when test="$nodes/@data-template-with != ''">
                    <!--                    <xsl:message>Convert HTML from old format </xsl:message>-->
                    <xsl:variable name="templatePath" select="replace(concat($staticSitePath, '/siteGenerator/components/', substring-after($nodes/@data-template-with, 'templates/')), '//', '/')"/>
                    <xsl:if test="doc-available(xs:anyURI($templatePath))">
                        <xsl:sequence select="document(xs:anyURI($templatePath))"/>
                    </xsl:if>
                </xsl:when>
                <xsl:otherwise>
                    <!--                    <xsl:message>Find generic page.html template</xsl:message>-->
                    <xsl:variable name="templatePath" select="replace(concat($staticSitePath, '/siteGenerator/components/page.html'), '//', '/')"/>
                    <xsl:if test="doc-available(xs:anyURI($templatePath))">
                        <xsl:sequence select="document(xs:anyURI($templatePath))"/>
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="collection" select="$collectionValues/@name"/>
        <!-- <xsl:apply-templates/> -->
        <html xmlns="http://www.w3.org/1999/xhtml">
            <!-- HTML Header, use templates as already estabilished, if no template exists, use generic 'page.html' -->
            <xsl:variable name="template">
                <xsl:choose>
                    <xsl:when test="$pageType = 'HTML'">
                        <xsl:choose>
                            <xsl:when test="$collectionTemplate/child::*">
                                <xsl:sequence select="$collectionTemplate"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:message>Error Can not find matching template for HTML page
                                    <xsl:value-of select="replace(concat($staticSitePath, '/siteGenerator/components/', string($collectionValues/@template), '.html'), '//', '/')" />
                                </xsl:message>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:when test="$pageType = 'TEI'">
                        <xsl:choose>
                            <xsl:when test="$collectionTemplate/child::*">
                                <xsl:sequence select="$collectionTemplate"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:message>Error Can not find matching template for TEI page
                                    <xsl:value-of select="replace(concat($staticSitePath, '/siteGenerator/components/', string($collectionValues/@template), '.html'), '//', '/')" />
                                </xsl:message>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:when test="$pageType = 'RDF'">
                        <xsl:choose>
                            <xsl:when test="$collectionTemplate/child::*">
                                <xsl:sequence select="$collectionTemplate"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:message>Error Can not find matching template for TEI page
                                    <xsl:value-of select="replace(concat($staticSitePath, '/siteGenerator/components/', string($collectionValues/@template), '.html'), '//', '/')" />
                                </xsl:message>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                </xsl:choose>
            </xsl:variable>
            <xsl:choose>
                <xsl:when test="$template/descendant::*:head">
                    <xsl:choose>
                        <xsl:when test="$template/descendant::*:head">
                            <xsl:copy-of select="$template/descendant::*:head"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:message>Error in template, check template for html:head
                            </xsl:message>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>No template found for html:head element</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
            <body id="body">
                <xsl:choose>
                    <xsl:when test="not(empty($template))">
                        <xsl:choose>
                            <xsl:when test="$template/descendant::html:nav">
                                <xsl:copy-of select="$template/descendant::html:nav"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:message>No template found for html:head element</xsl:message>
                                <xsl:call-template name="genericNav"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:message>No template found for html:head element</xsl:message>
                        <xsl:call-template name="genericNav"/>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:choose>
                    <xsl:when test="$pageType = 'HTML'">
                        <xsl:copy-of select="$nodes"/>
                    </xsl:when>
                    <xsl:when test="$pageType = 'RDF'">
                        <xsl:apply-templates select="$nodes/rdf:Description[@rdf:about = $idno]"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:choose>
                            <xsl:when test="$collectionTemplate">
                                <div class="main-content-block">
                                    <div class="interior-content">
                                        <xsl:call-template name="otherDataFormats">
                                            <xsl:with-param name="node" select="t:TEI"/>
                                            <xsl:with-param name="idno" select="$idno"/>
                                            <xsl:with-param name="formats" select="'print,tei,rdf'" />
                                        </xsl:call-template>
                                        <div class="row">
                                            <div class="col-md-7 col-lg-8">
                                                <xsl:apply-templates select="$nodes//t:TEI">
                                                    <xsl:with-param name="collection" select="$collection"/>
                                                </xsl:apply-templates>
                                            </div>
                                            <div class="col-md-5 col-lg-4 right-menu">
                                                <!-- Make dynamic -->
                                                <!-- WS:ToDo Maps -->
                                                <xsl:choose>
                                                    <xsl:when test="$nodes/ancestor-or-self::t:TEI/descendant::t:geo">
                                                        <xsl:call-template name="leafletMap">
                                                            <xsl:with-param name="nodes" select="$nodes/ancestor-or-self::t:TEI"/>
                                                        </xsl:call-template>
                                                    </xsl:when>
                                                    <!-- Maps for related places -->
                                                </xsl:choose>
                                                <span class="rdfRelationships" data-recordID="{$idno}"/>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:call-template name="genericTEIPage">
                                    <xsl:with-param name="config" select="$config"/>
                                    <xsl:with-param name="repository-title" select="$repository-title"/>
                                    <xsl:with-param name="collection-title" select="$collection-title"/>
                                </xsl:call-template>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:if test="doc-available(xs:anyURI(concat($staticSitePath, '/siteGenerator/components/footer.html')))">
                    <xsl:copy-of select="document(xs:anyURI(concat($staticSitePath, '/siteGenerator/components/footer.html')))" />
                </xsl:if>
            </body>
            <xsl:if test="$template/child::*[1]/html:script">
                <xsl:copy-of select="$template/child::*[1]/html:script"/>
            </xsl:if>
        </html>
    </xsl:template>

    <xsl:template match="html:li">
        <xsl:choose>
            <xsl:when test="@data-template = 'app:shared-content'">
                <xsl:variable name="sharedContent" select="@data-template-path"/>
                <xsl:if test="doc-available(xs:anyURI(concat($staticSitePath, '/siteGenerator/components/', tokenize($sharedContent, '/')[last()])))">
                    <xsl:copy-of select="document(xs:anyURI(concat($staticSitePath, '/siteGenerator/components/', tokenize($sharedContent, '/')[last()])))" />
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:element name="{name(.)}" namespace="http://www.w3.org/1999/xhtml">
                    <xsl:for-each select="@*">
                        <xsl:attribute name="{name(.)}">
                            <xsl:value-of select="."/>
                        </xsl:attribute>
                    </xsl:for-each>
                    <xsl:apply-templates/>
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="html:link | html:script | html:a">
        <xsl:element name="{name()}">
            <!--<link rel="stylesheet" type="text/css" href="$nav-base/resources/css/syr-icon-fonts.css"/>-->
            <xsl:copy-of select="@*[not(local-name() = 'href')]"/>
            <xsl:if test="@href">
                <xsl:variable name="href">
                    <xsl:choose>
                        <xsl:when test="starts-with(@href, '$nav-base/')">
                            <xsl:value-of select="replace(@href, '$nav-base/', '/')"/>
                        </xsl:when>
                        <xsl:when test="not(starts-with(@href, '/'))">
                            <xsl:value-of select="concat('/', @href)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="@href"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:attribute name="href" select="$href"/>
            </xsl:if>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="rdf:Description">
        <xsl:variable name="id" select="@rdf:about"/>
        <xsl:choose>
            <xsl:when test="child::*:hasTopConcept">
                <div class="main-content-block">
                    <div class="interior-content">
                        <h1>Browse Taxonomy</h1>
                        <ul class="list-unstyled indent">
                            <xsl:for-each select="*:hasTopConcept">
                                <xsl:sort select="@rdf:resource"/>
                                <xsl:variable name="id" select="@rdf:resource"/>
                                <xsl:for-each select="//rdf:Description[@rdf:about = $id]">
                                    <xsl:sort select="*:prefLabel[@xml:lang = 'en']"/>
                                    <li>
                                        <xsl:choose>
                                            <xsl:when test="*:narrower">
                                                <xsl:variable name="uID" select="tokenize(@rdf:about, '/')[last()]"/>
                                                <a href="#" type="button" class="expandTerms" data-toggle="collapse" data-target="#view{$uID}" style="display:inline-block;margin:.5em .75em;">
                                                    <span class="glyphicon glyphicon-plus-sign"/>
                                                </a>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <a href="#" type="button" class="expandTerms" style="display:inline-block;margin:.5em 1.25em;">
                                                  &#160; </a>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                        <a href="{concat(replace($id,$base-uri,concat($staticSitePath,'data')),'.html')}">
                                            <xsl:value-of select="*:prefLabel[@xml:lang = 'en']"/>
                                        </a>
                                        <xsl:call-template name="narrowerTerms">
                                            <xsl:with-param name="node" select="."/>
                                        </xsl:call-template>
                                    </li>
                                </xsl:for-each>
                            </xsl:for-each>
                        </ul>
                    </div>
                </div>
            </xsl:when>
            <xsl:otherwise>
                <div class="main-content-block">
                    <div class="interior-content">
                        <div class="container otherFormats"
                            xmlns="http://www.w3.org/1999/xhtml">
                            <a href="javascript:window.print();" type="button" class="btn btn-default btn-xs" id="teiBtn" data-toggle="tooltip" title="Click to send this page to the printer.">
                                <span class="glyphicon glyphicon-print" aria-hidden="true"/>
                            </a>
                            <xsl:text>&#160;</xsl:text>
                            <!-- WS:NOTE needs work on the link.  -->
                            <a href="{concat($dataPath,'.rdf')}" class="btn btn-default btn-xs" id="teiBtn" data-toggle="tooltip" title="Click to view the RDF-XML data for this record.">
                                <span class="glyphicon glyphicon-download-alt" aria-hidden="true"/>
                                RDF/XML </a>
                            <xsl:text>&#160;</xsl:text>

                        </div>
                        <div class="row">
                            <div class="col-md-7 col-lg-8">
                                <div class="title">
                                    <h1>
                                        <span id="title">
                                            <xsl:value-of select="*:prefLabel[@xml:lang = 'en']"/>
                                            <xsl:if test="*:prefLabel[@xml:lang = 'syr']">
                                                <xsl:text> - </xsl:text>
                                                <xsl:value-of select="*:prefLabel[@xml:lang = 'syr']"/>
                                            </xsl:if>
                                        </span>
                                    </h1>
                                </div>
                                <div class="idno seriesStmt" style="margin:0; margin-top:.25em; margin-bottom: 1em; padding:1em; color: #999999;">
                                    <small>
                                        <span class="uri">
                                            <button type="button" class="btn btn-default btn-xs" id="idnoBtn" data-clipboard-action="copy" data-clipboard-target="#syriaca-id">
                                                <span class="srp-label">URI</span>
                                            </button>
                                            <span id="syriaca-id">
                                                <xsl:value-of select="$id"/>
                                            </span>
                                            <script>
                                            var clipboard = new Clipboard('#idnoBtn');
                                            clipboard.on('success', function(e) {
                                            console.log(e);
                                            });
                                            
                                            clipboard.on('error', function(e) {
                                            console.log(e);
                                            });
                                            </script>
                                        </span>
                                    </small>
                                    <div>
                                        <xsl:if test="*:scopeNote[@xml:lang = 'en']">
                                            <h3>Scope Note</h3>
                                            <p class="indent">
                                                <xsl:apply-templates select="*:scopeNote[@xml:lang = 'en']"/>
                                            </p>
                                        </xsl:if>
                                        <h3>Label(s)</h3>
                                        <xsl:for-each-group select="*:prefLabel" group-by="@xml:lang">
                                            <h4>
                                                <xsl:value-of select="local:expand-lang(current-grouping-key(), '')" />
                                            </h4>
                                            <p class="indent">
                                                <xsl:for-each select="current-group()">
                                                    <xsl:value-of select="."/>
                                                    <xsl:if test="position() != last()">
                                                        <xsl:text>, </xsl:text>
                                                    </xsl:if>
                                                </xsl:for-each>
                                            </p>
                                        </xsl:for-each-group>
                                        <xsl:if test="*:altLabel">
                                            <h3>Alternate Label(s)</h3>
                                            <xsl:for-each-group select="*:altLabel" group-by="@xml:lang">
                                                <h4>
                                                    <xsl:value-of select="local:expand-lang(current-grouping-key(), '')" />
                                                </h4>
                                                <p class="indent">
                                                    <xsl:for-each select="current-group()">
                                                        <xsl:value-of select="."/>
                                                        <xsl:if test="position() != last()">
                                                            <xsl:text>, </xsl:text>
                                                        </xsl:if>
                                                    </xsl:for-each>
                                                </p>
                                            </xsl:for-each-group>
                                        </xsl:if>
                                    </div>
                                </div>
                            </div>
                            <div class="col-md-5 col-lg-4 right-menu">
                                <xsl:if test="*:broader">
                                    <h4>Broader</h4>
                                    <ul>
                                        <xsl:for-each select="*:broader">
                                            <xsl:variable name="broaderID" select="@rdf:resource"/>
                                            <xsl:for-each select="//rdf:Description[@rdf:about = $broaderID]">
                                                <li>
                                                    <a href="{concat(replace($broaderID,$base-uri,concat($staticSitePath,'data')),'.html')}">
                                                        <xsl:value-of select="*:prefLabel[@xml:lang = 'en']"/>
                                                    </a>
                                                </li>
                                            </xsl:for-each>
                                        </xsl:for-each>
                                    </ul>
                                </xsl:if>
                                <xsl:if test="*:narrower">
                                    <h4>Narrower</h4>
                                    <ul>
                                        <xsl:for-each select="*:narrower">
                                            <xsl:variable name="narrowerID" select="@rdf:resource"/>
                                            <xsl:for-each select="//rdf:Description[@rdf:about = $narrowerID]">
                                                <li>
                                                    <a href="{concat(replace($narrowerID,$base-uri,concat($staticSitePath,'data')),'.html')}">
                                                        <xsl:value-of select="*:prefLabel[@xml:lang = 'en']"/>
                                                    </a>
                                                </li>
                                            </xsl:for-each>
                                        </xsl:for-each>
                                    </ul>
                                </xsl:if>
                                <xsl:if test="*:related">
                                    <h4>See also</h4>
                                    <ul>
                                        <xsl:for-each select="*:related">
                                            <xsl:variable name="relatedID" select="@rdf:resource"/>
                                            <xsl:for-each select="//rdf:Description[@rdf:about = $relatedID]">
                                                <li>
                                                    <a href="{concat(replace($relatedID,$base-uri,concat($staticSitePath,'data')),'.html')}">
                                                        <xsl:value-of select="*:prefLabel[@xml:lang = 'en']"/>
                                                    </a>
                                                </li>
                                            </xsl:for-each>
                                        </xsl:for-each>
                                    </ul>
                                </xsl:if>
                            </div>
                        </div>
                    </div>
                </div>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="narrowerTerms">
        <xsl:param name="node"/>
        <xsl:if test="$node/*:narrower">
            <xsl:variable name="uID" select="tokenize(@rdf:about, '/')[last()]"/>
            <ul class="collapse list-unstyled indent" id="view{$uID}">
                <xsl:for-each select="$node/*:narrower">
                    <xsl:sort select="@rdf:resource"/>
                    <xsl:variable name="termID" select="@rdf:resource"/>
                    <xsl:for-each select="//rdf:Description[@rdf:about = $termID]">
                        <li>
                            <xsl:choose>
                                <xsl:when test="*:narrower">
                                    <xsl:variable name="uID" select="tokenize(@rdf:about, '/')[last()]"/>
                                    <a href="#" type="button" class="expandTerms" data-toggle="collapse" data-target="#view{$uID}" style="display:inline-block;margin:.5em .75em;">
                                        <span class="glyphicon glyphicon-plus-sign"/>
                                    </a>
                                </xsl:when>
                                <xsl:otherwise>
                                    <a href="#" type="button" class="expandTerms" style="display:inline-block;margin:.5em 1.25em;"> &#160;
                                    </a>
                                </xsl:otherwise>
                            </xsl:choose>
                            <a href="{concat(replace($termID,$base-uri,concat($staticSitePath,'data')),'.html')}">
                                <xsl:value-of select="*:prefLabel[@xml:lang = 'en']"/>
                            </a>
                            <xsl:call-template name="narrowerTerms">
                                <xsl:with-param name="node" select="."/>
                            </xsl:call-template>
                        </li>
                    </xsl:for-each>
                </xsl:for-each>
            </ul>
        </xsl:if>
    </xsl:template>

    <xsl:template name="otherDataFormats">
        <xsl:param name="node"/>
        <xsl:param name="formats"/>
        <xsl:param name="idno"/>
        <!-- WS: Needs work -->
        <xsl:variable name="teiRec" select="document-uri(root($node))"/>
        <xsl:variable name="dataPath" select="substring-before(concat($staticSitePath, '/data/', replace($resource-path, $dataPath, '')), '.xml')"/>
        <xsl:if test="$formats != ''">
            <div class="container otherFormats"
                xmlns="http://www.w3.org/1999/xhtml">
                <xsl:for-each select="tokenize($formats, ',')">
                    <xsl:choose>
                        <xsl:when test=". = 'geojson'">
                            <a href="{concat($dataPath,'.geojson')}" class="btn btn-default btn-xs" id="teiBtn" data-toggle="tooltip" title="Click to view the GeoJSON data for this record.">
                                <span class="glyphicon glyphicon-download-alt" aria-hidden="true"/>
                                GeoJSON </a>
                            <xsl:text>&#160;</xsl:text>
                        </xsl:when>
                        <xsl:when test=". = 'json'">
                            <a href="{concat($dataPath,'.json')}" class="btn btn-default btn-xs" id="teiBtn" data-toggle="tooltip" title="Click to view the GeoJSON data for this record.">
                                <span class="glyphicon glyphicon-download-alt" aria-hidden="true"/>
                                JSON-LD </a>
                            <xsl:text>&#160;</xsl:text>
                        </xsl:when>
                        <xsl:when test=". = 'kml'">
                            <xsl:if test="$node/descendant::t:location/t:geo">
                                <a href="{concat($dataPath,'.kml')}" class="btn btn-default btn-xs" id="teiBtn" data-toggle="tooltip" title="Click to view the KML data for this record.">
                                    <span class="glyphicon glyphicon-download-alt" aria-hidden="true"/>
 KML </a>
                                <xsl:text>&#160;</xsl:text>
                            </xsl:if>
                        </xsl:when>
                        <xsl:when test=". = 'print'">
                            <a href="javascript:window.print();" type="button" class="btn btn-default btn-xs" id="teiBtn" data-toggle="tooltip" title="Click to send this page to the printer.">
                                <span class="glyphicon glyphicon-print" aria-hidden="true"/>
                            </a>
                            <xsl:text>&#160;</xsl:text>
                        </xsl:when>
                        <xsl:when test=". = 'rdf'">
                            <a href="{concat($dataPath,'.rdf')}" class="btn btn-default btn-xs" id="teiBtn" data-toggle="tooltip" title="Click to view the RDF-XML data for this record.">
                                <span class="glyphicon glyphicon-download-alt" aria-hidden="true"/>
                                RDF/XML </a>
                            <xsl:text>&#160;</xsl:text>
                        </xsl:when>
                        <xsl:when test=". = 'tei'">
                            <a href="{concat($teiRec,'.tei')}" class="btn btn-default btn-xs" id="teiBtn" data-toggle="tooltip" title="Click to view the TEI XML data for this record.">
                                <span class="glyphicon glyphicon-download-alt" aria-hidden="true"/>
                                TEI/XML </a>
                            <xsl:text>&#160;</xsl:text>
                        </xsl:when>
                        <xsl:when test=". = 'text'">
                            <a href="{concat($dataPath,'.txt')}" class="btn btn-default btn-xs" id="teiBtn" data-toggle="tooltip" title="Click to view the plain text data for this record.">
                                <span class="glyphicon glyphicon-download-alt" aria-hidden="true"/>
                                Text </a>
                            <xsl:text>&#160;</xsl:text>
                        </xsl:when>
                        <xsl:when test=". = 'citations'">
                            <xsl:variable name="zoteroGrp" select="$config/descendant::*:zotero/@group"/>
                            <xsl:if test="$zoteroGrp != ''"> (                                <a href="{concat('https://api.zotero.org/groups/',$zoteroGrp,'/items/',tokenize($idno,'/')[last()])}" class="btn btn-default btn-xs" id="citationsBtn" data-toggle="tooltip" title="Click for additional Citation Styles.">
                                    <span class="glyphicon glyphicon-th-list" aria-hidden="true"/>
                                    Cite </a>
                                <xsl:text>&#160;</xsl:text>
                            </xsl:if>
                        </xsl:when>
                    </xsl:choose>
                </xsl:for-each>
            </div>
        </xsl:if>
    </xsl:template>
    <xsl:template name="genericTEIPage">
        <xsl:param name="config"/>
        <xsl:param name="repository-title"/>
        <xsl:param name="collection-title"/>
        <xsl:param name="idno"/>
        <div xmlns="http://www.w3.org/1999/xhtml">
            <div class="main-content-block">
                <div class="interior-content">
                    <xsl:call-template name="otherDataFormats">
                        <xsl:with-param name="node" select="t:TEI"/>
                        <xsl:with-param name="idno" select="$idno"/>
                        <!--                        <xsl:with-param name="formats" select="'print,tei,rdf,text'"/>-->
                        <xsl:with-param name="formats" select="'print,tei'"/>
                    </xsl:call-template>
                    <div class="row">
                        <div class="col-md-7 col-lg-8">
                            <xsl:apply-templates select="t:TEI"/>
                            <!--
                            <xsl:apply-templates select="t:TEI">
                                <xsl:with-param name="config" select="$config"/>
                                <xsl:with-param name="repository-title" select="$repository-title"/>
                                <xsl:with-param name="collection-title" select="$collection-title"/>
                            </xsl:apply-templates>
                            -->
                        </div>
                        <div class="col-md-5 col-lg-4 right-menu">
                            <!-- Make dynamic -->
                            <!-- WS:ToDo Maps -->
                            <xsl:choose>
                                <xsl:when test="descendant::t:geo">
                                    <xsl:call-template name="leafletMap">
                                        <xsl:with-param name="nodes" select="/t:TEI"/>
                                    </xsl:call-template>
                                </xsl:when>
                                <!-- Maps for related places -->

                            </xsl:choose>
                            <br/>
                            <!-- WS:Note need to wait for RDF, not sure how to resolve paths to files from URI, they are not dependable paths (NHSL for example) -->
                            <!-- 
                            <xsl:choose>
                                <xsl:when test="descendant::t:relation">
                                    <xsl:call-template name="leafletMap">
                                        <xsl:with-param name="nodes" select="/t:TEI"/>
                                    </xsl:call-template>
                                </xsl:when>
                            </xsl:choose>
                            -->
                            <!-- Relationsips listed in the TEI record  display: list/sentence -->
                            <!-- WS:ToDo Relationships -->
                            <!--                            <div data-template="app:internal-relationships" data-template-label="Internal Relationships"/>-->
                            <!-- Relationships referencing this TEI record -->
                            <!--                    <div data-template="app:external-relationships" data-template-label="External Relationships"/>    -->
                        </div>
                    </div>
                </div>
            </div>
            <!-- Modal email form-->
            <!-- WS:ToDo Contact form?  -->
            <!--            <div data-template="app:contact-form" data-template-collection="places"/>-->
            <xsl:if test="t:TEI/descendant::t:geo">
                <script type="text/javascript" src="/resources/leaflet/leaflet.js"/>
                <script type="text/javascript" src="/resources/js/maps.js"/>
            </xsl:if>
        </div>
    </xsl:template>
    <xsl:template name="genericHeader">
        <head xmlns="http://www.w3.org/1999/xhtml">
            <title>Generic Header: <xsl:value-of select="$resource-title"/>
            </title>
            <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
            <meta name="DC.type" property="dc.type" content="Text"/>
            <meta name="DC.isPartOf" property="dc.ispartof" content="{$config/html:title[1]}"/>
            <link rel="shortcut icon" href="/resources/images/fav-icons/syriaca-favicon.ico"/>
            <!-- Bootstrap 3 -->
            <link rel="stylesheet" type="text/css" href="/resources/bootstrap-5.3.6/css/bootstrap.min.css"/>
            <link rel="stylesheet" type="text/css" href="/resources/css/sm-core-css.css"/>
            <!-- Srophe styles -->
            <link rel="stylesheet" type="text/css" href="/resources/css/syr-icon-fonts.css"/>
            <link rel="stylesheet" type="text/css" href="/resources/css/style.css"/>
            <link rel="stylesheet" type="text/css" href="/resources/css/syriaca.css"/>
            <link rel="stylesheet" type="text/css" href="/resources/css/slider.css"/>
            <link rel="stylesheet" type="text/css" href="/resources/css/lightslider.css"/>
            <link rel="stylesheet" type="text/css" media="print" href="/resources/css/print.css"/>
            <!-- Leaflet -->
            <link rel="stylesheet" href="/resources/leaflet/leaflet.css"/>
            <link rel="stylesheet" href="/resources/leaflet/leaflet.awesome-markers.css"/>
            <script defer="defer" data-domain="syriaca.org" src="https://plausible.io/js/plausible.js"/>
            <!-- JQuery -->
            <link href="/resources/jquery-ui/jquery-ui.min.css" rel="stylesheet"/>
            <script type="text/javascript" src="/resources/js/jquery.min.js"/>
            <script type="text/javascript" src="/resources/jquery-ui/jquery-ui.min.js"/>
            <script type="text/javascript" src="/resources/js/jquery.smartmenus.min.js"/>
            <script type="text/javascript" src="/resources/js/clipboard.min.js"/>
            <!-- Bootstrap -->
            <script type="text/javascript" src="/resources/bootstrap-5.3.6/js/bootstrap.min.js"/>
            <!-- ReCaptcha -->
            <script src="https://www.google.com/recaptcha/api.js" type="text/javascript" async="async" defer="defer"/>
        </head>
    </xsl:template>
    <xsl:template name="genericNav">
        <nav class="navbar navbar-expand-lg bg-body-tertiary p-3 justify-content-between align-items-center"  xmlns="http://www.w3.org/1999/xhtml" role="navigation">
            <div class="container-fluid">
                <a class="navbar-brand banner-container" href="/index.html">
                    <span class="syriaca-icon syriaca-syriaca banner-icon"></span>
                    <span class="banner-text" data-template="config:app-title">SPEAR<span class="d-none d-md-inline">: Syriac Persons Events and Relations</span
            >                    </span
          >
                </a>
                <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNavAltMarkup" aria-controls="navbarNavAltMarkup" aria-expanded="false" aria-label="Toggle navigation">
                    <span class="navbar-toggler-icon"></span>
                </button>
                <div class="collapse navbar-collapse justify-content-end" id="navbarNavAltMarkup">
                    <div class="navbar-nav">
                        <!-- <xsl:call-template name="syriacaSharedLinks"/> -->
                        <a class="nav-link" aria-current="page" href="/">Home</a>
                        <a class="nav-link active" href="/browse.html">Browse</a>
                        <a class="nav-link" href="/documentation.html">Documentation</a>
                        <a class="nav-link" href="/about.html">About</a>
                        <a class="nav-link" href="/contact.html">Contact Us</a>
                    </div>
                </div>
            </div>
        </nav>
    </xsl:template>
    <xsl:template name="syriacaSharedLinks">
        <xsl:if test="doc-available(concat($applicationPath, '/', 'templates/shared-links.html'))">
            <xsl:copy-of select="doc(concat($applicationPath, '/', 'templates/shared-links.html'))" />
        </xsl:if>
    </xsl:template>

</xsl:stylesheet>
