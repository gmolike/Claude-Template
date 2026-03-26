---
name: contract
description: 'Neuen API-Contract definieren. Erstellt OpenAPI Spec mit Endpoints und Schemas.'
argument-hint: '[name]'
allowed-tools: Read, Write, Edit, Glob, Grep
---

# Neuen Contract erstellen

## `/contract [name]`

Erstelle eine neue OpenAPI Spec:

1. Frage nach: Endpoints, Request/Response Schemas, Auth-Anforderungen
2. Erstelle `openapi/[name].yaml` mit:
   - OpenAPI 3.1.0 Header
   - Paths mit operationId
   - Components/Schemas
   - Security Schemes (falls noetig)
   - $ref zu common.yaml fuer ErrorResponse, Pagination
3. Validiere: `pnpm validate`
4. Generiere Types: `pnpm generate`
5. Aktualisiere CHANGELOG.md

## Regeln

- Jeder Endpoint braucht `operationId`
- Request Bodies als benannte Schemas
- Gemeinsame Schemas in `common.yaml`
- Error Responses referenzieren `common.yaml#/components/schemas/ErrorResponse`
