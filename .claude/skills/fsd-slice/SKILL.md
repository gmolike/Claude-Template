---
name: fsd-slice
description: "Use when creating a new Feature-Sliced Design slice (feature, entity, or widget) in a React/TypeScript project. Scaffolds the slice folder with a public API index.ts and the model/ui/api/lib segments, respecting FSD layer boundaries. Trigger on requests like 'add a feature for X', 'create an entity', 'new FSD slice'."
---

# Scaffolding an FSD slice

Use this when adding a new slice. Pick the correct layer first, then create the
folder with a public API.

## 1. Choose the layer

- `entities/` — a business noun with its own data/model (user, order, product).
- `features/` — a user-facing capability/verb (login, add-to-cart, edit-profile).
- `widgets/` — composition of features/entities for a layout region (header, sidebar).

If unsure between feature and widget, start with `feature`.

## 2. Create the structure

```
<layer>/<slice-name>/
  index.ts        # public API — re-export ONLY what other slices may use
  model/          # stores, business logic, types
  ui/             # components (presentational + container)
  api/            # request fns + TanStack Query options
  lib/            # slice-local helpers (not exported)
```

## 3. Public API rules

- `index.ts` re-exports the slice's intended surface and nothing else.
- Other slices import from `@/<layer>/<slice-name>`, never from internal paths.
- Keep business logic in `model/`; keep `ui/` thin.

## 4. Checklist before done

- `index.ts` exists and exposes a minimal surface.
- No imports from layers above this one.
- No cross-slice deep imports.
- Types live in `model/`, colocated test added.
