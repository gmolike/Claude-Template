#!/bin/bash
# init.sh — Frontend-Repo initialisieren
set -euo pipefail

echo "=== {{PROJECT_NAME}} Frontend Setup ==="

read -p "Projektname (z.B. myproject): " PROJECT_NAME
read -p "API URL (z.B. https://dev.myproject.com/api): " API_URL

find . -type f \( -name "*.md" -o -name "*.json" -o -name "*.ts" -o -name "*.tsx" -o -name "*.mjs" -o -name "*.html" -o -name "*.sh" -o -name "*.css" \) \
  -not -path "./.git/*" \
  -not -path "./node_modules/*" \
  -exec sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" {} +

# .env erstellen
cp .env.example .env
sed -i "s|VITE_API_URL=.*|VITE_API_URL=$API_URL|" .env

echo "Setup abgeschlossen!"
echo "Naechste Schritte: pnpm install && pnpm dev"
