# {{PROJECT_NAME}} — Mobile App

> React Native + Expo + TanStack Query

## Setup

```bash
cp .env.example .env
pnpm install
pnpm start
```

## Architektur

```
src/
├── app/         — Entry, Providers, Navigation
├── screens/     — Screen Components
├── features/    — Business Logic
├── entities/    — Domain Models, Queries
└── shared/      — Utils, Config, UI, API Client
```
