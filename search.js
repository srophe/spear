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
      event: binding.event?.value || '' ,
      stmt: binding.stmt?.value || ''
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
  // if (state.fieldOfStudy) {
  //   lines.push(`
  //     ?fieldStmt sps:education <${state.fieldOfStudy}> ;
  //                spr:reference-URL ?factoid .
  //   `);
  // }

  // Final query
  return `
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX schema: <http://schema.org/>
PREFIX spr: <http://syriaca.org/prop/reference/>
PREFIX swdt: <http://syriaca.org/prop/direct/>
PREFIX sp: <http://syriaca.org/prop/>
PREFIX sps: <http://syriaca.org/prop/statement/>
PREFIX spq: <http://syriaca.org/prop/qualifier/>

SELECT DISTINCT ?factoid ?description ?person ?label ?gender ?type ?statementNode ?relationship ?event ?level
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
    // selectedFieldOfStudyKeywords = [],
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
  selectedEthnicityKeywords.forEach(uri => {
    tripleBlocks.push(`?person swdt:ethnic-label <${uri}> .`);
    tripleBlocks.push(`?person sp:ethnic-label ?stmt .`);
  });

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
  // selectedFieldOfStudyKeywords.forEach(uri => {
  //   tripleBlocks.push(`?stmt sps:education <${uri}> .`);
  // });

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

// export function buildFilterCountQuery(state) {
//   const {
//     selectedEventKeywords = [],
//     selectedRelationshipKeywords = [],
//     selectedEthnicityKeywords = [],
//     selectedGenderKeywords = [],
//     selectedPlaceKeywords = [],
//     selectedFieldOfStudyKeywords = [],
//     selectedUncertaintyKeywords = []
//   } = state;

//   const tripleBlocks = [];

//   selectedEventKeywords.forEach(uri => {
//     tripleBlocks.push(`?stmt sps:event-keyword <${uri}> .`);
//   });

//   selectedRelationshipKeywords.forEach(uri => {
//     const safeUri = uri.replace('/taxonomy/', '/prop/');
//     tripleBlocks.push(`?person <${safeUri}> ?stmt .`);
//   });

//   selectedEthnicityKeywords.forEach(uri => {
//     tripleBlocks.push(`?person swdt:ethnic-label <${uri}> .`);
//     tripleBlocks.push(`?person sp:ethnic-label ?stmt .`);
//   });

//   selectedGenderKeywords.forEach(uri => {
//     tripleBlocks.push(`?person swdt:gender <${uri}> .`);
//     tripleBlocks.push(`?person sp:gender ?stmt .`);
//   });

//   selectedPlaceKeywords.forEach(uri => {
//     tripleBlocks.push(`
//       {
//         ?person swdt:birth-place <${uri}> ; sp:birth-place ?stmt .
//       } UNION {
//         ?person swdt:death-place <${uri}> ; sp:death-place ?stmt .
//       } UNION {
//         ?person swdt:residence <${uri}> ; sp:residence ?stmt .
//       } UNION {
//         ?event swdt:event-place <${uri}> ; sp:event-place ?stmt .
//       }
//     `);
//   });

//   // selectedFieldOfStudyKeywords.forEach(uri => {
//   //   tripleBlocks.push(`?stmt sps:education <${uri}> .`);
//   // });

//   let query = `
// PREFIX schema: <http://schema.org/>
// PREFIX swdt: <http://syriaca.org/prop/direct/>
// PREFIX spr: <http://syriaca.org/prop/reference/>
// PREFIX sp: <http://syriaca.org/prop/>
// PREFIX sps: <http://syriaca.org/prop/statement/>
// PREFIX spq: <http://syriaca.org/prop/qualifier/>

// SELECT (COUNT(DISTINCT ?factoid) AS ?count)
// FROM <https://spear-prosop.org>
// WHERE {
//   ${tripleBlocks.join('\n')}
//   ?stmt spr:reference-URL ?factoid .
// `;

