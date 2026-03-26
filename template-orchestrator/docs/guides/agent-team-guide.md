# Agent-Team Guide

## Hierarchie pro Repo

### Orchestrator-Chat

```
User
└── PO (opusplan)
    ├── Scrum Master (opusplan)
    └── Designer (sonnetplan)
```

### Frontend-Chat

```
User (oder: Issue von Orchestrator)
└── Senior Frontend (sonnetplan)
    ├── Worker Frontend (sonnet)
    └── Worker QS (sonnet)
```

### Backend-Chat

```
User (oder: Issue von Orchestrator)
└── Senior Backend (sonnetplan)
    ├── Worker Backend (sonnet)
    └── Worker QS (sonnet)
```

## Cross-Repo Workflow

1. **Orchestrator:** PO erstellt Feature-Spec
2. **Orchestrator:** SM erstellt GitHub Issues in Frontend + Backend
3. **Frontend-Chat:** Senior sieht Issue, startet Workers
4. **Backend-Chat:** Senior sieht Issue, startet Workers
5. **Orchestrator:** PO reviewed abgeschlossene Issues
