#!/bin/bash
# generate-ts.sh — TypeScript Types aus OpenAPI generieren
set -euo pipefail

echo "=== TypeScript Codegen ==="

OUTPUT_DIR="generated/typescript"
mkdir -p "$OUTPUT_DIR"

for spec in openapi/*.yaml; do
  filename=$(basename "$spec" .yaml)
  if [ "$filename" = "bundled" ]; then
    continue
  fi
  echo "Generiere: $filename"
  npx openapi-typescript "$spec" -o "$OUTPUT_DIR/$filename.ts"
done

# Index-Datei erstellen
echo "// Auto-generated — do not edit manually" > "$OUTPUT_DIR/index.ts"
for ts in "$OUTPUT_DIR"/*.ts; do
  filename=$(basename "$ts" .ts)
  if [ "$filename" = "index" ]; then
    continue
  fi
  echo "export * from './$filename';" >> "$OUTPUT_DIR/index.ts"
done

echo ""
echo "TypeScript Types generiert in $OUTPUT_DIR/"
echo "Exportierte Module: $(grep -c 'export' "$OUTPUT_DIR/index.ts")"
