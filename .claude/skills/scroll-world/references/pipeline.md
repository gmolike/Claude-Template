# Pipeline: copy-paste scripts (bash 3.2 safe)

Set these once. `NAMES` is the ordered section ids; the last is the hero/finale.
`FAL_KEY` authenticates every fal.ai call — export it before running (never hardcode it).

```bash
export FAL_KEY=...               # fal.ai API key (from the fal dashboard). Keep it in the env, not the script.
WORK=/tmp/scroll-world           # scratch dir for prompts, sources, frames
ASSETS=./assets                  # where the site reads stills (webp) + clips (mp4)
mkdir -p "$WORK" "$ASSETS/vid"
NAMES="farm kitchen shop delivery plaza finale"   # <-- your section ids, in order

# --- Chain video model: ONE endpoint for BOTH dives and connectors (cohesion) -------
# The chain model must render from a start frame ALONE (dive) AND from start+end
# (connector). On fal that is the Kling image-to-video family — end_image_url is
# OPTIONAL (verified: input required=[start_image_url]). veo3.1 FLF needs BOTH frames
# (verified: required=[prompt,first_frame_url,last_frame_url]), so it CANNOT render a
# single-start dive — it is a connector-only upgrade (CMODEL below), never the VMODEL.
VMODEL=fal-ai/kling-video/v3/pro/image-to-video    # default. Cheaper alt: fal-ai/kling-video/o1/image-to-video (flat $0.112/s)
DIVE_DUR="8"; CONN_DUR="5"                          # fal duration is a STRING enum: v3 pro "3".."15", o1 "3".."10"
VEXTRA='{"generate_audio":false}'                  # v3 pro silent tier ($0.112/s), discarded at the -an encode anyway.
                                                   #   o1 is flat-priced and has NO audio param → set VEXTRA='{}' for o1.
# Kling has no resolution/aspect param — the start frame's aspect + native res govern
# (encode what ffprobe reports, never upscale). Fields: start_image_url (req) + end_image_url (opt).

# --- Optional hard-seam connector upgrade (native FLF, BOTH frames REQUIRED) ---------
# veo3.1 FLF gives the tightest seam, but it is connector-only and a DIFFERENT model
# family than the kling dives — a family mix can show at a seam (a deliberate trade-off;
# call it out if you use it). Leave CMODEL empty to run connectors on VMODEL (default:
# one family, fully cohesive). generate_audio:false keeps the flight silent (~50% cheaper).
CMODEL=""                                           # e.g. (prices verbatim from fal.ai model pages, 2026-07-23; fal re-tiers often — re-check live):
#   fal-ai/veo3.1/first-last-frame-to-video          720p/1080p $0.20/s (audio off) $0.40 (on); 4k $0.40/$0.60; duration 4s/6s/8s
#   fal-ai/veo3.1/fast/first-last-frame-to-video     720p/1080p $0.10/s off $0.15 on; 4k $0.30/$0.35 — cheaper tier
#   fal-ai/veo3.1/lite/first-last-frame-to-video     $0.03/s 720p off — FIXED 8s, no 4k, cheapest FLF
#   fal-ai/wan-flf2v                                 $0.20/video 480p, $0.40 720p — frame-based, max 720p
# veo3.1 fields: first_frame_url/last_frame_url, duration "4s"|"6s"|"8s", resolution
# "720p"|"1080p"|"4k", aspect_ratio "auto"|"16:9"|"9:16", generate_audio. wan-flf2v fields:
# start_image_url/end_image_url, NO duration → num_frames(81-100)+frames_per_second(5-24),
# resolution "480p"|"720p" (see the wan note under §4).

# --- Local frame → fal image input (data URI; no separate upload) --------------------
# fal image fields take an https URL OR a base64 data URI; this inlines the local PNG.
# If a body is rejected for size, upload the frame to fal storage (via the fal SDK) or
# put it on any public HTTPS URL and pass that URL instead. base64|tr is GNU+BSD portable.
img_datauri() { printf 'data:image/png;base64,%s' "$(base64 < "$1" | tr -d '\n')"; }

# --- fal.ai queue runner (replaces `higgsfield ... --wait`) --------------------------
# Submit a job, poll the queue to COMPLETED, download the result URL.
#   fal_run <endpoint_id> <body.json> <jq-path-to-url> <out-file>
fal_run() { # endpoint body jsonpath outfile
  local ep="$1" body="$2" jp="$3" out="$4" sub status_url resp_url st url
  sub=$(curl -fsS -X POST "https://queue.fal.run/$ep" \
    -H "Authorization: Key $FAL_KEY" -H "Content-Type: application/json" \
    --data-binary @"$body") || { echo "submit FAIL $ep"; return 1; }
  status_url=$(printf '%s' "$sub" | jq -r '.status_url // empty')
  resp_url=$(printf '%s'  "$sub" | jq -r '.response_url // empty')
  [ -n "$status_url" ] || { echo "no status_url: $sub"; return 1; }
  while :; do                                        # fal jobs take minutes — background the whole script
    st=$(curl -fsS "$status_url" -H "Authorization: Key $FAL_KEY" | jq -r '.status // "ERROR"')
    case "$st" in
      COMPLETED)            break ;;
      IN_QUEUE|IN_PROGRESS) sleep 10 ;;
      *)                    echo "status=$st ($ep)"; return 1 ;;
    esac
  done
  url=$(curl -fsS "$resp_url" -H "Authorization: Key $FAL_KEY" | jq -r "$jp // empty")
  [ -n "$url" ] && curl -fsSL "$url" -o "$out" || { echo "no result url $jp ($ep)"; return 1; }
}
```

