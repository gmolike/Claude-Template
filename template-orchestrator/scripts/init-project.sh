#!/bin/bash
# init-project.sh — Orchestrator-Repo initialisieren
set -euo pipefail

echo "=== {{PROJECT_NAME}} Orchestrator Setup ==="
echo ""

read -p "Projektname (z.B. myproject): " PROJECT_NAME
read -p "GitHub User/Org (z.B. gmolike): " GITHUB_USER
read -p "Projekt-Beschreibung: " PROJECT_DESC

echo ""
echo "Ersetze Platzhalter..."

# Platzhalter in allen relevanten Dateien ersetzen
find . -type f \( -name "*.md" -o -name "*.yaml" -o -name "*.yml" -o -name "*.json" -o -name "*.sh" \) \
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
echo "  1. git add -A && git commit -m 'chore: initialize $PROJECT_NAME orchestrator'"
echo "  2. Erstelle die weiteren Repos (siehe docs/guides/repo-setup.md)"
