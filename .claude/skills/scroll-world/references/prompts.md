# Prompt templates & intake

Everything here is fill-in-the-slots. Keep the **style preamble** byte-for-byte identical
across all scene stills — that identical text is what makes the world feel like one place.

## Intake checklist (Step 1)

Collect and write down:

- `SUBJECT` — the business + one-line pitch.
- `BRAND_NAME` — display name.
- `PALETTE` — 4–6 named hexes, e.g. `taro #9B7EBD, cream #F5EDE0, caramel #C88A5A, matcha #8FB98A, plum #3A2E48`. Pick ONE as the scene **background** colour (usually the lightest) and one as the primary **accent**.
- `TONE` — a word or two (cozy/premium, playful, industrial…).
- `STYLE` — the art direction (default below).
- `SECTIONS[]` — ordered list; for each: `id`, `label`, `subject` (what's in the diorama), `eyebrow`, `title`, `body` (≤ 1 sentence), `tags[]` (0–3). Last section = hero product + CTA.
- `MOBILE` — yes/no. **Always asked** (SKILL Step 1.5), presented to the user
  with the ~2× credit cost stated.
- `VIDEO_TIER` — draft (`fal-ai/kling-video/o1/image-to-video`, flat $0.112/s, cheapest
  single-model chain) | standard (`fal-ai/kling-video/v3/pro/image-to-video`, default) |
  connector upgrade (native-FLF `fal-ai/veo3.1/*/first-last-frame-to-video`, hard seam,
  connectors only — see pipeline `CMODEL`). Chosen by cost at SKILL Step 1.6, with the
  calibrated total estimate stated before anything renders.
- `STILLS_SOURCE` — fal (`$FAL_IMAGE_MODEL` text-to-image, spends credits; pick + verify
  live — this skill pins only the FLF *video* endpoints, so the still model is your
  choice) | codex (`image_gen`, subscription-billed; only offer when the Codex CLI is present). Yes = the **native 9:16 portrait chain** (pipeline §6b):
  portrait renders of every dive/connector + `clipMobile`/`connectorsMobile`/`stillMobile`
  wiring + the full mobile QA. The §6 crop encodes are a no-credits stopgap only.

## Style preamble (default: clay diorama)

Reuse verbatim in every scene prompt. Swap the bracketed bits for the brand's palette/bg.

```
Isometric low-poly 3D diorama floating as a small rounded island on a plain solid
[BG_HEX] background with a soft contact shadow beneath it. Soft matte clay 3D render,
rounded toy-model shapes, gentle warm studio lighting, soft long shadows, tilt-shift
miniature look. Cohesive color palette of [PALETTE]. Highly detailed, centered
composition, absolutely no text, no letters, no numbers, no logos.
```

Alternate directions (swap the first two sentences, keep the palette/no-text tail):
- **Flat papercraft:** "Isometric layered paper-craft diorama, matte cardstock, clean die-cut edges, subtle drop shadows between layers."
- **Glossy toy:** "Isometric glossy vinyl-toy diorama, smooth plastic shading, soft rim light, collectible figurine look."
- **Claymation:** "Isometric stop-motion clay set, visible thumbprints, handmade plasticine texture, soft studio softbox light."
- **Neon night:** "Isometric miniature at night, warm interior glow and neon signage, moody rim light, wet reflective ground."
- **Photoreal architectural** (real estate, hospitality, premium/luxury): "Ultra-photorealistic architectural photography of a single cohesive [subject], cinematic wide-angle, warm golden-hour light, natural materials, restrained designer furnishings, a breathtaking view, editorial magazine quality (Architectural Digest), shallow depth of field, no people." For photoreal, drop the floating-island framing and the knockout (Step 3) — the scenes are **full-bleed** (a dark page background reads premium), the "dive" glides *through doorways/glass* rather than opening a roof, and cohesion comes entirely from the identical preamble (do NOT pass a style-reference image — it clones the same room). Interiors trip video-model NSFW filters often; see SKILL Gotchas.

## Scene still prompt (Step 2)

```
[STYLE PREAMBLE]
Subject: [SECTION.subject — describe the miniature scene: the building/space, a few
characters doing the work, the props that signal this stage of the business].
```

Tips:
- Name concrete props (they anchor the scene): tanks, cauldrons, conveyor, crates, awning, string lights, benches, scooters, map pins.
- For the final "hero product" section, drop the diorama-island framing and prompt a
  single oversized product centerpiece floating on the same background with a few small
  orbiting props.
- **Compose for the centre.** The page renders every clip `object-fit:cover`. Keep the
  focal subject horizontally centred with a little headroom, and don't park anything
  essential at the far left/right edges. Mobile ships its own native 9:16 chain
  (pipeline §6b), so this is not about surviving a crop — but a centred composition makes
  the portrait renders open cleanly from the same still, and it keeps the dive's focal
  point where the camera actually flies.
- Aspect `3:2`, high resolution (~2k), high quality — set these via your fal image
  model's own aspect/size/quality keys (they differ per model; verify its schema live).

## Leg prompt — architecture A, continuous forward take (Step 4)

`start_image_url = previous leg's ACTUAL last frame` (leg 0: the first scene's still).
**No end frame** — a single-start clip, so the chain model is a Kling image-to-video
endpoint and `end_image_url` is simply omitted. The bolded clauses are the motion-handoff
contract — keep them verbatim; the mid-leg move is where the expression goes.

```
Single continuous cinematic camera move, no cuts. **Continue the same slow, steady
forward glide.** [MID-LEG MOVE — optional, from the library below.] The camera moves
into [SCENE i] toward [FOCAL POINT]. **In the final second, settle back into a slow,
steady forward glide toward [the doorway / opening / direction of the next scene].**
[STYLE tail + PALETTE]. Smooth, graceful, slow motion, subtle parallax. No text, no captions.
```

### Mid-leg move library (pick by concept; omit for a plain glide)

Reversals are safe *inside* a leg (it's one continuous render) — only a seam may never
reverse. That's why "ease back out" is fine mid-leg.

- **Half-orbit** (product, luxury): "sweeping in a slow half-orbit around [the hero
  object], keeping it centered, then continuing past it"
- **Crane-up reveal** (scale, atriums, campuses): "rising smoothly as the full scale of
  [the space] reveals below"
- **Low lateral track** (production lines, counters, shelves): "tracking low and level
  alongside [the line], foreground objects sliding past in parallax"
- **Push-in + ease back** (craft, detail): "pushing in close to [the craft moment] until
  it nearly fills the frame, then easing gently back out"
- **Rise-and-swoop** (travel, outdoors): "climbing in a gentle arc over [the terrain],
  then swooping down toward [the next focal point]"

After rendering each leg, **check its last frame** before generating the next: it should
read as a frame from a calm forward glide (no motion blur sideways, no half-finished
orbit). If it doesn't, re-roll this leg — a bad handoff frame poisons every leg after it.

## Dive-in clip prompt (Step 4)

`start_image_url = the scene still` (solid-bg version).

```
Single continuous cinematic camera move, no cuts. Begin high and far, looking down at the
whole [SECTION.subject] from outside like a tiny model. The camera slowly glides forward
and descends toward it, sweeping in toward [FOCAL POINT — the counter/the cauldrons/the
people], as if flying inside. As the camera pushes in, the roof and upper structure
gently lift and open away to reveal the warm interior. [STYLE tail: soft matte clay
diorama, tilt-shift miniature, warm light, [PALETTE]]. Smooth, graceful, slow motion,
subtle parallax. No text, no captions.
```

For scenes with no building to open (a field, a plaza, a road), replace the roof clause
with "the camera flies low across [the scene] toward [focal point]."

Params by chain model (fal): the chain model is a Kling image-to-video endpoint — body
`{prompt, start_image_url, duration:"8", generate_audio:false}` (`duration` is a string
enum: v3 pro `"3"`..`"15"`, o1 `"3"`..`"10"`; `generate_audio:false` reaches v3 pro's
silent tier and is discarded at the `-an` encode anyway — o1 is flat-priced and has no
audio param, so drop the key there). Kling has no resolution/aspect param: the clip
inherits the start frame's aspect (a 3:2 still yields ~3:2 clips, which the engine covers
fine), so feed a 16:9 canvas or use a veo3.1 connector with `aspect_ratio` if you need
strict 16:9. Same body for architecture-A legs (start frame only, no end field).
(Higgsfield's DoP / camera-motion presets have **no fal equivalent** — on fal the camera
motion lives entirely in the prompt text above, so nothing is lost in the port; there is
just no preset knob to set.)

## Connector clip prompt (Step 5)

`start_image_url = dive_i LAST frame` (extracted), `end_image_url = dive_{i+1} FIRST frame`
(extracted) — on the native-FLF veo3.1 upgrade these fields are
`first_frame_url`/`last_frame_url` and **both are required**. Both from the RENDERED
videos, not the stills.

```
Single continuous cinematic camera move, no cuts. The camera smoothly pulls up and back
out of [SCENE i], rising into the sky, then glides forward across the connected miniature
world and arrives above [SCENE i+1], beginning to descend toward it. One connected
miniature clay world, seamless flowing aerial transition. [STYLE tail + PALETTE]. Smooth
graceful slow motion. No text, no captions.
```

For the last connector into a hero-product finale: "…glides forward and the world
dissolves toward a single giant [PRODUCT] floating in soft [BG] space, arriving in front
of it."

Kling chain model: `{prompt, start_image_url, end_image_url, duration:"5", generate_audio:false}`
(native res, audio stripped at encode). veo3.1 connector upgrade:
`{prompt, first_frame_url, last_frame_url, duration:"6s", resolution:"1080p", generate_audio:false}`
(the veo3.1 `duration` enum has no 5s → `"6s"` is the nearest). Connectors need an end
frame → Kling sets the optional `end_image_url`; veo3.1 and wan-flf2v require BOTH frames
natively (Step 4 / pipeline §4).

## Copy per section (for the engine config)

- `eyebrow` — 2–4 words, uppercase feel (a value-prop label).
- `title` — 3–6 words, the beat's headline. First section = the site's hero line; last =
  the payoff + it carries the CTA.
- `body` — one sentence, plain-spoken, from the visitor's side.
- `tags` — 0–3 short proof chips (e.g. "Fresh-cooked", "30-min delivery").
