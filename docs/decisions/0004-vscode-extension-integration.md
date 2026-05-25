# ADR 0004: VS Code Extension Integration (Claude Code Monitor)

## Status

Accepted

## Context

Wir brauchen eine Moeglichkeit, Claude Code Sessions in Echtzeit zu monitoren — Token Usage, Session Status, Scrum Board, FSD Layer Aktivitaet und Agent Orchestration. Die Open-Source Extension [claude-code-session](https://github.com/madeby10am/claude-code-session) (MIT) bietet eine solide Basis mit Session-Parsing, Robot-Sprites und Usage-Metern.

## Decision

Wir forken die Extension als `apps/vscode-session` ins Monorepo und erweitern sie um drei Template-spezifische Features:

1. **Scrum Board Integration** — `.scrum/` Tasks in der Sidebar anzeigen und verschieben
2. **FSD Layer Monitor** — Welche FSD-Layer wurden in der Session bearbeitet
3. **Agent Orchestration Status** — tmux Session-Status live anzeigen

### Wichtige technische Entscheidungen

- **CommonJS statt ESModule**: VS Code Extensions muessen CommonJS sein. `apps/vscode-session/package.json` hat bewusst KEIN `"type": "module"`, obwohl der Rest des Monorepos ESModule nutzt.
- **Standalone**: Die Extension nutzt keine Shared Packages (`@repo/shared-types` etc.), da sie `~/.claude/` System-Dateien liest, nicht die App-Daten.
- **Zero Runtime Dependencies**: Nur VS Code API + Node.js Builtins — kein zusaetzlicher Dependency-Overhead.
- **Separater Build**: tsc (CommonJS) + esbuild (IIFE fuer Webview) statt Vite.

## Consequences

- Neue App `apps/vscode-session` wird automatisch vom pnpm Workspace erkannt
- Build ueber `pnpm ext:build` vom Root, eigenstaendige Extension-Entwicklung in `vscode-ext.code-workspace`
- Extension wird lokal per VSIX installiert, Marketplace-Publishing spaeter moeglich
- Robot-Sprite Assets (~2MB) werden im Repo committed — nur die Sprite Sheets werden im VSIX ausgeliefert
