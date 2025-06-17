import { SPARQL_ENDPOINT } from './factoidsqueries.js';
import fs from 'fs';

const getAllPersonFactoids = () => `
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX spr: <http://syriaca.org/prop/reference/>
PREFIX schema: <http://schema.org/>

SELECT DISTINCT ?factoid ?description
FROM <http://syriaca.org/persons#graph>
FROM NAMED <https://spear-prosop.org>
WHERE {
  ?person rdfs:label ?label .

  GRAPH <https://spear-prosop.org> {
    {
      ?person ?pred ?statementNode .
      ?statementNode spr:reference-URL ?factoid .
    }
    UNION
    {
      ?statementNode ?pred ?person .
      ?statementNode spr:reference-URL ?factoid .
    }

    FILTER(?factoid != ?person)

    OPTIONAL {
      ?factoid schema:description ?description .
    }
  }
}
ORDER BY ?factoid
`;

export const getEventKeywords = () => `
  PREFIX swdt: <http://syriaca.org/prop/direct/>

  SELECT DISTINCT ?keyword
  FROM <https://spear-prosop.org>
  WHERE {
    ?event swdt:event-keyword ?keyword .
  }
  ORDER BY ?keyword
`;

const getPlaceOptions = () => `
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX lawd: <http://lawd.info/ontology#>

SELECT DISTINCT ?place ?label ?relationType
FROM <http://syriaca.org/geo#graph>
FROM <https://spear-prosop.org>
WHERE {
  {
    ?person <http://syriaca.org/prop/direct/residence> ?place .
    BIND("residence" AS ?relationType)    
    ?place rdfs:label ?label .
         FILTER(LANG(?label) = "en")
  }
  UNION
  {
    ?person <http://syriaca.org/prop/direct/birth-place> ?place .
    BIND("birth-place" AS ?relationType)
    ?place rdfs:label ?label .
         FILTER(LANG(?label) = "en")
  }
  UNION
  {
    ?person <http://syriaca.org/prop/direct/death-place> ?place .
    BIND("death-place" AS ?relationType)
    ?place rdfs:label ?label .
      FILTER(LANG(?label) = "en")
  }
  UNION
  {
    ?event <http://syriaca.org/prop/direct/event-place> ?place .
    ?event <http://syriaca.org/prop/direct/event-participant> ?person .
    BIND("event-place" AS ?relationType)
    ?place rdfs:label ?label .
         FILTER(LANG(?label) = "en")
  }
  UNION
  {
    ?person <http://syriaca.org/prop/direct/citizenship> ?place .
    BIND("citizenship" AS ?relationType)
    ?place rdfs:label ?label .
      FILTER(LANG(?label) = "en")
  }
}
ORDER BY ?label
  `;
export const getEducationFieldsOfStudy = () => `
  PREFIX skos: <http://www.w3.org/2004/02/skos/core#>

  SELECT DISTINCT ?subject ?label
  WHERE {
    <http://syriaca.org/taxonomy/fields-of-study-collection> skos:member ?subject .
    ?subject skos:prefLabel ?label .
  }
  ORDER BY ?label
  `;


const query = getPlaceOptions();

// console.log("SPARQL query being sent:", query);

const output = async () => {
  try {
    const res = await fetch(`${SPARQL_ENDPOINT}?query=${encodeURIComponent(query)}`, {
      headers: { Accept: 'application/sparql-results+json' }
    });

    if (!res.ok) {
      const errorText = await res.text();
      console.error("SPARQL HTTP error:", res.status, errorText);
      throw new Error(`SPARQL HTTP error ${res.status}`);
    }

    const data = await res.json();

    if (!data.results?.bindings) {
      console.warn("No 'bindings' in response:", data);
      return [];
    }

    // return data.results.bindings.map(b => ({
    //   uri: b.factoid?.value ?? '',
    //   description: b.description?.value ?? ''
    // }));

    return data;
  } catch (err) {
    console.error("Failed to fetch factoids:", err);
    return [];
  }
};

const result = await output();

console.log("Result count:", result);

// fs.writeFileSync('factoids.json', JSON.stringify(result, null, 2), 'utf8');
// fs.writeFileSync('event-keywords.json', JSON.stringify(result, null, 2), 'utf8');
fs.writeFileSync('places.json', JSON.stringify(result, null, 2), 'utf8');