//   if (selectedUncertaintyKeywords.length > 0) {
//     const filters = selectedUncertaintyKeywords
//       .map(level => `LCASE(STR(?level)) = "${level.toLowerCase()}"`)
//       .join(" || ");
//     query += `
//   FILTER NOT EXISTS {
//     ?factoid spq:certainty ?level .
//     FILTER(${filters})
//   }`;
//   }

//   query += `\n}`;

//   return query;
// }


export function buildMultiFilterQuery(state) {
 
  const selectVars = new Set(['?factoid', '?description']);
  const blocks = [];

  // Event Keyword filter // Add event participant?
  if (state.selectedEventKeywords.size > 0) {
    blocks.push(`
      ?statementNode sps:event-keyword ?eventKeyword .
      VALUES ?eventKeyword { ${Array.from(state.selectedEventKeywords).map(uri => `<${uri}>`).join(' ')} }
    `);
    selectVars.add('?eventKeyword');
  }

  // Relationship filter
  if (state.selectedRelationshipKeywords.size > 0) {
    blocks.push(`
      ?person ?relationship ?statementNode .
      VALUES ?relationship { ${Array.from(state.selectedRelationshipKeywords).map(uri => `<${uri.replace('/taxonomy/', '/prop/')}>`).join(' ')} }
    `);
    selectVars.add('?relationship');
  }

  // Ethnicity filter
  if (state.selectedEthnicityKeywords.size > 0) {
    blocks.push(`
      ?person swdt:ethnic-label ?ethnicity .
      ?person sp:ethnic-label ?statementNode .
      VALUES ?ethnicity { ${Array.from(state.selectedEthnicityKeywords).map(uri => `<${uri}>`).join(' ')} }
    `);
    selectVars.add('?ethnicity');
  }

  // Gender filter
  if (state.selectedGenderKeywords.size > 0) {
    blocks.push(`
      ?person swdt:gender ?gender .
      ?person sp:gender ?statementNode .
      VALUES ?gender { ${Array.from(state.selectedGenderKeywords).map(uri => `<${uri}>`).join(' ')} }
    `);
    selectVars.add('?gender');
  }

  // Place filter
if (state.selectedPlaceKeywords.size > 0) {
  const placeValues = Array.from(state.selectedPlaceKeywords)
    .map(uri => `<${uri}>`)
    .join(' ');

  blocks.push(`
    VALUES ?place { ${placeValues} }
    {
{
          ?person swdt:birth-place ?place .
          ?person sp:birth-place ?birthStmt .
          ?birthStmt spr:reference-URL ?factoid .
        } UNION {
          ?person swdt:death-place ?place .
          ?person sp:death-place ?deathStmt .
          ?deathStmt spr:reference-URL ?factoid .
        } UNION {
          ?person swdt:residence ?place .
          ?person sp:residence ?resStmt .
          ?resStmt spr:reference-URL ?factoid .
        } UNION {
          ?event swdt:event-place ?place ;
                 sp:event-place ?placeStmt .
          ?placeStmt spr:reference-URL ?factoid .
        }
    }
  `);

  selectVars.add('?place');
}
        // ?event swdt:event-place <${uri}> ; sp:event-place ?stmt .


  // Field of Study filter
  // if (state.selectedFieldOfStudyKeywords.size > 0) {
  //   blocks.push(`
  //     ?statementNode sps:education ?field .
  //     VALUES ?field { ${Array.from(state.selectedFieldOfStudyKeywords).map(uri => `<${uri}>`).join(' ')} }
  //   `);
  //   selectVars.add('?field');
  // }

  // Uncertainty filter
  let uncertaintyBlock = ''; // Declare in outer scope

if (state.uncertainty && state.uncertainty.trim() !== '') {
  const levels = state.uncertainty
    .split(',')
    .map(level => level.trim().toLowerCase())
    .filter(Boolean); // remove empty strings

  if (levels.length > 0) {
    const filters = levels.map(lvl => `"${lvl}"`).join(', ');
    uncertaintyBlock = `
      FILTER NOT EXISTS {
        ?factoid spq:certainty ?level .
        FILTER(LCASE(STR(?level)) IN (${filters}))
      }`;
  }
}

// We can bind the labels to the person in places in the query where we already have ?person bound
const needsPersonLabel = blocks.some(b =>
  b.includes('?person') &&
  !b.includes('swdt:birth-place') &&
  !b.includes('swdt:death-place') &&
  !b.includes('swdt:residence') &&
  !b.includes('swdt:event-place')
);
    if (needsPersonLabel) {
      blocks.push(`
        OPTIONAL {
          GRAPH <http://syriaca.org/persons#graph> {
            ?person rdfs:label ?label .
            FILTER(LANG(?label) = "en")
          }
        }
      `);
      selectVars.add('?label');
      selectVars.add('?person');
    }


  // Final SPARQL query
  return `
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX schema: <http://schema.org/>
PREFIX spr: <http://syriaca.org/prop/reference/>
PREFIX swdt: <http://syriaca.org/prop/direct/>
PREFIX sp: <http://syriaca.org/prop/>
PREFIX sps: <http://syriaca.org/prop/statement/>
PREFIX spq: <http://syriaca.org/prop/qualifier/>

SELECT DISTINCT ${Array.from(selectVars).join(' ')}
FROM NAMED <http://syriaca.org/persons#graph>
FROM <https://spear-prosop.org>
WHERE {
  ?statementNode spr:reference-URL ?factoid .

  OPTIONAL { ?factoid schema:description ?description . }

  ${blocks.join('\n')}
  ${uncertaintyBlock}
}
ORDER BY ?factoid
LIMIT 20000
`;
}



