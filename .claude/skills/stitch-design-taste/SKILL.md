---
name: stitch-design-taste
description: Semantic Design System Skill for Google Stitch. Generates agent-friendly DESIGN.md files that enforce premium, anti-generic UI standards — strict typography, calibrated color, asymmetric layouts, perpetual micro-motion, and hardware-accelerated performance.
---

# Stitch Design Taste — Semantic Design System Skill

## Overview

This skill generates `DESIGN.md` files optimized for Google Stitch screen generation. It translates the battle-tested anti-slop frontend engineering directives into Stitch's native semantic design language — descriptive, natural-language rules paired with precise values that Stitch's AI agent can interpret to produce premium, non-generic interfaces.

The generated `DESIGN.md` serves as the **single source of truth** for prompting Stitch to generate new screens that align with a curated, high-agency design language. Stitch interprets design through **"Visual Descriptions"** supported by specific color values, typography specs, and component behaviors.

## Prerequisites — how Stitch reaches the agent

There are two paths, and only the second one needs wiring:

- **Web UI — no setup at all.** Open [labs.google.com/stitch](https://labs.google.com/stitch) and paste the generated `DESIGN.md` in. This skill's product IS that file, so this path is complete on its own; everything below is optional.
- **MCP proxy — the agent talks to Stitch directly.** This needs the `stitch` MCP server. In agent-core it is deliberately **not** in the default set: it is defined once in `shared/mcp/servers.json` and tagged for the **opt-in profile `stitch`** (`shared/profiles.json`), so it materializes only under `agent-core sync --profile stitch`. A bare sync leaves it out on purpose — the server is useless before the one-time interactive setup below, and on Claude a server that once shipped cannot be withdrawn by a later sync (the strike list knows top-level keys only, never `mcpServers.<name>`).

### The package — and the name that does not exist

- **`@_davideast/stitch-mcp`**, latest **0.9.0**, `bin: stitch-mcp`. Self-verified 2026-08-05: `npm view @_davideast/stitch-mcp version` → `0.9.0`, `time.modified` → `2026-05-28`, so an unpinned `npx` resolves to 0.9.0. Every version-specific claim below was read out of that exact tarball; re-check them before trusting them against a newer release.
- **`@google/stitch-mcp` does not exist.** Self-verified 2026-08-05: `npm view @google/stitch-mcp version` → `npm error code E404`. Several blog write-ups name it. It is not a Google package, and no amount of retrying will install it.
- **This is a third-party, experimental tool** — its own README carries a warning block: *"NOT affiliated with, endorsed by, or sponsored by Google LLC"*, *"NOT guaranteed to be maintained, secure, or compatible with future API versions"*, Apache-2.0 © David East. That is the reason for the opt-in profile, not just the interactive setup.
- Clients its README lists: VS Code, Cursor, **Claude Code**, Gemini CLI, Codex, **OpenCode** — both agent-core targets, which is why the server lives in the shared bucket rather than under one target.

### One-time setup — a HUMAN step, not an agent step

1. `npx -y @_davideast/stitch-mcp init` — a wizard: it resolves gcloud, then does Google-Cloud OAuth in a browser. No API key needed. One is possible, though, and it is the only non-interactive path: `STITCH_API_KEY` skips OAuth entirely (README, "Authentication"). Because it is optional rather than required, `env` stays empty in `servers.json`.
2. **Restart the session.** A server registered while a session runs does not load its tools into it.
3. `npx -y @_davideast/stitch-mcp doctor` — the package's own health check. Run it instead of guessing why the tools are missing.

An agent cannot do step 1: it needs a browser and, on Windows, a UAC prompt. Hand the command to a human and stop. Do not retry — fail loud rather than loop silently (`30-quality`).

### The Windows gcloud trap — the error names the wrong cause

`init` on a machine without a usable gcloud fails with these two strings (both verified present in v0.9.0's `dist/chunk-7ryqstaa.js`; the surrounding step label is from the observed run):

```text
Failed to install gcloud locally
suggestion: "Check your internet connection and try again"
```

**The suggestion is wrong.** Read out of that bundle's `GcloudInstallService.ensureInstalled`, the resolution order is: system gcloud on `PATH` (`where gcloud.cmd`) → the bundled SDK at `~/.stitch-mcp/google-cloud-sdk/bin/gcloud.cmd` → system gcloud once more → download `https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-windows-x86_64-bundled-python.zip`. Only that last step yields `DOWNLOAD_FAILED`, and on Windows it fails while the same host `dl.google.com` serves `winget` an installer moments later, hash verified. The network is not the problem; that download path is.

- **The fix is the FIRST step, not the last** — install a system gcloud and `init` never reaches the broken download. Note the order: system-first, so one install short-circuits the whole chain.
- **Mind the version floor.** A system gcloud is only accepted at **>= 400.0.0** (`minVersion: "400.0.0"` in the same bundle). An older one is skipped in silence and you land back on the broken download, with the same misleading message.
- **`--source winget` is not optional** when the `msstore` source breaks with `0x8a15005e` ("Serverzertifikat stimmte mit keinem der erwarteten Werte überein"); without the restriction winget refuses with "Geben Sie eine Option für --source an".
- **No winget?** `GoogleCloudSDKInstaller.exe` from `https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe` — "Install for single user" needs no admin rights.
- **Already have a gcloud you want it to use?** Set `STITCH_USE_SYSTEM_GCLOUD=1` for the proxy; the README documents that as the supported way to use an existing installation instead of the isolated one.

```powershell
winget install Google.CloudSDK --source winget   # interactive terminal, confirm the UAC prompt
npx -y @_davideast/stitch-mcp init               # same window, so the PATH is fresh
```

### What the proxy hands over

Alongside the upstream Stitch tools the proxy exposes three virtual tools (names verified in the v0.9.0 bundle). The last two are the actual handover point into the code workflow — screenshot plus HTML, per screen:

- `build_site` — builds a site from a project by mapping screens to routes; returns each page's design HTML.
- `get_screen_code` — retrieves a screen and downloads its HTML code content.
- `get_screen_image` — retrieves a screen and downloads its screenshot image as base64.

## The Goal

Generate a `DESIGN.md` file that encodes:

1. **Visual atmosphere** — the mood, density, and design philosophy
2. **Color calibration** — neutrals, accents, and banned patterns with hex codes
3. **Typographic architecture** — font stacks, scale hierarchy, and anti-patterns
4. **Component behaviors** — buttons, cards, inputs with interaction states
5. **Layout principles** — grid systems, spacing philosophy, responsive strategy
6. **Motion philosophy** — animation engine specs, spring physics, perpetual micro-interactions
7. **Anti-patterns** — explicit list of banned AI design clichés

## Analysis & Synthesis Instructions

### 1. Define the Atmosphere

Evaluate the target project's intent. Use evocative adjectives from the taste spectrum:

- **Density:** "Art Gallery Airy" (1–3) → "Daily App Balanced" (4–7) → "Cockpit Dense" (8–10)
- **Variance:** "Predictable Symmetric" (1–3) → "Offset Asymmetric" (4–7) → "Artsy Chaotic" (8–10)
- **Motion:** "Static Restrained" (1–3) → "Fluid CSS" (4–7) → "Cinematic Choreography" (8–10)

Default baseline: Variance 8, Motion 6, Density 4. Adapt dynamically based on user's vibe description.

### 2. Map the Color Palette

For each color provide: **Descriptive Name** + **Hex Code** + **Functional Role**.

**Mandatory constraints:**

- Maximum 1 accent color. Saturation below 80%
- The "AI Purple/Blue Neon" aesthetic is strictly BANNED — no purple button glows, no neon gradients
- Use absolute neutral bases (Zinc/Slate) with high-contrast singular accents
- Stick to one palette for the entire output — no warm/cool gray fluctuation
- Never use pure black (`#000000`) — use Off-Black, Zinc-950, or Charcoal

### 3. Establish Typography Rules

- **Display/Headlines:** Track-tight, controlled scale. Not screaming. Hierarchy through weight and color, not just massive size
- **Body:** Relaxed leading, max 65 characters per line
- **Font Selection:** `Inter` is BANNED for premium/creative contexts. Force unique character: `Geist`, `Outfit`, `Cabinet Grotesk`, or `Satoshi`
- **Serif Ban:** Generic serif fonts (`Times New Roman`, `Georgia`, `Garamond`, `Palatino`) are BANNED. If serif is needed for editorial/creative contexts, use only distinctive modern serifs: `Fraunces`, `Gambarino`, `Editorial New`, or `Instrument Serif`. Serif is always BANNED in dashboards or software UIs — unless a binding project design brief says otherwise; see the precedence note in step 9
- **Dashboard Constraint:** Use Sans-Serif pairings exclusively (`Geist` + `Geist Mono` or `Satoshi` + `JetBrains Mono`)
- **High-Density Override:** When density exceeds 7, all numbers must use Monospace

### 4. Define the Hero Section

The Hero is the first impression and must be creative, striking, and never generic:

- **Inline Image Typography:** Embed small, contextual photos or visuals directly between words or letters in the headline. Images sit inline at type-height, rounded, acting as visual punctuation. This is the signature creative technique
- **No Overlapping:** Text must never overlap images or other text. Every element occupies its own clean spatial zone
- **No Filler Text:** "Scroll to explore", "Swipe down", scroll arrow icons, bouncing chevrons are BANNED. The content should pull users in naturally
- **Asymmetric Structure:** Centered Hero layouts BANNED when variance exceeds 4
- **CTA Restraint:** Maximum one primary CTA. No secondary "Learn more" links

### 5. Describe Component Stylings

For each component type, describe shape, color, shadow depth, and interaction behavior:

- **Buttons:** Tactile push feedback on active state. No neon outer glows. No custom mouse cursors
- **Cards:** Use ONLY when elevation communicates hierarchy. Tint shadows to background hue. For high-density layouts, replace cards with border-top dividers or negative space
- **Inputs/Forms:** Label above input, helper text optional, error text below. Standard gap spacing
- **Loading States:** Skeletal loaders matching layout dimensions — no generic circular spinners
- **Empty States:** Composed compositions indicating how to populate data
- **Error States:** Clear, inline error reporting

### 6. Define Layout Principles

- No overlapping elements — every element occupies its own clear spatial zone. No absolute-positioned content stacking
- Centered Hero sections are BANNED when variance exceeds 4 — force Split Screen, Left-Aligned, or Asymmetric Whitespace
- The generic "3 equal cards horizontally" feature row is BANNED — use 2-column Zig-Zag, asymmetric grid, or horizontal scroll
- CSS Grid over Flexbox math — never use `calc()` percentage hacks
- Contain layouts using max-width constraints (e.g., 1400px centered)
- Full-height sections must use `min-h-[100dvh]` — never `h-screen` (iOS Safari catastrophic jump)

### 7. Define Responsive Rules

Every design must work across all viewports:

- **Mobile-First Collapse (< 768px):** All multi-column layouts collapse to single column. No exceptions
- **No Horizontal Scroll:** Horizontal overflow on mobile is a critical failure
- **Typography Scaling:** Headlines scale via `clamp()`. Body text minimum `1rem`/`14px`
- **Touch Targets:** All interactive elements minimum `44px` tap target
- **Image Behavior:** Inline typography images (photos between words) stack below headline on mobile
- **Navigation:** Desktop horizontal nav collapses to clean mobile menu
- **Spacing:** Vertical section gaps reduce proportionally (`clamp(3rem, 8vw, 6rem)`)

### 8. Encode Motion Philosophy

- **Spring Physics default:** `stiffness: 100, damping: 20` — premium, weighty feel. No linear easing
- **Perpetual Micro-Interactions:** Every active component should have an infinite loop state (Pulse, Typewriter, Float, Shimmer)
- **Staggered Orchestration:** Never mount lists instantly — use cascade delays for waterfall reveals
- **Performance:** Animate exclusively via `transform` and `opacity`. Never animate `top`, `left`, `width`, `height`. Grain/noise filters on fixed pseudo-elements only

### 9. List Anti-Patterns (AI Tells)

Encode these as explicit "NEVER DO" rules in the DESIGN.md:

**Precedence.** A binding, project-owned design brief beats these defaults — a brand design language is a requirement, not a taste question, and the serif ban is where the two collide most often. When the brief wins, write the deviation into the `DESIGN.md` explicitly (which ban, and on whose authority) instead of passing over it in silence. Everything the brief does not address stays banned.

- No emojis anywhere
- No `Inter` font
- No generic serif fonts (`Times New Roman`, `Georgia`, `Garamond`) — distinctive modern serifs only if needed
- No pure black (`#000000`)
- No neon/outer glow shadows
- No oversaturated accents
- No excessive gradient text on large headers
- No custom mouse cursors
- No overlapping elements — clean spatial separation always
- No 3-column equal card layouts
- No generic names ("John Doe", "Acme", "Nexus")
- No fake round numbers (`99.99%`, `50%`)
- No AI copywriting clichés ("Elevate", "Seamless", "Unleash", "Next-Gen")
- No filler UI text: "Scroll to explore", "Swipe down", scroll arrows, bouncing chevrons
- No broken Unsplash links — use `picsum.photos` or SVG avatars
- No centered Hero sections (for high-variance projects)

## Output Format (DESIGN.md Structure)

```markdown
# Design System: [Project Title]

## 1. Visual Theme & Atmosphere

(Evocative description of the mood, density, variance, and motion intensity.
Example: "A restrained, gallery-airy interface with confident asymmetric layouts
and fluid spring-physics motion. The atmosphere is clinical yet warm — like a
well-lit architecture studio.")

## 2. Color Palette & Roles

- **Canvas White** (#F9FAFB) — Primary background surface
- **Pure Surface** (#FFFFFF) — Card and container fill
- **Charcoal Ink** (#18181B) — Primary text, Zinc-950 depth
- **Muted Steel** (#71717A) — Secondary text, descriptions, metadata
- **Whisper Border** (rgba(226,232,240,0.5)) — Card borders, 1px structural lines
- **[Accent Name]** (#XXXXXX) — Single accent for CTAs, active states, focus rings
  (Max 1 accent. Saturation < 80%. No purple/neon.)

## 3. Typography Rules

- **Display:** [Font Name] — Track-tight, controlled scale, weight-driven hierarchy
- **Body:** [Font Name] — Relaxed leading, 65ch max-width, neutral secondary color
- **Mono:** [Font Name] — For code, metadata, timestamps, high-density numbers
- **Banned:** Inter, generic system fonts for premium contexts. Serif fonts banned in dashboards.

## 4. Component Stylings

- **Buttons:** Flat, no outer glow. Tactile -1px translate on active. Accent fill for primary, ghost/outline for secondary.
- **Cards:** Generously rounded corners (2.5rem). Diffused whisper shadow. Used only when elevation serves hierarchy. High-density: replace with border-top dividers.
- **Inputs:** Label above, error below. Focus ring in accent color. No floating labels.
- **Loaders:** Skeletal shimmer matching exact layout dimensions. No circular spinners.
- **Empty States:** Composed, illustrated compositions — not just "No data" text.

## 5. Layout Principles

(Grid-first responsive architecture. Asymmetric splits for Hero sections.
Strict single-column collapse below 768px. Max-width containment.
No flexbox percentage math. Generous internal padding.)

## 6. Motion & Interaction

(Spring physics for all interactive elements. Staggered cascade reveals.
Perpetual micro-loops on active dashboard components. Hardware-accelerated
transforms only. Isolated Client Components for CPU-heavy animations.)

## 7. Anti-Patterns (Banned)

(Explicit list of forbidden patterns: no emojis, no Inter, no pure black,
no neon glows, no 3-column equal grids, no AI copywriting clichés,
no generic placeholder names, no broken image links.)
```

## Best Practices

- **Be Descriptive:** "Deep Charcoal Ink (#18181B)" — not just "dark text"
- **Be Functional:** Explain what each element is used for
- **Be Consistent:** Same terminology throughout the document
- **Be Precise:** Include exact hex codes, rem values, pixel values in parentheses
- **Be Opinionated:** This is not a neutral template — it enforces a specific, premium aesthetic

## Tips for Success

1. Start with the atmosphere — understand the vibe before detailing tokens
2. Look for patterns — identify consistent spacing, sizing, and styling
3. Think semantically — name colors by purpose, not just appearance
4. Consider hierarchy — document how visual weight communicates importance
5. Encode the bans — anti-patterns are as important as the rules themselves

## Common Pitfalls to Avoid

- Using technical jargon without translation ("rounded-xl" instead of "generously rounded corners")
- Omitting hex codes or using only descriptive names
- Forgetting functional roles of design elements
- Being too vague in atmosphere descriptions
- Ignoring the anti-pattern list — these are what make the output premium
- Defaulting to generic "safe" designs instead of enforcing the curated aesthetic
