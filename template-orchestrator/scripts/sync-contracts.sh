#!/bin/bash
# sync-contracts.sh — OpenAPI Specs validieren
set -euo pipefail

echo "=== Contract Validation ==="

if ! command -v npx &> /dev/null; then
  echo "npx nicht gefunden. Bitte Node.js installieren."
  exit 1
fi

echo "Validiere OpenAPI Specs..."
for spec in docs/contracts/openapi/*.yaml; do
  if [ "$(basename "$spec")" = "README.md" ]; then
    continue
  fi
  echo "  Validiere: $spec"
  npx @redocly/cli lint "$spec" --skip-rule no-unused-components || true
done

echo ""
echo "Validation abgeschlossen."
