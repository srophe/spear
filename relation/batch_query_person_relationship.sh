#!/bin/bash

# Batch query all relationship factoids with person information
# This script queries each relationship type separately to avoid overwhelming Neptune

ENDPOINT="https://sparql.vanderbilt.edu/sparql"
INPUT_FILE="relationship_types.json"
OUTPUT_DIR="person_factoids_by_relationship"
COMBINED_OUTPUT="all_person_relation_factoids.json"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Extract relationship URIs from JSON
echo "Extracting relationship types..."
RELATIONSHIPS=$(jq -r '.results.bindings[].subject.value' "$INPUT_FILE")

# Count total relationships
TOTAL=$(echo "$RELATIONSHIPS" | wc -l | tr -d ' ')
echo "Found $TOTAL relationship types to query"

CURRENT=0

# Query each relationship separately
for rel_uri in $RELATIONSHIPS; do
  CURRENT=$((CURRENT + 1))
  # Extract just the relationship name for filename
  rel_name=$(echo "$rel_uri" | sed 's|.*/||')
  echo "[$CURRENT/$TOTAL] Querying: $rel_name..."

    # Extract just the relationship name for filename
  rel_name=$(echo "$rel_uri" | sed 's|.*/||')
  
  # Convert taxonomy URI to prop URI
  prop_uri=$(echo "$rel_uri" | sed 's|/taxonomy/|/prop/|')
  
  
  curl -G "$ENDPOINT" \
    --data-urlencode "query=
PREFIX sp: <http://syriaca.org/prop/>
PREFIX spr: <http://syriaca.org/prop/reference/>
PREFIX schema: <http://schema.org/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX swdt: <http://syriaca.org/prop/direct/>

SELECT DISTINCT ?factoid ?person ?label_en ?description ?relationship ?gender ?occupation ?source
FROM <https://spear-prosop.org>
FROM NAMED <http://syriaca.org/persons#graph>
WHERE {
  # Get factoids from the three main sources
  ?factoid spr:part-of-series ?source .
  VALUES ?source {
    <https://spear-prosop.org/letters-severus>
    <https://spear-prosop.org/lives-eastern-saints>
    <https://spear-prosop.org/chronicle-edessa>
  }
  
  # Get person relationships for this specific relationship type
  ?person <$prop_uri> ?statementNode .
  ?statementNode spr:reference-URL ?factoid .
  
  # Bind the relationship URI
  BIND(<$rel_uri> AS ?relationship)
  
  # Get factoid description
  OPTIONAL { 
    ?factoid schema:description ?description .
    FILTER(LANG(?description) = \"en\")
  }
  
  # Get person info from persons graph
  OPTIONAL {
    GRAPH <http://syriaca.org/persons#graph> {
      ?person rdfs:label ?label_en .
      FILTER(LANG(?label_en) = \"en\")
    }
  }
  
  OPTIONAL {
    GRAPH <http://syriaca.org/persons#graph> {
      ?person swdt:gender ?gender .
    }
  }
  
  OPTIONAL {
    GRAPH <http://syriaca.org/persons#graph> {
      ?person swdt:occupation ?occupation .
    }
  }
}
ORDER BY ?person ?factoid
LIMIT 10000
" \
    -H "Accept: application/sparql-results+json" \
    > "$OUTPUT_DIR/factoids_${rel_name}.json" 2>/dev/null
  
  # Check if query succeeded
  if [ $? -eq 0 ]; then
    RESULT_COUNT=$(jq '.results.bindings | length' "$OUTPUT_DIR/factoids_${rel_name}.json" 2>/dev/null)
    if [ -n "$RESULT_COUNT" ]; then
      echo "  ✓ Found $RESULT_COUNT factoids"
    else
      echo "  ✗ Query failed or returned invalid JSON"
    fi
  else
    echo "  ✗ Curl failed"
  fi
  
  # Sleep to avoid overwhelming Neptune
  sleep 2
done

echo ""
echo "Combining all results into $COMBINED_OUTPUT..."

# Combine all JSON files into one
# Start with the JSON structure
echo '{"head":{"vars":["factoid","person","label_en","description","relationship","gender","occupation","source"]},"results":{"bindings":[' > "$COMBINED_OUTPUT"

FIRST=true
for file in "$OUTPUT_DIR"/factoids_*.json; do
  if [ -f "$file" ]; then
    # Extract bindings and append
    BINDINGS=$(jq -c '.results.bindings[]' "$file" 2>/dev/null)
    if [ -n "$BINDINGS" ]; then
      while IFS= read -r binding; do
        if [ "$FIRST" = true ]; then
          echo "$binding" >> "$COMBINED_OUTPUT"
          FIRST=false
        else
          echo ",$binding" >> "$COMBINED_OUTPUT"
        fi
      done <<< "$BINDINGS"
    fi
  fi
done

# Close JSON structure
echo ']}}' >> "$COMBINED_OUTPUT"

# Validate and pretty print the combined file
if jq empty "$COMBINED_OUTPUT" 2>/dev/null; then
  jq '.' "$COMBINED_OUTPUT" > "${COMBINED_OUTPUT}.tmp" && mv "${COMBINED_OUTPUT}.tmp" "$COMBINED_OUTPUT"
  TOTAL_FACTOIDS=$(jq '.results.bindings | length' "$COMBINED_OUTPUT")
  echo ""
  echo "✓ Complete! Total factoids collected: $TOTAL_FACTOIDS"
  echo "✓ Combined output: $COMBINED_OUTPUT"
  echo "✓ Individual files: $OUTPUT_DIR/"
else
  echo "✗ Error: Combined JSON is invalid"
fi
