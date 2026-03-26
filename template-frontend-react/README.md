# {{PROJECT_NAME}} — Frontend

> React 19 + Vite + TanStack Router/Query + Feature-Sliced Design

## Setup

```bash
cp .env.example .env
# Edit .env: Set VITE_API_URL to your backend develop instance
pnpm install
pnpm dev
```

## Befehle

| Befehl                    | Beschreibung                     |
| ------------------------- | -------------------------------- |
| `pnpm dev`                | Dev Server (Vite)                |
| `pnpm build`              | Production Build                 |
| `pnpm test`               | Tests (Vitest)                   |
| `pnpm lint`               | ESLint + FSD Boundaries          |
| `pnpm typecheck`          | TypeScript strict                |
| `pnpm generate:api-types` | API Types aus OpenAPI generieren |

## Architektur

```
src/
├── app/         — Providers, Styles, Root
├── routes/      — TanStack Router (duenne Wrapper)
├── pages/       — FSD Pages
├── widgets/     — FSD Widgets
├── features/    — FSD Features (Mutations)
├── entities/    — FSD Entities (Queries)
└── shared/      — Utils, Config, UI
```

**Import-Regel:** Nur von niedrigeren zu hoeheren Layern.

## API-Types

Types werden aus OpenAPI Specs generiert:

```bash
pnpm generate:api-types
```

Die generierten Types liegen in `generated/api-types.ts`.
