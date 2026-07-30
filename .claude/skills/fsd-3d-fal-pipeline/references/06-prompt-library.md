# Hyperrealistic Tabletop Prompt Library (Redesign 2026-05)

> **Stand:** 2026-05-13 · **Endpoint-IDs und Preise korrigiert 2026-07-23**
> **Style-Direction:** Tabletop-Pergament + 3D-Akzente (ADR-019, pending)
> **Master-Anker:** `hyperrealistic, photoreal, museum-quality, no stylization`
>
> Die Prompts sind unveraendert; korrigiert wurden nur die Endpoint-IDs (`flux-2/pro` war tot →
> `fal-ai/flux-2-pro`, Veo-Wildcard → konkrete ID) und die Kostenzeilen. Preisquelle und
> Pruefmethode: `references/01-fal-models.md`.

This library is the **single source** for fal.ai prompts in the Flammenreiter Redesign initiative. When generating new assets, copy a template and only vary the asset-specific bracketed slot. **Do not drop the style-anchor or cinematography tags** — they are what keeps the output hyperrealistic instead of stylized.

---

## Style Anchors (always include)

| Slot | Tags |
|---|---|
| **Realism Lock** | `hyperrealistic, photoreal, museum-quality, sharp focus, 8K, no stylization, no illustration, no painting, no cartoon, no anime` |
| **Cinematography** | `ARRI Alexa cinematography, raking light, shallow depth of field` |
| **Material Detail (per asset)** | `patina, vellum fiber, hand-forged bronze, wax pour marks, brass tarnish, weathered stone, soot residue, oxidation` |
| **Negative (where supported)** | `flat colors, anime, painted, stylized, low-poly, illustration, watermark, text, logo, signature` |

---

## 4 House-Sigils — `fal-ai/hyper3d/rodin` (build-time)

Per Sigil ~30 Iterations à $0.40 pro Generation = ~$48 total (4 × 30 Generationen). Guenstigere
Variante derselben Familie: `fal-ai/hyper3d/rodin/v2.5/fast` zu $0.10 pro Generation. Output: GLB +
PBR + albedo/normal/roughness textures separat.

### Drachenfeste (Warrior / Fire — `#8B1A1A` + Gold `#D4A843`)

```
hyperrealistic medieval heraldic sigil, hand-forged wrought iron dragon coiled around
a broken longsword, hyperdetailed metal texture with battle patina, scorch marks and
soot residue, deep crimson #8B1A1A vitreous enamel inlay, polished gold #D4A843 leaf
highlights, mounted on dark oak shield base, museum artifact lighting, ARRI Alexa
studio cinematography, sharp focus, photoreal, no stylization, no painting, no cartoon
```

### Turm der Ketten (Strategy / Order — `#1A3A5C` + Silver `#A8B8C8`)

```
hyperrealistic medieval heraldic sigil, polished silver tower wrapped in tarnished iron
chains, geometric precision, riveted plates with cold patina, deep navy #1A3A5C
cloisonne enamel panels, brushed silver #A8B8C8 highlights, mounted on slate base,
cold museum lighting from above, ARRI Alexa cinematography, sharp focus, photoreal,
no stylization, no painting, no cartoon
```

### Tiefe Esse (Craft / Earth — `#6B4226` + Amber `#C8842A`)

```
hyperrealistic medieval blacksmith guild sigil, anvil and crossed hammers cast in
hand-hewn bronze, deep umber #6B4226 oxidation, amber #C8842A glass cabochon center
glowing like banked coals, soot-darkened texture, mounted on smoke-stained oak, forge
firelight from below, ARRI Alexa cinematography, sharp focus, photoreal, no stylization,
no painting, no cartoon
```

### Liebe & Leben (Healing / Nature — `#2A5C3A` + Jade `#7AB88A`)

```
hyperrealistic medieval healer-order sigil, intertwined ivy and oak leaves around a
chalice, hand-cast verdigris bronze, deep forest #2A5C3A enamel veining, polished jade
#7AB88A cabochon at center, organic asymmetry, mounted on living moss-covered stone,
dappled forest sunlight, ARRI Alexa cinematography, sharp focus, photoreal, no
stylization, no painting, no cartoon
```

---

## Pergament-Texturen — `fal-ai/flux-2-pro` (build-time)

30 Varianten × $0.03 fuer das erste Output-Megapixel ≈ $0.90 bei 1 MP. Output: 2K seamless texture
maps — 2K liegt ueber 1 MP, jedes weitere angefangene Megapixel kostet +$0.015, der reale Betrag
liegt also hoeher. Vor der Bestellung mit der Zielaufloesung nachrechnen.

```
hyperrealistic aged vellum parchment texture, naturally weathered animal skin with
visible fiber grain, subtle iron-gall ink stains and faint water rings, deckled
hand-cut edges, fine surface relief from quill scratches, photographed flat with
raking 90-degree candlelight to reveal micro-topography, neutral warm cream tones
#E8DCC0 to #C8B496, museum archive scan quality, 8K, sharp focus, no stylization,
no illustration
```

