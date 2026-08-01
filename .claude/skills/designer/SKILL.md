---
name: designer
description: UI/UX-Spec, Design-Tokens, Animations and Game-UI-Style decisions across the 3 Flammenreiter React frontends
---

# Designer

The Designer persona owns the **visual + interaction language** of the Flammenreiter platform across `lore-admin`, `session-gm`, and `session-player`. Used whenever a story touches UI structure, tokens, animations, transitions, or component design.

Pairs with the [design-briefing](../design-briefing/SKILL.md) skill — that one writes the per-story brief, this one carries the standing rules and decisions.

## Plugin-Routing (seit 2026-05-23)

- **Generic UI-Specs / Design-Token-Schema:** `frontend-design` Plugin-Skill (claude-plugins-official) — best-practice Heuristik für Token-Hierarchie, Component-Anatomy, Accessibility.
- **Dieser Skill:** wenn Flammenreiter-Spezifika gefragt sind — fal.ai-Prompt-Library, Pergament-/WaxSeal-/Scene-Mode-Patterns, Game-UI-Authority, House-Color-System, Pattern-Library mit Lottie/Framer-Motion-Tokens.
- **Hybrid:** Plugin für Standard-Token-Audit, dieser Skill für die spezifischen Pergament-/Atmosphere-Layer-Entscheidungen.

Memory: `project_plugins_installed.md` + `project_redesign_prompt_style.md`.

## Creative authority (Glenn-Decision, 2026-05-12)

The Designer is **standing-authorized** to generate new images and new animations without per-task approval. This is the core of the role.

- **Images:** create via `fal.ai` (existing api integration), Canva MCP (`mcp__claude_ai_Canva__*`), or any generation pipeline that fits the brief. Drop assets into the appropriate location (e.g. `lore-admin/public/images/`, `<repo>/src/assets/`, `entity_images` table for world-data art).
- **Animations:** author new Framer Motion variants, Lottie files, or CSS keyframes. When adding a recurring pattern (used in >1 spot), promote it into the **Pattern library** table below and reference it from there.
- **Naming:** image files in kebab-case + a short semantic suffix (`location-drachenfeste-hero.webp`, `npc-portrait-kaya.png`). Lottie / animation JSON: same convention.
- **Asset licensing:** generated outputs from fal.ai / Canva are usable under their respective licenses (commercial OK for Flammenreiter). Don't import 3rd-party assets without Glenn-sign-off.

