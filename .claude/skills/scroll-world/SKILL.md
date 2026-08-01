---
name: scroll-world
description: Baut eine scroll-gescrubbte "Flug durch die Welt"-Landingpage, bei der die Kamera beim Scrollen OHNE Schnitt von Szene zu Szene durch eine zusammenhängende, KI-gerenderte Welt fliegt (isometrische Diorama-Welt oder frei gewählte Art-Direction). Interviewt den Nutzer zu Thema, Story-Beats und Brand-Kit, generiert kohärente Szenen-Stills und nahtlose Kamera-Clips über fal.ai mit First-/Last-Frame-Locking und verdrahtet eine portable, framework-agnostische Scroll-Scrub-Engine. Nutze, wenn ein "3D-Welt"- oder "durch-die-Branche-fliegen"-Hero, ein Scroll-Cinematic, eine Diorama-Landingpage oder das Verwandeln eines Business in eine scrollbare Welt gewünscht ist.
---

# Scroll-World

Interaktive Landingpage, bei der das Scrollen eine Kamera kontinuierlich durch vorgerenderte, KI-generierte Szenen treibt: Die Kamera taucht in das Innere jeder Szene und fliegt dann nahtlos (ohne sichtbaren Schnitt) zur nächsten. fal.ai generiert Szenen-Stills und Video-Clips; die Engine spielt sie ab, indem sie `video.currentTime` an die Scroll-Position bindet.

**Kern-Output:** N Szenen-Stills → N Dive-/Leg-Clips → (N−1) Connector-Clips → eine self-contained JS-Scrub-Engine, die die ganze Kette orchestriert.

**Kern-Prinzip:** Nahtstellen (Seams) müssen frame-identisch sein. Connectors und Legs übergeben **echte gerenderte Frames**, niemals die Original-Stills — sonst sichtbarer Pop. Auf fal.ai heißt das: der letzte gerenderte Frame eines Clips wird als Startframe (`first_frame_url` / `start_image_url`) des nächsten gesetzt, der erste Frame des Folge-Clips als dessen Endframe (`last_frame_url` / `end_image_url`).

## Provider

- **fal.ai ist der Standard.** Auth über die Env-Var `FAL_KEY` (kein CLI-Login, kein Workspace-Konzept). Aufruf per `@fal-ai/client` (`fal.subscribe(...)`) oder über den Queue-HTTP-Weg (`Authorization: Key $FAL_KEY`).
- **Higgsfield optional per MCP.** Der ursprüngliche Higgsfield-CLI-Weg lässt sich additiv über den Higgsfield-MCP-Server (`https://mcp.higgsfield.ai/mcp`) nachrüsten — **hier bewusst nicht implementiert, nur als Option benannt**. Standardpfad bleibt fal.ai.
- **Kosten-Größenordnung:** grob **~$10–25 pro Seite** auf fal.ai (abhängig von Tier, Clip-Anzahl, Auflösung, Mobile-Kette). Deterministisch aus dem publizierten Preis rechenbar (siehe Asset-Generierung). fal ändert Preise/Tiers häufig → vor Produktionsintegration erneut live prüfen.

## Voraussetzungen

Vor jeder Generierung sicherstellen (Windows: alles in Git-Bash mit bash-3.2-Kompatibilität, Tools im `PATH`):

- **`FAL_KEY`** gesetzt; **`@fal-ai/client`** (npm) **oder** `curl` für den Queue-HTTP-Weg.
- **ffmpeg / ffprobe** — Frame-Extraktion und Encode; `ffprobe` liefert die native Auflösung ("encode what ffprobe reports, never upscale").
- **jq** — Result-URL aus dem JSON-Ergebnis parsen; **curl** — Clip-/Bild-URLs (`-fsSL`) laden und Queue-Jobs submitten/pollen.
- **cwebp** (libwebp) — PNG→WebP mit Alpha für Float-Szenen; **sips** (macOS, optional) als Alternative.
- **Python 3 + Pillow/PIL** — `knockout.py` (Border-Flood-Fill + GaussianBlur) und `python -m http.server` zum Servieren.
- **bash (3.2-safe!)** — alle Pipeline-Skripte; **keine** associative arrays; Array-getriebene Kettenschritte als `#!/bin/bash`-Datei via `bash script.sh` laufen lassen, **nie** inline in zsh (1- vs. 0-indexed).
- **Codex CLI** (optional, ≥0.125) — Stills-Alternative via eingebautem `image_gen` (ChatGPT-Abo statt Credits).
- **Headless-Browser** — Seam-QA (Step 8); Coreutils (`mkdir`, `cat`, `wc`, `cut`, `du`).

