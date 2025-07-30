export const SPARQL_ENDPOINT = "https://sparql.vanderbilt.edu/sparql";

// Add filter menu options

export const getEventKeywords = () => `
  PREFIX swdt: <http://syriaca.org/prop/direct/>
  SELECT DISTINCT ?keyword
  FROM <https://spear-prosop.org>
  WHERE {
    ?event swdt:event-keyword ?keyword .
  }
  ORDER BY ?keyword
`;

export const getRelationshipOptions = () => `
  PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
  SELECT DISTINCT ?collectionType ?subject ?label
  WHERE {
    VALUES (?collection ?collectionType) {
      (<http://syriaca.org/taxonomy/directed-relations-collection> "directed")
      (<http://syriaca.org/taxonomy/mutual-relations-collection> "mutual")
    }
    ?collection skos:member ?subject .
    ?subject skos:prefLabel ?label .
  }
  ORDER BY ?collectionType ?label
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

export const getPlaceOptions = () => `
  PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
  PREFIX swdt: <http://syriaca.org/prop/direct/>
  SELECT DISTINCT ?place ?label
  FROM <http://syriaca.org/geo#graph>
  FROM <https://spear-prosop.org>
  WHERE {
    {
      ?person swdt:residence ?place .
    } UNION {
      ?person swdt:birth-place ?place .
    } UNION {
      ?person swdt:death-place ?place .
    } UNION {
      ?event swdt:event-place ?place .
    } UNION {
      ?person swdt:citizenship ?place .
    }
    ?place rdfs:label ?label .
    FILTER(LANG(?label) = "en")
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


/**
 * Populates a <select> element with options from a SPARQL query above
 */
export async function populateDropdown(query, dropdownId, labelField = "label", valueField = "value") {
  try {
    const res = await fetch(`${SPARQL_ENDPOINT}?query=${encodeURIComponent(query)}`, {
      headers: { Accept: 'application/sparql-results+json' }
    });
    const data = await res.json();
    const select = document.getElementById(dropdownId);
    if (!select) return;

    select.innerHTML = ''; // Clear existing options

    // Add a default "All" option
    const allOpt = document.createElement('option');
    allOpt.value = '';
    allOpt.textContent = 'All';
    select.appendChild(allOpt);

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

/**
 * Renders a scrollable <ul> list from a SPARQL query for keywords, used by relationships menu, paginated by 50
 * Calls `onSelect(uri)` when a user clicks an item, also see `renderKeywordPrettyList` for a more generic version
 * @param {string} query - SPARQL query to fetch keywords
 * @param {string} itemsId - ID of the <ul> element to populate
 * @param {string} listId - ID of the container for scroll listener
 * @param {string} labelField - Field to use for display label (default "label")
 * @param {string} valueField - Field to use for value (default "value")
 * @param {function} onSelect - Callback function to call with the selected URI
 * @returns {Promise<void>}
 */
export async function renderKeywordList(query, itemsId, listId, labelField = "label", valueField = "value", onSelect) {
  const listEl = document.getElementById(itemsId);
  const container = document.getElementById(listId);
  if (!listEl || !container) return;

  const pageSize = 50;
  let offset = 0;
  let loading = false;
  let endReached = false;

  async function loadNextPage() {
    if (loading || endReached) return;
    loading = true;

    const pagedQuery = `${query}\nOFFSET ${offset}\nLIMIT ${pageSize}`;
    try {
      const res = await fetch(`${SPARQL_ENDPOINT}?query=${encodeURIComponent(pagedQuery)}`, {
        headers: { Accept: 'application/sparql-results+json' }
      });
      const data = await res.json();
      const results = data.results.bindings;

      if (results.length === 0) {
        endReached = true;
        return;
      }

      results.forEach(binding => {
        const uri = binding[valueField]?.value || "";
        const label = binding[labelField]?.value || uri;

        const li = document.createElement("li");
        li.textContent = label;
        li.style.marginBottom = "0.5rem";
        li.style.fontFamily = "Georgia, serif";
        li.style.fontSize = ".78rem";
        li.style.cursor = "pointer";
        li.style.padding = "0.4rem";
        li.style.borderBottom = "1px solid #eee";

        li.addEventListener("click", () => {
          onSelect(uri);
        });

        listEl.appendChild(li);
      });

      offset += pageSize;
    } catch (err) {
      console.error("Failed to load keyword list:", err);
    } finally {
      loading = false;
    }
  }

  loadNextPage();

  container.addEventListener("scroll", () => {
    const threshold = container.scrollHeight - container.clientHeight - 50;
    if (container.scrollTop >= threshold) {
      loadNextPage();
    }
  });
}