fal jobs take minutes — every `fal_run` below polls the queue and is meant to run inside
a **backgrounded** script. Launch the whole script with your tool's background/detached
mode and poll the progress log; never block the foreground.

## Qualitäts-Rezept — die live-verifizierte Modell-Kette (empfohlen)

Dies ist die in einem **echten Produktionslauf verifizierte** Kette und der eigentliche
Qualitätshebel. Sie ersetzt die generischen Modellangaben unten (`FAL_IMAGE_MODEL=...`,
kling-Default) durch konkrete, seam-getestete Endpoints. Die nummerierten §-Skripte darunter
bleiben der allgemeine Mechanismus; wo diese Kette und der generische Pfad kollidieren, gewinnt
die Kette hier.

**Der Kern-Trick gegen den sichtbaren Qualitätsfehler:** Bei der billigen Variante *morpht* das
Video zwischen zwei **unabhängig** erzeugten Stills — sichtbarer Matsch. Hier wird stattdessen
**jede Folge-Szene aus dem vorigen Still herauseditiert**, sodass die ganze Fahrt **eine
zusammenhängende Welt** ist statt eines Morphs zwischen unzusammenhängenden Bildern.

**1. Stills — chained edit statt N unabhängiger Renders.**
- Szene 1 (text-to-image): `fal-ai/nano-banana-pro`. Input: `prompt`, `resolution`
  (`'1K'|'2K'|'4K'`), `aspect_ratio` `'16:9'`, `num_images`, `output_format`. ~$0.15/Bild (2K),
  ~$0.30 (4K).
- Szene 2..N (image edit, **GECHAINT**): `fal-ai/nano-banana-pro/edit`. Input:
  `image_urls: [<vorheriger-still-url>]`, `prompt: 'exact same world, camera moved …'`. Jede Szene
  wird aus dem vorigen Still editiert — das hält Winkel, Palette, Licht und Geometrie konsistent
  (die eine Welt). Niemals N Stills unabhängig erzeugen und auf Kohäsion hoffen — genau das war der
  Morph-Fehler der billigen Variante.

