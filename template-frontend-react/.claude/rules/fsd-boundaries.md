# FSD Boundary Rules

## Layer-Hierarchie (STRIKT)

Imports sind NUR von niedrigeren zu hoeheren Layern erlaubt:

- app → alles
- routes → pages, widgets, features, entities, shared
- pages → widgets, features, entities, shared
- widgets → features, entities, shared
- features → entities, shared
- entities → shared
- shared → nur shared

## Slice-Isolation

Slices auf dem GLEICHEN Layer duerfen sich NICHT gegenseitig importieren.
Beispiel: `features/auth` darf NICHT `features/posts` importieren.
Gemeinsame Logik → nach `entities/` oder `shared/` extrahieren.

## Public API

Jeder Slice MUSS eine `index.ts` haben die als einziger Export-Punkt dient.
Externe Imports MUESSEN ueber diese Barrel-Datei gehen.

## Path Aliases

IMMER Path Aliases verwenden:

- `@app/` → `src/app/`
- `@pages/` → `src/pages/`
- `@widgets/` → `src/widgets/`
- `@features/` → `src/features/`
- `@entities/` → `src/entities/`
- `@shared/` → `src/shared/`

## API Types

- Types aus `src/generated/api-types.ts` importieren (OpenAPI Codegen)
- NIEMALS API-Types manuell definieren
- Bei Aenderung: `pnpm generate:api-types` ausfuehren
