<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:s="http://syriaca.org" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:x="http://www.w3.org/1999/xhtml" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:saxon="http://saxon.sf.net/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:local="http://syriaca.org/ns" exclude-result-prefixes="xs t s saxon" version="2.0">

    <!-- ================================================================== 
       Copyright 2013 New York University 
       
       This file is part of the Syriac Reference Portal Places Application.
       
       The Syriac Reference Portal Places Application is free software: 
       you can redistribute it and/or modify it under the terms of the GNU 
       General Public License as published by the Free Software Foundation, 
       either version 3 of the License, or (at your option) any later 
       version.
       
       The Syriac Reference Portal Places Application is distributed in 
       the hope that it will be useful, but WITHOUT ANY WARRANTY; without 
       even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
       PARTICULAR PURPOSE.  See the GNU General Public License for more 
       details.
       
       You should have received a copy of the GNU General Public License
       along with the Syriac Reference Portal Places Application.  If not,
       see (http://www.gnu.org/licenses/).
       
       ================================================================== -->

    <!-- ================================================================== 
       spear.xsl
       
       This XSLT transforms tei.xml to html for SPEAR content.
       
       parameters:
       
        
       code by: 
        + Winona Salesky (wsalesky@gmail.com)
          for use with eXist-db
        + Tom Elliott (http://www.paregorios.org) 
          for the Institute for the Study of the Ancient World, New York
          University, under contract to Vanderbilt University for the
          NEH-funded Syriac Reference Portal project.
        + Winona Salesky for use with eXist-db
          
       funding provided by:
        + National Endowment for the Humanities (http://www.neh.gov). Any 
          views, findings, conclusions, or recommendations expressed in 
          this code do not necessarily reflect those of the National 
          Endowment for the Humanities.
       
       ================================================================== -->

    <!-- =================================================================== -->
    <!-- TEMPLATES -->
    <!-- =================================================================== -->
    
    <xsl:template name="spearDates">
        <xsl:if test="@when or @notBefore or @notAfter or @from or @to">
            <span class="element"><span class="spearLabel">Date:</span> 
                <xsl:choose>
                    <xsl:when test="@when"><xsl:value-of select="@when"/></xsl:when>
                    <xsl:when test="@notBefore and @notAfter">Sometime between <xsl:value-of select="@notBefore"/> and <xsl:value-of select="@notAfter"/></xsl:when>
                    <xsl:when test="@notBefore and not(@notAfter)">Not before <xsl:value-of select="@notBefore"/></xsl:when>
                    <xsl:when test="@notAfter and not(@notBefore)">No later than <xsl:value-of select="@notAfter"/></xsl:when>
                    <xsl:when test="@from and @to">From <xsl:value-of select="@from"/> to <xsl:value-of select="@to"/></xsl:when>
                    <xsl:when test="@from and not(@to)">From <xsl:value-of select="@from"/></xsl:when>
                    <xsl:when test="@to and not(@from)">To <xsl:value-of select="@to"/></xsl:when>
                </xsl:choose>
            </span>
        </xsl:if>
    </xsl:template>
    <xsl:template name="spearCertainty">
        <!-- Certainty (zero or one, ab/note[@type=’certainty’]/subtype): dubia* | errata* | incerta*
             If possible, hyperlink the word after the colon to the matching section heading below.
        
        WS:Note: need test data, did not find any of these notes in the data
        -->
        <xsl:if test="t:note[@type='certainty']">
            <span class="element"><span class="spearLabel">Certainty:</span> <a href="#{@subtype}"><xsl:value-of select="@subtype"/></a></span>
        </xsl:if>
    </xsl:template>
    <xsl:template name="spearCite">
        <div class="citation">
            <h4>How to cite:</h4>
            <span class="element">
                <xsl:variable name="editorssourcedoc">
                    <xsl:if test="doc-available(concat('xmldb:exist://',$app-root,'/documentation/editors.xml'))">
                        <xsl:sequence select="doc(concat('xmldb:exist://',$app-root,'/documentation/editors.xml'))"/>
                    </xsl:if>
                </xsl:variable>
                <xsl:variable name="docEditors" select="/tei:TEI/descendant::tei:titleStmt/tei:editor"/>
                <xsl:variable name="respCount" select="count(tokenize(@resp,' '))"/>
                <xsl:for-each select="tokenize(@resp,' ')">
                    <xsl:variable name="persID" select="substring-after(.,'#')"/>
                    <xsl:choose>
                        <xsl:when test="$editorssourcedoc/descendant-or-self::tei:person[@xml:id = $persID]">
                            <xsl:value-of select="string-join($editorssourcedoc/descendant-or-self::tei:person[@xml:id = $persID]//text(), ' ')"/>
                        </xsl:when>
                        <xsl:when test="$docEditors[@ref = concat('http://syriaca.org/documentation/editors.xml#',$persID)]">
                            <xsl:value-of select="$docEditors[@ref = concat('http://syriaca.org/documentation/editors.xml#',$persID)]"/>
                        </xsl:when>
                        <xsl:otherwise/>
                    </xsl:choose>
                    <xsl:if test="position() != last()">
                        <xsl:choose>
                            <xsl:when test="$respCount = 2"><xsl:text> and </xsl:text></xsl:when>
                            <xsl:otherwise><xsl:text>, </xsl:text></xsl:otherwise>
                        </xsl:choose>    
                    </xsl:if>
                    <xsl:if test="position() = last()"><xsl:text>, </xsl:text></xsl:if>
                </xsl:for-each>
                <a href="{t:idno[@type='URI']}"><xsl:value-of select="t:idno[@type='URI']"/></a><xsl:text>, </xsl:text>
                <xsl:if test="ancestor-or-self::t:TEI/descendant::t:seriesStmt/t:title[@level='m']"><xsl:text>in </xsl:text><xsl:apply-templates select="ancestor-or-self::t:TEI/descendant::t:seriesStmt/t:title[@level='m']"/><xsl:text>, </xsl:text></xsl:if>
                <xsl:if test="ancestor-or-self::t:TEI/descendant::t:seriesStmt[t:title[@level='m']]/t:editor"><xsl:text>edited by </xsl:text><xsl:apply-templates select="ancestor-or-self::t:TEI/descendant::t:seriesStmt[t:title[@level='m']]/t:editor"/><xsl:text>, </xsl:text></xsl:if>
                <xsl:text>general editor </xsl:text> <xsl:apply-templates select="ancestor-or-self::t:TEI/descendant::t:seriesStmt[t:title[@level='s']]/t:editor"/><xsl:text>, </xsl:text><xsl:value-of select="current-date()"/><xsl:text>.</xsl:text>
            </span>
        </div>
     </xsl:template>
    <xsl:template name="spearSources">
        <div class="sources">
            <h4>Sources:</h4>
            <span class="element" id="sources">
                <!-- 
                WS:Note will need to make it look up Syriaca.org bibl items and return and process info. 
                -->
                <ul>
                    <xsl:for-each select="descendant::t:bibl">
                        <xsl:sort select="if(contains(@xml:id,'-')) then xs:integer(translate(substring-after(@xml:id,'-'),translate(substring-after(@xml:id,'-'), '0123456789', ''), '')) else position()"/>
                        <xsl:apply-templates select="." mode="footnote"/>
                    </xsl:for-each>
                </ul>
            </span>
        </div>
    </xsl:template>
    <xsl:template name="factoidHeader">
        <h3>
            <xsl:choose>
                <xsl:when test="@subtype='relation'">
                    Relation Factoid
                </xsl:when>
                <xsl:when test="@subtype='event'">
                    Event Factoid
                </xsl:when>
                <xsl:otherwise>
                    Person Factoid 
                </xsl:otherwise>
            </xsl:choose>
        </h3>
        <small>
            <span class="uri">
                <button type="button" class="btn btn-default btn-xs" id="idnoBtn" data-clipboard-action="copy" data-clipboard-target="#syriaca-id">
                    <span class="srp-label">URI</span>
                </button>
                <xsl:text> </xsl:text>
                <span id="syriaca-id">
                    <xsl:value-of select="tei:idno"/>
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
    </xsl:template>
    <xsl:template name="refs">
        <xsl:variable name="refIndexs" select="doc('/db/apps/spear/resources/indexes/keywordIndex.xml') | doc('/db/apps/spear/resources/indexes/personsIndex.xml') | doc('/db/apps/spear/resources/indexes/placesIndex.xml')"/>
        <xsl:for-each-group select="//t:ab//@ref | //t:ab//@ana" group-by="tokenize(.,'/')[4]">
            <xsl:if test="contains(current-grouping-key(),'person') or contains(current-grouping-key(),'place') or contains(current-grouping-key(),'keyword')">
                <xsl:variable name="refs" select="current-group()"/>
                <h4>Related <xsl:value-of select="current-grouping-key()"/>(s)</h4>
                <ul>
                    <xsl:for-each select="distinct-values($refs/tokenize(.,' '))">
                        <xsl:variable name="ref" select="."/>
                        <xsl:variable name="title" select="$refIndexs//t:idno[. = $ref]/parent::*/t:title[1]/descendant-or-self::text()"/>
                        <xsl:variable name="titleString">
                            <xsl:choose>
                                <xsl:when test="not(empty($title))"><xsl:value-of select="$title"/></xsl:when>
                                <xsl:otherwise><xsl:value-of select="replace(concat(upper-case(substring(tokenize(.,'/')[last()],1,1)),substring(tokenize(.,'/')[last()],2)),'_',' ')"/></xsl:otherwise>
                            </xsl:choose>
                        </xsl:variable>
                        <xsl:variable name="url">
                            <xsl:value-of select="concat('$nav-base/aggregate/',tokenize(.,'/')[4],'/',tokenize(.,'/')[last()],'.html')"/>
                        </xsl:variable>
                        <li><a href="{$url}">
                            <span class="loadRDF getLabel" data-rdfRef="{$ref}"/>
                            <xsl:value-of select="$titleString"/>
                            </a>
                        </li>
                    </xsl:for-each>
                </ul>
            </xsl:if>
        </xsl:for-each-group>
    </xsl:template>
    <!-- New SPEAR -->
    <xsl:template match="t:ab" mode="factoid">  
        <div class="row gx-5">
            <div class="col-12">
                <xsl:call-template name="factoidHeader"/>
            </div>
            <div class="col-md-8">
                <xsl:choose>
                    <xsl:when test="@subtype='nameVariant'">
                        <div class="factoid">
                            <xsl:for-each select="t:listPerson/t:person/t:persName[@when or @notBefore or @notAfter or @from or @to]">
                                <xsl:call-template name="spearDates"/>
                            </xsl:for-each>
                            <xsl:call-template name="spearCertainty"/>
                            <xsl:for-each select="t:listPerson/t:person">
                                <span class="element"><span class="spearLabel">Name Variant: </span> <xsl:apply-templates mode="spear"/></span>
                            </xsl:for-each>
                            <xsl:for-each select="t:listPerson/personGrp">
                                <span class="element"><span class="spearLabel">Name Variant: </span> <xsl:apply-templates mode="spear"/></span>
                            </xsl:for-each>
                            <xsl:for-each select="descendant-or-self::t:note[not(@type='certainty')]">
                                <span class="element"><span class="spearLabel">Social Rank: </span> <xsl:apply-templates mode="spear"/></span>
                            </xsl:for-each>
                            <xsl:apply-templates select="t:desc" mode="spear"/>  
                        </div>   
                    </xsl:when>
                    <xsl:when test="@subtype='socecStatus'">
                        <div class="factoid">
                            <xsl:for-each select="//t:socecStatus[@when or @notBefore or @notAfter or @from or @to]">
                                <xsl:call-template name="spearDates"/>
                            </xsl:for-each>
                            <xsl:call-template name="spearCertainty"/>
                            <xsl:for-each select="//t:socecStatus/t:note[not(@type='certainty')]">
                                <span class="element"><span class="spearLabel">Social Rank: </span> <xsl:apply-templates mode="spear"/></span>
                            </xsl:for-each>
                            <xsl:apply-templates select="t:desc" mode="spear"/>  
                        </div>
                    </xsl:when>
                    <xsl:when test="@subtype='sanctity'">
                        <div class="factoid">
                            <xsl:for-each select="//t:state[@when or @notBefore or @notAfter or @from or @to]">
                                <xsl:call-template name="spearDates"/>
                            </xsl:for-each>
                            <xsl:call-template name="spearCertainty"/>
                            <xsl:for-each select="//t:state/t:note">
                                <span class="element"><span class="spearLabel">Sanctity: </span> <xsl:apply-templates mode="spear"/></span>
                            </xsl:for-each>
                            <xsl:apply-templates select="t:desc" mode="spear"/>  
                        </div>
                    </xsl:when>
                    <xsl:when test="@subtype='residence'">
                        <div class="factoid">
                            <xsl:for-each select="//t:residence[@when or @notBefore or @notAfter or @from or @to]">
                                <xsl:call-template name="spearDates"/>
                            </xsl:for-each>
                            <xsl:call-template name="spearCertainty"/>
                            <xsl:for-each select="//t:residence/t:note">
                                <span class="element"><span class="spearLabel">Residence: </span> <xsl:apply-templates mode="spear"/></span>
                            </xsl:for-each>
                            <xsl:apply-templates select="t:desc" mode="spear"/> 
                        </div>
                    </xsl:when>
                    <xsl:when test="@subtype='relation'">
                        <div class="factoid">
                            <xsl:for-each select="//t:relation[@type='person']/t:date[@when or @notBefore or @notAfter or @from or @to]">
                                <xsl:call-template name="spearDates"/>
                            </xsl:for-each>
                            <xsl:call-template name="spearCertainty"/>
                            <xsl:for-each select="//t:relation[@type='person']/t:desc">
                                <span class="element"><span class="spearLabel">Relationship: </span> <xsl:apply-templates mode="spear"/></span>
                            </xsl:for-each>
                            <xsl:apply-templates select="t:desc" mode="spear"/> 
                        </div>
                    </xsl:when>
                    <xsl:when test="@subtype='physicalTrait'">
                        <div class="factoid">
                            <xsl:for-each select="//t:trait[@when or @notBefore or @notAfter or @from or @to]">
                                <xsl:call-template name="spearDates"/>
                            </xsl:for-each>
                            <xsl:call-template name="spearCertainty"/>
                            <xsl:for-each select="//t:trait/t:note">
                                <span class="element"><span class="spearLabel">Physical Trait: </span> <xsl:apply-templates mode="spear"/></span>
                            </xsl:for-each>
                            <xsl:apply-templates select="t:desc" mode="spear"/> 
                        </div>
                    </xsl:when>
                    <xsl:when test="@subtype='occupation'">
                        <div class="factoid">
                            <xsl:for-each select="//t:occupation[@when or @notBefore or @notAfter or @from or @to]">
                                <xsl:call-template name="spearDates"/>
                            </xsl:for-each>
                            <xsl:call-template name="spearCertainty"/>
                            <xsl:for-each select="//t:occupation/t:note">
                                <span class="element"><span class="spearLabel">Citizenship: </span> <xsl:apply-templates mode="spear"/></span>
                            </xsl:for-each>
                            <xsl:apply-templates select="t:desc" mode="spear"/> 
                        </div>
                    </xsl:when>
                    <xsl:when test="@subtype='mentalState'">
                        <div class="factoid">
                            <xsl:for-each select="//t:state[@when or @notBefore or @notAfter or @from or @to]">
                                <xsl:call-template name="spearDates"/>
                            </xsl:for-each>
                            <xsl:call-template name="spearCertainty"/>
                            <xsl:for-each select="//t:state/t:note">
                                <span class="element"><span class="spearLabel">Mental State: </span> <xsl:apply-templates mode="spear"/></span>
                            </xsl:for-each>
                            <xsl:apply-templates select="t:desc" mode="spear"/> 
                        </div>
                    </xsl:when>
                    <xsl:when test="@subtype='langKnown'">
                        <div class="factoid">
                            <xsl:for-each select="//t:langKnown[@when or @notBefore or @notAfter or @from or @to]">
                                <xsl:call-template name="spearDates"/>
                            </xsl:for-each>
                            <xsl:call-template name="spearCertainty"/>
                            <xsl:for-each select="//t:langKnown/t:note">
                                <span class="element"><span class="spearLabel">Language Known: </span> <xsl:apply-templates mode="spear"/></span>
                            </xsl:for-each>
                            <xsl:apply-templates select="t:desc" mode="spear"/>
                        </div>            
                    </xsl:when>
                    <xsl:when test="@subtype='gender'">
                        <div class="factoid">
                            <xsl:for-each select="//t:trait[@when or @notBefore or @notAfter or @from or @to]">
                                <xsl:call-template name="spearDates"/>
                            </xsl:for-each>
                            <xsl:call-template name="spearCertainty"/>
                            <xsl:for-each select="//t:trait/t:note">
                                <span class="element"><span class="spearLabel">Gender: </span> <xsl:apply-templates mode="spear"/></span>
                            </xsl:for-each>
                            <xsl:apply-templates select="t:desc" mode="spear"/> 
                        </div>
                    </xsl:when>
                    <xsl:when test="@subtype='event'">
                        <div class="factoid">
                            <xsl:for-each select="//t:event[@when or @notBefore or @notAfter or @from or @to]">
                                <xsl:call-template name="spearDates"/>
                            </xsl:for-each>
                            <xsl:call-template name="spearCertainty"/>
                            <xsl:for-each select="//t:event/t:desc">
                                <span class="element"><span class="spearLabel">Event Factoid: </span> <xsl:apply-templates mode="spear"/></span>
                            </xsl:for-each>            
                        </div>
                    </xsl:when>
                    <xsl:when test="@subtype='ethnicLabel'">
                        <div class="factoid">
                            <xsl:for-each select="//t:trait[@when or @notBefore or @notAfter or @from or @to]">
                                <xsl:call-template name="spearDates"/>
                            </xsl:for-each>
                            <xsl:call-template name="spearCertainty"/>
                            <xsl:for-each select="//t:trait/t:note">
                                <span class="element"><span class="spearLabel">Ethnic Label: </span> <xsl:apply-templates mode="spear"/></span>
                            </xsl:for-each>            
                        </div>
                    </xsl:when>
                    <xsl:when test="@subtype='education'">
                        <div class="factoid">
                            <xsl:for-each select="//t:education[@when or @notBefore or @notAfter or @from or @to]">
                                <xsl:call-template name="spearDates"/>
                            </xsl:for-each>
                            <xsl:call-template name="spearCertainty"/>
                            <xsl:for-each select="//t:education/t:note">
                                <span class="element"><span class="spearLabel">Education: </span> <xsl:apply-templates mode="spear"/></span>
                            </xsl:for-each>            
                        </div>
                    </xsl:when>
                    <xsl:when test="@subtype='death'">
                        <div class="factoid">
                            <xsl:for-each select="//t:death/t:date[@when or @notBefore or @notAfter or @from or @to]">
                                <xsl:call-template name="spearDates"/>
                            </xsl:for-each>
                            <xsl:call-template name="spearCertainty"/>
                            <xsl:for-each select="//t:death/t:note">
                                <span class="element"><span class="spearLabel">Death: </span> <xsl:apply-templates mode="spear"/></span>
                            </xsl:for-each>            
                        </div>
                    </xsl:when>
                    <xsl:when test="@subtype='citizenship'">
                        <div class="factoid">
                            <xsl:for-each select="//t:state[@type='citizenship'][@when or @notBefore or @notAfter or @from or @to]">
                                <xsl:call-template name="spearDates"/>
                            </xsl:for-each>
                            <xsl:call-template name="spearCertainty"/>
                            <xsl:for-each select="//t:state[@type='citizenship']/t:note">
                                <span class="element"><span class="spearLabel">Citizenship: </span> <xsl:apply-templates mode="spear"/></span>
                            </xsl:for-each>            
                        </div>
                    </xsl:when>
                    <xsl:when test="@subtype='birth'">
                        <div class="factoid">
                            <xsl:for-each select="//t:birth/t:date[@when or @notBefore or @notAfter or @from or @to]">
                                <xsl:call-template name="spearDates"/>
                            </xsl:for-each>
                            <xsl:call-template name="spearCertainty"/>
                            <xsl:for-each select="//t:birth/t:note">
                                <span class="element"><span class="spearLabel">Birth: </span> <xsl:apply-templates mode="spear"/></span>
                            </xsl:for-each>     
                        </div>
                    </xsl:when>
                    <xsl:otherwise>
                        <div class="factoid">
                            <xsl:for-each select="//t:date[@when or @notBefore or @notAfter or @from or @to]">
                                <xsl:call-template name="spearDates"/>
                            </xsl:for-each>
                            <xsl:call-template name="spearCertainty"/>
                            <xsl:choose>
                                <xsl:when test="//t:note">
                                    <xsl:for-each select="//t:note">
                                        <span class="element"><span class="spearLabel"><xsl:sequence select="concat(upper-case(substring(current-grouping-key(),1,1)),substring(current-grouping-key(), 2),' '[not(last())])"/>: </span> <xsl:apply-templates mode="spear"/></span>
                                    </xsl:for-each>  
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:for-each select="//child::*[not(self::t:bibl) and not(self::t:idno)]">
                                        <span class="element"><span class="spearLabel"><xsl:sequence select="concat(upper-case(substring(current-grouping-key(),1,1)),substring(current-grouping-key(), 2),' '[not(last())])"/>: </span> <xsl:apply-templates mode="spear"/></span>
                                    </xsl:for-each>  
                                </xsl:otherwise>
                            </xsl:choose>
                        </div>
                    </xsl:otherwise> 
                </xsl:choose>
                <xsl:if test="descendant::t:bibl[@type='urn']">
                    <xsl:for-each select="descendant::t:bibl[@type='urn']">
                        <div class="indent" style="padding-left:2em;padding-right:2em;">
                            <div class="panel panel-default">
                                <div class="panel-body">
                                    <h4>Source Text</h4>
                                    <xsl:variable name="ref" select="t:ptr/@target"/>
                                    <div class="ctsResolver" data-cts-location="https://syriaccorpus.org/" data-cts-urn="{$ref}" data-cts-format="xml"/>
                                    <span>
                                        <a href="https://syriaccorpus.org//api/cts?urn={$ref}">
                                            See full text at The Syriac Corpus <span class="glyphicon glyphicon-circle-arrow-right"> </span>
                                        </a>
                                    </span>
                                </div>
                                <script type="text/javascript" src="$nav-base/CTS/resources/js/cts.js"/>
                            </div>
                        </div>
                    </xsl:for-each>
                </xsl:if>
                <xsl:call-template name="spearSources"/>
                <xsl:for-each select="t:note[@type='certainty']">
                    <xsl:apply-templates/>
                </xsl:for-each>       
                <xsl:call-template name="spearCite"/>
            </div>
            <div class="col-md-4">
                <xsl:call-template name="refs"/>
            </div>
        </div>
    </xsl:template>
   
    <!-- General templates -->
    <xsl:template match="t:choice" mode="spear">
        <xsl:value-of select="t:orig"/> <xsl:if test="t:reg">(<xsl:value-of select="t:reg"/>)</xsl:if>
    </xsl:template>
    <xsl:template match="t:note" mode="spear">
        <h4>Note <xsl:if test="@subtype"><span class="spearLabel"><xsl:attribute name="id"><xsl:value-of select="@subtype"/></xsl:attribute><xsl:value-of select="@subtype"/>:</span></xsl:if>: </h4>
        <span class="element note">
            <xsl:apply-templates mode="spear"/>
        </span>
    </xsl:template>
    <xsl:template match="t:note" mode="aggregate">
        <xsl:apply-templates mode="spear"/>
    </xsl:template>
    <!-- OLD SPEAR -->
    <!-- Manuscript templates -->
    <!-- used by spear pages not real tei element -->
    <xsl:template match="t:aggregate-source">
        <div class="row title padding-top">
            <h1 class="col-md-8">
                <xsl:text>A Prosopography of </xsl:text>
                <xsl:call-template name="title"/>
            </h1>
        </div>
        <div style="margin:0 1em 1em; color: #999999;">
            <small>
                <a href="../documentation/terms.html#place-uri" title="Click to read more about Place URIs" class="no-print-link">
                    <span class="helper circle noprint">
                        <p>i</p>
                    </span>
                </a>
                <p>
                    <span class="srp-label">URI</span>
                    <xsl:text>: </xsl:text>
                    <span id="syriaca-id">
                        <!-- NOTE: temporary fix, the Perm URI will be found in header/sourceDesc -->
                        <xsl:value-of select="concat('http://syriaca.org/spear/aggregate.html?id=', $resource-id)"/>
                    </span>
                </p>
            </small>
        </div>
    </xsl:template>
    <xsl:template match="t:keyword-title">
        <div class="row title padding-top">
            <h1 class="col-md-8">
                <xsl:text>SPEAR Factoids about </xsl:text>
                <xsl:value-of select="substring-after(//tei:idno, '/keyword/')"/>
            </h1>
        </div>
        <div style="margin:0 1em 1em; color: #999999;">
            <small>
                <a href="../documentation/terms.html#place-uri" title="Click to read more about Place URIs" class="no-print-link">
                    <span class="helper circle noprint">
                        <p>i</p>
                    </span>
                </a>
                <p>
                    <span class="srp-label">URI</span>
                    <xsl:text>: </xsl:text>
                    <span id="syriaca-id">
                        <xsl:value-of select="$resource-id"/>
                    </span>
                </p>
            </small>
        </div>
    </xsl:template>
    <xsl:template match="t:factoid-title">
        <div class="row title padding-top">
            <h1 class="col-md-8">SPEAR Factoid </h1>
        </div>
        <div style="margin:0 1em 1em; color: #999999;">
            <xsl:variable name="current-id">
                <xsl:variable name="idString" select="tokenize($resource-id, '/')[last()]"/>
                <xsl:variable name="idSubstring" select="substring-after($idString, '-')"/>
                <xsl:choose>
                    <xsl:when test="$idSubstring castable as xs:integer">
                        <xsl:value-of select="$idSubstring cast as xs:integer"/>
                    </xsl:when>
                    <xsl:otherwise>0</xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="next-id" select="$current-id + 1"/>
            <xsl:variable name="prev-id" select="$current-id - 1"/>
            <xsl:variable name="next-uri" select="concat(substring-before($resource-id, '-'), '-', string($next-id))"/>
            <xsl:variable name="prev-uri" select="concat(substring-before($resource-id, '-'), '-', string($prev-id))"/>

            <small>
                <span class="uri">
                    <xsl:if test="starts-with($nav-base, '/exist/apps')">
                        <a href="{replace($prev-uri,$base-uri,$nav-base)}">
                            <span class="glyphicon glyphicon-backward" aria-hidden="true"/>
                        </a>
                    </xsl:if>
                    <xsl:text> </xsl:text>
                    <button type="button" class="btn btn-default btn-xs" id="idnoBtn" data-clipboard-action="copy" data-clipboard-target="#syriaca-id">
                        <span class="srp-label">URI</span>
                    </button>
                    <xsl:text> </xsl:text>
                    <span id="syriaca-id">
                        <xsl:value-of select="$resource-id"/>
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
                    <xsl:text> </xsl:text>
                    <xsl:if test="starts-with($nav-base, '/exist/apps')">
                        <a href="{replace($next-uri,$base-uri,$nav-base)}">
                            <span class="glyphicon glyphicon-forward" aria-hidden="true"/>
                        </a>
                    </xsl:if>
                </span>
            </small>
        </div>
    </xsl:template>
    <xsl:template match="t:spear-headwords">
        <xsl:call-template name="title"/>
    </xsl:template>
    <xsl:template match="t:aggregate">
        <xsl:variable name="id" select="@id"/>
        <xsl:variable name="titleString">
            <xsl:call-template name="title"/>
        </xsl:variable>
        <xsl:variable name="title">
            <xsl:choose>
                <xsl:when test="$titleString != ''"><xsl:call-template name="title"/></xsl:when>
                <xsl:when test="contains($id,'/keyword')"><xsl:value-of select="replace(tokenize($id,'/')[last()],'_',' ')"/></xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="url" select="concat('$nav-base/aggregate/',tokenize($id,'/')[4],'/',tokenize($id,'/')[last()],'.html')"/>
        <div class="padding-top">
            <h1>
                <xsl:text>SPEAR Factoids about </xsl:text>
               <xsl:sequence select="$title"/>
            </h1>
        </div>
        <!--
        <xsl:choose>
            <xsl:when test="contains($id,'/person/')">
                <h2>Person Factoids <xsl:value-of select="@title"/></h2>
            </xsl:when>
            <xsl:when test="contains($id,'/person/')">
                <h2>Place Factoids<xsl:value-of select="@title"/></h2>
            </xsl:when>
            <xsl:otherwise>
                <h2><xsl:sequence select="concat(upper-case(substring(tokenize($id)[4],1,1)),substring(tokenize($id)[4], 2),' '[not(last())])"/> Factoids</h2>
            </xsl:otherwise>
        </xsl:choose>
        -->
        <!-- Notes from syriaca.org -->
        <div>
            <xsl:apply-templates select="t:syriaca/descendant-or-self::t:note[@type='abstract']"/>
            <div style="margin:0 1em 1em; color: #999999;">
                <small>
                    <p>
                        <span class="srp-label"><strong>Syriaca.org URI</strong></span>
                        <xsl:text>: </xsl:text>
                        <span id="syriaca-id">
                            <a href="{$id}"><xsl:value-of select="$id"/></a>
                        </span>
                    </p>
                </small>
            </div>
        </div>
        <div class="row gx-5">
            <div class="col-md-8">
                <xsl:choose>
                    <xsl:when test="contains($id,'/person/')">
                        <xsl:if test="t:ab[@subtype = 'nameVariant']                             |t:ab[@subtype = 'birth']                             |t:ab[@subtype = 'death']                             |t:ab[@subtype = 'gender']                             |t:ab[@subtype = 'citizenship']                             |t:ab[@subtype = 'residence']                             |t:ab[@subtype = 'ethnicLabel']                             |t:ab[@subtype = 'sanctity']                             |t:ab[@subtype = 'occupation']                             |t:ab[@subtype = 'education']                             |t:ab[@subtype = 'socecStatus']                             |t:ab[@subtype = 'mentalState']                             |t:ab[@subtype = 'physicalTrait']">
                            <div class="sources">
                                <h3>Personal Information</h3>
                                <xsl:if test="t:ab[@subtype = 'nameVariant']">
                                    <h4>Name variant(s): </h4>
                                    <xsl:apply-templates select="t:ab[@subtype = 'nameVariant']" mode="aggregate">
                                        <xsl:sort select="@xml:id"/>
                                    </xsl:apply-templates>
                                </xsl:if>
                                <xsl:if test="t:ab[@subtype = 'birth']">
                                    <h4>Birth: </h4>
                                    <xsl:apply-templates select="t:ab[@subtype = 'birth']" mode="aggregate">
                                        <xsl:sort select="@xml:id"/>
                                    </xsl:apply-templates>
                                </xsl:if>
                                <xsl:if test="t:ab[@subtype = 'death']">
                                    <h4>Death: </h4>
                                    <xsl:apply-templates select="t:ab[@subtype = 'death']" mode="aggregate">
                                        <xsl:sort select="@xml:id"/>
                                    </xsl:apply-templates>
                                </xsl:if>
                                <xsl:if test="t:ab[@subtype = 'gender']">
                                    <h4>Sex: </h4>
                                    <xsl:apply-templates select="t:ab[@subtype = 'gender']" mode="aggregate">
                                        <xsl:sort select="@xml:id"/>
                                    </xsl:apply-templates>
                                </xsl:if>
                                <xsl:if test="t:ab[@subtype = 'citizenship']">
                                    <h4>Citizenship: </h4>
                                    <xsl:apply-templates select="t:ab[@subtype = 'citizenship']" mode="aggregate">
                                        <xsl:sort select="@xml:id"/>
                                    </xsl:apply-templates>
                                </xsl:if>
                                <xsl:if test="t:ab[@subtype = 'residence']">
                                    <h4>Place of residence: </h4>
                                    <xsl:apply-templates select="t:ab[@subtype = 'residence']" mode="aggregate">
                                        <xsl:sort select="@xml:id"/>
                                    </xsl:apply-templates>
                                </xsl:if>
                                <xsl:if test="t:ab[@subtype = 'ethnicLabel']">
                                    <h4>Ethnic Label: </h4>
                                    <xsl:apply-templates select="t:ab[@subtype = 'ethnicLabel']" mode="aggregate">
                                        <xsl:sort select="@xml:id"/>
                                    </xsl:apply-templates>
                                </xsl:if>
                                <xsl:if test="t:ab[@subtype = 'sanctity']">
                                    <h4>Sanctity: </h4>
                                    <xsl:apply-templates select="t:ab[@subtype = 'sanctity']" mode="aggregate">
                                        <xsl:sort select="@xml:id"/>
                                    </xsl:apply-templates>
                                </xsl:if>
                                <xsl:if test="t:ab[@subtype = 'occupation']">
                                    <h4>Occupation(s): </h4>
                                    <xsl:apply-templates select="t:ab[@subtype = 'occupation']" mode="aggregate">
                                        <xsl:sort select="@xml:id"/>
                                    </xsl:apply-templates>
                                </xsl:if>
                                <xsl:if test="t:ab[@subtype = 'education']">
                                    <h4>Education: </h4>
                                    <xsl:apply-templates select="t:ab[@subtype = 'education']" mode="aggregate">
                                        <xsl:sort select="@xml:id"/>
                                    </xsl:apply-templates>
                                </xsl:if>
                                <xsl:if test="t:ab[@subtype = 'socecStatus']">
                                    <h4>Social Rank: </h4>
                                    <xsl:apply-templates select="t:ab[@subtype = 'socecStatus']" mode="aggregate">
                                        <xsl:sort select="@xml:id"/>
                                    </xsl:apply-templates>
                                </xsl:if>
                                <xsl:if test="t:ab[@subtype = 'mentalState']">
                                    <h4>Mental State: </h4>
                                    <xsl:apply-templates select="t:ab[@subtype = 'mentalState']" mode="aggregate">
                                        <xsl:sort select="@xml:id"/>
                                    </xsl:apply-templates>
                                </xsl:if>
                                <xsl:if test="t:ab[@subtype = 'physicalTrait']">
                                    <h4>Physical Trait: </h4>
                                    <xsl:apply-templates select="t:ab[@subtype = 'physicalTrait']" mode="aggregate">
                                        <xsl:sort select="@xml:id"/>
                                    </xsl:apply-templates>
                                </xsl:if>
                            </div>
                        </xsl:if>
                        <xsl:if test="t:ab[@subtype = 'relation']">
                            <div class="sources">
                                <h3>Relationships</h3>
                                <xsl:apply-templates select="t:ab[@subtype = 'relation']" mode="aggregate">
                                    <xsl:sort select="@xml:id"/>
                                </xsl:apply-templates>
                            </div>
                        </xsl:if>
                        <xsl:if test="t:ab[@subtype = 'event']">
                            <div class="sources">
                                <h3>Events</h3>
                                <xsl:apply-templates select="t:ab[@subtype = 'event']" mode="aggregate">
                                    <xsl:sort select="@xml:id"/>
                                </xsl:apply-templates>
                            </div>
                        </xsl:if>    
                    </xsl:when>
                    <xsl:when test="contains($id,'/place/')">
                        <xsl:if test="t:ab[@subtype = 'event']">
                            <div class="sources">
                                <h3>Events</h3>
                                <xsl:apply-templates select="t:ab[@subtype = 'event']" mode="aggregate">
                                    <xsl:sort select="@xml:id"/>
                                </xsl:apply-templates>
                            </div>
                        </xsl:if>
                        <xsl:if test="t:ab[@subtype = 'nameVariant']                             |t:ab[@subtype = 'birth']                             |t:ab[@subtype = 'death']                             |t:ab[@subtype = 'gender']                             |t:ab[@subtype = 'citizenship']                             |t:ab[@subtype = 'residence']                             |t:ab[@subtype = 'ethnicLabel']                             |t:ab[@subtype = 'sanctity']                             |t:ab[@subtype = 'occupation']                             |t:ab[@subtype = 'education']                             |t:ab[@subtype = 'socecStatus']                             |t:ab[@subtype = 'mentalState']                             |t:ab[@subtype = 'physicalTrait']">
                            <div class="sources">
                                <xsl:if test="t:ab[@subtype = 'nameVariant']">
                                    <h4>Personal Names: </h4>
                                    <xsl:apply-templates select="t:ab[@subtype = 'nameVariant']" mode="aggregate">
                                        <xsl:sort select="@xml:id"/>
                                    </xsl:apply-templates>
                                </xsl:if>
                                <xsl:if test="t:ab[@subtype = 'birth']">
                                    <h4>Births: </h4>
                                    <xsl:apply-templates select="t:ab[@subtype = 'birth']" mode="aggregate">
                                        <xsl:sort select="@xml:id"/>
                                    </xsl:apply-templates>
                                </xsl:if>
                                <xsl:if test="t:ab[@subtype = 'death']">
                                    <h4>Deaths: </h4>
                                    <xsl:apply-templates select="t:ab[@subtype = 'death']" mode="aggregate">
                                        <xsl:sort select="@xml:id"/>
                                    </xsl:apply-templates>
                                </xsl:if>
                                <xsl:if test="t:ab[@subtype = 'citizenship']">
                                    <h4>Citizenship: </h4>
                                    <xsl:apply-templates select="t:ab[@subtype = 'citizenship']" mode="aggregate">
                                        <xsl:sort select="@xml:id"/>
                                    </xsl:apply-templates>
                                </xsl:if>
                                <xsl:if test="t:ab[@subtype = 'residence']">
                                    <h4>Residence: </h4>
                                    <xsl:apply-templates select="t:ab[@subtype = 'residence']" mode="aggregate">
                                        <xsl:sort select="@xml:id"/>
                                    </xsl:apply-templates>
                                </xsl:if>
                                <xsl:if test="t:ab[@subtype = 'sanctity']">
                                    <h4>Sanctity: </h4>
                                    <xsl:apply-templates select="t:ab[@subtype = 'sanctity']" mode="aggregate">
                                        <xsl:sort select="@xml:id"/>
                                    </xsl:apply-templates>
                                </xsl:if>
                                <xsl:if test="t:ab[@subtype = 'occupation']">
                                    <h4>Occupation(s): </h4>
                                    <xsl:apply-templates select="t:ab[@subtype = 'occupation']" mode="aggregate">
                                        <xsl:sort select="@xml:id"/>
                                    </xsl:apply-templates>
                                </xsl:if>
                                <xsl:if test="t:ab[@subtype = 'education']">
                                    <h4>Education: </h4>
                                    <xsl:apply-templates select="t:ab[@subtype = 'education']" mode="aggregate">
                                        <xsl:sort select="@xml:id"/>
                                    </xsl:apply-templates>
                                </xsl:if>
                                <xsl:if test="t:ab[@subtype = 'physicalTrait']">
                                    <h4>Physical Trait: </h4>
                                    <xsl:apply-templates select="t:ab[@subtype = 'physicalTrait']" mode="aggregate">
                                        <xsl:sort select="@xml:id"/>
                                    </xsl:apply-templates>
                                </xsl:if>
                            </div>
                        </xsl:if>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="t:ab" mode="aggregateLabels">
                            <xsl:sort select="@xml:id"/>    
                        </xsl:apply-templates>
                    </xsl:otherwise>
                </xsl:choose>
                <div class="citation">
                    <h3>How to cite:</h3>
                    <span class="element">
                        <xsl:choose>
                            <xsl:when test="contains($id,'/person/')">
                                “Person Page for <xsl:sequence select="$title"/>,” 
                                in SPEAR: Syriac Persons Events and Relations, general editor Daniel L. Schwartz, 
                                <xsl:value-of select="$url"/>, <xsl:value-of select="current-dateTime()"/>.
                            </xsl:when>
                            <xsl:when test="contains($id,'/place/')">
                                “Place Page for <xsl:sequence select="$title"/>,” 
                                in SPEAR: Syriac Persons Events and Relations, general editor Daniel L. Schwartz, 
                                <xsl:value-of select="$url"/>, <xsl:value-of select="current-dateTime()"/>.
                            </xsl:when>
                            <xsl:when test="contains($id,'/keyword/')">
                                “Keyword Page for <xsl:sequence select="$title"/>,” 
                                in SPEAR: Syriac Persons Events and Relations, general editor Daniel L. Schwartz, 
                                <xsl:value-of select="$url"/>, <xsl:value-of select="current-dateTime()"/>.
                            </xsl:when>
                        </xsl:choose>
                    </span>
                </div>
            </div>
            <div class="col-md-4">
                <xsl:call-template name="refs"/>
            </div>
        </div>
    </xsl:template>
    <xsl:template match="t:ab" mode="aggregate">
        <xsl:variable name="url" select="replace(string(t:idno),$base-uri,'\$nav-base/')"/>
        <xsl:choose>
            <xsl:when test=".[descendant::t:birth]">
                <xsl:if test="descendant::t:date">
                    <p class="indent">
                        <span class="spearLabel">Birth date: </span>
                        <xsl:apply-templates select="descendant::t:date" mode="aggregate"/>
                        <xsl:text> </xsl:text>
                        <a href="{$url}" class="factoid-more"> See factoid page <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/></a>
                    </p>
                </xsl:if>
                <xsl:if test="descendant::t:birth/t:placeName">
                    <p class="indent">
                        <span class="spearLabel">Birth place: </span>
                        <xsl:apply-templates select="descendant::t:birth/t:note" mode="aggregate"/>
                        <xsl:text> </xsl:text>
                        <a href="{$url}" class="factoid-more"> See factoid page <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/>
                        </a>
                    </p>
                </xsl:if>
            </xsl:when>
            <xsl:when test=".[descendant::t:death]">
                <xsl:if test="descendant::t:date">
                    <p class="indent">
                        <span class="spearLabel">Death date: </span>
                        <xsl:apply-templates select="descendant::t:date" mode="aggregate"/>
                        <xsl:text> </xsl:text>
                        <a href="{$url}" class="factoid-more"> See factoid page <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/></a>
                    </p>
                </xsl:if>
                <xsl:if test="descendant::t:death/t:placeName">
                    <p class="indent">
                        <span class="spearLabel">Death place: </span>
                        <xsl:apply-templates select="descendant::t:death/t:note" mode="aggregate"/>
                        <xsl:text> </xsl:text>
                        <a href="{$url}" class="factoid-more"> See factoid page <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/>
                        </a>
                    </p>
                </xsl:if>
            </xsl:when>
            <xsl:when test=".[descendant::t:state]">
                        <p class="indent">
                            <xsl:apply-templates select="descendant::t:state/t:note" mode="aggregate"/>
                            <xsl:text> </xsl:text>
                            <a href="{$url}" class="factoid-more"> See factoid page <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/>
                            </a>
                        </p>
            </xsl:when>
            <xsl:when test=".[descendant::t:trait[not(@type='gender')]]">
                        <p class="indent">
                            <xsl:apply-templates mode="spear"/>
                            <xsl:text> </xsl:text>
                            <a href="{$url}" class="factoid-more"> See factoid page <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/>
                            </a>
                        </p>
            </xsl:when>
            <xsl:otherwise>
                <p class="indent">
                    <xsl:choose>
                        <xsl:when test="descendant::t:note | descendant::t:desc">
                           <xsl:apply-templates select="descendant::t:note | descendant::t:desc" mode="aggregate"/>
                        </xsl:when>
                        <xsl:otherwise>
                           <xsl:apply-templates select="child::*[not(self::t:idno) and not(self::t:bibl)]" mode="spear"/> 
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:text> </xsl:text>
                    <a href="{$url}" class="factoid-more">See factoid page
                        <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/>
                    </a>
                </p>
                <xsl:if test="@subtype='event'"><hr/></xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:ab" mode="aggregateLabels">
        <xsl:variable name="url" select="replace(string(t:idno),$base-uri,'\$nav-base/')"/>
        <xsl:choose>
            <xsl:when test=".[descendant::t:birth]">
                <xsl:if test="descendant::t:date">
                    <p class="indent">
                        <span class="spearLabel">Birth date: </span>
                        <xsl:apply-templates select="descendant::t:date" mode="aggregate"/>
                        <xsl:text> </xsl:text>
                        <a href="{$url}" class="factoid-more"> See factoid page <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/></a>
                    </p>
                </xsl:if>
                <xsl:if test="descendant::t:birth/t:placeName">
                    <p class="indent">
                        <span class="spearLabel">Birth place: </span>
                        <xsl:apply-templates select="descendant::t:birth/t:note" mode="aggregate"/>
                        <xsl:text> </xsl:text>
                        <a href="{$url}" class="factoid-more"> See factoid page <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/>
                        </a>
                    </p>
                </xsl:if>
            </xsl:when>
            <xsl:when test=".[descendant::t:death]">
                <xsl:if test="descendant::t:date">
                    <p class="indent">
                        <span class="spearLabel">Death date: </span>
                        <xsl:apply-templates select="descendant::t:date" mode="aggregate"/>
                        <xsl:text> </xsl:text>
                        <a href="{$url}" class="factoid-more"> See factoid page <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/></a>
                    </p>
                </xsl:if>
                <xsl:if test="descendant::t:death/t:placeName">
                    <p class="indent">
                        <span class="spearLabel">Death place: </span>
                        <xsl:apply-templates select="descendant::t:death/t:note" mode="aggregate"/>
                        <xsl:text> </xsl:text>
                        <a href="{$url}" class="factoid-more"> See factoid page <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/>
                        </a>
                    </p>
                </xsl:if>
            </xsl:when>
            <xsl:when test=".[descendant::t:state]">
                <p class="indent"><span class="spearLabel"><xsl:value-of select="descendant::t:state/@type"/>: </span>
                    <xsl:apply-templates select="descendant::t:state/t:note" mode="aggregate"/>
                    <xsl:text> </xsl:text>
                    <a href="{$url}" class="factoid-more"> See factoid page <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/>
                    </a>
                </p>
            </xsl:when>
            <xsl:when test=".[descendant::t:trait[not(@type='gender')]]">
                <p class="indent"><span class="spearLabel"><xsl:value-of select="descendant::t:state/@type"/>: </span>
                    <xsl:apply-templates mode="spear"/>
                    <xsl:text> </xsl:text>
                    <a href="{$url}" class="factoid-more"> See factoid page <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/>
                    </a>
                </p>
            </xsl:when>
            <xsl:otherwise>
                <p class="indent"><span class="spearLabel"><xsl:value-of select="@subtype"/>: </span>
                    <xsl:choose>
                        <xsl:when test="descendant::t:note | descendant::t:desc">
                            <xsl:apply-templates select="descendant::t:note | descendant::t:desc" mode="aggregate"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates select="child::*[not(self::t:idno) and not(self::t:bibl)]" mode="spear"/> 
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:text> </xsl:text>
                    <a href="{$url}" class="factoid-more">See factoid page
                        <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/>
                    </a>
                </p>
                <xsl:if test="@subtype='event'"><hr/></xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:spear-teiHeader">
        <p>
            <span class="srp-label">Editor: </span>
            <xsl:value-of select="descendant::t:titleStmt/t:editor[@role = 'creator']"/>
        </p>
        <xsl:if test="descendant::t:respStmt">
            <div>
                <span class="srp-label">Contributors: </span>
                <xsl:choose>
                    <xsl:when test="count(descendant::t:respStmt) &gt; 2">
                        <xsl:value-of select="count(descendant::t:respStmt)"/> contributors ( <a class="togglelink" data-toggle="collapse" data-target="#show-contributors" href="#show-contributors" data-text-swap="Hide"> See all  <i class="glyphicon glyphicon-circle-arrow-right"/>
                        </a>) <div class="collapse" id="show-contributors">
                            <ul>
                                <xsl:for-each select="descendant::t:respStmt">
                                    <li>
                                        <xsl:apply-templates select="."/>
                                    </li>
                                </xsl:for-each>
                            </ul>
                        </div>
                    </xsl:when>
                    <xsl:otherwise>
                        <ul>
                            <xsl:for-each select="descendant::t:respStmt">
                                <li>
                                    <xsl:apply-templates select="."/>
                                </li>
                            </xsl:for-each>
                        </ul>
                    </xsl:otherwise>
                </xsl:choose>
            </div>
        </xsl:if>
        <xsl:if test="descendant::t:fileDesc/t:publicationStmt/t:date">
            <p>
                <span class="srp-label">Date of Publication: </span>
                <xsl:choose>
                    <xsl:when test="descendant::t:fileDesc/t:publicationStmt/t:date[1]/text() castable as xs:date">
                        <xsl:value-of select="format-date(xs:date(descendant::t:fileDesc/t:publicationStmt/t:date[1]), '[Y]')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="descendant::t:fileDesc/t:publicationStmt/t:date[1]"/>
                    </xsl:otherwise>
                </xsl:choose>
            </p>
        </xsl:if>
        <p>
            <span class="srp-label">Based on: </span>
            <ul class="list-unstyled indent">
                <xsl:apply-templates select="descendant::t:back/descendant::t:bibl" mode="footnote"/>
            </ul>
        </p>
    </xsl:template>
    <xsl:template match="t:spear-sources">
        <xsl:call-template name="sources"/>
    </xsl:template>
    <xsl:template match="t:spear-event">
        <xsl:apply-templates mode="spear"/>
    </xsl:template>
    <xsl:template match="tei:idno" mode="spear"/>
    <xsl:template match="t:listRelation" mode="spear">
        <xsl:apply-templates mode="spear"/>
    </xsl:template>
        
    <xsl:template match="t:relation" mode="spear">
            <xsl:apply-templates mode="spear"/>
    </xsl:template>
    <xsl:template match="t:birth | t:death" mode="spear">
        <xsl:choose>
            <xsl:when test="descendant::t:note">
                <xsl:apply-templates select="descendant::t:note" mode="spear"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates mode="spear"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:trait | t:occupation | t:socecStatus" mode="spear">
        <xsl:choose>
            <xsl:when test="t:note[@type='desc']">
               <xsl:apply-templates select="t:note[@type='desc']/node()" mode="spear"/>
            </xsl:when>
            <xsl:when test="@ana">
               <xsl:value-of select="substring-after(@ana,'/keyword/')"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:apply-templates mode="spear"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="*" mode="spear">
        <xsl:choose>
            <xsl:when test="self::t:bibl"/>
            <xsl:otherwise>
                <span class="tei-{local-name(.)}">
                    <xsl:sequence select="local:attributes(.)"/>
                    <xsl:call-template name="rend-spear"/>
                </span>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template name="rend-spear">
        <xsl:choose>
            <xsl:when test="@rend">
                <xsl:choose>
                    <xsl:when test="@rend = 'bold'">
                        <b>
                            <xsl:call-template name="ref-spear"/>
                        </b>
                    </xsl:when>
                    <xsl:when test="@rend = 'italic'">
                        <i>
                            <xsl:call-template name="ref-spear"/>
                        </i>
                    </xsl:when>
                    <xsl:when test="@rend = ('superscript','sup')">
                        <sup>
                            <xsl:call-template name="ref-spear"/>
                        </sup>
                    </xsl:when>
                    <xsl:when test="@rend = ('subscript','sub')">
                        <sub>
                            <xsl:call-template name="ref-spear"/>
                        </sub>
                    </xsl:when>
                    <xsl:otherwise>
                        <span class="tei-rend-{string(@rend)}">
                            <xsl:call-template name="ref-spear"/>
                        </span>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="ref-spear"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template name="ref-spear">
        <xsl:choose>
            <xsl:when test="contains(@ref,$base-uri) and contains(@ref,'-')">
                <a href="factoid.html?id={@ref}">
                    <xsl:value-of select="normalize-space(.)"/>
                </a>    
            </xsl:when>
            <xsl:when test="contains(@ref,$base-uri)">
                <a href="aggregate.html?id={@ref}">
                    <xsl:value-of select="normalize-space(.)"/>
                    <!--    <xsl:apply-templates mode="spear"/> -->
                </a>    
            </xsl:when>
            <xsl:otherwise>
               <xsl:apply-templates mode="spear"/>        
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>