# {{PROJECT_NAME}}

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

## tmux Multi-Instanz Orchestrierung

Der Root-Orchestrator (project.code-workspace) steuert domänenspezifische
Claude-Code-Instanzen über tmux-Sessions:

```
User ←→ Root-Orchestrator
         ├── tmux send-keys → {{PROJECT_NAME}}:web
         ├── tmux send-keys → {{PROJECT_NAME}}:api
         ├── tmux send-keys → {{PROJECT_NAME}}:mobile
         └── tmux send-keys → {{PROJECT_NAME}}:content
         └── tmux capture-pane ← Ergebnisse lesen
```

### Regeln

- JEDE Domäne läuft in eigener tmux-Session
- Root-Orchestrator delegiert NUR, implementiert NICHT selbst
- Ergebnisse werden via `tmux capture-pane` gelesen
- Bei Abhängigkeiten: sequentiell (shared → api → web/mobile)

### Optionale Domänen

- `web-player` — Kann bei Bedarf als zusätzliche Domäne aktiviert werden
  (siehe auskommentierte Einträge in `pnpm-workspace.yaml` und `project.code-workspace`)

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
- Animation Designer: `opusplan` — Kreative Motion-Strategie, Multi-Plattform
- Seniors: `sonnetplan` — Planen, dann implementieren
- Workers: `sonnet` — Reiner Code, keine Planung
- Kein Full Scrum für Tasks < 5 Dateien
- Nur relevante Seniors einbeziehen (nicht jedes Feature braucht Designer)
- Animation Designer NUR bei expliziten Animation-Tasks oder 3D/Video-Features

## OMC-Integration (Optional)

Oh My Claude Code kann als optionales Orchestrierungs-Plugin genutzt werden.
Template funktioniert AUCH ohne OMC. Wenn installiert:

- Stufe 1 → `ecomode` (Token-effizient)
- Stufe 2 → `ultrawork` (Parallele Execution)
- Stufe 3 → `autopilot` / `team` (Volle Autonomie)
- Model-Tiering wird NICHT von OMC überschrieben

## Environment Variables — Dotenv Vault

- **Dotenv Vault** als zentraler Secret-Manager für alle Umgebungen
- `.env` lokal für Entwicklung (NICHT committen)
- `.env.vault` verschlüsselt für Deployment (WIRD committet)
- `.env.keys` enthält Entschlüsselungskeys (NICHT committen)
- `.env.me` für persönliche Vault-Authentifizierung (NICHT committen)
- VS Code Extension: **Dotenv Official** (`dotenv.dotenv-vscode`) — Syntax-Highlighting, Auto-Cloaking
- Setup: `npx dotenv-vault new` → `npx dotenv-vault login` → `npx dotenv-vault push`
- Pull: `npx dotenv-vault pull`
- Deployment: `DOTENV_KEY` als einzige ENV-Variable im CI/CD setzen

## Git

- Ein PR pro Feature/Fix
- `pnpm lint && pnpm typecheck && pnpm test` vor jedem Commit (Husky)
- Code-Duplikation unter 5% halten (jscpd in CI)

## Slash Commands (Skills)

- `/scrum` — Sprint-Board anzeigen, Tasks verschieben/erstellen
- `/new-feature [beschreibung]` — Feature FSD-konform anlegen + Scrum-Task + Workflow-Stufe
- `/review [pfad]` — Code Review: FSD-Layer, Types, Duplikation, Tests, JSDoc
- `/commit [nachricht]` — Smart Commit: Status, Lint, Typecheck, Conventional Commit, Changelog
- `/design [briefing|concept|review|export]` — Design-Workflow mit Canva-MCP-Integration
- `/changelog-generator` — Release Notes aus Git-History generieren

**Impeccable Design-Skills** (via `pbakaus/impeccable`):

- `/impeccable` — Meta-Skill: Design, Redesign, Critique, Audit, Polish (Combined)
- `/audit` — Design auf Anti-Patterns prüfen
- `/polish` — Visuelles Fine-Tuning
- `/normalize` — Design-Inkonsistenzen bereinigen
- `/distill` — Komplexes UI vereinfachen
- `/animate` — Motion-Design
- `/bolder` / `/quieter` — Visuelles Gewicht anpassen
- `/colorize` — Farbpalette optimieren
- `/clarify` — UI-Verständlichkeit verbessern
- `/delight` — Micro-Interactions
- `/adapt` — Responsive Anpassungen
- `/extract` — Wiederverwendbare Komponenten extrahieren
- `/critique` — Design-Kritik
- `/harden` — Robustheit und Edge-Cases
- `/optimize` — Performance-optimiertes Design
- `/onboard` — Onboarding-Flows und Empty States

