---
name: scrum
description: 'Sprint-Board anzeigen und verwalten. Tasks sehen, verschieben, erstellen oder Sprint-Status pruefen.'
argument-hint: '[show|move|create|status]'
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(ls:*), Bash(find:*), Bash(cat:*), Bash(mv:*)
disable-model-invocation: true
---

# Sprint-Board verwalten

Du verwaltest das dateibasierte Scrum-Board in `.scrum/`.
Task-Dateien liegen in `.scrum/<status>/` (backlog, in-progress, review, done).

## Befehle

### `/scrum show` oder `/scrum` (ohne Argument)

Zeige uebersichtliche Tabelle des Board-Status:

1. Lies alle `.md` Dateien in `.scrum/backlog/`, `.scrum/in-progress/`, `.scrum/review/`, `.scrum/done/`
2. Parse YAML-Frontmatter (id, title, status, priority, assignee, github_issues)
3. Formatiere als Tabelle:

```
Backlog (2)
  FEAT-001  [high]   Login Feature         → frontend-repo  [#12, #13]
  FEAT-002  [medium] User Profile          → backend-repo   [#8]

In Progress (1)
  FEAT-003  [high]   Setup Auth            → contracts-repo  [#5]

Review (0)

Done (1)
  FEAT-004  [low]    README Update         → orchestrator
```

### `/scrum move <id> <status>`

1. Finde die Datei mit der passenden ID
2. Verschiebe in Zielordner (backlog, in-progress, review, done)
3. Aktualisiere `status:` im YAML-Frontmatter
4. Wenn nach `done`: Pruefe ob alle Acceptance Criteria abgehakt

### `/scrum create <titel>`

1. Ermittle naechste freie ID (FEAT-XXX, aufsteigend)
2. Frage nach: Prioritaet, betroffene Repos, Beschreibung, Acceptance Criteria
3. Erstelle Datei in `.scrum/backlog/`:

```markdown
---
id: FEAT-XXX
title: [titel]
status: backlog
priority: medium
assignee: unassigned
tags: []
created: [ISO-Datum]
blocked_by: []
github_issues: []
---

# FEAT-XXX: [titel]

## Beschreibung

[Vom User oder $ARGUMENTS]

## Acceptance Criteria

- [ ] [Kriterium]

## Betroffene Repos

- [ ] [Repo + was aendern]
```

### `/scrum status`

Sprint-Zusammenfassung:

- Anzahl Tasks pro Status
- Blockierte Tasks
- Tasks ohne Assignee
- Verlinkte GitHub Issues und deren Status

## Regeln

- Dateinamen: `[id]-[kurztitel].md`
- IDs fortlaufend und einzigartig
- Beim Verschieben nach `done` Acceptance Criteria pruefen
