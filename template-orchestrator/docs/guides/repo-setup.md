# Repo-Setup Guide

## Neues Projekt erstellen

### 1. Orchestrator-Repo

```bash
gh repo create {{PROJECT_NAME}}-orchestrator --template {{GITHUB_USER}}/template-orchestrator --private
cd {{PROJECT_NAME}}-orchestrator
./scripts/init-project.sh
```

### 2. Contracts-Repo

```bash
gh repo create {{PROJECT_NAME}}-contracts --template {{GITHUB_USER}}/template-shared-contracts --private
cd {{PROJECT_NAME}}-contracts
./scripts/init.sh
```

### 3. Backend-Repo (.NET oder Hono)

```bash
# Option A: .NET
gh repo create {{PROJECT_NAME}}-api --template {{GITHUB_USER}}/template-backend-dotnet --private

# Option B: Hono
gh repo create {{PROJECT_NAME}}-api --template {{GITHUB_USER}}/template-backend-hono --private

cd {{PROJECT_NAME}}-api
./scripts/init.sh
```

### 4. Frontend-Repo

```bash
gh repo create {{PROJECT_NAME}}-web --template {{GITHUB_USER}}/template-frontend-react --private
cd {{PROJECT_NAME}}-web
./scripts/init.sh
```

### 5. Mobile-Repo (optional)

```bash
gh repo create {{PROJECT_NAME}}-mobile --template {{GITHUB_USER}}/template-mobile-rn --private
cd {{PROJECT_NAME}}-mobile
./scripts/init.sh
```
