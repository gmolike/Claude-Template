# Workflow-Skills Regel

## Projekt-Workflow Skills

Verantwortlich: Scrum Master, alle Agents

| Skill                  | Wann nutzen                                 | Pflicht bei     |
| ---------------------- | ------------------------------------------- | --------------- |
| `/scrum`               | Sprint-Board anzeigen, Tasks verschieben    | Sprint-Planung  |
| `/new-feature`         | Feature FSD-konform anlegen + Scrum-Task    | Neuen Features  |
| `/review`              | Code Review: FSD, Types, Duplikation, Tests | Jedem Review    |
| `/commit`              | Smart Commit mit Lint/Typecheck/Changelog   | Jedem Commit    |
| `/design`              | Design-Workflow mit Canva-MCP               | Design-Aufgaben |
| `/changelog-generator` | Release Notes aus Git-History               | Releases        |

## Built-in Quality Skills

Verantwortlich: Senior QS (primaer), alle Seniors

| Skill              | Wann nutzen                           | Pflicht bei               |
| ------------------ | ------------------------------------- | ------------------------- |
| `/code-review`     | Diff auf Correctness-Bugs pruefen     | Jedem PR (PFLICHT)        |
| `/security-review` | Security-Audit der Branch-Aenderungen | Jedem PR (PFLICHT)        |
| `/verify`          | Feature im Browser/App testen         | Feature-Abnahme (PFLICHT) |
| `/run`             | App starten und Golden Path pruefen   | Feature-Abnahme           |

## Built-in Utility Skills

| Skill         | Wann nutzen                            | Pflicht bei        |
| ------------- | -------------------------------------- | ------------------ |
| `/init`       | CLAUDE.md fuer neues Projekt erstellen | Projekt-Setup      |
| `/loop`       | Recurring Tasks auf Intervall          | Monitoring/Polling |
| `/claude-api` | Claude API/Anthropic SDK Integration   | API-Anbindung      |

## Quality Gate Reihenfolge (PFLICHT vor PR)

1. `pnpm lint && pnpm typecheck && pnpm test` — Automatisierte Checks
2. `/code-review --effort high` — Correctness-Bugs
3. `/security-review` — Security-Schwachstellen
4. `/verify` — Feature manuell testen
5. CHANGELOG.md [Unreleased] aktualisieren
