# {{PROJECT_NAME}} — Backend API (Hono)

Hono + Prisma + PostgreSQL. Leichtgewichtige TypeScript-Alternative zum .NET Backend.

## HARD RULES

- Dieses Repo enthaelt NUR Backend-Code
- KEINE Frontend-Logik, KEIN React
- Business Logic im Service-Layer, NICHT in Routes
- Zod fuer Input-Validierung auf allen Endpunkten
- Jeder Endpoint generiert OpenAPI/Swagger Spec
- API-Types kommen aus dem Contracts-Repo (oder werden hier generiert)

## Architektur

```
src/
├── routes/       — API-Endpunkte (duenn, delegiert an Services)
├── services/     — Business Logic
├── middleware/    — Auth, Validation, Error Handling
├── db/           — Prisma Schema + Client
├── validators/   — Zod Schemas fuer Input-Validierung
└── index.ts      — Server Entry Point
```

## Agents

| Agent          | Model      | Rolle                                |
| -------------- | ---------- | ------------------------------------ |
| Senior Backend | sonnetplan | Plant API-Architektur, implementiert |
| Worker Backend | sonnet     | Implementiert Routes, Services       |
| Worker QS      | sonnet     | Schreibt Tests (Vitest)              |
| Debugger       | sonnet     | Analysiert und fixt Bugs             |

## Befehle

- `pnpm dev` — Dev Server (mit Hot Reload)
- `pnpm build` — Production Build
- `pnpm test` — Tests (Vitest)
- `pnpm lint` — ESLint
- `pnpm typecheck` — TypeScript strict
- `pnpm db:migrate` — Prisma Migrationen anwenden
- `pnpm db:generate` — Prisma Client generieren
- `pnpm db:studio` — Prisma Studio oeffnen

## Wann Hono statt .NET?

- Kleine Projekte / Prototypen
- Cloudflare Workers Deployment
- Team kann nur TypeScript
- Prisma statt EF Core bevorzugt

## MCP-Server

- **GitHub** — Issues, PRs
- **Prisma** — Schema Introspection, Migrations
- **Context7** — Hono, Prisma Doku
