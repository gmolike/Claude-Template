---
name: commit
description: 'Smart Commit erstellen: Git-Status prüfen, Conventional Commit Message generieren, CHANGELOG.md aktualisieren. Nutze bei Commits oder wenn der User Änderungen commiten will.'
argument-hint: '[optionale commit-nachricht]'
allowed-tools: Read, Write, Edit, Bash(git:*), Bash(pnpm:*), Bash(cat:*), Bash(grep:*)
disable-model-invocation: true
---

# Smart Commit

Du erstellst einen vollständigen, qualitätsgeprüften Commit.

## Prozess

### Schritt 1: Status prüfen

Führe aus und analysiere:

```bash
git status --short
git diff --staged --stat
git diff --staged
```

Wenn nichts gestaged ist:

```bash
git diff --stat
```

Frage den User ob alles oder bestimmte Dateien gestaged werden sollen.

### Schritt 2: Pre-Commit Checks

Führe die Qualitäts-Checks aus:

```bash
pnpm run lint 2>&1 | tail -20
pnpm run typecheck 2>&1 | tail -20
```

Wenn Fehler auftreten:

- Zeige die Fehler übersichtlich an
- Frage ob der User sie fixen will bevor committed wird
- Bei Lint-Fehlern: Biete `pnpm run lint:fix` an

### Schritt 3: Commit-Message generieren

Analysiere die Änderungen und generiere eine Conventional Commit Message:

**Format:**

```
<type>(<scope>): <beschreibung>

[optionaler body]

[optionaler footer]
```

**Types:**
| Type | Wann |
|------|------|
| `feat` | Neues Feature |
| `fix` | Bug Fix |
| `docs` | Nur Dokumentation |
| `style` | Formatierung (kein Code-Änderung) |
| `refactor` | Code-Änderung ohne Feature/Fix |
| `perf` | Performance-Verbesserung |
| `test` | Tests hinzugefügt/geändert |
| `chore` | Build, Dependencies, Tooling |
| `ci` | CI/CD Änderungen |
| `revert` | Revert eines früheren Commits |
| `build` | Build-System Änderungen |

**Scope** (aus den geänderten Pfaden ableiten):

- `apps/web/` → `web`
- `apps/api/` → `api`
- `apps/mobile/` → `mobile`
- `packages/shared-types/` → `shared-types`
- `packages/shared-ui/` → `shared-ui`
- `packages/shared-api/` → `shared-api`
- `.claude/` → `agents`
- `.scrum/` → `scrum`
- `.github/` → `ci`
- Mehrere Scopes → nutze den dominantesten oder keinen Scope

**Regeln für die Beschreibung:**

- Imperativ, Kleinschreibung, kein Punkt am Ende
- Max 72 Zeichen
- Deutsch ist OK wenn das Projekt deutsch ist
- Body erklärt WARUM, nicht WAS (das sieht man im Diff)

Wenn `$ARGUMENTS` angegeben: Nutze es als Basis für die Message.
Wenn nicht: Generiere automatisch aus dem Diff.

### Schritt 4: CHANGELOG.md aktualisieren

Prüfe ob `CHANGELOG.md` bereits aktualisiert wurde (im Diff).
Wenn nicht, füge unter `## [Unreleased]` den passenden Eintrag hinzu:

```markdown
### Added

- Neue Feature-Beschreibung

### Changed

- Was sich geändert hat

### Fixed

- Bug der gefixt wurde
```

Stage die CHANGELOG-Änderung mit:

```bash
git add CHANGELOG.md
```

### Schritt 5: Scrum-Board prüfen

Prüfe ob es einen passenden Task in `.scrum/in-progress/` gibt.
Wenn ja: Frage ob der Task nach `review/` oder `done/` verschoben werden soll.

### Schritt 6: Commit ausführen

Zeige dem User die vollständige Zusammenfassung:

```
📝 Commit Message:
  feat(web): implement user profile page

📄 CHANGELOG.md:
  Added: User profile page with avatar upload

📋 Scrum:
  FEAT-003 → von in-progress nach review verschoben

🔍 Staged Files (5):
  M  apps/web/src/pages/profile/ui/profile-page.tsx
  A  apps/web/src/pages/profile/index.ts
  ...

Commit ausführen? [j/n]
```

Erst nach Bestätigung:

```bash
git commit -m "<message>"
```

## Regeln

- NIEMALS ohne User-Bestätigung committen
- IMMER Pre-Commit Checks ausführen
- CHANGELOG.md MUSS aktualisiert sein
- Commit-Message MUSS Conventional Commits Format haben
- Bei Breaking Changes: `!` nach dem Type hinzufügen und `BREAKING CHANGE:` im Footer
