xquery version "3.0";
(:
 : Convert TEI to triples as defined by the syriaca.org project
:)
declare namespace srophe = "https://srophe.app";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:method "text";
declare option output:media-type "text/turtle";
declare option output:indent "yes";
(:method=text media-type=text/turtle indent=yes:)

(:~
 : Create an RDF URI
 : @param $uri uri/id as xs:string 
 :)
declare function local:make-uri($uri){
    concat('<',normalize-space($uri),'>')
};

(:~ 
 : Build literal string, normalize spaces and strip "", add lang if specified
 : @param $string string for literal
 : @param $lang language code as xs:string  
 :)
declare function local:make-literal($string as xs:string*, $lang as xs:string*, $datatype as xs:string?) as xs:string?{
    concat('"',replace(normalize-space(string-join($string,' ')),'"',''),'"',
        if($lang != '') then 
            let $langString := 
                if(contains($lang,'-')) then substring-before($lang,'-')
                else if(contains($lang,'en')) then 'en'
                else if(contains($lang,'syr')) then 'syr'
                else $lang
            return concat('@',$langString) 
        else (), 
        if($datatype != '') then concat('^^',$datatype) else()) 
};

(:~ 
 : Build basic triple string, output as string. 
 : @param $s triple subject
 : @param $o triple object
 : @param $p triple predicate
 :)
declare function local:make-triple($s as xs:string?, $o as xs:string?, $p as xs:string?) as xs:string* {
    concat('&#xa;', $s,' ', $o,' ', $p, ' .')
};

(: Create dates :)
declare function local:make-date($date){
    if($date castable as xs:dateTime) then 
        local:make-literal($date, (),'xsd:dateTime')
    else if($date castable as xs:gYearMonth) then
        local:make-literal($date, (),'xsd:gYearMonth')
    else if($date castable as xs:date) then 
        local:make-literal($date, (),'xsd:date')                        
    else if($date castable as xs:gYear) then 
        local:make-literal($date, (),'xsd:gYear') 
    else local:make-literal($date, (),())        
};

declare function local:make-dates-simple($date, $id, $instanceID, $type){
    if($date/@when) then
            local:make-triple(concat('swds:',$type,'-',$instanceID), 'spq:when', local:make-date(string($date/@when)))
        else if($date/@notBefore) then 
            local:make-triple(concat('swds:',$type,'-',$instanceID), 'spq:not-before', local:make-date(string($date/@notBefore)))
        else if($date/@notAfter) then 
            local:make-triple(concat('swds:',$type,'-',$instanceID), 'spq:not-after', local:make-date(string($date/@notAfter)))
        else if($date/@from) then 
            local:make-triple(concat('swds:',$type,'-',$instanceID), 'spq:from', local:make-date(string($date/@from)))
        else if($date/@to) then 
            local:make-triple(concat('swds:',$type,'-',$instanceID), 'spq:not-to', local:make-date(string($date/@to)))
        else ()

};
declare function local:make-date-triples($date, $id, $instanceID, $type){
if($date/@when != '') then
    (
        local:make-triple(local:make-uri($id), concat('swdt:',$type,'-when'), local:make-date(string($date/@when))),
        local:make-triple(local:make-uri($id), concat('sp:',$type,'-when'), concat('swds:',$type,'-when','-',$instanceID)),
        local:make-triple(concat('swds:',$type,'-when','-',$instanceID), concat('sps:',$type,'-when'), local:make-date(string($date/@when))),
        local:make-triple(concat('swds:',$type,'-when','-',$instanceID), 'spr:reference-URL', local:make-uri($id))
    )
else if($date/@notBefore != '') then
    if($date/@notAfter) then 
        (
            local:make-triple(local:make-uri($id), concat('swdt:',$type,'-notBefore'), local:make-date(string($date/@notBefore))),
            local:make-triple(local:make-uri($id), concat('sp:',$type,'-notBefore'), concat('swds:',$type,'-notBefore','-',$instanceID)),
            local:make-triple(concat('swds:',$type,'-notBefore','-',$instanceID), concat('sps:',$type,'-notBefore'), local:make-date(string($date/@notBefore))),
            local:make-triple(concat('swds:',$type,'-notBefore','-',$instanceID), 'spr:reference-URL', local:make-uri($id)),
            local:make-triple(local:make-uri($id), concat('swdt:',$type,'-notAfter'), local:make-date(string($date/@notAfter))),
            local:make-triple(local:make-uri($id), concat('sp:',$type,'-notAfter'), concat('swds:',$type,'-notAfter','-',$instanceID)),
            local:make-triple(concat('swds:',$type,'-notAfter','-',$instanceID), concat('sps:',$type,'-notAfter'), local:make-date(string($date/@notAfter))),
            local:make-triple(concat('swds:',$type,'-notAfter','-',$instanceID), 'spr:reference-URL', local:make-uri($id))
        )
    else 
        (
                local:make-triple(local:make-uri($id), concat('swdt:',$type,'-notBefore'), local:make-date(string($date/@notBefore))),
                local:make-triple(local:make-uri($id), concat('sp:',$type,'-notBefore'), concat('swds:',$type,'-notBefore','-',$instanceID)),
                local:make-triple(concat('swds:',$type,'-notBefore','-',$instanceID), concat('sps:',$type,'-notBefore'), local:make-date(string($date/@notBefore))),
                local:make-triple(concat('swds:',$type,'-notBefore','-',$instanceID), 'spr:reference-URL', local:make-uri($id))
                )
        else if($date/@notAfter) then
            (
                local:make-triple(local:make-uri($id), concat('swdt:',$type,'-notAfter'), local:make-date(string($date/@notAfter))),
                local:make-triple(local:make-uri($id), concat('sp:',$type,'-notAfter'), concat('swds:',$type,'-notAfter','-',$instanceID)),
                local:make-triple(concat('swds:',$type,'-notAfter','-',$instanceID), concat('sps:',$type,'-notAfter'), local:make-date(string($date/@notAfter))),
                local:make-triple(concat('swds:',$type,'-notAfter','-',$instanceID), 'spr:reference-URL', local:make-uri($id))
            )
        else if($date/@from != '') then
            if($date/@to) then 
            (
                local:make-triple(local:make-uri($id), concat('swdt:',$type,'-from'), local:make-date(string($date/@from))),
                local:make-triple(local:make-uri($id), concat('sp:',$type,'-from'), concat('swds:',$type,'-from','-',$instanceID)),
                local:make-triple(concat('swds:',$type,'-from','-',$instanceID), concat('sps:',$type,'-from'), local:make-date(string($date/@from))),
                local:make-triple(concat('swds:',$type,'-from','-',$instanceID), 'spr:reference-URL', local:make-uri($id)),
                local:make-triple(local:make-uri($id), concat('swdt:',$type,'-to'), local:make-date(string($date/@to))),
                local:make-triple(local:make-uri($id), concat('sp:',$type,'-to'), concat('swds:',$type,'-to','-',$instanceID)),
                local:make-triple(concat('swds:',$type,'-to','-',$instanceID), concat('sps:',$type,'-to'), local:make-date(string($date/@to))),
                local:make-triple(concat('swds:',$type,'-to','-',$instanceID), 'spr:reference-URL', local:make-uri($id))
            )
            else 
                (
                local:make-triple(local:make-uri($id), concat('swdt:',$type,'-from'), local:make-date(string($date/@from))),
                local:make-triple(local:make-uri($id), concat('sp:',$type,'-from'), concat('swds:',$type,'-from','-',$instanceID)),
                local:make-triple(concat('swds:',$type,'-from','-',$instanceID), concat('sps:',$type,'-from'), local:make-date(string($date/@from))),
                local:make-triple(concat('swds:',$type,'-from','-',$instanceID), 'spr:reference-URL', local:make-uri($id))
                )
        else if($date/@to) then
            (
                local:make-triple(local:make-uri($id), concat('swdt:',$type,'-to'), local:make-date(string($date/@to))),
                local:make-triple(local:make-uri($id), concat('sp:',$type,'-to'), concat('swds:',$type,'-to','-',$instanceID)),
                local:make-triple(concat('swds:',$type,'-to','-',$instanceID), concat('sps:',$type,'-to'), local:make-date(string($date/@to))),
                local:make-triple(concat('swds:',$type,'-to','-',$instanceID), 'spr:reference-URL', local:make-uri($id))
            )        
        else ()
};
declare function local:rec-type($node){
    if($node/descendant::tei:body/tei:listPerson) then
        'lawd:Person'
    else if($node/descendant::tei:body/tei:listPlace) then
        'lawd:Place'
    else if($node/descendant::tei:body/tei:bibl[@type="lawd:ConceptualWork"]) then
        'lawd:conceptualWork'
    else if($node/descendant::tei:body/tei:biblStruct) then
        'dcterms:bibliographicResource'        
    else if($node/tei:listPerson) then
       'syriaca:personFactoid'    
    else if($node/tei:listEvent) then
        'syriaca:eventFactoid'
    else if($node/tei:listRelation) then
        'syriaca:relationFactoid'
    else()
};

