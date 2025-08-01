

export const SPARQL_ENDPOINT = "https://sparql.vanderbilt.edu/sparql";

export async function fetchFactoidsWithFilters(state) {
  const query = buildFilterQuery(state);
  const url = `${SPARQL_ENDPOINT}?query=${encodeURIComponent(query)}`;
  console.log('Fetching factoids with query:', query);  
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
    console.log('Fetched factoids:', bindings);
    return bindings.map(binding => ({
      uri: binding.factoid?.value || '',
      description: binding.description?.value || '',
      person: binding.person?.value || '',
      label: binding.label?.value || '',
      gender: binding.gender?.value?.split('/').pop() || '',
      uncertainty: binding.level?.value || '',
      type: binding.type?.value || '',
      relationship: binding.relationship?.value || '',
      event: binding.event?.value || '' 
    }));
  } catch (error) {
    console.error('Failed to fetch factoids:', error);
    return [];
  }
}
export function buildFilterQueryExclusiveNoLabels(state) {
  const lines = [];

  // Core binding
  lines.push(`?statementNode spr:reference-URL ?factoid .`);

  // Gender
  if (state.gender) {
    lines.push(`?person swdt:gender <${state.gender}> .`);
  }

  // Uncertainty filter (excludes specific certainty values)
  if (state.uncertainty) {
    lines.push(`
      FILTER NOT EXISTS {
        ?factoid spq:certainty ?level .
        FILTER(LCASE(STR(?level)) = "${state.uncertainty.toLowerCase()}")
      }
    `);
  }

  // Event keyword
  for (const keyword of state.selectedEventKeywords || []) {
    lines.push(`
      ?statementNode sps:event-keyword <${keyword}> .
    `);
  }

  // Relationship
  for (const rel of state.selectedRelationshipKeywords || []) {
    lines.push(`
      ?person <${rel}> ?statementNode .
    `);
  }

  // Ethnicity
  for (const eth of state.selectedEthnicityKeywords || []) {
    lines.push(`
      ?person swdt:ethnic-label <${eth}> .
      ?person sp:ethnic-label ?statementNode .
    `);
  }

  // Place
  if (state.place) {
    lines.push(`
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
    `);
  }

  // Field of Study
  if (state.fieldOfStudy) {
    lines.push(`
      ?fieldStmt sps:education <${state.fieldOfStudy}> ;
                 spr:reference-URL ?factoid .
    `);
  }

  // Final query
  return `
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX schema: <http://schema.org/>
PREFIX spr: <http://syriaca.org/prop/reference/>
PREFIX swdt: <http://syriaca.org/prop/direct/>
PREFIX sp: <http://syriaca.org/prop/>
PREFIX sps: <http://syriaca.org/prop/statement/>
PREFIX spq: <http://syriaca.org/prop/qualifier/>

SELECT DISTINCT ?factoid ?description ?person ?label ?gender ?type 
FROM <http://syriaca.org/persons#graph>
FROM <https://spear-prosop.org>
WHERE {
  ${lines.join('\n')}

  OPTIONAL { ?factoid schema:description ?description . }

  OPTIONAL {
    ?statementNode ?p ?person .
    ?person rdfs:label ?label .
    FILTER(LANG(?label) = "en")
  }
}
ORDER BY ?label
LIMIT 20
`;
}


