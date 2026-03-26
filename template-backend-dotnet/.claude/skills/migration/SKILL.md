---
name: migration
description: 'EF Core Migration erstellen und anwenden.'
argument-hint: '[migration-name]'
allowed-tools: Read, Write, Bash(dotnet:*)
---

# EF Core Migration

## `/migration [name]`

1. Erstelle Migration:

```bash
dotnet ef migrations add [name] \
  --project src/{{PROJECT_NAME}}.Infrastructure \
  --startup-project src/{{PROJECT_NAME}}.API
```

2. Pruefe generierte Migration in `Persistence/Migrations/`
3. Wende an:

```bash
dotnet ef database update \
  --project src/{{PROJECT_NAME}}.Infrastructure \
  --startup-project src/{{PROJECT_NAME}}.API
```
