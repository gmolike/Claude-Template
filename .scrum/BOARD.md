# Sprint Board — {{PROJECT_NAME}}

## Aktueller Sprint: Sprint 0 (Setup)

### Epics

#### EPIC-001: Projektinfrastruktur

> Alle Domänen haben lauffähige Dev-Umgebung

| ID        | Titel                   | Domäne | Status  | Assignee     | Blocked by |
| --------- | ----------------------- | ------ | ------- | ------------ | ---------- |
| SETUP-001 | Shared Types definieren | shared | backlog | Sr. Backend  | —          |
| SETUP-002 | API Grundgerüst         | api    | backlog | Sr. Backend  | SETUP-001  |
| SETUP-003 | Web App Routing         | web    | backlog | Sr. Frontend | SETUP-001  |
| SETUP-004 | Mobile Navigation       | mobile | backlog | Sr. Frontend | SETUP-001  |

### Abhängigkeitsbaum

```
SETUP-001 (shared)
├── SETUP-002 (api)    ← braucht Types
├── SETUP-003 (web)    ← braucht Types
└── SETUP-004 (mobile) ← braucht Types
```

### Sprint-Ziel

> [Hier Sprint-Ziel formulieren]

---

## Board-Regeln

- Tasks werden als Markdown-Dateien in `.scrum/<domäne>/<status>/` verwaltet
- Status-Wechsel = Datei verschieben (z.B. `.scrum/web/backlog/` → `.scrum/web/in-progress/`)
- Domänen: `web`, `mobile`, `api`, `shared`, `content`
- Cross-Domain Review: `.scrum/review/` (Top-Level)
- Nur PO verschiebt Tasks nach `done/`
- Acceptance Criteria müssen abgehakt sein bevor `done/`