declare function local:make-triple-set($node){
let $idno := ($node/descendant::tei:idno[@type='URI'], $node/descendant::tei:idno)[1]
let $id := if(ends-with($idno,'/tei')) then replace($idno,'/tei','') else $idno
let $type := local:rec-type($node)
let $typeShort := tokenize($type,':')[last()]
let $idShort := tokenize($id,'/')[last()]
return 
    if($type = 'lawd:Person') then 
        (
        local:make-triple(local:make-uri($id), 'rdf:type', local:rec-type($node)),
        local:persons($node, $id, $idShort, $typeShort)
        )
    else if($type = 'lawd:Place') then 
        (
        local:make-triple(local:make-uri($id), 'rdf:type', local:rec-type($node)),
        local:places($node, $id, $idShort, $typeShort)
        )         
    else local:make-triple(local:make-uri($id), 'rdf:type', local:rec-type($node))
};

declare function local:places($node, $id, $idShort, $typeShort){
(
(:Series statement:)
    for $series in $node/descendant::tei:seriesStmt
    return local:make-triple(local:make-uri($id), 'rdfs:partOf', local:make-uri($series/tei:idno/text())),
(: RDFs Label from headwords:)
    for $headword in $node/descendant::tei:palce/tei:placeName[@srophe:tags='#syriaca-headword']
    let $lang := $headword/@xml:lang
    return local:make-triple(local:make-uri($id), 'rdfs:label', local:make-literal($headword/descendant-or-self::text(),$lang,'')),
(: hasCitation - bibl referenes :)
    for $citation in $node/descendant::tei:bibl/tei:ptr/@target[contains(., 'syriaca.org/bibl')]
    return local:make-triple(local:make-uri($id), 'lawd:hasCitation', local:make-uri($citation)),
(:primaryTopicOf idno in publication statement :)
    local:make-triple(local:make-uri($id), 'foaf:primaryTopicOf', local:make-uri($node/descendant::tei:publicationStmt/tei:idno/text())),
    local:make-triple(local:make-uri($id), 'foaf:primaryTopicOf', local:make-uri(replace($node/descendant::tei:publicationStmt/tei:idno/text(),'/tei','/html'))),
(: dcterms:hasFormat idno in publication statement :)
    local:make-triple(local:make-uri($id), 'dcterms:hasFormat', local:make-uri($node/descendant::tei:publicationStmt/tei:idno/text())),
    local:make-triple(local:make-uri($id), 'dcterms:hasFormat', local:make-uri(replace($node/descendant::tei:publicationStmt/tei:idno/text(),'/tei','/html'))),
(: Description/abstract :)
    for $note in $node/descendant::tei:note[@type='abstract']
    return local:make-triple(local:make-uri($id), 'schema:description', local:make-literal($note/descendant-or-self::text(),$note/@xml:lang,'')),
(:WS:NOTE literal does not work
    Description/abstract as an XML literal
    for $note in $node/descendant::tei:note[@type='abstract']
    return local:make-triple('', 'rdfs:XMLLiteral', concat('"',$note/self::*,'"')),
    :) 
(: relations :)
    for $relPers in $node/descendant::tei:text/descendant::tei:persName/@ref
    return local:make-triple(local:make-uri($id), 'dcterms:relation', local:make-uri($relPers)),
    for $relPlace in $node/descendant::tei:text/descendant::tei:placeName/@ref
    return local:make-triple(local:make-uri($id), 'dcterms:relation', local:make-uri($relPlace)),

(: Name varients :)
    for $nameVariant in $node/descendant::tei:place/tei:placeName 
    return local:make-triple(local:make-uri($id), 'swdt:name-variant', local:make-literal($nameVariant/descendant-or-self::text(),$nameVariant/@xml:lang,'')),
    
    (: Name variant unique statement instance :)
    for $nameVariant at $p in $node/descendant::tei:place/tei:placeName
    let $instanceID := concat($idShort,'-',$p)
    return 
        (local:make-triple(local:make-uri($id), 'sp:name-variant', concat('swds:',$typeShort,'-',$instanceID)),
        local:make-triple(concat('swds:',$typeShort,'-',$instanceID), 'sps:name-variant', local:make-literal($nameVariant/descendant-or-self::text(),$nameVariant/@xml:lang,'')),
        local:make-triple(concat('swds:',$typeShort,'-',$instanceID), 'spr:reference-URL', local:make-uri($id))
        ),
(:IDNO :) 
    for $closeMatch at $p in $node/descendant::tei:text/descendant::tei:idno[@type ='URI'][not(contains(., "syriaca.org"))][not(contains(., "/viaf.org/viaf/"))][not(contains(., "/www.csc.org.il/db/browse.aspx"))]
    let $instanceID := concat($idShort,'-',$p)    
    return 
        (local:make-triple(local:make-uri($id), 'swdt:closeMatch', local:make-literal($closeMatch,'','')),
        local:make-triple(local:make-uri($id), 'sp:closeMatch', concat('swds:closeMatch-',$instanceID)),
        local:make-triple(concat('swds:closeMatch-',$instanceID), 'sps:closeMatch', local:make-literal($closeMatch,'','')),
        local:make-triple(concat('swds:closeMatch-',$instanceID), 'spr:reference-URL', local:make-uri($id))
        ),
(: Events state[@type='existence']:)        
    for $event at $p in $node/descendant::tei:text/descendant::tei:state[@type='existence']
    let $instanceID := concat($idShort,'-',$p)
    return local:make-date-triples($event, $id, $instanceID, 'exist'),    
(: GPS :)        
    for $gps at $p in $node/descendant::tei:text/descendant::tei:location[@type='gps']
    let $instanceID := concat($idShort,'-',$p)
    return
        (
            local:make-triple(local:make-uri($id), 'swdt:has-gps-coordinates', local:make-literal($gps/descendant::text(),'','')),
            local:make-triple(local:make-uri($id), 'sp:has-gps-coordinates', concat('swds:coordinates','-',$instanceID)),
            local:make-triple(concat('swds:coordinates','-',$instanceID), 'sps:exist-to', local:make-literal($gps/descendant::text(),'','')),
            local:make-triple(concat('swds:coordinates','-',$instanceID), 'spr:reference-URL', local:make-uri($id))
        ),
(: Religious community has-religious-community  place/state[@type='confession']/@ref :)
    for $religiousCom at $p in $node/descendant::tei:text/descendant::tei:place/tei:state[@type='confession'][@ref != '']
    let $ref := $religiousCom/@ref
    let $instanceID := concat($idShort,'-',$p)
    return 
        (
        local:make-triple(local:make-uri($id), 'swdt:has-religious-community', local:make-uri($ref)),
        local:make-triple(local:make-uri($id), 'sp:has-religious-community', concat('swds:has-religious-community-',$instanceID)),
        local:make-triple(concat('swds:has-religious-community-',$instanceID), 'sps:has-religious-community', local:make-uri($ref)),
        local:make-triple(concat('swds:has-religious-community-',$instanceID), 'spr:reference-URL', local:make-uri($id)),
        local:make-dates-simple($religiousCom, $id, $instanceID, 'has-religious-community')
        ),
(: Relationships :)
     for $relation at $p in $node/descendant::tei:text/descendant::tei:relation
     let $instanceID := concat($idShort,'-',$p)
     return local:relationship-triples($relation, $id, $instanceID)         
)
};

