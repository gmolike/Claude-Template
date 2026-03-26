#!/bin/bash
set -euo pipefail
echo "=== {{PROJECT_NAME}} Backend Hono Setup ==="
read -p "Projektname: " PROJECT_NAME
find . -type f \( -name "*.md" -o -name "*.json" -o -name "*.ts" -o -name "*.mjs" -o -name "*.sh" -o -name "*.yaml" -o -name "*.yml" -o -name "*.prisma" \) \
  -not -path "./.git/*" -not -path "./node_modules/*" \
  -exec sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" {} +
echo "Setup abgeschlossen! pnpm install && pnpm dev"
