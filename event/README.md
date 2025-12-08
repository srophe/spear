Below is a polished **README.md for the EVENT SEARCH system** in SPEAR.
This matches the structure and tone of the Person Search README, and covers:

* Event-level facet logic
* Correct SPARQL patterns
* Working queries
* cURL diagnostics
* Integration details for the JS front-end

If you want a combined *Search System Developer Guide* later, I can generate that too.

---

# 📘 **README.md — Event Search (SPEAR Prosopography)**

# SPEAR Event Search

Advanced multi-facet querying for Syriac **events**, including participants, places, keywords, occupations, relationships, and uncertainty markers.

The Event Search system powers the SPEAR interface that returns **event factoids** associated with Syriac persons and places, enriched with descriptions, provenance, and taxonomy terms.

---

# 🔍 Overview

The SPEAR Event Search allows users to filter events by:

* **Associated persons**
* **Event keywords** (taxonomy terms)
* **Places**
* **Occupations** (of persons within the event)
* **Relationship types**
* **Gender of participants**
* **Uncertainty flags**
* **Source provenance**

Search is performed against the **Neptune SPARQL endpoint**:

```
https://sparql.vanderbilt.edu/sparql
```

Event metadata comes from:

* `<https://spear-prosop.org>` — event factoid triples, statement nodes, provenance
* `<http://syriaca.org/persons#graph>` — person labels associated with events
* `<http://syriaca.org/places#graph>` — place labels

---

# 🎯 Event Search Logic

Event Search differs from Person Search in one major way:

## **Each facet must apply to the *same event instance*.**

Example:

A user selects:

* Keyword = *monasticism*
* Place = *2605*

The query must return only events where:

```
(event has event-keyword monasticism)
AND
(event has event-place 2605)
```

Unlike Person Search, we do **not** intersect facets at the person level.
We intersect *inside the event*.

---

# 🧩 Event Data Model (Simplified)

### Direct triples (`swdt:`)

```ttl
:event8559-121  swdt:event-place     <place/2605> ;
                swdt:event-participant <person/1113> ;
                swdt:event-keyword   <taxonomy/monasticism> .
```

### Provenance statement nodes (`sp:` → `sps:`)

```ttl
:event8559-121 sp:event-participant  :stmt1 .
:stmt1         sps:event-participant <person/1113> ;
               spr:reference-URL     <https://spear-prosop.org/8559-121> .
```

Event Search should use **both**:

* Direct facts (`swdt:`)
* Statement nodes (`sp:` / `sps:`) for provenance and qualifiers

---

# ✔ Correct SPARQL Template for Event Search

This is the default pattern used by the application when assembling the dynamic query.

```sparql
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX schema: <http://schema.org/>
PREFIX swdt: <http://syriaca.org/prop/direct/>
PREFIX sp:   <http://syriaca.org/prop/>
PREFIX sps:  <http://syriaca.org/prop/statement/>
PREFIX spr:  <http://syriaca.org/prop/reference/>

SELECT DISTINCT ?event ?label ?place ?keyword ?person ?ref WHERE {

  GRAPH <https://spear-prosop.org> {

    ### EVENT facet: must match requested keyword(s)
    FILTER EXISTS {
      ?event sp:event-keyword/sps:event-keyword ?kw .
      VALUES ?kw { <http://syriaca.org/taxonomy/monasticism> }
    }

    ### EVENT facet: must match requested place(s)
    FILTER EXISTS {
      ?event swdt:event-place ?pl .
      VALUES ?pl { <http://syriaca.org/place/2605> }
    }

    ### List all participants
    ?event swdt:event-participant ?person .

    OPTIONAL { ?event sp:event-participant ?stmt .
               ?stmt spr:reference-URL ?ref }

    OPTIONAL { ?event rdfs:label ?label }
    OPTIONAL { ?event swdt:event-place ?place }
    OPTIONAL { ?event sp:event-keyword/sps:event-keyword ?keyword }
  }
}
ORDER BY ?event
```

---

