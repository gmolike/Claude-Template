# Skill: /commit

Smart Commit fuer Mobile-Codebase.

## Ablauf

1. `git status` — Geaenderte Dateien pruefen
2. `pnpm lint` — ESLint ausfuehren
3. `pnpm typecheck` — TypeScript pruefen
4. `pnpm test` — Tests ausfuehren
5. Conventional Commit Message erstellen
6. CHANGELOG.md `[Unreleased]` aktualisieren
7. Commit erstellen

## Commit-Format

```
feat(mobile): kurze Beschreibung

Ausfuehrlichere Erklaerung wenn noetig.

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Typen

- `feat` — Neues Feature
- `fix` — Bug Fix
- `refactor` — Refactoring ohne Funktionsaenderung
- `test` — Tests hinzufuegen oder aendern
- `chore` — Build, CI, Abhaengigkeiten
- `docs` — Dokumentation
