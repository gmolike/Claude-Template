# TMPL-300: Opus 4.7 Migration Guide

Anleitung fuer Repos, die bereits vom Claude-Template geklont wurden.
Fuehre diesen Guide in einem einzelnen Chat in deinem Repo durch.

---

## Uebersicht der Aenderungen

| Bereich        | Was ist neu                                                                            |
| -------------- | -------------------------------------------------------------------------------------- |
| **12 Agents**  | +1 Animation Designer (opusplan)                                                       |
| **57+ Skills** | +30 neue Skills (Emil Kowalski, Taste, HyperFrames, Flutter, CSS Animation, Changelog) |
| **4 Rules**    | +1 opus47-agents.md (Built-in Agent Types, Quality Gates)                              |
| **Packages**   | TypeScript 6, Vite 8, Vitest 4, ESLint 10, Prisma 7, Zod 4, Three.js                   |
| **Workflow**   | Built-in subagent_type, Worktree-Isolation, Background Agents, Status Line             |

---

## Schritt 1: Skills installieren

Kopiere diese Befehle und fuehre sie in deinem Repo-Root aus:

```bash
# Emil Kowalski Design Engineering
npx skills add emilkowalski/skill

# Taste Skill Suite (12+ Skills: design-taste, brandkit, imagegen, etc.)
npx skills add Leonxlnx/taste-skill

# HyperFrames Video Suite (15+ Skills: GSAP, Three, Lottie, WAAPI, etc.)
npx skills add heygen-com/hyperframes

# Flutter Animations
npx skills add madteacher/mad-agents-skills --skill flutter-animations

# CSS Animation
npx skills add neonwatty/css-animation-skill

# Release Notes Generator
npx skills add composiohq/awesome-claude-skills --skill changelog-generator

# Impeccable Combined (Update)
npx skills add pbakaus/impeccable
```

---

## Schritt 2: Dateien aus dem Template kopieren

Diese Dateien muessen aus dem aktualisierten Template uebernommen werden.
Ersetze dabei `{{PROJECT_NAME}}` durch deinen Projektnamen.

### Neue Dateien (erstellen)

| Datei                                        | Zweck                               |
| -------------------------------------------- | ----------------------------------- |
| `.claude/agents/animation-designer.md`       | Animation Designer Agent (opusplan) |
| `.claude/rules/opus47-agents.md`             | Built-in Agent Types, Quality Gates |
| `.agents/skills/animation-designer/SKILL.md` | Animation Designer Skill            |

### Aktualisierte Dateien (ersetzen)

| Datei                               | Was hat sich geaendert                                             |
| ----------------------------------- | ------------------------------------------------------------------ |
| `.claude/agents/scrum-master.md`    | Built-in subagent_type Mapping, Worktree-Isolation, Quality Skills |
| `.claude/agents/designer.md`        | Emil Kowalski, Taste, ImageGen, Animation-Delegation               |
| `.claude/agents/senior-qs.md`       | /code-review, /security-review, /verify Quality Gates              |
| `.claude/agents/senior-frontend.md` | /verify, /run, Taste-Skills, Animation-Delegation                  |
| `.claude/agents/senior-backend.md`  | /security-review, /verify, Zod 4 + Prisma 7 Hinweise               |
| `.claude/rules/token-efficiency.md` | Animation Designer als opusplan eingetragen                        |
| `CLAUDE.md`                         | Alle neuen Skill-Kategorien dokumentiert                           |

---

## Schritt 3: Packages aktualisieren

### Three.js hinzufuegen (wenn 3D benoetigt)

```bash
pnpm add three --filter=web
pnpm add -D @types/three --filter=web
```

### Major-Version-Upgrades

Aktualisiere die `package.json`-Dateien in Root, apps/web, apps/api und packages/\*:

```jsonc
// ALLE Workspaces:
"typescript": "~6.0.3"

// Root + apps/web:
"vite": "^8.0.14"
"vitest": "^4.1.7"
"@vitest/coverage-v8": "^4.1.7"
"eslint": "^10.4.0"
"@eslint/js": "^10.0.1"
"@vitejs/plugin-react": "^6.0.2"
"eslint-plugin-boundaries": "^6.0.2"

// Root:
"@commitlint/cli": "^21.0.1"
"@commitlint/config-conventional": "^21.0.1"
"lint-staged": "^17.0.5"

// apps/web:
"eslint-plugin-react-hooks": "^7.1.1"
"globals": "^17.6.0"
"jsdom": "^29.1.1"
"vite-tsconfig-paths": "^6.1.1"

// apps/api:
"@hono/node-server": "^2.0.4"
"@prisma/client": "^7.8.0"
"prisma": "^7.8.0"
"zod": "^4.4.3"
"@types/node": "^25.9.1"

// packages/shared-types:
"zod": "^4.4.3"
```

Danach:

```bash
pnpm install
```

### Peer-Dependency-Hinweise (nicht-kritisch)

- `eslint-plugin-jsx-a11y` und `eslint-plugin-react` haben noch keinen ESLint 10 Support
- `tsconfck` hat noch keinen TypeScript 6 Support
- Funktional kein Problem — Updates kommen in Kuerze

---

## Schritt 4: Zod 4 Migration (WICHTIG)

Zod 4 hat breaking API-Changes. Pruefe folgende Patterns in deinem Code:

