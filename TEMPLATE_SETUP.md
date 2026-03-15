# Template Setup

Dieses Projekt wurde aus dem FSD Agent Team Template erstellt.

## Ersteinrichtung

Führe das Init-Script aus um Platzhalter zu ersetzen:

```bash
chmod +x scripts/init.sh
./scripts/init.sh
```

Das Script:

1. Fragt Projektname, Beschreibung und GitHub-User ab
2. Ersetzt alle `{{PLATZHALTER}}` in allen Dateien
3. Installiert Dependencies
4. Initialisiert Husky
5. Erstellt initialen Commit
6. Löscht sich selbst und diese Datei

## Danach

1. `.env` konfigurieren (aus `.env.example`)
2. `GITHUB_TOKEN` in `.env` setzen (für GitHub MCP)
3. Datenbank starten (`docker compose up db -d`)
4. `pnpm dev` starten
5. Claude Code installieren (`npm i -g @anthropic-ai/claude-code`)
6. MCP-Status prüfen (`/mcp` in Claude Code)
7. Playwright installieren (`npx playwright install chromium`)
8. DRYwall Plugin installieren (`/plugin marketplace add nikhaldi/drywall && /plugin install drywall@drywall`)

## Optional: Oh My Claude Code (OMC)

OMC automatisiert die Agent-Orchestrierung. Das Template funktioniert auch OHNE OMC.

### Installation

```bash
/plugin marketplace add https://github.com/Yeachan-Heo/oh-my-claudecode
/plugin install oh-my-claudecode
/oh-my-claudecode:omc-setup
```

### Workflow-Mapping

| Template-Stufe       | OMC-Modus            | Verwendung                       |
| -------------------- | -------------------- | -------------------------------- |
| Stufe 1 — Bugfix     | `ecomode`            | Token-effizient, einzelner Agent |
| Stufe 2 — Lite       | `ultrawork`          | Parallele Execution              |
| Stufe 3 — Full Scrum | `autopilot` / `team` | Volle Autonomie mit Verification |
| Code Review          | `ultraqa`            | Automatisiertes QA               |

### Prüfen

```bash
/omc-doctor    # Sollte grünen Status zeigen
```

## Slash Commands testen

```bash
claude          # Claude Code starten
/scrum          # Sprint-Board anzeigen — sollte leer sein
/new-feature    # Feature scaffolden testen
/review         # Code Review testen
/commit         # Smart Commit testen
```

## Template-Sync

Dieses Projekt synchronisiert sich automatisch mit dem Template-Repo.
Jeden Montag prüft die GitHub Action ob es Updates gibt und erstellt ggf. einen PR.

Um die Sync-Quelle zu konfigurieren, passe `.github/workflows/template-sync.yml` an.
