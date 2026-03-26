# Clean Architecture Rules

## Dependency Rule (STRIKT)

Domain ← Application ← Infrastructure/API

- Domain referenziert NICHTS (nur .NET BCL)
- Application referenziert NUR Domain
- Infrastructure referenziert Application + Domain
- API referenziert Application + Infrastructure

## CQRS (MediatR)

- Commands sind SCHREIBEND (Create, Update, Delete)
- Queries sind LESEND (Get, List)
- Commands und Queries in getrennten Ordnern
- Jeder Command/Query hat einen eigenen Handler

## Repository Pattern

- Interfaces in Domain/Interfaces/
- Implementierungen in Infrastructure/Persistence/Repositories/
- Controller nutzen NIE direkt den DbContext
