# Integration Analysis: Repo-Empfehlungen für FSD Agent Team Template

## Zusammenfassung

| Repo                         | Empfehlung                  | Aufwand | Priorität |
| ---------------------------- | --------------------------- | ------- | --------- |
| pbakaus/impeccable           | ✅ Vollständige Integration | Niedrig | Hoch      |
| msitarzewski/agency-agents   | ⚠️ Selektive Übernahme      | Mittel  | Mittel    |
| Yeachan-Heo/oh-my-claudecode | ✅ Plugin-Integration       | Hoch    | Hoch      |

---

## Ticket 1: TMPL-101 — Impeccable Design-Skill integrieren

**Priorität:** Hoch
**Aufwand:** S (1-2h)
**Assignee:** Senior Frontend / Designer
**Tags:** frontend, design, skill

### Beschreibung

Das `pbakaus/impeccable`-Paket liefert einen erweiterten `frontend-design` Skill mit 7 Referenz-Dateien und 17 Slash-Commands, der auf Anthropic's eigenem Frontend-Design-Skill aufbaut. Es bekämpft systematisch typische LLM-Design-Fehler (Inter-Font, Purple Gradients, verschachtelte Cards, graue Schrift auf farbigem Hintergrund).

### Was es bringt

- 17 Design-Commands: `/audit`, `/polish`, `/normalize`, `/distill`, `/animate`, `/bolder`, `/quieter`, `/colorize`, `/clarify`, `/delight`, `/adapt`, `/extract`, `/review-design`, `/a11y`, `/responsive`, `/dark-mode`, `/simplify`
- Kuratierte Anti-Patterns (explizite "was NICHT tun"-Regeln)
- 7 Referenz-Dateien (Typografie, Farb-Kontraste, Animationen, etc.)

### Integration in Template

1. `npx skills add pbakaus/impeccable` im Template ausführen
2. Ergebnis: `.claude/skills/frontend-design/SKILL.md` + 7 Referenzen + 17 Commands in `.claude/commands/`
3. Designer-Agent (`designer.md`) Frontmatter erweitern um Skill-Referenz
4. Bestehenden `/design`-Skill mit Impeccable-Commands verknüpfen (kein Konflikt — komplementär)
5. `TEMPLATE_SETUP.md` aktualisieren

### Acceptance Criteria

- [ ] Impeccable Skills + Commands im Template installiert
- [ ] Designer-Agent referenziert den erweiterten Skill
- [ ] `/audit` und `/polish` funktionieren in Claude Code
- [ ] Kein Konflikt mit bestehendem `/design` Skill
- [ ] Anti-Patterns sind für alle Frontend-Agents sichtbar

### Betroffene Dateien

- `.claude/skills/frontend-design/` (NEU)
- `.claude/commands/*.md` (NEU, 17 Dateien)
- `.claude/agents/designer.md` (UPDATE)
- `TEMPLATE_SETUP.md` (UPDATE)
- `CHANGELOG.md` (UPDATE)

---

## Ticket 2: TMPL-102 — Agency-Agents: Selektive Persona-Übernahme

**Priorität:** Mittel
**Aufwand:** M (3-5h)
**Assignee:** Scrum Master / PO
**Tags:** agents, process, template

### Beschreibung

Das `msitarzewski/agency-agents`-Repo bietet 147 Agents in 12 Divisions. Unsere 10 bestehenden Agents haben bereits striktes Model-Tiering — die Agency-Agents NICHT. Daher: keine 1:1-Übernahme, sondern gezielte Extraktion von Best Practices.

### Was wir übernehmen

**A) Agent-Persona-Muster (für bestehende Agents):**

- Success Metrics pro Agent (messbare Erfolgskriterien)
- Deliverable-Templates (strukturierte Ausgabeformate)
- "I don't just..." Persönlichkeits-Patterns (schärfere Rollenabgrenzung)
- Explizite Prozess-Schritte pro Agent

**B) Neue Agent-Rollen evaluieren (optional):**

- Reality Checker → Integration in Senior QS Agent
- Security Reviewer → Neuer Agent oder Senior QS Erweiterung

**C) NICHT übernehmen:**

- Kein Ersetzen unserer Model-Tiering-Strategie
- Keine generischen Marketing/Growth-Agents (nicht relevant für Dev-Template)
- Kein globales Install nach `~/.claude/agents/` (wir nutzen projekt-scoped)

### Integration in Template

1. Agent-Dateien analysieren (Frontmatter-Struktur, Persona-Pattern)
2. Bestehende 10 Agents um Success Metrics + Deliverable-Templates erweitern
3. Optional: Security-Reviewer Agent hinzufügen (mit unserem Model-Tiering: `sonnet`)
4. ADR erstellen: "Warum selektive Übernahme statt Vollintegration"

