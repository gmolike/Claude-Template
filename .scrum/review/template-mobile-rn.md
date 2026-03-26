# Worker-Frontend Output: template-mobile-rn

## Implementierte Dateien

### Root-Level

- `template-mobile-rn/CLAUDE.md` — Projekt-Instruktionen fuer Mobile-Agenten
- `template-mobile-rn/AGENTS.md` — Agent-Rollen-Uebersicht
- `template-mobile-rn/CHANGELOG.md` — Initiales Changelog
- `template-mobile-rn/README.md` — Setup-Anleitung
- `template-mobile-rn/package.json` — Expo + TanStack Query Abhaengigkeiten
- `template-mobile-rn/app.json` — Expo-Konfiguration mit {{PROJECT_NAME}}-Platzhaltern
- `template-mobile-rn/tsconfig.json` — TypeScript strict + Path Aliases
- `template-mobile-rn/.env.example` — EXPO_PUBLIC_API_URL Vorlage
- `template-mobile-rn/.gitignore` — node_modules, .expo, generated/api-types.ts
- `template-mobile-rn/.editorconfig` — LF, 2 Spaces, UTF-8

### src/app/

- `src/app/providers.tsx` — QueryClientProvider mit staleTime 5min, JSDoc
- `src/app/index.tsx` — Public API Barrel Export

### src/ FSD-Layer-Platzhalter

- `src/screens/.gitkeep` — Screen-Layer (entspricht FSD pages)
- `src/features/.gitkeep` — Business Logic, Mutations
- `src/entities/.gitkeep` — Domain Models, Queries
- `src/shared/ui/.gitkeep` — UI-Komponenten
- `src/shared/lib/.gitkeep` — Utilities

### src/shared/

- `src/shared/api/client.ts` — HTTP-Client mit GET/POST/PATCH/DELETE, ApiError-Klasse, JSDoc
- `src/shared/api/index.ts` — Public API Export
- `src/shared/config/index.ts` — Zentralisierte Konfiguration mit const assertion

### .claude/

- `.claude/agents/senior-frontend.md` — sonnetplan, Architektur + Review
- `.claude/agents/worker-frontend.md` — sonnet, Code-Output nach Spec
- `.claude/agents/worker-qs.md` — sonnet, Jest + RNTL
- `.claude/agents/debugger.md` — sonnet, minimaler Fix
- `.claude/rules/token-efficiency.md` — Model-Tiering, Workflow-Stufen
- `.claude/rules/documentation.md` — JSDoc, CHANGELOG, Scrum-Board Pflichten
- `.claude/skills/commit/SKILL.md` — Conventional Commits Workflow
- `.claude/skills/review/SKILL.md` — FSD + RN Code Review Checkliste
- `.claude/settings.json` — Agent Teams aktiviert, Permissions
- `.claude/.mcp.json` — GitHub + Context7 MCP-Server

### scripts/

- `scripts/generate-api-types.sh` — OpenAPI Codegen via openapi-typescript
- `scripts/init.sh` — Interaktives Setup mit sed-Replace fuer {{PROJECT_NAME}}

### .github/workflows/

- `.github/workflows/ci.yml` — lint + typecheck + test auf main/PR
- `.github/workflows/template-sync.yml` — Woechentlicher Template-Sync

### generated/

- `generated/.gitkeep` — Platzhalter (api-types.ts ist in .gitignore)

## Tests

Keine Tests in diesem Template selbst — Testinfrastruktur (Jest) wird ueber
`package.json` konfiguriert. Tests werden durch `worker-qs` Agent geschrieben
wenn Screens und Features implementiert werden.

## FSD-Check

- Layer: FSD-adaptiert fuer Mobile — screens/features/entities/shared statt pages/widgets
- Public API: `src/app/index.tsx` und `src/shared/api/index.ts` vorhanden
- Imports: client.ts verwendet kein `import.meta.env` (Vite) sondern `process.env` (RN)
- Keine react-dom Imports
- API-Types-Slot vorbereitet via `generated/` Verzeichnis

## Status: Bereit fuer Review in .scrum/review/
