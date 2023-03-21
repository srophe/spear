xquery version "3.1";

import module namespace config="http://srophe.org/srophe/config" at "../config.xqm";
import module namespace data="http://srophe.org/srophe/data" at "../lib/data.xqm";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:method "text";

declare function local:create-date-triples($factoidRef as xs:string?, $InstanceRef as xs:string?, $dateElement as node()*){
    if($dateElement[@when or @notBefore or @notAfter or @from or @to]) then
        for $date in $dateElement/@when | $dateElement/@notBefore | $dateElement/@notAfter | $dateElement/@from | $dateElement/@to
        let $predicate := 
            if(local-name($dateElement) = 'birth') then 
               if(name($date) = 'when') then  'birth-when'
                else if(name($date) = 'notBefore') then 'birth-not-before' 
                else if(name($date) = 'notAfter') then 'birth-not-after'
                else if(name($date) = 'from') then 'birth-from'
                else if(name($date) = 'to') then 'birth-to'
                else ()
            else if(local-name($dateElement) = 'death') then 
               if(name($date) = 'when') then  'death-when'
                else if(name($date) = 'notBefore') then 'death-not-before' 
                else if(name($date) = 'notAfter') then 'death-not-after'
                else if(name($date) = 'from') then 'death-from'
                else if(name($date) = 'to') then 'death-to'
                else ()    
            else if(name($date) = 'when') then  'when'
            else if(name($date) = 'notBefore') then 'not-before' 
            else if(name($date) = 'notAfter') then 'not-after'
            else if(name($date) = 'from') then 'from'
            else if(name($date) = 'to') then 'to'
            else ()
        let $factoidRef := if(starts-with($factoidRef,'<http')) then
                                $factoidRef
                           else if(starts-with($factoidRef,'http')) then
                                local:make-uri($factoidRef)
                           else local:make-uri(concat('http://syriaca.org/',$factoidRef))
        let $factoidShortRef := replace(replace(local:createRDFID($factoidRef),'>',''),'<','')                         
        return 
           if($date != '' and $predicate != '') then
                if($InstanceRef != '') then 
                    if(local-name($dateElement) = 'birth' or local-name($dateElement) = 'death') then
                        (
                        local:make-triple($factoidRef, concat('swdt:',$predicate), local:dateLiteral($date)),
                        local:make-triple($factoidRef, concat('sp:',$predicate), concat('swds:',concat($InstanceRef,replace($predicate,'-','')))),
                        local:make-triple(concat('swds:',concat($InstanceRef,replace($predicate,'-',''))), concat('sps:',$predicate), local:dateLiteral($date)),
                        local:make-triple(concat('swds:',concat($InstanceRef,replace($predicate,'-',''))),'prov:wasDerivedFrom', local:make-uri(concat('https://spear-prosop.org/',substring-before($InstanceRef,'Inst'))))
                        )
                    else if(local-name($dateElement) = 'event') then 
                        (
                        local:make-triple(concat('swd:event',$factoidShortRef), concat('swdt:',$predicate), local:dateLiteral($date)),
                        local:make-triple(concat('swd:event',$factoidShortRef), concat('sp:',$predicate), concat('swds:',concat($InstanceRef,replace($predicate,'-','')))),
                        local:make-triple(concat('swds:',concat($InstanceRef,replace($predicate,'-',''))), concat('sps:',$predicate), local:dateLiteral($date)),
                        local:make-triple(concat('swds:',concat($InstanceRef,replace($predicate,'-',''))),'prov:wasDerivedFrom', local:make-uri(concat('https://spear-prosop.org/',$factoidShortRef)))
                        )
                    else local:make-triple(concat('swds:',$InstanceRef), concat('spq:',$predicate), local:dateLiteral($date))
                else if(local-name($dateElement) = 'birth' or local-name($dateElement) = 'death' or local-name($dateElement) = 'event') then 
                     local:make-triple(local:make-uri(concat('http://syriaca.org/',$factoidRef)), concat('swdt:',$predicate), local:dateLiteral($date))
                else local:make-triple(concat('swds:',$factoidShortRef), concat('spq:',$predicate), local:dateLiteral($date))
            else ()
    else if($dateElement/descendant-or-self::tei:date[@when or @notBefore or @notAfter or @from or @to]) then
        for $date in $dateElement/descendant-or-self::tei:date/@when | $dateElement/descendant-or-self::tei:date/@notBefore | 
        $dateElement/descendant-or-self::tei:date/@notAfter | $dateElement/descendant-or-self::tei:date/@from | $dateElement/descendant-or-self::tei:date/@to
        let $predicate := 
            if(name($date) = 'when') then  'when'
            else if(name($date) = 'notBefore') then 'not-before' 
            else if(name($date) = 'notAfter') then 'not-after'
            else if(name($date) = 'from') then 'from'
            else if(name($date) = 'to') then 'to'
            else ()
        let $factoidRef := if(starts-with($factoidRef,'<http')) then
                                $factoidRef
                           else if(starts-with($factoidRef,'http')) then
                                local:make-uri($factoidRef)
                           else local:make-uri(concat('http://syriaca.org/',$factoidRef))
        let $factoidShortRef := replace(replace(local:createRDFID($factoidRef),'>',''),'<','') 
        return 
            if($date != '' and $predicate != '') then
                if($InstanceRef != '') then 
                    if(local-name($dateElement) = 'birth' or local-name($dateElement) = 'death') then
                        (
                        local:make-triple($factoidRef, concat('swdt:',$predicate), local:dateLiteral($date)),
                        local:make-triple($factoidRef, concat('sp:',$predicate), concat('swds:',concat($InstanceRef,replace($predicate,'-','')))),
                        local:make-triple(concat('swds:',concat($InstanceRef,replace($predicate,'-',''))), concat('sps:',$predicate), local:dateLiteral($date)),
                        local:make-triple(concat('swds:',concat($InstanceRef,replace($predicate,'-',''))),'prov:wasDerivedFrom', local:make-uri(concat('https://spear-prosop.org/',substring-before($InstanceRef,'Inst'))))
                        )
                    else if(local-name($dateElement) = 'event') then 
                        (
                        local:make-triple(concat('swd:event',$factoidShortRef), concat('swdt:',$predicate), local:dateLiteral($date)),
                        local:make-triple(concat('swd:event',$factoidShortRef), concat('sp:',$predicate), concat('swds:',concat($InstanceRef,replace($predicate,'-','')))),
                        local:make-triple(concat('swds:',concat($InstanceRef,replace($predicate,'-',''))), concat('sps:',$predicate), local:dateLiteral($date)),
                        local:make-triple(concat('swds:',concat($InstanceRef,replace($predicate,'-',''))),'prov:wasDerivedFrom', local:make-uri(concat('https://spear-prosop.org/',$factoidShortRef)))
                        )
                    else local:make-triple(concat('swds:',$InstanceRef), concat('spq:',$predicate), local:dateLiteral($date))
                else if(local-name($dateElement) = 'birth' or local-name($dateElement) = 'death' or local-name($dateElement) = 'event') then 
                     local:make-triple(local:make-uri(concat('http://syriaca.org/',$factoidRef)), concat('swdt:',$predicate), local:dateLiteral($date))
                else local:make-triple(concat('swds:',$factoidShortRef), concat('spq:',$predicate), local:dateLiteral($date))
            else ()
    else ()      
};


