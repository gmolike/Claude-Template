# Token Efficiency Rules

## Model-Zuweisung (HARD RULES)

| Rolle             | Model      | Begruendung                      |
| ----------------- | ---------- | -------------------------------- |
| PO / Scrum Master | opusplan   | Tiefes Reasoning, Planning-First |
| Designer          | sonnetplan | Plant UI/UX                      |
| Senior (alle)     | sonnetplan | Plant, dann implementiert        |
| Worker (alle)     | sonnet     | Reiner Code-Output               |
| Debugger          | sonnet     | Fokussierter Fix                 |

## Workflow-Stufen-Regeln (Multi-Repo)

- Einzelnes Repo, 1-2 Dateien → Stufe 1 (Bugfix) — Issue im Repo
- Einzelnes Repo, 2-5 Dateien → Stufe 2 (Lite) — Issue im Repo
- Repo-uebergreifend → Stufe 3 (Full Scrum) — Issues in allen Repos
- NUR betroffene Repos einbeziehen
- Kein Frontend-Issue fuer reine API-Aenderungen
- Kein Backend-Issue fuer reine UI-Aenderungen

## Allgemeine Regeln

- Workers diskutieren NICHT — sie implementieren nach Spec
- Seniors planen ERST vollstaendig, implementieren DANN
- Keine unnuetigen Refactorings in Bug-Fix-Tickets
- Contract-Aenderungen ZUERST, dann Implementation
