export const SPARQL_ENDPOINT = "https://sparql.vanderbilt.edu/sparql";



// Relation Factoids
function buildRelationFactoidQuery(state) {
 
  const selectVars = new Set(['?factoid', '?description','?source','?relationship']);
  const blocks = [];
  console.log("state: ", state);
  // Person filter: filtering currently in json for partial string matches
  // if (state.persons.length > 0) {
  //   blocks.push(`
  //     ?statementNode sps:event-participant ?person .
  //     ?statementNode spr:reference-URL ?factoid .
  //     VALUES ?person { ${Array.from(state.persons).map(uri => `<${uri}>`).join(' ')} }
  //   `);
  //   selectVars.add('?person');
  // }
  // Event Uri filter: Handles the person filters for gender, name, and occupation
  if (state.relations.length > 0) {
    console.log("Adding relations URIs to SPARQL query:", state.relations);
    blocks.push(`
      ?statementNode spr:reference-URL ?factoid .
      VALUES ?factoid { ${Array.from(state.relations).map(uri => `<${uri}>`).join(' ')} }
    `);
  }

  // Source filter
  if (state.selectedSourceKeywords.size > 0) {
    blocks.push(`
      ?factoid spr:part-of-series ?source .
      VALUES ?source { ${Array.from(state.selectedSourceKeywords).map(uri => `<${uri}>`).join(' ')} }
    `);
    selectVars.add('?source');
  } else {
    blocks.push(`    
    ?factoid spr:part-of-series ?source .
      VALUES ?source {
    <https://spear-prosop.org/chronicle-edessa>
    <https://spear-prosop.org/lives-eastern-saints>
    <https://spear-prosop.org/letters-severus>
  }`)
  }
 // Gender filter
  // if (state.selectedGenderKeywords.size > 0) {
  //   blocks.push(`
  //     ?person swdt:gender ?gender .
  //     ?person sp:gender ?statementNode .
  //     VALUES ?gender { ${Array.from(state.selectedGenderKeywords).map(uri => `<${uri}>`).join(' ')} }
  //   `);
  //   selectVars.add('?gender');
  // }
  // Relationship filter//works for person
  if (state.selectedRelationshipKeywords.size > 0) {
    blocks.push(`
      ?person ?relationship ?statementNode .
      ?statementNode spr:reference-URL ?factoid .
      VALUES ?relationship { ${Array.from(state.selectedRelationshipKeywords).map(uri => `<${uri.replace('/taxonomy/', '/prop/')}>`).join(' ')} }
    `);
  }
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
PREFIX sp:   <http://syriaca.org/prop/>
PREFIX spr:  <http://syriaca.org/prop/reference/>
PREFIX schema: <http://schema.org/>
PREFIX swdt: <http://syriaca.org/prop/direct/>

PREFIX sps: <http://syriaca.org/prop/statement/>
PREFIX spq: <http://syriaca.org/prop/qualifier/>

SELECT DISTINCT ${Array.from(selectVars).join(' ')}
FROM <https://spear-prosop.org>
FROM NAMED <http://syriaca.org/persons#graph>
WHERE {
  ${blocks.join('\n')}
  ${uncertaintyBlock}

    ?statementNode spr:reference-URL ?factoid .

  OPTIONAL { ?factoid schema:description ?description . }
  
}
ORDER BY ?factoid
LIMIT 20000
`;
}

export async function fetchRelationFactoids(state) {
 const query = buildRelationFactoidQuery(state);
  console.log("Buiding query with state:", state);
  console.log('Fetching factoids with query:', query);
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
      relationship: b.relationship?.value ?? '',
      gender: b.gender?.value ?? '',
      field: b.field?.value ?? '',
      source: b.source?.value ?? '',
      uncertainty: b.level?.value ?? '',
      type: b.type?.value ?? '',
      stmt: b.stmt?.value ?? ''
    }));
  } catch (err) {
    console.error("Failed to fetch factoids:", err);
    return [];
  }
}

export async function fetchData(state) {
  const query = buildMultiFilterQuery(state);
  console.log("Build MultiFilterQuery with state:", state);
  console.log('Fetching persons with multi-type query:', query);

    // --- EARLY EXIT CONDITION: Source-only selection crashes Neptune---
//   const onlySourceSelected =
//     state.selectedSourceKeywords.size > 0 && state.selectedSourceKeywords.size < 3 &&
//     (!state.persons || state.persons.length === 0) &&
//     state.selectedRelationshipKeywords.size === 0 &&
//     state.selectedOccupationKeywords.size === 0 &&
//     state.selectedGenderKeywords.size === 0 &&

//     if(onlySourceSelected) {
//         console.warn("Source-only facet query prevented.");
//         return {
//         error: true,
//         message: "Source choice alone is insufficient for query. Please select at least one additional facet.",
//         rows: []
//         };
//   }

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 5000);

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
      relationship: b.relationship?.value ?? '',
      occupation: b.occupation?.value ?? '',
      gender: b.gender?.value ?? '',
      source: b.source?.value ?? '',
      type: b.type?.value ?? '',
      stmt: b.stmt?.value ?? '',
      label_en: b.label_en?.value ?? '',
      label_syr: b.label_syr?.value ?? '',
    }));
  } catch (err) {
    clearTimeout(timeoutId);
    if (err.name === 'AbortError') {
      console.error("Query timed out after 5 seconds");
    } else {
      console.error("Failed to fetch factoids:", err);
    }
    return [];
  }
}
