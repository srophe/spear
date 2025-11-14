import event from "../modes/event";

export const SPARQL_ENDPOINT = "https://sparql.vanderbilt.edu/sparql";

export const getNames = () => `
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

SELECT DISTINCT ?person ?label_en 
FROM <http://syriaca.org/persons#graph>
FROM NAMED <https://spear-prosop.org>
WHERE {
  ?person rdfs:label ?label_en .
  FILTER(LANG(?label_en) = "en")
  {
    GRAPH <https://spear-prosop.org> {
      { ?person ?anyPredicate ?anyObject }
      UNION
      { ?anySubject ?anyPredicate ?person }
    }
  }
}
ORDER BY ?label_en
`;
//9 seconds: 902 results
export const getPeopleProfiles = () =>
      `
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX schema: <http://schema.org/>
PREFIX swdt: <http://syriaca.org/prop/direct/>

SELECT DISTINCT ?person ?label_en ?description (STRAFTER(STR(?gender), "/taxonomy/") AS ?sex)
WHERE {
  GRAPH <https://spear-prosop.org> {
    { ?person ?p ?o } UNION { ?s ?p ?person }
  }
  GRAPH <http://syriaca.org/persons#graph> {
    ?person rdfs:label ?label_en . 
    FILTER(LANG(?label_en) = "en")
    OPTIONAL {?person schema:description ?description}
    OPTIONAL  { ?person swdt:gender  ?gender }
  }
}
ORDER BY ?label_en
    `;

// Get people profiles with labels and descriptions and occupations
export const getPeopleNamesGenderOccupation = () =>
      `
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX schema: <http://schema.org/>
PREFIX swdt: <http://syriaca.org/prop/direct/>

SELECT DISTINCT ?person ?label_en ?description (STRAFTER(STR(?gender), "/taxonomy/") AS ?sex) ?occupation
WHERE {
  GRAPH <https://spear-prosop.org> {
    { ?person ?p ?o } UNION { ?s ?p ?person }
  }
  GRAPH <http://syriaca.org/persons#graph> {
    ?person rdfs:label ?label_en . 
    FILTER(LANG(?label_en) = "en")
    OPTIONAL {?person schema:description ?description}
    OPTIONAL  { ?person swdt:gender  ?gender }
    OPTIONAL { ?person swdt:occupation ?occupation }
  }
}
ORDER BY ?label_en
    `;

    // Curl test version
curl -G "https://sparql.vanderbilt.edu/sparql" \
  --data-urlencode 'query=
  PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX schema: <http://schema.org/>
PREFIX swdt: <http://syriaca.org/prop/direct/>
PREFIX spr: <http://syriaca.org/prop/reference/>
PREFIX sps: <http://syriaca.org/prop/statement/>


SELECT DISTINCT ?factoid ?person ?label_en ?description ?gender (STRAFTER(STR(?occupation), "/persons/") AS ?occupation)
WHERE {
  GRAPH <https://spear-prosop.org> {
    ?statementNode sps:event-participant ?person ;
                   spr:reference-URL ?factoid .
    OPTIONAL { ?person swdt:occupation ?occupation }

  }
  GRAPH <http://syriaca.org/persons#graph> {
    ?person rdfs:label ?label_en .
    FILTER(LANG(?label_en) = "en")
    OPTIONAL {?person schema:description ?description}
    OPTIONAL  { ?person swdt:gender  ?gender }
    OPTIONAL { ?person swdt:occupation ?occupation }
  }
}
ORDER BY ?label_en
  ' \
  -H "Accept: application/sparql-results+json"

// Limits and offsets do not save api call time, unfortunately
export const getPeopleProfilesLimited = (limit = 25, offset = 0) =>
    `
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX schema: <http://schema.org/>
PREFIX swdt: <http://syriaca.org/prop/direct/>

SELECT DISTINCT
  (STR(?person) AS ?uri)
  (STR(?label_en) AS ?name)
  (STR(?desc) AS ?description)
  (STRAFTER(STR(?gender), "/taxonomy/") AS ?sex)
FROM <http://syriaca.org/persons#graph>
FROM NAMED <https://spear-prosop.org>
WHERE {
  ?person rdfs:label ?label_en . 
  FILTER(LANG(?label_en) = "en")
  OPTIONAL {?person schema:description ?desc}
  OPTIONAL { ?person swdt:gender  ?gender }

  {
    GRAPH <https://spear-prosop.org> {
      { ?person ?anyPredicate ?anyObject }
      UNION
      { ?anySubject ?anyPredicate ?person }
    }
  }
}
ORDER BY ?label_en
LIMIT ${limit}
OFFSET ${offset}
`;

export const getPersonByUri = (uri) =>
    `
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX schema: <http://schema.org/>
PREFIX swdt: <http://syriaca.org/prop/direct/>

SELECT DISTINCT
  (STR(?label_en) AS ?name)
  (STR(?desc) AS ?description)
  (STRAFTER(STR(?gender), "/taxonomy/") AS ?sex)
FROM <http://syriaca.org/persons#graph>
WHERE {
  <${uri}> rdfs:label ?label_en . 
  FILTER(LANG(?label_en) = "en")
  OPTIONAL <${uri}> schema:description ?desc
  OPTIONAL { <${uri}> swdt:gender ?gender }
}
`;
//Example:
// curl -G https://sparql.vanderbilt.edu/sparql \
//   --data-urlencode 'query=
// PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
// PREFIX schema: <http://schema.org/>
// PREFIX swdt: <http://syriaca.org/prop/direct/>

// SELECT DISTINCT
//   (STR(?label_en) AS ?name)
//   (STR(?desc) AS ?description)
//   (STRAFTER(STR(?gender), "/taxonomy/") AS ?sex)
// FROM <http://syriaca.org/persons#graph>
// WHERE {
//   <http://syriaca.org/person/3784> rdfs:label ?label_en . 
//   FILTER(LANG(?label_en) = "en")
//   <http://syriaca.org/person/3784> schema:description ?desc .
//   OPTIONAL { <http://syriaca.org/person/3784> swdt:gender ?gender }
// }' \
//   -H 'Accept: application/sparql-results+json'

