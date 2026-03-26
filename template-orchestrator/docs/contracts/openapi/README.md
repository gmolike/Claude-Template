# OpenAPI Contracts

API-Contracts als Single Source of Truth. Diese Specs definieren die Schnittstelle zwischen Frontend und Backend.

## Dateien

- `auth.yaml` — Authentifizierung (Login, Register, Token Refresh)
- `users.yaml` — Benutzerverwaltung (CRUD, Profile)
- `common.yaml` — Gemeinsame Schemas (Pagination, Error Response)

## Regeln

- Jeder Endpoint MUSS hier definiert sein bevor er implementiert wird
- Breaking Changes erfordern Abstimmung mit Frontend UND Backend
- Spec wird bei jedem PR automatisch validiert
