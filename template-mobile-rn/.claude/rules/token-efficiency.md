# Token Efficiency Rules — Mobile

## Model-Zuweisung (HARD RULES)

| Rolle           | Model      | Begruendung               |
| --------------- | ---------- | ------------------------- |
| Senior Frontend | sonnetplan | Plant, dann implementiert |
| Worker Frontend | sonnet     | Reiner Code-Output        |
| Worker QS       | sonnet     | Reiner Test-Output        |
| Debugger        | sonnet     | Fokussierter Fix          |

## Workflow-Stufen-Regeln

- Tasks < 2 Dateien → Stufe 1 (Bugfix) — EIN Agent
- Tasks 2-5 Dateien → Stufe 2 (Lite) — Senior + QS
- Tasks > 5 Dateien → Stufe 3 (Full Scrum) — Volles Team
- Kein Backend fuer reine UI-Aenderungen

## Allgemeine Regeln

- Workers diskutieren NICHT — sie implementieren nach Spec
- Seniors planen ERST vollstaendig, implementieren DANN
- Keine unnötigen Refactorings in Bug-Fix-Tickets
