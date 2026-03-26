#!/bin/bash
set -euo pipefail
SPEC_URL="${OPENAPI_SPEC_URL:-https://dev.example.com/api/swagger/v1/swagger.json}"
OUTPUT="generated/api-types.ts"
mkdir -p "$(dirname "$OUTPUT")"
npx openapi-typescript "$SPEC_URL" -o "$OUTPUT"
echo "Types generiert: $OUTPUT"
