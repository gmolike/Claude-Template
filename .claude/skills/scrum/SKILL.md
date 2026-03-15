---
name: scrum
description: 'Sprint-Board anzeigen und verwalten. Nutze diesen Skill wenn der User Tasks sehen, verschieben, erstellen oder den Sprint-Status prüfen will.'
argument-hint: '[show|move|create|status]'
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(ls:*), Bash(find:*), Bash(cat:*), Bash(mv:*)
disable-model-invocation: true
---

# Sprint-Board verwalten

Du verwaltest das dateibasierte Scrum-Board in `.scrum/`.

Domänen: `web`, `mobile`, `api`, `shared`, `content`
Task-Dateien liegen in `.scrum/<domäne>/<status>/`.
Cross-Domain Reviews liegen in `.scrum/review/` (Top-Level).

## Befehle

Interpretiere `$ARGUMENTS` und führe die passende Aktion aus:

### `/scrum show` oder `/scrum` (ohne Argument)

Zeige eine übersichtliche Tabelle des aktuellen Board-Status für ALLE Domänen:

1. Lies alle `.md` Dateien in `.scrum/<domäne>/backlog/`, `.scrum/<domäne>/in-progress/`, `.scrum/<domäne>/done/` für jede Domäne (web, mobile, api, shared, content)
2. Lies außerdem `.scrum/review/` für Cross-Domain Reviews
3. Parse den YAML-Frontmatter jeder Datei (id, title, status, priority, assignee)
4. Formatiere als übersichtliche Tabelle pro Domäne:

```
=== web ===
Backlog (2)
  FEAT-001  [high]   Implement login       → unassigned
  FEAT-002  [medium] Add user profile      → senior-frontend

In Progress (1)
  FEAT-003  [high]   Setup routing         → worker-frontend

Done (0)

=== api ===
Backlog (1)
  FEAT-010  [high]   Setup database        → senior-backend

In Progress (0)

Done (0)

=== review (cross-domain) ===
  FEAT-005  [medium] Add health endpoint   → worker-backend
```

### `/scrum move <id> <status> --domain <domäne>`

Verschiebe eine Task-Datei innerhalb einer Domäne:

1. Finde die Datei mit der passenden ID in `.scrum/<domäne>/` Unterordnern
2. Verschiebe sie in den Zielordner der Domäne (backlog, in-progress, review, done)
   - Bei `review`: Verschiebe in `.scrum/review/` (Top-Level, cross-domain)
3. Aktualisiere das `status:` Feld im YAML-Frontmatter
4. Wenn nach `done` verschoben: Prüfe ob alle Acceptance Criteria abgehakt sind

Beispiel: `/scrum move FEAT-001 in-progress --domain web`

### `/scrum create <titel> --domain <domäne>`

Erstelle eine neue Task-Datei in der angegebenen Domäne:

1. Ermittle die nächste freie ID (FEAT-XXX, aufsteigend, über alle Domänen hinweg)
2. Frage nach: Priorität, Beschreibung, Acceptance Criteria
3. Erstelle die Datei in `.scrum/<domäne>/backlog/` mit vollständigem YAML-Frontmatter:

```markdown
---
id: FEAT-XXX
title: [titel]
status: backlog
domain: [domäne]
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

Beispiel: `/scrum create Login-Feature --domain web`

### `/scrum status`

Zeige Sprint-Zusammenfassung über alle Domänen:

- Anzahl Tasks pro Status und Domäne
- Blockierte Tasks (blocked_by nicht leer)
- Tasks ohne Assignee
- Überblick wer woran arbeitet
- Cross-Domain Reviews in `.scrum/review/`

## Regeln

- Dateinamen: `[id]-[kurztitel].md` (z.B. `FEAT-001-implement-login.md`)
- IDs sind fortlaufend und einzigartig (über alle Domänen hinweg)
- Task-Dateien liegen in `.scrum/<domäne>/<status>/`
- Cross-Domain Review: `.scrum/review/` (Top-Level, nicht domänenspezifisch)
- Beim Verschieben nach `done` immer prüfen ob Acceptance Criteria vollständig sind
- `.scrum/BOARD.md` wird NICHT automatisch verändert (ist Referenz-Doku)
- Gültige Domänen: `web`, `mobile`, `api`, `shared`, `content`

## OMC-Status (Optional)

Wenn OMC installiert ist, zeige bei `/scrum status` zusätzlich:

- Aktiver OMC-Modus (ecomode/ultrawork/autopilot)
- Laufende OMC-Agents und deren Status
- OMC ist OPTIONAL — wenn nicht installiert, diesen Abschnitt überspringen
