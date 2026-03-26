# Documentation Rules — Frontend

## Pflicht-Dokumentation bei jeder Aenderung

1. **CHANGELOG.md** — `[Unreleased]` Abschnitt aktualisieren
   - Added: Neue Features
   - Changed: Aenderungen an bestehenden Features
   - Fixed: Bug Fixes
   - Removed: Entfernte Features

2. **JSDoc** — Auf ALLEN exportierten Funktionen, Komponenten und Types

   ````typescript
   /**
    * Kurzbeschreibung.
    *
    * @param name - Beschreibung des Parameters
    * @returns Beschreibung des Rueckgabewerts
    * @example
    * ```tsx
    * <MyComponent name="test" />
    * ```
    */
   ````

3. **Barrel Files** — `index.ts` in jedem Slice dokumentiert die Public API
