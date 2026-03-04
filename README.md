# claude-template

> Turborepo Monorepo mit React + FSD, Hono, React Native

## Tech-Stack

| Bereich     | Technologie                                          |
| ----------- | ---------------------------------------------------- |
| Web         | React 19 + TypeScript + Vite + TanStack Router/Query |
| Architektur | Feature-Sliced Design (FSD)                          |
| API         | Hono + Prisma + PostgreSQL                           |
| Mobile      | React Native + Expo (Platzhalter)                    |
| Monorepo    | Turborepo + pnpm Workspaces                          |
| AI Dev      | Claude Code Agent Teams                              |
| CI/CD       | GitHub Actions + Jenkins                             |
| Qualität    | ESLint Boundaries + jscpd + DRYwall                  |

## Schnellstart

```bash
pnpm install
cp .env.example .env
docker compose up db -d
pnpm dev
```

## Projektstruktur

```
├── apps/
│   ├── web/          ← React + FSD
│   ├── api/          ← Hono Backend
│   └── mobile/       ← React Native (Platzhalter)
├── packages/
│   ├── shared-types/ ← Zod Schemas + Types (Single Source of Truth)
│   ├── shared-ui/    ← Gemeinsame Komponenten
│   ├── shared-api/   ← API Client + Query Factories
│   └── config/       ← Shared Configs
├── .claude/agents/   ← Agent Team Definitionen
├── .scrum/           ← Scrum Board (Dateien)
├── docs/             ← ADRs, Guides
└── workspaces/       ← VS Code Team-Configs
```

## Agent Workflow

```bash
claude                                    # Claude Code starten

# Slash Commands (Skills):
/scrum                                    # Sprint-Board anzeigen
/scrum create Login implementieren        # Neuen Task anlegen
/new-feature User-Profil mit Avatar       # Feature FSD-konform scaffolden
/review apps/web/src/features/            # Code Review nach Standards
/commit                                   # Smart Commit mit Changelog

# Workflow-Stufen:
"Bugfix: [Problem]"                       # Stufe 1 — schnell, 1 Agent
"Lite Feature: [Was]"                     # Stufe 2 — Senior + QS
"Full Scrum: [Anforderung]"               # Stufe 3 — volles Team
```

## MCP-Server (vorkonfiguriert)

| MCP        | Nutzen                               |
| ---------- | ------------------------------------ |
| GitHub     | Issues, PRs, Branches direkt steuern |
| Prisma     | Migrationen, Schema, Studio          |
| Context7   | Aktuelle Library-Doku abrufen        |
| Playwright | Browser-Tests ausführen              |

Config: `.claude/.mcp.json` — `GITHUB_TOKEN` in `.env` setzen.

## VS Code Workspaces

Jedes Team hat einen eigenen farbcodierten Workspace:

| Workspace                 | Farbe     | Für                  |
| ------------------------- | --------- | -------------------- |
| `team.code-workspace`     | Grau      | Lead / Übersicht     |
| `frontend.code-workspace` | 🔵 Blau   | Frontend-Entwicklung |
| `backend.code-workspace`  | 🟢 Grün   | Backend-Entwicklung  |
| `qa.code-workspace`       | 🟠 Orange | Qualitätssicherung   |
| `designer.code-workspace` | 🩷 Pink   | UI/UX Design         |
| `po.code-workspace`       | 🟣 Lila   | Product Owner        |

## Lizenz

MIT
