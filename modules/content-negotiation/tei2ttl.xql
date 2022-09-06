xquery version "3.1";

import module namespace config="http://srophe.org/srophe/config" at "../config.xqm";
import module namespace data="http://srophe.org/srophe/data" at "../lib/data.xqm";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:method "text";

declare function local:create-date-triples($factoidRef as xs:string?, $dateElement as node()*){
    let $date := if($dateElement/@when) then $dateElement/@when 
                             else if($dateElement/@notBefore) then $dateElement/@notBefore 
                             else if($dateElement/@notAfter) then $dateElement/@notAfter
                             else if($dateElement/@from) then $dateElement/@from
                             else if($dateElement/@to) then $dateElement/@to
                             else()
    let $dateLiteral := local:dateLiteral($date)
        (:
                            if($date castable as xs:date) then 
                                local:make-literal(string($date), (),'xsd:date')
                            else if($date castable as xs:dateTime) then 
                                local:make-literal(string($date), (),'xsd:dateTime')                        
                            else if($date castable as xs:gYear) then 
                                local:make-literal(string($date), (),'xsd:gYear')
                            else if($date castable as xs:gYearMonth) then
                                local:make-literal(string($date), (),'xsd:gYearMonth')
                            else local:make-literal(string($date), (),())
                            :)
    let $predicate :=  
                             if($dateElement/@when) then  'spq:when'
                             else if($dateElement/@notBefore) then 'spq:not-before' 
                             else if($dateElement/@notAfter) then 'spq:not-after'
                             else if($dateElement/@from) then 'spq:from'
                             else if($dateElement/@to) then 'spq:to'
                             else()                       
    return 
        if($date != '') then 
            local:make-triple(concat('swds:',$factoidRef),$predicate, $dateLiteral) 
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

declare function local:prefix() as xs:string{
"@prefix swd: <http://syriaca.org/>.
@prefix swds: <http://spear-prosop/entity/statement/>.
@prefix swdt: <http://syriaca.org/prop/direct/>.
@prefix sp: <http://syriaca.org/prop/>.
@prefix sps: <http://syriaca.org/prop/statement/>.
@prefix spr: <http://syriaca.org/prop/reference/>.
@prefix spq: <http://syriaca.org/prop/qualifier/>.
@prefix swdref: <http://spear-prosop/reference/>.
@prefix schema: <http://schema.org/>.
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>.
@prefix prov: <http://www.w3.org/ns/prov#>. &#xa;"
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
    concat('&#xa;', $s,' ', $o,' ', $p, ' ;')
};

declare function local:make-triple-set-spear($rec){
  for $factoid in $rec/descendant-or-self::tei:ab
  let $factoidRef := tokenize($factoid/tei:idno[@type="URI"], "/")[last()]
  let $persRef := 
                    if($factoid/descendant::tei:person/tei:persName) then
                        substring-after($factoid/descendant::tei:person/tei:persName/@ref, "syriaca.org/")
                    else substring-after($factoid/descendant::tei:persName[1]/@ref, "syriaca.org/") 
  let $recIdno := $factoid/tei:idno[@type='URI']
  return 
  string-join(
  (
    (: idnos, creator :)
    for $series in $rec/descendant-or-self::tei:seriesStmt/tei:idno[@type='URI']
    return local:make-triple(concat('swdref:',$factoidRef),'spr:part-of-series', local:make-uri($series)),
    for $publicationStmt in $rec/descendant-or-self::tei:publicationStmt/tei:idno[@type='URI']
    return local:make-triple(concat('swdref:',$factoidRef),'spr:part-of-series', local:make-uri($publicationStmt)),
    local:make-triple(concat('swds:',$factoidRef),'spr:wasDerivedFrom', local:make-uri($recIdno)),
    for $creator in tokenize($factoid/@resp,' ')
    let $nameRef := replace($creator, '#','')
    let $name := if($rec/descendant-or-self::tei:editor[@role='creator'][ends-with(@ref,$nameRef)]) then 
                    string-join($rec/descendant-or-self::tei:editor[@role='creator'][ends-with(@ref,$nameRef)]//text(),'')
                 else if(doc-available('https://raw.githubusercontent.com/srophe/srophe-eXist-app/master/documentation/editors.xml')) then
                    if(doc('https://raw.githubusercontent.com/srophe/srophe-eXist-app/master/documentation/editors.xml')//tei:person[@xml:id = $nameRef]) then 
                        doc('https://raw.githubusercontent.com/srophe/srophe-eXist-app/master/documentation/editors.xml')//tei:person[@xml:id = $nameRef]
                    else $nameRef
                 else $nameRef
    return local:make-triple(concat('swdref:',$factoidRef),'spr:creator', local:make-literal($name, (), ())),
    for $bibl in $factoid/tei:bibl
    let $biblref := $bibl/tei:ptr/@target
    return 
        if($bibl[@type='URN']) then 
          local:make-triple(concat('swdref:',$factoidRef),'spr:reference-bibl', local:make-uri($biblref))  
        else local:make-triple(concat('swdref:',$factoidRef),'spr:reference-bibl', local:make-uri($biblref)),
    for $certainty in $factoid/tei:note[@type='certainty']
    let $certaintyref := $certainty/@subtype
    return local:make-triple(concat('swds:',$factoidRef),'spq:certainty', local:make-uri($certaintyref)),
    (: Birth Dates :)
    for $birth in $factoid[@subtype='birth'] 
    let $date := if($birth/descendant::tei:birth/@when) then $birth/descendant::tei:birth/@when else if($birth/descendant::tei:birth/@notBefore) then $birth/descendant::tei:birth/@notBefore else if($birth/descendant::tei:birth/@notAfter) then $birth/descendant::tei:birth/@notAfter else()
    let $dateLiteral := local:dateLiteral($date)
    return 
        (if(string($date) != '') then local:make-triple(concat('swd:',$persRef),'swdt:birth-date', $dateLiteral) else (),
        local:make-triple(concat('swd:',$persRef),'sp:birth-date', concat('swds:',$factoidRef)),
        local:create-date-triples($factoidRef, $date),
        for $birthNote in $birth/descendant::tei:birth/tei:note
        return local:make-triple(concat('swd:',$factoidRef),'rdfs:label', local:make-literal(string-join(($birthNote//text()),' '), (),())),
        (: Birth Place :)
        if($birth/descendant::tei:person/tei:birth/tei:placeName) then 
            (local:make-triple(concat('swd:',$persRef),'swdt:birth-place', concat('swds:',substring-after($birth/descendant::tei:person/tei:birth/tei:placeName/@ref, "syriaca.org/"))),
             local:make-triple(concat('swd:',$persRef),'sp:birth-place', concat('swds:',$factoidRef)), 
             local:make-triple(concat('swds:',$factoidRef),'sps:birth-place', concat('swds:',substring-after($birth/descendant::tei:person/tei:birth/tei:placeName/@ref, "syriaca.org/")))
            )
        else()
        ),
    (: citizenship :)
    for $citizenship in $factoid[@subtype='citizenship']
    let $placeRef := substring-after($citizenship/descendant::tei:person/tei:nationality/tei:placeName/@ref, "syriaca.org/")
    return 
        (
        local:make-triple(concat('swd:',$persRef),'swdt:citizenship', concat('swd:',$placeRef)),
        local:make-triple(concat('swd:',$persRef),'sp:citizenship', concat('swds:',$factoidRef)),
        local:make-triple(concat('swds:',$factoidRef),'sps:citizenship', concat('swd:',$placeRef)),
        if($citizenship/descendant::tei:nationality[@when or @notBefore or @notAfter or @from or @to]) then 
            local:create-date-triples($factoidRef, $citizenship/descendant::tei:nationality)   
        else (),
        for $citizenshipNote in $citizenship/descendant::tei:person/tei:nationality/tei:note
        return local:make-triple(concat('swd:',$factoidRef),'rdfs:label', local:make-literal(string-join(($citizenshipNote//text()),' '), (),()))
        ),
    (: Death Dates :)
    for $death in $factoid[@subtype='death'] 
    let $date := if($death/descendant::tei:death/@when) then $death/descendant::tei:death/@when else if($death/descendant::tei:death/@notBefore) then $death/descendant::tei:death/@notBefore else if($death/descendant::tei:death/@notAfter) then $death/descendant::tei:death/@notAfter else()
    let $dateLiteral := local:dateLiteral($date)
    return 
        (if(string($date) != '') then local:make-triple(concat('swd:',$persRef),'swdt:death-date', $dateLiteral) else (),
        local:make-triple(concat('swd:',$persRef),'sp:death-date', concat('swds:',$factoidRef)),
        local:create-date-triples($factoidRef, $date),
        for $deathNote in $death/descendant::tei:death/tei:note
        return local:make-triple(concat('swd:',$factoidRef),'rdfs:label', local:make-literal(string-join(($deathNote//text()),' '), (),())),
        (: Death Place :)
        if($death/descendant::tei:person/tei:death/tei:placeName) then 
            (local:make-triple(concat('swd:',$persRef),'swdt:death-place', concat('swds:',substring-after($death/descendant::tei:person/tei:death/tei:placeName/@ref, "syriaca.org/"))),
             local:make-triple(concat('swd:',$persRef),'sp:death-place', concat('swds:',$factoidRef)), 
             local:make-triple(concat('swds:',$factoidRef),'sps:death-place', concat('swds:',substring-after($death/descendant::tei:person/tei:death/tei:placeName/@ref, "syriaca.org/")))
            )
        else()
        ),
    (:Education:)
    for $education in $factoid[@subtype='education']/descendant-or-self::tei:education
    return 
        (
            for $eduAna in tokenize($education/@ana, ' ')
            return 
                (local:make-triple(concat('swd:',$persRef),'swdt:education', concat('swd:',substring-after($eduAna, "syriaca.org/"))),
                local:make-triple(concat('swds:',$factoidRef),'sps:education', concat('swd:',substring-after($eduAna, "syriaca.org/")))
                ),
            local:make-triple(concat('swd:',$persRef),'sp:education', concat('swds:',$factoidRef)),
            if($education[@when or @notBefore or @notAfter or @from or @to]) then 
                local:create-date-triples($factoidRef, $education)   
            else (),
            for $educationNote in $education/descendant-or-self::tei:education/tei:note
            return local:make-triple(concat('swd:',$factoidRef),'rdfs:label', local:make-literal(string-join($educationNote//text(),' '), (),()))
        ),
    (: ethnicLabel :)
    for $ethnicLabel in $factoid[@subtype='ethnicLabel']/descendant-or-self::tei:trait
    return 
        (local:make-triple(concat('swds:',$persRef),'sp:ethnic-label', concat('swds:',$factoidRef)),
            for $ethnicLabelAna in tokenize($ethnicLabel/@ana, ' ')
            return 
                (local:make-triple(concat('swd:',$persRef),'swdt:ethnic-label', concat('swd:',substring-after($ethnicLabelAna, "syriaca.org/"))),
                local:make-triple(concat('swds:',$factoidRef),'sps:ethnic-label', concat('swd:',substring-after($ethnicLabelAna, "syriaca.org/")))
                ),
            if($ethnicLabel[@when or @notBefore or @notAfter or @from or @to]) then 
                local:create-date-triples($factoidRef, $ethnicLabel)   
            else (),
            for $ethnicLabelNote in $ethnicLabel/tei:note
            return local:make-triple(concat('swd:',$factoidRef),'rdfs:label', local:make-literal(string-join($ethnicLabelNote//text(),' '), (),()))
        ),
    (:Gender:)
    for $gender in $factoid[@subtype='gender']/descendant-or-self::tei:trait
    return 
            (local:make-triple(concat('swds:',$persRef),'sp:gender', concat('swds:',$factoidRef)),
            for $genderAna in tokenize($gender/@ana, ' ')
            return 
                (local:make-triple(concat('swd:',$persRef),'swdt:gender', concat('swd:',substring-after($genderAna, "syriaca.org/"))),       
                local:make-triple(concat('swds:',$factoidRef),'sps:gender', concat('swd:',substring-after($genderAna, "syriaca.org/")))
                ),
            if($gender[@when or @notBefore or @notAfter or @from or @to]) then 
                local:create-date-triples($factoidRef, $gender)   
            else (),
            for $genderNote in $gender/tei:note
            return local:make-triple(concat('swd:',$factoidRef),'rdfs:label', local:make-literal(string-join($genderNote//text(),' '), 'en',()))
            ),
    (: Language :)
    for $lang in $factoid[@subtype='langKnown']/descendant-or-self::tei:langKnowledge
    return 
            (local:make-triple(concat('swds:',$persRef),'spa:language-known', concat('swds:',$factoidRef)),
            for $langAna in tokenize($lang/tei:langKnown/@ana, ' ')
            return 
                (local:make-triple(concat('swd:',$persRef),'swdt:language-known', concat('swd:',substring-after($langAna, "syriaca.org/"))),       
                local:make-triple(concat('swds:',$factoidRef),'sps:language-known', concat('swd:',substring-after($langAna, "syriaca.org/")))
                ),
            if($lang/tei:langKnown[@when or @notBefore or @notAfter or @from or @to]) then 
                local:create-date-triples($factoidRef, $lang/tei:langKnown)   
            else (),
            for $langNote in $lang/tei:note
            return local:make-triple(concat('swd:',$factoidRef),'rdfs:label', local:make-literal(string-join($langNote//text(),' '), 'en',()))
            ),
    (: Mental State:)            
    for $mentalState in $factoid[@subtype='mentalState']/descendant-or-self::tei:state
    return 
            (local:make-triple(concat('swds:',$persRef),'sp:mental-state', concat('swds:',$factoidRef)),
            for $mentalStateAna in tokenize($mentalState/@ana, ' ')
            return 
                (local:make-triple(concat('swd:',$persRef),'swdt:mental-state', concat('swd:',substring-after($mentalStateAna, "syriaca.org/"))),       
                local:make-triple(concat('swds:',$factoidRef),'sps:mental-state', concat('swd:',substring-after($mentalStateAna, "syriaca.org/")))
                ),
            if($mentalState[@when or @notBefore or @notAfter or @from or @to]) then 
                local:create-date-triples($factoidRef, $mentalState)   
            else (),
            for $mentalStateNote in $mentalState/tei:note
            return local:make-triple(concat('swd:',$factoidRef),'rdfs:label', local:make-literal(string-join($mentalStateNote//text(),' '), 'en',()))
            ),
    (: Name :)
    for $nameVariant in $factoid[@subtype='nameVariant']/descendant-or-self::tei:person/tei:persName
    return 
        (local:make-triple(concat('swds:',$factoidRef),'sps:name-variant', concat('swd:',$persRef)),
        local:make-triple(concat('swd:',$persRef),'swdt:name-variant', local:make-literal(string($nameVariant), 'en',())),
        local:make-triple(concat('swd:',$persRef),'sp:name-variant', concat('swds:',$factoidRef)),
        if($nameVariant[@when or @notBefore or @notAfter or @from or @to]) then 
                    local:create-date-triples($factoidRef, $nameVariant)   
        else ()
        ),
    (: occupation :)
    for $occupation in $factoid[@subtype='occupation']/descendant-or-self::tei:occupation
    return 
        (local:make-triple(concat('swd:',$persRef),'sp:occupation', concat('swds:',$factoidRef)),
        for $occupationAna in tokenize($occupation/@ana, ' ')
            return 
                (local:make-triple(concat('swd:',$persRef),'swdt:occupation', concat('swd:',substring-after($occupationAna, "syriaca.org/"))),       
                local:make-triple(concat('swds:',$factoidRef),'sps:occupation', concat('swd:',substring-after($occupationAna, "syriaca.org/")))
                ),
        if($occupation[@when or @notBefore or @notAfter or @from or @to]) then 
                local:create-date-triples($factoidRef, $occupation)   
            else (),
        for $occupationNote in $occupation/tei:note
        return local:make-triple(concat('swd:',$factoidRef),'rdfs:label', local:make-literal(string-join($occupationNote//text(),' '), 'en',()))  
        ),
    (: physicalTrait :)
    for $physicalTrait in $factoid[@subtype='physicalTrait']/descendant-or-self::tei:trait
    return 
        (local:make-triple(concat('swd:',$persRef),'sp:physical-trait', concat('swds:',$factoidRef)),
        for $physicalTraitAna in tokenize($physicalTrait/@ana, ' ')
        return 
                (local:make-triple(concat('swd:',$persRef),'swdt:physical-trait', concat('swd:',substring-after($physicalTraitAna, "syriaca.org/"))),       
                local:make-triple(concat('swds:',$factoidRef),'sps:physical-trait', concat('swd:',substring-after($physicalTraitAna, "syriaca.org/")))
                ),
        if($physicalTrait[@when or @notBefore or @notAfter or @from or @to]) then 
                local:create-date-triples($factoidRef, $physicalTrait)   
            else (),
        for $physicalTraitNote in $physicalTrait/tei:note
        return local:make-triple(concat('swd:',$factoidRef),'rdfs:label', local:make-literal(string-join($physicalTraitNote//text(),' '), 'en',()))  
        ),
    (: residence :)
    for $residence in $factoid[@subtype='residence']/descendant-or-self::tei:residence
    return 
        (local:make-triple(concat('swd:',$persRef),'swdt:residence', concat('swd:',substring-after($residence/tei:placeName/@ref, "syriaca.org/"))),
        local:make-triple(concat('swd:',$persRef),'sp:residence', concat('swds:',$factoidRef)),
        local:make-triple(concat('swds:',$factoidRef),'sps:residence', concat('swd:',substring-after($residence/tei:placeName/@ref, "syriaca.org/"))),
        
        if($residence[@when or @notBefore or @notAfter or @from or @to]) then 
                local:create-date-triples($factoidRef, $residence)   
            else (),
        for $residenceNote in $residence/tei:note
        return local:make-triple(concat('swd:',$factoidRef),'rdfs:label', local:make-literal(string-join($residenceNote//text(),' '), 'en',()))  
        ),
    (: sanctity :)
    for $sanctity in $factoid[@subtype='sanctity']/descendant-or-self::tei:state
    return 
        (local:make-triple(concat('swd:',$persRef),'sp:sanctity', concat('swds:',$factoidRef)),
        for $sanctityAna in tokenize($sanctity/@ana, ' ')
        return 
                (local:make-triple(concat('swd:',$persRef),'swdt:sanctity', concat('swd:',substring-after($sanctityAna, "syriaca.org/"))),       
                local:make-triple(concat('swds:',$factoidRef),'sps:sanctity', concat('swd:',substring-after($sanctityAna, "syriaca.org/")))
                ),
        if($sanctity[@when or @notBefore or @notAfter or @from or @to]) then 
                local:create-date-triples($factoidRef, $sanctity)   
            else (),
        for $sanctityNote in $sanctity/tei:note
        return local:make-triple(concat('swd:',$factoidRef),'rdfs:label', local:make-literal(string($sanctityNote), 'en',()))  
        ),
    (: socecStatus :)
    for $socecStatus in $factoid[@subtype='socecStatus']/descendant-or-self::tei:socecStatus
    return 
        (local:make-triple(concat('swd:',$persRef),'sp:socec-status', concat('swds:',$factoidRef)),
        for $socecStatusAna in tokenize($socecStatus/@ana, ' ')
        return 
                (local:make-triple(concat('swd:',$persRef),'swdt:socec-status', concat('swd:',substring-after($socecStatusAna, "syriaca.org/"))),       
                local:make-triple(concat('swds:',$factoidRef),'sps:socec-status', concat('swd:',substring-after($socecStatusAna, "syriaca.org/")))
                ),
        if($socecStatus[@when or @notBefore or @notAfter or @from or @to]) then 
                local:create-date-triples($factoidRef, $socecStatus)   
            else (),
        for $socecStatusNote in $socecStatus/tei:note
        return local:make-triple(concat('swd:',$factoidRef),'rdfs:label', local:make-literal(string-join($socecStatusNote//text(),' '), 'en',()))  
        ),
    (: Relationships :)
    for $relation in $factoid/descendant-or-self::tei:relation[@type='person']
    let $rel := substring-after($relation/@ref, "keyword/")
    let $label := 
        if($relation/tei:desc) then 
            local:make-literal(string($relation/tei:desc), 'en',())
        else if($relation/ancestor::tei:ab/descendant::tei:event/tei:desc) then 
            local:make-literal(string($relation/ancestor::tei:ab/descendant::tei:event/tei:desc), 'en',())
        else ()    
    return
    (
        (: relation dates :)
        if($relation[@when or @notBefore or @notAfter or @from or @to]) then     
            local:create-date-triples($factoidRef, $relation)   
        else (),
        if($relation[@passive or @active]) then
            (
                (: relation active:)
                for $relActive in tokenize($relation/@active, ' ')
                return 
                    for $relActivePassive in tokenize($relation/@passive, ' ')
                    return 
                     (local:make-triple(concat('swd:',substring-after($relActive, "syriaca.org/")),concat('swdt:',$rel), concat('swd:',substring-after($relActivePassive, "syriaca.org/"))),
                     local:make-triple(concat('swd:',substring-after($relActive, "syriaca.org/")),concat('sp:',$rel), concat('swds:',$factoidRef)),
                     local:make-triple(concat('swds:',$factoidRef),concat('sps:',$rel), concat('swd:',substring-after($relActivePassive, "syriaca.org/"))),
                     if($label != '') then
                        local:make-triple(concat('swds:',$factoidRef),'rdfs:label', $label)   
                     else (),
                     for $relationshipQualifier in tokenize($relation/@ana, ' ')
                     return
                        local:make-triple(concat('spq:',$factoidRef),'spq:relationshipQualifier', concat('swd:',substring-after($relationshipQualifier, "keyword/")))
                     ),
                (: relation passive:)
                for $relPassive in tokenize($relation/@passive, ' ')
                return 
                    for $relPassiveActive in tokenize($relation/@active, ' ')
                    return 
                     (
                     local:make-triple(concat('swd:',substring-after($relPassive, "syriaca.org/")),concat('swdt:',$rel), concat('swd:',substring-after($relPassiveActive, "syriaca.org/"))),
                     local:make-triple(concat('swd:',substring-after($relPassive, "syriaca.org/")),concat('sp:',$rel), concat('swds:',$factoidRef)),
                     local:make-triple(concat('swds:',$factoidRef),concat('sps:',$rel), concat('swd:',substring-after($relPassiveActive, "syriaca.org/"))),
                     if($label != '') then
                        local:make-triple(concat('swds:',$factoidRef),'rdfs:label', $label)   
                     else (),
                     for $relationshipQualifier in tokenize($relation/@ana, ' ')
                     return
                     local:make-triple(concat('spq:',$factoidRef),'spq:relationshipQualifier', concat('swd:',substring-after($relationshipQualifier, "keyword/")))
                    )
            )
        else if($relation[@mutual]) then 
            for $relMutual in $relation[@mutual]  
            return     
                for $mutual in tokenize($relMutual/@mutual, ' ')
                return 
                    for $mutualRelated in tokenize($relMutual/@mutual, ' ')[not(. = $mutual)]
                    return 
                        (
                        local:make-triple(concat('swd:',substring-after($mutual, "syriaca.org/")),concat('swdt:',$rel), concat('swd:',substring-after($mutualRelated, "syriaca.org/"))),
                        local:make-triple(concat('swd:',substring-after($mutual, "syriaca.org/")),concat('sp:',$rel), concat('swd:',substring-after($mutualRelated, "syriaca.org/"))),
                        local:make-triple(concat('swds:',$factoidRef),concat('sps:',$rel), concat('swd:',substring-after($mutualRelated, "syriaca.org/"))),
                        local:make-triple(concat('swds:',$factoidRef),concat('sps:',$rel), concat('swd:',substring-after($mutual, "syriaca.org/"))),
                        if($label != '') then
                            local:make-triple(concat('swds:',$factoidRef),'rdfs:label', $label)   
                         else (),
                         for $relationshipQualifier in tokenize($relation/@ana, ' ')
                         return
                            local:make-triple(concat('spq:',$factoidRef),'spq:relationshipQualifier', concat('swd:',substring-after($relationshipQualifier, "keyword/")))
                        )
        else()
    ),
    (: Events :)
    for $event in $factoid[@subtype='event']
    return 
    ((:event description:)
        if($event/descendant-or-self::tei:listEvent/tei:event/tei:desc) then
            local:make-triple(concat('swds:',$factoidRef),'schema:description', local:make-literal(string-join($event/descendant-or-self::tei:listEvent/tei:event/tei:desc//text(),' '), 'en',()))
        else (),
       for $pers in $event/descendant::tei:persName/@ref
       let $eventPersRef := substring-after($pers, "syriaca.org/")
       return 
       (
       local:make-triple(concat('swd:event',$factoidRef),'swdt:event-participant', concat('swd:',$eventPersRef)),
       local:make-triple(concat('swd:event',$factoidRef),'sp:event-participant', concat('swds:',$factoidRef)),
       local:make-triple(concat('swds:',$factoidRef),'sp:event-participant', concat('swd:',$eventPersRef))
       ),
       for $place in $event/descendant::tei:placeName/@ref
       let $eventPlaceRef := substring-after($place, "syriaca.org/")
       return 
       (
       local:make-triple(concat('swd:event',$factoidRef),'swdt:event-place', concat('swd:',$eventPlaceRef)),
       local:make-triple(concat('swd:event',$factoidRef),'sp:event-place', concat('swds:',$factoidRef)),
       local:make-triple(concat('swds:',$factoidRef),'sps:event-place', concat('swd:',$eventPlaceRef))
       ),
       for $keyword in $event/descendant::tei:listEvent/tei:event/@ana
       let $eventKeywordRef := substring-after($keyword, "syriaca.org/")
       return 
       (
       local:make-triple(concat('swd:event',$factoidRef),'swdt:event-keyword', concat('swd:',$eventKeywordRef)),
       local:make-triple(concat('swd:event',$factoidRef),'sp:event-keyword', concat('swds:',$factoidRef)),
       local:make-triple(concat('swds:',$factoidRef),'sps:event-keyword', concat('swd:',$eventKeywordRef))
       ),
       for $when in $event/descendant::tei:listEvent/tei:event/@when
       let $eventWhenRef := substring-after($when, "syriaca.org/")
       return 
       (
       local:make-triple(concat('swd:event',$factoidRef),'swdt:when', concat('swd:',$eventWhenRef)),
       local:make-triple(concat('swd:event',$factoidRef),'sp:when', concat('swds:',$factoidRef)),
       local:make-triple(concat('swds:',$factoidRef),'sps:when', concat('swd:',$eventWhenRef))
       ),
       for $notBefore in $event/descendant::tei:listEvent/tei:event/@notBefore
       let $eventNotBeforeRef := substring-after($notBefore, "syriaca.org/")
       return 
       (
       local:make-triple(concat('swd:event',$factoidRef),'swdt:not-before', concat('swd:',$eventNotBeforeRef)),
       local:make-triple(concat('swd:event',$factoidRef),'sp:not-before', concat('swds:',$factoidRef)),
       local:make-triple(concat('swds:',$factoidRef),'sps:not-before', concat('swd:',$eventNotBeforeRef))
       ),
       for $notAfter in $event/descendant::tei:listEvent/tei:event/@notAfter
       let $eventNotAfterRef := substring-after($notAfter, "syriaca.org/")
       return 
       (
       local:make-triple(concat('swd:event',$factoidRef),'swdt:not-after', concat('swd:',$eventNotAfterRef)),
       local:make-triple(concat('swd:event',$factoidRef),'sp:not-after', concat('swds:',$factoidRef)),
       local:make-triple(concat('swds:',$factoidRef),'sps:not-after', concat('swd:',$eventNotAfterRef))
       ),
       for $from in $event/descendant::tei:listEvent/tei:event/@from
       let $eventFromRef := substring-after($from, "syriaca.org/")
       return 
       (
       local:make-triple(concat('swd:event',$factoidRef),'swdt:from', concat('swd:',$eventFromRef)),
       local:make-triple(concat('swd:event',$factoidRef),'sp:from', concat('swds:',$factoidRef)),
       local:make-triple(concat('swds:',$factoidRef),'sps:from', concat('swd:',$eventFromRef))
       ),
       for $to in $event/descendant::tei:listEvent/tei:event/@to
       let $eventToRef := substring-after($to, "syriaca.org/")
       return 
       (
       local:make-triple(concat('swd:event',$factoidRef),'swdt:from', concat('swd:',$eventToRef)),
       local:make-triple(concat('swd:event',$factoidRef),'sp:from', concat('swds:',$factoidRef)),
       local:make-triple(concat('swds:',$factoidRef),'sps:from', concat('swd:',$eventToRef))
       )
    ),
   (:
   Event related WS:Note - not done - check against other related code - probably handled by the other related code. should be fine... 
   
swd	string-join("event", substring-after(ab//note[@type='relatedEvent']//relation/@mutual, "/spear/"))	swdt	substring-after(ab[@subtype='event']/note[@type='relatedEvent']//relation/@ref, "keyword/")	[generated]	swd	string-join("event", substring-after(ab//note[@type='relatedEvent']//relation/@mutual, "/spear/"))	A1 explains why C3 and H3 have the same path and should grab different values.
swd	string-join("event", substring-after(ab//note[@type='relatedEvent']//relation/@mutual, "/spear/"))	sp	substring-after(ab[@subtype='event']/note[@type='relatedEvent']//relation/@ref, "keyword/")	[generated]	swds	substring-after(ab[@subtype='event']/idno, "/spear/")	
swds	substring-after(ab[@subtype='event']/idno, "/spear/")	sps	substring-after(ab[@subtype='event']/note[@type='relatedEvent']//relation/@ref, "keyword/")	[generated]	swd	string-join("event", substring-after(ab//note[@type='relatedEvent']//relation/@mutual, "/spear/"))	A1 explains why C5 and H5 have the same path and should grab different values.
swds	substring-after(ab[@subtype='socecStatus']/idno, "/spear/")	rdfs	label	rdfs:label		ab[@subtype='socecStatus']//socec-status/note	append @en


   :)
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

(:let $dataDump := subsequence(collection($config:data-root),1,5):)
let $data := data:get-document()    
return  
    if(request:get-parameter('download', '') = 'true') then
        for $r in subsequence(collection($config:data-root), 1, 5)
        let $fileName := substring-before(tokenize(document-uri($r),'/')[last()],'.')
        let $records := concat(local:prefix(),string-join(for $r in subsequence(collection($config:data-root), 1, 50) return local:make-triple-set-spear($r),''))
        return 
        (response:set-header("Content-Type", "text/turtle; charset=utf-8"),
         response:set-header("media-type", "text/plain"),
         response:set-header("Content-Disposition", fn:concat("attachment; filename=", concat('allSPEAR','.ttl'))),$records) 
    else 
        (response:set-header("Content-Type", "text/turtle; charset=utf-8"),
         response:set-header("media-type", "text/plain"),
         concat(local:prefix(), local:make-triple-set-spear($data)))