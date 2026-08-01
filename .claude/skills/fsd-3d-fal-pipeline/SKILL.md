---
name: fsd-3d-fal-pipeline
description: Use this skill when working on React/TypeScript Feature-Sliced Design projects that involve React Three Fiber (R3F) 3D scenes, Motion (formerly Framer Motion) animation systems, fal.ai asset generation pipelines, or any combination of these. Triggers include requests to build hero scenes, scroll-triggered 3D, AI-generated assets (3D models, textures, HDRIs, images, videos), animation token systems, page transitions, motion design systems, or asset optimization pipelines (Draco, KTX2, AVIF, AV1). Also use when the user mentions FSD layer placement for 3D widgets, fal.ai backend proxies, or Cloudflare R2 asset storage.
---

# FSD + R3F + Motion + fal.ai Pipeline

This skill encodes a proven production stack for AI-asset-driven React applications using Feature-Sliced Design. Read references before writing code — they encode hard-won decisions.

## Plugin-Routing (seit 2026-05-23)

- **Generic React-Patterns / Hooks / Component-Structure:** `react-dev` Plugin-Skill (agent-toolkit) — Standard-React-Mechanik, Test-Heuristik.
- **Dieser Skill:** wenn FSD-Layer-Mapping, R3F-Patterns, Motion-Token-System oder fal.ai-Pipeline gefragt sind — `react-dev` kennt die Flammenreiter-Pipeline und die fal.ai-Modelle nicht.
- **Hybrid:** Plugin für Hook-Refactors, dieser Skill für FSD-Placement + 3D-Asset-Sourcing.

Memory: `project_plugins_installed.md` + `project_redesign_prompt_style.md`.

## Workflow Decision Tree

**Step 1: Identify the request type.**

- "Build a hero scene / Add 3D to my landing page" → Hero workflow (build-time generation)
- "Generate dynamic 3D / textures / images at runtime" → Runtime workflow
- "Set up animations / page transitions / motion system" → Motion workflow
- "Optimize / fix performance / mobile fallback" → Optimization workflow

**Step 2: Always read the relevant references.** They override training-data assumptions, which are stale for fal.ai (rapidly changing) and Motion (rebranded mid-2025).

| Task | Read first |
|---|---|
| Any fal.ai integration | `references/01-fal-models.md`, `references/04-pitfalls.md` |
| Component placement | `references/02-fsd-placement.md` |
| Motion / animation work | `references/03-motion-tokens.md`, `references/04-pitfalls.md` |
| Cost estimate / SLA discussion | `references/05-cost-model.md` |

**Step 3: Copy from `templates/` rather than re-creating from scratch.** The templates are battle-tested. Adapt placeholders (prompts, endpoint IDs, environment names) but do not change the structure unless the user explicitly requests it.

## Hard Rules (NEVER violate without explicit user override)

1. `FAL_KEY` belongs only on the server. Frontend uses `fetch('/api/fal/*')` against our own backend.
2. Every fal.ai endpoint route MUST have: Zod validation → cache lookup → fal call → optimization → R2 upload → cache write. Skipping any step is a bug.
3. Cache key is `sha256(endpoint + JSON.stringify(input))`. Never just the prompt.
4. GLB output from fal goes through `optimizeGLB()` (Draco + textureCompress) before R2 upload. Unoptimized 5–20 MB GLBs in production are not acceptable.
5. FLUX.1 dev gilt hier weiter als non-commercial. Use FLUX schnell (Apache 2.0) or FLUX Pro / FLUX.2 Pro (commercial via fal) instead. **Offener Punkt (2026-07-23):** die fal-Modellseite widerspricht dieser Einordnung ("suitable for both personal and commercial use" über die fal-Plattformlizenz). Geprüft wurde nur die Modellseite, nicht die Lizenz-AGB — bis zur rechtlichen Klärung bleibt die konservative Regel. Details: `references/01-fal-models.md`.
6. R3F decorative canvases get `pointerEvents: 'none'` + `events={undefined}` + `aria-hidden="true"`.
7. Motion: `m.*` (not `motion.*`) under `<LazyMotion strict>`. `import from 'motion/react'`, never `framer-motion`.
8. Rate-limit middleware on every `/api/fal/*` route. Without it, a single bot can drain $1000+/hour.
9. **Endpoint-IDs nie analog ableiten.** fal.ai mischt Slash und Bindestrich innerhalb derselben Modellfamilie (`fal-ai/flux/schnell` vs. `fal-ai/flux-2-pro`, `fal-ai/hunyuan3d/v2` vs. `fal-ai/hunyuan-3d/v3.1/rapid/text-to-3d`), und mal fehlt das `fal-ai/`-Präfix, mal ist es Pflicht. Jede ID einzeln gegen `https://fal.ai/models/<id>` prüfen — mit Negativkontrolle (erfundene ID muss 404 liefern) und Seiteninhalt lesen (deprecated Endpoints antworten trotzdem mit 200). Nie eine Wildcard-ID (`.../v3/pro/*`) in Code oder Referenz schreiben: sie ist per Konstruktion nicht prüfbar. Methode: `references/01-fal-models.md`.

## FSD Placement Quick Reference

