# Documentation Rules

## Pflicht-Dokumentation bei jeder Änderung

1. **CHANGELOG.md** — `[Unreleased]` Abschnitt aktualisieren
   - Added: Neue Features
   - Changed: Änderungen an bestehenden Features
   - Fixed: Bug Fixes
   - Removed: Entfernte Features

2. **JSDoc** — Auf ALLEN exportierten Funktionen, Komponenten und Types

   ````typescript
   /**
    * Kurzbeschreibung.
    *
    * @param name - Beschreibung des Parameters
    * @returns Beschreibung des Rückgabewerts
    * @example
    * ```tsx
    * <MyComponent name="test" />
    * ```
    */
   ````

3. **ADR** — Bei Architektur-Entscheidungen in `docs/decisions/`
   Format: `XXXX-kurzbeschreibung.md` (MADR 4.0.0)

4. **Scrum-Board** — Task-Dateien in `.scrum/` aktualisieren
   - Status ändern durch Verschieben zwischen Ordnern
   - Acceptance Criteria abhaken
