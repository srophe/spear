
export const SPARQL_ENDPOINT = "https://sparql.vanderbilt.edu/sparql";


// Event Factoids
function buildEventFactoidQuery(state) {
 
  const selectVars = new Set(['?factoid', '?description','?source']);
  const blocks = [];

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
  if (state.events.length > 0) {
    console.log("Adding event URIs to SPARQL query:", state.events);
    blocks.push(`
      ?statementNode spr:reference-URL ?factoid .
      VALUES ?factoid { ${Array.from(state.events).map(uri => `<${uri}>`).join(' ')} }
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
  // Event Keyword filter // Add event participant?
  if (state.selectedEventKeywords.size > 0) {
    blocks.push(`
      ?statementNode sps:event-keyword ?eventKeyword .
      ?statementNode spr:reference-URL ?factoid .
      VALUES ?eventKeyword { ${Array.from(state.selectedEventKeywords).map(uri => `<${uri}>`).join(' ')} }
    `);
    selectVars.add('?eventKeyword');
  } else {
    blocks.push(`
      ?event sp:event-keyword/spr:reference-URL ?factoid .
      `)
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

  OPTIONAL { ?factoid schema:description ?description . }
  
}
ORDER BY ?factoid
LIMIT 20000
`;
}


export async function fetchEventFactoids(state) {
 const query = buildEventFactoidQuery(state);
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
      eventKeyword: b.eventKeyword?.value ?? '',
      relationship: b.relationship?.value ?? '',
      ethnicity: b.ethnicity?.value ?? '',
      gender: b.gender?.value ?? '',
      place: b.place?.value ?? '',
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


// This query gets all people associated with event factoids, along with their names, gender, occupations, and event keywords. The results are the event/person.json file.
export const getAllPeopleNamesGenderOccupationEventFactoid = () =>
 `
  PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX schema: <http://schema.org/>
PREFIX swdt: <http://syriaca.org/prop/direct/>
PREFIX spr: <http://syriaca.org/prop/reference/>
PREFIX sps: <http://syriaca.org/prop/statement/>


SELECT DISTINCT ?factoid ?person ?label_en ?description ?gender (STRAFTER(STR(?occupation), "/persons/") AS ?occupation) (STRAFTER(STR(?eventKeyword), "/taxonomy/") AS ?eventKeyword)
WHERE {
  GRAPH <https://spear-prosop.org> {
    ?statementNode sps:event-participant ?person ;
                   spr:reference-URL ?factoid .
    OPTIONAL { ?person swdt:occupation ?occupation }
    OPTIONAL { ?statementNode sps:event-keyword ?eventKeyword }


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
  ` ;

//   <http://syriaca.org/person/2652>
//         swdt:occupation  <http://syriaca.org/taxonomy/monks>;
//         sp:occupation    swds:3128-3Instd0e2781 .

// swds:3128-3Instd0e2781
//         sps:occupation     <http://syriaca.org/taxonomy/monks>;
//         spr:reference-URL  <https://spear-prosop.org/3128-3> .

// swd:event3128-2  swdt:event-keyword  <http://syriaca.org/taxonomy/letters>;
//         sp:event-keyword    swds:3128-2Inst1d0e2371 .

// swds:3128-2Inst1d0e2371
//         sps:event-keyword  <http://syriaca.org/taxonomy/letters>;
//         spr:reference-URL  <https://spear-prosop.org/3128-2> .

// curl -G "https://sparql.vanderbilt.edu/sparql" \
//   --data-urlencode 'query=
//   PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
// PREFIX schema: <http://schema.org/>
// PREFIX swdt: <http://syriaca.org/prop/direct/>
// PREFIX spr: <http://syriaca.org/prop/reference/>
// PREFIX sps: <http://syriaca.org/prop/statement/>


// SELECT DISTINCT   
//   ?person
//   (SAMPLE(?label_en) AS ?label)
//   (SAMPLE(?description) AS ?desc)
//   (SAMPLE(?gender) AS ?g)
//   (GROUP_CONCAT(DISTINCT STRAFTER(STR(?o), "/taxonomy/"); SEPARATOR=", ") AS ?occupations)
//   (GROUP_CONCAT(DISTINCT STRAFTER(STR(?keyword), "/taxonomy/"); SEPARATOR=", ") AS ?eventKeywords)
//   (GROUP_CONCAT(DISTINCT STR(?factoid); SEPARATOR=", ") AS ?factoids)
// WHERE {
//   GRAPH <https://spear-prosop.org> {
//     ?statementNode sps:event-participant ?person ;
//                    spr:reference-URL ?factoid  ;

//     OPTIONAL {    ?s sps:event-keyword  ?keyword ;
//        spr:reference-URL  ?factoid .}

//     OPTIONAL { ?person swdt:occupation ?o .}

//   }
//   GRAPH <http://syriaca.org/persons#graph> {
//     ?person rdfs:label ?label_en .
//     FILTER(LANG(?label_en) = "en")
//     OPTIONAL {?person schema:description ?description}
//     OPTIONAL  { ?person swdt:gender  ?gender }
//   }
// }
// GROUP BY ?person
// ORDER BY ?label
//   ' \
// -H "Accept: application/sparql-results+json"

// curl -G "https://sparql.vanderbilt.edu/sparql" \
//   --data-urlencode 'query=
//   PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
// PREFIX schema: <http://schema.org/>
// PREFIX swdt: <http://syriaca.org/prop/direct/>
// PREFIX spr: <http://syriaca.org/prop/reference/>
// PREFIX sps: <http://syriaca.org/prop/statement/>


// SELECT DISTINCT ?factoid ?person ?label_en ?description (STRAFTER(STR(?gender), "/taxonomy/") AS ?sex) (STRAFTER(STR(?o), "/taxonomy/") AS ?occupation) (STRAFTER(STR(?keyword), "/taxonomy/") AS ?eventKeyword)
// WHERE {
//   GRAPH <https://spear-prosop.org> {
//     ?statementNode sps:event-participant ?person ;
//                    spr:reference-URL ?factoid  ;
//     OPTIONAL { ?person swdt:occupation ?o .}

//   }
//   GRAPH <http://syriaca.org/persons#graph> {
//     ?person rdfs:label ?label_en .
//     FILTER(LANG(?label_en) = "en")
//     OPTIONAL {?person schema:description ?description}
//     OPTIONAL  { ?person swdt:gender  ?gender }
   
//   }
// }
// ORDER BY ?label_en
//   ' \
// -H "Accept: application/sparql-results+json"