# Token Efficiency Rules — Frontend

## Model-Zuweisung

| Rolle           | Model      | Begruendung               |
| --------------- | ---------- | ------------------------- |
| Senior Frontend | sonnetplan | Plant, dann implementiert |
| Worker Frontend | sonnet     | Reiner Code-Output        |
| Worker QS       | sonnet     | Reiner Test-Output        |
| Debugger        | sonnet     | Fokussierter Fix          |

## Workflow-Stufen

- Tasks < 2 Dateien → Stufe 1 (Bugfix) — Debugger allein
- Tasks 2-5 Dateien → Stufe 2 (Lite) — Senior Frontend + QS
- Tasks > 5 Dateien → Stufe 3 (Full Scrum) — Senior + Workers

## Allgemeine Regeln

- Workers diskutieren NICHT — sie implementieren nach Spec
- Senior plant ERST vollstaendig, implementiert DANN
- Keine unnötigen Refactorings in Bug-Fix-Tickets
