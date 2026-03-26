# Skill: /review

Code Review fuer Mobile (React Native + Expo) mit FSD-Checks.

## Checkliste

### FSD-Architektur

- [ ] Korrekter Layer (screens/features/entities/shared)
- [ ] index.ts Public API vorhanden
- [ ] Imports nur von niedrigeren Layern
- [ ] Kein Cross-Import zwischen Slices

### Code-Qualitaet

- [ ] TypeScript strict — kein `any`, kein `@ts-ignore`
- [ ] JSDoc auf allen exportierten Funktionen
- [ ] Keine hardcodierten Werte — alles in `shared/config/`
- [ ] API-Types aus `generated/api-types.ts`

### React Native

- [ ] Kein `react-dom` Import
- [ ] Platform-spezifischer Code korrekt isoliert
- [ ] Performance: keine teuren Operationen in Render

### Tests

- [ ] Tests fuer jeden Export vorhanden
- [ ] Jest + React Native Testing Library

## Ausgabe-Format

```markdown
## Review: [Dateiname]

### Befunde

- [CRITICAL/WARNING/INFO] Beschreibung

### FSD-Check

- Layer: [korrekt/falsch]
- Public API: [vorhanden/fehlt]
- Imports: [sauber/Verletzungen]

### Empfehlung

[APPROVE / REQUEST_CHANGES]
```
