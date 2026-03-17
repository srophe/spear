# Two-step process to get all relationship factoids

## Step 1: Get all relationship types from the menu

```bash
curl -G "https://sparql.vanderbilt.edu/sparql" \
  --data-urlencode 'query=
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>

SELECT DISTINCT ?subject ?label
WHERE {
  VALUES (?collection) {
    (<http://syriaca.org/taxonomy/directed-relations-collection>)
    (<http://syriaca.org/taxonomy/mutual-relations-collection>)
  }
  ?collection skos:member ?subject .
  ?subject skos:prefLabel ?label .
}
ORDER BY ?label
' \
-H "Accept: application/sparql-results+json" > relationship_types.json
```

## Step 2: Get all factoids for those relationships

```bash
curl -G "https://sparql.vanderbilt.edu/sparql" \
  --data-urlencode 'query=
PREFIX sp: <http://syriaca.org/prop/>
PREFIX spr: <http://syriaca.org/prop/reference/>
PREFIX schema: <http://schema.org/>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>

SELECT DISTINCT ?factoid ?description ?source
FROM <https://spear-prosop.org>
WHERE {
  # Get all relationship types
  VALUES (?collection) {
    (<http://syriaca.org/taxonomy/directed-relations-collection>)
    (<http://syriaca.org/taxonomy/mutual-relations-collection>)
  }
  ?collection skos:member ?relationshipType .
  
  # Convert taxonomy URI to prop URI
  BIND(IRI(REPLACE(STR(?relationshipType), "/taxonomy/", "/prop/")) AS ?relationshipProp)
  
  # Find factoids with this relationship
  ?person ?relationshipProp ?statementNode .
  ?statementNode spr:reference-URL ?factoid .
  
  OPTIONAL { ?factoid schema:description ?description }
  OPTIONAL { ?factoid spr:part-of-series ?source }
}
ORDER BY ?factoid
LIMIT 20000
' \
-H "Accept: application/sparql-results+json" > relation_factoids.json
```

## Alternative: Use discovered relationship properties directly, times out and needs source filter

If Step 2 returns empty, use the properties we discovered from your diagnostic query:

```bash
curl -G "https://sparql.vanderbilt.edu/sparql" \
  --data-urlencode 'query=
PREFIX sp: <http://syriaca.org/prop/>
PREFIX spr: <http://syriaca.org/prop/reference/>
PREFIX schema: <http://schema.org/>

SELECT DISTINCT ?factoid ?description ?source ?relationshipProp
FROM <https://spear-prosop.org>
WHERE {
  ?person ?relationshipProp ?statementNode .
  ?statementNode spr:reference-URL ?factoid .
  
  # Filter to only relationship properties
  FILTER(CONTAINS(STR(?relationshipProp), "syriaca.org/prop/"))
  FILTER(CONTAINS(STR(?relationshipProp), "syriaca.org/taxonomy/"))

  FILTER(?relationshipProp NOT IN (sp:gender, sp:occupation, sp:birth, sp:death, 
                                    sp:residence, sp:event-keyword, sp:birth-place, 
                                    sp:death-place, sp:event-place, sp:event-participant, sp:name:variant))
  
  OPTIONAL { ?factoid schema:description ?description }
  OPTIONAL { ?factoid spr:part-of-series ?source }
}
ORDER BY ?factoid
LIMIT 20000
' \
-H "Accept: application/sparql-results+json" > relation_factoids.json
```

The alternative query is more reliable since it uses the actual properties that exist in the database.
