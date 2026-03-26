---
name: design
description: 'Design-Workflow mit Canva-MCP. Briefing erstellen, Visual Concept generieren, Component Structure definieren.'
argument-hint: '[briefing|concept|review]'
allowed-tools: Read, Write, Edit, Glob, Grep
---

# Design-Workflow

3-Stufen-Freigabe-Workflow fuer UI/UX Design.

## `/design briefing`

Erstelle Design-Brief fuer ein Feature:

1. Analysiere Feature-Spec in `.scrum/`
2. Erstelle `docs/designs/FEAT-XXX-briefing.md`:
   - Zielgruppe und Use Case
   - UI-Patterns und Interaktionsmodell
   - Farbschema und Typografie-Empfehlung
   - Responsive-Strategie
   - Referenz-Screenshots oder Inspirationen
3. **PO-Freigabe erforderlich** bevor Visual Concept

## `/design concept`

Nach Briefing-Freigabe:

1. Nutze Canva MCP fuer Visual Concept
2. Generiere Design-Varianten (min. 2)
3. Dokumentiere Design-Entscheidungen
4. **PO-Review** des Visual Concepts

## `/design review`

Nach Implementation im Frontend-Repo:

1. Pruefe ob Implementation dem Design entspricht
2. Accessibility-Check (WCAG 2.1 AA)
3. Responsive-Check
4. Erstelle Review-Report

## Hard Rules

- KEIN Canva-Export ohne explizite User-Freigabe
- Design-Entscheidungen IMMER dokumentieren
- Accessibility ist Pflicht, nicht optional
- Mobile-First bei Responsive Design
