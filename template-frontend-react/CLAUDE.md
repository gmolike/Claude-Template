# {{PROJECT_NAME}} — Frontend

React 19 + Vite + TanStack Router/Query + Feature-Sliced Design.

## HARD RULES

- Dieses Repo enthaelt NUR Frontend-Code
- KEINE API-Logik, KEINE Datenbank-Zugriffe
- API wird IMMER ueber den generierten Client angesprochen
- API-Types kommen aus `generated/api-types.ts` (OpenAPI Codegen)
- NIEMALS Types manuell definieren die aus der API kommen
- Backend laeuft als externe Develop-Instanz, NICHT lokal

## Architektur: Feature-Sliced Design

**Layer-Hierarchie (STRIKT):**
app → routes → pages → widgets → features → entities → shared

**Import-Regeln:**

- Imports NUR von niedrigeren zu hoeheren Layern
- Kein Cross-Import zwischen Slices
- Jeder Slice hat eine `index.ts` Public API (Barrel File)
- ESLint Boundaries Plugin erzwingt diese Regeln

**Path Aliases:**
`@app/`, `@pages/`, `@widgets/`, `@features/`, `@entities/`, `@shared/`

## API-Anbindung

- API-Base-URL in `.env`: `VITE_API_URL=https://dev.{{PROJECT_NAME}}.example.com/api`
- Types generiert aus OpenAPI Spec: `pnpm run generate:api-types`
- Query Factories in `src/entities/` mit `queryOptions()`
- Mutations in `src/features/`

## Agents

| Agent           | Model      | Rolle                                               |
| --------------- | ---------- | --------------------------------------------------- |
| Senior Frontend | sonnetplan | Plant FSD-Struktur, implementiert komplexe Features |
| Worker Frontend | sonnet     | Implementiert nach Spec, schreibt Komponenten       |
| Worker QS       | sonnet     | Schreibt Tests (Vitest + Testing Library)           |
| Debugger        | sonnet     | Analysiert und fixt Bugs                            |

## Befehle

- `pnpm dev` — Dev Server starten (Vite)
- `pnpm build` — Production Build
- `pnpm test` — Tests (Vitest)
- `pnpm lint` — ESLint mit FSD Boundaries
- `pnpm typecheck` — TypeScript strict
- `pnpm generate:api-types` — API Types aus OpenAPI Spec generieren

## Coding-Standards

- TypeScript `strict: true` — kein `any`, kein `@ts-ignore`
- Path Aliases: `@app/`, `@pages/`, `@widgets/`, `@features/`, `@entities/`, `@shared/`
- Jeder FSD-Slice hat eine `index.ts` Public API
- TanStack Query: Query Factory Pattern mit `queryOptions()` in entities
- Mutations in `features/` Layer
- Routes in `src/routes/` sind DUENNE Wrapper — Logik lebt in FSD pages
- Conventional Commits: `feat:`, `fix:`, `docs:`, `chore:`
- JSDoc auf allen exportierten Funktionen und Komponenten

## MCP-Server

- **GitHub** — Issues, PRs, Branches
- **Context7** — TanStack, React, Vite Doku
- **Playwright** — E2E Tests
