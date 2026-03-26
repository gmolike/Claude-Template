#!/bin/bash
set -euo pipefail

echo "=== OpenAPI Export ==="

dotnet run --project src/{{PROJECT_NAME}}.API -- --urls "http://localhost:5099" &
API_PID=$!
sleep 3

curl -s http://localhost:5099/swagger/v1/swagger.json > openapi-export.json
kill $API_PID

echo "OpenAPI Spec exportiert: openapi-export.json"