**2. Dives — lokale „Breathing"-Loops, KEIN fal-Clip (Kostenboden $0).** Statt eines KI-Dive-Clips
pro Szene ein lokaler ffmpeg-Loop, dessen **erster Frame == letzter Frame == der Still** ist (sanftes
zoompan-„Atmen", kein Kameraweg). Das erfüllt die Seam-Regel *per Konstruktion*: der Connector startet
auf genau diesem Still, es gibt also keinen Pop.

```bash
# "Breathing" dive loop from one still — first frame == last frame == the still, so a
# connector whose first_frame_url is that same still hands off with no pop. $0 (local ffmpeg).
breath() { # still.png out.mp4   (8s @ 24fps, gentle push-in-and-out, peak zoom at the middle)
  ffmpeg -v error -y -loop 1 -i "$1" -t 8 -r 24 \
    -vf "scale=2400:-2,zoompan=z='1+0.05*sin(on/191*PI)':d=1:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=1920x1080:fps=24,unsharp=5:5:0.8:5:5:0.0" \
    -c:v libx264 -preset slow -crf 20 -pix_fmt yuv420p \
    -g 8 -keyint_min 8 -sc_threshold 0 -movflags +faststart -an "$2"
}
for n in $NAMES; do breath "$WORK/still_$n.png" "$ASSETS/vid/$n.mp4"; done
```

**3. Connectors — veo3.1 FLF (voll), Still N → Still N+1.**
`fal-ai/veo3.1/first-last-frame-to-video` (**volle** Variante, **nicht** `/lite`),
`resolution: '1080p'`, `duration: '8s'`. Input: `prompt` (Kamerabewegung),
`first_frame_url` = Still N, `last_frame_url` = Still N+1, `aspect_ratio: '16:9'`,
`generate_audio: false`. Weil die Stills gechaint sind (eine Welt) **und** der Breathing-Dive auf dem
Still endet, sind `first_frame_url`/`last_frame_url` = die Stills hier **echte** Handoff-Frames — die
Seam-Regel (SKILL Kern-Prinzip) bleibt gewahrt, obwohl direkt zwischen Stills verbunden wird.
- **Kosten:** nominal ~$0.20/s (720p/1080p ohne Audio) → 8s ≈ $1.60; **in der Praxis bei 1080p
  ~$3.20/Clip** beobachtet — mit dem höheren Wert budgetieren und live gegen die fal-Modellseite
  gegenprüfen (fal re-tiert oft).
- **Günstigere Tiers als Option:** `fal-ai/veo3.1/lite/first-last-frame-to-video` (Kostenboden,
  weicher, `duration` fix `'8s'`) · `fal-ai/kling-video/o1/image-to-video` (Felder
  `start_image_url`/`end_image_url`).

**Frame-Locking-Felder — exakt, nie per Analogie raten:** veo3.1 nutzt
`first_frame_url`/`last_frame_url`; kling und wan nutzen `start_image_url`/`end_image_url`
(volle Tabelle in SKILL „Asset-Generierung"). Ein falsch geratener Feldname wird still ignoriert
oder mit 400 abgelehnt.

**Lokaler ffmpeg-Post (kein fal-Kosten):** die Breathing-Dive-Loops (oben), die 720p-Mobile-Varianten
(§6 `encm`) und der Re-Encode fürs saubere Scrubbing (`-g 8 -keyint_min 8 -movflags +faststart -an`,
§5 `enc`).

**Kostenmodell/Seite (6 Szenen):** 6 Stills nano 2K (~$0.90) + 5 Connectors veo3.1 1080p 8s (~$16)
≈ **~$17** (Dives lokal → $0).

## 1. Scene stills (Step 2)

**Empfohlenes konkretes Bildmodell (statt des generischen `FAL_IMAGE_MODEL` unten):**
`fal-ai/nano-banana-pro` für Szene 1, `fal-ai/nano-banana-pro/edit` gechaint für Szene 2..N — siehe
Qualitäts-Rezept oben. Der generische Block unten bleibt gültig, wenn bewusst ein anderes Bildmodell
gesetzt wird.

Write one prompt file per section to `$WORK/still_<name>.txt` (see prompts.md), then:

```bash
# This skill pins only the FLF *video* endpoints — the still model is your pick. Set
# FAL_IMAGE_MODEL to a fal text-to-image endpoint and verify its schema live (the size/
# quality keys and the output path differ per model). Upstream wanted a 3:2 landscape
# ~2k high-quality render; add that model's own aspect/size keys to the body below.
FAL_IMAGE_MODEL=...              # e.g. a fal text-to-image endpoint (verify live)

gen_still() { # name
  jq -n --arg p "$(cat "$WORK/still_$1.txt")" \
    '{prompt:$p}' > "$WORK/still_$1.body.json"      # + the model's aspect/size keys (upstream: 3:2, ~2k, high)
  fal_run "$FAL_IMAGE_MODEL" "$WORK/still_$1.body.json" '.images[0].url' "$WORK/still_$1.png" \
    && echo "still $1 ok" || echo "still $1 FAIL"    # .images[0].url = fal text-to-image convention; verify per model
}
for n in $NAMES; do gen_still "$n" & done ; wait
```

Codex variant (STILLS_SOURCE=codex, SKILL Step 1.6 — subscription-billed, zero
credits; ~1–3 min each, parallelize in small batches):

```bash
gen_still_codex() { # name
  codex exec -C "$WORK" -s workspace-write --skip-git-repo-check \
    'Use the image generation tool ($imagegen) to generate: '"$(cat "$WORK/still_$1.txt")"' Wide 3:2 landscape, high resolution. Save it as ./still_'"$1"'.png. Do not do anything else.' \
    > "$WORK/still_$1.codex.log" 2>&1
  [ -f "$WORK/still_$1.png" ] && echo "still $1 ok (codex)" || echo "still $1 FAIL (see .codex.log)"
}
```

Convert to webp for the site (and optionally run knockout.py first for transparency):

```bash
for n in $NAMES; do cwebp -quiet -q 84 -resize 1800 0 "$WORK/still_$n.png" -o "$ASSETS/$n.webp"; done
```

Review the stills for cohesion before continuing. Re-roll any off-style one (if your fal
image model accepts a style/reference image, pass `$WORK/still_<good>.png` to lock style).

## 1b. STOPP — Stills-Abnahme durch den Nutzer (PFLICHT-GATE)

> **Hartes Gate. Erst ALLE Stills, dann — und nur nach ausdrücklicher Freigabe — Video.**

Bevor **irgendein** Video-Clip generiert wird (§2 Dives, §4 Connectors, bzw. die Connectors des
Qualitäts-Rezepts): **alle** Szenen-Stills fertigstellen, sie dem Nutzer **geschlossen zur Abnahme
vorlegen** (Kohäsion, Palette, Winkel, Licht, Art-Direction) und **explizite Freigabe** einholen.
Erst danach die teuren Video-Stufen starten.

**Warum Pflicht — echter, gemessener Produktionsschaden:** Stills sind billig (~$0.15/Stück), Video
ist teuer (ein veo3.1-1080p-Connector ~$3.20/Clip). In einem realen Lauf wurde eine **ganze Seite
inklusive Videos (~$16)** gerendert, **bevor** der Nutzer auf die Art-Direction reagieren konnte — der
Look passte nicht, das Budget war verbrannt. Dieses Gate verhindert genau das: Der Nutzer sieht die
günstigen Stills, bevor ein einziger teurer Clip läuft.

**Ablauf:** §1 (bzw. die Still-Kette des Qualitäts-Rezepts) laufen lassen → Stills präsentieren →
**auf Freigabe warten** → off-style/inkohärente Stills einzeln neu würfeln und erneut vorlegen →
**erst nach dem „go"** die Video-Stufen §2/§4/§5. Kein stillschweigendes Durchlaufen in die
Video-Generierung — das ist der teure Fehler, den dieses Gate abfängt.

## 2. Dive-in clips (Step 4)

Prompt files at `$WORK/dive_<name>.txt`. Start image = the solid-bg still PNG. A dive is a
single-start clip, so `VMODEL` must be a Kling image-to-video endpoint (veo3.1 FLF would
reject it — it requires an end frame too).

```bash
gen_dive() { # name
  jq -n --arg p "$(cat "$WORK/dive_$1.txt")" \
        --arg s "$(img_datauri "$WORK/still_$1.png")" --arg d "$DIVE_DUR" \
        --argjson x "$VEXTRA" \
    '{prompt:$p, start_image_url:$s, duration:$d} + $x' > "$WORK/dive_$1.body.json"
  fal_run "$VMODEL" "$WORK/dive_$1.body.json" '.video.url' "$WORK/dive_$1.mp4" \
    && echo "dive $1 ok" || echo "dive $1 FAIL"
}
for n in $NAMES; do gen_dive "$n" & done ; wait
```

The clip inherits the start frame's aspect (a 3:2 still → ~3:2 clip; the engine covers it).
For strict 16:9, feed a 16:9 start canvas or run that leg on a veo3.1 connector with
`aspect_ratio:"16:9"`.

Re-roll individual failures (transient 429 / 5xx / queue races):
`gen_dive shop`  (just that one).

## 3. Extract boundary frames — the seam handoff (Step 5)

For each adjacent pair, the connector's start = dive_i's LAST frame, end = dive_{i+1}'s
FIRST frame — extracted from the **rendered videos**, never the stills.

```bash
set -- $NAMES
prev=""
for n in "$@"; do
  ffmpeg -v error -ss 0 -i "$WORK/dive_$n.mp4" -frames:v 1 -q:v 2 "$WORK/first_$n.png"      # establishing
  ffmpeg -v error -sseof -0.15 -i "$WORK/dive_$n.mp4" -frames:v 1 -q:v 2 "$WORK/last_$n.png" # interior
done
```

## 4. Connector clips (Step 5)

Prompt files at `$WORK/conn_<i>.txt` (i = 1..N-1). Iterate adjacent pairs. Default: connectors
run on the same Kling `VMODEL` (one family, cohesive), setting the optional `end_image_url`.
Set `CMODEL` to flip connectors onto the native-FLF veo3.1 upgrade (`first_frame_url` /
`last_frame_url`, both required) for the hardest seam.

```bash
gen_conn() { # i startPng endPng
  local ep sf ef dur extra
  if [ -n "$CMODEL" ]; then                          # native-FLF upgrade (veo3.1 shown; wan-flf2v differs — see note)
    ep="$CMODEL"; sf=first_frame_url; ef=last_frame_url; dur="6s"   # veo3.1 enum has no 5s → 6s is nearest
    extra='{"resolution":"1080p","generate_audio":false}'
  else                                               # default: connectors on the Kling chain model (one family)
    ep="$VMODEL"; sf=start_image_url; ef=end_image_url; dur="$CONN_DUR"; extra="$VEXTRA"
  fi
  jq -n --arg p "$(cat "$WORK/conn_$1.txt")" \
        --arg s "$(img_datauri "$2")" --arg e "$(img_datauri "$3")" \
        --arg sf "$sf" --arg ef "$ef" --arg d "$dur" --argjson x "$extra" \
    '{prompt:$p, duration:$d} + {($sf):$s} + {($ef):$e} + $x' > "$WORK/conn_$1.body.json"
  fal_run "$ep" "$WORK/conn_$1.body.json" '.video.url' "$WORK/conn_$1.mp4" \
    && echo "conn $1 ok" || echo "conn $1 FAIL"
}
set -- $NAMES ; i=0 ; prev=""
for n in "$@"; do
  if [ -n "$prev" ]; then i=$((i+1)); gen_conn "$i" "$WORK/last_$prev.png" "$WORK/first_$n.png" & fi
  prev="$n"
done ; wait
```

`wan-flf2v` is frame-based, not duration-based: for that endpoint drop `duration` and pass
`num_frames` (81–100) + `frames_per_second` (5–24) and `resolution` "480p"|"720p" instead
(e.g. 81 frames @ 16 fps ≈ 5 s) — same `start_image_url`/`end_image_url` fields.

## 5. Encode everything for scrubbing (Step 6)

Native resolution (Kling returns its own native res; veo3.1 returns whatever `resolution`
you asked for; 720p-class renders stay 720p — **never upscale, encode what ffprobe
reports**), crf 20, GOP 8, light sharpen, no audio, faststart. Same for dives + connectors.

```bash
enc() { ffmpeg -v error -y -i "$1" -an -vf "unsharp=5:5:0.8:5:5:0.0" \
  -c:v libx264 -preset slow -crf 20 -pix_fmt yuv420p \
  -g 8 -keyint_min 8 -sc_threshold 0 -movflags +faststart "$2"; echo "enc $2 $(du -h "$2"|cut -f1)"; }

for n in $NAMES; do enc "$WORK/dive_$n.mp4" "$ASSETS/vid/$n.mp4"; done
i=0; for f in "$WORK"/conn_*.mp4; do i=$((i+1)); enc "$f" "$ASSETS/vid/conn$i.mp4"; done
```

Now the engine config's `sections[k].clip = assets/vid/<name>.mp4` and
`connectors = [assets/vid/conn1.mp4, …]` (length N-1, in order). **Hosting note:**
Cloudflare Pages caps every file at **25 MiB** — a native-res dive/connector can exceed
that. Serve those clips from R2 (or another object store) and point `clip`/`connectors` at
the R2 URLs; keep the small `-m.mp4` mobile encodes (§6) and the webp stills on Pages.

## 6. Centre-crop mobile encodes — FALLBACK ONLY, not the mobile version

**The mobile version is the native 9:16 portrait chain (§6b).** This section's crop
encodes exist for one case: the user opted into mobile but credits can't cover the
portrait chain — and shipping them must be called out and approved, never silent
(portrait phones will see the landscape film's centre ~26%). The encode mechanics
matter either way: scrubbing sets `currentTime` every frame, and a phone decoder's
**seek cost scales with how many frames it must decode from the nearest keyframe** — so
a 1080p `-g 8` master that scrubs fine on a laptop stutters on a phone. A **smaller
frame + tighter GOP** fixes that (and halves the bytes on cellular). The crop `-m.mp4`
sibling per clip:

```bash
# 720p, GOP 4 (twice the keyframes = ~half the seek-decode work), crf 23, same sharpen/faststart.
encm() { ffmpeg -v error -y -i "$1" -an -vf "scale=-2:720,unsharp=5:5:0.6:5:5:0.0" \
  -c:v libx264 -preset slow -crf 23 -pix_fmt yuv420p \
  -g 4 -keyint_min 4 -sc_threshold 0 -movflags +faststart "$2"; echo "encm $2 $(du -h "$2"|cut -f1)"; }

for n in $NAMES; do encm "$WORK/dive_$n.mp4" "$ASSETS/vid/$n-m.mp4"; done
i=0; for f in "$WORK"/conn_*.mp4; do i=$((i+1)); encm "$f" "$ASSETS/vid/conn$i-m.mp4"; done
```

Wire the variants in the engine config — the engine serves them automatically on phones,
falling back to the desktop `clip` when a mobile one is absent:

```js
sections[k].clipMobile = 'assets/vid/<name>-m.mp4';
connectorsMobile = ['assets/vid/conn1-m.mp4', …];   // length N-1, in order
```

If phone scrubbing still stutters, tighten the GOP further (`-g 2`, or `-g 1` for all-intra
= instant seeks at the cost of larger files); if cellular weight is the bigger worry, raise
`crf` (24–26) or drop to `scale=-2:600`. If the master is already 720p (e.g. wan-flf2v or a
720p veo3.1/kling render), the mobile encode still pays off — the tighter GOP is what makes
phone seeks cheap. All-mobile encodes stay 16:9 — the engine centre-crops them; see the
portrait note in SKILL Step 8 / prompts.md.

## 6b. Native 9:16 portrait chain — THE mobile version (Step 1.5 opt-in)

When the user opts into mobile, this is what they get: a **parallel 9:16 chain** rendered
natively for phones and shipped as the mobile variants — never the §6 crops (those are the
no-credits stopgap). Same seam laws as the main chain — the portrait chain frame-locks
against its own rendered frames, never the landscape ones. Budget ~2N-1 video gens +
re-rolls (interiors trip the NSFW filter in portrait too); state the credit cost at the
Step 1.5 interview.

1. **Portrait start canvases.** Don't hand the video model a 3:2 still and hope: composite
   each scene onto a 1080×1920 canvas in the page bg colour (island at ~94% width, visual
   centre at ~45% height). The render then opens exactly on what the portrait poster shows.
   For knocked-out stills, composite the RGBA over the bg colour first.
2. **Dives/legs**: same prompt templates with a portrait clause up front ("Vertical
   portrait composition, the diorama centered with generous [bg] space above and below"),
   same model/params as the main chain — the 9:16 comes from the 1080×1920 start canvas
   (Kling has no aspect param; on a veo3.1 connector also set `aspect_ratio:"9:16"`).
   Review each last frame before chaining, as ever.
3. **Connectors**: extract first/last frames **from the 9:16 renders** and generate 9:16
   connectors between them. A native 9:16 scene mixed into cropped-16:9 neighbours pops at
   both seams — the portrait chain must be complete, not partial.
4. **Encode** with the §6 settings but portrait-oriented scale: `scale=720:-2` (720 wide),
   `-g 4`, crf 23 → these ARE the `-m.mp4` mobile files (and they replace any §6 crop
   stopgaps that shipped earlier).
5. **Posters**: extract each 9:16 dive's first frame → webp → wire as the section's
   `stillMobile` so the poster matches the portrait video's frame 0 (no landscape→portrait
   flash when the clip paints). Engine support: `sections[k].stillMobile`.

## 7. Seam-QA im Browser — plus die browser-freie Kontinuitätsprüfung (Step 8)

**Bewegungs-QA nur im echten Nutzer-Chrome.** Automation-/Headless-Browser (inklusive
`claude-in-chrome`) können oft **kein Video dekodieren**: Ein valides H.264 bleibt bei
`readyState 0` hängen, `loadedmetadata` feuert nie, und es wird **kein Fehler** geworfen — es sieht
aus wie „lädt noch". Die Bewegungs-QA (Scrubbing, Seams, Stutter) muss deshalb in einem **echten
Chrome** laufen, nicht im Automations-Browser.

**Die datenseitige Kontinuitätsprüfung ist browser-frei und deferiert NICHT — immer ausführen.** Sie
braucht kein Video-Decoding: `first_frame_url`/`last_frame_url` locken die Connector-Endframes auf die
Stills, also muss der **erste** Connector-Frame den ausgehenden Still und der **letzte** den
eingehenden Still treffen. Hohe PSNR / niedrige MAE = frame-dichter Seam; niedrige PSNR = ein Pop, den
der Engine-Crossfade nur kaschiert.

```bash
seam_check() { # connector.mp4  expected_first.png(=Still N)  expected_last.png(=Still N+1)
  ffmpeg -v error -y -ss 0        -i "$1" -frames:v 1 "$WORK/_cf.png"
  ffmpeg -v error -y -sseof -0.05 -i "$1" -frames:v 1 "$WORK/_cl.png"
  printf 'first vs Still N   PSNR '; ffmpeg -v error -i "$WORK/_cf.png" -i "$2" \
    -lavfi "[0:v]scale=1280:720[a];[1:v]scale=1280:720[b];[a][b]psnr" -f null - 2>&1 | grep -o 'average:[0-9.]*'
  printf 'last  vs Still N+1 PSNR '; ffmpeg -v error -i "$WORK/_cl.png" -i "$3" \
    -lavfi "[0:v]scale=1280:720[a];[1:v]scale=1280:720[b];[a][b]psnr" -f null - 2>&1 | grep -o 'average:[0-9.]*'
}
# >~40 dB = frame-tight; ein Ausreißer nach unten = ein Still statt eines echten Frames, oder das
# Modell hat den Frame-Lock verfehlt -> diesen Clip neu würfeln (nicht nur den Crossfade hochdrehen).
```

Die **visuelle** QA (Look, Design-Bar) darf mit benanntem Owner + Termin an manuelles QA deferieren;
die **datenseitige** Prüfung oben deferiert **nie** (kein Browser, keine Session nötig).

## Notes

- The result URL is `.video.url` on the fal job response (the `response_url` from the
  submit reply; the submit reply also carries `status_url` for polling). fal image models
  return `.images[0].url`.
- **NSFW fallback across models**: if one clip keeps getting flagged after re-rolls +
  prompt scrubbing, regenerate just that clip on a different endpoint with the SAME
  start/end frames — flip that single index onto the veo3.1 FLF upgrade:
  `CMODEL=fal-ai/veo3.1/first-last-frame-to-video; gen_conn 3 "$WORK/last_shop.png" "$WORK/first_delivery.png"` —
  then clear `CMODEL` to restore the chain model. A one-off family switch on a single
  connector is far less visible than on a dive. See SKILL Gotchas for the trade-off.
- **Previz on the cheap**: run the whole chain once with
  `VMODEL=fal-ai/kling-video/o1/image-to-video` (flat $0.112/s; start-req/end-opt shape →
  dives and connectors both work; set `VEXTRA='{}'`) to validate the journey and seams
  before spending on the standard tier — because it's still seamless, the previz translates
  directly to the final render. Don't reach for a plain text-to-video or an image-to-video
  with no end-frame field: without a start+end it can't hold a seam, so its output can't be
  chained (Step 4 rule).
- If a whole batch stalls, check your fal dashboard for balance and `$WORK/*.body.json` /
  the `status=` echo from `fal_run` for the reason.
- Concurrency: launching ~5–6 gens at once is fine; much more can trigger transient
  rate/queue errors — stagger or re-roll.