```typescript
// Zod 3 (alt):
import { z } from 'zod';

// Zod 4 (neu) — gleiche Syntax, aber:
// - Bessere Error Messages out-of-the-box
// - Tree-Shaking Support
// - Performance-Verbesserungen
// - Einige Edge-Cases bei .transform() und .refine() geaendert
```

**Reihenfolge:** Zuerst `packages/shared-types` migrieren, dann `apps/api`.

---

## Schritt 5: Neue Workflow-Features aktivieren

### Status Line (Neue Leiste unten)

Claude Code zeigt jetzt eine persistente Status-Leiste am unteren Bildschirmrand.
Sie zeigt: aktiven Agent, laufende Tasks, Model-Tier, und Token-Verbrauch.

Aktivieren/Konfigurieren:

```
/config
```

Unter "Status Line" die gewuenschten Informationen einblenden.

### Built-in Agent Types

Der Scrum Master kann jetzt built-in `subagent_type` Parameter nutzen:

```
Agent({
  subagent_type: "senior-frontend",  // Nutzt built-in + custom agent definition
  isolation: "worktree",              // Isolierte Repo-Kopie
  run_in_background: true,            // Laeuft parallel
  name: "frontend-worker-1"           // Adressierbar via SendMessage
})
```

### Quality Gates (neu)

Diese Skills sind jetzt PFLICHT in Reviews:

| Gate          | Wann                | Skill                        |
| ------------- | ------------------- | ---------------------------- |
| Correctness   | Vor jedem PR        | `/code-review --effort high` |
| Security      | Vor jedem PR        | `/security-review`           |
| Visual        | Vor Feature-Abnahme | `/verify`                    |
| App-Check     | Vor Feature-Abnahme | `/run`                       |
| Release Notes | Bei Releases        | `/changelog-generator`       |

### Worktree-Isolation

Parallele Worker koennen jetzt in isolierten Git-Worktrees arbeiten:

- Keine Konflikte bei gleichzeitiger Arbeit am gleichen Code
- Automatisches Cleanup wenn Agent keine Aenderungen macht
- Branch und Pfad werden im Result zurueckgegeben

---

## Schritt 6: Neue Skill-Kategorien kennenlernen

### Animation & Motion (Animation Designer Agent)

```
/animation-designer audit      — Bestehende Animationen analysieren
/animation-designer plan       — Animations-Strategie erstellen
/animation-designer implement  — Animationen implementieren
/animation-designer review     — Quality Gate fuer Animationen
```

Untergeordnete Skills:

- `/animate` — UI Micro-Interactions
- `/emil-design-eng` — Emil Kowalski Prinzipien
- `/gsap` — GSAP Timelines
- `/three` — Three.js/WebGPU
- `/lottie` — After Effects Exports
- `/flutter-animations` — Flutter Motion
- `/css-animation` — CSS Demos/Walkthroughs

### HyperFrames Video-Produktion

```
/hyperframes          — Video-Komposition erstellen
/hyperframes-cli      — CLI: init, lint, preview, render
/hyperframes-media    — TTS, Transcription, BG-Removal
/website-to-hyperframes — Website zu Video konvertieren
```

### Taste & Design-Qualitaet

```
/design-taste-frontend      — Anti-LLM-Bias UI Engineering
/high-end-visual-design     — Agentur-Level Standards
/frontend-design            — Production-Grade ohne AI-Slop
/brandkit                   — Brand-Kit Image Generation
/imagegen-frontend-web      — Premium Website Mockups
/imagegen-frontend-mobile   — Premium Mobile Mockups
```

### UI-Style-Presets

```
/minimalist-ui              — Editorialer Stil
/industrial-brutalist-ui    — Swiss Typographic Terminal
```

---

## Schritt 7: Verifizierung

Pruefe nach der Migration:

```bash
# Packages korrekt installiert?
pnpm outdated

# Lint noch funktionsfaehig? (ESLint 10 Config pruefen)
pnpm lint

# TypeScript 6 kompiliert?
pnpm typecheck

# Tests laufen?
pnpm test

# Skills geladen?
# Starte Claude Code und pruefe ob die Skills in der Skill-Liste erscheinen
```

---

## Checkliste

- [ ] Skills installiert (Schritt 1)
- [ ] Agent/Rule/Skill-Dateien kopiert (Schritt 2)
- [ ] Packages aktualisiert (Schritt 3)
- [ ] Zod 4 Migration durchgefuehrt (Schritt 4)
- [ ] Neue Workflow-Features getestet (Schritt 5)
- [ ] Neue Skills ausprobiert (Schritt 6)
- [ ] Verifizierung bestanden (Schritt 7)

---

## Quick-Reference: Neues Model-Tiering

| Rolle                  | Model        | Aenderung                      |
| ---------------------- | ------------ | ------------------------------ |
| PO / Scrum Master      | opusplan     | Unveraendert                   |
| **Animation Designer** | **opusplan** | **NEU**                        |
| Senior Frontend        | sonnetplan   | +Taste, +Animation-Delegation  |
| Senior Backend         | sonnetplan   | +Zod 4, +Prisma 7, +Security   |
| Senior QS              | sonnetplan   | +code-review, +security-review |
| Designer               | sonnetplan   | +Emil, +Taste, +ImageGen       |
| Workers                | sonnet       | Unveraendert                   |
| Debugger               | sonnet       | Unveraendert                   |

---

_Erstellt: 2026-05-24 | Template-Version: TMPL-300 | Opus 4.7_
