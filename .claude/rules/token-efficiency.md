# Token Efficiency Rules

## Model-Zuweisung (HARD RULES)

| Rolle              | Model      | Begründung                                 |
| ------------------ | ---------- | ------------------------------------------ |
| PO / Scrum Master  | opusplan   | Tiefes Reasoning, Planning-First           |
| Animation Designer | opusplan   | Kreative Motion-Strategie, Multi-Plattform |
| Senior Frontend    | sonnetplan | Plant, dann implementiert                  |
| Senior Backend     | sonnetplan | Plant, dann implementiert                  |
| Senior QS          | sonnetplan | Plant Teststrategie                        |
| Designer           | sonnetplan | Plant UI/UX                                |
| Worker Frontend    | sonnet     | Reiner Code-Output                         |
| Worker Backend     | sonnet     | Reiner Code-Output                         |
| Worker QS          | sonnet     | Reiner Test-Output                         |
| Debugger           | sonnet     | Fokussierter Fix                           |

## Workflow-Stufen-Regeln

- Tasks < 2 Dateien → Stufe 1 (Bugfix) — EIN Agent
- Tasks 2-5 Dateien → Stufe 2 (Lite) — Senior + QS
- Tasks > 5 Dateien → Stufe 3 (Full Scrum) — Volles Team
- NUR relevante Seniors einbeziehen
- Kein Designer für reine Logik-Features
- Kein Backend für reine UI-Änderungen
- Animation Designer NUR bei expliziten Animation-Tasks oder 3D/Video-Features

## Allgemeine Regeln

- Workers diskutieren NICHT — sie implementieren nach Spec
- Seniors planen ERST vollständig, implementieren DANN
- Keine unnötigen Refactorings in Bug-Fix-Tickets
- Shared Types EINMAL definieren, nicht in jeder App

## OMC-spezifische Regeln (wenn installiert)

- OMC-Modi nutzen das gleiche Model-Tiering wie manuelle Orchestrierung
- `ecomode` darf NUR `sonnet` Agents spawnen
- `ultrawork` darf `sonnet` und `sonnetplan` Agents spawnen
- `autopilot` darf alle Tier-Stufen spawnen (inkl. `opusplan` für PO/SM)
- Bei Konflikt zwischen OMC-Config und Template-Tiering gilt IMMER Template-Tiering
