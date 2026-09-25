
# SPEAR Person Search

Advanced facet-based querying across Syriac persons, events, and places.

This document describes how the **Person Search** system works, including SPARQL logic, facet behavior, and cURL examples useful for debugging data.

---

## 🔍 Overview

The SPEAR **Person Search** engine allows users to filter persons based on multiple independent facets such as:

* **Event keyword taxonomy** (e.g., `monasticism`)
* **Places** (birth, death, residence, or place of an associated event)
* **Gender, occupation, relationships** (optional facets)
* **Names / keyword text search**

Search is executed against the **Vanderbilt University Libraries' public SPARQL endpoint**:

```
https://sparql.vanderbilt.edu/sparql
```

All person-level data is sourced from:

* `<https://spear-prosop.org>` – event links, factoids, provenance
* `<http://syriaca.org/persons#graph>` – labels, descriptions, metadata

---

## Person-Level Facet Intersection 

A person should be returned **if they match all selected facets**, but:

### Facets do *not* need to be satisfied by the same event.

Example:

* A person participates in **Event A**, which has keyword *monasticism*
* They also participate in **Event B**, which has place *Edessa*

Even though A ≠ B, this **should still match**, because both facets apply to the **same person node**.


---

## ✔ Corrected SPARQL Logic

Facet filters use **independent EXISTS blocks**, ensuring each facet can be satisfied by different event or person triples.

```sparql
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX swdt: <http://syriaca.org/prop/direct/>
PREFIX sp:   <http://syriaca.org/prop/>
PREFIX sps:  <http://syriaca.org/prop/statement/>

SELECT DISTINCT ?person WHERE {
  GRAPH <https://spear-prosop.org> {

    VALUES ?taxonomy { <http://syriaca.org/taxonomy/monasticism> }
    VALUES ?place    { <http://syriaca.org/place/2605> }

    ### Person must match EVENT facet (keyword)
    FILTER EXISTS {
      ?event1 swdt:event-participant ?person .
      ?event1 sp:event-keyword/sps:event-keyword ?taxonomy .
    }

    ### Person must match PLACE facet
    FILTER EXISTS {
      { ?person swdt:birth-place ?place . }
      UNION { ?person swdt:death-place ?place . }
      UNION { ?person swdt:residence ?place . }
      UNION {
        ?event2 swdt:event-participant ?person ;
                swdt:event-place ?place .
      }
    }
  }
}
```

This version works for all valid person searches and returns person 1113 correctly.

---

## Troublshooting: Running Diagnostic Queries via cURL

Useful for debugging when a person fails to appear in results.

### Diagnostic: Show all events, keywords, and places for a given person

```bash
curl -G "https://sparql.vanderbilt.edu/sparql" \
--data-urlencode 'query=
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX swdt: <http://syriaca.org/prop/direct/>
PREFIX sp:   <http://syriaca.org/prop/>
PREFIX sps:  <http://syriaca.org/prop/statement/>

SELECT DISTINCT ?event ?eventLabel ?keyword ?place ?ref WHERE {
  GRAPH <https://spear-prosop.org> {
    VALUES ?person { <http://syriaca.org/person/1113> }

    ?event swdt:event-participant ?person .
    OPTIONAL { ?event rdfs:label ?eventLabel }
    OPTIONAL { ?event sp:event-keyword/sps:event-keyword ?keyword }
    OPTIONAL { ?event swdt:event-place ?place }
    OPTIONAL {
      ?event sp:event-participant ?stmt .
      ?stmt sps:event-participant ?person ;
            spr:reference-URL ?ref .
    }
  }
}
ORDER BY ?event
' \
-H "Accept: application/sparql-results+json"
```

This reveals:

* All events related to the person
* Keywords per event
* Places per event
* Reference URLs

---

## Person Search Query (Labels + Description + Facets)

This expands the facet query to retrieve multilingual labels and descriptions.

```sparql
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX schema: <http://schema.org/>
PREFIX swdt: <http://syriaca.org/prop/direct/>
PREFIX sp:   <http://syriaca.org/prop/>
PREFIX sps:  <http://syriaca.org/prop/statement/>

SELECT DISTINCT ?person ?label_en ?label_syr ?description WHERE {

  GRAPH <https://spear-prosop.org> {
    VALUES ?taxonomy { <http://syriaca.org/taxonomy/monasticism> }
    VALUES ?place    { <http://syriaca.org/place/2605> }

    FILTER EXISTS {
      ?event1 swdt:event-participant ?person .
      ?event1 sp:event-keyword/sps:event-keyword ?taxonomy .
    }

    FILTER EXISTS {
      { ?person swdt:birth-place ?place . }
      UNION { ?person swdt:death-place ?place . }
      UNION { ?person swdt:residence ?place . }
      UNION {
        ?event2 swdt:event-participant ?person ;
                swdt:event-place ?place .
      }
    }
  }

  GRAPH <http://syriaca.org/persons#graph> {
    OPTIONAL { ?person rdfs:label ?label_en_ FILTER(LANGMATCHES(LANG(?label_en_), "en")) }
    OPTIONAL { ?person rdfs:label ?label_syr FILTER(LANGMATCHES(LANG(?label_syr), "syr")) }
    OPTIONAL { ?person schema:description ?description }
  }

  BIND(COALESCE(?label_en_, STRAFTER(STR(?person), "/person/")) AS ?label_en)
}
ORDER BY ?label_en
```

---

## 🔧 Integration Notes for the Front-End

* Facet state is composed client-side (React)
* A SPARQL query is built dynamically based on selected facets
* Queries are cached to avoid unnecessary calls
* Place, Keyword, Gender, and Occupation facets are independent filters
* Results are always the **intersection of person sets**, not event sets
* Pagination is implemented client-side

---

## Data Model Summary

| Element              | Source Graph     | Description                   |
| -------------------- | ---------------- | ----------------------------- |
| `swdt:*`             | spear-prosop.org | Direct factoid triples        |
| `sp:*` / `sps:*`     | spear-prosop.org | Statement nodes + provenance  |
| `rdfs:label`         | persons#graph    | Multilingual labels (en, syr) |
| `schema:description` | persons#graph    | Text descriptions             |
| Event Taxonomy       | taxonomy URIs    | From syriaca.org              |

---

## 📌 Known Pitfalls to Avoid

### ❌ Requiring facets to match the same event

This incorrectly excludes many valid persons.

### ❌ Putting VALUES outside GRAPH blocks

Neptune interprets them differently.

### ❌ Mixing person and event logic before resolving person identity

Compute person URIs first, then enrich.

---
