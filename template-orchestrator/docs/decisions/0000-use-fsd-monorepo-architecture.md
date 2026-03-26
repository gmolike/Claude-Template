---
status: superseded by ADR-0004
date: 2026-03-01
decision-makers: [project-lead]
---

# FSD Monorepo-Architektur mit Claude Code Agent Teams

## Kontext

Wir brauchten eine Projektstruktur die Web, API und Mobile in einem Repository verwaltet.

## Entscheidung

Turborepo + pnpm Workspaces Monorepo mit Feature-Sliced Design.

## Status

**Superseded** durch ADR-0004 (Multi-Repo Migration). Siehe docs/decisions/0004-multi-repo-migration.md.

## Konsequenzen

### Positiv (historisch)

- Single Source of Truth fuer Types
- FSD Layer mapppen auf Agent-Rollen
- ESLint Boundaries verhindern Architektur-Verstoesse

### Negativ (fuehrte zu Migration)

- Agent-Grenzueberschreitungen bei 20+ Agents
- Kein Polyglot-Support (.NET nicht moeglich)
- Branch-Chaos bei Parallelarbeit
- tmux-Orchestrierung war ein Hack
