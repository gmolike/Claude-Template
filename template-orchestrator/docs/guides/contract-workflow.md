# Contract-Workflow

## Ablauf

1. API-Contract als OpenAPI Spec definieren (im Contracts-Repo oder in `docs/contracts/openapi/`)
2. Spec validieren: `pnpm validate`
3. PR erstellen und reviewen
4. Bei Merge: CI generiert TypeScript + C# Types
5. Frontend-Repo: `pnpm generate:api-types` fuer neue Types
6. Backend-Repo: NuGet-Paket aktualisieren oder Spec direkt nutzen

## OpenAPI-First Workflow

```
OpenAPI Spec (SSOT)
    ├── openapi-typescript → TypeScript Types (Frontend)
    ├── NSwag → C# Interfaces (.NET Backend)
    └── Swagger UI → API-Dokumentation (Backend)
```

## Regeln

- Contracts werden IMMER zuerst definiert
- Frontend und Backend generieren Types, schreiben sie NIE manuell
- Breaking Changes erfordern Major-Version-Bump
- Jeder Endpoint muss in der Spec dokumentiert sein
