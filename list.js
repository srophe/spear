import { fetchWithCache } from './menu.js';

const SPARQL_ENDPOINT = "https://sparql.vanderbilt.edu/sparql";

/**
 * Renders a keyword list from a SPARQL query, prettifying the URI tail for display.
 *
 * Results are fetched once (all pages), cached in localStorage keyed on the target
 * list element id, and rendered in a single pass. This replaces the previous
 * scroll-paginated model that issued a fresh Neptune query on every scroll and
 * never cached, which added avoidable load to the endpoint.
 *
 * @param {string} query - SPARQL query to fetch keywords (without OFFSET/LIMIT)
 * @param {string} listId - ID of the <ul> element to populate
 * @param {string} containerId - ID of the scroll container (kept for signature compatibility)
 * @param {string} labelField - Field to use for display label (unused; label is derived from the URI)
 * @param {string} valueField - Field to use for value (default "value")
 * @param {function} onSelect - Callback invoked with the selected URI
 * @returns {Promise<void>}
 */
export async function renderKeywordPrettyList(query, listId, containerId, labelField = "label", valueField = "value", onSelect) {
  const listEl = document.getElementById(listId);
  if (!listEl) return;

  const pageSize = 50;
  const cacheKey = `keywordPrettyV1_${listId}`;

  function prettify(uri) {
    const raw = uri.split('/').pop();
    return raw
      .replace(/[-_]/g, ' ')
      .replace(/\b\w/g, c => c.toUpperCase());
  }

  // Fetch every page once and return the combined bindings. This is what gets cached,
  // so subsequent loads (and scrolling) never hit Neptune again.
  async function fetchAllBindings() {
    const all = [];
    let offset = 0;

    while (true) {
      const pagedQuery = `${query}\nOFFSET ${offset}\nLIMIT ${pageSize}`;
      const res = await fetch(`${SPARQL_ENDPOINT}?query=${encodeURIComponent(pagedQuery)}`, {
        headers: { Accept: 'application/sparql-results+json' }
      });
      const data = await res.json();
      const results = data.results?.bindings ?? [];

      if (results.length === 0) break;

      all.push(...results);
      offset += pageSize;

      // Last page reached when fewer than a full page came back.
      if (results.length < pageSize) break;
    }

    return all;
  }

  try {
    const bindings = await fetchWithCache(cacheKey, fetchAllBindings);
    console.log("Keyword pretty list bindings:", listId, bindings.length);

    bindings.forEach(binding => {
      const uri = binding[valueField]?.value || "";
      const prettyLabel = prettify(uri);

      const li = document.createElement("li");
      li.style.marginBottom = "0.75rem";
      li.style.fontFamily = "Georgia, serif";
      li.style.fontSize = ".78rem";
      li.style.cursor = "pointer";
      li.style.padding = "0.5rem";
      li.style.borderBottom = "1px solid #ddd";
      li.textContent = prettyLabel;

      li.addEventListener("click", () => {
        onSelect(uri);
      });

      listEl.appendChild(li);
    });
  } catch (err) {
    console.error("Failed to load keywords:", err);
  }
}
