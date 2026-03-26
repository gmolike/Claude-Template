# {{PROJECT_NAME}} — Mobile App

React Native + Expo + TanStack Query + FSD-adaptierte Architektur.

## HARD RULES

- Dieses Repo enthaelt NUR Mobile-Code
- KEINE Web-spezifische Logik, KEIN react-dom
- API wird ueber den generierten Client angesprochen
- API-Types kommen aus `generated/api-types.ts` (OpenAPI Codegen)
- Backend laeuft als externe Develop-Instanz

## Architektur (FSD-adaptiert)

```
src/
├── app/         — App Entry, Providers, Navigation
├── screens/     — Screen-Komponenten (≈ FSD Pages)
├── features/    — Business Logic, Mutations
├── entities/    — Domain Models, Queries
└── shared/      — Utils, Config, UI Components, API Client
```

**Import-Regeln (wie FSD):**

- screens → features, entities, shared
- features → entities, shared
- entities → shared
- shared → nur shared

## Agents

| Agent           | Model      | Rolle                             |
| --------------- | ---------- | --------------------------------- |
| Senior Frontend | sonnetplan | Plant Architektur, implementiert  |
| Worker Frontend | sonnet     | Implementiert Screens, Components |
| Worker QS       | sonnet     | Schreibt Tests                    |
| Debugger        | sonnet     | Analysiert und fixt Bugs          |

## Befehle

- `pnpm start` — Expo Dev Server
- `pnpm android` — Android Emulator
- `pnpm ios` — iOS Simulator
- `pnpm test` — Tests (Jest)
- `pnpm lint` — ESLint
- `pnpm typecheck` — TypeScript strict
- `pnpm generate:api-types` — API Types generieren

## MCP-Server

- **GitHub** — Issues, PRs
- **Context7** — React Native, Expo Doku
