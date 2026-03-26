# {{PROJECT_NAME}} — Shared Contracts

> OpenAPI Specifications als Single Source of Truth fuer API-Contracts.

## Was ist dieses Repo?

Dieses Repo definiert die API-Schnittstelle zwischen Frontend und Backend als OpenAPI Specs. Types werden **generiert**, nie manuell geschrieben.

## Struktur

```
openapi/
├── common.yaml    — Gemeinsame Schemas (Pagination, Error)
├── auth.yaml      — Auth Endpoints (Login, Register)
├── users.yaml     — User Endpoints (CRUD, Profile)
└── bundled.yaml   — Auto-generiertes Bundle aller Specs
```

## Setup

```bash
pnpm install
pnpm validate      # Specs validieren
pnpm generate      # TypeScript + C# Types generieren
```

## Workflow

1. OpenAPI Spec aendern
2. `pnpm validate` — Validation
3. `pnpm generate` — Codegen pruefen
4. PR erstellen
5. Bei Merge: CI published npm + NuGet Packages

## Generierte Packages

| Package                         | Registry | Consumer         |
| ------------------------------- | -------- | ---------------- |
| `@{{PROJECT_NAME}}/api-types`   | npm      | Frontend (React) |
| `{{PROJECT_NAME}}.ApiContracts` | NuGet    | Backend (.NET)   |
