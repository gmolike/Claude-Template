# Pitfall Checklist — Review before declaring task complete

> **Stand:** 2026-05-13

## fal.ai

- [ ] `FAL_KEY` never in `VITE_*` ENV vars (would ship in bundle!)
- [ ] `FAL_KEY` never in any file under `src/` of the frontend
- [ ] Backend has rate-limit middleware on `/api/fal/*` (token bucket, ≤ 10 req/min/IP default)
- [ ] Cache key is `sha256(endpoint + JSON.stringify(input))`, NOT just `sha256(prompt)`
- [ ] FLUX.1 **dev** is NOT used anywhere (non-commercial license — Lizenzlage seit 2026-07-23 strittig, konservative Regel gilt bis zur Klaerung: `01-fal-models.md`)
- [ ] Jede benutzte Endpoint-ID ist einzeln gegen `https://fal.ai/models/<id>` geprueft — **nie analog abgeleitet** (fal.ai mischt Slash und Bindestrich in derselben Modellfamilie) und **nie als Wildcard** (`.../v3/pro/*`) notiert
- [ ] Der Seiteninhalt wurde gelesen, nicht nur der Statuscode — deprecated Endpoints (`fal-ai/veo3`, `fal-ai/flux-pro`) antworten mit 200
- [ ] GLB output from fal goes through `optimizeGLB()` before R2 upload
- [ ] Long-running 3D / video generations use `fal.subscribe` (auto-poll) or queue+webhook, NEVER blocking `fal.run`
- [ ] User prompts pass through content moderation before fal call (or are scoped to trusted users)
- [ ] CORS is origin-whitelisted, not `*`
- [ ] Spending limit set in fal dashboard (Settings → Spending Limit)
- [ ] R2 objects have `Cache-Control: public, max-age=31536000, immutable`
- [ ] Webhook signatures (`X-Fal-Webhook-Signature`) verified via JWKS

## Motion

- [ ] No `framer-motion` import anywhere — all imports from `motion/react`
- [ ] `<LazyMotion strict>` mounted in `app/providers/`
- [ ] All app-internal components use `m.*` not `motion.*`
- [ ] `useReducedMotion()` checked with `=== true` (returns `boolean | null`)
- [ ] Variants defined at module scope, not inline in JSX
- [ ] `AnimatePresence` uses `mode="wait"` for page transitions, has stable `key`s for children
- [ ] `useScroll` MotionValues consumed directly in `style={{}}`, NEVER copied to React state
- [ ] No spring animations on `width`/`height` (use `scaleX`/`scaleY` or `layout` prop)
- [ ] `whileInView` uses `viewport={{ once: true }}` unless re-trigger is intentional
- [ ] `transition.duration` not combined with `type: 'spring'` (springs are physical, ignore duration)

## R3F

- [ ] Decorative canvas: `pointerEvents: 'none'` + `events={undefined}`
- [ ] Decorative canvas: `aria-hidden="true"`
- [ ] `dpr={[1, 2]}` — never higher
- [ ] `frameloop="demand"` if scene is static or scroll-driven
- [ ] No shadows on marketing hero
- [ ] Mobile fallback via `shouldRender3D()` heuristic + AVIF image
- [ ] `useGLTF.preload()` called for primary hero asset
- [ ] Drei imports are tree-shakable (`{ ScrollControls }`, not `* as drei`)
- [ ] GLB models use Draco + KTX2/WebP via gltf-transform

## FSD

- [ ] No cross-slice imports between widgets/features on the same layer
- [ ] All slices expose a public `index.ts`
- [ ] No business logic in `shared/`
- [ ] No imports from `app/`, `pages/`, `widgets/`, `features/`, `entities/` into `shared/`
- [ ] ESLint `@feature-sliced/eslint-config` passes

## TypeScript / JSDoc

- [ ] No `any` outside of fal-adapter layer (and those are commented)
- [ ] Every exported function/hook/component has JSDoc
- [ ] Every file has `@file` header
- [ ] SemVer used for all library versions referenced
