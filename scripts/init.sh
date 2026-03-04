#!/usr/bin/env bash
set -euo pipefail

echo "🚀 FSD Agent Team Template — Projektinitialisierung"
echo "===================================================="
echo ""

read -p "📝 Projektname (lowercase, keine Leerzeichen): " PROJECT_NAME
read -p "📄 Beschreibung: " PROJECT_DESC
read -p "👤 GitHub Username/Org: " GITHUB_USER
read -p "📦 Template Repo (Owner/Repo): " TEMPLATE_REPO

TEMPLATE_OWNER=$(echo "$TEMPLATE_REPO" | cut -d'/' -f1)
TEMPLATE_REPO_NAME=$(echo "$TEMPLATE_REPO" | cut -d'/' -f2)
CREATION_DATE=$(date +%Y-%m-%d)

echo ""
echo "🔄 Ersetze Platzhalter..."

find . -type f \( \
  -name "*.md" -o -name "*.json" -o -name "*.yml" -o -name "*.yaml" \
  -o -name "*.ts" -o -name "*.tsx" -o -name "*.mjs" -o -name "*.html" \
  -o -name "*.css" -o -name "*.prisma" -o -name "Jenkinsfile" \
  -o -name "*.code-workspace" -o -name "Dockerfile*" -o -name "*.conf" \
\) \
  -not -path "./node_modules/*" \
  -not -path "./.git/*" \
  -not -path "./.turbo/*" \
  -exec sed -i "s/{{PROJECT_NAME}}/${PROJECT_NAME}/g" {} \; \
  -exec sed -i "s/{{PROJECT_DESC}}/${PROJECT_DESC}/g" {} \; \
  -exec sed -i "s/{{GITHUB_USER}}/${GITHUB_USER}/g" {} \; \
  -exec sed -i "s/gmolike/${TEMPLATE_OWNER}/g" {} \; \
  -exec sed -i "s/Claude-Template/${TEMPLATE_REPO_NAME}/g" {} \; \
  -exec sed -i "s/{{CREATION_DATE}}/${CREATION_DATE}/g" {} \;

echo "📦 Installiere Dependencies..."
pnpm install

echo "🐶 Initialisiere Husky..."
pnpm exec husky init 2>/dev/null || true

echo "🧹 Räume auf..."
rm -f scripts/init.sh TEMPLATE_SETUP.md

echo "📝 Erstelle initialen Commit..."
git add -A
git commit -m "feat: initialize ${PROJECT_NAME} from template"

echo ""
echo "✅ Projekt ${PROJECT_NAME} ist bereit!"
echo ""
echo "Nächste Schritte:"
echo "  1. cp .env.example .env && vim .env"
echo "  2. GITHUB_TOKEN in .env setzen (https://github.com/settings/tokens)"
echo "  3. docker compose up db -d"
echo "  4. pnpm --filter @repo/api db:push"
echo "  5. pnpm dev"
echo "  6. claude  (Claude Code starten)"
echo "  7. /mcp    (MCP-Server Status prüfen)"
echo "  8. /scrum  (Sprint-Board testen)"