**Windows-Hinweis:** Git-Bash stellt die bash-3.2-kompatible Shell; `jq`, `cwebp`, `ffmpeg`, `ffprobe` müssen im `PATH` liegen. Die Regel "Kettenschritte als `#!/bin/bash`-Skript" gilt auch hier.

## Ablauf (Steps 0–8)

**Step 0 — Bootstrap.** `FAL_KEY` prüfen; ffmpeg/ffprobe/jq/curl vorhanden. Generierungen dauern 3–8 min → immer detached starten und pollen, nie blockierend. Ob ein Endpoint Start-/Endframe akzeptiert, per OpenAPI-Route verifizieren (siehe Asset-Generierung), nicht raten.

**Step 1 — Interview.** Thema/Pitch/Brand-Name; Brand-Kit (Nutzer liefert Palette+Name+Tone, oder du schlägst 4–6 benannte Hex-Werte vor, oder du liest sie aus der Website — fal hat **kein** Brand-Kit-Feature, also manuell); Art-Direction (Default: "soft matte low-poly clay diorama, isometric, tilt-shift miniature, warm light" → wird als Style-Preamble **verbatim** in jeden Szenen-Prompt übernommen); Journey aus 5–7 Sektionen entlang der Wertschöpfungskette (letzte = Hero-Produkt + CTA); Mobile ja/nein (`AskUserQuestion`); Budget/Tier (`AskUserQuestion`). Nie stillschweigend einen Center-Crop als Mobile-Version ausliefern. Intake-Checkliste + alle Prompt-Templates: `references/prompts.md`.

**Step 2 — Szenen-Stills.** Ein Bild pro Sektion, alle mit **identischer** Style-Preamble (Kohäsion: gleicher Winkel, Palette, Licht). Erzeugung via fal.ai-Text-to-Image **oder** Codex `image_gen` (siehe Asset-Generierung). Fehlgeschlagene/stil-fremde Stills einzeln neu würfeln; alle zusammen prüfen, bevor es weitergeht. Diese Stills dienen doppelt als Video-Poster/Lazy-Load-Fallback — immer behalten.

**Step 3 — (Optional) Szenen freistellen.** Flachen Hintergrund mit `references/knockout.py` (Border-Flood-Fill) auf Transparenz knocken und nach WebP encoden, falls die Dioramen über einem Atmosphären-Hintergrund schweben sollen. Sonst Seiten-Hintergrund an den Szenen-Hintergrund angleichen und überspringen.

**Step 4 — Kamera-Architektur (eine wählen — größter Qualitätshebel).**
- **Architektur A — Continuous Forward Take** (empfohlen für grounded/realistisch/Walkthrough): eine Kamera gleitet **nur vorwärts** als ein Take. Legs **sequentiell**; jeder Leg-Startframe = **echter letzter Frame** des Vorgänger-Legs (per ffmpeg extrahiert), **kein Endframe** (ein Endframe erzwingt einen Pull-back — Hauptursache für Stutter). **Keine Connectors** (Step 5 entfällt), Legs mit `connectors: []` und kleinem `crossfade` (~0.08) verdrahten.
- **Architektur B — Dive-in + Aerial Connector** (nur Diorama/Miniatur/Vogelperspektive): Dive-Clip pro Szene + Connector, der hoch/heraus zieht und zur nächsten Szene fliegt. Der Pull-out **kehrt die Kamerarichtung an jeder Nahtstelle um** — in einer Miniatur-Welt gewollt, in grounded First-Person wirkt es als Rewind/Stutter. Im Zweifel A.
- **Kamera-Grammatik (beide):** Innerhalb eines Legs darf die Kamera frei orbiten/kranen/tracken — nur Seams brauchen Positions-/Geschwindigkeitskontinuität. Letzte ~1 s jedes Legs = langsamer, stetiger Vorwärts-Drift; jeder Leg-Start setzt diesen Drift fort (beide Klauseln **verbatim** im Prompt). Motion-Palette je Konzept: `references/prompts.md`.

