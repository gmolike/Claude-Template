# Changelog

Alle wesentlichen Änderungen werden hier dokumentiert.
Format basiert auf [Keep a Changelog](https://keepachangelog.com/de/1.1.0/).

## [Unreleased]

### Added

- **Claude Code Monitor** — VS Code Sidebar-Extension als `apps/vscode-session` integriert (Fork von claude-code-session, MIT)
  - Live Session-Monitoring mit Pixel-Art Robot Companion
  - Token Usage Meters (5h Session + 7d Weekly) mit Pace-Based Coloring
  - Token Activity Chart mit konfigurierbaren Zeitfenstern
  - Git Status, MCP Servers, Skills Browser, CLI Tools
  - **Scrum Board Integration** — `.scrum/` Tasks direkt in der Sidebar anzeigen und Status aendern
  - **FSD Layer Monitor** — Zeigt welche Feature-Sliced Design Layer in der Session bearbeitet wurden
  - **Agent Orchestration Status** — tmux Sessions und Agent-Status live anzeigen
  - Workspace-File `vscode-ext.code-workspace` fuer Extension-Entwicklung
  - Convenience-Scripts: `pnpm ext:build`, `pnpm ext:watch`, `pnpm ext:package`, `pnpm ext:deploy`
- Initiale Projektstruktur aus Template erstellt
- **Animation Designer Agent** (opusplan) — orchestriert alle Animation-Skills ueber Web, Mobile und Video
- **Animation Designer Skill** — /animation-designer mit Modes: audit, plan, implement, review
- **Emil Kowalski Design Engineering Skill** — UI-Polish, Easing, Component Design Prinzipien
- **Taste Skill Suite** (12+ Skills) — Anti-Slop Frontend Framework inkl. brandkit, imagegen, design-taste
- **HyperFrames Video Suite** (15+ Skills) — HTML-to-Video, GSAP, Three.js, Lottie, WAAPI, Anime.js
- **Flutter Animations Skill** — Implicit/Explicit/Hero/Physics Animations
- **CSS Animation Skill** — Selbststaendige HTML/CSS Walkthrough-Demos
- **Changelog Generator Skill** — Release Notes aus Git-History
- **Impeccable Combined Skill** — Meta-Skill fuer Design, Redesign, Critique, Audit, Polish
- **opus47-agents.md** Rule — Built-in Agent Types, Quality Gates, Worktree-Isolation
- **Three.js** (v0.184.0 + @types/three) in apps/web fuer 3D/WebGPU
- **Migrations-Guide** `docs/migration/TMPL-300-opus47-migration.md` fuer geklonte Repos
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
- Offizieller shadcn/ui Skill integriert (CLI v4, Component Discovery, Registry Workflow)
- Vercel Web-Design-Guidelines Skill integriert (100+ WCAG/UX Regeln, Live-Fetch)
- ADR 0003: Evaluierung von 4 Design-Skills (shadcn/ui, WDG, AccessLint, UI/UX Pro Max)
- TMPL-301 Scrum-Ticket für Skills-Integration
- `settings.local.json.example` als Muster für lokale Permission-Overrides (TMPL-201)
- `pnpm-workspace.yaml` mit optionalem web-player Eintrag (TMPL-202)
- `scripts/tmux-setup.sh` Template für tmux-Session-Erstellung (TMPL-202)

### Changed

- **Projekt-Override der Session-Defaults entfernt** (`.claude/settings.json`): die sechs von `agent-core sync --scope project` geseedeten Keys `model`, `fallbackModel`, `effortLevel`, `ultracode`, `disableWorkflows`, `dynamicWorkflowSize` sind gelöscht. In der Präzedenz `Managed > CLI > Local > Project > User` sticht eine Projektdatei das User-Setting — das Projekt lief damit weiter auf `claude-fable-5[1m]`, obwohl global Opus 5 kanonisch ist (agent-core ADR-0033). Ohne die Keys erbt das Projekt das User-Setting und folgt künftigen Modellwechseln automatisch. Der Mechanismus-Fix (Scope-Unterscheidung in `mergeClaudeSettings`) gehört nach agent-core und ist hier bewusst nicht enthalten
  - **Dieselben sechs Keys auch aus allen sechs Template-Gerüsten entfernt** — `template-backend-dotnet`, `template-backend-hono`, `template-frontend-react`, `template-mobile-rn`, `template-orchestrator`, `template-shared-contracts` (je `.claude/settings.json`). Die Gerüste sind die eigentliche Fehlerquelle: jedes daraus gebootstrappte Projekt startete sofort wieder mit einem Projekt-Override, der die Nutzerwahl sticht — genau der Zustand, der in acht bestehenden Projekten von Hand aufgeräumt werden musste. Alle sechs trugen exakt den historischen Seed (`model` = `claude-fable-5[1m]`, `fallbackModel` = `["claude-opus-4-8[1m]", "default"]`, `effortLevel` = `xhigh`, `ultracode` = `true`, `disableWorkflows` = `false`, `dynamicWorkflowSize` = `medium`); kein Gerüst hatte einen abweichenden, bewusst gesetzten Wert. Nur die sechs Keys entfernt — Formatierung, Key-Reihenfolge, `permissions`, `hooks`, `mcpServers` und `statusLine` bleiben unangetastet
- **Alle npm-Pakete auf neueste Major-Versionen** aktualisiert (TypeScript 6, Vite 8, Vitest 4, ESLint 10, Prisma 7, Zod 4, commitlint 21, lint-staged 17)
- **Versionsinkonsistenzen bereinigt** zwischen Root und apps/web (vite, globals, jsdom, eslint-plugin-react-hooks, @vitejs/plugin-react, vite-tsconfig-paths)
- **Scrum Master Agent** erweitert um built-in subagent_type Mapping, Worktree-Isolation, Background Agents, Quality Skills
- **Designer Agent** erweitert um Emil Kowalski, Taste-Skills, ImageGen-Skills, Animation-Delegation
- **Senior QS Agent** erweitert um /code-review, /security-review, /verify Quality Gates
- **Senior Frontend Agent** erweitert um /verify, /run, Taste-Skills, Animation-Delegation
- **Senior Backend Agent** erweitert um /security-review, /verify, Zod 4 + Prisma 7 Migrations-Hinweise
- **token-efficiency.md** Rule erweitert um Animation Designer als opusplan Agent
- **CLAUDE.md** komplett ueberarbeitet mit 7 Skill-Kategorien (57+ Skills dokumentiert)
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