This authority is broad on purpose. It does not extend to:
- Schema / data-model changes (that's Senior Backend)
- Tech-stack changes (Framer Motion + Radix-UI locked per C.2=c)
- Hardcoding colors / fonts / spacing outside the shared/config tokens

---

## Phase 3 Vision — Atmospheric Char-Layer

> _"Ich hätte gerne, dass wir wirklich mit vielen Bildern, Kleinanimationen [arbeiten].
> Beim Turm von Liebe und Leben soll sich was übers Bildschirm ranken. Aber auch deine
> Rasse soll widerspiegelt werden: bei einem Zwerg ist alles mehr aus Stein. Bei einem
> Aasimar mehr göttliche Richtung. Bei einem Halbelfen ein bisschen angehaucht in die
> Magierichtung. Roll20-Overlay-Richtung, aber modern, mit Transitions, auf einer
> epischen Ebene. Und viel mit generierten Kleinst-Elementen."_
>
> — Glenn, 2026-05-12

Reference: [`workspace-docs/design/atmospheric-char-layer.md`](../../../workspace-docs/design/atmospheric-char-layer.md)

### Die drei Layer

Über dem statischen UI liegt eine adaptive Hintergrund-Komposition, die in Echtzeit auf den aktiven Charakter reagiert. Drei modulare Schichten:

```
╔════════════════════════════════════════════════════════════════════╗
║                                                                    ║
║   LAYER C  ⚡ Klassen-Aktions-Effekte                              ║
║            ↳ Spell-Glyph-Bloom, Klingen-Glanz, Heil-Aura           ║
║            ↳ getriggert bei Actions, ephemer (1-2s)                ║
║   ─────────────────────────────────────────────────────────────    ║
║   LAYER B  🜃 Rassen-Material-Modulation                           ║
║            ↳ Zwerg: Stein-Risse + Staub-Partikel                   ║
║            ↳ Aasimar: göttlicher Atem-Puls + Sterne-Glitter        ║
║            ↳ Halbelf: gelegentliche Magie-Glyphen blitzen          ║
║            ↳ subtle, char-immersiv, dauerhaft                      ║
║   ─────────────────────────────────────────────────────────────    ║
║   LAYER A  🏛 Akademie-Macro-Atmosphäre                            ║
║            ↳ Drachenfeste: Funkenregen + Schwingen-Schatten        ║
║            ↳ Turm der Ketten: Ketten-Ornamente + Schrift-Glitch    ║
║            ↳ Tiefe Esse: pulsierende Stein-Adern                   ║
║            ↳ Liebe & Leben: Ranken wachsen übers Bild              ║
║            ↳ dominanteste Schicht, House-defining                  ║
║   ════════════════════════════════════════════════════════════     ║
║   UI       Content, Sidebar, Nav, Cards, Forms                     ║
║   ────                                                             ║
║   BASE     Void background, warm-dark Palette                      ║
║                                                                    ║
╚════════════════════════════════════════════════════════════════════╝
```

**Idle-Mode:** alle Layer im Sleep-State, sehr subtile Atemlicht-Pulse.
**Power-Mode:** Triggern bei Page-Transition, Char-Switch, oder Action → kurzer Burst, dann zurück zu Idle.

### Storytelling — die 4 Akademien

#### 🔥 Drachenfeste — Schmiede, Drache, Mut

> _Du betrittst Drachenfeste. Die Luft schmeckt nach Asche und glühendem Metall.
> Im Hintergrund pulsiert das Echo eines Schmiede-Hammers. Funkenregen treibt
> vom unteren Rand nach oben. Hin und wieder zieht der Schatten gewaltiger
> Schwingen über die Glas-Decke — flüchtig, fast geträumt._

Farben: tiefes Rot `#8B1A1A` + glühendes Gold `#D4A843`. Hintergrund-Stills: glühende Schmiedeglut, Drachenschuppen-Texturen am Rand. Animationen: Asche-Drift (langsam aufsteigend), Funken-Cluster bei Page-Wechsel, Drachen-Silhouette (1-2s Power-Moment).

Erwartetes Concept-Bild: `concepts/akademie-drachenfeste-hero-1.webp`

#### 🔗 Turm der Ketten — Wissen, Ordnung, Tinte

> _Im Turm der Ketten herrscht stille Diszipliniertheit. Hauchdünne Ketten-
> Ornamente zeichnen sich am Frame ab, als hielten sie das Wissen selbst
> zusammen. Silberne Tinten-Streifen tropfen kurz auf, Schriftzeichen-Glitch-
> Effekte wandern über Headlines wie ein altes Pergament, das sich
> selbst neu interpretiert._

Farben: tiefes Marineblau `#1A3A5C` + Silber `#A8B8C8`. Hintergrund-Stills: Ketten-Ornamente am Frame, alte Pergament-Texturen, Schriftzeichen-Glitch-Effekte. Animationen: Tinte tropft (kurz), Ketten-Glanz-Welle, Schrift-Glitch (subtle).

Erwartetes Concept-Bild: `concepts/akademie-turm-der-ketten-hero-1.webp`

#### 🔨 Tiefe Esse — Handwerk, Erde, Glut

> _Tiefe Esse atmet mit dem Berg. Stein-Risse ziehen sich über den Hintergrund,
> tief in ihnen pulsieren glühende Adern wie das Herz eines schlafenden Drachen.
> Bei jedem Hover spürst du die Vibration des Hammers in den Buttons. Erz-
> Splitter glitzern bei Bewegungen, Bernstein-Pulse atmen durch die Fugen._

Farben: warmes Braun `#6B4226` + Bernstein `#C8842A`. Hintergrund-Stills: Stein-Adern, Erz-Glanz, Glut in Spalten. Animationen: Hammer-Vibration auf Click, Erz-Splitter-Twinkle, Adern-Puls (rhythmisch).

Erwartetes Concept-Bild: `concepts/akademie-tiefe-esse-hero-1.webp`

#### 🌿 Liebe & Leben — Heilung, Natur, Wachstum

> _Du öffnest Liebe & Leben — und der Bildschirm atmet. Aus den Ecken wachsen
> Ranken über das Layout, schlagen feine Blattknoten an die Buttons, drücken
> sanft Blütenblätter in den Lese-Pfad. Heilungs-Aura pulst hauchzart hinter
> Cards, als säße jeder Knoten in einem Garten._

Farben: tiefes Grün `#2A5C3A` + Jade `#7AB88A`. Hintergrund-Stills: Ranken-Knoten, Blattwerk, weiches Atemlicht. Animationen: **Ranken wachsen** (L-System, ~3-4s Growth-Animation bei Page-Enter, dann statisch), Blütenblätter-Drift, Heilungs-Puls.

Erwartetes Concept-Bild: `concepts/akademie-liebe-leben-hero-1.webp`

### Rassen-Modulation — Material-Sprache pro Ancestry

Layer B überlagert das Akademie-Idiom mit einer **Material-Filter-Schicht**:

| Ancestry-Key | Material | Idle-Effekt | Hover/Click-Effekt |
|--------------|----------|-------------|---------------------|
| `mensch` | Pergament, neutral | keine Modulation | – |
| `hochelf` | fließendes Licht | Cursor-Lichtspur | Halo um Buttons |
| `holzelf` | Naturgrün-Tint | Blätter-Spuren bei Cursor | Blatt-Spread |
| `dunkelelf` | Schatten-violett | langgezogene Schatten | violette Aura |
| `halbelf` | Licht + Magie-Hauch | Magie-Glyph blitzt (~10s) | Glyph-Bloom |
| `bergzwerg` | Stein, Erz | Steinkanten an Buttons | Staub-Partikel |
| `huegelzwerg` | warm-Bernstein | Erdton-Pulse | Glanz-Drift |
| `halbling` | Holz, Heim | weiches Lampen-Licht | Lampen-Flackern |
| `aasimar` | göttliches Licht | sanftes warmes Pulsen | Sterne-Glitter |
| `tiefling` | Schatten, Schwefel | rote Funken (rare) | dunkler Rauch |
| `drakonid_rot` | Schuppe, Hitze | glühende Adern | Hitze-Distortion |
| `drakonid_blau` | Schuppe, Blitz | elektrische Funken | Blitz-Crack |
| `drakonid_gruen` | Schuppe, Säure | Säure-Tropfen | Säure-Spritzer |
| `drakonid_schwarz` | Schuppe, Säure | dunkle Aura | Schatten-Crack |
| `drakonid_weiss` | Schuppe, Eis | Eiskristall-Funken | Eis-Crack |
| `genasi_feuer` | Element-Feuer | Flammen-Wisp | Flammen-Burst |
| `genasi_wasser` | Element-Wasser | Wasser-Wellen | Wasser-Spritzer |
| `genasi_erde` | Element-Erde | Stein-Rumbling | Stein-Welle |
| `genasi_luft` | Element-Luft | Wind-Streifen + ferne Wolken | Wind-Stoß |

### Klassen-Aktions-Layer

Layer C ist **event-driven**. Triggert nur bei Aktionen, nicht im Idle:

| Klasse | Trigger | Visueller Effekt |
|--------|---------|---------------------|
| Magier | Spell-Cast | Arkaner Glyph-Bloom an Action-Position |
| Zauberer | Wild-Surge | Random-Color-Funken + gelegentlich Glitch |
| Hexenmeister | Pakt | Dunkle Aura mit violetten Highlights |
| Kleriker | Heal/Divine | Goldener Aura-Bloom über Page |
| Paladin | Divine-Strike | Heiligen-Strahl von oben |
| Druide | Nature-Cast | Blätter-Cascade über Action |
| Barde | Song | Notenwellen-Ripple (musical visualizer) |
| Krieger | Attack-Roll | Klingen-Glanz / Funken |
| Barbar | Rage/Strike | Wut-Flammen am Rand |
| Schurke | Stealth | UI dimmt, Schatten wachsen |
| Mönch | Ki-Strike | Konzentrische Ki-Welle |
| Ranger | Arrow-Shot | Pfeil-Spur am Click-Pfad |

### Visuelles Companion — Page-Mockup

```
┌────────────────────────────────────────────────────────────────┐
│  ✦   ✦      ✦                       ✦      ✦      ✦   ✦       │ ← Sterne (Aasimar)
│ ⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙ │ ← Ranken (Liebe&Leben Macro)
│ ⤙ ┌────────┐                                                ⤙│
│ ⤙ │ FLAMMEN │   ┌─────────────────────────────────────────┐  ⤙│
│ ⤙ │ REITER  │   │                                         │  ⤙│
│ ⤙ │ ───────│   │       CHARAKTER-DETAIL — Mirael         │  ⤙│
│ ⤙ │ ⌂ Dash  │   │       Halb-Elf · Magier · Liebe&Leben    │  ⤙│
│ ⤙ │ ⊞ Karte │   │                                         │  ⤙│
│ ⤙ │ ⚔ Combat│   │   STR  DEX  CON  INT  WIS  CHA           │  ⤙│
│ ⤙ │ ✦ Lore  │   │    8   14   12   18   13   16            │  ⤙│
│ ⤙ │ ⊞ Inv   │   │                                         │  ⤙│
│ ⤙ │         │   │   ┌─ Fähigkeiten ────────────────────┐   │  ⤙│
│ ⤙ │ +Neu    │   │   │  · Arkane Erkenntnis             │   │  ⤙│
│ ⤙ └────────┘   │   │  · Magie-Aspekt:  Tiefe Esse     │   │  ⤙│
│ ⤙              │   └──────────────────────────────────┘   │  ⤙│
│ ⤙              │                                         │  ⤙│
│ ⤙   ✨← Glyph │   ┌─ Zauber ────────────────────────────┐ │  ⤙│ ← Magie-Glyph blitzt (Halbelf)
│ ⤙   blitzt    │   │  [Feuerball]  [Heilen]  [Schild]   │ │  ⤙│
│ ⤙              │   └──────────────────────────────────┘   │  ⤙│
│ ⤙              └─────────────────────────────────────────┘  ⤙│
│ ⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙⤙ │
│  ✦       ✦         ✦              ✦         ✦       ✦         │
└────────────────────────────────────────────────────────────────┘
        ▲                       ▲                       ▲
   Layer A wird zum         Layer B addiert Magie-     Layer C: bei Spell-Click
   "Ranken-Frame"           Glyphen-Blitzer            kommt Arkaner Bloom
   (Liebe&Leben Macro)      (Halbelf-Modulation)       (Magier-Klassen-Effekt)
```

Bei Char-Switch zu einem Zwerg-Krieger-Drachenfeste-Char:

```
┌────────────────────────────────────────────────────────────────┐
│         ·  ·    ·          ·    ·       ·        ·             │ ← Funkenregen (Drachenfeste)
│ ☆☆☆☆☆☆☆☆☆☆☆ Stein-Adern an den Rändern ☆☆☆☆☆☆☆☆☆☆☆☆☆           │ ← Stein-Risse (Zwerg-Modulation)
│ ☆       (glühen mit Bernstein-Pulse)                      ☆    │
│   :Drachen-Silhouette flüchtig oben rechts:                    │
│ ☆ ┌─────────┐ ┌─ Thorin · Bergzwerg · Krieger · Drachenfeste┐ ☆│
│ ☆ │ FLAMMEN │ │                                             │ ☆│
│ ☆ │ REITER  │ │   STR 18  DEX 12  CON 16  ...               │ ☆│
│ ☆ └─────────┘ │                                             │ ☆│
│ ☆             │   [Greatsword] ←──── Klick erzeugt           │ ☆│ ← Layer C: Klingen-Glanz
│ ☆             │      Klingen-Glanz + Funken                 │ ☆│   (Krieger-Klasse)
│ ☆             └─────────────────────────────────────────────┘ ☆│
│ ☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆ │
│              ·  ·       ·         ·        ·                    │
└────────────────────────────────────────────────────────────────┘
```

Cross-Fade-Transition (~600ms) wenn der User von Mirael zu Thorin wechselt.

### Art-Bible — fal.ai Prompts

Wenn Designer- oder Background-Agent Concept-Art via fal.ai generiert, diese Prompts als Master-Bible nutzen. Model: `fal-ai/flux-pro/v1.1` (existing api-Integration).

**Akademien — je 3 Variants (12 Hero-Stills total):**

```
DRACHENFESTE
─────────────
Dark fantasy academy tower interior, glowing forge embers floating
upward, blood-red and gold color palette (#8B1A1A primary, #D4A843
accent), dragon scale textures in shadow margins, ember particles
mid-air, atmospheric chiaroscuro lighting, painterly D&D Beyond /
Roll20-modern aesthetic, no characters in scene, 16:9 hero composition,
high detail in foreground textures, dark warm vignette, no text.

Variant-1: smithy-glow — focus on forge with rising embers
Variant-2: dragon-silhouette — winged silhouette over distant tower
Variant-3: ash-drift — wider scene with ash particles drifting up

TURM DER KETTEN
────────────────
Mystical academy tower interior with hanging silver chain ornaments,
dark navy and silver color palette (#1A3A5C primary, #A8B8C8 accent),
old parchment scrolls, ink-stains, magical glyphs etched in stone,
moonlit window light, scholarly atmosphere, painterly fantasy style,
no characters, 16:9 hero composition, dark blue dominant, no text.

Variant-1: chain-frame — chains hang along borders of composition
Variant-2: ink-streams — silver ink dripping from suspended scrolls
Variant-3: glyph-glitch — overlapping magical script across walls

TIEFE ESSE
──────────
Underground forge academy carved into mountain stone, glowing amber
veins running through dark rock walls, warm brown and amber palette
(#6B4226 primary, #C8842A accent), ore-glints in stone, hammer-impact
sparks, deep tunnel-end glow, atmospheric subterranean lighting,
painterly fantasy, no characters, 16:9 hero, no text.

Variant-1: glowing-veins — emphasis on amber veins in stone
Variant-2: ore-glitter — small ore crystals embedded in walls
Variant-3: hammer-echo — distant glowing forge at end of corridor

LIEBE & LEBEN
─────────────
Lush nature academy with living vines growing across stone architecture,
deep green and jade color palette (#2A5C3A primary, #7AB88A accent),
flower petals drifting in air, healing aura soft glow, garden atrium,
warm sunlight filtering through leaves, peaceful but powerful,
painterly fantasy, no characters, 16:9 hero, no text.

Variant-1: vine-growth — vines actively spreading from corners
Variant-2: petal-drift — many soft petals in air
Variant-3: atemlicht — calm glow with subtle aura pulses
```

**Rassen-Material-Examples (für visuell-aufwendige Rassen, 6 Stills):**

```
DRAKONID_ROT (red dragon-blooded scale texture)
Seamless tileable scale-pattern PNG, fiery red scales (#8B1A1A) with
amber highlights, photorealistic detail, no characters, 512x512 tile.

DRAKONID_BLAU
Same as above, blue scales (#1A3A5C) with silver edge highlights.

AASIMAR (celestial atmosphere overlay)
Subtle starfield with celestial light streaks, transparent PNG overlay
for layering over UI, golden #D4A843 accents, dark navy background,
1920x1080 panorama.

TIEFLING (shadow / sulfur overlay)
Dark smoky atmosphere with subtle red ember particles, transparent
PNG overlay, deep crimson #8B1A1A with charcoal shadows, 1920x1080.

GENASI_FEUER (elemental fire wisp pattern)
Flickering flame wisp pattern, transparent PNG for layering at screen
edges, orange-red gradient, painterly fantasy style, 512x1080 vertical.

GENASI_WASSER (elemental water wave overlay)
Subtle wave distortion pattern, transparent PNG, blue gradient
(#1A3A5C → #7AB88A), painterly, 1920x1080.
```

**Page-Mockup-Concepts (3 Composites mit ausgewähltem Char):**

```
COMPOSITE-1: Char-Sheet "Mirael" (Halbelf-Magier, Liebe & Leben)
Show full character-detail page with Liebe-&-Leben atmospheric layer
(vines from corners), half-elf magic glyph effect mid-page, character
stats panel on left, spell buttons bottom right, dark warm UI palette,
Cinzel headings, EB Garamond body text, "epic D&D Beyond modern"
aesthetic, no real photo elements.

COMPOSITE-2: Combat-View "Thorin" (Zwerg-Krieger, Drachenfeste)
Combat encounter screen with Drachenfeste atmospheric layer
(ember particles), dwarven stone texture on UI cards, attack-roll
glow effect mid-screen, initiative tracker on top, dice roller right,
warm forge palette, epic dramatic feel.

COMPOSITE-3: Session-Page "Zara" (Mensch-Kleriker, Tiefe Esse)
GM session view with Tiefe-Esse atmospheric layer (amber stone veins),
NPC-panel on right (per Phase-3 NPC-rechts spec), healing aura
effect, calendar/event timeline, warm earthy palette, ceremonial feel.
```

### Page-Transition Choreography

Wenn der User von Login → /character navigiert:

```
T=0ms     User klickt "Eintreten"
T=0-300ms Login-Form fade-out, Submit-Button shows loading spinner
T=300ms   Real Supabase auth completes
T=300-500ms Layer A starts: house-macro fades in (cross-fade from void)
T=500-800ms Layer B starts: ancestry-modulation overlays
T=800ms   Char-Detail Content appears with staggered list-in
T=800-1200ms Stagger continues: Stats card, Spell card, Inventory card
T=1200ms  Idle state — Akademie-Loop läuft, Rasse-Idle aktiv
```

```
SEQUENCE:
─────────
  T=0       T=300     T=500     T=800     T=1200
  │         │         │         │         │
  │ Login   │ Auth    │ Layer A │ Content │ Idle
  │ fade    │ pending │ macro   │ stagger │ loop
  │         │         │         │         │
  └─────────┴─────────┴─────────┴─────────┴────►
                                                  Time
```

### Procedural Generators — code that creates the magic

Deterministisch pro Char (Seed = `character.id`-Hash):

```ts
// shared/src/lib/atmospheric/generators/generate-stone-cracks.ts
export const generateStoneCracks = (options: {
  seed: string      // character.id
  density: number   // 0..1, default 0.3
  width: number     // canvas px
  height: number
}): SVGPathElement[] => { /* L-system / random-walk */ }

// shared/src/lib/atmospheric/generators/generate-vines.ts
export const generateVines = (options: {
  seed: string
  startCorner: 'tl' | 'tr' | 'bl' | 'br'
  depth: number     // L-system iterations
  length: number    // total px
}): SVGPathElement[] => { /* L-system plant growth */ }

// shared/src/lib/atmospheric/generators/generate-celestial-stars.ts
// Poisson-disc-distribution, twinkle-Animation via Framer Motion

// shared/src/lib/atmospheric/generators/generate-magic-glyphs.ts
// Pentagon/Hexagon-Komposition mit symmetrischen Sigil-Lines

// shared/src/lib/atmospheric/generators/generate-dragon-scales.ts
// Voronoi-Tessellation mit Glow-Filter

// shared/src/lib/atmospheric/generators/generate-elemental-wisps.ts
// Particle-Field mit Element-modulierter Bewegung
```

Jeder Generator:
- Pure function (deterministic with seed)
- Returns SVG-element-data (paths, circles, polygons)
- Unit-tested mit Vitest (snapshot-based)
- Tree-shakeable

### Roll20-Vergleich (Glenn-Referenz)

|  | Roll20 | Flammenreiter Phase 3 |
|---|--------|------------------------|
| **Overlay-Stil** | Statisches Dark-Brown-Pergament | Adaptiv pro Char, drei reaktive Layer |
| **Animationen** | minimal (Dice-Roll-Animation) | Sub-tile permanent + Power-Bursts |
| **Personalisierung** | Char-Avatar + Stats | Full atmospheric UI atmet mit Char |
| **Tech-Stack** | jQuery + Backbone | React 19 + Framer Motion + SVG/Lottie |
| **Epische Momente** | Token-Effects, Sound | Plus Akademie-Macro, Rassen-Modulation, Klassen-Action |

Wir nehmen Roll20's warm-dunkel-Pergament-Grundton und packen drei Layer adaptiver Animation drauf — modern, atmospheric, persönlich.

### Concept-Asset-Verzeichnis (generiert 2026-05-12 via fal.ai flux-pro/v1.1)

21 Concept-Bilder unter `workspace-docs/design/concepts/`:

**Akademien (4 × 3 = 12 Hero-Stills):**
- `akademie-drachenfeste-hero-{1,2,3}.webp` — Schmiede-Glut, Drachen-Silhouette, Asche-Drift
- `akademie-turm-der-ketten-hero-{1,2,3}.webp` — Ketten-Frame, Tinte-Streams, Glyph-Glitch
- `akademie-tiefe-esse-hero-{1,2,3}.webp` — Glühende Adern, Ore-Glitter, Hammer-Echo
- `akademie-liebe-leben-hero-{1,2,3}.webp` — Ranken-Wachstum, Blütenblatt-Drift, Atemlicht

**Rassen-Materials (6 Stills):**
- `ancestry/drakonid-rot-scale-tile.webp` — feurig-rote Schuppen, seamless tile
- `ancestry/drakonid-blau-scale-tile.webp` — tief-blaue Schuppen, seamless tile
- `ancestry/aasimar-celestial-overlay.webp` — Sternenfeld + goldene Lichtstreifen
- `ancestry/tiefling-shadow-overlay.webp` — Rauchschwaden + rote Ember-Partikel
- `ancestry/genasi-feuer-wisp.webp` — flackernde Flammen-Wisps am unteren Rand
- `ancestry/genasi-wasser-wave.webp` — Wasser-Wellen-Distortion-Pattern

**Composites (3 UI-Mockups):**
- `composites/char-sheet-mirael-halbelf-magier-liebe-leben.webp` — Char-Sheet mit Liebe&Leben-Atmosphäre + Halbelf-Magier-Layer
- `composites/combat-thorin-zwerg-krieger-drachenfeste.webp` — Combat-View mit Drachenfeste-Forge + Zwerg-Krieger-Layer
- `composites/session-zara-mensch-kleriker-tiefe-esse.webp` — GM-Session-View mit Tiefe-Esse-Ambient + Kleriker-Layer

**Featured (siehe inline):**

![Drachenfeste — Schmiede-Hero](../../workspace-docs/design/concepts/akademie-drachenfeste-hero-1.webp)
![Turm der Ketten — Gothic-Hall](../../workspace-docs/design/concepts/akademie-turm-der-ketten-hero-1.webp)
![Tiefe Esse — Glühende Adern](../../workspace-docs/design/concepts/akademie-tiefe-esse-hero-1.webp)
![Liebe & Leben — Ranken-Atrium](../../workspace-docs/design/concepts/akademie-liebe-leben-hero-1.webp)

**Composite-Vision (Mirael · Halbelf · Magier · Liebe & Leben):**

![Char-Sheet Composite](../../workspace-docs/design/concepts/composites/char-sheet-mirael-halbelf-magier-liebe-leben.webp)

### Re-Generation

Wenn ein Bild iteriert werden soll: Prompt-Datei in `scripts/fal-prompts/<name>.json` anpassen, dann:

```bash
node scripts/fal-generate.mjs scripts/fal-prompts/<name>.json
```

Generator-Script ist `scripts/fal-generate.mjs` — liest `FAL_API_KEY` aus workspace `.env` (NEVER commited), single-image per run, ~5-10s pro Bild, ~$0.005 pro Bild.

**Bekannte Limitationen aus fal.ai flux-pro:**
- Text in UI-Composites ist garbled (AI image gen kann meistens keinen lesbaren Text)
- Manche Bilder zeigen Charaktere obwohl "no characters" gepromptet (drift)
- Gelegentlich Watermark-/Signatur-Artefakte aus Training-Data
- Für Production-Final-Polish ggf. Hand-cleanup oder Re-Roll mit präziseren Prompts

---

## Source of truth

| Layer | Where | Owner |
|------|-------|-------|
| **Design tokens** (colors, fonts, spacing, radii, shadows, motion) | `shared/src/config/houses.ts` + `shared/src/config/theme.ts` | shared (Single-Source) |
| **House primaries** | `shared/src/config/houses.ts` (4 houses table) | shared |
| **Tailwind theme** | per-frontend `tailwind.config.*` references shared/config via CSS vars | per-frontend |
| **Animation constants** | `shared/src/config/motion.ts` (PLANNED — Phase 3 prereq) | shared |
| **Component primitives** | `shared/src/ui/*` (button, card, dialog, spinner, skeleton, etc.) | shared |
| **Per-frontend UI** | `<repo>/src/shared/ui/*` (frontend-local extensions only) | per-frontend |

Never hardcode hex colors, font families, or animation durations in component code. Reference tokens via Tailwind class or `theme()` helper.

## The 4 houses (immutable, from world-design)

| Haus | Primary | Accent | Character |
|------|---------|--------|-----------|
| Drachenfeste | `#8B1A1A` | Gold `#D4A843` | Krieger, Mut, Feuer |
| Turm der Ketten | `#1A3A5C` | Silber `#A8B8C8` | Strategie, Ordnung, Wissen |
| Tiefe Esse | `#6B4226` | Bernstein `#C8842A` | Handwerk, Ausdauer, Erde |
| Liebe & Leben | `#2A5C3A` | Jade `#7AB88A` | Heilung, Natur, Diplomatie |

House assignment per character / NPC is data-driven (not hardcoded by the UI).

## Typography

| Use | Family | Weights |
|-----|--------|---------|
| Display / title | Cinzel Decorative | 700 |
| Headings | Cinzel | 600, 700 |
| Body | EB Garamond | 400, 500 |
| Code / stats | JetBrains Mono | 400 |

Load via global CSS (`app/styles/`), reference via Tailwind classes (`font-display`, `font-heading`, `font-body`, `font-mono`).

## Game-UI style direction (Glenn-Decision C.4=c)

**Inspiration:** D&D Beyond / Roll20 — clean, content-first, dark warm palette. **Not** heavy skeuomorphism — no faux leather, no chunky borders for decoration. But:

- **Frame language:** subtle gold/copper hairlines on cards/dialogs reinforce the academy / forge motif
- **Iconography:** Material Symbols (existing pattern) + house-specific glyphs where house identity matters
- **Color hierarchy:** void (`bg-void`) backdrop → card surface elevation → gold accent for actionable
- **No glow / no neon** — palette stays warm-earth-fire, gold not lime, copper not magenta
- **Image-heavy where the world is** (locations, NPCs, lore): generous portrait + scene-art placement, content text wraps

## Animation (Glenn-Decision C.2=c — Framer Motion + Radix-UI)

**Stack stays.** No new motion library introductions in Phase 3.

### Pattern library (canonical)

| Pattern | Spring vs Tween | Duration / Stiffness | Where |
|---------|------------------|----------------------|-------|
| Page transition | `motion.div` + `AnimatePresence` | spring, stiffness 220, damping 26 | Layout pages between routes |
| List stagger | `staggerChildren: 0.03` | 30 ms versatz, ease-out | Listings, feed-pages |
| Modal in/out | spring, stiffness 280, damping 24 | scale 0.96 → 1, opacity 0 → 1 | Dialog, Drawer |
| Toast slide-in | spring, stiffness 350, damping 30 | translateY 8 → 0 | Notifications |
| Hover scale | `whileHover={{ scale: 1.02 }}` | 100ms ease | Cards, buttons |
| Active-tap | `whileTap={{ scale: 0.98 }}` | 80ms ease | Primary buttons |

### Reduced-Motion (mandatory)

Every motion variant must include a `reducedMotion` branch:

```tsx
const prefersReducedMotion = useReducedMotion()
const cardVariants = prefersReducedMotion
  ? { initial: { opacity: 0 }, animate: { opacity: 1 } }
  : { initial: { opacity: 0, y: 8 }, animate: { opacity: 1, y: 0 } }
```

Tailwind utility `motion-safe:` / `motion-reduce:` is the lighter-weight alternative for pure CSS transitions.

## Radix-UI conventions

- Use Radix primitives directly (`@radix-ui/react-*`); wrap once in `shared/src/ui/<name>/<name>.tsx` to apply theme classes
- Never style Radix primitives ad-hoc inside feature code — go through the shared wrapper
- Accessibility props (`aria-*`, `role`) propagate from Radix automatically; don't override

## Cross-frontend consistency rules

| What stays shared (in `shared/src/ui/*`) | What's allowed local (in `<repo>/src/shared/ui/*`) |
|---|---|
| Button, Badge, Card, Dialog, Drawer, Toast, Tooltip, Tabs, Spinner, Skeleton, EmptyState, Avatar, Pagination, Input, Select, Switch, Checkbox, Radio | Repo-specific compositions (e.g. `LocationCard` in lore-admin, `EncounterHeader` in session-gm, `SpellTile` in session-player) |
| Design tokens, fonts, motion constants | — (must reference shared) |
| Common patterns (DetailPageNotFound, DetailSkeleton, AppShell variants) | per-frontend AppShell wiring (Sidebar contents, BottomNav items differ) |

If a frontend wants to "extend" a shared component, it must be via composition (wrap the shared primitive), not duplication.

## Designer responsibilities per story

1. Read the story / requirement
2. Identify target screens — new or existing?
3. Token audit — does this need new tokens? If yes → propose in `shared/`, not local
4. Component audit — can existing primitives be composed? If no → propose in `shared/`
5. Write the design brief using the [design-briefing](../design-briefing/SKILL.md) template
6. For animations: pick the matching pattern from the table above, or propose a new pattern with rationale + add it to this skill
7. Reduced-Motion variant defined upfront, not bolted on
8. Sign-off on the brief before the Frontend-Worker implements

## Anti-patterns

- ❌ Hardcoded hex colors / px values in components
- ❌ Per-frontend duplicates of shared UI primitives
- ❌ Motion without reduced-motion fallback
- ❌ Skeuomorphism / 3D-bevels / heavy decorative borders
- ❌ Neon glows, gradient text shadows, lime-green accents
- ❌ New animation library in Phase 3 (stack-decision locked: Framer Motion + Radix)
- ❌ Inline Radix primitive styling — always go through `shared/src/ui` wrappers

## Animation Reference Videos

31 Veo 3 reference clips for all animation layers — generated 2026-05-13 via `fal-ai/veo3` (720p, 6s, audio-off).

**Catalog:** [`workspace-docs/design/concepts/animations/index.md`](../../../workspace-docs/design/concepts/animations/index.md)

| Category | Count | Source |
|----------|-------|--------|
| Class-Action Effects (Layer C) | 12 | `shared/src/ui/atmospheric/class-effects/*.tsx` |
| House Transitions (Layer A) | 4 | `shared/src/ui/atmospheric/atmospheric-layer.tsx` |
| Ancestry Filter Loops (Layer B) | 6 | `shared/src/ui/atmospheric/ancestry-profiles.ts` |
| Card Animations | 4 | `shared/src/ui/cards/card-motion.ts` |
| Page-Level Animations | 5 | Frontend interactions (tabs, modal, stagger, combat) |

**How to use:** Open `workspace-docs/design/concepts/animations/index.md` in VS Code Markdown Preview or any viewer supporting `<video>` tags.

**Regenerate:**
```bash
# Full set (idempotent — skips existing):
node scripts/fal-generate-video.mjs --all

# Retry failures:
node scripts/fal-generate-video.mjs --retry
```

---

## Related skills + rules

- `.claude/skills/design-briefing/SKILL.md` — per-story brief format
- `<repo>/.claude/rules/design-tokens.md` — repo-local token reference (will be consolidated into shared/config in Phase 3)
- `<repo>/.claude/rules/fsd-architecture.md` — where components live by layer
- `.claude/rules/workflow-defaults.md` — picker-always-visible rule (§4), reduced-motion implicit