declare function local:persons($node, $id, $idShort, $typeShort){
(
(:Series statement:)
    for $series in $node/descendant::tei:seriesStmt
    return local:make-triple(local:make-uri($id), 'rdfs:partOf', local:make-uri($series/tei:idno/text())),
(: RDFs Label from headwords:)
    for $headword in $node/descendant::tei:person/tei:persName[@srophe:tags='#syriaca-headword'] | $node/descendant::tei:personGrp/tei:persName[@srophe:tags='#syriaca-headword']
    let $lang := $headword/@xml:lang
    return local:make-triple(local:make-uri($id), 'rdfs:label', local:make-literal($headword/descendant-or-self::text(),$lang,'')), 
(: hasCitation - bibl referenes :)
    for $citation in $node/descendant::tei:bibl/tei:ptr/@target[contains(., 'syriaca.org/bibl')]
    return local:make-triple(local:make-uri($id), 'rdfs:label', local:make-uri($citation)),
(:primaryTopicOf idno in publication statement :)
    local:make-triple(local:make-uri($id), 'foaf:primaryTopicOf', local:make-uri($node/descendant::tei:publicationStmt/tei:idno/text())),
    local:make-triple(local:make-uri($id), 'foaf:primaryTopicOf', local:make-uri(replace($node/descendant::tei:publicationStmt/tei:idno/text(),'/tei','/html'))),
(: dcterms:hasFormat idno in publication statement :)
    local:make-triple(local:make-uri($id), 'dcterms:hasFormat', local:make-uri($node/descendant::tei:publicationStmt/tei:idno/text())),
    local:make-triple(local:make-uri($id), 'dcterms:hasFormat', local:make-uri(replace($node/descendant::tei:publicationStmt/tei:idno/text(),'/tei','/html'))),
(: Description/abstract :)
    for $note in $node/descendant::tei:note[@type='abstract']
    return local:make-triple(local:make-uri($id), 'schema:description', local:make-literal($note/descendant-or-self::text(),$note/@xml:lang,'')),
(:WS:NOTE literal does not work
    Description/abstract as an XML literal
    for $note in $node/descendant::tei:note[@type='abstract']
    return local:make-triple('', 'rdfs:XMLLiteral', concat('"',$note/self::*,'"')),
    :)
(: relations :)
    for $relPers in $node/descendant::tei:text/descendant::tei:persName/@ref
    return local:make-triple(local:make-uri($id), 'foaf:primaryTopicOf', local:make-uri($relPers)),
    for $relPlace in $node/descendant::tei:text/descendant::tei:placeName/@ref
    return local:make-triple(local:make-uri($id), 'foaf:primaryTopicOf', local:make-uri($relPlace)),
(: Name varients :)
    for $nameVariant in $node/descendant::tei:person/tei:persName | $node/descendant::tei:personGrp/tei:persName
    return local:make-triple(local:make-uri($id), 'swdt:name-variant', local:make-literal($nameVariant/descendant-or-self::text(),$nameVariant/@xml:lang,'')),
    
    (: Name variant unique statement instance :)
    for $nameVariant at $p in $node/descendant::tei:person/tei:persName | $node/descendant::tei:personGrp/tei:persName
    let $instanceID := concat($idShort,'-',$p)
    return 
        (local:make-triple(local:make-uri($id), 'sp:name-variant', concat('swds:',$typeShort,'-',$instanceID)),
        local:make-triple(concat('swds:',$typeShort,'-',$instanceID), 'sps:name-variant', local:make-literal($nameVariant/descendant-or-self::text(),$nameVariant/@xml:lang,'')),
        local:make-triple(concat('swds:',$typeShort,'-',$instanceID), 'spr:reference-URL', local:make-uri($id))
        ),
(:IDNO :) 
    for $closeMatch at $p in $node/descendant::tei:text/descendant::tei:idno[@type ='URI'][not(contains(., "syriaca.org"))][not(contains(., "/viaf.org/viaf/"))][not(contains(., "/www.csc.org.il/db/browse.aspx"))]
    let $instanceID := concat($idShort,'-',$p)
    return 
        (local:make-triple(local:make-uri($id), 'swdt:closeMatch', local:make-literal($closeMatch,'','')),
        local:make-triple(local:make-uri($id), 'sp:closeMatch', concat('swds:closeMatch-',$instanceID)),
        local:make-triple(concat('swds:closeMatch-',$instanceID), 'sps:closeMatch', local:make-literal($closeMatch,'','')),
        local:make-triple(concat('swds:closeMatch-',$instanceID), 'spr:reference-URL', local:make-uri($id))
        ),
(: Floruit :)
    for $floruit at $p in $node/descendant::tei:text/descendant::tei:floruit/tei:date
    let $instanceID := concat($idShort,'-',$p)
    return local:make-date-triples($floruit, $id, $instanceID, 'floruit'), 
(:Birth Dates:)
    for $birth at $p in $node/descendant::tei:text/descendant::tei:birth/tei:date
    let $instanceID := concat($idShort,'-',$p)
    return local:make-date-triples($birth, $id, $instanceID, 'birth'),
(:Death Dates:)
    for $death at $p in $node/descendant::tei:text/descendant::tei:death/tei:date
    let $instanceID := concat($idShort,'-',$p)
    return local:make-date-triples($death, $id, $instanceID, 'death'),
(: Birth Place:)
    for $birthPlace at $p in $node/descendant::tei:text/descendant::tei:birth[tei:placeName]/tei:placeName[@ref]
    let $ref := $birthPlace/@ref
    let $instanceID := concat($idShort,'-',$p)
    return 
        (
        local:make-triple(local:make-uri($id), 'swdt:birth-place', local:make-uri($ref)),
        local:make-triple(local:make-uri($id), 'sp:birth-place', concat('swds:birth-place-',$instanceID)),
        local:make-triple(concat('swds:birth-place-',$instanceID), 'sps:birth-place', local:make-uri($ref)),
        local:make-triple(concat('swds:birth-place-',$instanceID), 'spr:reference-URL', local:make-uri($id))
        ),
(: Death Place:)
    for $deathPlace at $p in $node/descendant::tei:text/descendant::tei:death[tei:placeName]/tei:placeName[@ref]
    let $ref := $deathPlace/@ref
    let $instanceID := concat($idShort,'-',$p)
    return 
        (
        local:make-triple(local:make-uri($id), 'swdt:death-place', local:make-uri($ref)),
        local:make-triple(local:make-uri($id), 'sp:death-place', concat('swds:death-place-',$instanceID)),
        local:make-triple(concat('swds:death-place-',$instanceID), 'sps:death-place', local:make-uri($ref)),
        local:make-triple(concat('swds:death-place-',$instanceID), 'spr:reference-URL', local:make-uri($id))
        ),
(: Gender Place:)
    for $gender at $p in $node/descendant::tei:text/descendant::tei:gender[@ana]
    for $ana in tokenize($gender/@ana,' ')
    let $ref := $ana
    let $instanceID := concat($idShort,'-',$p)
    return 
        (
        local:make-triple(local:make-uri($id), 'swdt:gender', local:make-uri($ref)),
        local:make-triple(local:make-uri($id), 'sp:gender', concat('swds:gender-',$instanceID)),
        local:make-triple(concat('swds:gender-',$instanceID), 'sps:gender', local:make-uri($ref)),
        local:make-triple(concat('swds:gender-',$instanceID), 'spr:reference-URL', local:make-uri($id))
        ),
(: WS:Note, may be an issue with the first triple because these are uris may need some help here 
    Occupation :)    
    for $occupation at $p in $node/descendant::tei:text/descendant::tei:state[@type='occupation'][@ref != '']
    let $ref := $occupation/@ref
    let $instanceID := concat($idShort,'-',$p)
    return 
        (
        local:make-triple(local:make-uri($id), 'swdt:occupation', local:make-uri($ref)),
        local:make-triple(local:make-uri($id), 'sp:occupation', concat('swds:occupation-',$instanceID)),
        local:make-triple(concat('swds:occupation-',$instanceID), 'sps:occupation', local:make-uri($ref)),
        local:make-triple(concat('swds:occupation-',$instanceID), 'spr:reference-URL', local:make-uri($id)),
        local:make-dates-simple($occupation, $id, $instanceID, 'occupation')
        ), 
(: WS:Note, may be an issue with the first triple because these are uris may need some help here 
    Socio Economic Status :)    
    for $economic at $p in $node/descendant::tei:text/descendant::tei:state[@type='socio-economic-status'][@ref != '']
    let $ref := $economic/@ref
    let $instanceID := concat($idShort,'-',$p)
    return 
        (
        local:make-triple(local:make-uri($id), 'swdt:socio-economic-status', local:make-uri($ref)),
        local:make-triple(local:make-uri($id), 'sp:socio-economic-status', concat('swds:socio-economic-status-',$instanceID)),
        local:make-triple(concat('swds:socio-economic-status-',$instanceID), 'sps:socio-economic-status', local:make-uri($ref)),
        local:make-triple(concat('swds:socio-economic-status-',$instanceID), 'spr:reference-URL', local:make-uri($id)),
        local:make-dates-simple($economic, $id, $instanceID, 'socio-economic-status')
        ),
(: WS:Note, may be an issue with the first triple because these are uris may need some help here 
    Status :)    
    for $status at $p in $node/descendant::tei:text/descendant::tei:state[@type='status'][@ref != '']
    let $ref := $status/@ref
    let $instanceID := concat($idShort,'-',$p)
    return 
        (
        local:make-triple(local:make-uri($id), 'swdt:status', local:make-uri($ref)),
        local:make-triple(local:make-uri($id), 'sp:status', concat('swds:status-',$instanceID)),
        local:make-triple(concat('swds:status-',$instanceID), 'sps:status', local:make-uri($ref)),
        local:make-triple(concat('swds:status-',$instanceID), 'spr:reference-URL', local:make-uri($id)),
        local:make-dates-simple($status, $id, $instanceID, 'status')
        ),
(: WS:Note, may be an issue with the first triple because these are uris may need some help here 
    commemorates :)    
    for $commemorates at $p in $node/descendant::tei:text/descendant::tei:event[@type='veneration'][descendant::tei:rs[@ref != '']]
    let $ref := $commemorates/descendant::tei:rs/@ref
    let $instanceID := concat($idShort,'-',$p)
    return 
        (
        local:make-triple(local:make-uri($ref), 'swdt:commemorates' ,local:make-uri($id)),
        local:make-triple(local:make-uri($ref), 'sp:commemorates' ,concat('swds:commemorates-',$instanceID)),
        local:make-triple(concat('swds:commemorates-',$instanceID), 'sps:commemorates' ,local:make-uri($id)),
        local:make-triple(concat('swds:commemorates-',$instanceID), 'spr:reference-URL', local:make-uri($id)),
        local:make-dates-simple($commemorates, $id, $instanceID, 'commemorates')
        ),
(: Relationships :)
     for $relation at $p in $node/descendant::tei:text/descendant::tei:relation
     let $instanceID := concat($idShort,'-',$p)
     return local:relationship-triples($relation, $id, $instanceID) 
)
};

