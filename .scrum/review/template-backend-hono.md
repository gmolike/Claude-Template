## Worker-Backend Output: template-backend-hono

### Implementierte Dateien

- `template-backend-hono/CLAUDE.md` — Projekt-Dokumentation, HARD RULES, Befehle
- `template-backend-hono/AGENTS.md` — Agent-Rollenuebersicht
- `template-backend-hono/CHANGELOG.md` — Initiale Changelog-Eintraege
- `template-backend-hono/README.md` — Setup-Anleitung, Architektur-Uebersicht
- `template-backend-hono/package.json` — Dependencies (Hono, Prisma, Zod, Vitest, TSX)
- `template-backend-hono/tsconfig.json` — TypeScript strict, path aliases `@/*`
- `template-backend-hono/vitest.config.ts` — Vitest node environment, coverage v8
- `template-backend-hono/eslint.config.mjs` — ESLint flat config
- `template-backend-hono/docker-compose.yml` — PostgreSQL 16-alpine service
- `template-backend-hono/docker/Dockerfile` — Multi-stage pnpm/node:20-alpine build
- `template-backend-hono/.env.example` — DATABASE_URL, PORT, JWT_SECRET Platzhalter
- `template-backend-hono/.gitignore` — node_modules, dist, .env, coverage
- `template-backend-hono/.editorconfig` — LF, UTF-8, 2-space indent
- `template-backend-hono/scripts/init.sh` — {{PROJECT_NAME}} Ersetzung via find+sed
- `template-backend-hono/src/index.ts` — Hono App, Middleware, Routes, Health-Check, Swagger
- `template-backend-hono/src/db/client.ts` — PrismaClient Singleton
- `template-backend-hono/src/db/schema.prisma` — User Model mit PostgreSQL
- `template-backend-hono/src/validators/auth.ts` — loginSchema, registerSchema (Zod)
- `template-backend-hono/src/validators/users.ts` — updateUserSchema (Zod)
- `template-backend-hono/src/services/user-service.ts` — getById, getByEmail, create, update (JSDoc)
- `template-backend-hono/src/routes/auth.ts` — POST /login, POST /register mit zValidator
- `template-backend-hono/src/routes/users.ts` — GET /me, PATCH /me, GET /:id
- `template-backend-hono/src/middleware/error-handler.ts` — ZodError → 400, fallback → 500
- `template-backend-hono/.claude/agents/senior-backend.md` — sonnetplan, Planning-First
- `template-backend-hono/.claude/agents/worker-backend.md` — sonnet, Spec-Implementierung
- `template-backend-hono/.claude/agents/worker-qs.md` — sonnet, Vitest Tests
- `template-backend-hono/.claude/agents/debugger.md` — sonnet, minimaler Fix
- `template-backend-hono/.claude/rules/token-efficiency.md` — Model-Tiering, Workflow-Stufen
- `template-backend-hono/.claude/rules/documentation.md` — CHANGELOG, JSDoc, ADR Pflichten
- `template-backend-hono/.claude/skills/commit/SKILL.md` — Smart Commit fuer Hono Backend
- `template-backend-hono/.claude/skills/review/SKILL.md` — Review gegen Hono-Architektur-Standards
- `template-backend-hono/.claude/settings.json` — AGENT_TEAMS, Bash-Permissions
- `template-backend-hono/.claude/.mcp.json` — GitHub, Prisma, Context7 MCP Server
- `template-backend-hono/.github/workflows/ci.yml` — Lint, Typecheck, Test (mit Postgres Service), Build
- `template-backend-hono/.github/workflows/template-sync.yml` — Woechentlicher Template-Sync

### Tests

Keine Test-Dateien in diesem Template-Gerüst erstellt — das Template selbst ist das Artefakt.
Die Vitest-Konfiguration (`vitest.config.ts`) und die CI-Pipeline (`ci.yml`) sind vollstaendig
eingerichtet; konkrete Test-Dateien werden pro Feature vom Worker QS nach Spec geschrieben.

### Migrations

Nicht angewandt — schema.prisma liegt bereit, Migrationen erfolgen nach `pnpm db:migrate`
im jeweiligen Projekt-Kontext.

### Status: Bereit fuer Review in .scrum/review/
