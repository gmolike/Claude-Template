---
status: accepted
date: 2026-03-15
decision-makers: [product-owner, scrum-master]
---

# Integration externer Agent-Tools in das FSD Template

## Kontext

Drei externe Repositories wurden als potenzielle Erweiterungen für unser Claude Code Agent Team Template evaluiert:

1. **pbakaus/impeccable** — Frontend-Design-Skill mit Anti-Pattern-Regeln
2. **msitarzewski/agency-agents** — 147 Agents in 12 Divisions mit Persona-Patterns
3. **Yeachan-Heo/oh-my-claudecode (OMC)** — Orchestrierungs-Plugin mit 5 Execution-Modi

Das Template hat bereits ein striktes Model-Tiering (opusplan/sonnetplan/sonnet) und 10 fest definierte Agent-Rollen. Jede Integration muss diese Grundprinzipien respektieren.

## Entscheidung

### 1. Impeccable → Vollständige Integration

**Begründung:** Der Skill ist komplementär zu unserem bestehenden Design-Workflow. Er liefert konkrete Anti-Patterns und Design-Commands die unsere Agents aktuell nicht haben. Kein Konflikt mit Model-Tiering — es ist ein reiner Skill, keine Agent-Rolle.

- Installation via `npx skills add pbakaus/impeccable`
- 17 neue Slash-Commands für Design-Qualität
- 7 Referenz-Dateien für Anti-Patterns
- Designer-Agent referenziert den erweiterten Skill

### 2. Agency-Agents → Selektive Übernahme

**Begründung:** Die 147 Agents sind größtenteils nicht relevant (Marketing, Growth, etc.) und haben KEIN Model-Tiering. Eine Vollintegration würde unsere Token-Effizienz-Strategie brechen. Aber: die Persona-Patterns (Success Metrics, Deliverable-Templates, explizite Prozess-Schritte) sind wertvoll und fehlen in unseren Agents.

**Übernommen:**

- Success Metrics pro Agent (messbare Erfolgskriterien)
- Deliverable-Templates (strukturierte Ausgabeformate)
- Schärfere Rollenabgrenzung ("I don't just...")
- Explizite Prozess-Schritte

**Nicht übernommen:**

- Keine neuen Agent-Rollen (147 → wir bleiben bei 10)
- Kein Ersetzen unserer Model-Tiering-Strategie
- Keine generischen Marketing/Growth-Agents
- Kein globales Install nach `~/.claude/agents/`

### 3. OMC → Optionales Plugin

**Begründung:** OMC automatisiert Orchestrierung die unser Scrum Master manuell macht. Aber: es ist eine externe Dependency die nicht jedes Template-Projekt braucht. Daher: optionale Integration mit Fallback.

- Template funktioniert AUCH ohne OMC
- Workflow-Stufen mappen auf OMC-Modi (ecomode/ultrawork/autopilot)
- Scrum Master erkennt ob OMC installiert ist
- Model-Tiering darf von OMC nicht überschrieben werden

## Template-Kompatibilitäts-Kriterien

Für zukünftige Tool-Evaluierungen gelten folgende Hard Rules:

1. **Model-Tiering First:** Kein Tool darf unser opusplan/sonnetplan/sonnet Tiering brechen oder überschreiben
2. **Projekt-Scoped:** Alles lebt im Projekt-Verzeichnis (`.claude/`), nicht global (`~/.claude/`)
3. **Opt-In:** Externe Dependencies sind IMMER optional — das Template muss ohne sie funktionieren
4. **Komplementär:** Tools dürfen bestehende Funktionalität ergänzen, nicht ersetzen
5. **Token-Bewusst:** Kein Tool das unkontrolliert Token verbraucht (z.B. durch unnötige Agent-Spawns)

## Konsequenzen

### Positiv

- Designer-Agent bekommt konkrete Anti-Pattern-Regeln statt generischer Richtlinien
- Alle Agents haben messbare Erfolgskriterien und strukturierte Outputs
- Orchestrierung kann bei Bedarf automatisiert werden (OMC)
- Klare Evaluierungskriterien für zukünftige Tools

### Negativ

- 17 neue Slash-Commands erhöhen die Einstiegskomplexität
- OMC als optionale Dependency erfordert Conditional-Logic im Scrum Master
- Success Metrics müssen pro Agent definiert und gepflegt werden
