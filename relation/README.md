# Relation Mode

## Overview

The Relation mode displays factoids about relationships between persons in the SPEAR prosopography. Due to data structure limitations, relationship queries require batch processing scripts to generate the default view.

## Generating Default Relationship Factoids

### Prerequisites



### Running the Batch Query

1. Make the batch script executable:

```bash
chmod +x batch_query_person_relationship.sh
```
2. cd into relation folder, run:
```bash
./batch_query_person_relationship.sh
```

Or run directly with bash:

```bash
bash batch_query_person_relationship.sh
```

## Data Structure Challenge

The main issue with querying all relationships is that they require string manipulation to connect taxonomy relationship URIs with person triple prop URIs. The SPEAR data uses:

- `/taxonomy/` URIs for relationship types in results
- `/prop/` URIs for person triples

These should either be the same or have connecting triples in the triplestore to enable direct sparql queries of relationships. String matching or manipulating queries are not efficient in graph databases, which is why batch processing is necessary.

## Automated Generation (GitHub Actions)

The repository includes a GitHub Actions workflow that automatically generates all necessary JSON files:

```bash
# Trigger manually from GitHub Actions tab
# Or runs automatically every Sunday at midnight
```

The workflow:
1. Fetches relationship types from SPARQL endpoint
2. Runs `batch_query_relationships.sh` to generate `all_relation_factoids.json`
3. Runs `filter_factoids.js` to create `filtered_relation_factoids.json`
4. Runs `batch_query_person_relationship.sh` to generate `all_person_relation_factoids.json`
5. Commits and pushes the updated JSON files

Workflow file: `.github/workflows/generate_relation_data.yml`

## Files

- `batch_query_person_relationship.sh`: Batch script to query all relationship types with person info
- `batch_query_relationships.sh`: Batch script to query all relationship factoids
- `filter_factoids.js`: Node.js script to filter factoids by source
- `filtered_relation_factoids.json`: Pre-filtered factoids from three main sources (1,188 entries)
- `all_relation_factoids.json`: Complete relationship factoids dataset (3,569 entries)
- `all_person_relation_factoids.json`: Relationship factoids with person details
- `relationship_types.json`: List of all relationship types from taxonomy