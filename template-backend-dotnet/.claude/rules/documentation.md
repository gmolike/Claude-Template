# Documentation Rules

## Pflicht-Dokumentation bei jeder Aenderung

1. **CHANGELOG.md** — `[Unreleased]` Abschnitt aktualisieren
   - Added: Neue Features
   - Changed: Aenderungen an bestehenden Features
   - Fixed: Bug Fixes
   - Removed: Entfernte Features

2. **XML-Doc** — Auf ALLEN exportierten Klassen, Methoden und Properties

   ```csharp
   /// <summary>
   /// Kurzbeschreibung.
   /// </summary>
   /// <param name="id">Beschreibung des Parameters</param>
   /// <returns>Beschreibung des Rueckgabewerts</returns>
   ```

3. **ADR** — Bei Architektur-Entscheidungen in `docs/decisions/`
   Format: `XXXX-kurzbeschreibung.md` (MADR 4.0.0)

4. **Scrum-Board** — Task-Dateien in `.scrum/` aktualisieren
   - Status aendern durch Verschieben zwischen Ordnern
   - Acceptance Criteria abhaken
