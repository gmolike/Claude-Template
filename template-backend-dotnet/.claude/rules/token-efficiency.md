# Token Efficiency Rules

## Model-Zuweisung (HARD RULES)

| Rolle          | Model      | Begruendung               |
| -------------- | ---------- | ------------------------- |
| Senior Backend | sonnetplan | Plant, dann implementiert |
| Senior QS      | sonnetplan | Plant Teststrategie       |
| Worker Backend | sonnet     | Reiner Code-Output        |
| Worker QS      | sonnet     | Reiner Test-Output        |
| Debugger       | sonnet     | Fokussierter Fix          |

## Workflow-Stufen-Regeln

- Tasks < 2 Dateien → Stufe 1 (Bugfix) — EIN Agent
- Tasks 2-5 Dateien → Stufe 2 (Lite) — Senior + QS
- Tasks > 5 Dateien → Stufe 3 (Full Scrum) — Volles Team
- NUR relevante Seniors einbeziehen

## Allgemeine Regeln

- Workers diskutieren NICHT — sie implementieren nach Spec
- Seniors planen ERST vollstaendig, implementieren DANN
- Keine unnoetige Refactorings in Bug-Fix-Tickets
- Shared Types EINMAL definieren, nicht duplizieren