declare function local:dateLiteral($date as xs:string?){
if($date != '') then 
    if($date castable as xs:date) then 
        local:make-literal(string($date), (),'xsd:date')
    else if($date castable as xs:dateTime) then 
        local:make-literal(string($date), (),'xsd:dateTime')                        
    else if($date castable as xs:gYear) then 
        local:make-literal(string($date), (),'xsd:gYear')
    else if($date castable as xs:gYearMonth) then
        local:make-literal(string($date), (),'xsd:gYearMonth')
    else local:make-literal(string($date), (),())
else ()    
};

declare function local:createRDFID($string){
    if(contains($string, 'syriaca.org/')) then 
        substring-after($string, "syriaca.org/")
    else if(contains($string, 'spear-prosop.org/')) then 
        substring-after($string, "spear-prosop.org/")
    else if(starts-with($string, 'http')) then
        tokenize($string, "/")[last()]
    else $string
};

declare function local:relationships($relationshipElement, $factoidRef){
    let $relation := $relationshipElement
    let $relationStatementInstance := concat($factoidRef,'Inst',replace(generate-id($relation),'\.',''))
    let $relationshipType := 
        if(contains($relation/@ref,'keyword/')) then substring-after($relation/@ref, "keyword/") 
        else if($relation/@ana) then $relation/@ana
        else()
    return
        (
        if($relation[@mutual]) then
            let $mutual := tokenize($relation/@mutual, ' ')
            for $m at $n in $mutual
            for $mr at $n2 in $mutual[. != $m]
            let $mutualStmtInstance := concat($relationStatementInstance,'r',$n,$n2)
            return 
                if(contains($relationshipType,'event')) then 
                   (local:create-date-triples($factoidRef, $mutualStmtInstance, $relation),
                    local:make-triple(local:make-uri($m),concat('swdt:',$relationshipType), local:make-uri($mr)),
                    local:make-triple(concat('swd:',concat('event',local:createRDFID($m))),concat('sp:',$relationshipType), concat('swds:',$mutualStmtInstance)),
                    local:make-triple(concat('swds:',$mutualStmtInstance),concat('sps:',$relationshipType), concat('swd:',concat('event',local:createRDFID($mr)))),
                    local:make-triple(concat('swds:',$mutualStmtInstance),'prov:wasDerivedFrom', local:make-uri(concat('https://spear-prosop.org/',$factoidRef))),
                    for $relationshipQualifier in tokenize($relation/@ana, ' ')
                    return
                            local:make-triple(concat('swds:',$mutualStmtInstance),'spq:relationshipQualifier', local:make-uri($relationshipQualifier))
                    )
                else 
                (   local:create-date-triples($factoidRef, $mutualStmtInstance, $relation),
                    local:make-triple(local:make-uri($m),concat('swdt:',$relationshipType), local:make-uri($mr)),
                    local:make-triple(local:make-uri($m),concat('sp:',$relationshipType), concat('swds:',$mutualStmtInstance)),
                    local:make-triple(concat('swds:',$mutualStmtInstance),concat('sps:',$relationshipType), local:make-uri($mr)),
                    local:make-triple(concat('swds:',$mutualStmtInstance),'prov:wasDerivedFrom', local:make-uri(concat('https://spear-prosop.org/',$factoidRef))),
                    for $relationshipQualifier in tokenize($relation/@ana, ' ')
                    return
                            local:make-triple(concat('swds:',$mutualStmtInstance),'spq:relationshipQualifier', local:make-uri($relationshipQualifier))
                )
        else if($relation[@passive or @active]) then
            let $active := tokenize($relation/@active, ' ')
            let $passive := tokenize($relation/@passive, ' ')
            for $a at $n in $active
            for $p at $n2 in $passive
            let $passiveStmtInstance := concat($relationStatementInstance,'rl',$n, $n2)
            return 
                ( local:create-date-triples($factoidRef, $passiveStmtInstance, $relation),
                  local:make-triple(local:make-uri($a),concat('swdt:',$relationshipType), local:make-uri($p)),
                  local:make-triple(local:make-uri($a),concat('sp:',$relationshipType), concat('swds:',$passiveStmtInstance)),
                  local:make-triple(concat('swds:',$passiveStmtInstance),concat('sps:',$relationshipType), local:make-uri($p)),
                  local:make-triple(concat('swds:',$passiveStmtInstance),'prov:wasDerivedFrom', local:make-uri(concat('https://spear-prosop.org/',$factoidRef))),
                  for $relationshipQualifier in tokenize($relation/@ana, ' ')
                  return
                        local:make-triple(concat('swds:',$passiveStmtInstance),'spq:relationshipQualifier', local:make-uri($relationshipQualifier))
                     
                )
        else ())
};

