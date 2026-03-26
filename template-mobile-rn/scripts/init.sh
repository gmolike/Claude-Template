#!/bin/bash
set -euo pipefail
echo "=== {{PROJECT_NAME}} Mobile Setup ==="
read -p "Projektname: " PROJECT_NAME
read -p "API URL: " API_URL
find . -type f \( -name "*.md" -o -name "*.json" -o -name "*.ts" -o -name "*.tsx" -o -name "*.sh" \) \
  -not -path "./.git/*" -not -path "./node_modules/*" \
  -exec sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" {} +
cp .env.example .env
sed -i "s|EXPO_PUBLIC_API_URL=.*|EXPO_PUBLIC_API_URL=$API_URL|" .env
echo "Setup abgeschlossen! pnpm install && pnpm start"
