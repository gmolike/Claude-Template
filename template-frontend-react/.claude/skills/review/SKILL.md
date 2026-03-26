---
name: review
description: Code Review nach FSD-Standards, Types, Duplikation, Tests, JSDoc
---

# /review [pfad]

Fuehrt ein umfassendes Code Review durch.

## Checkliste

### FSD Architecture

- [ ] Layer-Hierarchie eingehalten (keine Imports nach oben)
- [ ] Kein Cross-Import zwischen Slices
- [ ] Barrel Files (`index.ts`) vorhanden und korrekt
- [ ] Path Aliases verwendet (`@app/`, `@pages/`, etc.)

### Types

- [ ] API Types aus `generated/api-types.ts` (nicht manuell)
- [ ] Keine `any` oder `@ts-ignore`
- [ ] TypeScript strict konform

### Code Quality

- [ ] JSDoc auf allen exportierten Funktionen/Komponenten
- [ ] Keine hardcodierten Werte (→ `@shared/config/`)
- [ ] Keine Code-Duplikation (unter 5%)
- [ ] Conventional Commits verwendet

### Tests

- [ ] Unit Tests fuer Logik vorhanden
- [ ] Component Tests fuer UI vorhanden
- [ ] Edge Cases abgedeckt

### Documentation

- [ ] CHANGELOG.md aktualisiert
- [ ] JSDoc mit @example wo sinnvoll
