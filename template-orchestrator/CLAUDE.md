# {{PROJECT_NAME}} — Orchestrator

Dieses Repo steuert das Gesamtprojekt. Es enthaelt KEINEN Anwendungscode.

## Scope

- Projektplanung und Sprint-Management (.scrum/)
- Architektur-Entscheidungen (docs/decisions/)
- API-Contract-Definitionen (docs/contracts/openapi/)
- Cross-Repo Koordination via GitHub Issues

## Was hier NICHT passiert

- KEIN Anwendungscode (kein TypeScript, kein C#, kein React)
- KEINE Implementierung — nur Planung, Specs und Contracts
- KEINE direkten Code-Aenderungen an anderen Repos

## Agents in diesem Repo

| Agent         | Model      | Rolle                                                |
| ------------- | ---------- | ---------------------------------------------------- |
| Product Owner | opusplan   | Plant Features, schreibt Specs, erstellt Issues      |
| Scrum Master  | opusplan   | Koordiniert Sprint, verteilt Tasks als GitHub Issues |
| Designer      | sonnetplan | UI/UX Konzepte, Canva MCP, Design Specs              |

## Workflow: Cross-Repo Feature

1. PO erstellt Feature-Spec in `.scrum/backlog/`
2. PO erstellt GitHub Issues in den Ziel-Repos (Frontend, Backend, etc.)
3. Scrum Master verteilt Issues an die richtigen Repos
4. Jedes Repo bearbeitet seine Issues eigenstaendig
5. PO reviewed abgeschlossene Issues repo-uebergreifend

## Contract-Workflow

1. API-Contracts werden als OpenAPI Spec in `docs/contracts/openapi/` definiert
2. Bei Aenderung: CI validiert die Spec und published sie
3. Frontend-Repo generiert TypeScript-Types via openapi-typescript
4. Backend-Repo generiert C#-Interfaces via NSwag oder eigene Controller

## Workflow-Stufen (angepasst an Multi-Repo)

**Stufe 3 — Full Scrum** (repo-uebergreifend, komplexes Feature):
PO erstellt Spec → SM erstellt GitHub Issues in allen betroffenen Repos → Repos arbeiten parallel → PO reviewed

**Stufe 2 — Lite** (einzelnes Repo, klares Scope):
PO/SM erstellt GitHub Issue im Ziel-Repo → Repo arbeitet eigenstaendig

**Stufe 1 — Bugfix** (einzelnes Repo, 1-2 Dateien):
Issue direkt im betroffenen Repo erstellen → Repo fixt

## Model-Tiering (HARD RULES — unveraenderlich)

| Rolle             | Model      | Begruendung                      |
| ----------------- | ---------- | -------------------------------- |
| PO / Scrum Master | opusplan   | Tiefes Reasoning, Planning-First |
| Designer          | sonnetplan | Plant UI/UX                      |
| Senior (alle)     | sonnetplan | Plant, dann implementiert        |
| Worker (alle)     | sonnet     | Reiner Code-Output               |
| Debugger          | sonnet     | Fokussierter Fix                 |

## MCP-Server

- **GitHub** — Issues erstellen in allen Projekt-Repos
- **Canva** — Design-Erstellung mit 3-Stufen-Workflow

## Befehle

- `/scrum` — Sprint-Board verwalten (show, move, create, status)
- `/design briefing` — Design-Brief erstellen
- `/design concept` — Canva-Design generieren

## Conventional Commits

Pflicht in JEDEM Repo: `feat:`, `fix:`, `docs:`, `chore:`, `ci:`, `test:`, `refactor:`
