export const SPARQL_ENDPOINT = "https://sparql.vanderbilt.edu/sparql";

export const getAllFactoids = () => `
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX spr: <http://syriaca.org/prop/reference/>
PREFIX schema: <http://schema.org/>

SELECT DISTINCT ?factoid ?description
FROM <https://spear-prosop.org>
WHERE {
  
    ?statementNode spr:reference-URL ?factoid .
    OPTIONAL {
      ?factoid schema:description ?description .
    }
}
ORDER BY ?factoid
`;

export const getAllPersonFactoids = () => `
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
export const getFactoidsForEthnicity = (ethnicityUri) => `
  PREFIX swdt: <http://syriaca.org/prop/direct/>
  PREFIX schema: <http://schema.org/>
  PREFIX sp: <http://syriaca.org/prop/>
  PREFIX sps: <http://syriaca.org/schema/>
  PREFIX spr: <http://syriaca.org/prop/reference/>
  
  SELECT DISTINCT ?factoid ?description
  FROM <https://spear-prosop.org>
  WHERE {
    ?person swdt:ethnic-label <${ethnicityUri}> .
    ?person sp:ethnic-label ?statementNode .
    ?statementNode spr:reference-URL ?factoid .
    ?factoid schema:description ?description .
  }
`;

export const getFactoidsForPlace = (placeUri) => `
  PREFIX swdt: <http://syriaca.org/prop/direct/>
  PREFIX spr: <http://syriaca.org/prop/reference/>
  PREFIX schema: <http://schema.org/>
  PREFIX sp: <http://syriaca.org/prop/>
  PREFIX sps: <http://syriaca.org/schema/>

  SELECT DISTINCT ?factoid ?description
  FROM <https://spear-prosop.org>
  WHERE {
    {
      ?person swdt:birth-place <${placeUri}> ;
              sp:birth-place ?statementNode .
    } UNION {
      ?person swdt:death-place <${placeUri}> ;
              sp:death-place ?statementNode .
    } UNION {
      ?person swdt:residence <${placeUri}> ;
              sp:residence ?statementNode .
    } UNION {
      ?event swdt:event-place <${placeUri}> ;
             sp:event-place ?statementNode .
    }
    ?statementNode spr:reference-URL ?factoid .
    ?factoid schema:description ?description .
  }
`;

export const getFactoidsForFieldOfStudy = (fieldUri) => `
  PREFIX swdt: <http://syriaca.org/prop/direct/>
  PREFIX spr: <http://syriaca.org/prop/reference/>
  PREFIX schema: <http://schema.org/>
  PREFIX sp: <http://syriaca.org/prop/>
  PREFIX sps: <http://syriaca.org/schema/>

  SELECT DISTINCT ?factoid ?description
  FROM <https://spear-prosop.org>
  WHERE {
    ?statementNode sps:education <${fieldUri}> ;
       spr:reference-URL ?factoid .
    ?factoid schema:description ?description .
  }
`;
export const getFactoidsRelatedToKeyword = (eventKeywordUri) => `
PREFIX spr: <http://syriaca.org/prop/reference/>
PREFIX schema: <http://schema.org/>
PREFIX sps: <http://syriaca.org/prop/statement/>

  SELECT DISTINCT ?factoid ?description
  FROM <https://spear-prosop.org>
  WHERE {
    ?statementNode sps:event-keyword <${eventKeywordUri}> ;
                   spr:reference-URL ?factoid .
    OPTIONAL { ?factoid schema:description ?description . }
  }
`;

export async function fetchFactoidsByType(uri, type) {
  let query;

  switch (type) {
    case "event":
      query = getFactoidsRelatedToKeyword(uri);
      break;
    case "ethnicity":
      query = getFactoidsForEthnicity(uri);
      break;
    case "place":
      query = getFactoidsForPlace(uri);
      break;
    case "fieldOfStudy":
      console.log("Field of Study URI:", uri);
      query = getFactoidsForFieldOfStudy(uri);
      break;
    default:
      console.warn(`Unsupported type: ${type}`);
      return [];
  }

  console.log("SPARQL query being sent:", query);

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

    return data.results.bindings.map(b => ({
      uri: b.factoid?.value ?? '',
      description: b.description?.value ?? ''
    }));
  } catch (err) {
    console.error("Failed to fetch factoids:", err);
    return [];
  }
}