declare function local:prefix() as xs:string{
"@prefix swd: <http://syriaca.org/>.
@prefix swds: <http://spear-prosop/entity/statement/>.
@prefix swdt: <http://syriaca.org/prop/direct/>.
@prefix sp: <http://syriaca.org/prop/>.
@prefix sps: <http://syriaca.org/prop/statement/>.
@prefix spr: <http://syriaca.org/prop/reference/>.
@prefix spq: <http://syriaca.org/prop/qualifier/>.
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#/>.
@prefix schema: <http://schema.org/>.
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>.
@prefix prov: <http://www.w3.org/ns/prov#>.
@prefix xsd: <http://www.w3.org/2001/XMLSchema#>. &#xa;"
};

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
 
 ex: 
 local:make-literal(string($date/@when)
 local:make-literal($name/text(),$name/@xml:lang, ())
 :)
declare function local:make-literal($string as xs:string*, $lang as xs:string*, $datatype as xs:string?) as xs:string?{
    concat('"',replace(normalize-space(string-join($string,' ')),'"',''),'"',
        if($lang != '') then concat('@',$lang) 
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

declare function local:make-triple-set-spear($rec){
  for $factoid in $rec/descendant-or-self::tei:ab
  let $factoidURI := $factoid/tei:idno[@type="URI"]
  let $factoidRef := tokenize($factoid/tei:idno[@type="URI"], "/")[last()]
  let $spearRecordURI := concat('https://spear-prosop.org/',substring-before($factoidRef,'-'))
  let $persRef := 
                    if($factoid/descendant::tei:person/tei:persName) then
                       local:make-uri($factoid/descendant::tei:person/tei:persName/@ref)
                    else local:make-uri($factoid/descendant::tei:persName[1]/@ref)
            (:
                    if($factoid/descendant::tei:person/tei:persName) then
                        local:createRDFID($factoid/descendant::tei:person/tei:persName/@ref)
                    else local:createRDFID($factoid/descendant::tei:persName[1]/@ref)
                    :)
  let $recIdno := $factoid/tei:idno[@type='URI']
  let $labelNode := 
                 if($factoid/tei:listEvent/tei:event/descendant::tei:desc) then
                    $factoid/tei:listEvent/tei:event/descendant::tei:desc[1]
                 else if($factoid/descendant::tei:note) then
                    $factoid/descendant::tei:note[1]
                  else if($factoid/descendant::tei:desc) then
                    $factoid/descendant::tei:desc[1]
                  else if($factoid/descendant::tei:listPerson) then 
                    $factoid/descendant::tei:listPerson
                  else
                    string-join(($factoid/child::*[not(self::tei:idno) and not(self::tei:bibl)]),'')      
  let $labelLiteral := local:make-literal(string($labelNode), 'en',())
  let $descHTML := serialize(('"""',$labelNode,'"""'), 
                        <output:serialization-parameters>
                            <output:method>html</output:method>
                        </output:serialization-parameters>)
  return 
  string-join(
  (
    if($labelLiteral != '') then
            local:make-triple(local:make-uri($factoidURI),'schema:description', $labelLiteral)  
    else (),  
    if($descHTML != '') then
            local:make-triple(local:make-uri($factoidURI),'rdf:XMLLiteral ', $descHTML)   
    else (),
    (: idnos, creator :)
    for $series in $rec/descendant-or-self::tei:seriesStmt/tei:idno[@type='URI']
    return local:make-triple(local:make-uri($recIdno),'spr:part-of-series', local:make-uri($series)),
    for $publicationStmt in $rec/descendant-or-self::tei:publicationStmt/tei:idno[@type='URI']
    return local:make-triple(local:make-uri($recIdno),'spr:part-of-series', local:make-uri($spearRecordURI)),
    for $creator in tokenize($factoid/@resp,' ')
    let $nameURI := if(starts-with($creator,'http')) then $creator else concat('http://syriaca.org/documentation/editors.xml',$creator)              
    return local:make-triple(local:make-uri($recIdno),'spr:creator', local:make-uri($nameURI)),
    for $bibl in $factoid/tei:bibl
    let $biblref := $bibl/tei:ptr/@target
    return 
        if($bibl[@type='URN']) then 
          local:make-triple(local:make-uri($recIdno),'spr:reference-bibl', local:make-uri($biblref))  
        else local:make-triple(local:make-uri($recIdno),'spr:reference-bibl', local:make-uri($biblref)),
    for $certainty in $factoid/tei:note[@type='certainty']
    let $certaintyref := $certainty/@subtype
    return local:make-triple(local:make-uri($factoidURI),'spq:certainty', local:make-uri($certaintyref)),
    (: Birth Dates :)
    for $birth in $factoid[@subtype='birth'] 
    let $date := if($birth/descendant::tei:birth[@when or @notBefore or @notAfter or @from or @to]) then $birth/descendant::tei:birth else if($birth/descendant::tei:date[@when or @notBefore or @notAfter or @from or @to]) then $birth/descendant::tei:date else ()
    let $dateLiteral := local:dateLiteral($date)
    let $birthStatementInstance := concat($factoidRef,'Inst',replace(generate-id($date),'\.',''))
    return 
        (
        local:create-date-triples($persRef,$birthStatementInstance, $date),
        (: Birth Place :)
        if($birth/descendant::tei:person/tei:birth/tei:placeName) then 
            for $birthPlace in $birth/descendant::tei:person/tei:birth/tei:placeName
            let $bpStatementInstance := concat($factoidRef,'Inst',replace(generate-id($birthPlace),'\.',''))
            return 
            (local:make-triple($persRef,'swdt:birth-place', local:make-uri($birthPlace/@ref)),
             local:make-triple($persRef,'sp:birth-place', concat('swds:',$bpStatementInstance)), 
             local:make-triple(concat('swds:',$bpStatementInstance),'sps:birth-place', local:make-uri($birthPlace/@ref)),
             local:make-triple(concat('swds:',$bpStatementInstance),'prov:wasDerivedFrom', local:make-uri($factoidURI))
            )
        else()
        ),
    (: Death Dates :)
    for $death in $factoid[@subtype='death'] 
    let $date := if($death/descendant::tei:death[@when or @notBefore or @notAfter or @from or @to]) then $death/descendant::tei:death else if($death/descendant::tei:date[@when or @notBefore or @notAfter or @from or @to]) then $death/descendant::tei:date else ()
    let $dateLiteral := local:dateLiteral($date)
    let $deathStatementInstance := concat($factoidRef,'Inst',replace(generate-id($date),'\.',''))
    return 
        (
        local:create-date-triples($persRef,$deathStatementInstance, $date),
        (: Death Place :)
        if($death/descendant::tei:person/tei:death/tei:placeName) then
            for $deathPlace in $death/descendant::tei:person/tei:death/tei:placeName
            let $dpStatementInstance := concat($factoidRef,'Inst',replace(generate-id($deathPlace),'\.',''))
            return
            (local:make-triple($persRef,'swdt:death-place', local:make-uri($deathPlace/@ref)),
             local:make-triple($persRef,'sp:death-place', concat('swds:',$dpStatementInstance)), 
             local:make-triple(concat('swds:',$dpStatementInstance),'sps:death-place', local:make-uri($deathPlace/@ref)),
             local:make-triple(concat('swds:',$dpStatementInstance),'prov:wasDerivedFrom', local:make-uri($factoidURI))
            )
        else()
        ),        
    (: citizenship :)
    for $citizenship in $factoid[@subtype='citizenship']
    let $placeRef := local:make-uri($citizenship/descendant::tei:person/tei:nationality/tei:placeName/@ref)
    let $citizenStatementInstance := concat($factoidRef,'Inst',replace(generate-id($citizenship),'\.',''))
    return 
        (
        local:make-triple($persRef,'swdt:citizenship', $placeRef),
        local:make-triple($persRef,'sp:citizenship', concat('swds:',$citizenStatementInstance)),
        local:make-triple(concat('swds:',$citizenStatementInstance),'sps:citizenship', $placeRef),
        local:make-triple(concat('swds:',$citizenStatementInstance),'prov:wasDerivedFrom', local:make-uri($factoidURI)),
        if($citizenship/descendant::tei:nationality[@when or @notBefore or @notAfter or @from or @to]) then 
            local:create-date-triples($citizenStatementInstance,(), $citizenship/descendant::tei:nationality)   
        else ()
        ),
    (:Education:)
    for $education in $factoid[@subtype='education']/descendant-or-self::tei:education
    return 
        (
            for $eduAna at $n in tokenize($education/@ana, ' ')
            let $eduAnaRef := local:make-uri($eduAna)
            let $eduAnaStatementInstance := concat($factoidRef,'Inst',replace(generate-id($education),'\.',''),$n)
            return 
                (local:make-triple($persRef,'swdt:education', $eduAnaRef),
                local:make-triple($persRef,'sp:education', concat('swds:',$eduAnaStatementInstance)),
                local:make-triple(concat('swds:',$eduAnaStatementInstance),'sps:education', $eduAnaRef),
                local:make-triple(concat('swds:',$eduAnaStatementInstance),'prov:wasDerivedFrom', local:make-uri($factoidURI)),
                if($education[@when or @notBefore or @notAfter or @from or @to]) then 
                    local:create-date-triples($eduAnaStatementInstance,(), $education)   
                else ()
        )),
    (: ethnicLabel :)
    for $ethnicLabel in $factoid[@subtype='ethnicLabel']/descendant-or-self::tei:trait
    return 
        (
            for $ethnicLabelAna at $n in tokenize($ethnicLabel/@ana, ' ')
            let $ethnicLabelRef := local:make-uri($ethnicLabelAna)
            let $ethnicAnaStatementInstance := concat($factoidRef,'Inst',replace(generate-id($ethnicLabel),'\.',''), $n)
            return 
                (local:make-triple($persRef,'swdt:ethnic-label', $ethnicLabelRef),
                local:make-triple($persRef,'sp:ethnic-label', concat('swds:',$ethnicAnaStatementInstance)),
                local:make-triple(concat('swds:',$ethnicAnaStatementInstance),'sps:ethnic-label', $ethnicLabelRef),
                local:make-triple(concat('swds:',$ethnicAnaStatementInstance),'prov:wasDerivedFrom', local:make-uri($factoidURI)),
                if($ethnicLabel[@when or @notBefore or @notAfter or @from or @to]) then 
                    local:create-date-triples($ethnicAnaStatementInstance,(), $ethnicLabel)   
                else ()
        )),
    (:Gender:)
    for $gender in $factoid[@subtype='gender']/descendant-or-self::tei:trait
    return 
            (
            for $genderAna at $n in tokenize($gender/@ana, ' ')
            let $genderRef := local:make-uri($genderAna)
            let $genderAnaStatementInstance := concat($factoidRef,'Inst',replace(generate-id($gender),'\.',''), $n)
            return 
                (
                local:make-triple($persRef,'swdt:gender', $genderRef),
                local:make-triple($persRef,'sp:gender', concat('swds:',$genderAnaStatementInstance)),
                local:make-triple(concat('swds:',$genderAnaStatementInstance),'sps:gender', $genderRef),
                local:make-triple(concat('swds:',$genderAnaStatementInstance),'prov:wasDerivedFrom', local:make-uri($factoidURI)),
                if($gender[@when or @notBefore or @notAfter or @from or @to]) then 
                    local:create-date-triples($genderAnaStatementInstance,(), $gender)   
                else ()
            )),
    (: Language :)
    for $lang in $factoid[@subtype='langKnown']/descendant-or-self::tei:langKnowledge
    return 
            (
            for $langAna at $n in tokenize($lang/tei:langKnown/@ana, ' ')
            let $langRef := local:make-uri($langAna)
            let $langAnaStatementInstance := concat($factoidRef,'Inst',replace(generate-id($lang),'\.',''), $n)
            return 
                (local:make-triple($persRef,'swdt:language-known', $langRef),
                local:make-triple($persRef,'sp:language-known', concat('swds:',$langAnaStatementInstance)),
                local:make-triple(concat('swds:',$langAnaStatementInstance),'sps:language-known', $langRef),
                local:make-triple(concat('swds:',$langAnaStatementInstance),'prov:wasDerivedFrom', local:make-uri($factoidURI)),                            
                if($lang/tei:langKnown[@when or @notBefore or @notAfter or @from or @to]) then 
                    local:create-date-triples($langAnaStatementInstance, (), $lang/tei:langKnown)   
                else ()
            )),
    (: Mental State:)            
    for $mentalState in $factoid[@subtype='mentalState']/descendant-or-self::tei:state
    return 
            (
            for $mentalStateAna at $n in tokenize($mentalState/@ana, ' ')
            let $mentalStateRef := local:make-uri($mentalStateAna)
            let $mentalAnaStatementInstance := concat($factoidRef,'Inst',concat(replace(generate-id($mentalState),'\.',''),$n))
            return 
                (local:make-triple($persRef,'swdt:mental-state', $mentalStateRef),
                local:make-triple($persRef,'sp:mental-state', concat('swds:',$mentalAnaStatementInstance)),
                local:make-triple(concat('swds:',$mentalAnaStatementInstance),'sps:mental-state', $mentalStateRef),
                local:make-triple(concat('swds:',$mentalAnaStatementInstance),'prov:wasDerivedFrom', local:make-uri($factoidURI)),                  
                if($mentalState[@when or @notBefore or @notAfter or @from or @to]) then 
                    local:create-date-triples($mentalAnaStatementInstance, (), $mentalState)   
                else ()
            )),
    (: Name :)
    for $nameVariant in $factoid[@subtype='nameVariant']/descendant-or-self::tei:listPerson/child::tei:persName
    let $nameVariantStatementInstance := concat($factoidRef,'Inst',replace(generate-id($nameVariant),'\.',''))
    return 
        (local:make-triple(concat('swds:',$factoidRef),'sps:name-variant', local:make-literal(string($nameVariant), 'en',())),
        local:make-triple($persRef,'swdt:name-variant', local:make-literal(string($nameVariant), 'en',())),
        local:make-triple($persRef,'sp:name-variant', concat('swds:',$factoidRef)),
        local:make-triple(concat('swds:',$factoidRef),'prov:wasDerivedFrom', local:make-uri($factoidURI)),
        if($nameVariant[@when or @notBefore or @notAfter or @from or @to]) then 
                    local:create-date-triples($factoidRef,(), $nameVariant)   
        else ()
        ),
    (: occupation :)
    for $occupation in $factoid[@subtype='occupation']/descendant-or-self::tei:occupation
    return 
        (
        for $occupationAna at $n in tokenize($occupation/@ana, ' ')
        let $occupationRef := local:make-uri($occupationAna)
        let $occupationAnaStatementInstance := concat($factoidRef,'Inst',replace(generate-id($occupation),'\.',''), $n)
        return 
            (local:make-triple($persRef,'swdt:occupation', $occupationRef),
             local:make-triple($persRef,'sp:occupation', concat('swds:',$occupationAnaStatementInstance)),
             local:make-triple(concat('swds:',$occupationAnaStatementInstance),'sps:occupation', $occupationRef),
             local:make-triple(concat('swds:',$occupationAnaStatementInstance),'prov:wasDerivedFrom', local:make-uri($factoidURI)),
             if($occupation[@when or @notBefore or @notAfter or @from or @to]) then 
                local:create-date-triples($occupationAnaStatementInstance,(), $occupation)   
             else ()
            )),
    (: physicalTrait :)
    for $physicalTrait in $factoid[@subtype='physicalTrait']/descendant-or-self::tei:trait
    return 
        (
        for $physicalTraitAna at $n in tokenize($physicalTrait/@ana, ' ')
        let $physicalTraitRef := local:make-uri($physicalTraitAna)
        let $physicalTraitAnaStatementInstance := concat($factoidRef,'Inst',replace(generate-id($physicalTrait),'\.',''), $n)
        return 
            (local:make-triple($persRef,'swdt:physical-trait', $physicalTraitRef),
             local:make-triple($persRef,'sp:physical-trait', concat('swds:',$physicalTraitAnaStatementInstance)),
             local:make-triple(concat('swds:',$physicalTraitAnaStatementInstance),'sps:physical-trait', $physicalTraitRef),
             local:make-triple(concat('swds:',$physicalTraitAnaStatementInstance),'prov:wasDerivedFrom', local:make-uri($factoidURI)),
            if($physicalTrait[@when or @notBefore or @notAfter or @from or @to]) then 
                local:create-date-triples($physicalTraitAnaStatementInstance,(), $physicalTrait)   
            else ()
            )),
    (: residence :)
    for $residence in $factoid[@subtype='residence']/descendant-or-self::tei:residence
    let $residenceStatementInstance := concat($factoidRef,'Inst',replace(generate-id($residence),'\.',''))
    return 
        (local:make-triple($persRef,'swdt:residence', local:make-uri($residence/tei:placeName/@ref)),
        local:make-triple($persRef,'sp:residence', concat('swds:',$residenceStatementInstance)),
        local:make-triple(concat('swds:',$residenceStatementInstance),'sps:residence', local:make-uri($residence/tei:placeName/@ref)),
        local:make-triple(concat('swds:',$residenceStatementInstance),'prov:wasDerivedFrom', local:make-uri($factoidURI)),
        if($residence[@when or @notBefore or @notAfter or @from or @to]) then 
                local:create-date-triples($residenceStatementInstance,(), $residence)   
            else ()
            ),
    (: sanctity :)
    for $sanctity in $factoid[@subtype='sanctity']/descendant-or-self::tei:state
    return 
        (
        for $sanctityAna at $n in tokenize($sanctity/@ana, ' ')
        let $sanctityAnaStatementInstance := concat($factoidRef,'Inst',replace(generate-id($sanctity),'\.',''), $n)
        return 
            (local:make-triple($persRef,'swdt:sanctity', local:make-uri($sanctityAna)),
             local:make-triple($persRef,'sp:sanctity', concat('swds:',$sanctityAnaStatementInstance)),
             local:make-triple(concat('swds:',$sanctityAnaStatementInstance),'sps:sanctity', local:make-uri($sanctityAna)),
             local:make-triple(concat('swds:',$sanctityAnaStatementInstance),'prov:wasDerivedFrom', local:make-uri($factoidURI)),            
            if($sanctity[@when or @notBefore or @notAfter or @from or @to]) then 
                local:create-date-triples($sanctityAnaStatementInstance,(), $sanctity)   
            else ())),
    (: socecStatus :)
    for $socecStatus in $factoid[@subtype='socecStatus']/descendant-or-self::tei:socecStatus
    return 
        (
        for $socecStatusAna at $n in tokenize($socecStatus/@ana, ' ')
        let $socecStatusAnaStatementInstance := concat($factoidRef,'Inst',replace(generate-id($socecStatus),'\.',''), $n)
        return 
            (local:make-triple($persRef,'swdt:socec-status', local:make-uri($socecStatusAna)),
             local:make-triple($persRef,'sp:socec-status', concat('swds:',$socecStatusAnaStatementInstance)),
             local:make-triple(concat('swds:',$socecStatusAnaStatementInstance),'sps:socec-status', local:make-uri($socecStatusAna)),
             local:make-triple(concat('swds:',$socecStatusAnaStatementInstance),'prov:wasDerivedFrom', local:make-uri($factoidURI)),
            if($socecStatus[@when or @notBefore or @notAfter or @from or @to]) then 
                local:create-date-triples($socecStatusAnaStatementInstance,(), $socecStatus)   
            else ())),
    (: Relationships :)
    for $relation in $factoid/tei:listRelation/tei:relation[@type='person']
    return (local:create-date-triples($factoidRef,(), $relation), local:relationships($relation, $factoidRef)),
    (: Events :)
    for $event in $factoid[@subtype='event']   
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
       local:make-triple(concat('swds:',$eventStatementInstance),'prov:wasDerivedFrom', local:make-uri($factoidURI))
       ),
       for $place in $event/descendant::tei:placeName/@ref
       let $eventPlaceRef := local:make-uri($place)
       let $eventStatementInstance := concat($factoidRef,'Inst',replace(generate-id($place),'\.',''))
       return 
       (
       local:make-triple(concat('swd:event',$factoidRef),'swdt:event-place', $eventPlaceRef),
       local:make-triple(concat('swd:event',$factoidRef),'sp:event-place', concat('swds:',$eventStatementInstance)),
       local:make-triple(concat('swds:',$eventStatementInstance),'sps:event-place', $eventPlaceRef),
       local:make-triple(concat('swds:',$eventStatementInstance),'prov:wasDerivedFrom', local:make-uri($factoidURI))
       ),
       for $keyword at $n in tokenize($event/descendant::tei:listEvent/tei:event/@ana,' ')
       let $eventKeywordRef := local:make-uri($keyword)
       let $eventStatementInstance := concat($factoidRef,'Inst',$n,replace(generate-id($event/descendant::tei:listEvent/tei:event),'\.',''), $n)
       return 
       (
       local:make-triple(concat('swd:event',$factoidRef),'swdt:event-keyword', $eventKeywordRef),
       local:make-triple(concat('swd:event',$factoidRef),'sp:event-keyword', concat('swds:',$eventStatementInstance)),
       local:make-triple(concat('swds:',$eventStatementInstance),'sps:event-keyword', $eventKeywordRef),
       local:make-triple(concat('swds:',$eventStatementInstance),'prov:wasDerivedFrom', local:make-uri($factoidURI))
       ),
       for $when in $event/descendant::tei:listEvent/tei:event
       return 
            local:create-date-triples($factoidRef, $eventStatementInstance, $when),
       for $eventRelations in $event/descendant::tei:relation       
       return 
            (local:relationships($eventRelations, $factoidRef))
    ),
    ''
  ),'')
};


(: Make sure record ends with a '.' :)
declare function local:record($triple as xs:string*) as xs:string*{
    replace($triple,';$','.&#xa;')
};

declare function local:ttl-output($recs) {
    (local:prefix(), local:make-triple-set-spear($recs))
};
(:for $hit at $p in subsequence($hits, $search:start, $search:perpage):)
(: example: http://localhost:8080/exist/apps/spear/modules/content-negotiation/tei2ttl.xql?download=true :)
(:let $dataDump := subsequence(collection($config:data-root),1,5):)
let $data := data:get-document()    
return  
    if(request:get-parameter('download', '') = 'true') then
        let $records := collection($config:data-root)
        let $collectionRDF := string-join((local:prefix(),string-join((for $r in $records return local:make-triple-set-spear($r)),'')),'')
        return 
        (response:set-header("Content-Type", "text/turtle; charset=utf-8"),
         response:set-header("media-type", "text/plain"),
         response:set-header("Content-Disposition", fn:concat("attachment; filename=", concat('allSPEAR','.ttl'))),$collectionRDF)
    else 
        (response:set-header("Content-Type", "text/turtle; charset=utf-8"),
         response:set-header("media-type", "text/plain"),
         concat(local:prefix(), local:make-triple-set-spear($data)))