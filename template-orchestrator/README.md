# {{PROJECT_NAME}} — Orchestrator

> Projektsteuerung, Sprint-Management und Cross-Repo Koordination.

## Was ist dieses Repo?

Das Orchestrator-Repo ist das zentrale Steuerungs-Repo fuer {{PROJECT_NAME}}. Es enthaelt **keinen Anwendungscode**, sondern:

- **Sprint-Board** (`.scrum/`) — Tasks planen, priorisieren, tracken
- **Architektur-Entscheidungen** (`docs/decisions/`) — ADRs im MADR-Format
- **API-Contracts** (`docs/contracts/openapi/`) — OpenAPI Specs als Single Source of Truth
- **Guides** (`docs/guides/`) — Setup, Workflows, Agent-Hierarchie

## Zugehoerige Repos

| Repo                         | Beschreibung            |
| ---------------------------- | ----------------------- |
| `{{PROJECT_NAME}}-web`       | React + FSD Frontend    |
| `{{PROJECT_NAME}}-api`       | .NET / Hono Backend     |
| `{{PROJECT_NAME}}-mobile`    | React Native + Expo     |
| `{{PROJECT_NAME}}-contracts` | OpenAPI Specs + Codegen |

## Setup

```bash
./scripts/init-project.sh
```

Das Script fragt nach Projektname und GitHub-User und ersetzt alle `{{PROJECT_NAME}}` Platzhalter.

## Claude Code Agent Teams

Oeffne dieses Repo in Claude Code. Die Agents (PO, SM, Designer) sind vorkonfiguriert.

```
/scrum show          # Sprint-Board anzeigen
/scrum create [titel] # Neuen Task erstellen
/scrum move [id] [status] # Task verschieben
```
