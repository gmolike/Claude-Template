# Video-Skills Regel (HyperFrames)

## HyperFrames Suite (heygen-com/hyperframes)

Verantwortlich: Animation Designer Agent

### Kern-Skills

| Skill                   | Wann nutzen                                                            | Pflicht bei                      |
| ----------------------- | ---------------------------------------------------------------------- | -------------------------------- |
| `/hyperframes`          | Video-Kompositionen erstellen (Captions, TTS, Transitions)             | Jeder Video-Produktion           |
| `/hyperframes-cli`      | CLI Dev-Loop: init, lint, inspect, preview, render                     | Rendering und Debugging          |
| `/hyperframes-media`    | Asset-Preprocessing: TTS (Kokoro), Transcription (Whisper), BG-Removal | Voiceover, Untertitel            |
| `/hyperframes-registry` | Registry-Bloecke installieren und verdrahten                           | Wiederverwendbare Video-Patterns |

### Konvertierungs-Skills

| Skill                      | Wann nutzen                                  | Pflicht bei                            |
| -------------------------- | -------------------------------------------- | -------------------------------------- |
| `/website-to-hyperframes`  | Website zu Video konvertieren                | Marketing-Videos von bestehenden Sites |
| `/remotion-to-hyperframes` | Remotion-Projekte nach HyperFrames migrieren | Nur bei expliziter Migration           |
| `/contribute-catalog`      | Upstream-Beitraege zum HyperFrames Registry  | Community-Contributions                |

## Video-Workflow

1. `/hyperframes-cli` — Projekt scaffolden (`npx hyperframes init`)
2. `/hyperframes` — Komposition erstellen (HTML + CSS + GSAP Timeline)
3. `/hyperframes-media` — Assets vorbereiten (TTS, Transcription)
4. `/hyperframes-cli` — Lint und Preview pruefen
5. `/hyperframes-cli` — Finales Rendering (`npx hyperframes render`)

## HyperFrames-Prinzipien

- Kompositionen sind HTML-Dateien mit `data-*` Attributen — kein React, kein proprietaeres DSL
- Frame Adapter Pattern: GSAP, Lottie, CSS, Three.js, WAAPI, Anime.js
- Deterministic Rendering: gleicher Input = identischer Output
- AI-First: nicht-interaktive CLI, designed fuer Agent-Workflows
