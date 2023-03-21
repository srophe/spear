xquery version "3.1";
(:~
 : XQuery to call, format and save TEI2HTML pages into the database
:)

import module namespace http="http://expath.org/ns/http-client";
import module namespace config="http://srophe.org/srophe/config" at "config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace srophe="https://srophe.app";

(: Helper function to recursively create a collection hierarchy. :)
declare function local:mkcol-recursive($collection, $components) {
    if (exists($components)) then
        let $newColl := concat($collection, "/", $components[1])
        return (
            xmldb:create-collection($collection, $components[1]),
            local:mkcol-recursive($newColl, subsequence($components, 2))
        )
    else ()
};

(: Helper function to recursively create a collection hierarchy. :)
declare function local:mkcol($collection, $path) {
    local:mkcol-recursive($collection, tokenize($path, "/"))
};

declare function local:buildHTML($results as item()*){
    <div xmlns="http://www.w3.org/1999/xhtml" xmlns:xi="http://www.w3.org/2001/XInclude" data-template="templates:surround" data-template-with="templates/page.html" data-template-at="content">
        <div class="record">
            <div class="interior-content">
                {
                        transform:transform($results, doc($config:app-root || '/resources/xsl/tei2html.xsl'), 
                            <parameters>
                                <param name="data-root" value="{$config:data-root}"/>
                                <param name="app-root" value="{$config:app-root}"/>
                                <param name="nav-base" value="{$config:nav-base}"/>
                                <param name="base-uri" value="{$config:base-uri}"/>
                            </parameters>
                            )
                    }
            </div>
        </div>
    </div>  
};

declare function local:buildFactoids(){
    let $start := if(request:get-parameter('start', '') != '') then request:get-parameter('start', '') else 1
    let $limit := if(request:get-parameter('limit', '') != '') then request:get-parameter('limit', '') else 10
    let $startParam := if(request:get-parameter('start', '') != '') then concat('&amp;start=',request:get-parameter('start', '')) else '&amp;start=0'
    let $limitParam := if(request:get-parameter('limit', '') != '') then concat('&amp;limit=',request:get-parameter('limit', '')) else '&amp;limit=50'
    let $action := if(request:get-parameter('action', '') != '') then request:get-parameter('action', '') else 'check'
    let $items := if(request:get-parameter('id', '') != '') then collection($config:data-root)//tei:TEI[.//tei:idno[. = request:get-parameter('id', '')][@type='URI']] else collection($config:data-root)
    let $total := count($items)
    let $next := if(xs:integer($start) lt xs:integer($total)) then (xs:integer($start) + xs:integer($limit)) else ()
    let $group := 
        for $f in subsequence($items,$start,$limit)
        let $collection := document-uri($f)
        let $file := tokenize($collection,'/')[last()]
        let $fileName := replace($file,'.xml','.html')
        let $htmlPath := replace(replace($collection, $config:data-root,$config:app-root),concat('/',$file),'')
        let $html := local:buildHTML($f)
        let $buildPath := 
                if(xmldb:collection-available($htmlPath)) then ()
                else (local:mkcol("/db/apps", replace($htmlPath,'/db/apps','')))
        return 
           try {xmldb:store($htmlPath, xmldb:encode-uri($fileName), $html)} 
         catch *{
                <response status="fail">
                    <message>Failed to add resource {$fileName}: {concat($err:code, ": ", $err:description)}</message>
                </response>
            }
    return 
        if($next) then
            ($group,
            <div xmlns="http://www.w3.org/1999/xhtml">
                <p>Processed {if(request:get-parameter('start', '') != '') then request:get-parameter('start', '') else '0'} - {substring-before($next,'&amp;')} of {string($total)}</p>
                <p><a href="?type=factoids&amp;start={$next}&amp;limit={$limit}" class="btn btn-info zotero">Next</a></p>
            </div>)
        else 
            ($group,
            <div><h3>Updated!</h3>
                <p><label>Number of updated records: </label> {string($total)}</p>
             </div>)
};

