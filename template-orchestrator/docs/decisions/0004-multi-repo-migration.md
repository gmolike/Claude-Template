---
status: accepted
date: 2026-03-26
decision-makers: [project-lead]
supersedes: ADR-0000
---

# Multi-Repo Migration: Von Monorepo zu spezialisierten Repo-Templates

## Kontext

Das Turborepo Monorepo zeigte fundamentale Probleme:

1. **Agent-Grenzueberschreitungen** — Claude Code Agents wandern ueber Domaenengrenzen
2. **Kein Polyglot-Support** — .NET/C# Backend nicht moeglich mit Turborepo
3. **Branch-Chaos** — 20 Agents = 300+ geaenderte Files in einem Branch
4. **tmux ist ein Hack** — Claude Code Teams bietet native Agent-Hierarchie

## Entscheidung

Migration von Turborepo Monorepo zu Multi-Repo mit Package Registry fuer Shared Contracts.

### Ziel-Architektur

| Repo-Template             | Inhalt                           | Agents                          |
| ------------------------- | -------------------------------- | ------------------------------- |
| template-orchestrator     | Planung, Tickets, Contracts      | PO, SM, Designer                |
| template-frontend-react   | React + FSD + TanStack           | Sr. FE, Worker FE, QS, Debugger |
| template-backend-dotnet   | .NET + Clean Architecture + CQRS | Sr. BE, Worker BE, QS, Debugger |
| template-backend-hono     | Hono + Prisma (leichtgewichtig)  | Sr. BE, Worker BE, QS, Debugger |
| template-mobile-rn        | React Native + Expo              | Sr. FE, Worker FE, QS, Debugger |
| template-shared-contracts | OpenAPI Specs, Codegen           | Sr. BE                          |

### Kommunikation zwischen Repos

- **Tickets:** GitHub Issues mit Cross-Repo Labels
- **Types:** OpenAPI Codegen (openapi-typescript fuer TS, NSwag fuer C#)
- **Orchestrierung:** Claude Code Teams statt tmux

## Konsequenzen

### Positiv

- Jeder Claude Code Chat hat klar definierten Scope
- Backend und Frontend komplett unabhaengig entwickelbar
- .NET/C# Backend erstklassig unterstuetzt
- Kleinere, reviewbare PRs
- Template-Sync pro Repo-Template

### Negativ

- Shared Types brauchen Publish-Pipeline (npm/NuGet/OpenAPI codegen)
- Contract-Aenderungen erfordern koordinierte Releases
- Kein "one click dev start" — jedes Repo startet separat

### Was bleibt unveraendert

- Model-Tiering (opusplan/sonnetplan/sonnet)
- FSD fuer React Frontend
- Conventional Commits
- ADRs im MADR-Format
- Workflow-Stufen (Bugfix/Lite/Full Scrum)
