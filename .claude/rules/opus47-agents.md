# Opus 4.7 Agent & Skill Integration

## Built-in Agent Types

Claude Code bietet built-in `subagent_type` Parameter die den Template-Agents entsprechen.
Custom Agent-Definitionen in `.claude/agents/` erweitern diese mit projekt-spezifischen Regeln.

### Mapping

| Built-in Type   | Custom Agent       | Tools                                     | Model      |
| --------------- | ------------------ | ----------------------------------------- | ---------- |
| product-owner   | product-owner.md   | Read, Write, Edit, Glob, Grep             | opusplan   |
| scrum-master    | scrum-master.md    | Read, Write, Edit, Glob, Grep, Task       | opusplan   |
| senior-frontend | senior-frontend.md | Read, Write, Edit, Bash, Glob, Grep, Task | sonnetplan |
| senior-backend  | senior-backend.md  | Read, Write, Edit, Bash, Glob, Grep, Task | sonnetplan |
| senior-qs       | senior-qs.md       | Read, Write, Edit, Bash, Glob, Grep, Task | sonnetplan |
| worker-frontend | worker-frontend.md | Read, Write, Edit, Bash, Glob, Grep       | sonnet     |
| worker-backend  | worker-backend.md  | Read, Write, Edit, Bash, Glob, Grep       | sonnet     |
| worker-qs       | worker-qs.md       | Read, Write, Edit, Bash, Glob, Grep       | sonnet     |
| debugger        | debugger.md        | Read, Edit, Bash, Grep, Glob              | sonnet     |

### Zusaetzliche Custom Agents (kein built-in Pendant)

| Custom Agent          | Model      | Zweck                               |
| --------------------- | ---------- | ----------------------------------- |
| animation-designer.md | opusplan   | Animation & Motion Design Architect |
| designer.md           | sonnetplan | UI/UX Design mit Canva-MCP          |

## Agent-Orchestrierung Features

### Worktree-Isolation

`isolation: "worktree"` erstellt eine isolierte Kopie des Repos.
Nutzen fuer parallele Worker die am gleichen Code arbeiten.

### Background Agents

`run_in_background: true` fuer unabhaengige Tasks.
Der aufrufende Agent wird benachrichtigt wenn der Hintergrund-Agent fertig ist.

### Named Agents

`name: "agent-name"` erlaubt spaetere Kommunikation via `SendMessage({to: "agent-name"})`.
Nutzen fuer iterative Reviews und Feedback-Loops.

## Built-in Skills (immer verfuegbar)

Diese Skills sind in Claude Code eingebaut und muessen NICHT installiert werden:

| Skill              | Zweck                     | Verantwortlicher Agent     |
| ------------------ | ------------------------- | -------------------------- |
| `/verify`          | Feature im Browser testen | Senior Frontend, Senior QS |
| `/code-review`     | Diff auf Bugs pruefen     | Senior QS, Seniors         |
| `/security-review` | Security-Audit des Branch | Senior Backend, Senior QS  |
| `/run`             | App starten, Screenshot   | Senior Frontend, Workers   |
| `/init`            | CLAUDE.md initialisieren  | Scrum Master               |
| `/review`          | PR reviewen               | Senior QS                  |
| `/loop`            | Recurring Tasks (Polling) | Scrum Master               |
| `/claude-api`      | Claude API/SDK Apps bauen | Senior Backend             |

## Quality Gates (PFLICHT)

### Vor jedem PR

1. `/code-review` — Correctness-Bugs finden
2. `/security-review` — Security-Schwachstellen pruefen

### Vor jeder Feature-Abnahme

1. `/verify` — Feature im Browser/App testen
2. `/run` — App starten und Golden Path pruefen

### Bei Releases

1. `/changelog-generator` — Release Notes generieren
2. CHANGELOG.md [Unreleased] aktualisieren
