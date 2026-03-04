---
status: accepted
date: 2026-03-01
decision-makers: [project-lead]
---

# FSD Monorepo-Architektur mit Claude Code Agent Teams

## Kontext

Wir brauchen eine Projektstruktur die:

1. Web, API und Mobile Apps in einem Repository verwaltet
2. Code-Duplikation zwischen Apps verhindert (Shared Types, UI, API)
3. AI-gestützte Entwicklung mit klar definierten Agent-Rollen unterstützt
4. Strikte Architektur-Grenzen erzwingt (ESLint Boundaries)

## Entscheidung

Turborepo + pnpm Workspaces Monorepo mit Feature-Sliced Design
in der Web App und Claude Code Agent Teams für die Entwicklung.

## Konsequenzen

### Positiv

- Single Source of Truth für Types (Zod Schemas in shared-types)
- FSD Layer mapppen natürlich auf Agent-Rollen
- ESLint Boundaries verhindern Architektur-Verstöße
- Turborepo Cache beschleunigt Builds

### Negativ

- Höhere Einstiegskomplexität
- FSD hat Lernkurve
- Monorepo-Tooling erfordert Wartung