**Step 5 — Connectors (nur Architektur B).** Ein Connector fliegt vom Ende von Szene *i* in den Start von Szene *i+1*. **Beide Endpunkte sind ECHTE gerenderte Frames der Nachbar-Clips, nie die Original-Stills.** Frame-Extraktion per ffmpeg: `-sseof -0.15 … -frames:v 1` holt den letzten Interior-Frame von `dive_i`, `-ss 0 … -frames:v 1` den Opening-Frame von `dive_next` (volle Zeilen in `references/pipeline.md`). Diese zwei Frames werden zum Start-/Endframe des Connectors (siehe Asset-Generierung). Die Engine legt zusätzlich einen kurzen Crossfade über jeden Seam — aber **nie** den echten Frame-Handoff überspringen und allein auf den Crossfade bauen.

**Step 6 — Encode fürs Scrubbing.** Zwei Praktiken: (1) **Seekability** treibt die Glätte, nicht Keyframe-Dichte — viele Hosts liefern keine HTTP-Byte-Ranges → `video.seekable` = `[0,0]` → eingefroren; Fix: jeden Clip als **Blob** aus einem In-Memory-Object-URL abspielen (die Engine macht das) → **kein** All-Intra nötig. (2) Encode-Rezept: native Auflösung, `-an`, `-crf 20`, kleines GOP (`-g 8 -keyint_min 8 -sc_threshold 0`), `+faststart`, leichtes `unsharp`; alle 2N−1 Clips identisch (volle ffmpeg-Zeile in `references/pipeline.md`). Mobile (nur bei Opt-in): native 9:16-Portrait-Kette, `scale=720:-2`, `-g 4`, crf 23 → `clipMobile`/`connectorsMobile`; nie stumm einen Crop ausliefern.

**Step 7 — Seite zusammenbauen.** `references/scrub-engine.js` (+ optional `references/index-template.html`) ins Projekt kopieren/adaptieren — config-getrieben, self-contained (baut DOM + injiziert CSS, kein externes Framework). Config: `sections[]` (je `id`, `still`, `clip`, optional `clipMobile`/`stillMobile`, `scroll`/`linger`-Pacing, `accent`, Copy, `tags`), `connectors[]` (Länge = sections−1), Brand. Theming über `--sw-bg`/`--sw-ink`/`--sw-accent`/`--sw-font-*` (Engine kapselt Defaults in `@layer sw`, Page-`:root` gewinnt ohne Specificity-Hacks). Volle Config + CSS-Variablen: Header von `scrub-engine.js`.

**Step 8 — QA der Seams (nicht überspringen).** Seite im Headless-Browser fahren. **Desktop:** Screenshot direkt vor/nach jedem Seam — die zwei Frames müssen nahezu identisch sein (Dive-Endframe ≈ Connector-Startframe); poppt es, wurde ein Still statt des echten Frames genutzt (Step 5 wiederholen). Console prüfen, `video.seekable.end(0) > 0` bestätigen. **Mobile** (nur bei Opt-in): CPU 4–6× drosseln und schnell scrollen (kein Freeze); erste Szene lädt sofort (Poster→Video, iOS-Safari testen); `-m.mp4` wird ausgeliefert und ist **nativ portrait** (`videoWidth < videoHeight`); URL-Bar-Kollaps darf keinen Sprung auslösen; `prefers-reduced-motion` → Stills, kein Video.

## Asset-Generierung über fal.ai

Dies ist die Provider-Schicht: Higgsfield-CLI-Aufrufe des Upstreams sind durch die kanonischen fal.ai-Endpoints ersetzt. **Frame-Locking ist der Kern** — die folgende Tabelle sagt, welches Feld welchen Frame setzt (Feldnamen live aus der rohen OpenAPI, Stand 2026-07-23):

| fal.ai-Endpoint | Startframe-Feld | Endframe-Feld | End-Constraint |
|---|---|---|---|
| `fal-ai/veo3.1/first-last-frame-to-video` | `first_frame_url` | `last_frame_url` | native FLF (beide Kern-Contract) |
| `fal-ai/veo3.1/fast/first-last-frame-to-video` | `first_frame_url` | `last_frame_url` | native FLF |
| `fal-ai/veo3.1/lite/first-last-frame-to-video` | `first_frame_url` | `last_frame_url` | native FLF; **fix 8s**, kein 4k |
| `fal-ai/kling-video/o1/image-to-video` | `start_image_url` (req) | `end_image_url` (optional) | **weich** — für Connectors explizit setzen |
| `fal-ai/kling-video/v3/pro/image-to-video` | `start_image_url` (req) | `end_image_url` (optional) | **weich** — für Connectors explizit setzen |
| `fal-ai/wan-flf2v` | `start_image_url` | `end_image_url` | native FLF; frame-basiert, max 720p |

