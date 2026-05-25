# VS Code Extension — Claude Code Monitor

VS Code Sidebar-Extension fuer Live-Monitoring von Claude Code Sessions.
Fork von [claude-code-session](https://github.com/madeby10am/claude-code-session) (MIT).

## Architektur

```
extension.ts          → Entry Point, registriert Sidebar + Command
panel.ts              → WebviewViewProvider, HTML-Builder, Message-Handler
sessionManager.ts     → Watches ~/.claude/projects/**/*.jsonl
session/
  types.ts            → SessionState, UsageStats, ActivityState
  jsonlParser.ts      → JSONL Log Parser (inkrementell)
  usageCompute.ts     → API Rate-Limit Abfrage via Credentials
  claudeEnvironment.ts → MCP Servers, Skills aus ~/.claude/
  activityTimers.ts   → Idle/Sleep Timer
  clis.ts             → CLI Tool Detection (PATH scan)
  tokenActivity.ts    → Token Events aus JSONL Logs
  categorize.ts       → Skill Kategorisierung
  scrumBoard.ts       → .scrum/ Board Integration
  fsdLayerMonitor.ts  → FSD Layer Aktivitaet
  agentOrchestration.ts → tmux Agent Status
shared/
  messages.ts         → Typed Message Protocol (Extension <-> Webview)
webview/
  index.ts            → 51KB Frontend (IIFE Bundle via esbuild)
  body.html           → HTML Markup
  styles.css          → Styling (VS Code Theme Auto-Match)
```

## Build Pipeline

- `pnpm compile` — tsc (CommonJS) + esbuild (IIFE) + copy static
- `pnpm watch` — tsc Watch Mode
- `pnpm watch:webview` — esbuild Watch Mode
- `pnpm deploy:ext` — Build + in installierte Extension kopieren
- `pnpm package` — VSIX erstellen
- `pnpm test` — Vitest

**WICHTIG:** Kein `"type": "module"` — VS Code Extensions muessen CommonJS sein.

## Datenquellen

- `~/.claude/projects/**/*.jsonl` — Session Logs
- `~/.claude/.credentials.json` — OAuth Token fuer Usage API
- `~/.claude/settings.json` — Effort Level
- `~/.claude/skills/` + `~/.claude/plugins/cache/` — Skills
- `~/.claude/mcp.json` — MCP Server
- `.scrum/` — Scrum Board Tasks (Workspace-relativ)
- `tmux list-sessions` — Agent Orchestration

## Workflow-Stufe

- Tasks < 2 Dateien → Stufe 1 (Bugfix)
- Tasks 2-5 Dateien → Stufe 2 (Lite)
- Kein Full Scrum noetig (eigenstaendige Extension)

## Coding Standards

- TypeScript strict, kein any
- Zero Runtime Dependencies (nur VS Code API + Node.js builtins)
- Webview ist ein monolithischer IIFE Bundle (esbuild)
- Pixel-Art Sprites: `imageSmoothingEnabled = false`
