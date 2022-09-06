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
    </xsl:template>
    <xsl:template name="spearSources">
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
    <!-- New SPEAR -->
    <xsl:template match="t:ab[@subtype='nameVariant']">
        <xsl:call-template name="factoidHeader"/>
        <xsl:for-each select="t:listPerson/t:person/t:persName[@when or @notBefore or @notAfter or @from or @to]">
            <xsl:call-template name="spearDates"/>
        </xsl:for-each>
        <xsl:call-template name="spearCertainty"/>
        <xsl:for-each select="t:listPerson/t:person">
            <span class="element"><span class="spearLabel">Name Variant: </span> <xsl:apply-templates mode="spear"/></span>
        </xsl:for-each>
        <xsl:for-each select="descendant-or-self::t:note[not(@type='certainty')]">
            <span class="element"><span class="spearLabel">Social Rank: </span> <xsl:apply-templates mode="spear"/></span>
        </xsl:for-each>
        <xsl:apply-templates select="t:desc" mode="spear"/>            
        <xsl:call-template name="spearSources"/>
        <xsl:for-each select="t:note[@type='certainty']">
            <xsl:apply-templates/>
        </xsl:for-each>       
        <xsl:call-template name="spearCite"/>
    </xsl:template>
    <xsl:template match="t:ab[@subtype='socecStatus']">
        <xsl:call-template name="factoidHeader"/>
        <xsl:for-each select="//t:socecStatus[@when or @notBefore or @notAfter or @from or @to]">
            <xsl:call-template name="spearDates"/>
        </xsl:for-each>
        <xsl:call-template name="spearCertainty"/>
        <xsl:for-each select="//t:socecStatus/t:note[not(@type='certainty')]">
            <span class="element"><span class="spearLabel">Social Rank: </span> <xsl:apply-templates mode="spear"/></span>
        </xsl:for-each>
        <xsl:apply-templates select="t:desc" mode="spear"/>            
        <xsl:call-template name="spearSources"/>
        <xsl:for-each select="t:note[@type='certainty']">
            <xsl:apply-templates/>
        </xsl:for-each>       
        <xsl:call-template name="spearCite"/>
    </xsl:template>
    <xsl:template match="t:ab[@subtype='sanctity']">
        <xsl:call-template name="factoidHeader"/>
        <xsl:for-each select="//t:state[@when or @notBefore or @notAfter or @from or @to]">
            <xsl:call-template name="spearDates"/>
        </xsl:for-each>
        <xsl:call-template name="spearCertainty"/>
        <xsl:for-each select="//t:state/t:note">
            <span class="element"><span class="spearLabel">Sanctity: </span> <xsl:apply-templates mode="spear"/></span>
        </xsl:for-each>
        <xsl:apply-templates select="t:desc" mode="spear"/>            
        <xsl:call-template name="spearSources"/>
        <xsl:for-each select="t:note[@type='certainty']">
            <xsl:apply-templates/>
        </xsl:for-each>       
        <xsl:call-template name="spearCite"/>
    </xsl:template>
    <xsl:template match="t:ab[@subtype='residence']">
        <xsl:call-template name="factoidHeader"/>
        <xsl:for-each select="//t:residence[@when or @notBefore or @notAfter or @from or @to]">
            <xsl:call-template name="spearDates"/>
        </xsl:for-each>
        <xsl:call-template name="spearCertainty"/>
        <xsl:for-each select="//t:residence/t:note">
            <span class="element"><span class="spearLabel">Residence: </span> <xsl:apply-templates mode="spear"/></span>
        </xsl:for-each>
        <xsl:apply-templates select="t:desc" mode="spear"/>            
        <xsl:call-template name="spearSources"/>
        <xsl:for-each select="t:note[@type='certainty']">
            <xsl:apply-templates/>
        </xsl:for-each>       
        <xsl:call-template name="spearCite"/>
    </xsl:template>
    <xsl:template match="t:ab[@subtype='relation']">
        <xsl:call-template name="factoidHeader"/>
        <xsl:for-each select="//t:relation[@type='person']/t:date[@when or @notBefore or @notAfter or @from or @to]">
            <xsl:call-template name="spearDates"/>
        </xsl:for-each>
        <xsl:call-template name="spearCertainty"/>
        <xsl:for-each select="//t:relation[@type='person']/t:desc">
            <span class="element"><span class="spearLabel">Relationship: </span> <xsl:apply-templates mode="spear"/></span>
        </xsl:for-each>
        <xsl:apply-templates select="t:desc" mode="spear"/>            
        <xsl:call-template name="spearSources"/>
        <xsl:for-each select="t:note[@type='certainty']">
            <xsl:apply-templates/>
        </xsl:for-each>       
        <xsl:call-template name="spearCite"/>
    </xsl:template>
    <xsl:template match="t:ab[@subtype='physicalTrait']">
        <xsl:call-template name="factoidHeader"/>
        <xsl:for-each select="//t:trait[@when or @notBefore or @notAfter or @from or @to]">
            <xsl:call-template name="spearDates"/>
        </xsl:for-each>
        <xsl:call-template name="spearCertainty"/>
        <xsl:for-each select="//t:trait/t:note">
            <span class="element"><span class="spearLabel">Physical Trait: </span> <xsl:apply-templates mode="spear"/></span>
        </xsl:for-each>
        <xsl:apply-templates select="t:desc" mode="spear"/>            
        <xsl:call-template name="spearSources"/>
        <xsl:for-each select="t:note[@type='certainty']">
            <xsl:apply-templates/>
        </xsl:for-each>       
        <xsl:call-template name="spearCite"/>
    </xsl:template>
    <xsl:template match="t:ab[@subtype='occupation']">
        <xsl:call-template name="factoidHeader"/>
        <xsl:for-each select="//t:occupation[@when or @notBefore or @notAfter or @from or @to]">
            <xsl:call-template name="spearDates"/>
        </xsl:for-each>
        <xsl:call-template name="spearCertainty"/>
        <xsl:for-each select="//t:occupation/t:note">
            <span class="element"><span class="spearLabel">Citizenship: </span> <xsl:apply-templates mode="spear"/></span>
        </xsl:for-each>
        <xsl:apply-templates select="t:desc" mode="spear"/>            
        <xsl:call-template name="spearSources"/>
        <xsl:for-each select="t:note[@type='certainty']">
            <xsl:apply-templates/>
        </xsl:for-each>       
        <xsl:call-template name="spearCite"/>
    </xsl:template>
    <xsl:template match="t:ab[@subtype='mentalState']">
        <xsl:call-template name="factoidHeader"/>
        <xsl:for-each select="//t:state[@when or @notBefore or @notAfter or @from or @to]">
            <xsl:call-template name="spearDates"/>
        </xsl:for-each>
        <xsl:call-template name="spearCertainty"/>
        <xsl:for-each select="//t:state/t:note">
            <span class="element"><span class="spearLabel">Mental State: </span> <xsl:apply-templates mode="spear"/></span>
        </xsl:for-each>
        <xsl:apply-templates select="t:desc" mode="spear"/>            
        <xsl:call-template name="spearSources"/>
        <xsl:for-each select="t:note[@type='certainty']">
            <xsl:apply-templates/>
        </xsl:for-each>       
        <xsl:call-template name="spearCite"/>
    </xsl:template>
    <xsl:template match="t:ab[@subtype='langKnown']">
        <xsl:call-template name="factoidHeader"/>
        <xsl:for-each select="//t:langKnown[@when or @notBefore or @notAfter or @from or @to]">
            <xsl:call-template name="spearDates"/>
        </xsl:for-each>
        <xsl:call-template name="spearCertainty"/>
        <xsl:for-each select="//t:langKnown/t:note">
            <span class="element"><span class="spearLabel">Language Known: </span> <xsl:apply-templates mode="spear"/></span>
        </xsl:for-each>
        <xsl:apply-templates select="t:desc" mode="spear"/>            
        <xsl:call-template name="spearSources"/>
        <xsl:for-each select="t:note[@type='certainty']">
            <xsl:apply-templates/>
        </xsl:for-each>       
        <xsl:call-template name="spearCite"/>
    </xsl:template>
    <xsl:template match="t:ab[@subtype='gender']">
        <xsl:call-template name="factoidHeader"/>
        <xsl:for-each select="//t:trait[@when or @notBefore or @notAfter or @from or @to]">
            <xsl:call-template name="spearDates"/>
        </xsl:for-each>
        <xsl:call-template name="spearCertainty"/>
        <xsl:for-each select="//t:trait/t:note">
            <span class="element"><span class="spearLabel">Gender: </span> <xsl:apply-templates mode="spear"/></span>
        </xsl:for-each>
        <xsl:apply-templates select="t:desc" mode="spear"/>            
        <xsl:call-template name="spearSources"/>
        <xsl:for-each select="t:note[@type='certainty']">
            <xsl:apply-templates/>
        </xsl:for-each>       
        <xsl:call-template name="spearCite"/>
    </xsl:template>
    <xsl:template match="t:ab[@subtype='event']">
        <xsl:call-template name="factoidHeader"/>
        <xsl:for-each select="//t:event[@when or @notBefore or @notAfter or @from or @to]">
            <xsl:call-template name="spearDates"/>
        </xsl:for-each>
        <xsl:call-template name="spearCertainty"/>
        <xsl:for-each select="//t:event/t:desc">
            <span class="element"><span class="spearLabel">Event Factoid: </span> <xsl:apply-templates mode="spear"/></span>
        </xsl:for-each>            
        <xsl:call-template name="spearSources"/>
        <xsl:for-each select="t:note[@type='certainty']">
            <xsl:apply-templates/>
        </xsl:for-each>       
        <xsl:call-template name="spearCite"/>
    </xsl:template>
    <xsl:template match="t:ab[@subtype='ethnicLabel']">
        <xsl:call-template name="factoidHeader"/>
        <xsl:for-each select="//t:trait[@when or @notBefore or @notAfter or @from or @to]">
            <xsl:call-template name="spearDates"/>
        </xsl:for-each>
        <xsl:call-template name="spearCertainty"/>
        <xsl:for-each select="//t:trait/t:note">
            <span class="element"><span class="spearLabel">Ethnic Label: </span> <xsl:apply-templates mode="spear"/></span>
        </xsl:for-each>            
        <xsl:call-template name="spearSources"/>
        <xsl:for-each select="t:note[@type='certainty']">
            <xsl:apply-templates/>
        </xsl:for-each>       
        <xsl:call-template name="spearCite"/>
    </xsl:template>
    <xsl:template match="t:ab[@subtype='education']">
        <xsl:call-template name="factoidHeader"/>
        <xsl:for-each select="//t:education[@when or @notBefore or @notAfter or @from or @to]">
            <xsl:call-template name="spearDates"/>
        </xsl:for-each>
        <xsl:call-template name="spearCertainty"/>
        <xsl:for-each select="//t:education/t:note">
            <span class="element"><span class="spearLabel">Education: </span> <xsl:apply-templates mode="spear"/></span>
        </xsl:for-each>            
        <xsl:call-template name="spearSources"/>
        <xsl:for-each select="t:note[@type='certainty']">
            <xsl:apply-templates/>
        </xsl:for-each>       
        <xsl:call-template name="spearCite"/>
    </xsl:template>
    <xsl:template match="t:ab[@subtype='death']">
        <xsl:call-template name="factoidHeader"/>
        <xsl:for-each select="//t:death/t:date[@when or @notBefore or @notAfter or @from or @to]">
            <xsl:call-template name="spearDates"/>
        </xsl:for-each>
        <xsl:call-template name="spearCertainty"/>
        <xsl:for-each select="//t:death/t:note">
            <span class="element"><span class="spearLabel">Death: </span> <xsl:apply-templates mode="spear"/></span>
        </xsl:for-each>            
        <xsl:call-template name="spearSources"/>
        <xsl:for-each select="t:note[@type='certainty']">
            <xsl:apply-templates/>
        </xsl:for-each>       
        <xsl:call-template name="spearCite"/>
    </xsl:template>
    <xsl:template match="t:ab[@subtype='citizenship']">
        <xsl:call-template name="factoidHeader"/>
        <xsl:for-each select="//t:nationality[@when or @notBefore or @notAfter or @from or @to]">
            <xsl:call-template name="spearDates"/>
        </xsl:for-each>
        <xsl:call-template name="spearCertainty"/>
        <xsl:for-each select="//t:nationality/t:note">
            <span class="element"><span class="spearLabel">Citizenship: </span> <xsl:apply-templates mode="spear"/></span>
        </xsl:for-each>            
        <xsl:call-template name="spearSources"/>
        <xsl:for-each select="t:note[@type='certainty']">
            <xsl:apply-templates/>
        </xsl:for-each>       
        <xsl:call-template name="spearCite"/>
    </xsl:template>
    <xsl:template match="t:ab[@subtype='birth']">
        <xsl:call-template name="factoidHeader"/>
        <xsl:for-each select="//t:birth/t:date[@when or @notBefore or @notAfter or @from or @to]">
            <xsl:call-template name="spearDates"/>
        </xsl:for-each>
        <xsl:call-template name="spearCertainty"/>
        <xsl:for-each select="//t:birth/t:note">
            <span class="element"><span class="spearLabel">Birth: </span> <xsl:apply-templates mode="spear"/></span>
        </xsl:for-each>            
        <xsl:call-template name="spearSources"/>
        <xsl:for-each select="t:note[@type='certainty']">
            <xsl:apply-templates/>
        </xsl:for-each>       
        <xsl:call-template name="spearCite"/>
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
    <xsl:template match="t:aggregate-title">
        <div class="row title padding-top">
            <h1 class="col-md-8">
                <xsl:text>SPEAR Factoids about </xsl:text>
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
                        <xsl:value-of select="$resource-id"/>
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
    <!--
    <xsl:template match="t:factoid | t:ab[t:idno] | t:ab[@type='factoid']">
                <div class="factoid">
                    <xsl:if test="t:factoid-headword">
                        <h4>
                            <xsl:call-template name="title"/>
                        </h4>
                    </xsl:if>
                    <xsl:choose>
                        <xsl:when test="descendant::t:ab[t:idno]/t:listPerson">
                            <h4>Person</h4>
                        </xsl:when>
                        <xsl:when test="descendant::t:ab[t:idno]/t:listEvent">
                            <h4>Event</h4>
                        </xsl:when>
                        <xsl:when test="descendant::t:ab[t:idno]/t:listRelation">
                            <h4>Relationship</h4>
                        </xsl:when>
                    </xsl:choose>
                    <xsl:for-each select="//t:ab[@type='factoid']">
                        <xsl:for-each select="child::*[not(self::t:bibl)][not(self::t:note)][not(self::t:idno)]                             [not(self::t:listRelation)]/child::*/child::*[not(empty(descendant-or-self::text()))]">
                            <xsl:variable name="label">
                                <xsl:choose>
                                    <xsl:when test="name(.) = 'persName'">Name</xsl:when>
                                    <xsl:when test="name(.) = 'desc'">Description</xsl:when>
                                    <xsl:when test="name(.) = 'socecStatus'">Social rank</xsl:when>
                                    <xsl:when test="name(.) = 'relation'">Relationship</xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="concat(upper-case(substring(name(.), 1, 1)), substring(name(.), 2))"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:variable>
                            <div class="tei-{$label}">
                                <strong>
                            <xsl:value-of select="$label"/>: </strong>
                                <xsl:apply-templates mode="spear"/>                                
                            </div>
                        </xsl:for-each>
                        <xsl:if test="@subtype='relation'">
                            <xsl:for-each select="descendant::t:listRelation/t:relation">
                                <xsl:apply-templates select="t:desc" mode="spear"/>
                                <xsl:if test="@type!=''">
                                    <p>Qualifier(s):  
                                        <xsl:for-each select="tokenize(@type,' ')">
                                            <xsl:choose>
                                                <xsl:when test=". = 'snap:AcknowledgedFamilyRelationship'">(Acknowledged family relationship)</xsl:when>
                                                <xsl:when test=". = 'snap:AdoptedFamilyRelationship'">(Adopted family relationship)</xsl:when>
                                                <xsl:when test=". = 'syriaca:AllegedRelationship'">(Alleged relationship)</xsl:when>
                                                <xsl:when test=". = 'snap:ClaimedFamilyRelationship'">(Claimed family relationship)</xsl:when>
                                                <xsl:when test=". = 'snap:FosterFamilyRelationship'">(Foster family relationship)</xsl:when>
                                                <xsl:when test=". = 'snap:HalfFamilyRelationship'">(Half family relationship)</xsl:when>
                                                <xsl:when test=". = 'snap:InLawFamilyRelationship'">(In law family relationship)</xsl:when>
                                                <xsl:when test=". = 'snap:MaternalFamilyRelationship'">(Maternal family relationship)</xsl:when>
                                                <xsl:when test=". = 'snap:PaternalFamilyRelationship'">(Paternal family relationship)</xsl:when>
                                                <xsl:when test=". = 'syriaca:RitualKinship'">(Ritual kinship)</xsl:when>
                                                <xsl:when test=". = 'snap:StepFamilyRelationship'">(Step family relationship) </xsl:when>
                                            </xsl:choose> 
                                        </xsl:for-each>
                                    </p>
                                </xsl:if>    
                            </xsl:for-each>
                        </xsl:if>
                        <xsl:for-each select="descendant::t:note[not(@type='desc')]">
                            <xsl:variable name="label">
                                <xsl:value-of select="concat(upper-case(substring(@type, 1, 1)), substring(@type, 2))"/>    
                            </xsl:variable>
                            <div class="tei-note {if($label != '') then $label else ()}">
                                <xsl:choose>
                                    <xsl:when test="@type='desc'">
                                        <span class="note-label">Description : </span>
                                    </xsl:when>
                                    <xsl:otherwise>
                                <span class="note-label">Note : <xsl:if test="$label != ''">
                                        <xsl:value-of select="$label"/>
                                    </xsl:if>
                                </span>
                            </xsl:otherwise>
                                </xsl:choose>
                                <br/>
                                <xsl:apply-templates mode="spear"/>                            
                            </div>    
                        </xsl:for-each>
                    </xsl:for-each>
                    <xsl:if test="//t:ab[@type='factoid'][@resp != '']">
                        <xsl:variable name="editorssourcedoc">
                            <xsl:if test="doc-available(concat('xmldb:exist://',$app-root,'/documentation/editors.xml'))">
                                <xsl:sequence select="doc(concat('xmldb:exist://',$app-root,'/documentation/editors.xml'))"/>
                            </xsl:if>
                        </xsl:variable>
                        <xsl:variable name="editors">
                            <xsl:for-each select="tokenize(//t:ab[@type='factoid']/@resp,' ')">
                                <xsl:variable name="sought" select="substring-after(.,'#')"/>
                                <xsl:choose>
                                    <xsl:when test="$editorssourcedoc/descendant::t:body/t:listPerson[1]/t:person[@xml:id=$sought][1]">
                                        <xsl:sequence select="$editorssourcedoc/descendant::t:body/t:listPerson[1]/t:person[@xml:id=$sought][1]"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                <xsl:value-of select="."/>
                            </xsl:otherwise>
                                </xsl:choose>                            
                            </xsl:for-each>
                        </xsl:variable>
                        <div class="tei-rsp">
                            - This data collected by <xsl:value-of select="local:emit-responsible-persons-all($editors//t:person, 'footnote')"/>
                        </div>    
                    </xsl:if>
                </div>
    </xsl:template>
    -->
    <xsl:template match="t:aggregate">
        <xsl:variable name="id" select="@id"/>
        <div class="spear-aggregate">
            <xsl:choose>
                <xsl:when test="t:ab">
                    <xsl:for-each-group select="t:ab/t:listPerson/t:person/t:persName[. != ''] | t:ab/t:listPerson/t:personGrp/t:persName[. != '']" group-by="name(.)">
                        <h4>Name variant(s): </h4>
                        <xsl:for-each select="current-group()">
                            <xsl:sort select="xs:integer(substring-after(ancestor::t:ab[1]/t:idno, '-'))" order="ascending"/>
                            <p class="indent">
                                <xsl:copy-of select="."/>

                                <a href="{replace(string(ancestor::t:ab[1]/t:idno),$base-uri,$nav-base)}" class="factoid-more"> See factoid page <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/>
                                </a>
                            </p>
                        </xsl:for-each>
                    </xsl:for-each-group>
                    <xsl:for-each-group select="t:ab[descendant::t:trait[@type='gender']]" group-by="name(t:ab[descendant::t:trait[@type='gender']][1])">
                        <h4>Sex: </h4>
                        <xsl:for-each select="current-group()">
                            <xsl:sort select="xs:integer(substring-after(t:idno, '-'))" order="ascending"/>
                            <p class="indent">
                                <xsl:apply-templates mode="spear"/>
                                <xsl:text> </xsl:text>
                                <a href="{replace(string(t:idno),$base-uri,$nav-base)}" class="factoid-more">See factoid page
                                        <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/>
                                </a>
                            </p>
                        </xsl:for-each>
                    </xsl:for-each-group>
                    <xsl:for-each-group select="t:ab[descendant::t:birth]" group-by="name(t:ab[descendant::t:birth][1])">
                        <xsl:for-each-group select=".[descendant::t:birth][descendant::t:date]" group-by="name(descendant::t:birth)">
                            <h4>Birth date: </h4>
                            <xsl:for-each select="current-group()">
                                <xsl:sort select="xs:integer(substring-after(t:idno, '-'))" order="ascending"/>
                                <p class="indent">
                                    <xsl:apply-templates mode="spear"/>
                                    <xsl:text> </xsl:text>
                                    <a href="{replace(string(t:idno),$base-uri,$nav-base)}" class="factoid-more"> See factoid page <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/>
                                    </a>
                                </p>
                            </xsl:for-each>
                        </xsl:for-each-group>
                        <xsl:for-each-group select=".[descendant::t:birth/t:placeName]" group-by="name(descendant::t:birth/t:placeName)">
                            <h4>Birth Place: </h4>
                            <xsl:for-each select="current-group()">
                                <xsl:sort select="xs:integer(substring-after(t:idno, '-'))" order="ascending"/>
                                <p class="indent">
                                    <xsl:apply-templates mode="spear"/>
                                    <xsl:text> </xsl:text>
                                    <a href="{replace(string(t:idno),$base-uri,$nav-base)}" class="factoid-more"> See factoid page <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/>
                                    </a>
                                </p>
                            </xsl:for-each>
                        </xsl:for-each-group>
                    </xsl:for-each-group>
                    <xsl:for-each-group select="t:ab[descendant::t:death]" group-by="name(t:ab[descendant::t:death][1])">
                        <xsl:for-each-group select=".[descendant::t:death][descendant::t:date]" group-by="name(descendant::t:death)">
                            <h4>Death date: </h4>
                            <xsl:for-each select="current-group()">
                                <xsl:sort select="xs:integer(substring-after(t:idno, '-'))" order="ascending"/>
                                <p class="indent">
                                    <xsl:apply-templates mode="spear"/>
                                    <xsl:text> </xsl:text>
                                    <a href="{replace(string(t:idno),$base-uri,$nav-base)}" class="factoid-more"> See factoid page <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/>
                                    </a>
                                </p>
                            </xsl:for-each>
                        </xsl:for-each-group>
                        <xsl:for-each-group select=".[descendant::t:death/t:placeName]" group-by="name(descendant::t:death/t:placeName)">
                            <h4>Death Place: </h4>
                            <xsl:for-each select="current-group()">
                                <xsl:sort select="xs:integer(substring-after(t:idno, '-'))" order="ascending"/>
                                <p class="indent">
                                    <xsl:apply-templates mode="spear"/>
                                    <xsl:text> </xsl:text>
                                    <a href="{replace(string(t:idno),$base-uri,$nav-base)}" class="factoid-more"> See factoid page <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/>
                                    </a>
                                </p>
                            </xsl:for-each>
                        </xsl:for-each-group>
                    </xsl:for-each-group>
                    <xsl:for-each-group select="t:ab[descendant::t:socecStatus]" group-by="name(t:ab[descendant::t:socecStatus][1])">
                        <h4>Social rank: </h4>
                        <xsl:for-each select="current-group()">
                            <xsl:sort select="xs:integer(substring-after(t:idno, '-'))" order="ascending"/>
                            <p class="indent">
                                <xsl:apply-templates mode="spear"/>
                                <xsl:text> </xsl:text>
                                <a href="{replace(string(t:idno),$base-uri,$nav-base)}" class="factoid-more">See factoid page
                                        <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/>
                                </a>
                            </p>
                        </xsl:for-each>
                    </xsl:for-each-group>
                    <xsl:for-each-group select="t:ab[descendant::t:occupation]" group-by="name(t:ab[descendant::t:occupation][1])">
                        <h4>Occupation(s): </h4>
                        <xsl:for-each select="current-group()">
                            <xsl:sort select="xs:integer(substring-after(t:idno, '-'))" order="ascending"/>
                            <p class="indent">
                                <xsl:apply-templates mode="spear"/>
                                <xsl:text> </xsl:text>
                                <a href="{replace(string(t:idno),$base-uri,$nav-base)}" class="factoid-more">See factoid page
                                        <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/>
                                </a>
                            </p>
                        </xsl:for-each>
                    </xsl:for-each-group>
                    <xsl:for-each-group select="t:ab[descendant::t:nationality]" group-by="name(t:ab[descendant::t:nationality][1])">
                        <h4>Citizenship: </h4>
                        <xsl:for-each select="current-group()">
                            <xsl:sort select="xs:integer(substring-after(t:idno, '-'))" order="ascending"/>
                            <p class="indent">
                                <xsl:apply-templates mode="spear"/>
                                <xsl:text> </xsl:text>
                                <a href="{replace(string(t:idno),$base-uri,$nav-base)}" class="factoid-more">See factoid page
                                        <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/>
                                </a>
                            </p>
                        </xsl:for-each>
                    </xsl:for-each-group>
                    <xsl:for-each-group select="t:ab[descendant::t:residence]" group-by="name(t:ab[descendant::t:residence][1])">
                        <h4>Place of residence: </h4>
                        <xsl:for-each select="current-group()">
                            <xsl:sort select="xs:integer(substring-after(t:idno, '-'))" order="ascending"/>
                            <p class="indent">
                                <xsl:apply-templates mode="spear"/>
                                <xsl:text> </xsl:text>
                                <a href="{replace(string(t:idno),$base-uri,$nav-base)}" class="factoid-more">See factoid page
                                        <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/>
                                </a>
                            </p>
                        </xsl:for-each>
                    </xsl:for-each-group>
                    <xsl:for-each-group select="t:ab[descendant::t:state]" group-by="name(t:ab[descendant::t:state][1])">
                        <xsl:for-each-group select=".[descendant::t:state]" group-by="descendant::t:state/@type">
                            <h4>
                                <xsl:choose>
                                    <xsl:when test="current-grouping-key() = 'mental'">Mental state: </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="current-grouping-key()"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </h4>
                            <xsl:for-each select="current-group()">
                                <xsl:sort select="xs:integer(substring-after(t:idno, '-'))" order="ascending"/>
                                <p class="indent">
                                    <xsl:apply-templates mode="spear"/>
                                    <xsl:text> </xsl:text>
                                    <a href="{replace(string(t:idno),$base-uri,$nav-base)}" class="factoid-more"> See factoid page <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/>
                                    </a>
                                </p>
                            </xsl:for-each>
                        </xsl:for-each-group>
                    </xsl:for-each-group>
                    <xsl:for-each-group select="t:ab[descendant::t:education]" group-by="name(t:ab[descendant::t:education][1])">
                        <h4>Education: </h4>
                        <xsl:for-each select="current-group()">
                            <xsl:sort select="xs:integer(substring-after(t:idno, '-'))" order="ascending"/>
                            <p class="indent">
                                <xsl:apply-templates mode="spear"/>
                                <xsl:text> </xsl:text>
                                <a href="{replace(string(t:idno),$base-uri,$nav-base)}" class="factoid-more">See factoid page
                                        <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/>
                                </a>
                            </p>
                        </xsl:for-each>
                    </xsl:for-each-group>
                    <xsl:for-each-group select="t:ab[descendant::t:langKnowledge]" group-by="name(t:ab[descendant::t:langKnowledge][1])">
                        <h4>Language known: </h4>
                        <xsl:for-each select="current-group()">
                            <xsl:sort select="xs:integer(substring-after(t:idno, '-'))" order="ascending"/>
                            <p class="indent">
                                <xsl:apply-templates mode="spear"/>
                                <xsl:text> </xsl:text>
                                <a href="{replace(string(t:idno),$base-uri,$nav-base)}">More <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/>
                                </a>
                            </p>
                        </xsl:for-each>
                    </xsl:for-each-group>
                    <xsl:for-each-group select="t:ab[descendant::t:trait[not(@type='gender')]]" group-by="name(t:ab[descendant::t:trait][1])">
                        <xsl:for-each-group select=".[descendant::t:trait]" group-by="descendant::t:trait/@type">
                            <h4>
                                <xsl:choose>
                                    <xsl:when test="current-grouping-key() = 'physical'">Physical
                                        trait: </xsl:when>
                                    <xsl:when test="current-grouping-key() = 'gender'">Gender: </xsl:when>
                                    <xsl:when test="current-grouping-key() = 'ethnicLabel'">Ethnic
                                        label: </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="current-grouping-key()"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </h4>
                            <xsl:for-each select="current-group()">
                                <xsl:sort select="xs:integer(substring-after(t:idno, '-'))" order="ascending"/>
                                <p class="indent">
                                    <xsl:apply-templates mode="spear"/>
                                    <xsl:text> </xsl:text>
                                    <a href="{replace(string(t:idno),$base-uri,$nav-base)}" class="factoid-more"> See factoid page <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/>
                                    </a>
                                </p>
                            </xsl:for-each>
                        </xsl:for-each-group>
                    </xsl:for-each-group>
                    <xsl:for-each select="t:ab[not(descendant::t:sex | descendant::t:state | descendant::t:occupation | descendant::t:birth | descendant::t:death | descendant::t:education | descendant::t:nationality | descendant::t:residence | descendant::t:langKnowledge | descendant::t:socecStatus | descendant::t:trait | t:listPerson/child::*/t:persName[. != ''])]">
                        <xsl:sort select="xs:integer(substring-after(t:idno, '-'))" order="ascending"/>
                        <p class="indent">
                            <xsl:apply-templates mode="spear"/>
                            <xsl:text> </xsl:text>
                            <a href="{replace(string(t:idno),$base-uri,$nav-base)}" class="factoid-more">See factoid page
                                    <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/>
                            </a>
                        </p>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates mode="spear"/>
                </xsl:otherwise>
            </xsl:choose>
        </div>
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
    
    <!-- Needs work -->
    <xsl:template match="t:spear-citation">
        <xsl:if test="descendant-or-self::tei:body/descendant::t:bibl">
                <!-- Sources -->
                <div id="sources" class="text-block">
                    <h3>Source</h3>
                    <ul>
                        <li>
                            <!-- title of the entry -->
                            <xsl:apply-templates select="descendant-or-self::t:teiHeader/t:fileDesc/t:titleStmt/t:title[@level='a'][1]" mode="footnote"/>
                        </li>
                    </ul>
                    <h3>Factoid Citations</h3>
                    <ul>
                        <xsl:apply-templates select="descendant-or-self::tei:body/descendant::t:bibl" mode="footnote"/>
                    </ul>
                </div>
            
        </xsl:if>
    </xsl:template>
</xsl:stylesheet>