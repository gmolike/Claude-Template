---
name: review
description: 'Code Review nach Hono Backend-Standards durchführen mit Validierungs-Check, Service-Layer-Validierung und Qualitätsprüfung. Nutze bei Code Reviews oder wenn der User seinen Code prüfen lassen will.'
argument-hint: '[datei-oder-ordner-pfad]'
allowed-tools: Read, Bash, Glob, Grep
disable-model-invocation: true
---

# Code Review — Hono Backend Standards

Du führst ein umfassendes Code Review nach den Backend-Projektstandards durch.

## Scope bestimmen

- Wenn `$ARGUMENTS` leer: Review alle Dateien im aktuellen `git diff --staged` oder `git diff HEAD~1`
- Wenn `$ARGUMENTS` ein Pfad ist: Review nur diesen Pfad
- Wenn `$ARGUMENTS` "all" ist: Review gesamtes `src/` Verzeichnis

## Review-Checkliste

Prüfe JEDEN Punkt und bewerte mit ✅ ❌ ⚠️:

### 1. Architektur-Schichtentrennung

- [ ] **Routes sind duenn** — Keine Business Logic in Route-Handlern
- [ ] **Services enthalten Business Logic** — Alle DB-Zugriffe und Logik in `services/`
- [ ] **Middleware korrekt genutzt** — Auth, Validation, Error via Middleware
- [ ] **Validators getrennt** — Zod Schemas in `validators/`, nicht inline

### 2. Zod-Validierung

- [ ] **Alle Endpunkte validiert** — `zValidator` auf allen POST/PATCH/PUT Endpunkten
- [ ] **Schemas exportiert** — Wiederverwendbare Schemas aus `validators/`
- [ ] **Type-Inference** — Types per `z.infer<>` abgeleitet, nicht manuell definiert
- [ ] **Fehler-Response** — ZodError wird vom errorHandler abgefangen

### 3. TypeScript Quality

- [ ] **Strict Mode konform** — Kein `any`, kein `@ts-ignore`, kein `@ts-expect-error`
- [ ] **Explizite Return-Types** — Auf allen exportierten Funktionen
- [ ] **`noUncheckedIndexedAccess`** — Array-Zugriffe korrekt gehandhabt
- [ ] **Kein `as` Type-Assertion** — Wenn doch, kommentiert warum

### 4. Error Handling

- [ ] **Konsistente Fehler-Responses** — Immer `{ error: { code, message } }` Format
- [ ] **HTTP-Status korrekt** — 400 Validation, 401 Auth, 404 Not Found, 409 Conflict, 500 Internal
- [ ] **Unhandled Errors** — Alle async Fehler werden gefangen
- [ ] **Prisma Errors** — NotFoundError und UniqueConstraintError behandelt

### 5. Documentation

- [ ] **JSDoc auf allen Exports** — Services, Middleware, Validators
- [ ] **@param und @returns** — Auf allen Service-Methoden
- [ ] **CHANGELOG.md aktualisiert** — `[Unreleased]` Abschnitt

### 6. Tests

- [ ] **Tests vorhanden** — Fuer jeden neuen Service und Route
- [ ] **Happy Path getestet** — Erfolgreiche Szenarien
- [ ] **Error Cases** — Mindestens 404, 401, Validation Error
- [ ] **Mocks** — Prisma Client korrekt gemockt

## Output-Format

Erstelle einen strukturierten Review-Report:

```markdown
# Code Review: [Scope]

## Zusammenfassung

[1-2 Sätze Gesamtbewertung]

## Score: X/6 Kategorien bestanden

### ✅ Bestanden

- [Kategorie]: [kurze Begründung]

### ❌ Nicht bestanden

- [Kategorie]: [was fehlt, wo genau, wie zu fixen]

### ⚠️ Warnungen

- [Kategorie]: [kein Blocker, aber verbesserbar]

## Empfohlene Aktionen

1. [Konkrete Aktion mit Dateipfad]
2. [...]
```

## Schweregrade

- **❌ Blocker** — Muss gefixt werden: fehlende Zod-Validierung, Business Logic in Routes, fehlender Error Handler
- **⚠️ Warning** — Sollte gefixt werden: Fehlende JSDoc, fehlende Tests
- **💡 Hinweis** — Nice-to-have: Prisma Query-Optimierungen, bessere Namensgebung
