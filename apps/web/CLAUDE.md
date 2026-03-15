# Web App (apps/web)

React 19 + Vite + TanStack Router/Query + FSD Architecture.

## FSD Layer

- `src/app/` — App-Konfiguration, Provider, Router
- `src/routes/` — TanStack Router Definitionen (dünne Wrapper)
- `src/pages/` — Seitenlogik und Layout
- `src/widgets/` — Zusammengesetzte UI-Bereiche
- `src/features/` — User-Interaktionen, Mutations
- `src/entities/` — Domain-Modelle, Query Factories
- `src/shared/` — UI-Primitives, Utilities, Config

## Path Aliases

`@app/`, `@pages/`, `@widgets/`, `@features/`, `@entities/`, `@shared/`

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