export function buildFilterQuery(state) {
  const {
    selectedEventKeywords = [],
    selectedRelationshipKeywords = [],
    selectedEthnicityKeywords = [],
    selectedGenderKeywords = [],
    selectedPlaceKeywords = [],
    selectedFieldOfStudyKeywords = [],
    selectedUncertaintyKeywords = []
  } = state;

  const tripleBlocks = [];

  // Event Keywords
  selectedEventKeywords.forEach(uri => {
    tripleBlocks.push(`?stmt sps:event-keyword <${uri}> .`);
  });

  // Relationships
  selectedRelationshipKeywords.forEach(uri => {
    const safeUri = uri.replace('/taxonomy/', '/prop/');
    tripleBlocks.push(`?person <${safeUri}> ?stmt .`);
  });

  // Ethnicity
  if (selectedEthnicityKeywords.length > 0) {
    const ethnicityUnion = selectedEthnicityKeywords.map(uri => `
      {
        ?person swdt:ethnic-label <${uri}> .
        ?person sp:ethnic-label ?stmt .
      }
    `).join(' UNION ');

    tripleBlocks.push(ethnicityUnion);
  }


  // Gender: How is this handled in Neptune, need named graph block?
  selectedGenderKeywords.forEach(uri => {
    tripleBlocks.push(`?person swdt:gender <${uri}> .`);
    tripleBlocks.push(`?person sp:gender ?stmt .`);
  });

  // Place
  selectedPlaceKeywords.forEach(uri => {
    tripleBlocks.push(`
      {
        ?person swdt:birth-place <${uri}> ; sp:birth-place ?stmt .
      } UNION {
        ?person swdt:death-place <${uri}> ; sp:death-place ?stmt .
      } UNION {
        ?person swdt:residence <${uri}> ; sp:residence ?stmt .
      } UNION {
        ?event swdt:event-place <${uri}> ; sp:event-place ?stmt .
      }
    `);
  });

  // Field of Study
  selectedFieldOfStudyKeywords.forEach(uri => {
    tripleBlocks.push(`?stmt sps:education <${uri}> .`);
  });

  // Begin query template
  let query = `
PREFIX schema: <http://schema.org/>
PREFIX swdt: <http://syriaca.org/prop/direct/>
PREFIX spr: <http://syriaca.org/prop/reference/>
PREFIX sp: <http://syriaca.org/prop/>
PREFIX sps: <http://syriaca.org/prop/statement/>
PREFIX spq: <http://syriaca.org/prop/qualifier/>

SELECT DISTINCT ?factoid ?description ?label ?person ?type ?relationship ?event ?level ?stmt
FROM <https://spear-prosop.org>
WHERE {
  ${tripleBlocks.join('\n')}
  ?stmt spr:reference-URL ?factoid .
  OPTIONAL { ?factoid schema:description ?description . }
`;

if (state.uncertainty && state.uncertainty.trim() !== '') {
  const levels = state.uncertainty
    .split(',')
    .map(level => level.trim().toLowerCase())
    .filter(Boolean); // remove empty strings

  if (levels.length > 0) {
    const filters = levels.map(lvl => `"${lvl}"`).join(', ');
    query += `
      FILTER NOT EXISTS {
        ?factoid spq:certainty ?level .
        FILTER(LCASE(STR(?level)) IN (${filters}))
      }`;
  }
}


  query += `\n}\nORDER BY ?factoid`;

  return query;
}

export function buildFilterCountQuery(state) {
  const {
    selectedEventKeywords = [],
    selectedRelationshipKeywords = [],
    selectedEthnicityKeywords = [],
    selectedGenderKeywords = [],
    selectedPlaceKeywords = [],
    selectedFieldOfStudyKeywords = [],
    selectedUncertaintyKeywords = []
  } = state;

  const tripleBlocks = [];

  selectedEventKeywords.forEach(uri => {
    tripleBlocks.push(`?stmt sps:event-keyword <${uri}> .`);
  });

  selectedRelationshipKeywords.forEach(uri => {
    const safeUri = uri.replace('/taxonomy/', '/prop/');
    tripleBlocks.push(`?person <${safeUri}> ?stmt .`);
  });

  selectedEthnicityKeywords.forEach(uri => {
    tripleBlocks.push(`?person swdt:ethnic-label <${uri}> .`);
    tripleBlocks.push(`?person sp:ethnic-label ?stmt .`);
  });

  selectedGenderKeywords.forEach(uri => {
    tripleBlocks.push(`?person swdt:gender <${uri}> .`);
    tripleBlocks.push(`?person sp:gender ?stmt .`);
  });

  selectedPlaceKeywords.forEach(uri => {
    tripleBlocks.push(`
      {
        ?person swdt:birth-place <${uri}> ; sp:birth-place ?stmt .
      } UNION {
        ?person swdt:death-place <${uri}> ; sp:death-place ?stmt .
      } UNION {
        ?person swdt:residence <${uri}> ; sp:residence ?stmt .
      } UNION {
        ?event swdt:event-place <${uri}> ; sp:event-place ?stmt .
      }
    `);
  });

  selectedFieldOfStudyKeywords.forEach(uri => {
    tripleBlocks.push(`?stmt sps:education <${uri}> .`);
  });

  let query = `
PREFIX schema: <http://schema.org/>
PREFIX swdt: <http://syriaca.org/prop/direct/>
PREFIX spr: <http://syriaca.org/prop/reference/>
PREFIX sp: <http://syriaca.org/prop/>
PREFIX sps: <http://syriaca.org/prop/statement/>
PREFIX spq: <http://syriaca.org/prop/qualifier/>

SELECT (COUNT(DISTINCT ?factoid) AS ?count)
FROM <https://spear-prosop.org>
WHERE {
  ${tripleBlocks.join('\n')}
  ?stmt spr:reference-URL ?factoid .
`;

  if (selectedUncertaintyKeywords.length > 0) {
    const filters = selectedUncertaintyKeywords
      .map(level => `LCASE(STR(?level)) = "${level.toLowerCase()}"`)
      .join(" || ");
    query += `
  FILTER NOT EXISTS {
    ?factoid spq:certainty ?level .
    FILTER(${filters})
  }`;
  }

  query += `\n}`;

  return query;
}


