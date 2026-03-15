---
status: accepted
date: 2026-03-15
decision-makers: [scrum-master, senior-backend]
---

# Oh My Claude Code als optionales Orchestrierungs-Plugin

## Kontext

Die manuelle Orchestrierung durch den Scrum Master Agent funktioniert, ist aber bei Full-Scrum-Workflows (Stufe 3) Token-intensiv und erfordert explizite Delegation für jeden Task. OMC bietet 5 Execution-Modi die unsere Workflow-Stufen direkt mappen.

## Entscheidung

OMC wird als OPTIONALES Plugin integriert. Das Template funktioniert vollständig ohne OMC. Bei Installation ergänzt OMC die manuelle Orchestrierung, ersetzt sie aber nicht.

### Hard Rules

1. Model-Tiering wird NICHT von OMC überschrieben
2. OMC ist eine optionale Dependency — kein Pflicht-Setup
3. Scrum Master prüft ob OMC installiert ist und wählt entsprechend
4. Alle OMC-Modi müssen Template-Tiering respektieren

## Konsequenzen

### Positiv

- Automatisierte Orchestrierung bei Stufe 3 Tasks
- Parallele Agent-Execution spart Zeit
- Verification-Loop in autopilot-Modus erhöht Qualität

### Negativ

- Zusätzliche Komplexität durch Conditional-Logic im Scrum Master
- OMC-Updates können Template-Kompatibilität brechen
- Debugging wird komplexer bei OMC-orchestrierten Workflows