declare function local:relationship-triples($relation, $id, $instanceID){
let $relRef := substring-after($relation/@ref,'taxonomy/')
     return (
        for $s at $ap in tokenize($relation/@active,' ')
        let $sRef := $s
        return
           for $o at $op in tokenize($relation/@passive,' ')
           let $oRef := $o
           return
               (
               local:make-triple(local:make-uri($sRef), concat('swdt:',$relRef), local:make-uri($oRef)),
               local:make-triple(local:make-uri($sRef), concat('sp:',$relRef), concat('swds:activeRelation',$relRef,'-',$instanceID,$ap)),
               local:make-triple(concat('swds:activeRelation',$relRef,'-',$instanceID,$ap), concat('swd:',$relRef), local:make-uri($oRef)),
               local:make-triple(concat('swds:activeRelation',$relRef,'-',$instanceID,$ap), 'spr:reference-URL', local:make-uri($id))
               ), 
          for $s at $m1p in tokenize($relation/@mutual,' ')
          let $sRef := $s
          return   
            for $o at $m2p in tokenize($relation/@mutual,' ')[. != $s]
            let $oRef := $o
            return 
               (
               local:make-triple(local:make-uri($sRef), concat('swdt:',$relRef), local:make-uri($oRef)),
               local:make-triple(local:make-uri($sRef), concat('sp:',$relRef), concat('swds:activeRelation',$relRef,'-',$instanceID,$m1p)),
               local:make-triple(concat('swds:activeRelation',$relRef,'-',$instanceID,$m1p), concat('swd:',$relRef), local:make-uri($oRef)),
               local:make-triple(concat('swds:activeRelation',$relRef,'-',$instanceID,$m1p), 'spr:reference-URL', local:make-uri($id)),
               
               local:make-triple(local:make-uri($oRef), concat('swdt:',$relRef), local:make-uri($sRef)),
               local:make-triple(local:make-uri($oRef), concat('sp:',$relRef), concat('swds:activeRelation',$relRef,'-',$instanceID,$m2p)),
               local:make-triple(concat('swds:activeRelation',$relRef,'-',$instanceID,$m2p), concat('swd:',$relRef), local:make-uri($sRef)),
               local:make-triple(concat('swds:activeRelation',$relRef,'-',$instanceID,$m2p), 'spr:reference-URL', local:make-uri($id))
               )
        )
};

