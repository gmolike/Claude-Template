# Projektweite Standards

## Version 2.0.0

## Architektur

Multi-Repo mit spezialisierten Repo-Templates:

- **Orchestrator** — Planung, Tickets, Contracts (dieses Repo)
- **Frontend** — React + FSD + TanStack
- **Backend** — .NET Clean Architecture ODER Hono + Prisma
- **Contracts** — OpenAPI Specs als Single Source of Truth
- **Mobile** — React Native + Expo

## Kommunikation zwischen Repos

- GitHub Issues mit Labels (`repo:frontend`, `repo:backend`, `repo:contracts`)
- API-Contracts als OpenAPI Specs (nicht manuell definierte Types)
- Codegen fuer TypeScript (openapi-typescript) und C# (NSwag)

## Coding-Konventionen

### TypeScript (Frontend + Hono)

- `strict: true` — keine Kompromisse
- Kein `any` — nutze `unknown` + Type Guards
- Kein `@ts-ignore` oder `@ts-expect-error`

### C# (.NET Backend)

- Clean Architecture Dependency Rule
- CQRS via MediatR
- Central Package Management

### Git (alle Repos)

- Conventional Commits (feat, fix, docs, chore, ci, test, refactor)
- Ein PR pro Feature/Fix
- Branch-Format: `feat/kurz-beschreibung`, `fix/kurz-beschreibung`

## Test-Standards

- Mindestabdeckung: 80%
- Test-Datei neben Source
- Alle States testen (Loading, Error, Empty, Success)

## Model-Tiering (HARD RULES)

- opusplan: PO, Scrum Master
- sonnetplan: Seniors, Designer
- sonnet: Workers, Debugger
