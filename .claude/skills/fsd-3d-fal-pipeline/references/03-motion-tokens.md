# Motion Design Token Reference

> **Stand:** 2026-05-13

All tokens live in `shared/config/motion/tokens.ts`. No magic numbers anywhere else.

## DURATION (seconds, Motion convention)

| Token | Value | Use |
|---|---|---|
| `instant` | 0.1 | Hover color, focus ring |
| `short` | 0.15 | Button state, toggle, micro-interaction |
| `medium` | 0.25 | Modal, drawer, tooltip |
| `long` | 0.4 | Page transition |
| `xlong` | 0.6 | Hero reveal, scrollytelling |

## EASING (cubic-bezier 4-tuples)

| Token | Curve | Source / Use |
|---|---|---|
| `standard` | `[0.2, 0, 0, 1]` | Material 3 default. **Safest default.** |
| `decelerate` | `[0.05, 0.7, 0.1, 1]` | Element entering viewport |
| `accelerate` | `[0.3, 0, 0.8, 0.15]` | Element leaving viewport |
| `apple` | `[0.25, 0.1, 0.25, 1]` | CSS `ease`, soft default |
| `anticipate` | `[0.68, -0.55, 0.265, 1.55]` | Micro-bounce / celebration |
| `linear` | `[0, 0, 1, 1]` | Loaders, continuous motion only |

## SPRING

| Token | Config | Character |
|---|---|---|
| `subtle` | `{ stiffness: 100, damping: 20, mass: 1 }` | Soft, mild overshoot |
| `snappy` | `{ stiffness: 400, damping: 30, mass: 0.8 }` | Fast, minimal overshoot |
| `bouncy` | `{ stiffness: 300, damping: 15, mass: 1 }` | Visible bounce — sparingly |

## Standard Variants

In `shared/lib/motion/variants.ts`:

- `fadeInUp` — paragraphs, cards, hero text
- `fade` — overlays, neutral default
- `scaleIn` — modal, popover (uses SPRING.snappy)
- `staggerContainer` — pair with child variants, 0.08 s stagger
- `pageTransition` — route changes

## Provider Setup

```tsx
// app/providers/MotionProvider.tsx
<LazyMotion features={loadFeatures} strict>
  <MotionConfig reducedMotion="user" transition={DEFAULT_TRANSITION}>
    {children}
  </MotionConfig>
</LazyMotion>
```

`strict` mode enforces `m.*` over `motion.*`. This is mandatory for bundle-splitting to work — without it, the full Motion bundle (~34 KB) lands in initial JS instead of the ~4.6 KB minimal core.

## Reduced-Motion Strategy

- Global: `MotionConfig reducedMotion="user"` handles 90 % of cases
- Per-component: `useReducedMotion()` returns `boolean | null`. Always check `=== true` for safety
- Cross-cut: CSS media query `@media (prefers-reduced-motion: reduce)` for non-Motion animations as backup
