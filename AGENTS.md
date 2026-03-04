# AGENTS.md

Dieses Projekt nutzt AI-gestützte Entwicklung mit klar definierten Rollen und Regeln.
Alle AI Coding Agents (Claude Code, Codex, Cursor, etc.) MÜSSEN diese Regeln befolgen.

## Architektur: Feature-Sliced Design in Turborepo Monorepo

Dieses Projekt ist ein Monorepo mit drei Apps und vier Shared Packages.
Die Web-App nutzt Feature-Sliced Design (FSD) mit strikter Layer-Hierarchie.

### FSD Import-Regeln (STRIKT)

```
app → kann alles importieren
routes → pages, widgets, features, entities, shared
pages → widgets, features, entities, shared
widgets → features, entities, shared
features → entities, shared
entities → shared
shared → nur shared
```

Verstöße gegen diese Regeln werden vom ESLint `boundaries` Plugin als ERROR gemeldet.

### Shared Packages

- `@repo/shared-types` — EINZIGE Quelle für TypeScript Types und Zod Schemas
- `@repo/shared-ui` — Gemeinsame UI-Komponenten
- `@repo/shared-api` — API Client und Query Factories
- `@repo/config` — Shared Konfigurationen

Types werden NIEMALS in einer App dupliziert. Immer `@repo/shared-types` nutzen.

## Dokumentations-Pflichten

Jeder Agent MUSS bei Änderungen:

1. `CHANGELOG.md` — Abschnitt `[Unreleased]` aktualisieren
2. `docs/decisions/` — ADR erstellen bei Architektur-Entscheidungen
3. `.scrum/` — Task-Dateien zwischen Ordnern verschieben
4. JSDoc — Auf allen exportierten Funktionen, Komponenten und Types

## Scrum-Board (.scrum/)

Das Scrum-Board liegt auf der Root-Ebene. ALLE Agents sehen es.
Tasks sind Markdown-Dateien die zwischen Ordnern verschoben werden:

```
.scrum/backlog/     → Neue Aufgaben
.scrum/in-progress/ → Wird gerade bearbeitet
.scrum/review/      → Wartet auf Review
.scrum/done/        → Abgeschlossen
```

Vor Arbeitsbeginn: Prüfe `.scrum/in-progress/` um Konflikte zu vermeiden.

## Code-Qualität

- TypeScript strict mode — kein `any`, kein `@ts-ignore`
- Tests für jeden Export (Vitest + Testing Library)
- Code-Duplikation unter 5% (jscpd)
- ESLint FSD Boundaries müssen grün sein
- Conventional Commits sind Pflicht

## Slash Commands (Skills)

Alle Agents können diese projektweiten Skills nutzen:

- `/scrum` — Sprint-Board verwalten (show, move, create, status)
- `/new-feature [beschreibung]` — Feature anlegen (FSD-konform, Scrum-Task, Workflow-Stufe)
- `/review [pfad]` — Code Review (FSD, Types, Duplikation, Tests, JSDoc)
- `/commit [nachricht]` — Smart Commit (Checks, Conventional Commit, Changelog)

Skills liegen in `.claude/skills/` und werden mit Template-Sync aktualisiert.

## MCP-Server

Vorkonfigurierte externe Tools in `.claude/.mcp.json`:

- **GitHub** — Issues erstellen, PRs verwalten, Branches steuern
- **Prisma** — Datenbank-Migrationen, Schema-Introspection
- **Context7** — Aktuelle Dokumentation von TanStack, Hono, etc. abrufen
- **Playwright** — Browser-Automatisierung und E2E-Tests