export function buildMultiFilterQuery(state) {
  const {
    selectedEventKeywords = [],
    selectedRelationshipKeywords = [],
    selectedEthnicityKeywords = [],
    selectedGenderKeywords = [],
    selectedPlaceKeywords = [],
    selectedFieldOfStudyKeywords = [],
    selectedUncertaintyKeywords = []
  } = state;

  const valuesBlocks = [
    buildValuesBlock("eventKeyword", selectedEventKeywords),
    buildValuesBlock("relationship", selectedRelationshipKeywords),
    buildValuesBlock("ethnicity", selectedEthnicityKeywords),
    buildValuesBlock("gender", selectedGenderKeywords),
    buildValuesBlock("place", selectedPlaceKeywords),
    buildValuesBlock("field", selectedFieldOfStudyKeywords),
  ].filter(Boolean).join('\n');

  const uncertaintyBlock = selectedUncertaintyKeywords.length
    ? selectedUncertaintyKeywords.map(level => `
        FILTER NOT EXISTS {
          ?factoid spq:certainty ?level .
          FILTER(LCASE(STR(?level)) = "${level.toLowerCase()}")
        }
      `).join('\n')
    : '';

  return `
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX schema: <http://schema.org/>
PREFIX spr: <http://syriaca.org/prop/reference/>
PREFIX swdt: <http://syriaca.org/prop/direct/>
PREFIX sp: <http://syriaca.org/prop/>
PREFIX sps: <http://syriaca.org/prop/statement/>
PREFIX spq: <http://syriaca.org/prop/qualifier/>

SELECT DISTINCT ?factoid ?description ?label ?person
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

  ${valuesBlocks}

  # Filters based on values blocks
  ${selectedEventKeywords.length ? '?statementNode sps:event-keyword ?eventKeyword .' : ''}
  ${selectedRelationshipKeywords.length ? '?person ?relationship ?statementNode .' : ''}
  ${selectedEthnicityKeywords.length ? `
    ?person swdt:ethnic-label ?ethnicity .
    ?person sp:ethnic-label ?statementNode .
  ` : ''}
  ${selectedGenderKeywords.length ? '?person swdt:gender ?gender .' : ''}
  ${selectedPlaceKeywords.length ? `
    {
      ?person swdt:birth-place ?place ;
              sp:birth-place ?placeStatement .
    } UNION {
      ?person swdt:death-place ?place ;
              sp:death-place ?placeStatement .
    } UNION {
      ?person swdt:residence ?place ;
              sp:residence ?placeStatement .
    } UNION {
      ?event swdt:event-place ?place ;
             sp:event-place ?placeStatement .
    }
    ?placeStatement spr:reference-URL ?factoid .
  ` : ''}
  ${selectedFieldOfStudyKeywords.length ? `
    ?statementNode sps:education ?field ;
                   spr:reference-URL ?factoid .
  ` : ''}

  ${uncertaintyBlock}
}
ORDER BY ?label
LIMIT 200
`;
}

export async function fetchFactoidsByMultiType(state) {
  const query = buildMultiFilterQuery(state);

  try {
    const res = await fetch(`${SPARQL_ENDPOINT}?query=${encodeURIComponent(query)}`, {
      headers: { Accept: 'application/sparql-results+json' }
    });

    if (!res.ok) {
      const errorText = await res.text();
      console.error("SPARQL HTTP error:", res.status, errorText);
      return [];
    }

    const data = await res.json();
    return data.results.bindings.map(b => ({
      uri: b.factoid?.value ?? '',
      description: b.description?.value ?? '',
      label: b.label?.value ?? '',
      person: b.person?.value ?? '',
      gender: b.gender?.value ?? '',
      uncertainty: b.level?.value ?? '',
      type: b.type?.value ?? '',
      relationship: b.relationship?.value ?? '',
      event: b.event?.value ?? ''
    }));
  } catch (err) {
    console.error("Failed to fetch factoids:", err);
    return [];
  }
}
function buildValuesBlock(variable, uris) {
  if (!uris?.length) return '';
  const values = uris.map(uri => `<${uri}>`).join(' ');
  return `VALUES ?${variable} { ${values} }`;
}