**Zuordnung Clip-Typ → Endpoint:**

- **Dive-/Leg-Clip (nur Startframe, Ende frei)** — Startframe = Szenen-Still (Arch B) bzw. extrahierter letzter Frame des Vorgänger-Legs (Arch A). Endpoint mit **optionalem** Ende: `fal-ai/kling-video/v3/pro/image-to-video` oder `.../o1/image-to-video` — `start_image_url` setzen, `end_image_url` **weglassen** (Kamera läuft frei vorwärts). Ersetzt Upstream `gen_dive` (`--start-image`).
- **Connector-Clip (beide Frames hart)** — `first_frame_url`/`start_image_url` = `dive_i_last.png`, `last_frame_url`/`end_image_url` = `dive_next_first.png`. Default: `fal-ai/veo3.1/fast/first-last-frame-to-video` mit `generate_audio: false` (stumm → ~50% günstiger). Ersetzt Upstream `gen_conn` (`--start-image` + `--end-image`).

**Tier-Wahl für Connectors:** günstig `fal-ai/veo3.1/lite/...` ($0.03/s 720p ohne Audio, aber **fix 8s**, kein 4k) · Standard `fal-ai/veo3.1/fast/...` ($0.10/s 1080p ohne Audio) · Qualität `fal-ai/veo3.1/first-last-frame-to-video` (bis 4k) · günstigster Kurz-Loop `fal-ai/wan-flf2v` ($0.20–0.40 pro Video, frame-basiert via `num_frames` 81–100 / `frames_per_second`, max 720p).

**Ein Modell pro Kette (Seam-Regel des Upstreams):** Jedes Modell hat eigenen Motion-/Color-/Grain-Charakter — ein Modellwechsel mitten in der Kette poppt trotz frame-gematchter Endpunkte. **Seam-sicherster Weg:** die gesamte Kette auf **einem** kling-Endpoint (o1 **oder** v3 pro) fahren — Dives ohne `end_image_url`, Connectors mit explizit gesetztem `end_image_url`. Die veo3.1-/wan-FLF-Endpoints liefern den **härtesten** End-Lock für Connectors; nutzt du sie gegen kling-Dives, halte den Familienwechsel hinter dem Engine-Crossfade verborgen (die einzige sanktionierte Ausnahme, wie beim NSFW-Re-Roll).

**Duration/Auflösung/Audio (fal-Input-Params, ersetzen Higgsfields `--mode`/`--resolution`/`--sound`/`--duration`):** veo3.1 → `duration` enum `'4s'|'6s'|'8s'` (lite: const `'8s'`), `resolution` `'720p'|'1080p'|'4k'` (lite ohne 4k), `aspect_ratio` `'auto'|'16:9'|'9:16'`, `generate_audio` bool (Default true → für stumme Flüge **false** setzen). kling → `duration` als String (o1 `'3'..'10'`, v3 pro `'3'..'15'`, Default `'5'`), `prompt` required. wan → **kein** `duration`, stattdessen `num_frames`/`frames_per_second`, `resolution` `'480p'|'720p'`.

**Aufruf per `@fal-ai/client`** (Connector-Beispiel):
```js
import { fal } from '@fal-ai/client';
fal.config({ credentials: process.env.FAL_KEY });
const result = await fal.subscribe('fal-ai/veo3.1/fast/first-last-frame-to-video', {
  input: {
    first_frame_url: diveLastUrl,   // Startframe = letzter Frame von dive_i
    last_frame_url:  diveNextUrl,   // Endframe   = erster Frame von dive_{i+1}
    duration: '8s',                 // '4s' | '6s' | '8s'
    resolution: '1080p',            // '720p' | '1080p' | '4k'
    generate_audio: false,          // stumm -> ~50% guenstiger
  },
});
// result.data traegt die Clip-URL -> mit curl -fsSL herunterladen
```

