---
name: design-briefing
description: UI-/UX-Brief vor Frontend-Story-Implementierung erstellen
---

# Design-Briefing

Wird vom Designer-Profil verwendet, bevor eine UI-Story implementiert wird. Sorgt für Spec-Treue über die 3 Frontend-Repos hinweg (`lore-admin`, `session-gm`, `session-player`).

## Workflow

1. Story-Anforderung lesen (`.scrum/backlog/STORY-XXX.md`)
2. Ziel-Screen(s) identifizieren — neu oder bestehend?
3. Brief schreiben (Template unten) → ablegen in `.scrum/repos/<repo>/designs/STORY-XXX-brief.md` (oder direkt im Story-File)
4. Bei neuem Screen: Stitch-Design oder Skizze referenzieren
5. Design-Tokens prüfen — passt das Bestehende oder braucht es neue?

## Brief-Template

```markdown
---
story: STORY-XXX
feature: [Feature-Name]
screens: [Liste]
priority: P1
---

### Kontext
[Welches User-Problem löst dieses UI? Welcher Use-Case (`.scrum/usecases/`) ist verbunden?]

### Screens

#### Screen 1: [Name]
- Layout: [Beschreibung — Sections, Komponenten-Typen]
- Daten-Quellen: [welche API-Endpoints / Stores]
- Interaktionen: [welche User-Actions, was passiert]
- States: empty / loading / error / success

#### Screen 2: ...

### Design-Tokens

Welche Tokens werden benutzt (aus `<repo>/.claude/rules/design-tokens.md`):
- Colors: [primary, surface, accent, danger]
- Typography: [heading-XL, body-M, ...]
- Spacing: [4 / 8 / 12 / 16 / 24]
- Border-Radius / Elevation: ...

Falls neue Tokens gebraucht → in welchem Repo? Cross-Repo? → kurz begründen.

### Komponenten

Bestehende Components reusen oder neu? Liste:
- ✅ Reuse: `<Button>`, `<DataTable>`
- 🆕 Neu: `<EncounterPicker>` — siehe Spec unten

### Accessibility

- Keyboard-Navigation: [Tab-Order, Shortcuts]
- Screen-Reader: [ARIA-Labels, Landmarks]
- Color-Contrast: WCAG AA (4.5:1 normal, 3:1 large)
- Reduced-Motion: Animationen via `prefers-reduced-motion`

### Responsive

- Mobile (< 640px): Layout-Änderungen?
- Desktop (≥ 1024px): Hauptlayout
- Print? (selten)

### Cross-Frontend-Konsistenz

Falls dieses UI-Pattern auch in einem anderen Frontend existiert (z.B. Picker-Pattern in lore-admin + session-gm) → Verweis auf Pendant. **Picker-Regel:** "Neu erstellen" muss immer sichtbar sein, auch bei N=1 (siehe `workflow-defaults.md` Punkt 4).
```

## Verwandte Dokumente

- `<repo>/.claude/rules/design-tokens.md` — Design-Token-Referenz pro Frontend
- `<repo>/.claude/rules/fsd-architecture.md` — wo Components landen
- `.claude/rules/workflow-defaults.md` — Picker-Regel und andere UI-Defaults
