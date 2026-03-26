#!/bin/bash
# bundle.sh — Einzelne Specs zu bundled.yaml zusammenfuegen
set -euo pipefail

echo "=== OpenAPI Bundle ==="

npx @redocly/cli bundle openapi/auth.yaml openapi/users.yaml \
  -o openapi/bundled.yaml

echo "Bundle erstellt: openapi/bundled.yaml"