### Acceptance Criteria

- [ ] Alle 10 bestehenden Agents haben Success Metrics
- [ ] Alle 10 Agents haben Deliverable-Templates
- [ ] ADR dokumentiert die Entscheidung
- [ ] Model-Tiering bleibt unverändert (opusplan/sonnetplan/sonnet)
- [ ] Kein Agent ohne explizite Rollenbeschreibung

### Betroffene Dateien

- `.claude/agents/*.md` (UPDATE alle 10)
- `docs/decisions/XXXX-selective-agency-adoption.md` (NEU)
- `CHANGELOG.md` (UPDATE)

---

## Ticket 3: TMPL-103 — Oh My Claude Code: Orchestrierungs-Plugin integrieren

**Priorität:** Hoch
**Aufwand:** L (5-8h)
**Assignee:** Scrum Master / Senior Backend
**Tags:** orchestration, plugin, automation

### Beschreibung

`oh-my-claudecode` (OMC) ist ein Claude Code Plugin mit 5 Execution-Modi, 32 Agents und 31+ Skills. Es automatisiert die Orchestrierung, die unser Scrum Master aktuell manuell übernimmt. OMC nutzt Claude Code's native Teams und Hooks-System.

### Mapping auf unseren Workflow

| Unser Workflow       | OMC-Modus            | Vorteil                          |
| -------------------- | -------------------- | -------------------------------- |
| Stufe 1 — Bugfix     | `ecomode` / `ralph`  | Token-effizient, persistent      |
| Stufe 2 — Lite       | `ultrawork`          | Parallele Execution              |
| Stufe 3 — Full Scrum | `autopilot` / `team` | Volle Autonomie mit Verification |
| Code Review          | `ultraqa`            | Automatisiertes QA               |
| Planning             | `/deep-interview`    | Socratic Questioning vor Impl.   |

### Integration in Template

1. OMC als Plugin-Abhängigkeit im Template deklarieren
2. `TEMPLATE_SETUP.md` um OMC-Setup erweitern:
   ```
   /plugin marketplace add https://github.com/Yeachan-Heo/oh-my-claudecode
   /plugin install oh-my-claudecode
   /oh-my-claudecode:omc-setup
   ```
3. Scrum Master Agent um OMC-Delegation erweitern (Magic Keywords in Workflow-Stufen-Entscheidung)
4. `.claude/rules/token-efficiency.md` um OMC-spezifische Model-Routing-Regeln erweitern
5. OMC Config (`.omc-config.json`) mit unseren Workflow-Stufen vorbelegen
6. `/scrum` Skill erweitern: automatische Erkennung ob OMC installiert ist
7. Hooks integrieren: `conversationStart` → Scrum-Board Status laden

### Konfiguration

```json
// .omc-config.json (Template-Default)
{
  "defaultExecutionMode": "ecomode",
  "teamDefaults": {
    "maxAgents": 5,
    "verifyWithArchitect": true
  }
}
```

### Acceptance Criteria

- [ ] OMC Plugin installierbar über `TEMPLATE_SETUP.md`
- [ ] Workflow-Stufen 1/2/3 mappen auf OMC-Modi
- [ ] Scrum Master delegiert an OMC bei entsprechendem Keyword
- [ ] Model-Tiering wird von OMC respektiert (kein Override)
- [ ] `/omc-doctor` zeigt grünen Status
- [ ] Fallback: Template funktioniert AUCH ohne OMC (optional dependency)
- [ ] ADR dokumentiert OMC-Integration

### Betroffene Dateien

- `TEMPLATE_SETUP.md` (UPDATE)
- `.claude/agents/scrum-master.md` (UPDATE)
- `.claude/rules/token-efficiency.md` (UPDATE)
- `.claude/skills/scrum/SKILL.md` (UPDATE)
- `docs/decisions/XXXX-omc-orchestration.md` (NEU)
- `CHANGELOG.md` (UPDATE)

---

## Ticket 4: TMPL-104 — ADR: Integration externer Agent-Tools

**Priorität:** Hoch (Blocker für TMPL-101/102/103)
**Aufwand:** S (1h)
**Assignee:** PO
**Tags:** docs, architecture

### Beschreibung

Architektur-Entscheidung (MADR-Format) dokumentieren, die erklärt:

- Warum Impeccable vollständig übernommen wird
- Warum Agency-Agents nur selektiv übernommen werden
- Warum OMC als optionales Plugin integriert wird
- Hard Rule: Keine Dependency die unser Model-Tiering bricht

### Acceptance Criteria

- [ ] ADR in `docs/decisions/` im MADR-Format
- [ ] Referenziert alle drei Repos mit Begründung
- [ ] Definiert "Template-Kompatibilitäts-Kriterien" für zukünftige Tool-Evaluierung
