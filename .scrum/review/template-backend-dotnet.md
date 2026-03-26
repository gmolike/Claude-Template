## Worker-Backend Output: template-backend-dotnet

### Implementierte Dateien

| Pfad                                                                   | Beschreibung                                                            |
| ---------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| `template-backend-dotnet/CLAUDE.md`                                    | Projekt-Instructions fuer Claude Code                                   |
| `template-backend-dotnet/AGENTS.md`                                    | Agent-Rollendefinitionen                                                |
| `template-backend-dotnet/CHANGELOG.md`                                 | Changelog (Unreleased initial)                                          |
| `template-backend-dotnet/README.md`                                    | Projektdokumentation                                                    |
| `template-backend-dotnet/{{PROJECT_NAME}}.sln`                         | Visual Studio Solution-Datei                                            |
| `template-backend-dotnet/Directory.Build.props`                        | Geteilte MSBuild-Properties (net9.0, Nullable, TreatWarningsAsErrors)   |
| `template-backend-dotnet/Directory.Packages.props`                     | Zentrales NuGet Package-Management                                      |
| `template-backend-dotnet/global.json`                                  | .NET SDK Version Pinning (9.0.100)                                      |
| `template-backend-dotnet/src/{{PROJECT_NAME}}.Domain/`                 | Domain-Layer: BaseEntity, User, IUserRepository                         |
| `template-backend-dotnet/src/{{PROJECT_NAME}}.Application/`            | Application-Layer: Commands, Queries, DTOs, ValidationBehavior          |
| `template-backend-dotnet/src/{{PROJECT_NAME}}.Infrastructure/`         | Infrastructure-Layer: AppDbContext, UserConfiguration, UserRepository   |
| `template-backend-dotnet/src/{{PROJECT_NAME}}.API/`                    | API-Layer: Program.cs, UsersController, appsettings                     |
| `template-backend-dotnet/tests/{{PROJECT_NAME}}.Domain.Tests/`         | Domain Unit Tests (UserTests)                                           |
| `template-backend-dotnet/tests/{{PROJECT_NAME}}.Application.Tests/`    | Application Test Stub (.csproj + .gitkeep)                              |
| `template-backend-dotnet/tests/{{PROJECT_NAME}}.Infrastructure.Tests/` | Infrastructure Test Stub (.csproj + .gitkeep)                           |
| `template-backend-dotnet/tests/{{PROJECT_NAME}}.API.Tests/`            | API Test Stub (.csproj + .gitkeep)                                      |
| `template-backend-dotnet/.claude/agents/`                              | Agent-Definitionen: senior-backend, worker-backend, worker-qs, debugger |
| `template-backend-dotnet/.claude/skills/`                              | Skills: commit, review, migration                                       |
| `template-backend-dotnet/.claude/rules/`                               | Rules: clean-architecture, token-efficiency, documentation              |
| `template-backend-dotnet/.claude/settings.json`                        | Claude Code Permissions                                                 |
| `template-backend-dotnet/.claude/.mcp.json`                            | MCP Server Konfiguration (GitHub, Context7)                             |
| `template-backend-dotnet/docker/Dockerfile`                            | Multi-Stage Docker Build                                                |
| `template-backend-dotnet/docker-compose.yml`                           | API + PostgreSQL Compose                                                |
| `template-backend-dotnet/scripts/init.sh`                              | Template-Initialisierung (Placeholder-Ersetzung)                        |
| `template-backend-dotnet/scripts/generate-openapi.sh`                  | OpenAPI Spec Export                                                     |
| `template-backend-dotnet/.github/workflows/ci.yml`                     | CI Pipeline mit PostgreSQL Service                                      |
| `template-backend-dotnet/.github/workflows/template-sync.yml`          | Woechentlicher Template-Sync                                            |
| `template-backend-dotnet/.gitignore`                                   | .NET-spezifische Ignores                                                |
| `template-backend-dotnet/.editorconfig`                                | Code-Style Einstellungen                                                |

### Tests

| Pfad                                               | Was wird getestet                                                                         |
| -------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| `tests/{{PROJECT_NAME}}.Domain.Tests/UserTests.cs` | User.Create() setzt Properties korrekt; UpdateProfile() aktualisiert Felder und UpdatedAt |

### Migrations

Nicht anwendbar — Template ohne laufende Datenbank. Migrations werden nach init.sh + dotnet ef erstellt.

### Status: Bereit fuer Review in .scrum/review/
