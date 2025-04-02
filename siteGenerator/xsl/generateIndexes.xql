(: Sample xqueries for generating index pages:)
let $tei := 
        <TEI xmlns="http://www.tei-c.org/ns/1.0">
            {
                let $items := collection('/db/apps/spear-data/data')
                let $refs := 
                    string-join(
                        for $r in $items/descendant::tei:ab//@ref | $items/descendant::tei:ab//@ana 
                        where contains($r,'syriaca.org/person/') or contains($r,'syriaca.org/place/') or contains($r,'syriaca.org/keyword/') 
                        return string($r), ' ')
                let $dedup := 
                    for $t in distinct-values(tokenize($refs,' '))
                    return $t 
                let $taxonomy := collection('/db/apps/syriaca-data/data/taxonomy')
                for $s in $taxonomy//*:Description[starts-with(@*:about,'http://syriaca.org/taxonomy/')]
                let $idno := string($s/@*:about)
                return 
                <keyword>
                    <idno>{$idno}</idno>
                    <title>{$s/*:prefLabel}</title>
                    <abstract>{$s/*:scopeNote}</abstract>
                    <related>
                        {if($dedup[. = $idno]) then <refs>{string($idno)}</refs> else ()}
                    </related>
                </keyword>
            }
        </TEI>
return xmldb:store('/db/apps/spear-data', 'keywordsIndex.xml', $tei)        

let $tei :=
<TEI xmlns="http://www.tei-c.org/ns/1.0">
            {
                    for $p in collection('/db/apps/syriaca-data/data/places')
                    let $ref2 := replace($p/descendant::tei:publicationStmt/tei:idno[1],'/tei','')
                    return 
                    <place>
                        <idno>{$ref2}</idno>
                        <title>{
                            if($p/descendant-or-self::*[@syriaca-tags='#syriaca-headword'][@xml:lang='en']) then 
                                $p/descendant-or-self::*[@syriaca-tags='#syriaca-headword'][@xml:lang='en'][1]/descendant-or-self::text()
                            else if($p/descendant-or-self::*[@srophe:tags='#syriaca-headword'][@xml:lang='en']) then 
                                $p/descendant-or-self::*[@srophe:tags='#syriaca-headword'][@xml:lang='en'][1]/descendant-or-self::text()                            
                            else if($p/descendant::tei:title[@level="a"][@xml:lang='en']) then 
                                $p/descendant::tei:title[@level="a"][@xml:lang='en'][1]/descendant-or-self::text()     
                            else $p/descendant::tei:title[1]/descendant-or-self::text()
                          }</title>
                        <abstract>{$p/descendant-or-self::tei:note[@type='abstract']}</abstract>
                    </place>
            }
        </TEI>
return xmldb:store('/db/apps/spear-data', 'placesIndex.xml', $tei)

let $tei := 
        <TEI xmlns="http://www.tei-c.org/ns/1.0">
            {
                    for $p in collection('/db/apps/syriaca-data/data/persons')
                    let $ref2 := replace($p/descendant::tei:publicationStmt/tei:idno[1],'/tei','')
                    return 
                    <person>
                        <idno>{$ref2}</idno>
                        <title>{
                            if($p/descendant-or-self::*[@syriaca-tags='#syriaca-headword'][@xml:lang='en']) then 
                                $p/descendant-or-self::*[@syriaca-tags='#syriaca-headword'][@xml:lang='en'][1]/descendant-or-self::text()
                            else if($p/descendant-or-self::*[@srophe:tags='#syriaca-headword'][@xml:lang='en']) then 
                                $p/descendant-or-self::*[@srophe:tags='#syriaca-headword'][@xml:lang='en'][1]/descendant-or-self::text()                            
                            else if($p/descendant::tei:title[@level="a"][@xml:lang='en']) then 
                                $p/descendant::tei:title[@level="a"][@xml:lang='en'][1]/descendant-or-self::text()     
                            else $p/descendant::tei:title[1]/descendant-or-self::text()
                          }</title>
                        <abstract>{$p/descendant-or-self::tei:note[@type='abstract']}</abstract>
                    </person>
            }
        </TEI>
return xmldb:store('/db/apps/spear-data', 'personsIndex.xml', $tei)

let $tei := 
        <TEI xmlns="http://www.tei-c.org/ns/1.0">
            {
                    let $items := collection('/db/apps/spear-data/data')
                    let $bibls := 
                        string-join(
                            for $r in $items/descendant::tei:bibl/tei:ptr/@target
                            return string($r), ' ')
                    let $dedup := 
                        for $t in distinct-values(tokenize($bibls,' '))
                        return $t 
                    for $p in collection('/db/apps/syriaca-data/data/bibl')
                    let $ref2 := replace($p/descendant::tei:publicationStmt/tei:idno[1],'/tei','')
                    where $ref2 = $dedup
                    return 
                    <bibl>
                        <idno>{$ref2}</idno>
                        <citation>{$p/descendant::tei:bibl[@subtype='citation']}</citation>
                        {
                            for $id in $p/descendant::tei:biblStruct/descendant::tei:idno[@type='URI']
                            return $id
                            }
                    </bibl>
            }
        </TEI>
return xmldb:store('/db/apps/spear-data', 'biblIndex.xml', $tei)