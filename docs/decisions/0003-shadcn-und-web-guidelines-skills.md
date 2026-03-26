---
status: accepted
date: 2026-03-26
decision-makers: [product-owner]
---

# shadcn/ui und Web-Design-Guidelines Skills integrieren

## Kontext

Unser Template hat bereits Impeccable (18 Design-Commands) und den Anthropic Frontend-Design Skill. Es fehlte jedoch:

1. Kontext über korrekte shadcn/ui APIs und CLI-Workflows (Agent halluziniert veraltete Props)
2. Ein systematisches Quality Gate für WCAG-Compliance und UX Best Practices

Vier Skills wurden evaluiert: shadcn/ui, Web-Design-Guidelines, AccessLint, UI/UX Pro Max.

## Entscheidung

### shadcn/ui (offiziell) → Vollständige Integration

Kein Overlap mit Impeccable. Eliminiert API-Halluzinationen. Monorepo-aware. Progressive Disclosure.

### Web-Design-Guidelines (Vercel) → Vollständige Integration

Komplementär zu Impeccable: Impeccable = Ästhetik, WDG = technische Korrektheit. Live-Fetch hält Regeln aktuell.

### AccessLint → Nicht integriert (vorerst)

Signifikanter Overlap mit Impeccable + WDG. Subagent-Spawning widerspricht Model-Tiering. MCP-Tools ggf. später separat.

### UI/UX Pro Max → Nicht integriert

Massiver Overlap mit Impeccable. Python-Dependency. Generisch statt FSD-spezifisch. Token-ineffizient.

## Konsequenzen

### Positiv

- Agents generieren korrekten shadcn-Code mit aktuellen APIs
- Systematische WCAG-Checks als Quality Gate
- Komplette Design-Pipeline: Ästhetik → Code → Compliance

### Negativ

- Ein weiterer Skill erhöht marginale Scan-Last (~100 Tokens)
- Web-Design-Guidelines braucht WebFetch bei jedem Aufruf
