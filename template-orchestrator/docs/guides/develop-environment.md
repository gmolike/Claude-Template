# Develop-Environment Guide

## Uebersicht

Jedes Repo laeuft unabhaengig. Das Backend stellt eine Develop-Instanz bereit, gegen die das Frontend entwickelt.

## Frontend-Setup

```bash
cd {{PROJECT_NAME}}-web
cp .env.example .env
# VITE_API_URL auf Develop-Instanz setzen
pnpm install
pnpm dev
```

## Backend-Setup (.NET)

```bash
cd {{PROJECT_NAME}}-api
cp appsettings.Development.example.json appsettings.Development.json
dotnet restore
docker-compose up -d  # PostgreSQL + Redis
dotnet run --project src/{{PROJECT_NAME}}.API
```

## Backend-Setup (Hono)

```bash
cd {{PROJECT_NAME}}-api
cp .env.example .env
pnpm install
docker-compose up -d  # PostgreSQL
pnpm dev
```

## API-Types aktualisieren

```bash
cd {{PROJECT_NAME}}-web
pnpm generate:api-types  # Generiert Types aus Swagger/OpenAPI
```
