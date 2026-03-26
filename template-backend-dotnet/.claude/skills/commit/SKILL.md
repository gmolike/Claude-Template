---
name: commit
description: 'Smart Commit: Status pruefen, Conventional Commit generieren, CHANGELOG aktualisieren.'
argument-hint: '[optionale nachricht]'
allowed-tools: Read, Write, Edit, Bash(git:*), Bash(dotnet:*), Bash(cat:*), Bash(grep:*)
disable-model-invocation: true
---

# Smart Commit — .NET

## Prozess

### 1. Status pruefen

```bash
git status --short
git diff --staged --stat
```

### 2. Pre-Commit Checks

```bash
dotnet build --no-restore 2>&1 | tail -20
dotnet test --no-build 2>&1 | tail -20
```

### 3. Conventional Commit Message

Format: `<type>(<scope>): <beschreibung>`
Scopes: `domain`, `application`, `infrastructure`, `api`, `tests`, `ci`

### 4. CHANGELOG.md aktualisieren

### 5. Commit ausfuehren (nach User-Bestaetigung)