declare function local:make-SPEAR-triples($node){
let $rec := $node/child::*[1]
let $recID := replace($rec/descendant::tei:publicationStmt/tei:idno,'/tei','')
for $factoid in $rec/descendant-or-self::tei:ab
let $id := $factoid/tei:idno[@type="URI"]
let $idShort := tokenize($id,'/')[last()]
let $factoidRef := tokenize($factoid/tei:idno[@type="URI"], "/")[last()]
let $persRef := 
                    if($factoid/descendant::tei:person/tei:persName) then
                       $factoid/descendant::tei:person/tei:persName/@ref
                    else $factoid/descendant::tei:persName[1]/@ref
let $labelNode := 
                 if($factoid/tei:listEvent/tei:event/descendant::tei:desc) then
                    $factoid/tei:listEvent/tei:event/descendant::tei:desc[1]
                 else if($factoid/descendant::tei:listPerson) then 
                    string-join($factoid/descendant::tei:listPerson/descendant::tei:persName/text(),' ')   
                 else if($factoid/descendant::tei:note) then
                    $factoid/descendant::tei:note[1]
                  else if($factoid/descendant::tei:desc) then
                    $factoid/descendant::tei:desc[1]
                  else
                    string-join(($factoid/child::*[not(self::tei:idno) and not(self::tei:bibl)]),'')      
let $labelLiteral := local:make-literal(string($labelNode), 'en',())
(:
let $descHTML := serialize(('"""',$labelNode,'"""'), 
                        <output:serialization-parameters>
                            <output:method>html</output:method>
                        </output:serialization-parameters>)
:)                        
return 
(
    if($labelLiteral != '') then
            local:make-triple(local:make-uri($id),'schema:description', $labelLiteral)  
    else (),
    (:,
    if($descHTML != '') then
            local:make-triple(local:make-uri($id),'rdf:XMLLiteral ', $descHTML)   
    else ()
    :)
    (: idnos, creator :)
    for $series in $rec/descendant-or-self::tei:seriesStmt/tei:idno[@type='URI']
    return local:make-triple(local:make-uri($id),'spr:part-of-series', local:make-uri($series)),
    for $publicationStmt in $rec/descendant-or-self::tei:publicationStmt/tei:idno[@type='URI']
    return local:make-triple(local:make-uri($id),'spr:part-of-series', local:make-uri($recID)),
    for $creator in tokenize($factoid/@resp,' ')
    let $nameURI := if(starts-with($creator,'http')) then $creator else concat('http://syriaca.org/documentation/editors.xml',$creator)              
    return local:make-triple(local:make-uri($id),'spr:creator', local:make-uri($nameURI)),
    for $bibl in $factoid/tei:bibl
    let $biblref := $bibl/tei:ptr/@target
    return 
        if($bibl[@type='URN']) then 
          local:make-triple(local:make-uri($id),'spr:reference-bibl', local:make-uri($biblref))  
        else local:make-triple(local:make-uri($id),'spr:reference-bibl', local:make-uri($biblref)),
    for $certainty in $factoid/tei:note[@type='certainty']
    let $certaintyref := $certainty/@subtype
    return local:make-triple(local:make-uri($id),'spq:certainty', local:make-literal($certaintyref,'en','')),
    
    for $birth at $p in $factoid[@subtype='birth']/descendant::tei:birth
    let $instanceID := concat($idShort,'-',$p)
    return 
    (
        if($birth/tei:placeName) then 
            (
            local:make-triple(local:make-uri($persRef),'swdt:birth-place', local:make-uri($birth/tei:placeName/@ref)),
            local:make-triple(local:make-uri($persRef),'sp:birth-place', concat('swds:birth-place',$instanceID)),
            local:make-triple(concat('swds:birth-place',$instanceID),'sps:birth-place', local:make-uri($birth/tei:placeName/@ref)),
            local:make-triple(concat('swds:birth-place',$instanceID),'spr:reference-URL', local:make-uri($id))
            )
        else (),
    local:make-date-triples($birth, $persRef, $instanceID, 'birth')
    ),
   for $death at $p in $factoid[@subtype='death']/descendant::tei:death
   let $instanceID := concat($idShort,'-',$p)
   return 
        (
        if($death/tei:placeName) then 
            (
            local:make-triple(local:make-uri($persRef),'swdt:death-place', local:make-uri($death/tei:placeName/@ref)),
            local:make-triple(local:make-uri($persRef),'sp:death-place', concat('swds:death-place',$instanceID)),
            local:make-triple(concat('swds:death-place',$instanceID),'sps:death-place', local:make-uri($death/tei:placeName/@ref)),
            local:make-triple(concat('swds:death-place',$instanceID),'spr:reference-URL', local:make-uri($id))
            )
        else (),
        local:make-date-triples($death, $persRef, $instanceID, 'death')
        ),
    (: citizenship :)
    for $citizenship in $factoid[@subtype='citizenship']
    let $placeRef := local:make-uri($citizenship/descendant::tei:person/tei:state[@type='citizenship']/tei:placeName/@ref)
    let $citizenStatementInstance := concat($factoidRef,'Inst',replace(generate-id($citizenship),'\.',''))
    return 
        (
        local:make-triple(local:make-uri($persRef),'swdt:citizenship', $placeRef),
        local:make-triple(local:make-uri($persRef),'sp:citizenship', concat('swds:',$citizenStatementInstance)),
        local:make-triple(concat('swds:',$citizenStatementInstance),'sps:citizenship', $placeRef),
        local:make-triple(concat('swds:',$citizenStatementInstance),'spr:reference-URL', local:make-uri($id)),
        for $state at $p in $citizenship/descendant::tei:state
        let $instanceID := concat($idShort,'-',$p)
        return 
            local:make-dates-simple($citizenship, $id, $instanceID, 'citizenship')
        ),
    (:Education:)
    for $education at $p in $factoid[@subtype='education']/descendant-or-self::tei:education
    let $instanceID := concat($idShort,'-',$p)
    return 
        (
            for $eduAna at $n in tokenize($education/@ana, ' ')
            let $eduAnaRef := local:make-uri($eduAna)
            let $eduAnaStatementInstance := concat($factoidRef,'Inst',replace(generate-id($education),'\.',''),$n)
            return 
                (local:make-triple(local:make-uri($persRef),'swdt:education', $eduAnaRef),
                local:make-triple(local:make-uri($persRef),'sp:education', concat('swds:',$eduAnaStatementInstance)),
                local:make-triple(concat('swds:',$eduAnaStatementInstance),'sps:education', $eduAnaRef),
                local:make-triple(concat('swds:',$eduAnaStatementInstance),'spr:reference-URL', local:make-uri($id)),
                local:make-dates-simple($education, $id, $instanceID, 'education')
        )),
    (: ethnicLabel :)
    for $ethnicLabel at $p in $factoid[@subtype='ethnicLabel']/descendant-or-self::tei:trait
    let $instanceID := concat($idShort,'-',$p)
    return 
        (
            for $ethnicLabelAna at $n in tokenize($ethnicLabel/@ana, ' ')
            let $ethnicLabelRef := local:make-uri($ethnicLabelAna)
            let $ethnicAnaStatementInstance := concat($factoidRef,'Inst',replace(generate-id($ethnicLabel),'\.',''), $n)
            return 
                (local:make-triple(local:make-uri($persRef),'swdt:ethnic-label', $ethnicLabelRef),
                local:make-triple(local:make-uri($persRef),'sp:ethnic-label', concat('swds:',$ethnicAnaStatementInstance)),
                local:make-triple(concat('swds:',$ethnicAnaStatementInstance),'sps:ethnic-label', $ethnicLabelRef),
                local:make-triple(concat('swds:',$ethnicAnaStatementInstance),'spr:reference-URL', local:make-uri($id)),
                local:make-dates-simple($ethnicLabel, $id, $instanceID, 'ethnic-label')
        )),
    (:Gender:)
    for $gender at $p in $factoid[@subtype='gender']/descendant-or-self::tei:trait
    let $instanceID := concat($idShort,'-',$p)
    return 
            (
            for $genderAna at $n in tokenize($gender/@ana, ' ')
            let $genderRef := local:make-uri($genderAna)
            let $genderAnaStatementInstance := concat($factoidRef,'Inst',replace(generate-id($gender),'\.',''), $n)
            return 
                (
                local:make-triple(local:make-uri($persRef),'swdt:gender', $genderRef),
                local:make-triple(local:make-uri($persRef),'sp:gender', concat('swds:',$genderAnaStatementInstance)),
                local:make-triple(concat('swds:',$genderAnaStatementInstance),'sps:gender', $genderRef),
                local:make-triple(concat('swds:',$genderAnaStatementInstance),'spr:reference-URL', local:make-uri($id)),
                local:make-dates-simple($gender, $id, $instanceID, 'gender')
            )),
    (: Language :)
    for $lang at $p in $factoid[@subtype='langKnown']/descendant-or-self::tei:langKnowledge
    let $instanceID := concat($idShort,'-',$p)
    return 
            (
            for $langAna at $n in tokenize($lang/tei:langKnown/@ana, ' ')
            let $langRef := local:make-uri($langAna)
            let $langAnaStatementInstance := concat($factoidRef,'Inst',replace(generate-id($lang),'\.',''), $n)
            return 
                (local:make-triple(local:make-uri($persRef),'swdt:language-known', $langRef),
                local:make-triple(local:make-uri($persRef),'sp:language-known', concat('swds:',$langAnaStatementInstance)),
                local:make-triple(concat('swds:',$langAnaStatementInstance),'sps:language-known', $langRef),
                local:make-triple(concat('swds:',$langAnaStatementInstance),'spr:reference-URL', local:make-uri($id)),                            
               local:make-dates-simple($lang, $id, $instanceID, 'language-known')
            )),
    (: Mental State:)            
    for $mentalState at $p in $factoid[@subtype='mentalState']/descendant-or-self::tei:state
    let $instanceID := concat($idShort,'-',$p)
    return 
            (
            for $mentalStateAna at $n in tokenize($mentalState/@ana, ' ')
            let $mentalStateRef := local:make-uri($mentalStateAna)
            let $mentalAnaStatementInstance := concat($factoidRef,'Inst',concat(replace(generate-id($mentalState),'\.',''),$n))
            return 
                (local:make-triple(local:make-uri($persRef),'swdt:mental-state', $mentalStateRef),
                local:make-triple(local:make-uri($persRef),'sp:mental-state', concat('swds:',$mentalAnaStatementInstance)),
                local:make-triple(concat('swds:',$mentalAnaStatementInstance),'sps:mental-state', $mentalStateRef),
                local:make-triple(concat('swds:',$mentalAnaStatementInstance),'spr:reference-URL', local:make-uri($id)),                  
                local:make-dates-simple($mentalState, $id, $instanceID, 'mental-state')
            )),
    (: Name :)
    for $nameVariant at $p in $factoid[@subtype='nameVariant']/descendant-or-self::tei:listPerson/descendant-or-self::tei:persName[1]
    let $nameVariantStatementInstance := concat($factoidRef,'Inst',replace(generate-id($nameVariant),'\.',''))
    let $instanceID := concat($idShort,'-',$p)
    return 
        (
        local:make-triple(local:make-uri($persRef),'swdt:name-variant', local:make-literal(string($nameVariant), 'en',())),
        local:make-triple(local:make-uri($persRef),'sp:name-variant', concat('swds:',$factoidRef)),
        local:make-triple(concat('swds:',$factoidRef),'sps:name-variant', local:make-literal(string($nameVariant), 'en',())),
        local:make-triple(concat('swds:',$factoidRef),'spr:reference-URL', local:make-uri($id))
        ),
    (: occupation :)
    for $occupation at $p in $factoid[@subtype='occupation']/descendant-or-self::tei:occupation
    let $instanceID := concat($idShort,'-',$p)
    return 
        (
        for $occupationAna at $n in tokenize($occupation/@ana, ' ')
        let $occupationRef := local:make-uri($occupationAna)
        let $occupationAnaStatementInstance := concat($factoidRef,'Inst',replace(generate-id($occupation),'\.',''), $n)
        return 
            (local:make-triple(local:make-uri($persRef),'swdt:occupation', $occupationRef),
             local:make-triple(local:make-uri($persRef),'sp:occupation', concat('swds:',$occupationAnaStatementInstance)),
             local:make-triple(concat('swds:',$occupationAnaStatementInstance),'sps:occupation', $occupationRef),
             local:make-triple(concat('swds:',$occupationAnaStatementInstance),'spr:reference-URL', local:make-uri($id)),
             local:make-dates-simple($occupation, $id, $instanceID, 'occupation')
            )),
    (: physicalTrait :)
    for $physicalTrait at $p in $factoid[@subtype='physicalTrait']/descendant-or-self::tei:trait
    let $instanceID := concat($idShort,'-',$p)
    return 
        (
        for $physicalTraitAna at $n in tokenize($physicalTrait/@ana, ' ')
        let $physicalTraitRef := local:make-uri($physicalTraitAna)
        let $physicalTraitAnaStatementInstance := concat($factoidRef,'Inst',replace(generate-id($physicalTrait),'\.',''), $n)
        return 
            (local:make-triple(local:make-uri($persRef),'swdt:physical-trait', $physicalTraitRef),
             local:make-triple(local:make-uri($persRef),'sp:physical-trait', concat('swds:',$physicalTraitAnaStatementInstance)),
             local:make-triple(concat('swds:',$physicalTraitAnaStatementInstance),'sps:physical-trait', $physicalTraitRef),
             local:make-triple(concat('swds:',$physicalTraitAnaStatementInstance),'spr:reference-URL', local:make-uri($id)),
            local:make-dates-simple($physicalTrait, $id, $instanceID, 'physical-trait')
            )),
    (: residence :)
    for $residence at $p in $factoid[@subtype='residence']/descendant-or-self::tei:residence
    let $residenceStatementInstance := concat($factoidRef,'Inst',replace(generate-id($residence),'\.',''))
    let $instanceID := concat($idShort,'-',$p)
    return 
        (local:make-triple(local:make-uri($persRef),'swdt:residence', local:make-uri($residence/tei:placeName/@ref)),
        local:make-triple(local:make-uri($persRef),'sp:residence', concat('swds:',$residenceStatementInstance)),
        local:make-triple(concat('swds:',$residenceStatementInstance),'sps:residence', local:make-uri($residence/tei:placeName/@ref)),
        local:make-triple(concat('swds:',$residenceStatementInstance),'spr:reference-URL', local:make-uri($id)),
        local:make-dates-simple($residence, $id, $instanceID, 'residence')
            ),
    (: sanctity :)
    for $sanctity at $p in $factoid[@subtype='sanctity']/descendant-or-self::tei:state
    let $instanceID := concat($idShort,'-',$p)
    return 
        (
        for $sanctityAna at $n in tokenize($sanctity/@ana, ' ')
        let $sanctityAnaStatementInstance := concat($factoidRef,'Inst',replace(generate-id($sanctity),'\.',''), $n)
        return 
            (local:make-triple(local:make-uri($persRef),'swdt:sanctity', local:make-uri($sanctityAna)),
             local:make-triple(local:make-uri($persRef),'sp:sanctity', concat('swds:',$sanctityAnaStatementInstance)),
             local:make-triple(concat('swds:',$sanctityAnaStatementInstance),'sps:sanctity', local:make-uri($sanctityAna)),
             local:make-triple(concat('swds:',$sanctityAnaStatementInstance),'spr:reference-URL', local:make-uri($id)),
             local:make-dates-simple($sanctity, $id, $instanceID, 'sanctity')
            )),
    (: socecStatus :)
    for $socecStatus at $p in $factoid[@subtype='socecStatus']/descendant-or-self::tei:socecStatus
    let $instanceID := concat($idShort,'-',$p)
    return 
        (
        for $socecStatusAna at $n in tokenize($socecStatus/@ana, ' ')
        let $socecStatusAnaStatementInstance := concat($factoidRef,'Inst',replace(generate-id($socecStatus),'\.',''), $n)
        return 
            (local:make-triple(local:make-uri($persRef),'swdt:socec-status', local:make-uri($socecStatusAna)),
             local:make-triple(local:make-uri($persRef),'sp:socec-status', concat('swds:',$socecStatusAnaStatementInstance)),
             local:make-triple(concat('swds:',$socecStatusAnaStatementInstance),'sps:socec-status', local:make-uri($socecStatusAna)),
             local:make-triple(concat('swds:',$socecStatusAnaStatementInstance),'spr:reference-URL', local:make-uri($id)),
            local:make-dates-simple($socecStatus, $id, $instanceID, 'socec-status')
            )),
    (: Events :)
    for $event at $p in $factoid[@subtype='event']
    let $instanceID := concat($idShort,'-',$p)
    let $eventStatementInstance := concat($factoidRef,'Inst',replace(generate-id($event),'\.',''))
    return 
    (
    local:make-triple(concat('swd:event',$factoidRef),'rdfs:label', local:make-literal(concat('Event ', $factoidRef),'en',())),
    (:event description:)
       for $pers in $event/descendant::tei:persName/@ref
       let $eventPersRef := local:make-uri($pers)
       let $eventStatementInstance := concat($factoidRef,'Inst',replace(generate-id($pers),'\.',''))
       return 
       (
       local:make-triple(concat('swd:event',$factoidRef),'swdt:event-participant', $eventPersRef),
       local:make-triple(concat('swd:event',$factoidRef),'sp:event-participant', concat('swds:',$eventStatementInstance)),
       local:make-triple(concat('swds:',$eventStatementInstance),'sps:event-participant', $eventPersRef),
       local:make-triple(concat('swds:',$eventStatementInstance),'spr:reference-URL', local:make-uri($id))
       ),
       for $place in $event/descendant::tei:placeName/@ref
       let $eventPlaceRef := local:make-uri($place)
       let $eventStatementInstance := concat($factoidRef,'Inst',replace(generate-id($place),'\.',''))
       return 
       (
       local:make-triple(concat('swd:event',$factoidRef),'swdt:event-place', $eventPlaceRef),
       local:make-triple(concat('swd:event',$factoidRef),'sp:event-place', concat('swds:',$eventStatementInstance)),
       local:make-triple(concat('swds:',$eventStatementInstance),'sps:event-place', $eventPlaceRef),
       local:make-triple(concat('swds:',$eventStatementInstance),'spr:reference-URL', local:make-uri($id))
       ),
       for $keyword at $n in tokenize($event/descendant::tei:listEvent/tei:event/@ana,' ')
       let $eventKeywordRef := local:make-uri($keyword)
       let $eventStatementInstance := concat($factoidRef,'Inst',$n,replace(generate-id($event/descendant::tei:listEvent/tei:event),'\.',''), $n)
       return 
       (
       local:make-triple(concat('swd:event',$factoidRef),'swdt:event-keyword', $eventKeywordRef),
       local:make-triple(concat('swd:event',$factoidRef),'sp:event-keyword', concat('swds:',$eventStatementInstance)),
       local:make-triple(concat('swds:',$eventStatementInstance),'sps:event-keyword', $eventKeywordRef),
       local:make-triple(concat('swds:',$eventStatementInstance),'spr:reference-URL', local:make-uri($id))
       ),
       for $when at $p in $event/descendant::tei:listEvent/tei:event
       return local:make-dates-simple($when, $id, $instanceID, 'event'),
       for $eventRelations at $p in $event/descendant::tei:relation     
       let $instanceID := concat($idShort,'-',$p)
       return local:relationship-triples($eventRelations, $id, $instanceID)
    ),        
    for $relation at $p in $factoid/tei:listRelation/tei:relation[@type='person']
    let $instanceID := concat($idShort,'-',$p)
    return local:relationship-triples($relation, $id, $instanceID)             
)

(:

    
  :)

};

