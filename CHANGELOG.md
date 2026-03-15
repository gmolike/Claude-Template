# Changelog

Alle wesentlichen Änderungen werden hier dokumentiert.
Format basiert auf [Keep a Changelog](https://keepachangelog.com/de/1.1.0/).

## [Unreleased]

### Added

- Initiale Projektstruktur aus Template erstellt
- Impeccable Design-Skills integriert (18 Slash-Commands für Design-Qualität via `pbakaus/impeccable`)
- Success Metrics und Deliverable-Templates für alle 10 Agent-Rollen
- Oh My Claude Code (OMC) als optionales Orchestrierungs-Plugin
- ADR 0001: Integration externer Agent-Tools (Evaluierungskriterien)
- ADR 0002: OMC Orchestrierungs-Plugin (Optional Dependency)
- Template-Kompatibilitäts-Kriterien für zukünftige Tool-Evaluierung
- tmux Multi-Instanz-Orchestrierung für domänenspezifische Claude-Code-Sessions (TMPL-202)
- Domain-CLAUDE.md für apps/web, apps/api, apps/mobile mit Workflow-Level-Routing (TMPL-202)
- `/design` Skill mit 4 Subcommands: briefing, concept, review, export (TMPL-203)
- Dotenv Vault als Standard-ENV-Management mit `dotenv.dotenv-vscode` Extension
- `settings.local.json.example` als Muster für lokale Permission-Overrides (TMPL-201)
- `pnpm-workspace.yaml` mit optionalem web-player Eintrag (TMPL-202)
- `scripts/tmux-setup.sh` Template für tmux-Session-Erstellung (TMPL-202)

### Changed

- Designer-Agent erweitert um Impeccable Skill-Referenzen und Anti-Pattern-Regeln
- Scrum Master Agent erweitert um OMC-Delegation (Optional)
- Token-Efficiency Rules erweitert um OMC-spezifische Regeln
- CLAUDE.md erweitert um Impeccable Commands und OMC-Integration
- TEMPLATE_SETUP.md erweitert um OMC-Installationsanleitung
- FSD-Architektur für Web App
- Hono API Backend
- React Native Mobile Platzhalter
- Shared Packages (Types, UI, API)
- Claude Code Agent Team Definitionen (10 Agents, 3 Tier-Stufen)
- Slash Commands: `/scrum`, `/new-feature`, `/review`, `/commit`
- MCP-Server: GitHub, Prisma, Context7, Playwright
- Scrum Board als Dateien (.scrum/)
- CI/CD (GitHub Actions + Jenkins)
- Code-Duplikation-Erkennung (jscpd + DRYwall)
- VS Code Workspaces: von 6 gruppierten auf 8 granulare Domänen-Workspaces (TMPL-201)
- Docker Setup (Web + API + PostgreSQL)
- Template-Sync Workflow (wöchentlich)
- `.claude/settings.json` Permissions-Overhaul: erweiterte allow-Liste, reduzierte deny-Liste (TMPL-201)
- `.scrum/` von flacher auf domänenbasierte Ordnerstruktur migriert (web, api, mobile, shared, content) (TMPL-202)
- `BOARD.md` mit Beispiel-Epic und Abhängigkeitsbaum (TMPL-202)
- `/scrum` Skill unterstützt domänenbasierte Pfade mit `--domain` Parameter (TMPL-202)
- Designer-Agent: kollaborativer 3-Stufen-Canva-Workflow statt generischer Spec-Maschine (TMPL-203)
- `package.json`: `pnpm.overrides` mit `{{REACT_VERSION}}` Platzhalter (TMPL-201)
- `init.sh`: React-Version Abfrage und Platzhalter-Ersetzung (TMPL-201)
- Alle Workspaces empfehlen Dotenv Official VS Code Extension

### Removed

- `backend.code-workspace` und `frontend.code-workspace` (ersetzt durch granulare Domänen-Workspaces) (TMPL-201)
- Flache `.scrum/{backlog,in-progress,done}` Ordner (ersetzt durch `.scrum/<domäne>/`) (TMPL-202)

## [0.1.0] - {{CREATION_DATE}}

### Added

- Projekt aus Template erstellt
