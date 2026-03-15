# API (apps/api)

Hono + Prisma + PostgreSQL REST API.

## Struktur

- `src/routes/` — Hono Route Handler
- `src/services/` — Business Logic
- `src/middleware/` — Auth, Validation, Error Handling
- `prisma/schema.prisma` — Datenbankschema
- `prisma/migrations/` — Migrationen

## Befehle

- `turbo run dev --filter=api` — API starten
- `turbo run db:migrate --filter=api` — Migrationen ausführen
- `turbo run db:seed --filter=api` — Seed-Daten

## Workflow-Level-Routing

### Level 3 — Full Scrum (5+ Dateien, mehrere Layer)

PO erstellt Spec → Seniors planen parallel → Workers implementieren → QS → PO Review
**Team:** Scrum Master, PO, Sr. Frontend, Sr. Backend, Workers, Sr. QS

### Level 2 — Lite (2–5 Dateien, klares Scope)

Senior plant + implementiert selbst → QS reviewed
**Team:** Relevanter Senior + Sr. QS

### Level 1 — Bugfix (1–2 Dateien, klar lokalisiert)

Debugger analysiert + fixt → Senior reviewed
**Team:** Debugger + relevanter Senior
