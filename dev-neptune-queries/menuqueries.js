export const getEventKeywords = () => `
  PREFIX swdt: <http://syriaca.org/prop/direct/>

  SELECT DISTINCT ?keyword
  FROM <https://spear-prosop.org>
  WHERE {
    ?event swdt:event-keyword ?keyword .
  }
  ORDER BY ?keyword
`;

export const getEthnicityOptions = () => `
  PREFIX swdt: <http://syriaca.org/prop/direct/>

  SELECT DISTINCT ?ethnicity
  FROM <https://spear-prosop.org>
  WHERE {
    ?person swdt:ethnic-label ?ethnicity .
  }
  ORDER BY ?ethnicity
`;
export const SPARQL_ENDPOINT = "https://sparql.vanderbilt.edu/sparql";

export const getPlaceOptions = () => `
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

// Generic loader for any dropdown
export async function populateDropdown(query, dropdownId, labelField = "label", valueField = "value") {
  try {
    const res = await fetch(`${SPARQL_ENDPOINT}?query=${encodeURIComponent(query)}`, {
      headers: { Accept: 'application/sparql-results+json' }
    });
    const data = await res.json();
    const select = document.getElementById(dropdownId);
    select.innerHTML = ''; // Clear existing options

    data.results.bindings.forEach(binding => {
      const option = document.createElement("option");
      const label = binding[labelField]?.value || binding[valueField].value;
      option.value = binding[valueField].value;
      option.textContent = label;
      select.appendChild(option);
    });
  } catch (err) {
    console.error("Dropdown load failed:", err);
  }
}
// Load related people for a selected value
export async function fetchPeopleRelatedToKeyword(uri, relation) {
  const keywordQueryMap = {
    event: `
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX schema: <http://schema.org/>
      PREFIX swdt: <http://syriaca.org/prop/direct/>
      
      SELECT DISTINCT
        (STR(?p) AS ?person)
        (STR(?label_en) AS ?label)
        (STR(?desc) AS ?description)
        (STRAFTER(STR(?sex), "/taxonomy/") AS ?gender)
      FROM <http://syriaca.org/persons#graph>
      FROM NAMED <https://spear-prosop.org>
      WHERE {
        ?p rdfs:label ?label_en . 
        FILTER(LANG(?label_en) = "en")
        ?p schema:description ?desc
        OPTIONAL { ?p swdt:gender  ?sex }
        {
          GRAPH <https://spear-prosop.org> {
              ?event swdt:event-keyword <${uri}> ;
                     swdt:event-participant ?p .
          }
        }
      }
      ORDER BY ?label_en
    `,
    ethnicity: `
      PREFIX swdt: <http://syriaca.org/prop/direct/>
      SELECT DISTINCT ?person
      FROM <https://spear-prosop.org>
      WHERE {
        ?person swdt:ethnic-label <${uri}> .
      }
      ORDER BY ?person
    `,
    place: `
      PREFIX swdt: <http://syriaca.org/prop/direct/>
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX schema: <http://schema.org/>
      SELECT DISTINCT         
        (STR(?p) AS ?person)
        (STR(?label_en) AS ?label)
        (STR(?desc) AS ?description)
        (STRAFTER(STR(?sex), "/taxonomy/") AS ?gender)
      FROM <http://syriaca.org/persons#graph>
      FROM NAMED <https://spear-prosop.org>
      WHERE {
          ?p rdfs:label ?label_en . 
          FILTER(LANG(?label_en) = "en")
          ?p schema:description ?desc
          OPTIONAL { ?p swdt:gender  ?sex }
        {
          GRAPH <https://spear-prosop.org> {
        { ?person swdt:residence <${uri}> } UNION
         { ?person swdt:citizenship <${uri}> } UNION
        { ?person swdt:birth-place <${uri}> } UNION
        { ?person swdt:death-place <${uri}> } UNION
        {
          ?event swdt:event-place <${uri}> ;
                 swdt:event-participant ?person .
        }
        }
      } 
      ORDER BY ?person
    `
  };

  const query = keywordQueryMap[relation];
  if (!query) return [];

  const res = await fetch(`${SPARQL_ENDPOINT}?query=${encodeURIComponent(query)}`, {
    headers: { Accept: 'application/sparql-results+json' }
  });
  const data = await res.json();
  return data.results.bindings.map(b => ({
    person: b.person.value,
    label: b.label?.value || "",
    description: b.description?.value || "",
    gender: b.gender?.value || ""
  }));
}


