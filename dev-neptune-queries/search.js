const state = {
  selectedEventKeywords: new Set(),
  selectedRelationshipKeywords: new Set(),
  ethnicity: '',
  gender: '',
  uncertainty: '',
  place: '',           
  fieldOfStudy: '',    
  currentTab: 'factoids'
};

import { SPARQL_ENDPOINT } from './constants.js';

export async function fetchFactoidsWithFilters(state) {
  const query = buildFilterQuery(state);
  const url = `${SPARQL_ENDPOINT}?query=${encodeURIComponent(query)}`;

  try {
    const response = await fetch(url, {
      headers: {
        'Accept': 'application/sparql-results+json'
      }
    });

    if (!response.ok) {
      const text = await response.text();
      console.error('SPARQL query failed:', response.status, text);
      return [];
    }

    const data = await response.json();
    const bindings = data?.results?.bindings || [];

    return bindings.map(binding => ({
      uri: binding.factoid?.value || '',
      description: binding.description?.value || '',
      person: binding.person?.value || '',
      label: binding.label?.value || '',
      gender: binding.gender?.value?.split('/').pop() || ''
    }));
  } catch (error) {
    console.error('Failed to fetch factoids:', error);
    return [];
  }
}

// BUILD THE SQL QUERIES CUSTOM, MULTIFIELD
export function buildFilterQuery(state) {
  const eventPatterns = Array.from(state.selectedEventKeywords || []).map(uri => `
    {
      ?statementNode sps:event-keyword <${uri}> .
    }
  `);

  const relationshipPatterns = Array.from(state.selectedRelationshipKeywords || []).map(uri => `
    {
      ?person <${uri}> ?statementNode .
    }
  `);

  const ethnicityPattern = state.ethnicity
    ? `
      ?person swdt:ethnic-label <${state.ethnicity}> .
      ?person sp:ethnic-label ?ethnicityStmt .
    `
    : '';

  const genderPattern = state.gender
    ? `
      ?person swdt:gender <${state.gender}> .
    `
    : '';

  const uncertaintyFilter = state.uncertainty
    ? `
      FILTER NOT EXISTS {
        ?factoid spq:certainty ?level .
        FILTER(LCASE(STR(?level)) = "${state.uncertainty.toLowerCase()}")
      }
    `
    : '';

  const unionBlocks = [...eventPatterns, ...relationshipPatterns];
  const unionBlock = unionBlocks.length
    ? `FILTER EXISTS {
      ${unionBlocks.join('\n      UNION\n')}
    }`
    : '';

  return `
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX schema: <http://schema.org/>
PREFIX spr: <http://syriaca.org/prop/reference/>
PREFIX swdt: <http://syriaca.org/prop/direct/>
PREFIX sp: <http://syriaca.org/prop/>
PREFIX sps: <http://syriaca.org/prop/statement/>
PREFIX spq: <http://syriaca.org/prop/qualifier/>

SELECT DISTINCT ?factoid ?description ?person ?label ?gender
FROM <http://syriaca.org/persons#graph>
FROM <https://spear-prosop.org>
WHERE {
  ?statementNode spr:reference-URL ?factoid .

  OPTIONAL { ?factoid schema:description ?description . }

  OPTIONAL {
    ?statementNode ?p ?person .
    ?person rdfs:label ?label .
    FILTER(LANG(?label) = "en")
  }

  ${ethnicityPattern}
  ${genderPattern}
  ${uncertaintyFilter}
  ${unionBlock}
  ${placePattern}
  ${fieldOfStudyPattern}

}
ORDER BY ?label
LIMIT 200
`;
}


const placePattern = state.place
  ? `
    {
      ?person swdt:birth-place <${state.place}> ;
              sp:birth-place ?placeStatement .
    } UNION {
      ?person swdt:death-place <${state.place}> ;
              sp:death-place ?placeStatement .
    } UNION {
      ?person swdt:residence <${state.place}> ;
              sp:residence ?placeStatement .
    } UNION {
      ?event swdt:event-place <${state.place}> ;
             sp:event-place ?placeStatement .
    }
    ?placeStatement spr:reference-URL ?factoid .
  `
  : '';

const fieldOfStudyPattern = state.fieldOfStudy
  ? `
    ?statementNode sps:education <${state.fieldOfStudy}> ;
                   spr:reference-URL ?factoid .
  `
  : '';

export function buildFilterQuery(state) {
  const eventPatterns = Array.from(state.selectedEventKeywords || []).map(uri => `
    {
      ?statementNode sps:event-keyword <${uri}> .
    }
  `);

  const relationshipPatterns = Array.from(state.selectedRelationshipKeywords || []).map(uri => `
    {
      ?person <${uri}> ?statementNode .
    }
  `);

  const ethnicityPattern = state.ethnicity
    ? `
      ?person swdt:ethnic-label <${state.ethnicity}> .
      ?person sp:ethnic-label ?ethnicityStmt .
    `
    : '';

  const genderPattern = state.gender
    ? `
      ?person swdt:gender <${state.gender}> .
    `
    : '';

  const uncertaintyFilter = state.uncertainty
    ? `
      FILTER NOT EXISTS {
        ?factoid spq:certainty ?level .
        FILTER(LCASE(STR(?level)) = "${state.uncertainty.toLowerCase()}")
      }
    `
    : '';

  const unionBlocks = [...eventPatterns, ...relationshipPatterns];
  const unionBlock = unionBlocks.length
    ? `FILTER EXISTS {
      ${unionBlocks.join('\n      UNION\n')}
    }`
    : '';

  return `
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX schema: <http://schema.org/>
PREFIX spr: <http://syriaca.org/prop/reference/>
PREFIX swdt: <http://syriaca.org/prop/direct/>
PREFIX sp: <http://syriaca.org/prop/>
PREFIX sps: <http://syriaca.org/prop/statement/>
PREFIX spq: <http://syriaca.org/prop/qualifier/>

SELECT DISTINCT ?factoid ?description ?person ?label ?gender
FROM <http://syriaca.org/persons#graph>
FROM <https://spear-prosop.org>
WHERE {
  ?statementNode spr:reference-URL ?factoid .

  OPTIONAL { ?factoid schema:description ?description . }

  OPTIONAL {
    ?statementNode ?p ?person .
    ?person rdfs:label ?label .
    FILTER(LANG(?label) = "en")
  }

  ${ethnicityPattern}
  ${genderPattern}
  ${uncertaintyFilter}
  ${unionBlock}
}
ORDER BY ?label
LIMIT 200
`;
}
