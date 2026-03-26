#!/bin/bash
# init.sh — Contracts-Repo initialisieren
set -euo pipefail

echo "=== {{PROJECT_NAME}} Contracts Setup ==="
echo ""

read -p "Projektname (z.B. myproject): " PROJECT_NAME
read -p "GitHub User/Org (z.B. gmolike): " GITHUB_USER

echo ""
echo "Ersetze Platzhalter..."

find . -type f \( -name "*.md" -o -name "*.yaml" -o -name "*.yml" -o -name "*.json" -o -name "*.sh" -o -name "*.ts" \) \
  -not -path "./.git/*" \
  -not -path "./node_modules/*" \
  -exec sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" {} +

find . -type f \( -name "*.md" -o -name "*.yaml" -o -name "*.yml" -o -name "*.json" -o -name "*.sh" \) \
  -not -path "./.git/*" \
  -not -path "./node_modules/*" \
  -exec sed -i "s/{{GITHUB_USER}}/$GITHUB_USER/g" {} +

echo "Platzhalter ersetzt."
echo ""
echo "Setup abgeschlossen!"
echo "Naechste Schritte:"
echo "  1. pnpm install"
echo "  2. pnpm validate"
echo "  3. git add -A && git commit -m 'chore: initialize $PROJECT_NAME contracts'"
