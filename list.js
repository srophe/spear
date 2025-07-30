export async function renderKeywordPrettyList(query, listId, labelField = "label", valueField = "value", onSelect) {
  const listEl = document.getElementById(listId);
  const container = document.getElementById(listId); // Make scroll listener flexible
  const pageSize = 50;
  let offset = 0;
  let loading = false;
  let endReached = false;
  const SPARQL_ENDPOINT = "https://sparql.vanderbilt.edu/sparql";

  function prettify(uri) {
    const raw = uri.split('/').pop();
    return raw
      .replace(/[-_]/g, ' ')
      .replace(/\b\w/g, c => c.toUpperCase());
  }

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

      offset += pageSize;
    } catch (err) {
      console.error("Failed to load keywords:", err);
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
