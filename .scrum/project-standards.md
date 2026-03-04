# Projektweite Standards

## Version 1.0.0

## Tech-Stack

| Bereich      | Technologie              | Version        |
| ------------ | ------------------------ | -------------- |
| Frontend     | React + TypeScript       | ^19.0.0 / ~5.7 |
| Routing      | TanStack Router          | ^1.95.0        |
| Server-State | TanStack Query           | ^5.62.0        |
| Architektur  | Feature-Sliced Design    | v2.1           |
| Build        | Vite                     | ^6.0           |
| Backend      | Hono                     | ^4.6.0         |
| ORM          | Prisma                   | ^6.1.0         |
| Datenbank    | PostgreSQL               | 16+            |
| Monorepo     | Turborepo + pnpm         | ^2.3.0 / 9.x   |
| Tests        | Vitest + Testing Library | ^2.1.8         |
| Linting      | ESLint (Flat Config)     | ^9.17.0        |
| Formatting   | Prettier                 | ^3.4.2         |

## Coding-Konventionen

### TypeScript

- `strict: true` — keine Kompromisse
- Kein `any` — nutze `unknown` + Type Guards
- Kein `@ts-ignore` oder `@ts-expect-error`
- Explizite Return-Types auf allen exportierten Funktionen
- Interfaces für Objekte, Type für Unions/Intersections

### Komponenten

- Arrow Functions: `const MyComponent = ({ ... }: Props) => { ... }`
- Props Interface: `interface MyComponentProps { ... }`
- Kein `React.FC` ohne Props Type
- JSDoc auf jeder exportierten Komponente

### TanStack Query

- Query Factory Pattern mit `queryOptions()` in entities
- Mutations in features
- Query Keys als Teil der Factory
- Error-Handling in jedem Hook

### FSD

- Layer-Reihenfolge: shared → entities → features → widgets → pages → app
- Imports NUR von niedrigeren Layern
- Kein Cross-Import zwischen Slices
- Jeder Slice: Public API (index.ts)
- Routes sind DÜNNE Wrapper

### Git

- Conventional Commits (feat, fix, docs, chore, ci, test, refactor, perf, build, revert)
- Ein PR pro Feature/Fix
- Branch-Format: `feat/kurz-beschreibung`, `fix/kurz-beschreibung`
- Squash Merge bevorzugt

## Test-Standards

- Jeder Export hat mindestens einen Test
- Komponenten: Alle States testen (Loading, Error, Empty, Success)
- Hooks: Alle Pfade testen
- API: Request/Response Validierung
- Mindestabdeckung: 80%
- Test-Datei neben Source: `*.test.ts(x)`
