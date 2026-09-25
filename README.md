# SPEAR — Syriaca Prosopographical Event Analysis and Research

A web application for exploring prosopographical data from the Syriaca.org
project, built with vanilla JavaScript (ES modules) and SPARQL queries against
an AWS Neptune triplestore.

> **Developers:** for detailed, code-accurate technical documentation
> (architecture, boot lifecycle, SPARQL query construction, caching,
> Neptune/API Gateway backend, local development, and operations), see
> **[`TECHNICAL.md`](./TECHNICAL.md)**.

## Overview

SPEAR provides an interactive interface for searching and analyzing historical
persons, events, and relationships from Syriac sources. Search runs against a
public SPARQL endpoint backed by a Neptune database. To reduce load, default and
simple views are served from bundled JSON snapshots, and only complex facet
combinations issue live SPARQL queries.

## Features

### Multi-modal search
- **Person search** — find individuals by name, occupation, gender,
  relationships, and associated places.
- **Event search** — explore historical events, filtering by participants,
  places, event keywords, and sources.
- **Relation search** — explore documented relationships, filtering by source
  and relationship type.

### Filtering
- **Multi-select facets** — combine events, relationships, places, occupations,
  gender, and sources.
- **Source filtering** — Letters of Severus, Lives of the Eastern Saints,
  Chronicle of Edessa. (Selecting all three is treated as no source filter.)
- **Uncertainty filter** — exclude claims by certainty level.
- **Geographic filtering** — birth place, death place, residence, and event
  place.
- **Shareable URLs** — active mode and facet selections are encoded in the URL.

### Performance
- **JSON-first** — default/simple views read from bundled JSON; live SPARQL is a
  fallback for complex facet combinations.
- **Client-side caching** — facet menus and event-factoid results are cached in
  `localStorage` (24h TTL) to reduce endpoint traffic.
- **Backend safeguards** — API Gateway throttling plus a Neptune query timeout
  (`neptune_query_timeout`) protect the triplestore.

## Technical architecture

### Frontend
- **Vanilla JavaScript, no build step** — plain ES modules, no bundler or
  `package.json`.
- **Mode router** (`mode.js`) — routes between `person`, `event`, and `relation`
  modes based on the `?type=` URL parameter; manages mount lifecycle and
  browser history.
- **Per-mode modules** (`modes/*.js`) — each exports `sidebar`, `bind`, `fetch`,
  and `render`.
- **Query builders** (`{person,event,relation}/search.js`) — construct SPARQL
  from facet state and fetch results.
- **Responsive UI** — Bootstrap-based sidebar with collapsible filter sections.

### Backend
- **SPARQL over HTTP GET** — requests use `?query=<url-encoded>` with
  `Accept: application/sparql-results+json`.
- **AWS Neptune** — cluster (writer + reader) in a VPC, reached via API Gateway
  → VPC Link → NLB, targeting the reader endpoint.
- **Error handling** — failed/timed-out queries degrade to empty results.

See [`TECHNICAL.md`](./TECHNICAL.md) for the full backend topology, security
posture, and tuning guidance.

## Getting started

### Prerequisites
- A modern browser with JavaScript enabled.
- Access to the configured SPARQL endpoint.

### Run locally
No build step. Serve the folder over HTTP (ES modules and `localStorage` do not
work under `file://`):

```bash
python3 -m http.server 8000
# then open http://localhost:8000/browse.html
```

Alternatives: `npx serve`, or the VS Code "Live Server" extension.

> **CORS:** the SPARQL endpoint must allow your local origin
> (e.g. `http://localhost:8000`); otherwise browser fetches fail with a CORS
> error even when the query is valid.

### Usage
1. Open `browse.html`.
2. Choose a search mode (Person, Event, or Relation).
3. Apply filters in the sidebar.
4. View results in the main panel.
5. Share the search via the URL.

## Configuration

### SPARQL endpoint
`SPARQL_ENDPOINT` is defined in each search/menu module:
- `menu.js`, `list.js`
- `person/search.js`, `event/search.js`, `relation/search.js`

### Caching (client-side)
- 24h TTL in `localStorage`; shared helper `fetchWithCache` in `menu.js`.
- Cache key prefixes: `dropdown_`, `keywordListV2_`, `keywordPrettyV1_`,
  `eventFactoidsV1_`.
- Call `clearMenuCache()` (in `menu.js`) to purge all cached menu/result data —
  e.g. after a Neptune data refresh.

## Data sources

- **SPEAR prosopography graph:** `https://spear-prosop.org`
- **Syriaca persons graph:** `http://syriaca.org/persons#graph`
- **Place labels graph:** `http://syriaca.org/geo#graph`
- **Source collections:** Letters of Severus, Lives of the Eastern Saints,
  Chronicle of Edessa

## Browser support

Requires ES6 modules, the Fetch API, `localStorage`, and CSS Grid/Flexbox.
Recent Chrome/Edge, Firefox, and Safari are supported.

## Development

### File structure (top level)
```
spear/
├── browse.html            # production entry
├── dev.html               # development entry
├── mode.js                # mode router / boot lifecycle
├── filter.js              # shared filter state + URL sync
├── menu.js                # facet menu queries + caching (fetchWithCache, clearMenuCache)
├── list.js                # event-concept / ethnicity menu loader + caching
├── modes/
│   ├── person.js
│   ├── event.js
│   └── relation.js
├── person/   { search.js, person.json, README.md }
├── event/    { search.js, person.json, README.md }
├── relation/ { search.js, *.json, batch_query_*.sh }
├── utils/    { cleanUi.js, url.js }
├── aggregate/             # static person/place/taxonomy HTML pages
└── CTS/                   # CTS resolver (XQuery) — separate subsystem
```


### Adding a new filter
1. Add the UI control to the relevant mode's `sidebar`/`bind` (`modes/*.js`).
2. Add the facet to the filter state and to `FILTER_MAP` in `filter.js`.
3. Extend the SPARQL query builder in the relevant `*/search.js`.
4. Add URL parameter handling so the facet is shareable.

## License

Open source — see the original Srophé Application license terms.
See [`LICENSE`](./LICENSE) §3.
