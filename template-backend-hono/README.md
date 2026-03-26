# {{PROJECT_NAME}} — Backend API (Hono)

> Hono + Prisma + PostgreSQL — leichtgewichtiges TypeScript Backend

## Setup

```bash
cp .env.example .env
docker-compose up -d    # PostgreSQL starten
pnpm install
pnpm db:migrate         # Migrationen anwenden
pnpm dev                # Dev Server starten
```

Swagger UI: http://localhost:3001/swagger

## Architektur

```
src/
├── routes/       — API-Endpunkte
├── services/     — Business Logic
├── middleware/    — Auth, Validation, Error
├── db/           — Prisma Schema + Client
├── validators/   — Zod Schemas
└── index.ts      — Entry Point
```