**Animation & Motion-Skills** (Verantwortlich: Animation Designer Agent):

- `/animation-designer [audit|plan|implement|review]` — Meta-Orchestrator fuer alle Animationen
- `/emil-design-eng` — Emil Kowalski Design-Prinzipien (Easing, Timing, Component Polish)
- `/css-animation` — HTML/CSS Animation-Demos und Walkthroughs
- `/flutter-animations` — Flutter Implicit/Explicit/Hero/Physics Animations

**HyperFrames Video-Skills** (via `heygen-com/hyperframes`):

- `/hyperframes` — HTML-to-Video Kompositionen (Captions, TTS, Transitions)
- `/hyperframes-cli` — CLI Dev-Loop (init, lint, preview, render)
- `/hyperframes-media` — Asset-Preprocessing (TTS, Transcription, BG-Removal)
- `/hyperframes-registry` — Registry-Bloecke installieren und verdrahten
- `/website-to-hyperframes` — Website zu Video konvertieren
- `/remotion-to-hyperframes` — Remotion zu HyperFrames migrieren
- `/contribute-catalog` — HyperFrames Registry-Beitraege erstellen

**Animation-Runtime-Adapter** (fuer HyperFrames):

- `/gsap` — GSAP Timelines, ScrollTrigger, Easing
- `/three` — Three.js/WebGL Szenen und AnimationMixer
- `/typegpu` — TypeGPU/WebGPU Shader und Partikel
- `/lottie` — Lottie/dotLottie After Effects Exports
- `/waapi` — Web Animations API (native Browser)
- `/animejs` — Anime.js Adapter-Patterns
- `/css-animations` — CSS Keyframes Adapter (HyperFrames-spezifisch)
- `/tailwind` — Tailwind CSS v4 Browser-Runtime (HyperFrames)

**Taste & Design-Qualitaet** (via `Leonxlnx/taste-skill`):

- `/design-taste-frontend` — Senior UI/UX Engineering, Anti-LLM-Bias
- `/gpt-taste` — Elite GSAP Motion + Editorial Typography
- `/high-end-visual-design` — Agentur-Level Design Standards
- `/brandkit` — Brand-Kit Image Generation
- `/imagegen-frontend-web` — Premium Website Design References
- `/imagegen-frontend-mobile` — Premium Mobile App Screen Concepts
- `/image-to-code` — Website Image-to-Code Pipeline
- `/redesign-existing-projects` — Bestehende Projekte upgraden
- `/stitch-design-taste` — Google Stitch Design System
- `/full-output-enforcement` — Anti-Truncation, vollstaendige Code-Ausgabe

**UI-Style-Presets:**

- `/minimalist-ui` — Editorialer Stil, warme Monochrome
- `/industrial-brutalist-ui` — Swiss Typographic + Terminal Aesthetik

**Component & Compliance Skills:**

- `/shadcn` — shadcn/ui Skill (CLI v4, Component Discovery, Registry)
- `/web-design-guidelines [dateien]` — WCAG-Compliance und UX Best Practices (100+ Regeln)
- `/frontend-design` — Production-Grade Interfaces ohne AI-Slop
- `/teach-impeccable` — Einmalige Design-Kontext-Konfiguration

Alle Skills liegen in `.claude/skills/` und `.agents/skills/` und werden mit `/` im Claude Code Terminal aufgerufen.
**Regel:** Jeder Skill ist in mindestens einem Agent, einer Routine oder einer Regel verankert.

## MCP-Server (vorkonfiguriert)

- **GitHub** — Issues, PRs, Branches direkt aus Claude Code (`GITHUB_TOKEN` in `.env` nötig)
- **Prisma** — Migrationen, Schema-Introspection, Prisma Studio
- **Context7** — Aktuelle Doku von Libraries abrufen (z.B. TanStack, Hono)
- **Playwright** — Browser-Tests ausführen und debuggen

MCP-Config: `.claude/.mcp.json` — wird mit Template-Sync aktualisiert.