**Variant-Slots** (via Seed + extra phrase):
- Flat: `(default)`
- Rolled: `rolled scroll partially unfurled`
- Creased: `creased and folded with visible fold lines`
- Wax-sealed: `red wax seal pressed in center with house sigil imprint`
- Burned: `partially burned edge with brittle char`
- Tea-stained: `tea-stained corners with brown spreading`

---

## House-Atmosphere-Panoramas — `fal-ai/flux-2-pro` equirectangular

Resolution: `width: 2048, height: 1024` (2:1 ratio) — das sind ≈2,1 MP, nach Aufrundung 3 MP. 4 Houses
× 20 Iterations = 80 Generationen; $2.40 ist die 1-MP-Untergrenze, real kommen +$0.015 je weiterem
angefangenen Megapixel dazu. Used as R3F `<Environment files={url} background={false} />`.

### Drachenfeste-Throne-Hall

```
360 degree equirectangular HDR panorama, hyperrealistic medieval great hall lit by
iron braziers and red stained glass windows, weathered grey-stone walls with hanging
crimson banners, fire-cast shadows dancing on stone, golden afternoon light spilling
through arched gothic windows, no visible horizon discontinuity, seamless wrap, ARRI
Alexa cinematography, photoreal, no stylization, no text, no people, no signature
```

### Turm der Ketten — Library-Tower

```
360 degree equirectangular HDR panorama, hyperrealistic medieval library tower with
floor-to-ceiling oak shelving, leather-bound tomes and rolled charts, blue stained
glass windows casting cool light, brass instruments and astrolabes on reading desks,
no visible horizon discontinuity, seamless wrap, ARRI Alexa cinematography, photoreal,
no stylization, no text, no people, no signature
```

### Tiefe Esse — Forge-Cathedral

```
360 degree equirectangular HDR panorama, hyperrealistic underground forge cathedral
carved from living stone, glowing forge fires casting amber light, hanging chains and
finished blades, smoke-blackened ceiling, anvils and quenching troughs, no visible
horizon discontinuity, seamless wrap, ARRI Alexa cinematography, photoreal, no
stylization, no text, no people, no signature
```

### Liebe & Leben — Healing-Grove

```
360 degree equirectangular HDR panorama, hyperrealistic ancient healing grove inside
a living tree-cathedral, dappled green sunlight through canopy, hanging herbs and
hand-blown glass lanterns, moss-covered stone altars, no visible horizon
discontinuity, seamless wrap, ARRI Alexa cinematography, photoreal, no stylization,
no text, no people, no signature
```

---

## Hero-Video-Loops — `fal-ai/veo3.1` (5s seamless)

Top-5-Splash-Pages × $1.00 pro 5-s-Loop ($0.20/s @720p und @1080p ohne Audio). Mit Audio waeren es
$0.40/s = $2.00 pro Loop, die NO-audio-Variante spart also genau 50 %. @4K kostet der Loop $2.00 ohne
Audio bzw. $3.00 mit Audio. Guenstigere Tiers derselben Familie: `fal-ai/veo3.1/fast` ($0.10/s bzw.
$0.15/s @720p und @1080p) und `fal-ai/veo3.1/lite` ($0.03/s @720p ohne Audio bis $0.08/s @1080p mit
Audio). Use first-frame-equals-last-frame for seamless loop.

Die frueher hier stehende Wildcard `fal-ai/veo3.1/...` ist durch die konkrete Basis-ID ersetzt —
eine Platzhalter-ID laesst sich nicht gegen die Live-API pruefen (SKILL.md, Hard Rule 9).

### Master Template

```
hyperrealistic slow cinematic dolly across [SCENE_FOCUS], [3-5 PROPS], dust motes
drifting in shafts of golden window light, seamless loop with first-frame-equals-
last-frame, ARRI Alexa cinematography, shallow depth of field f/1.8, 5 seconds,
no people, no text, no signature, photoreal, no stylization
```

### Variants per Splash-Page

- **War-Room (Combat-Entry):** `SCENE_FOCUS=an ancient oak war-room table` / `PROPS=hand-drawn battle maps weighted by brass compasses, antique leather-bound tomes, hand-rolled parchment scrolls with red wax seals, brass astrolabe catching candlelight`
- **Library (lore-admin):** `SCENE_FOCUS=an ancient oak desk in a candlelit library` / `PROPS=leather-bound tomes, hand-rolled scrolls, brass quill and ink well, magnifying lens on open ledger`
- **Forge (Char-Sheet entry):** `SCENE_FOCUS=a working medieval forge` / `PROPS=glowing horseshoe on anvil, hammer mid-strike resting position, water-quenching trough, hanging finished blades`
- **Healing-Chamber:** `SCENE_FOCUS=a healer's stillroom` / `PROPS=mortar and pestle, drying herbs hanging from beams, hand-blown glass vials catching sunlight, open recipe-book`
- **Map-Room (session-gm):** `SCENE_FOCUS=a strategist's map room` / `PROPS=topographic battle-map on oak table, brass dividers and compasses, hand-painted miniatures positioned mid-encounter, candle flickering`

---

## Character-Token-3D — `fal-ai/hunyuan-3d/v3.1/rapid/text-to-3d`