declare function local:buildAggregate(){
    let $start := if(request:get-parameter('start', '') != '') then request:get-parameter('start', '') else 1
    let $limit := if(request:get-parameter('limit', '') != '') then request:get-parameter('limit', '') else 10
    let $startParam := if(request:get-parameter('start', '') != '') then concat('&amp;start=',request:get-parameter('start', '')) else '&amp;start=0'
    let $limitParam := if(request:get-parameter('limit', '') != '') then concat('&amp;limit=',request:get-parameter('limit', '')) else '&amp;limit=50'
    let $action := if(request:get-parameter('action', '') != '') then request:get-parameter('action', '') else 'check'
    let $items := collection($config:data-root)
    let $aggGroup := (: maybe use distinct values here, and change count to count this not items :)
        string-join(for $r in $items/descendant::tei:ab//@ref | $items/descendant::tei:ab//@ana where contains($r,'syriaca.org/person/') or contains($r,'syriaca.org/place/') or contains($r,'syriaca.org/keyword/') return string($r), ' ')
    let $dedup := 
        for $t in distinct-values(tokenize($aggGroup,' '))
        return $t     
    let $total := count($dedup)  
    let $next := if(xs:integer($start) lt xs:integer($total)) then (xs:integer($start) + xs:integer($limit)) else ()
    let $indexes := doc('/db/apps/spear/resources/indexes/keywordIndex.xml')//tei:keyword 
                    | doc('/db/apps/spear/resources/indexes/personsIndex.xml')//tei:person
                    | doc('/db/apps/spear/resources/indexes/placesIndex.xml')//tei:place
    let $group := 
        if(request:get-parameter('id', '') != '') then
            let $f := request:get-parameter('id', '')
            let $htmlPath := ($config:app-root||'/aggregate/'||tokenize($f,'/')[4])
            let $file := tokenize($f,'/')[last()]
            let $fileName := concat($file,'.html')
            let $items := 
                <aggregate xmlns="http://www.tei-c.org/ns/1.0" id="{$f}">
                    {let $sropheData := 
                                        if($indexes[tei:idno = $f]) then 
                                            $indexes[tei:idno = $f]
                                         else () (: http:send-request(<http:request http-version="1.1" href="{xs:anyURI(concat($f,'.xml'))}" method="get"/>):)
                                         
                     return 
                        <syriaca xmlns="http://www.tei-c.org/ns/1.0">
                            {$sropheData}
                        </syriaca>} 
                    {(collection($config:data-root)//tei:ab[.//@ref[. = $f]] | collection($config:data-root)//tei:ab[.//@ana[matches(., concat($f,'(\W.*)?$'))]])}
                </aggregate>
            let $html := local:buildHTML($items)
            let $buildPath := 
                     if(xmldb:collection-available($htmlPath)) then ()
                     else (local:mkcol("/db/apps", replace($htmlPath,'/db/apps','')))
            return 
                try {xmldb:store($htmlPath, xmldb:encode-uri($fileName), $html)} 
                 catch *{
                     <response status="fail">
                         <message>Failed to add resource {$fileName}: {concat($err:code, ": ", $err:description)}</message>
                     </response>
                 }
        else 
            for $f in subsequence($dedup,$start,$limit)
            let $htmlPath := ($config:app-root||'/aggregate/'||tokenize($f,'/')[4])
            let $file := tokenize($f,'/')[last()]
            let $fileName := concat($file,'.html')
            let $items := 
                <aggregate xmlns="http://www.tei-c.org/ns/1.0" id="{$f}">
                    {let $sropheData :=  if($indexes[tei:idno = $f]) then 
                                            $indexes[tei:idno = $f]
                                         else ()(:http:send-request(<http:request http-version="1.1" href="{xs:anyURI(concat($f,'.xml'))}" method="get"/>):)
                     return 
                        <syriaca xmlns="http://www.tei-c.org/ns/1.0">
                            {$sropheData}
                        </syriaca>}
                    {(collection($config:data-root)//tei:ab[.//@ref[. = $f]] | collection($config:data-root)//tei:ab[.//@ana[matches(., concat($f,'(\W.*)?$'))]])}
                </aggregate>
            let $html := local:buildHTML($items)
            let $buildPath := 
                    if(xmldb:collection-available($htmlPath)) then ()
                    else (local:mkcol("/db/apps", replace($htmlPath,'/db/apps','')))
            return 
              try {xmldb:store($htmlPath, xmldb:encode-uri($fileName), $html)} 
                catch *{
                    <response status="fail">
                        <message>Failed to add resource {$fileName}: {concat($err:code, ": ", $err:description)}</message>
                    </response>
                }
    return 
        if($next) then
            ($group,
            <div xmlns="http://www.w3.org/1999/xhtml">
                <p>Processed {if(request:get-parameter('start', '') != '') then request:get-parameter('start', '') else '0'} - {substring-before($next,'&amp;')} of {string($total)}</p>
                <p><a href="?type=aggregate&amp;start={$next}&amp;limit={$limit}" class="btn btn-info zotero">Next</a></p>
            </div>)
        else 
            ($group,
            <div><h3>Updated!</h3>
                <p><label>Number of updated records: </label> {string($total)}</p>
             </div>)
};

declare function local:buildPersonIndex(){
    let $teiRec := 
        <TEI xmlns="http://www.tei-c.org/ns/1.0">
            {
                let $items := collection($config:data-root)
                let $refs := 
                    string-join(
                        for $r in $items/descendant::tei:ab//@ref | $items/descendant::tei:ab//@ana 
                        where contains($r,'syriaca.org/person/') or contains($r,'syriaca.org/place/') or contains($r,'syriaca.org/keyword/') 
                        return string($r), ' ')
                let $dedup := 
                    for $t in distinct-values(tokenize($refs,' '))
                    return $t 
                for $p in collection('/db/apps/srophe-data/data/persons')
                let $idno := replace($p//tei:publicationStmt/tei:idno[1],'/tei','')
                return 
                <person>
                    <idno>{$idno}</idno>
                    <title>{
                        if($p/descendant::tei:title[@level="a"][@xml:lang='en']) then 
                            $p/descendant::tei:title[@level="a"][@xml:lang='en'][1] 
                        else if($p/descendant-or-self::*[@syriaca-tags='#syriaca-headword'][@xml:lang='en']) then 
                            $p/descendant-or-self::*[@syriaca-tags='#syriaca-headword'][@xml:lang='en'][1]
                        else if($p/descendant-or-self::*[@srophe:tags='#syriaca-headword'][@xml:lang='en']) then 
                            $p/descendant-or-self::*[@srophe:tags='#syriaca-headword'][@xml:lang='en'][1]                            
                        else $p/descendant::tei:title[1]
                    }</title>
                    <abstract>{$p/descendant-or-self::tei:note[@type='abstract']}</abstract>
                    <related>
                        {if($dedup[. = $idno]) then <refs>{string($idno)}</refs> else ()}
                    </related>
                </person>
            }
        </TEI>
    let $htmlPath := '/db/apps/spear/resources/indexes/'
    let $buildPath := 
                    if(xmldb:collection-available($htmlPath)) then ()
                    else (local:mkcol("/db/apps", replace($htmlPath,'/db/apps','')))        
     return    
        try {xmldb:store($htmlPath, 'personsIndex.xml', $teiRec)} 
                catch *{
                    <response status="fail">
                        <message>Failed to add resource personsIndex : {concat($err:code, ": ", $err:description)}</message>
                    </response>
                }
       
    
};

declare function local:buildPlaceIndex(){
    let $teiRec := 
        <TEI xmlns="http://www.tei-c.org/ns/1.0">
            {
                let $items := collection($config:data-root)
                let $refs := 
                    string-join(
                        for $r in $items/descendant::tei:ab//@ref | $items/descendant::tei:ab//@ana 
                        where contains($r,'syriaca.org/person/') or contains($r,'syriaca.org/place/') or contains($r,'syriaca.org/keyword/') 
                        return string($r), ' ')
                let $dedup := 
                    for $t in distinct-values(tokenize($refs,' '))
                    return $t 
                for $p in collection('/db/apps/srophe-data/data/places')
                let $idno := replace($p//tei:publicationStmt/tei:idno[1],'/tei','')
                return 
                <place>
                    <idno>{$idno}</idno>
                    <title>{
                        if($p/descendant::tei:title[@level="a"][@xml:lang='en']) then 
                            $p/descendant::tei:title[@level="a"][@xml:lang='en'][1] 
                        else if($p/descendant-or-self::*[@syriaca-tags='#syriaca-headword'][@xml:lang='en']) then 
                            $p/descendant-or-self::*[@syriaca-tags='#syriaca-headword'][@xml:lang='en'][1]
                        else if($p/descendant-or-self::*[@srophe:tags='#syriaca-headword'][@xml:lang='en']) then 
                            $p/descendant-or-self::*[@srophe:tags='#syriaca-headword'][@xml:lang='en'][1]                            
                        else $p/descendant::tei:title[1]
                      }</title>
                    <abstract>{$p/descendant-or-self::tei:note[@type='abstract']}</abstract>
                     <related>
                        {if($dedup[. = $idno]) then <refs>{string($idno)}</refs> else ()}
                    </related>
                </place>
            }
        </TEI>
    let $htmlPath := '/db/apps/spear/resources/indexes/'
    let $buildPath := 
                    if(xmldb:collection-available($htmlPath)) then ()
                    else (local:mkcol("/db/apps", replace($htmlPath,'/db/apps','')))        
     return    
        try {xmldb:store($htmlPath, 'placesIndex.xml', $teiRec)} 
                catch *{
                    <response status="fail">
                        <message>Failed to add resource personsIndex : {concat($err:code, ": ", $err:description)}</message>
                    </response>
                }
       
    
};

declare function local:buildKeywordIndex(){
    let $teiRec := 
        <TEI xmlns="http://www.tei-c.org/ns/1.0">
            {
                let $items := collection($config:data-root)
                let $refs := 
                    string-join(
                        for $r in $items/descendant::tei:ab//@ref | $items/descendant::tei:ab//@ana 
                        where contains($r,'syriaca.org/person/') or contains($r,'syriaca.org/place/') or contains($r,'syriaca.org/keyword/') 
                        return string($r), ' ')
                let $dedup := 
                    for $t in distinct-values(tokenize($refs,' '))
                    return $t
                for $p in collection('/db/apps/srophe-data/data/subjects')
                let $idno := replace($p//tei:publicationStmt/tei:idno[1],'/tei','')
                return 
                <keyword>
                    <idno>{$idno}</idno>
                    <title>{
                        if($p/descendant::tei:title[@level="a"][@xml:lang='en']) then 
                            $p/descendant::tei:title[@level="a"][@xml:lang='en'][1] 
                        else if($p/descendant-or-self::*[@syriaca-tags='#syriaca-headword'][@xml:lang='en']) then 
                            $p/descendant-or-self::*[@syriaca-tags='#syriaca-headword'][@xml:lang='en'][1]
                        else if($p/descendant-or-self::*[@srophe:tags='#syriaca-headword'][@xml:lang='en']) then 
                            $p/descendant-or-self::*[@srophe:tags='#syriaca-headword'][@xml:lang='en'][1]                            
                        else $p/descendant::tei:title[1]
                    }</title>
                    <abstract>{$p/descendant-or-self::tei:note[@type='abstract']}</abstract>
                     <related>
                        {if($dedup[. = $idno]) then <refs>{string($idno)}</refs> else ()}
                    </related>
                </keyword>
            }
        </TEI>
    let $htmlPath := '/db/apps/spear/resources/indexes/'
    let $buildPath := 
                    if(xmldb:collection-available($htmlPath)) then ()
                    else (local:mkcol("/db/apps", replace($htmlPath,'/db/apps','')))        
     return    
        try {xmldb:store($htmlPath, 'keywordIndex.xml', $teiRec)} 
                catch *{
                    <response status="fail">
                        <message>Failed to add resource personsIndex : {concat($err:code, ": ", $err:description)}</message>
                    </response>
                }
       
    
};

declare function local:buildBrowsePage(){
    let $items := collection($config:data-root)
    let $aggGroup := (: maybe use distinct values here, and change count to count this not items :)
        string-join(for $r in $items/descendant::tei:ab//@ref | $items/descendant::tei:ab//@ana where contains($r,'syriaca.org/person/') or contains($r,'syriaca.org/place/') or contains($r,'syriaca.org/keyword/') return string($r), ' ')
    let $dedup := 
        for $t in distinct-values(tokenize($aggGroup,' '))
        return $t     
    let $total := count($dedup) 
    let $persons := $dedup[contains(.,'/person/')]
    let $places := $dedup[contains(.,'/place/')]
    let $keywords := $dedup[contains(.,'/keyword/')]
    let $teiRec :=
        <div xmlns="http://www.w3.org/1999/xhtml" data-template="templates:surround" data-template-with="templates/page.html" data-template-at="content">
            <div class="main-content top-padding">
                <h1>Browse</h1>
                <div class="tabbable">
                    <ul class="nav nav-tabs" role="tablist">
                     <li role="presentation" class="active"><a href="#persons" aria-controls="persons" role="tab" data-toggle="tab">Persons</a></li>
                     <li role="presentation"><a href="#places" aria-controls="places" role="tab" data-toggle="tab">Places</a></li>
                     <li role="presentation"><a href="#keywords" aria-controls="keywords" role="tab" data-toggle="tab">Keywords</a></li>
                 </ul>
                 <div class="tab-content">
                     <div role="tabpanel" class="tab-pane active" id="persons">
                         {
                            let $personsRec := doc('/db/apps/spear/resources/indexes/personsIndex.xml')//tei:person
                            for $p in $persons
                            let $persInfo := $personsRec[tei:idno = $p]
                            let $title := if($persInfo/descendant-or-self::tei:title/descendant-or-self::text()) then 
                                            normalize-space(string-join($persInfo/descendant-or-self::tei:title[1]/descendant-or-self::text(),''))
                                          else 'No title'
                            let $url := concat('/db/apps/spear/aggregate/',tokenize($p,'/')[4],'/',tokenize($p,'/')[last()],'.html')
                            let $sortLetter := substring($title,1,1)
                            order by $sortLetter
                            return <div class="results" sort="{$sortLetter}"><a href="{$url}">{$title}</a></div>
                         }
                     </div> 
                     <div role="tabpanel" class="tab-pane active" id="places">
                         {
                            let $placesRec := doc('/db/apps/spear/resources/indexes/placesIndex.xml')//tei:place
                            for $p in $places
                            let $placeInfo := $placesRec[tei:idno = $p]
                            let $title := if($placeInfo/descendant-or-self::tei:title/descendant-or-self::text()) then 
                                            normalize-space(string-join($placeInfo/descendant-or-self::tei:title[1]/descendant-or-self::text(),''))
                                          else 'No title'
                            let $url := concat('/db/apps/spear/aggregate/',tokenize($p,'/')[4],'/',tokenize($p,'/')[last()],'.html')
                            let $sortLetter := substring($title,1,1)
                            order by $sortLetter[1]
                            return <div class="results" sort="{$sortLetter}"><a href="{$url}">{$title}</a></div>
                         }
                     </div>
                     <div role="tabpanel" class="tab-pane active" id="keywords">
                         {
                            let $keyRec := doc('/db/apps/spear/resources/indexes/keywordIndex.xml')//tei:keyword
                            for $p in $keywords
                            let $keyInfo := $keyRec[tei:idno = $p]
                            let $title := if($keyInfo/descendant-or-self::tei:title/descendant-or-self::text()) then 
                                            normalize-space(string-join($keyInfo/descendant-or-self::tei:title[1]/descendant-or-self::text(),''))
                                          else 'No title'
                            let $url := concat('/db/apps/spear/aggregate/',tokenize($p,'/')[4],'/',tokenize($p,'/')[last()],'.html')
                            let $sortLetter := substring($title,1,1)
                            order by $sortLetter[1]
                            return <div class="results" sort="{$sortLetter}"><a href="{$url}">{$title}</a></div>
                         }
                     </div> 
                    </div>
                </div>
            </div>
        </div>
    let $htmlPath := '/db/apps/spear'        
    return 
        try {xmldb:store($htmlPath, 'browseStatic.html', $teiRec)} 
        catch *{
                    <response status="fail">
                        <message>Failed to add resource personsIndex : {concat($err:code, ": ", $err:description)}</message>
                    </response>
                }                
};

<div>{    
if(request:get-parameter('type', '') = 'factoids') then 
    local:buildFactoids()
else if(request:get-parameter('type', '') = 'aggregate') then
    local:buildAggregate()
else if(request:get-parameter('type', '') = 'personIndex') then
    local:buildPersonIndex()
else if(request:get-parameter('type', '') = 'placeIndex') then
    local:buildPlaceIndex()    
else if(request:get-parameter('type', '') = 'keywordIndex') then
    local:buildKeywordIndex()    
else if(request:get-parameter('type', '') = 'browse') then
    local:buildBrowsePage()    
else <div>In correct parameters, see instructions. </div>
}</div>