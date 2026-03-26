#!/bin/bash
# generate-api-types.sh — TypeScript Types aus OpenAPI Spec generieren
set -euo pipefail

SPEC_URL="${OPENAPI_SPEC_URL:-https://dev.example.com/api/swagger/v1/swagger.json}"
OUTPUT="generated/api-types.ts"

echo "Generiere API Types aus: $SPEC_URL"

mkdir -p "$(dirname "$OUTPUT")"
npx openapi-typescript "$SPEC_URL" -o "$OUTPUT"

echo "Types generiert: $OUTPUT"
echo "Anzahl exportierte Types: $(grep -c 'export' "$OUTPUT" || echo 0)"
