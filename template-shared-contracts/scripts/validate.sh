#!/bin/bash
# validate.sh — OpenAPI Specs validieren
set -euo pipefail

echo "=== OpenAPI Validation ==="

ERRORS=0

for spec in openapi/*.yaml; do
  filename=$(basename "$spec")
  if [ "$filename" = "bundled.yaml" ]; then
    continue
  fi
  echo "Validiere: $spec"
  if ! npx @redocly/cli lint "$spec" --skip-rule no-unused-components 2>&1; then
    ERRORS=$((ERRORS + 1))
  fi
done

if [ $ERRORS -gt 0 ]; then
  echo ""
  echo "FEHLER: $ERRORS Spec(s) mit Validierungsfehlern!"
  exit 1
fi

echo ""
echo "Alle Specs valide."
