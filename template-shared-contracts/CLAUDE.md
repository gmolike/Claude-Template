# {{PROJECT_NAME}} — Shared Contracts

OpenAPI Specifications als Single Source of Truth fuer API Contracts.

## HARD RULES

- Dieses Repo enthaelt NUR API-Contract-Definitionen
- KEIN Anwendungscode, KEINE Business-Logik
- OpenAPI Specs in `openapi/` sind die EINZIGE Wahrheit
- Types werden GENERIERT, nie manuell geschrieben
- Jede Aenderung erfordert Validierung vor Merge

## Workflow

1. OpenAPI Spec in `openapi/` aendern
2. `pnpm validate` — Spec validieren
3. `pnpm generate` — TypeScript + C# Types generieren
4. PR erstellen + Review
5. Bei Merge: automatischer Publish auf npm + NuGet

## Generierte Packages

- **npm:** `@{{PROJECT_NAME}}/api-types` — TypeScript Types
- **NuGet:** `{{PROJECT_NAME}}.ApiContracts` — C# Interfaces

## Agents

| Agent          | Model      | Rolle                                |
| -------------- | ---------- | ------------------------------------ |
| Senior Backend | sonnetplan | Definiert und reviewed API Contracts |

## Befehle

- `pnpm validate` — OpenAPI Specs validieren
- `pnpm bundle` — Specs zu bundled.yaml zusammenfuegen
- `pnpm generate` — TypeScript + C# Types generieren
- `pnpm generate:ts` — Nur TypeScript
- `pnpm generate:csharp` — Nur C#

## MCP-Server

- **GitHub** — Issues, PRs

## Conventional Commits

Pflicht: `feat:`, `fix:`, `docs:`, `chore:`
