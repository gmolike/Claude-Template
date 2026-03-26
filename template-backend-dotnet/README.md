# {{PROJECT_NAME}} — Backend API

> ASP.NET Core + Clean Architecture + CQRS + EF Core + PostgreSQL

## Setup

```bash
# PostgreSQL starten
docker-compose up -d

# API starten
dotnet run --project src/{{PROJECT_NAME}}.API
```

Swagger UI: https://localhost:5001/swagger

## Architektur

```
src/
├── {{PROJECT_NAME}}.Domain/           — Entities, Value Objects, Interfaces
├── {{PROJECT_NAME}}.Application/      — Commands, Queries, DTOs, Validators
├── {{PROJECT_NAME}}.Infrastructure/   — EF Core, External Services
└── {{PROJECT_NAME}}.API/              — Controllers, Middleware, DI
```

**Dependency Rule:** Domain ← Application ← Infrastructure/API

## Befehle

| Befehl                                          | Beschreibung        |
| ----------------------------------------------- | ------------------- |
| `dotnet build`                                  | Solution bauen      |
| `dotnet test`                                   | Tests ausfuehren    |
| `dotnet run --project src/{{PROJECT_NAME}}.API` | API starten         |
| `dotnet ef migrations add [Name]`               | Migration erstellen |
