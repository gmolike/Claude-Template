---
name: fsd-review
description: 'Code Review nach FSD-Standards durchführen mit Duplikations-Check, Layer-Validierung und Qualitätsprüfung. Nutze bei Code Reviews, Quality Gates oder wenn der User seinen Code prüfen lassen will.'
argument-hint: '[datei-oder-ordner-pfad]'
allowed-tools: Read, Bash, Glob, Grep
disable-model-invocation: true
---

# Code Review — FSD Standards

Du führst ein umfassendes Code Review nach den Projektstandards durch.

## Scope bestimmen

- Wenn `$ARGUMENTS` leer: Review alle Dateien im aktuellen `git diff --staged` oder `git diff HEAD~1`
- Wenn `$ARGUMENTS` ein Pfad ist: Review nur diesen Pfad
- Wenn `$ARGUMENTS` "all" ist: Review gesamtes `src/` Verzeichnis

## Review-Checkliste

Prüfe JEDEN Punkt und bewerte mit ✅ ❌ ⚠️:

### 1. FSD Architecture

```
Befehl: Analysiere Import-Pfade in den betroffenen Dateien
```

- [ ] **Layer-Hierarchie korrekt** — Imports nur von niedrigeren Layern
  - app → routes → pages → widgets → features → entities → shared
  - Kein Import von höheren Layern (z.B. features darf NICHT pages importieren)
- [ ] **Kein Cross-Slice-Import** — Slices auf gleichem Layer importieren sich nicht gegenseitig
- [ ] **Public API vorhanden** — Jeder Slice hat `index.ts` als einzigen Export-Punkt
- [ ] **Imports über Barrel** — Externe Imports gehen über `index.ts`, nicht direkt in Slice-Interna

### 2. Shared Types — Single Source of Truth

- [ ] **Types in `@repo/shared-types`** — Keine lokalen Type-Definitionen die shared sein sollten
- [ ] **Zod Schemas vorhanden** — Runtime-Validierung für API-Grenzen
- [ ] **Type-Inference** — Types werden aus Zod Schemas abgeleitet (`z.infer<>`)
- [ ] **Keine Duplikation** — Gleiche Types nicht in mehreren Apps definiert

### 3. TanStack Query/Router

- [ ] **Query Factory Pattern** — `queryOptions()` in `entities/*/api/`
- [ ] **Mutations in Features** — Nicht in Entities
- [ ] **Routes sind dünn** — Logik in FSD Pages, nicht in Route-Dateien
- [ ] **Loader nutzen queryClient** — `queryClient.ensureQueryData()` in Route-Loadern

### 4. TypeScript Quality

- [ ] **Strict Mode konform** — Kein `any`, kein `@ts-ignore`, kein `@ts-expect-error`
- [ ] **Explizite Return-Types** — Auf allen exportierten Funktionen
- [ ] **`noUncheckedIndexedAccess`** — Array-Zugriffe korrekt gehandhabt
- [ ] **Kein `as` Type-Assertion** — Wenn doch, kommentiert warum

### 5. Documentation

- [ ] **JSDoc auf allen Exports** — Funktionen, Komponenten, Types, Hooks
- [ ] **@example vorhanden** — Mindestens auf Komponenten und Hooks
- [ ] **CHANGELOG.md aktualisiert** — `[Unreleased]` Abschnitt

### 6. Code-Duplikation

Führe aus:

```bash
npx jscpd --min-tokens 50 --reporters console [pfad-zum-scope]
```

- [ ] **Keine neuen Duplikate** — jscpd meldet keine neuen Clones
- [ ] **Cross-App Duplikation** — Gleicher Code nicht in web UND api
- [ ] **Kandidaten für Shared** — Code der in mehreren Apps vorkommt → `packages/shared-*`

### 7. Tests

- [ ] **Tests vorhanden** — Für jeden neuen Export
- [ ] **Alle States getestet** — Loading, Error, Empty, Success
- [ ] **Edge Cases** — Mindestens die offensichtlichen

## Output-Format

Erstelle einen strukturierten Review-Report:

```markdown
# Code Review: [Scope]

## Zusammenfassung

[1-2 Sätze Gesamtbewertung]

## Score: X/7 Kategorien bestanden

### ✅ Bestanden

- [Kategorie]: [kurze Begründung]

### ❌ Nicht bestanden

- [Kategorie]: [was fehlt, wo genau, wie zu fixen]

### ⚠️ Warnungen

- [Kategorie]: [kein Blocker, aber verbesserbar]

## Duplikations-Report

[jscpd Ergebnis]

## Empfohlene Aktionen

1. [Konkrete Aktion mit Dateipfad]
2. [...]
```

## Schweregrade

- **❌ Blocker** — Muss gefixt werden: FSD-Verletzungen, Type-Duplikation, fehlende Public API
- **⚠️ Warning** — Sollte gefixt werden: Fehlende JSDoc, fehlende Tests
- **💡 Hinweis** — Nice-to-have: Performance-Optimierungen, bessere Namensgebung
