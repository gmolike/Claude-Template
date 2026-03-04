# claude-template

Turborepo Monorepo mit React + FSD (Web), Hono (API), React Native (Mobile).
Shared Packages für Types, UI, API-Client. pnpm Workspaces.

## Architektur

**Monorepo-Struktur:**

- `apps/web` — React 19 + Vite + TanStack Router/Query + FSD
- `apps/api` — Hono + Prisma + PostgreSQL
- `apps/mobile` — React Native + Expo
- `packages/shared-types` — Zod Schemas + TypeScript Types (Single Source of Truth)
- `packages/shared-ui` — Gemeinsame UI-Komponenten
- `packages/shared-api` — API Client, Query Factories
- `packages/config` — Shared ESLint, TS, Prettier Configs

**FSD Layer (apps/web):** app → routes → pages → widgets → features → entities → shared
Imports NUR von niedrigeren zu höheren Layern. Kein Cross-Import zwischen Slices.

## Befehle

- `pnpm dev` — Alle Apps starten
- `pnpm build` — Alles bauen (mit Turbo-Cache)
- `pnpm test` — Alle Tests (Vitest)
- `pnpm lint` — ESLint mit FSD Boundary-Checks
- `pnpm typecheck` — TypeScript strict prüfen
- `pnpm cpd` — Code-Duplikation prüfen (jscpd)
- `turbo run dev --filter=web` — Nur Web starten
- `turbo run dev --filter=api` — Nur API starten

## Coding-Standards

- TypeScript `strict: true` — kein `any`, kein `@ts-ignore`
- Path Aliases: `@app/`, `@pages/`, `@widgets/`, `@features/`, `@entities/`, `@shared/`
- Jeder FSD-Slice hat eine `index.ts` Public API (Barrel File)
- TanStack Query: Query Factory Pattern mit `queryOptions()` in entities
- Mutations gehören in `features/` Layer
- Routes in `src/routes/` sind DÜNNE Wrapper — Logik lebt in FSD pages
- Conventional Commits: `feat:`, `fix:`, `docs:`, `chore:`, etc.
- JSDoc auf allen exportierten Funktionen und Komponenten
- Keine hardcodierten Werte — alles in `shared/config/`

## Shared Packages — Single Source of Truth

- **Types/Schemas** IMMER in `packages/shared-types` definieren
- Web, API und Mobile importieren DIESELBEN Types
- Zod Schemas für Runtime-Validierung UND Type-Inference
- API-Contracts werden EINMAL definiert, nicht dupliziert

## Datenbank

- EINE PostgreSQL-Datenbank für alle Apps
- Prisma Schema in `apps/api/prisma/schema.prisma`
- Migrationen: `turbo run db:migrate --filter=api`
- Generated Types fließen in `packages/shared-types`

## Dokumentation — PFLICHT

- CHANGELOG.md `[Unreleased]` bei JEDER Änderung aktualisieren
- ADR in `docs/decisions/` bei Architektur-Entscheidungen erstellen
- Scrum-Board in `.scrum/` pflegen (Dateien zwischen Ordnern verschieben)
- `project-standards.md` ist die Referenz für alle Agents

## Agent Workflow-Stufen

**Stufe 3 — Full Scrum:** `Full Scrum: [Anforderung]`
PO → Seniors (parallel) → Workers (parallel) → Senior Review → PO Review

**Stufe 2 — Lite:** `Lite Feature: [Was]`
PO (kurz) → relevanter Senior implementiert selbst → QS

**Stufe 1 — Bugfix:** `Bugfix: [Problem]`
Senior analysiert → Worker fixt → Senior reviewed

## Token-Effizienz — HARD RULES

- PO / Scrum Master: `opusplan` — IMMER Planning-First
- Seniors: `sonnetplan` — Planen, dann implementieren
- Workers: `sonnet` — Reiner Code, keine Planung
- Kein Full Scrum für Tasks < 5 Dateien
- Nur relevante Seniors einbeziehen (nicht jedes Feature braucht Designer)

## Git

- Ein PR pro Feature/Fix
- `pnpm lint && pnpm typecheck && pnpm test` vor jedem Commit (Husky)
- Code-Duplikation unter 5% halten (jscpd in CI)

## Slash Commands (Skills)

- `/scrum` — Sprint-Board anzeigen, Tasks verschieben/erstellen
- `/new-feature [beschreibung]` — Feature FSD-konform anlegen + Scrum-Task + Workflow-Stufe
- `/review [pfad]` — Code Review: FSD-Layer, Types, Duplikation, Tests, JSDoc
- `/commit [nachricht]` — Smart Commit: Status, Lint, Typecheck, Conventional Commit, Changelog

Alle Skills liegen in `.claude/skills/` und werden mit `/` im Claude Code Terminal aufgerufen.

## MCP-Server (vorkonfiguriert)

- **GitHub** — Issues, PRs, Branches direkt aus Claude Code (`GITHUB_TOKEN` in `.env` nötig)
- **Prisma** — Migrationen, Schema-Introspection, Prisma Studio
- **Context7** — Aktuelle Doku von Libraries abrufen (z.B. TanStack, Hono)
- **Playwright** — Browser-Tests ausführen und debuggen

MCP-Config: `.claude/.mcp.json` — wird mit Template-Sync aktualisiert.
