# Pitfall Checklist — Review before declaring task complete

> **Stand:** 2026-09-17 — der früher hier stehende Stempel "2026-05-13" lag zwei Monate hinter dem
> letzten Edit dieser Datei (2026-07-23). Ein Datumsvermerk, der nicht mitwandert, ist schlimmer als
> keiner: er datiert Substanz, die er nie gesehen hat.

## fal.ai

- [ ] `FAL_KEY` never in `VITE_*` ENV vars (would ship in bundle!)
- [ ] `FAL_KEY` never in any file under `src/` of the frontend
- [ ] Backend has rate-limit middleware on `/api/fal/*` (token bucket, ≤ 10 req/min/IP default)
- [ ] Cache key is `sha256(endpoint + JSON.stringify(input))`, NOT just `sha256(prompt)`
- [ ] FLUX.1 **dev** is NOT used anywhere (non-commercial license — Lizenzlage seit 2026-07-23 strittig, konservative Regel gilt bis zur Klaerung: `01-fal-models.md`)
- [ ] Jede benutzte Endpoint-ID ist einzeln gegen `https://fal.ai/models/<id>` geprueft — **nie analog abgeleitet** (fal.ai mischt Slash und Bindestrich in derselben Modellfamilie) und **nie als Wildcard** (`.../v3/pro/*`) notiert
- [ ] Der Seiteninhalt wurde gelesen, nicht nur der Statuscode — deprecated Endpoints (`fal-ai/veo3`, `fal-ai/flux-pro`) antworten mit 200. Gesucht wurde dabei der **per-Modell-Marker** ("This endpoint is deprecated" / "This model is no longer supported"), **nicht** das bloße Wort "deprecated": jede fal.ai-Modellseite trägt einen globalen ltx-2-Banner, der sonst auch die Positivkontrolle `fal-ai/flux/schnell` rot färbt (`01-fal-models.md`, Prüfmethode Schritt 4)
- [ ] GLB output from fal goes through `optimizeGLB()` before R2 upload
- [ ] Long-running 3D / video generations use `fal.subscribe` (auto-poll) or queue+webhook, NEVER blocking `fal.run`
- [ ] User prompts pass through content moderation before fal call (or are scoped to trusted users)
- [ ] CORS is origin-whitelisted, not `*`
- [ ] Spending limit set in fal dashboard (Settings → Spending Limit)
- [ ] R2 objects have `Cache-Control: public, max-age=31536000, immutable`
- [ ] Webhook signatures (`X-Fal-Webhook-Signature`) verified via JWKS
- [ ] Loop-Video: der Anker stammt aus dem **Pilot-Video**, nie aus dem Original-Still — und die Loop-Naht ist gegen die INNEREN Nähte derselben Kette gemessen, nicht gegen eine absolute Schwelle. Instrument vorher kalibrieren; nur EINE Metrik pro Kette. Rezept + Endpoint-Anforderung: `01-fal-models.md`, "Seamless Video Loops"; der laufbereite browser-freie Nahtcheck (`seam_check()`, PSNR `>~40 dB`): `skill:scroll-world`, `references/pipeline.md` Abschnitt 7
- [ ] Loop-Endpoint nimmt Start- UND Endbild **getrennt** an (`start_image_url` + `end_image_url` bei Kling und `fal-ai/wan-flf2v`, `image_url` + `end_image_url` bei `fal-ai/wan/v2.7/image-to-video`, `first_frame_url` + `last_frame_url` bei den veo3.1-FLF-Endpoints — am 2026-09-22 im Input-Schema gelesen). Ein reiner `text-to-video`-Endpoint kann `A -> A` konstruktiv nicht, egal wie günstig er ist

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

## Video-Auslieferung im Browser (gilt für jedes `<video>`, auch ohne fal-Asset)

> Gemessen 2026-09-08 in einem Konsumentenprojekt: Playwright 1.60.0, WebKit-Build 2287, Windows.
> **In agent-core selbst nicht nachstellbar** — hier gibt es keine Browser-Testfläche (`package.json`
> führt kein playwright). Datierte Fremdmessung, kein Repo-Gate. Der Mechanismus darunter — der
> Kandidaten-Algorithmus des `<video>`-Elements — ist dagegen nicht build-spezifisch.
>
> Kanonische Kurzform: `skill:verify`, Abschnitt "Gotchas" (Eintrag "Ein Automations-Browser kann ein
> gültiges Video nicht dekodieren …"). Diese Liste ist die Checklisten-Fassung mit den Belegen;
> widerspricht sie der Kurzform, wird hier nachgezogen, nicht dort.

- [ ] `<video>` mit mehreren `<source>`: **mp4 zuerst, webm danach**. Die Reihenfolge ist Kompatibilität, nicht Dateigröße — die Engine nimmt den ERSTEN Kandidaten, den sie zu können behauptet, und nimmt ihn nie zurück. Gegentest, sonst identischer Aufbau: `[webm, mp4]` -> Zeitüberschreitung in allen drei Engines; `[mp4, webm]` -> alle drei spielen
- [ ] `canPlayType` NICHT als Weichensteller im Produktionscode: derselbe Build meldet `"probably"` für den frei **erfundenen** Codec `video/webm; codecs="vp99"`. Eine Auskunft, die lügt, plus ein Fallback, der nur auf Fehler reagiert, ergibt einen stillen Totalausfall — deshalb ist die Reihenfolge oben die Absicherung und nicht die Weiche
- [ ] Ein `onError`-Fallback am `<video>` zählt NICHT als Absicherung: bei einem nicht abspielbaren Kandidaten bleiben `readyState` 0 und `networkState` 2 dauerhaft stehen, `error` feuert **nie**, `window.load` kommt nie — nur der Harness-Timeout merkt es (dort 45 s in `page.goto`). Wer absichern will, pollt `readyState` gegen eine **Frist** und schaltet selbst um
- [ ] Dieselbe Stille kennt agent-core schon von der Dekodierseite: `skill:scroll-world`, `references/pipeline.md` Abschnitt 7 — "ein valides H.264 bleibt bei `readyState 0` hängen, `loadedmetadata` feuert nie, und es wird **kein Fehler** geworfen". Bewegungs-QA gehört deshalb in ein echtes Chrome, nicht in den Automations-Browser. `31-quality-web` nennt beide Werkzeuge nebeneinander (claude-in-chrome / Playwright); für Bewegung und Video ist claude-in-chrome die Wahl, weil es das echte Chrome steuert
- [ ] Jedes `await` auf ein Video-Ereignis (`loadedmetadata`, `canplay`) trägt eine Frist UND einen `error`-Listener. Ohne beides settelt das Promise unter dem Verhalten oben nie und blockiert die ganze async-Initialisierung
