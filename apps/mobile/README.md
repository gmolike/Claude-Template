# Mobile App (Platzhalter)

Dieses Verzeichnis ist vorbereitet für eine React Native / Expo App.

## Setup

```bash
# Expo initialisieren
npx create-expo-app@latest . --template blank-typescript

# Shared Packages sind bereits als Dependencies konfiguriert
pnpm install
```

## Shared Code

Die Mobile App nutzt dieselben Shared Packages wie die Web App:

- `@repo/shared-types` — Types und Zod Schemas
- `@repo/shared-ui` — Gemeinsame Komponenten (wo kompatibel)
- `@repo/shared-api` — API Client und Query Factories

## Architektur

Nutze die gleiche FSD-Struktur wie in `apps/web`:

```
src/
├── screens/     (≈ pages)
├── components/  (≈ widgets)
├── navigation/  (≈ routes)
└── ...
```
