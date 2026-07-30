# FSD Placement Rules

> **Stand:** 2026-05-13

Layer hierarchy (FSD 2.0 "pages-first"): `app → pages → widgets → features → entities → shared`. Higher layers can import from lower; never the reverse, never same-layer cross-imports between slices.

## Decision Matrix

| If the thing is… | Place in |
|---|---|
| Generic 3D Canvas wrapper (no business meaning) | `shared/ui/canvas/` |
| Three.js utility (disposal, easings) | `shared/lib/three/` |
| fal-API client (calling own backend) | `shared/api/fal/` |
| TanStack Query hooks wrapping the client | `shared/lib/react-query/` |
| Motion design tokens, variants | `shared/config/motion/`, `shared/lib/motion/` |
| fal endpoint constants | `shared/config/fal/` |
| .glb / .avif / .webm assets, multi-widget reuse | `shared/assets/` |
| .glb / .avif / .webm assets, exclusive to one widget | `widgets/<widget>/assets/` |
| Generic Provider (Motion, Query) | `app/providers/` |
| Self-contained UI block, no user action | `widgets/<name>/` |
| User-triggered action ("generate", "submit", "login") | `features/<name>/` |
| Page composition (router target) | `pages/<name>/` |
| Backend route, service, middleware | `backend/src/{routes,services,middleware}/` (NOT in FSD) |

## Widget vs Feature — the test

Ask: "Does the user click something with intent to cause a side effect / API call / state change?"
- Yes → Feature
- No → Widget

Hero with 3D scrolling is a Widget. "Generate my own crystal" form is a Feature. "Click cube to rotate it" alone could be either — if it stores progress, it's a Feature; if it's pure UI delight, Widget.

## Standard Slice Layout

```
widgets/<name>/
├── ui/
│   └── <Component>.tsx
├── model/           # state, hooks
│   └── use-*.ts
├── lib/             # local helpers (not for re-export)
├── api/             # local API calls (rare, usually shared)
├── assets/          # widget-scoped binaries
└── index.ts         # public API (named re-exports)
```

The `index.ts` is the ONLY entry point other slices may import from. Internal restructuring stays invisible.

## Cross-Slice Import Rules

✗ `widgets/hero-scene/ui/...` importing from `widgets/dynamic-3d-showcase/`
✗ `features/ai-asset-generation/` importing from `features/login/`
✓ Both importing from `shared/api/fal/` or `entities/<x>/`

## Tooling

Add `@feature-sliced/eslint-config` to enforce the hierarchy. It catches the cross-import violations automatically.
