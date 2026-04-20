#!/bin/bash

# Batch query all relationship factoids
# This script queries each relationship type separately to avoid overwhelming Neptune

ENDPOINT="https://sparql.vanderbilt.edu/sparql"
INPUT_FILE="relationship_types.json"
OUTPUT_DIR="factoids_by_relationship"
COMBINED_OUTPUT="all_relation_factoids.json"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Extract relationship URIs from JSON (get the last part after the last /)
echo "Extracting relationship types..."
RELATIONSHIPS=$(jq -r '.results.bindings[].subject.value' "$INPUT_FILE" | sed 's|.*/||')

# Count total relationships
TOTAL=$(echo "$RELATIONSHIPS" | wc -l | tr -d ' ')
echo "Found $TOTAL relationship types to query"

CURRENT=0

# Query each relationship separately
for rel in $RELATIONSHIPS; do
  CURRENT=$((CURRENT + 1))
  echo "[$CURRENT/$TOTAL] Querying: $rel..."
  
  curl -G "$ENDPOINT" \
    --data-urlencode "query=
PREFIX sp: <http://syriaca.org/prop/>
PREFIX spr: <http://syriaca.org/prop/reference/>
PREFIX schema: <http://schema.org/>

SELECT DISTINCT ?factoid ?description ?source ('http://syriaca.org/taxonomy/$rel' AS ?relationship)
FROM <https://spear-prosop.org>
WHERE {
  ?person sp:$rel ?statementNode .
  ?statementNode spr:reference-URL ?factoid .
  
  OPTIONAL { ?factoid schema:description ?description }
  OPTIONAL { ?factoid spr:part-of-series ?source }
}
ORDER BY ?factoid
" \
    -H "Accept: application/sparql-results+json" \
    > "$OUTPUT_DIR/factoids_${rel}.json" 2>/dev/null
  
  # Check if query succeeded
  if [ $? -eq 0 ]; then
    RESULT_COUNT=$(jq '.results.bindings | length' "$OUTPUT_DIR/factoids_${rel}.json" 2>/dev/null)
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
echo '{"head":{"vars":["factoid","description","source","relationship"]},"results":{"bindings":[' > "$COMBINED_OUTPUT"

FIRST=true
for file in "$OUTPUT_DIR"/factoids_*.json; do
  if [ -f "$file" ]; then
    # Extract bindings and append
    BINDINGS=$(jq -c '.results.bindings[]' "$file" 2>/dev/null)
    if [ -n "$BINDINGS" ]; then
      if [ "$FIRST" = true ]; then
        echo "$BINDINGS" >> "$COMBINED_OUTPUT"
        FIRST=false
      else
        echo ",$BINDINGS" >> "$COMBINED_OUTPUT"
      fi
    fi
  fi
done

# Close JSON structure
echo ']}}' >> "$COMBINED_OUTPUT"

# Pretty print the combined file
jq '.' "$COMBINED_OUTPUT" > "${COMBINED_OUTPUT}.tmp" && mv "${COMBINED_OUTPUT}.tmp" "$COMBINED_OUTPUT"

TOTAL_FACTOIDS=$(jq '.results.bindings | length' "$COMBINED_OUTPUT")
echo ""
echo "✓ Complete! Total factoids collected: $TOTAL_FACTOIDS"
echo "✓ Combined output: $COMBINED_OUTPUT"
echo "✓ Individual files: $OUTPUT_DIR/"
