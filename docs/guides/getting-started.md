# Getting Started

## Voraussetzungen

- Node.js 20+ / pnpm 9+ / Claude Code CLI / Docker (optional)

## Ersteinrichtung

```bash
git clone <repo-url> && cd <project>
pnpm install
cp .env.example .env
docker compose up db -d
pnpm --filter @repo/api db:push
pnpm dev
```

## MCP-Server einrichten

Die MCP-Config liegt in `.claude/.mcp.json` und wird automatisch geladen.

1. **GitHub Token** setzen (für Issues, PRs, Branches):

   ```bash
   # In .env eintragen:
   GITHUB_TOKEN=ghp_dein_token_hier
   # Token erstellen: https://github.com/settings/tokens
   # Scopes: repo, read:org, read:project
   ```

2. **MCP-Status prüfen** (in Claude Code):

   ```
   /mcp
   ```

   Alle 4 Server (github, prisma, context7, playwright) sollten grün sein.

3. **Playwright einrichten** (einmalig):
   ```bash
   npx playwright install chromium
   ```

## Slash Commands nutzen

```bash
claude  # Im Projektverzeichnis starten

/scrum                              # Sprint-Board anzeigen
/scrum create Login implementieren  # Task erstellen
/new-feature User-Profil mit Avatar # Feature scaffolden (FSD-konform)
/review apps/web/src/features/      # Code Review
/commit                             # Smart Commit
```

## Workflow-Stufen

```bash
# Stufe 1 — Bugfix (1 Agent):
"Bugfix: Login Button reagiert nicht"

# Stufe 2 — Lite (Senior + QS):
"Lite Feature: User-Profil-Seite"

# Stufe 3 — Full Scrum (volles Team):
"Full Scrum: Komplettes Benachrichtigungssystem"
```

## VS Code Workspaces

Öffne den passenden Workspace:

- `team.code-workspace` — Gesamtübersicht (Lead)
- `frontend.code-workspace` — Frontend (🔵 Blau)
- `backend.code-workspace` — Backend (🟢 Grün)
- `qa.code-workspace` — QA (🟠 Orange)
- `designer.code-workspace` — Design (🩷 Pink)
- `po.code-workspace` — PO (🟣 Lila)

## DRYwall Plugin (Code-Duplikation)

```bash
# In Claude Code:
/plugin marketplace add nikhaldi/drywall
/plugin install drywall@drywall
```