(: Prefixes :)
declare function local:prefix() as xs:string{
"@prefix swd: <http://syriaca.org/> .
@prefix swds: <http://syriaca-person/entity/statement/> .
@prefix swdt: <http://syriaca.org/prop/direct/> .
@prefix sp: <http://syriaca.org/prop/> .
@prefix sps: <http://syriaca.org/prop/statement/> .
@prefix spr: <http://syriaca.org/prop/reference/> .
@prefix spq: <http://syriaca.org/prop/qualifier/> .
@prefix swdref: <http://spear-prosop/reference/> .
@prefix schema: <http://schema.org/> .
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix prov: <http://www.w3.org/ns/prov#> .
@prefix cwrc: <http://sparql.cwrc.ca/ontologies/cwrc#>.
@prefix dcterms: <http://purl.org/dc/terms/> .
@prefix foaf:	<http://xmlns.com/foaf/0.1/> .
@prefix geo: <http://www.w3.org/2003/01/geo/wgs84_pos#> .
@prefix lawd:	<http://lawd.info/ontology/> .
@prefix owl:	<http://www.w3.org/2002/07/owl#> .
@prefix periodo:	<http://n2t.net/ark:/99152/p0v#> .
@prefix person:	<https://www.w3.org/ns/person> .
@prefix skos:	<http://www.w3.org/2004/02/skos/core#> .
@prefix syriaca:	<http://syriaca.org/schema#> .
@prefix snap:	<http://data.snapdrgn.net/ontology/snap#> . 
@prefix time:	<http://www.w3.org/2006/time#> .
@prefix wdata:	<https://www.wikidata.org/wiki/Special:EntityData/> .
@prefix xsd:	<http://www.w3.org/2001/XMLSchema#> .&#xa;"
};

if(//tei:publicationStmt/tei:idno[starts-with(.,'https://spear-prosop.org/')]) then
   (local:prefix(),local:make-SPEAR-triples(.))
else (local:prefix(),local:make-triple-set(.))