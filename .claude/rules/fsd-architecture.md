# FSD Architecture Rules

## Layer-Hierarchie (STRIKT)

Imports sind NUR von niedrigeren zu höheren Layern erlaubt:

- app → alles
- routes → pages, widgets, features, entities, shared
- pages → widgets, features, entities, shared
- widgets → features, entities, shared
- features → entities, shared
- entities → shared
- shared → nur shared

## Slice-Isolation

Slices auf dem GLEICHEN Layer dürfen sich NICHT gegenseitig importieren.
Beispiel: `features/auth` darf NICHT `features/posts` importieren.
Wenn zwei Features gemeinsame Logik brauchen → nach `entities/` oder `shared/` extrahieren.

## Public API

Jeder Slice MUSS eine `index.ts` haben die als einziger Export-Punkt dient.
Externe Imports MÜSSEN über diese Barrel-Datei gehen.

## Shared Packages

Types und Schemas IMMER in `packages/shared-types` definieren.
UI-Komponenten die von mehreren Apps genutzt werden → `packages/shared-ui`.
API-Client und Query Factories → `packages/shared-api`.
