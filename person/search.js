export const SPARQL_ENDPOINT = "https://sparql.vanderbilt.edu/sparql";


export function buildMultiFilterQuery(state) {
 
  const selectVars = new Set([]);
  const blocks = [];
    // Name filter
  if (state.persons && state.persons.length > 0) {
    blocks.push(`
      VALUES ?person { ${Array.from(state.persons).map(uri => `<${uri}>`).join(' ')} }
    `);
  }

  // Event Keyword filter // Add event participant//works
  if (state.selectedEventKeywords.size > 0) {
    blocks.push(`
        ?event swdt:event-participant ?person .
        ?event sp:event-keyword/sps:event-keyword ?eventKeyword .
      VALUES ?eventKeyword { ${Array.from(state.selectedEventKeywords).map(uri => `<${uri}>`).join(' ')} }
    `);
  }

  // Relationship filter//works
  if (state.selectedRelationshipKeywords.size > 0) {
    blocks.push(`
      ?person ?relationship ?statementNode .
      VALUES ?relationship { ${Array.from(state.selectedRelationshipKeywords).map(uri => `<${uri.replace('/taxonomy/', '/prop/')}>`).join(' ')} }
    `);
  }
    // Occupation filter
  if (state.selectedOccupationKeywords.size > 0) {
    blocks.push(`
      ?person swdt:occupation ?occupation .
      VALUES ?occupation { ${Array.from(state.selectedOccupationKeywords).map(uri => `<${uri}>`).join(' ')} }
    `);
  }
// <http://syriaca.org/person/2737>
//         swdt:occupation  <http://syriaca.org/taxonomy/chamberlains>;

  // Ethnicity filter//works
//   if (state.selectedEthnicityKeywords.size > 0) {
//     blocks.push(`
//       ?person swdt:ethnic-label ?ethnicity .
//       ?person sp:ethnic-label ?statementNode .
//       VALUES ?ethnicity { ${Array.from(state.selectedEthnicityKeywords).map(uri => `<${uri}>`).join(' ')} }
//     `);
//     selectVars.add('?ethnicity');
//   }

  // Gender filter//working
  if (state.selectedGenderKeywords.size > 0) {
    blocks.push(`
      ?person swdt:gender ?gender .
      VALUES ?gender { ${Array.from(state.selectedGenderKeywords).map(uri => `<${uri}>`).join(' ')} }
    `);
  }

  // Place filter//working
if (state.selectedPlaceKeywords.size > 0) {
  const placeValues = Array.from(state.selectedPlaceKeywords)
    .map(uri => `<${uri}>`)
    .join(' ');

  blocks.push(`
    VALUES ?place { ${placeValues} }
    {
    { ?person swdt:birth-place  ?place . }
    UNION
    { ?person swdt:death-place  ?place . }
    UNION
    { ?person swdt:residence    ?place . }
    UNION
    {
        ?event  swdt:event-place       ?place ;
                swdt:event-participant ?person .
    }
    }
  `);

  selectVars.add('(GROUP_CONCAT(DISTINCT STR(?place); SEPARATOR=", ") AS ?places)');
}
      // Source filter
  if (state.selectedSourceKeywords.size > 0 && state.selectedSourceKeywords.size < 3) {
    blocks.push(`
    
      ?statementNode spr:reference-URL ?factoid .
      ?factoid spr:part-of-series ?source .
    
      VALUES ?source { ${Array.from(state.selectedSourceKeywords).map(uri => `<${uri}>`).join(' ')} }
      ?person ?p ?statementNode .  
    `);
  }

  // Uncertainty filter
//   let uncertaintyBlock = ''; // Declare in outer scope

// if (state.uncertainty && state.uncertainty.trim() !== '') {
//   const levels = state.uncertainty
//     .split(',')
//     .map(level => level.trim().toLowerCase())
//     .filter(Boolean); // remove empty strings

//   if (levels.length > 0) {
//     const filters = levels.map(lvl => `"${lvl}"`).join(', ');
//     uncertaintyBlock = `
//       FILTER NOT EXISTS {
//         ?factoid spq:certainty ?level .
//         FILTER(LCASE(STR(?level)) IN (${filters}))
//       }`;
//   }
// }

const graphBlock = blocks.join('\n'); 

  // Final SPARQL query
  return `
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX schema: <http://schema.org/>
PREFIX spr: <http://syriaca.org/prop/reference/>
PREFIX swdt: <http://syriaca.org/prop/direct/>
PREFIX sp: <http://syriaca.org/prop/>
PREFIX sps: <http://syriaca.org/prop/statement/>
PREFIX spq: <http://syriaca.org/prop/qualifier/>

SELECT DISTINCT
  ?person
  ?label_en
  ?label_syr
  (GROUP_CONCAT(DISTINCT ?desc_en; SEPARATOR=" ") AS ?description)
  ${Array.from(selectVars).join(' ')}
WHERE {
  {
    SELECT DISTINCT ?person WHERE {
      GRAPH <https://spear-prosop.org> {
        ${graphBlock}
      }
      FILTER isIRI(?person)
    }
  }

  GRAPH <http://syriaca.org/persons#graph> {
    OPTIONAL { ?person rdfs:label ?label_en_ FILTER(LANGMATCHES(LANG(?label_en_), "en")) }
    OPTIONAL { ?person rdfs:label ?label_syr_ FILTER(LANGMATCHES(LANG(?label_syr_), "syr")) }
    OPTIONAL { ?person schema:description ?desc_en }
  }

  BIND(COALESCE(?label_en_, STRAFTER(STR(?person), "/person/")) AS ?label_en)
  BIND(?label_syr_ AS ?label_syr)
}
GROUP BY ?person ?label_en ?label_syr
ORDER BY ?label_en
`;
}


export async function fetchData(state) {
  const query = buildMultiFilterQuery(state);
  console.log("Build Person MultiFilterQuery with state:", state);
  console.log('Fetching persons with multi-type query:', query);
  query.split('\n').forEach((line,i)=>console.log(String(i+1).padStart(3,' '), line));

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
      occupation: b.occupation?.value ?? '',
      gender: b.gender?.value ?? '',
      place: b.place?.value ?? '',
      field: b.field?.value ?? '',
      source: b.source?.value ?? '',
      type: b.type?.value ?? '',
      stmt: b.stmt?.value ?? '',
      label_en: b.label_en?.value ?? '',
      label_syr: b.label_syr?.value ?? '',

    }));
  } catch (err) {
    console.error("Failed to fetch factoids:", err);
    return [];
  }
}