export async function fetchFactoidsByMultiType(state) {
  const query = buildMultiFilterQuery(state);
  console.log("buildMultiFilterQuery state:", state);
  console.log('Fetching factoids with multi-type query:', query);
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
      eventKeyword: b.eventKeyword?.value ?? '',
      relationship: b.relationship?.value ?? '',
      ethnicity: b.ethnicity?.value ?? '',
      gender: b.gender?.value ?? '',
      place: b.place?.value ?? '',
      field: b.field?.value ?? '',
    }));
  } catch (err) {
    console.error("Failed to fetch factoids:", err);
    return [];
  }
}

// export function buildMultiFilterQuery(state) {
//   const selectVars = new Set(['?factoid', '?description']);
//   const blocks = [];

//   // Event Keyword filter
//   if (state.selectedEventKeywords.size > 0) {
//     blocks.push(`
//       ?statementNode sps:event-keyword ?eventKeyword .
//       ?statementNode spr:reference-URL ?factoid .
//       VALUES ?eventKeyword { ${Array.from(state.selectedEventKeywords).map(uri => `<${uri}>`).join(' ')} }
//     `);
//     selectVars.add('?eventKeyword');
//   }

//   // Relationship filter
//   if (state.selectedRelationshipKeywords.size > 0) {
//     blocks.push(`
//       ?person ?relationship ?relStmt .
//       ?relStmt spr:reference-URL ?factoid .
//       VALUES ?relationship { ${Array.from(state.selectedRelationshipKeywords).map(uri => `<${uri.replace('/taxonomy/', '/prop/')}>`).join(' ')} }
//     `);
//     selectVars.add('?relationship');
//     selectVars.add('?person');
//   }

//   // Ethnicity filter
//   if (state.selectedEthnicityKeywords.size > 0) {
//     blocks.push(`
//       ?person swdt:ethnic-label ?ethnicity .
//       ?person sp:ethnic-label ?ethStmt .
//       ?ethStmt spr:reference-URL ?factoid .
//       VALUES ?ethnicity { ${Array.from(state.selectedEthnicityKeywords).map(uri => `<${uri}>`).join(' ')} }
//     `);
//     selectVars.add('?ethnicity');
//     selectVars.add('?person');
//   }

