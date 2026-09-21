# SPEAR — Technical Documentation

Technical reference for the SPEAR (Syriaca Prosopographical Event Analysis and
Research) web application. This document describes the actual implementation as
it exists in the codebase: architecture, data flow, SPARQL query construction,
caching, the Neptune/API Gateway backend, and operational guidance.

> **Scope note.** This document reflects the code in this repository. Where the
> top-level `README.md` disagrees with the code, the code is authoritative and
> the discrepancies are called out in [Appendix A](#appendix-a--readme-discrepancies).

---

## 1. High-level architecture

SPEAR is a **static, framework-free single-page application** written in vanilla
ES modules. There is no build step, bundler, or `package.json`. Files are served
as-is over HTTP and executed directly by the browser.

```
Browser (ES modules)
  │
  ├── browse.html / dev.html         ← entry HTML, boots the app
  │
  ├── mode.js                        ← mode router / mount lifecycle
  │
  ├── modes/{person,event,relation}.js   ← per-mode UI + fetch + render
  │
  ├── {person,event,relation}/search.js  ← SPARQL query builders + fetchers
  │
  ├── menu.js  +  list.js            ← facet menu loading + localStorage cache
  │
  ├── filter.js                      ← shared filter state + URL sync helpers
  │
  └── utils/{cleanUi.js,url.js}      ← display + URL helpers
        │
        ▼
  SPARQL HTTP endpoint  (https://sparql.vanderbilt.edu/sparql)
        │
        ▼
  AWS API Gateway ──(VPC Link → NLB)──►  Amazon Neptune cluster
                                          (writer + reader, db.t3.medium)
```

**Data strategy:** the app is a hybrid. Default and "simple" views are served
from bundled JSON snapshots; only complex/live facet combinations issue live
SPARQL queries to Neptune. This is a deliberate load-reduction measure.

---

## 2. Entry points and boot sequence

### HTML entry points
- **`browse.html`** — production entry.
- **`dev.html`** — development entry (same wiring; used for local testing).

Both end with an ES module script that imports the mode router and registers the
three modes:

```html
<script type="module">
  import { boot }   from './mode.js';
  import personMode from './modes/person.js';
  import eventMode  from './modes/event.js';
  import relationMode from './modes/relation.js';

  boot({
    registry: { person: personMode, event: eventMode, relation: relationMode },
    defaultType: 'person'
  });
</script>
```

### `mode.js` — the router (`boot`)
`boot({ registry, defaultType })` owns the application lifecycle:

- Holds shared `state = { type, filters }`.
- Reads/writes the active mode from the `?type=` URL parameter
  (`readTypeFromUrl` / `writeTypeToUrl`), enabling shareable, back-button-aware
  URLs via `history.pushState` / `popstate`.
- `togglePanels(type)` shows/hides the `#personResults` / `#eventResults` /
  `#relationResults` panels.
- `wireSidebarChrome` handles collapse toggles and dispatches a `clearSection`
  custom event that the active mode listens for.
- `mount(type)` renders the mode's sidebar (`mode.sidebar(state)`), wires it
  (`mode.bind(...)`), then calls `runSearch()`.
- `runSearch()` calls `mode.fetch(state)` → `mode.render(rows, state)`, with
  special handling: a falsy return aborts silently, and a `{ error, message }`
  return renders a user-facing facet error instead of results.

### Mode contract
Each mode module (`modes/*.js`) exports a default object implementing:

| Method | Purpose |
|---|---|
| `sidebar(state)` | returns the sidebar HTML string for the mode |
| `bind(root, state, runSearch)` | wires event listeners, loads facet menus, initializes state |
| `fetch(state)` | returns result rows (from JSON and/or live SPARQL) |
| `render(rows, state)` | renders rows into the mode's results panel |

---

## 3. Search modes

There are three modes, each backed by its own `search.js`.

### 3.1 Person mode (`modes/person.js` + `person/search.js`)
- **Result shape:** persons (deduplicated), enriched with labels + description.
- **JSON-first:** default view and name-only searches are served from
  `person/person.json`. Live SPARQL (`fetchData`) is only called for complex
  facet combinations.
- **Query builder:** `buildMultiFilterQuery(state)` resolves person identity in
  an inner subquery inside `GRAPH <https://spear-prosop.org>`, then enriches
  with labels/description from `GRAPH <http://syriaca.org/persons#graph>`.
  This follows the "resolve person first, then enrich" pattern documented in
  `person/README.md`.
- **UI fields consumed by `render`:** `person`, `label_en`, `label_syr`,
  `description` (only these four).

### 3.2 Event mode (`modes/event.js` + `event/search.js`)
- **Result shape:** event factoids.
- **JSON pre-filtering:** name/gender/occupation filters are applied
  client-side against `event/person.json`, but the fetch path **always** ends by
  calling the live `fetchEventFactoids(...)`.
- **Query builder:** `buildEventFactoidQuery(state)`. With no facets selected it
  emits the default query across all three sources
  (`?event sp:event-keyword/spr:reference-URL ?factoid`) with `LIMIT 20000`.
- **UI fields consumed by `render`:** `uri` (factoid), `description`, `source`
  (mapped to a label), `eventKeyword`.

### 3.3 Relation mode (`modes/relation.js` + `relation/search.js`)
- **Result shape:** relationship factoids.
- **JSON-first:** default view + source/name/gender/occupation combinations read
  from `relation/filtered_relation_factoids.json` /
  `relation/all_person_relation_factoids.json` with client-side filtering.
  Live SPARQL (`fetchData` / `fetchRelationFactoids`) is the fallback.
- **Query builder:** `buildRelationFactoidQuery(state)` anchors on
  `?statementNode spr:reference-URL ?factoid` and joins
  `?factoid spr:part-of-series ?source` (defaulting to the three known sources).
- **UI fields consumed by `render`:** `uri` (factoid), `description`, `source`,
  `relationship`.

> **Dead code:** the top-level `search.js` (which contains two same-named
> `buildMultiFilterQuery` functions and `fetchFactoidsByMultiType` /
> `fetchFactoidsWithFilters`) is **not imported anywhere** — the only reference
> in `filter.js` is commented out. It does not run. Treat it as removable.

---

## 4. Filter state and URL synchronization (`filter.js`)

- Filter state is a set of `Set`s, one per facet
  (`selectedEventKeywords`, `selectedRelationshipKeywords`,
  `selectedEthnicityKeywords`, `selectedGenderKeywords`,
  `selectedPlaceKeywords`, `selectedOccupationKeywords`,
  `selectedSourceKeywords`), plus a `name` string and `uncertainty`.
- `FILTER_MAP` maps each facet to its state key and URL parameter key.
- `stateToUrlParams(state)` serializes facet selections into
  `URLSearchParams`; the mode files call a `writeFilterParamsToUrl(state)` on
  each change so the URL is always shareable.
- Source label display is handled by a small `sourceLabels` lookup +
  `getSourceLabel(uri)` (falls back to `prettifyUri`).

### Source facets
The three sources are:

| URI | Label |
|---|---|
| `https://spear-prosop.org/letters-severus` | Letters of Severus of Antioch |
| `https://spear-prosop.org/lives-eastern-saints` | Lives of the Eastern Saints |
| `https://spear-prosop.org/chronicle-edessa` | Chronicle of Edessa |

Selecting all three is treated as "no source filter"; selecting a strict subset
(`size > 0 && size < 3`) applies a source constraint.

---

## 5. SPARQL data model

### Named graphs
| Graph | Contents |
|---|---|
| `https://spear-prosop.org` | factoids, event links, statement nodes, provenance |
| `http://syriaca.org/persons#graph` | multilingual labels (en/syr), descriptions |
| `http://syriaca.org/geo#graph` | place labels (used by the place menu) |

### Prefixes
| Prefix | Namespace | Role |
|---|---|---|
| `swdt:` | `http://syriaca.org/prop/direct/` | direct factoid triples |
| `sp:` | `http://syriaca.org/prop/` | statement-node predicates |
| `sps:` | `http://syriaca.org/prop/statement/` | statement-level values |
| `spr:` | `http://syriaca.org/prop/reference/` | provenance / reference URLs |
| `spq:` | `http://syriaca.org/prop/qualifier/` | qualifiers (e.g. certainty) |
| `schema:` | `http://schema.org/` | descriptions |
| `rdfs:` | `http://www.w3.org/2000/01/rdf-schema#` | labels |
| `skos:` | `http://www.w3.org/2004/02/skos/core#` | taxonomy collections |

### Query-construction conventions
- Facet blocks are built into an array and joined into the `WHERE` clause.
- Multi-value facets use `VALUES ?var { <uri> <uri> ... }`.
- Relationship facets rewrite taxonomy URIs to property URIs
  (`.replace('/taxonomy/', '/prop/')`) and bind a **variable predicate**
  (`?person ?relationship ?stmt`).
- Uncertainty is an **exclusion** filter:
  `FILTER NOT EXISTS { ?factoid spq:certainty ?level . FILTER(LCASE(STR(?level)) IN (...)) }`.
- Place facets are a 4-way `UNION` over birth-place / death-place / residence /
  event-place.
- `VALUES` should be placed **inside** `GRAPH` blocks — Neptune interprets them
  differently outside (see `person/README.md`).

### Known query-cost hotspots (optimization backlog)
These are documented so future work is grounded:
1. `LIMIT 20000` + global `ORDER BY ?factoid` forces full materialize + sort
   before limiting. Prefer server-side paging (small `LIMIT`+`OFFSET`, or
   keyset paging) and drop `ORDER BY` when the UI sorts client-side.
2. Always-on anchors (`?statementNode spr:reference-URL ?factoid` +
   `?factoid spr:part-of-series ?source`) full-scan when no selective facet is
   set. A "require ≥1 selective facet" guard (the commented-out
   `onlySourceSelected` checks) avoids the worst queries.
3. Variable-predicate relationship patterns defeat predicate indexing.
4. `FILTER(LANG(...))` / `LCASE(STR(...))` run post-match; prefer `LANGMATCHES`
   and direct value comparison.
5. Wide `SELECT DISTINCT` projections increase dedup cost — project only what
   `render` consumes.

---

## 6. Facet menus and caching

Facet menus are reference data (taxonomies, place lists). They are loaded by two
loaders and cached in `localStorage`.

### 6.1 `menu.js`
- **Query generators** (`getEventKeywords`, `getRelationshipOptions`,
  `getEthnicityOptions`, `getPlaceOptions`, `getOccupationOptions`,
  `getEducationFieldsOfStudy`) return SPARQL strings.
- **`populateDropdown(query, dropdownId, ...)`** — fills a `<select>`; cached via
  `fetchWithCache` under key `dropdown_<id>`.
- **`renderKeywordList(query, itemsId, listId, ...)`** — fills a scrollable
  `<ul>`; cached under key **`keywordListV2_<itemsId>`**.
  > The cache key is derived from the **element id**, not the query text. An
  > earlier version keyed on the first 20 chars of `btoa(query)`, which collided
  > across queries sharing a leading `PREFIX` (occupations, relationships,
  > fields-of-study), causing one list to overwrite another. The `V2` prefix
  > also bypasses stale collided entries left by the old version.
- **`fetchWithCache(key, fetchFn)`** — exported. 24h TTL in `localStorage`
  (`<key>` + `<key>_time`). Only writes on success.
- **`clearMenuCache()`** — purges all cache prefixes: `dropdown_`,
  `keywordList_` (legacy), `keywordListV2_`, `keywordPrettyV1_`,
  `eventFactoidsV1_`.

### 6.2 `list.js` — `renderKeywordPrettyList`
Drives the **event-concept** (`eventKeywordItems`) and **ethnicity**
(`ethnicityKeywordItems`) lists. It:
- Fetches **all pages once** (loops `OFFSET`/`LIMIT 50` until a short/empty page).
- Caches the combined bindings via `fetchWithCache` under
  **`keywordPrettyV1_<listId>`**.
- Renders in a single pass (no per-scroll Neptune queries).
- Derives display labels by prettifying the URI tail.

### 6.3 Event factoids cache (`event/search.js`)
`fetchEventFactoids` caches its **mapped result rows** via `fetchWithCache`,
keyed on a DJB2 hash of the full query text
(`eventFactoidsV1_<hash>` via `eventCacheKey(query)`). This caches the default
unfiltered event query and gives each distinct facet combination its own entry.
On a non-OK HTTP response it throws (so failures are not cached); the caller
still returns `[]`.

### Cache summary
| Data | Loader | Cache key prefix | Cached |
|---|---|---|---|
| `<select>` dropdowns | `populateDropdown` | `dropdown_` | ✅ |
| place / relationship / occupation lists | `renderKeywordList` | `keywordListV2_` | ✅ |
| event concepts / ethnicity | `renderKeywordPrettyList` | `keywordPrettyV1_` | ✅ |
| event factoid results | `fetchEventFactoids` | `eventFactoidsV1_` | ✅ |

**TTL:** 24h for all of the above. Menus are static reference data (safe).
Event factoid results are *result data* — if Neptune data is updated, cached
results can be up to 24h stale; call `clearMenuCache()` after a data refresh or
lower the TTL for that key if immediate freshness is required.

**localStorage limit:** ~5 MB per origin. Large `LIMIT 20000` result sets could
approach this; if many distinct large results accumulate, a `setItem` may throw
`QuotaExceededError`. Consider a best-effort write guard if this becomes an issue.

---

## 7. Backend: Neptune + API Gateway

### Topology
```
Client → API Gateway (stage) → VPC Link → Network Load Balancer → Neptune
```
- **Neptune cluster:** writer + reader instances, `db.t3.medium`, in a VPC.
- **API Gateway integration:** points at the Neptune **reader** instance
  endpoint over TCP/HTTPS 443. It is a **raw SPARQL passthrough** — there is no
  Lambda between API Gateway and Neptune.
- **Integration timeout:** 15000 ms (recommended; fail fast to release Neptune
  slots).

### Neptune configuration
- **`neptune_query_timeout`** (cluster parameter group): 25000 ms. Backstop that
  kills long queries server-side regardless of the client.
- Integration timeout (15s) intentionally sits below `neptune_query_timeout`
  (25s): API Gateway gives up first and frees the client, while Neptune retains
  a hard 25s backstop.

### API Gateway throttling
- **Stage throttling:** ~10 req/sec rate, 20 burst. This is the aggregate
  ceiling protecting Neptune; it is well above expected real load
  (~12 users × ~2 req/min ≈ 0.4 req/sec).
- Recommended additional layer: per-IP rate limiting via AWS WAF so one client
  cannot consume the whole stage budget.

### CPU / write-activity note
"Writer at ~10% CPU with no writers" is **normal baseline** on `db.t3.medium`
(background housekeeping + possibly reads). CPU is not a write indicator.
- To confirm writes: check CloudWatch **`VolumeWriteIOPs`** (≈0 means no writes).
- The writer can also serve reads; the **cluster endpoint** always resolves to
  the writer, so ensure clients/scripts target the **reader** endpoint.

### Security posture and recommendations
Because the endpoint is a public raw passthrough:
- **Block writes:** nothing structurally prevents `INSERT`/`DELETE`/`LOAD`/`DROP`
  from reaching Neptune if a request can hit a writer-capable endpoint. Confirm
  no API Gateway route targets the cluster/writer endpoint. Strongest fix: a
  Lambda proxy that allows only `SELECT`/`ASK`, caps `LIMIT`, and sets a
  per-query timeout — or a read-only IAM database-auth constraint on Neptune.
- **Keep Neptune private:** it should sit in private subnets, reachable only via
  the NLB/VPC Link, never publicly routable.
- **WAF:** attach rate-based rules + managed rule groups + request-size limits.
- **Caching:** API Gateway response caching / CloudFront in front further sheds
  load for near-static data.

### Observability
Alarm on:
- `MainRequestQueuePendingRequests` (queue depth; current alarm: `> 1` for one
  datapoint in 5 min).
- API Gateway 4xx/5xx and latency.
- Neptune `VolumeWriteIOPs`, `SPARQLRequestsPerSec`, CPU credit balance.

---

## 8. Local development

No build step. Serve the folder over HTTP (ES modules + `localStorage` do not
work under `file://`):

```bash
python3 -m http.server 8000
# then open:
#   http://localhost:8000/browse.html   (production entry)
#   http://localhost:8000/dev.html      (dev entry)
```

Alternatives: `npx serve`, or the VS Code "Live Server" extension.

### CORS
The SPARQL endpoint must allow the local origin
(`http://localhost:8000`). If it does not, browser fetches fail with a CORS
error even when the query is valid — this is an endpoint-config issue, not a
code bug.

### Verifying caching behavior
1. Open DevTools before loading the page.
2. **Network** (filter `sparql`): requests fire on first load, then should
   **not** re-fire on reload.
3. **Console:** `fetchWithCache` logs `[CACHE] Fetching new data for <key>`
   (cold) vs `[CACHE] Using cached data for <key>` (warm).
4. **Application → Local Storage:** confirm one key per data set, e.g.
   `keywordListV2_occupationKeywordItems`, `keywordPrettyV1_eventKeywordItems`,
   `eventFactoidsV1_<hash>`.
5. To force a cold start, clear Local Storage (or call `clearMenuCache()`), then
   reload. A hard reload alone does not clear `localStorage`.

---

## 9. Utilities

- **`utils/cleanUi.js`** — display helpers: `cleanPunctuationSpacing`,
  `uriDisplayString`, `toAggregateUri`, `deduplicateFactoids`.
- **`utils/url.js`** — URL parameter helpers used alongside `filter.js`.

Aggregate person/place/taxonomy pages are static HTML under `aggregate/`
(`aggregate/person/*.html`, `aggregate/place/*.html`,
`aggregate/taxonomy/*.html`). `toAggregateUri` links results to these pages.

---

## 10. Directory structure (actual)

```
spear/
├── browse.html                # production entry
├── dev.html                   # development entry
├── mode.js                    # mode router / boot
├── filter.js                  # shared filter state + URL sync
├── menu.js                    # facet menu queries + populateDropdown/renderKeywordList + cache
├── list.js                    # renderKeywordPrettyList (event concepts, ethnicity) + cache
├── modes/
│   ├── person.js              # person UI + fetch + render
│   ├── event.js               # event UI + fetch + render
│   └── relation.js            # relation UI + fetch + render
├── person/
│   ├── search.js              # person query builder + fetchData
│   ├── person.json            # bundled person snapshot
│   └── README.md              # person-search SPARQL notes + pitfalls
├── event/
│   ├── search.js              # event query builder + fetchEventFactoids (+ cache)
│   ├── person.json            # bundled event/person snapshot
│   └── README.md
├── relation/
│   ├── search.js              # relation query builder + fetchers
│   ├── *.json                 # bundled relation factoid snapshots
│   └── batch_query_*.sh       # batch export scripts (rate-limited)
├── utils/
│   ├── cleanUi.js
│   └── url.js
├── aggregate/                 # static person/place/taxonomy HTML pages
└── CTS/                       # CTS resolver (XQuery) — separate subsystem
```

```
```
```
```
