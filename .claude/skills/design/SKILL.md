---
name: design
description: Design-Workflow mit Canva-MCP-Integration
user_invocable: true
---

# /design — Design-Workflow

## Subcommands

### `/design briefing <beschreibung>`

Erstelle ein Design-Briefing für das beschriebene Feature.

**Schritte:**

1. Analysiere die Feature-Beschreibung
2. Recherchiere bestehende UI-Patterns im Projekt (Glob + Read)
3. Erstelle Briefing-Dokument:
   - Zielgruppe und Kontext
   - Gewünschte User Journey
   - UI-Patterns und Referenzen
   - Technische Constraints (FSD-Layer, bestehende Komponenten)
4. Speichere als `.scrum/<domäne>/in-progress/DESIGN-<id>-briefing.md`
5. **Fordere PO-Freigabe an** bevor Visual Concept beginnt

### `/design concept`

Erstelle Visual Concept über Canva MCP.

**Voraussetzung:** Freigegebenes Briefing vorhanden.

**Schritte:**

1. Lade freigegebenes Briefing
2. Erstelle Design über Canva MCP (generate-design)
3. Generiere min. 2 Varianten
4. Dokumentiere Unterschiede und Empfehlung
5. **Fordere PO-Review an**

### `/design review`

Führe Design-Review Checkliste durch.

**Prüfpunkte:**

- [ ] Konsistenz mit bestehendem Design-System
- [ ] Accessibility (Kontrast, Fokus-Management, Screen-Reader)
- [ ] Responsive Verhalten (Mobile, Tablet, Desktop)
- [ ] FSD-Kompatibilität (Component-Mapping möglich?)
- [ ] Performance-Implikationen (Bilder, Animationen)
- [ ] Dark/Light Mode Kompatibilität

### `/design export`

Exportiere finalisiertes Design aus Canva.

**HARD RULE: Kein Export ohne explizite User-Freigabe!**

**Schritte:**

1. Zeige Design-Zusammenfassung
2. Frage explizit: "Soll das Design exportiert werden? (ja/nein)"
3. NUR bei "ja": Export über Canva MCP (export-design)
4. Speichere Export-Referenz im Briefing-Dokument