# 🟦 cURL Example — Test Event Search Manually

```bash
curl -G "https://sparql.vanderbilt.edu/sparql" \
--data-urlencode 'query=
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX swdt: <http://syriaca.org/prop/direct/>
PREFIX sp:   <http://syriaca.org/prop/>
PREFIX sps:  <http://syriaca.org/prop/statement/>

SELECT DISTINCT ?event ?label ?person ?place ?keyword WHERE {
  GRAPH <https://spear-prosop.org> {

    VALUES ?kw { <http://syriaca.org/taxonomy/monasticism> }
    VALUES ?pl { <http://syriaca.org/place/2605> }

    FILTER EXISTS { ?event sp:event-keyword/sps:event-keyword ?kw }
    FILTER EXISTS { ?event swdt:event-place ?pl }

    ?event swdt:event-participant ?person .
    OPTIONAL { ?event rdfs:label ?label }
    OPTIONAL { ?event swdt:event-place ?place }
    OPTIONAL { ?event sp:event-keyword/sps:event-keyword ?keyword }
  }
}
ORDER BY ?event
' \
-H "Accept: application/sparql-results+json"
```

This verifies whether the event(s) matching all facets exist.

---

# 🧪 Diagnostic: Show All Facets per Event

Useful when an event appears in one facet search but not in another.

```bash
curl -G "https://sparql.vanderbilt.edu/sparql" \
--data-urlencode 'query=
PREFIX swdt: <http://syriaca.org/prop/direct/>
PREFIX sp:   <http://syriaca.org/prop/>
PREFIX sps:  <http://syriaca.org/prop/statement/>

SELECT DISTINCT ?event ?keyword ?place ?person WHERE {
  GRAPH <https://spear-prosop.org> {

    ?event swdt:event-participant ?person .
    OPTIONAL { ?event swdt:event-place ?place }
    OPTIONAL { ?event sp:event-keyword/sps:event-keyword ?keyword }
  }
}
ORDER BY ?event
' \
-H "Accept: application/sparql-results+json"
```

This reveals how events are structured and helps validate facet logic.

---

# 🔧 Front-End Integration Notes

The Event Search UI generates dynamic SPARQL:

* Based on selected filters
* Using `FILTER EXISTS` for facet intersection
* Using UI state objects (`selectedEventKeywords`, `selectedPlaceKeywords`, etc.)

### Search Flow

1. User selects facets
2. JS assembles SPARQL clauses for each facet
3. Clauses are inserted into the template query
4. Query is executed via fetch()
5. Results are enriched through:

   * Person metadata (labels, gender)
   * Place metadata
   * Provenance references

### Important:

✔ Event facets must match *inside the same event*. This is because a user is shown cited factoids.
✔ Person facets are used only to filter events containing a person with the selected characteriscs
✔ Unlike Person Search, OR logic is rare; the Event Search defaults to AND semantics

---

# 📌 Known Pitfalls and Fixes

### ❗ Problem: Event appears in a facet-only test but disappears when multiple facets are selected

**Cause:** One facet applies to the event; another facet applies to the person
**Fix:** Ensure all event filters apply inside the `<https://spear-prosop.org>` graph and use `FILTER EXISTS` blocks.

### ❗ Problem: Statement nodes missing

If `sp:` or `sps:` data is missing, keywords or provenance may not appear.
Use diagnostic queries to isolate gaps.

---

# 🗂 Summary

Event Search enforces **event-level facet intersection**:

| Facet       | Applied At                            | Notes                                             |
| ----------- | ------------------------------------- | ------------------------------------------------- |
| Keyword     | Event                                 | Must match same event                             |
| Place       | Event                                 | Birth/death/residence apply only to Person Search |
| Participant | Event                                 | Multiple participants allowed                     |
| Gender      | Person → filtered within event search |                                                   |
| Uncertainty | Statement node                        |                                                   |
| Source      | Provenance nodes                      |                                                   |

This strict but correct model ensures that search results represent **actual historical events**, not aggregated person properties.

