---
name: commit
description: Smart Commit mit Lint, Typecheck, Conventional Commit und Changelog
---

# /commit [nachricht]

Erstellt einen qualitaetsgesicherten Commit.

## Workflow

1. `pnpm lint` ausfuehren — bei Fehlern abbrechen
2. `pnpm typecheck` ausfuehren — bei Fehlern abbrechen
3. `pnpm test` ausfuehren — bei Fehlern abbrechen
4. CHANGELOG.md pruefen — `[Unreleased]` muss aktualisiert sein
5. Conventional Commit Message erstellen:
   - `feat:` — Neues Feature
   - `fix:` — Bug Fix
   - `docs:` — Dokumentation
   - `chore:` — Maintenance
   - `refactor:` — Refactoring
   - `test:` — Tests
   - `style:` — Formatting
6. `git add` relevante Dateien (NICHT `git add -A`)
7. `git commit` mit Conventional Commit Message
8. Zusammenfassung anzeigen

## Regeln

- NIEMALS `git add -A` oder `git add .`
- NIEMALS `--no-verify` verwenden
- Bei Hook-Fehlern: Fix und NEUEN Commit erstellen (nicht amend)
