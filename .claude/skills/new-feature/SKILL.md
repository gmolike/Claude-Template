---
name: new-feature
description: 'Neues Feature FSD-konform anlegen mit Scrum-Task, Workflow-Stufe und Dateistruktur. Nutze wenn der User ein Feature, eine Page, ein Widget oder einen neuen Slice erstellen will.'
argument-hint: '[feature-beschreibung]'
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Task
disable-model-invocation: true
---

# Neues Feature anlegen

Du erstellst ein neues Feature vollständig FSD-konform mit Scrum-Integration.

## Prozess

### Schritt 1: Anforderung analysieren

Analysiere `$ARGUMENTS` und bestimme:

1. **Betroffene Apps**: web, api, mobile, shared-packages?
2. **FSD-Layer** (für Web):
   - Neue Page? → `src/pages/[name]/`
   - Neues Widget? → `src/widgets/[name]/`
   - Neues Feature? → `src/features/[name]/`
   - Neue Entity? → `src/entities/[name]/`
   - Shared Erweiterung? → `src/shared/[segment]/`
3. **Shared Types nötig?** → `packages/shared-types/src/`
4. **API-Endpunkte nötig?** → `apps/api/src/routes/`

### Schritt 2: Workflow-Stufe bestimmen

Basierend auf Komplexität:

| Kriterium                      | Stufe                                  |
| ------------------------------ | -------------------------------------- |
| 1-2 Dateien, klar lokalisiert  | **Stufe 1 — Bugfix** (1 Agent)         |
| 2-5 Dateien, klares Scope      | **Stufe 2 — Lite** (Senior + QS)       |
| 5+ Dateien, mehrere Layer/Apps | **Stufe 3 — Full Scrum** (volles Team) |

Teile dem User die gewählte Stufe mit und begründe warum.

### Schritt 3: Scrum-Task erstellen

Erstelle Task-Datei in `.scrum/backlog/FEAT-XXX-[kurzname].md`:

```markdown
---
id: FEAT-XXX
title: [Feature-Name]
status: backlog
priority: [basierend auf Analyse]
assignee: [basierend auf Stufe]
tags: [betroffene Apps/Layer]
created: [ISO-Datum]
workflow: [stufe-1|stufe-2|stufe-3]
blocked_by: []
---

# FEAT-XXX: [Feature-Name]

## User Story

Als [Rolle] möchte ich [Funktion], damit [Nutzen].

## Acceptance Criteria

- [ ] [Messbar und testbar]

## Technische Planung

### Betroffene Apps/Packages

- [ ] apps/web — [was]
- [ ] apps/api — [was]
- [ ] packages/shared-types — [was]

### FSD-Einordnung (Web)

- Layer: [pages|widgets|features|entities|shared]
- Neue Slices: [welche]

### Shared Types

- Neue Schemas: [welche Zod Schemas in shared-types]

### API-Endpunkte

- [METHOD] /api/[path] — [Beschreibung]

## Workflow: Stufe [1|2|3]

[Erklärung welche Agents beteiligt sind]
```

### Schritt 4: Dateistruktur scaffolden

Erstelle die leeren FSD-konformen Dateien. Beispiel für ein neues Feature `posts`:

**Shared Types** (immer ZUERST wenn neue Types nötig):

```
packages/shared-types/src/post.ts         ← Zod Schema + Types
packages/shared-types/src/index.ts        ← Re-Export ergänzen
```

**Entity** (wenn neuer Datentyp):

```
apps/web/src/entities/post/
├── api/
│   └── post.queries.ts                   ← Query Factory (queryOptions)
├── model/
│   └── types.ts                          ← Re-Export aus @repo/shared-types
├── ui/
│   └── post-card.tsx                     ← Entity UI-Komponente
└── index.ts                              ← Public API
```

**Feature** (wenn User-Interaktion):

```
apps/web/src/features/create-post/
├── api/
│   └── create-post.mutation.ts           ← useMutation Hook
├── ui/
│   └── create-post-form.tsx              ← Feature UI
└── index.ts                              ← Public API
```

**Page** (wenn neue Route):

```
apps/web/src/pages/posts/
├── ui/
│   └── posts-page.tsx                    ← Page-Komponente
└── index.ts                              ← Public API

apps/web/src/routes/posts/
└── index.tsx                             ← Dünner Route-Wrapper
```

**API** (wenn Backend nötig):

```
apps/api/src/routes/posts.ts              ← Hono Route
apps/api/src/services/post.service.ts     ← Business Logic
```

### Schritt 5: Boilerplate generieren

Jede generierte Datei enthält:

- JSDoc auf allen Exports
- TypeScript strict-konform
- Types aus `@repo/shared-types` importiert
- `index.ts` Public API

## Regeln

- Types IMMER zuerst in `packages/shared-types` definieren
- Entity-Queries nutzen `queryOptions()` Factory Pattern
- Mutations gehören in `features/`, NICHT in `entities/`
- Routes sind DÜNNE Wrapper — Logik in Pages
- Jeder Slice hat `index.ts` als einzigen Export-Punkt
- Kein Cross-Import zwischen Slices auf gleichem Layer