//   // Gender filter
//   if (state.selectedGenderKeywords.size > 0) {
//     blocks.push(`
//       ?person swdt:gender ?gender .
//       ?person sp:gender ?genderStmt .
//       ?genderStmt spr:reference-URL ?factoid .
//       VALUES ?gender { ${Array.from(state.selectedGenderKeywords).map(uri => `<${uri}>`).join(' ')} }
//     `);
//     selectVars.add('?gender');
//     selectVars.add('?person');
//   }

//   // Place filter
//   if (state.selectedPlaceKeywords.size > 0) {
//     const placeValues = Array.from(state.selectedPlaceKeywords).map(uri => `<${uri}>`).join(' ');
//     blocks.push(`
//       VALUES ?place { ${placeValues} }
//       {
//         {
//           ?person swdt:birth-place ?place .
//           ?person sp:birth-place ?birthStmt .
//           ?birthStmt spr:reference-URL ?factoid .
//         } UNION {
//           ?person swdt:death-place ?place .
//           ?person sp:death-place ?deathStmt .
//           ?deathStmt spr:reference-URL ?factoid .
//         } UNION {
//           ?person swdt:residence ?place .
//           ?person sp:residence ?resStmt .
//           ?resStmt spr:reference-URL ?factoid .
//         } UNION {
//           ?event swdt:event-place ?place ;
//                 sp:event-place ?stmt .
//           ?stmt spr:reference-URL ?factoid .
//         }
//       }
//     `);
//     selectVars.add('?place');
//     selectVars.add('?person'); // might be bound in first 3 branches
//     selectVars.add('?event'); // might be bound in last branch
//     selectVars.add('?birthStmt');
//     selectVars.add('?deathStmt');
//     selectVars.add('?resStmt');
//     selectVars.add('?stmt');
//   }

//   // Uncertainty filter
//   let uncertaintyBlock = '';
//   if (state.uncertainty && state.uncertainty.trim() !== '') {
//     const levels = state.uncertainty
//       .split(',')
//       .map(level => level.trim().toLowerCase())
//       .filter(Boolean);

//     if (levels.length > 0) {
//       const filters = levels.map(lvl => `"${lvl}"`).join(', ');
//       uncertaintyBlock = `
//         FILTER NOT EXISTS {
//           ?factoid spq:certainty ?level .
//           FILTER(LCASE(STR(?level)) IN (${filters}))
//         }`;
//     }
//   }

//   // Optional label binding
//   const needsPersonLabel = blocks.some(b => b.includes('?person'));
//   if (needsPersonLabel) {
//     blocks.push(`
//       OPTIONAL {
//         GRAPH <http://syriaca.org/persons#graph> {
//           ?person rdfs:label ?label .
//           FILTER(LANG(?label) = "en")
//         }
//       }
//     `);
//     selectVars.add('?label');
//   }

//   // Final SPARQL query
//   return `
// PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
// PREFIX schema: <http://schema.org/>
// PREFIX spr: <http://syriaca.org/prop/reference/>
// PREFIX swdt: <http://syriaca.org/prop/direct/>
// PREFIX sp: <http://syriaca.org/prop/>
// PREFIX sps: <http://syriaca.org/prop/statement/>
// PREFIX spq: <http://syriaca.org/prop/qualifier/>

// SELECT DISTINCT ${Array.from(selectVars).join(' ')}
// FROM NAMED <http://syriaca.org/persons#graph>
// FROM <https://spear-prosop.org>
// WHERE {
//   OPTIONAL { ?factoid schema:description ?description . }
//   ${blocks.join('\n')}
//   ${uncertaintyBlock}
// }
// ORDER BY ?factoid
// LIMIT 2000
// `;
// }
