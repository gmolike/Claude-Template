#!/bin/bash
# generate-csharp.sh — C# Interfaces aus OpenAPI generieren
set -euo pipefail

echo "=== C# Codegen ==="

OUTPUT_DIR="generated/csharp"
mkdir -p "$OUTPUT_DIR"

# Pruefen ob NSwag installiert ist
if ! command -v nswag &> /dev/null; then
  echo "NSwag nicht gefunden. Installiere mit: dotnet tool install -g NSwag.ConsoleCore"
  echo "Alternativ: dotnet add package NSwag.ApiDescription.Client"
  echo ""
  echo "Skipping C# generation (optional)."
  exit 0
fi

echo "Generiere C# Interfaces aus bundled spec..."
nswag openapi2csclient \
  /input:openapi/bundled.yaml \
  /output:"$OUTPUT_DIR/ApiContracts.cs" \
  /namespace:"{{PROJECT_NAME}}.Contracts" \
  /generateClientInterfaces:true \
  /generateDtoTypes:true

echo ""
echo "C# Interfaces generiert: $OUTPUT_DIR/ApiContracts.cs"