- Hero-3D scene → `widgets/hero-scene/` (UI block, no user action)
- Runtime 3D viewer → `widgets/dynamic-3d-showcase/`
- "User generates a model" form → `features/ai-asset-generation/`
- fal API client → `shared/api/fal/`
- TanStack Query hooks for fal → `shared/lib/react-query/fal-queries.ts`
- Motion tokens / variants → `shared/config/motion/`, `shared/lib/motion/`
- Endpoint constants → `shared/config/fal/endpoints.ts`
- 3D Canvas wrapper (generic) → `shared/ui/canvas/`
- Backend (Hono) lives outside `src/` in `backend/`, mirrors route names

## Model Selection Heuristic

> Alle IDs und Preise hier sind der Kurzauszug aus `references/01-fal-models.md` (Stand 2026-07-23).
> Bei Abweichung gilt die Referenz — und vor Nutzung immer die dort beschriebene Pruefmethode.

When the user asks for a 3D model:
- Brand-critical, one-shot, build-time → Hyper3D Rodin (`fal-ai/hyper3d/rodin`, $0.40 pro Generation)
- Runtime, user-facing, cached → Hunyuan3D v3.1 Rapid (`fal-ai/hunyuan-3d/v3.1/rapid/text-to-3d`, $0.225 pro Generation)
- Preview / thumbnail → TRELLIS (`fal-ai/trellis`, $0.02 pro Generation). **Achtung:** der frühere
  Preview-Default SF3D (`fal-ai/stable-point-aware-3d`) ist nicht mehr verfügbar (geprüft
  2026-07-23), und TRELLIS ist **kein Drop-in-Ersatz** — anderes Modell, anderes Output-Profil.
  Wer SF3D-Eigenschaften (sub-second, albedo-only) fachlich braucht, bewertet die Preview-Stufe neu.

When the user asks for an image:
- Brand-critical fallback / hero → FLUX.2 Pro (`fal-ai/flux-2-pro`, $0.03 für das erste Output-MP,
  danach +$0.015 je weiterem MP Input und Output, aufgerundet auf volle MP)
- Iteration, textures, low-stakes → FLUX schnell (`fal-ai/flux/schnell`, $0.003 pro MP, aufgerundet)
- Multi-image consistency needed → Nano Banana Pro (`fal-ai/nano-banana-pro`, $0.15 pro Bild bei
  1K/2K, $0.30 bei 4K, +$0.015 mit Web-Search)

When the user asks for video:
- Cheapest viable loop → Wan 2.7 (`fal-ai/wan/v2.7/text-to-video`, $0.10/s @720p, $0.15/s @1080p)
- Cinematic quality → Kling 3.0 Pro (`fal-ai/kling-video/v3/pro/text-to-video`, $0.112/s ohne Audio,
  $0.168/s mit Audio, $0.196/s mit Audio + Voice-Control)
- Audio required → Veo 3.1 (`fal-ai/veo3.1`, $0.20/s @720p/1080p ohne Audio, $0.40/s mit Audio;
  @4K $0.40/s bzw. $0.60/s — günstigere Tiers: `/fast` und `/lite`)

When the user asks for HDRI:
- Stop. Explain: fal.ai has no true HDR generation. Generate LDR panorama via FLUX.2 Pro
  (`fal-ai/flux-2-pro`) with equirectangular prompt. Use as R3F `<Environment files=…>`. This is sufficient for web hero scenes but not physically correct HDR.

## Generation Triggers (when to start a new fal-call vs. reuse)

- New: prompt has changed, quality tier has changed, image references have changed
- Reuse from cache: same prompt + same endpoint + same parameters → identical hash
- Force regeneration: append a `seed` parameter, never randomize the prompt

## Output Format

- Always TypeScript with JSDoc.
- Complete files, never partial excerpts. If a change is small, output the full file with the change.
- SemVer for library versions (`hono@^4.6.0`, not `latest`).
- Use Bash blocks for shell commands, ts/tsx blocks for code.

## Setup Commands (when scaffolding from scratch)

```bash
# Frontend dependencies (assuming Vite-React-TS template exists)
pnpm add three @react-three/fiber@^9.0.0 @react-three/drei@^9.115.0 \
  motion@^12.37.0 @tanstack/react-query@^5 @tanstack/react-router@^1

# Backend dependencies
cd backend
pnpm add @fal-ai/client@^1.6.0 hono@^4.6.0 @hono/node-server@^1.13.0 \
  @hono/zod-validator@^0.4.0 zod@^3.23.0 \
  @aws-sdk/client-s3@^3.700.0 @upstash/redis@^1.34.0 \
  @gltf-transform/core@^4.2.0 @gltf-transform/functions @gltf-transform/extensions \
  draco3dgltf@^1.5.7 sharp@^0.34.0 lru-cache@^11.0.0

pnpm add -D tsx@^4.19.0 typescript@^5.6.0 @types/node@^22.7.0
```

Apt/system: `ffmpeg` with `libsvtav1` codec (Dockerfile: `apt-get install -y ffmpeg`).

## Self-Check Before Done

Before declaring a task complete, verify:
- [ ] No `FAL_KEY` in any client-bundled code (grep `VITE_FAL_KEY`, `process.env.FAL_KEY` in `src/`)
- [ ] Every new fal route has Zod schema + rate-limit + cache-key-from-hash
- [ ] GLB outputs go through `optimizeGLB()` before R2 upload
- [ ] New 3D widgets follow `widgets/<name>/{ui,model,lib,assets,index.ts}` layout
- [ ] Motion code uses `m.*` not `motion.*`
- [ ] All exports have JSDoc, all files have `@file` header
- [ ] No `framer-motion` import survives anywhere