Per Token $0.225 pro Generation. Used for in-game tokens, character-sheet portrait-thumbs, NPC
list-icons.

### Master Template (Style-Lock — IDENTICAL across all tokens)

```
hyperrealistic 3D miniature figurine of [CHARACTER_DESCRIPTION], hand-painted museum-grade
resin finish, photogrammetry-quality detail, weathered medieval equipment with hammer
marks and edge wear, neutral T-pose facing forward, soft three-point studio lighting,
28mm wargaming scale aesthetic, photoreal, no stylization, no cartoon, no anime
```

**CHARACTER_DESCRIPTION-Slots** (examples):
- `a heavyset blacksmith in scorched leather apron, hammer in right hand, bearded`
- `a slender elven scout in mottled grey cloak, hood up, hand on dagger hilt`
- `a robed scholar with silver hair, open tome in hands, brass spectacles`
- `an armored knight in pitted chainmail, broken longsword raised, helmet under arm`

---

## Wax-Seals (Card-Header-Component asset) — `fal-ai/flux-2-pro`

Per Haus 1 statisches Asset + 1 mit Imprint = 8 Generationen × $0.03 (erstes Output-Megapixel) =
~$0.24 total bei 1 MP; jedes weitere angefangene MP kostet +$0.015.

```
hyperrealistic close-up of red wax seal pressed onto aged parchment, [HOUSE_NAME]
sigil imprint pressed deep into cooled wax, irregular hand-pressed edges, glossy
center fading to matte rim, micro-cracks visible, dramatic side-lighting from candle,
neutral parchment background, ARRI Alexa macro cinematography, photoreal, no
stylization, no text
```

`HOUSE_NAME`-Slot: `coiled dragon and broken sword` (Drachenfeste) / `tower wrapped in chains` (Turm) / `anvil and crossed hammers` (Esse) / `ivy and chalice` (Liebe).

---

## Prompt-Engineering-Rules (lessons learned)

1. **Realism-Lock muss am Anfang stehen** — fal-Modelle interpretieren spätere Worte stärker, aber `hyperrealistic` als erstes Wort verhindert dass das Modell in Cartoon kippt.
2. **Material-Detail-Wörter sind die zweite Realismus-Schicht** — `patina, fiber grain, soot residue, oxidation` machen den Unterschied zwischen "rendered" und "photographed".
3. **Cinematography-Anker sind die dritte Schicht** — `ARRI Alexa, shallow depth of field, raking light` triggern Foto-Realismus-Training-Data.
4. **Niemals `digital art, concept art, fantasy art, painting` benutzen** — auch wenn man "kunstvoll" meint. Diese Wörter ziehen das Modell sofort in Illustration.
5. **`no stylization, no painting, no cartoon` am Ende** als Sicherheitsnetz — verstärkt den Realismus-Pull.
6. **House-Hex-Codes direkt im Prompt** — `#8B1A1A enamel inlay` ist präziser als `dark red enamel`. fal versteht Hex-Codes.
7. **Lighting-Direction explizit** — `raking light from 90 degrees` oder `forge firelight from below` ist immer besser als generisches `dramatic lighting`.
8. **Negative-Prompts (wo supported, z.B. `fal-ai/flux-2-pro`):** immer `flat colors, anime, painted, stylized, low-poly, illustration, watermark, text, logo, signature`.

---

## Cost-Summary Phase 0 Generation (mit reichlich Iteration)

| Asset | Endpoint | Qty | Iterations | Unit-Cost | Sub-Total |
|---|---|---|---|---|---|
| House-Sigils | `fal-ai/hyper3d/rodin` | 4 | 30 each | $0.40 pro Generation | $48 |
| Pergament-Textures | `fal-ai/flux-2-pro` | 30 | 1 each | $0.03 (1. MP) +$0.015/MP | ≥$0.90 |
| House-Panoramas | `fal-ai/flux-2-pro` | 4 | 20 each | $0.03 (1. MP) +$0.015/MP | ≥$2.40 |
| Hero-Loops | `fal-ai/veo3.1` (no audio) | 5 | 3 each | $1.00 pro 5-s-Loop @720p/1080p | $15 |
| Wax-Seals | `fal-ai/flux-2-pro` | 8 | 3 each | $0.03 (1. MP) +$0.015/MP | ≥$0.72 |
| Char-Tokens | `fal-ai/hunyuan-3d/v3.1/rapid/text-to-3d` | 50 | 1 each | $0.225 pro Generation | $11.25 |
| A/B-Reserve | mixed | — | — | — | ~$30 |
| **Total budget** | | | | | **≥~$108** |

Die drei `fal-ai/flux-2-pro`-Zeilen sind Untergrenzen: sie rechnen mit 1 Megapixel Output. 2K-Texturen
und 2048×1024-Panoramas liegen darueber, jedes weitere angefangene MP kostet +$0.015 (Input **und**
Output). Der Gesamtbetrag ist deshalb ein Minimum, keine Punktschaetzung.

Spending-Cap im fal.ai-Dashboard: empfohlen $200/Monat.
