---
name: scrum
description: 'Sprint-Board anzeigen und verwalten. Nutze diesen Skill wenn der User Tasks sehen, verschieben, erstellen oder den Sprint-Status prüfen will.'
argument-hint: '[show|move|create|status]'
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(ls:*), Bash(find:*), Bash(cat:*), Bash(mv:*)
disable-model-invocation: true
---

# Sprint-Board verwalten

Du verwaltest das dateibasierte Scrum-Board in `.scrum/`.

## Befehle

Interpretiere `$ARGUMENTS` und führe die passende Aktion aus:

### `/scrum show` oder `/scrum` (ohne Argument)

Zeige eine übersichtliche Tabelle des aktuellen Board-Status:

1. Lies alle `.md` Dateien in `.scrum/backlog/`, `.scrum/in-progress/`, `.scrum/review/`, `.scrum/done/`
2. Parse den YAML-Frontmatter jeder Datei (id, title, status, priority, assignee)
3. Formatiere als übersichtliche Tabelle:

```
📋 BACKLOG (3)
  FEAT-001  [high]   Implement login       → unassigned
  FEAT-002  [medium] Add user profile      → senior-frontend

🔄 IN PROGRESS (1)
  FEAT-003  [high]   Setup database        → senior-backend

👀 REVIEW (0)

✅ DONE (2)
  FEAT-004  [low]    Create README         → worker-frontend
  FEAT-005  [medium] Add health endpoint   → worker-backend
```

### `/scrum move FEAT-XXX [status]`

Verschiebe eine Task-Datei:

1. Finde die Datei mit der passenden ID in allen `.scrum/` Unterordnern
2. Verschiebe sie in den Zielordner (backlog, in-progress, review, done)
3. Aktualisiere das `status:` Feld im YAML-Frontmatter
4. Wenn nach `done` verschoben: Prüfe ob alle Acceptance Criteria abgehakt sind

### `/scrum create [titel]`

Erstelle eine neue Task-Datei:

1. Ermittle die nächste freie ID (FEAT-XXX, aufsteigend)
2. Frage nach: Priorität, Beschreibung, Acceptance Criteria
3. Erstelle die Datei in `.scrum/backlog/` mit vollständigem YAML-Frontmatter:

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
---

# FEAT-XXX: [titel]

## Beschreibung

[Vom User oder $ARGUMENTS]

## Acceptance Criteria

- [ ] [Kriterium]
```

### `/scrum status`

Zeige Sprint-Zusammenfassung:

- Anzahl Tasks pro Status
- Blockierte Tasks (blocked_by nicht leer)
- Tasks ohne Assignee
- Überblick wer woran arbeitet

## Regeln

- Dateinamen: `[id]-[kurztitel].md` (z.B. `FEAT-001-implement-login.md`)
- IDs sind fortlaufend und einzigartig
- Beim Verschieben nach `done` immer prüfen ob Acceptance Criteria vollständig sind
- `.scrum/BOARD.md` wird NICHT automatisch verändert (ist Referenz-Doku)
