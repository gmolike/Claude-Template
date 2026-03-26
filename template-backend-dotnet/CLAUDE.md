# {{PROJECT_NAME}} — Backend API

ASP.NET Core + Clean Architecture + CQRS (MediatR) + EF Core + PostgreSQL.

## HARD RULES

- Dieses Repo enthaelt NUR Backend-Code
- KEINE Frontend-Logik, KEIN React, KEIN TypeScript
- Clean Architecture Dependency Rule: Domain ← Application ← Infrastructure/API
- Domain-Layer hat KEINE externen Abhaengigkeiten (nur .NET BCL)
- CQRS via MediatR — Commands und Queries sind getrennt
- Jeder Endpoint generiert automatisch OpenAPI/Swagger Spec

## Architektur: Clean Architecture (Onion)

**Layer-Hierarchie (STRIKT — Dependency Rule):**

```
API (aeusserster Ring)
  └── referenziert: Application, Infrastructure
Infrastructure (aeusserer Ring)
  └── referenziert: Application, Domain
Application (innerer Ring)
  └── referenziert: Domain
Domain (Kern)
  └── referenziert: NICHTS (nur .NET BCL)
```

**Was wo lebt:**

| Layer          | Inhalt                                                        |
| -------------- | ------------------------------------------------------------- |
| Domain         | Entities, Value Objects, Domain Events, Repository Interfaces |
| Application    | Commands, Queries, DTOs, Validators, Pipeline Behaviors       |
| Infrastructure | DbContext, Repository Implementierungen, External Services    |
| API            | Controller, Middleware, Filter, DI-Konfiguration              |

## CQRS Pattern

**Command (schreibend):**

```csharp
public record CreateUserCommand(string Email, string Name) : IRequest<UserDto>;
public class CreateUserHandler : IRequestHandler<CreateUserCommand, UserDto> { ... }
```

**Query (lesend):**

```csharp
public record GetUserQuery(Guid Id) : IRequest<UserDto>;
public class GetUserHandler : IRequestHandler<GetUserQuery, UserDto> { ... }
```

## Agents

| Agent          | Model      | Rolle                                       |
| -------------- | ---------- | ------------------------------------------- |
| Senior Backend | sonnetplan | Plant Clean Architecture, CQRS Pattern      |
| Worker Backend | sonnet     | Implementiert Commands, Queries, Controller |
| Worker QS      | sonnet     | Schreibt Unit + Integration Tests           |
| Debugger       | sonnet     | Analysiert und fixt Bugs                    |

## Befehle

- `dotnet build` — Solution bauen
- `dotnet test` — Alle Tests ausfuehren
- `dotnet run --project src/{{PROJECT_NAME}}.API` — API starten
- `dotnet ef migrations add [Name] --project src/{{PROJECT_NAME}}.Infrastructure --startup-project src/{{PROJECT_NAME}}.API` — Migration
- `dotnet ef database update --project src/{{PROJECT_NAME}}.Infrastructure --startup-project src/{{PROJECT_NAME}}.API` — Migrationen anwenden

## OpenAPI

- Swagger UI: `https://localhost:5001/swagger`
- Swagger JSON: `https://localhost:5001/swagger/v1/swagger.json`
- Frontend generiert daraus TypeScript Types

## MCP-Server

- **GitHub** — Issues, PRs
- **Context7** — .NET, EF Core Doku

## Conventional Commits

Pflicht: `feat:`, `fix:`, `docs:`, `chore:`
