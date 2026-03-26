---
name: new-feature
description: FSD-konformes Feature scaffolden mit korrekter Layer-Struktur
---

# /new-feature [name]

Erstellt ein neues FSD-konformes Feature mit korrekter Ordnerstruktur.

## Workflow

1. Feature-Name validieren (kebab-case)
2. Entscheiden welcher Layer (feature, entity, widget, page)
3. Ordnerstruktur erstellen:
   ```
   src/{layer}/{name}/
   ├── index.ts          ← Public API (Barrel File)
   ├── ui/               ← Komponenten
   │   └── {Name}.tsx
   ├── model/            ← State, Types, Hooks
   │   └── types.ts
   ├── api/              ← API-Aufrufe (nur bei entities/features)
   │   └── queries.ts
   └── lib/              ← Utilities
   ```
4. Barrel File (`index.ts`) mit initialen Exports
5. JSDoc-Kommentare auf allen Exports
6. CHANGELOG.md aktualisieren

## Regeln

- Imports nur von niedrigeren Layern
- Types aus `src/generated/api-types.ts` importieren wenn API-bezogen
- Path Aliases verwenden
