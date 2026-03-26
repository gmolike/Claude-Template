---
name: review
description: 'Code Review nach Clean Architecture Standards.'
argument-hint: '[datei-oder-ordner-pfad]'
allowed-tools: Read, Bash, Glob, Grep
disable-model-invocation: true
---

# Code Review — Clean Architecture

## Checkliste

### 1. Clean Architecture

- [ ] Dependency Rule eingehalten
- [ ] Domain hat keine externen Dependencies
- [ ] Korrekte Projekt-Referenzen

### 2. CQRS

- [ ] Commands und Queries getrennt
- [ ] Handler korrekt implementiert
- [ ] Validators vorhanden

### 3. EF Core

- [ ] Configurations explizit
- [ ] Indizes definiert
- [ ] Keine N+1 Queries

### 4. API

- [ ] Controller duenn
- [ ] Swagger-Annotationen
- [ ] Error-Handling konsistent

### 5. Tests

- [ ] Unit Tests fuer Domain + Application
- [ ] Integration Tests fuer Infrastructure