**Aufruf per Queue-HTTP** (Dive-Beispiel, nur Startframe):
```bash
curl -s -X POST https://queue.fal.run/fal-ai/kling-video/v3/pro/image-to-video \
  -H "Authorization: Key $FAL_KEY" -H "Content-Type: application/json" \
  -d '{"start_image_url":"'"$START_URL"'","prompt":"'"$(cat leg_i.txt)"'","duration":"5"}'
# Antwort traegt request_id + status_url + response_url;
# status_url pollen bis COMPLETED, dann response_url GETten und die Clip-URL per jq extrahieren.
```

**Stills (Step 2).** fal-Text-to-Image erzeugt die Szenen-Bilder; das gehostete Still wird zum `first_frame_url`/`start_image_url` der FLF-Videostufe. Der hier verifizierte Endpoint-Satz deckt **nur die Video-FLF-Endpoints** ab — den konkreten fal-Bildmodell-`endpoint_id` live gegen `fal.ai/models` bestätigen (Preise/Roster driften), **nicht** raten. Zero-Credit-Alternative: Codex CLI (`codex exec ... $imagegen ... Save it as ./still_i.png`), 3:2, ~1–3 min/Bild. Eine einzige Stills-Quelle für alle N Szenen (Mischen liest sich als Stil-Drift).

**Endpoint-Fähigkeit verifizieren** (ersetzt Higgsfield `model get`): `GET https://fal.ai/api/openapi/queue/openapi.json?endpoint_id=<id>` → Input-Schema lesen (welche Frame-Felder der Endpoint akzeptiert). **Kosten** sind deterministisch aus dem publizierten Preis (Preis/s × Dauer × Clip-Zahl bzw. Preis/Video) — kein Balance-Diff wie bei Higgsfields `workspace list`. Beispiel: 9 Connectors à 8 s auf `veo3.1/fast` 1080p ohne Audio = 9 × 8 × $0.10 = $7.20, plus Dives/Stills/Mobile → ~$10–25/Seite.

## Gotchas (hart erkauft)

- **Seam-Pop** → Connector-Endpunkte waren die Stills statt echter Nachbar-Frames. Immer echte Frames extrahieren (Step 5).
- **Seam-Stutter / "Kamera springt rückwärts"** → Geschwindigkeit kehrt sich um (Forward-Dive → Pull-back-Connector). Inhärent für Architektur B; für grounded Walkthrough Architektur A (nur Vorwärts-Legs, kein Endframe).
- **Eingefrorenes Video / Frame 0** → `seekable=[0,0]`, Host liefert keine Byte-Ranges (kein All-Intra hilft). Blob-URLs nutzen (Engine tut das).
- **Phone-Scrub ruckelt** → 1080p-Master zu schwer fürs Phone-Decoder. `-m.mp4` (720p, `-g 4`) + `clipMobile`/`connectorsMobile`; Engine coalesced Seeks bereits.
- **Schwarze Szene auf iOS** → gemutetes, nie abgespieltes Video malt keinen geseekten Frame. Engine hält das Still als Poster bis der Clip malt und primet jedes Video beim ersten Touch — beim Adaptieren `playsinline`/`muted` **nicht** strippen.

Provider-spezifische Fallen (Ein-Modell-pro-Kette, `generate_audio: false`, `wan-flf2v` frame-basiert) stehen in **Asset-Generierung**; die bash-3.2-/zsh-Falle in **Voraussetzungen**.

## References

Tiefe liegt in den Begleitdateien (von anderen Writern angelegt):

| Datei | Zweck |
|---|---|
| `references/prompts.md` | Intake-Checkliste, Style-Preamble-Muster, alle Prompt-Templates (Szenen-Still, Dive, Connector) mit Füll-Slots. |
| `references/pipeline.md` | Copy-paste-Batch-Skripte für den ganzen Lauf (generate → Frames extrahieren → Connectors → encode → Mobile), bash-3.2-safe, auf die fal.ai-Endpoints gemünzt. |
| `references/scrub-engine.js` | Portable, config-getriebene Scrub-Engine: Blob-Seek, Lazy-Load, Seam-Crossfade, Copy, Route-Rail, `prefers-reduced-motion`, Phone-Hardening. |
| `references/index-template.html` | Minimale Standalone-Seite, die die Engine mountet. |
| `references/knockout.py` | Border-connected Background-Knockout für schwebende Szenen (PIL). |
