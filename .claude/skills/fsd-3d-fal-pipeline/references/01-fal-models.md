# fal.ai Model Reference (Juli 2026)

> **Stand:** 2026-07-23 — Modell-Preise und Endpoint-IDs aendern sich oefter. Halbjaehrlich review-en.
>
> **KORREKTUR 2026-07-23 — der Befund-Block vom 2026-05-13 war falsch und ist widerrufen.**
> Jede ID unten wurde einzeln gegen zwei unabhaengige Routen geprueft (Methode siehe naechster
> Abschnitt), mit bestandener Positiv- und Negativkontrolle. Konkret widerrufen:
> - **`fal-ai/hyper3d/rodin` ist gelistet und live** ($0.40 pro Generation). Die Behauptung "aktuell
>   nicht auf fal.ai gelistet (404 auf model-page)" ist widerlegt: Modellseite **und** Queue-OpenAPI
>   antworten mit 200. Zusaetzlich existiert die neuere Familie `fal-ai/hyper3d/rodin/v2.5`.
> - **`fal-ai/hunyuan3d/v2` ist gelistet und live** ($0.16 untexturiert / $0.48 texturiert), ebenso
>   die Rapid-Linie `fal-ai/hunyuan-3d/v3.1/rapid/text-to-3d` ($0.225 pro Generation). Auch diese
>   "nicht gelistet"-Behauptung ist widerlegt.
> - Der Meshy-Endpoint heisst `fal-ai/meshy/v6/multi-image-to-3d`. Die frueher notierte Schreibweise
>   `meshy/v6/multi-image-to-3d` ohne `fal-ai/`-Praefix ist tot (404).
> - **`fal-ai/veo3` ist deprecated** ("This endpoint is deprecated" / "This model is no longer
>   supported") und antwortet trotzdem mit 200. Ersatz: `fal-ai/veo3.1`.
> - **`fal-ai/flux-2-pro` ist live** — "FLUX-2-Pro endpoint nicht verfuegbar" war falsch. Tot ist nur
>   die Schreibweise `flux-2/pro` mit Slash. Enthaelt die DB `model='flux-2/pro'`, mappt der Generator
>   ab jetzt auf `fal-ai/flux-2-pro` (vorher: auf `fal-ai/flux-pro/v1.1`).
> - Die Alt-Notiz "FLUX-pro/v1.1 ist Sync-only (`https://fal.run/`), Queue 405" wurde 2026-07-23
>   **nicht bestaetigt** und bleibt offen: ein GET auf `https://queue.fal.run/<id>/openapi.json`
>   liefert fuer **jede** ID 405 — auch fuer erfundene. Der 405 taugt weder als Liveness- noch als
>   Sync-only-Beweis. Vor Nutzung selbst gegenpruefen.

## ID-Regel: IDs niemals analog ableiten

fal.ai mischt **Slash und Bindestrich innerhalb derselben Modellfamilie**, und mal steht das
`fal-ai/`-Praefix davor, mal ist es Teil eines eigenen Owner-Namespace. Es gibt keine Regel, aus der
sich die naechste ID ableiten liesse — **jede ID einzeln gegen die Modellseite pruefen, nie raten.**

| Falle | Tot | Live |
|---|---|---|
| Slash statt Bindestrich | `fal-ai/flux-2/pro` | `fal-ai/flux-2-pro` |
| Slash statt Bindestrich | `fal-ai/kling-video/v2.5/turbo/pro` | `fal-ai/kling-video/v2.5-turbo/pro/text-to-video` |
| Praefix fehlt | `meshy/v6/multi-image-to-3d` | `fal-ai/meshy/v6/multi-image-to-3d` |
| Version geraten | `fal-ai/wan/v2.6/text-to-video` | `fal-ai/wan/v2.7/text-to-video` |

Gegenbeispiele im selben Bestand: `fal-ai/flux/schnell` und `fal-ai/flux/dev` benutzen den Slash,
`fal-ai/flux-2-pro` den Bindestrich — alle drei live. `fal-ai/hunyuan3d/v2` schreibt sich ohne
Bindestrich, `fal-ai/hunyuan-3d/v3.1/rapid/text-to-3d` mit. Ein Analogieschluss ist nicht "riskant",
sondern nachweislich falsch — er hat in dieser Datei vier tote IDs erzeugt.

**Wildcards gehoeren nicht in diese Referenz.** Ein Eintrag wie `fal-ai/veo3.1/*` ist per Konstruktion
nicht gegen die Live-API pruefbar. Immer die konkreten Endpoint-IDs auflisten.

**Pruefmethode (zwei Routen, jeweils mit Positiv- UND Negativkontrolle):**

1. Modellseite `https://fal.ai/models/<id>` — 200 = existiert, 404 = tot.
2. Queue-OpenAPI `https://fal.ai/api/openapi/queue/openapi.json?endpoint_id=<id>`.
3. Negativkontrolle mit einer erfundenen ID (muss auf **beiden** Routen 404 liefern) und
   Positivkontrolle mit `fal-ai/flux/schnell` (muss auf beiden Routen antworten). Ohne beide
   Kontrollen ist das Ergebnis wertlos.
4. **Statuscode allein reicht nicht:** `fal-ai/veo3` und `fal-ai/flux-pro` antworten mit 200 und
   tragen trotzdem "This endpoint is deprecated". Den Seiteninhalt lesen, nicht nur den Code.
5. **NICHT benutzen:** `https://queue.fal.run/<id>/openapi.json` — liefert per GET fuer jede ID
   405 Method Not Allowed, auch fuer erfundene. Die Route unterscheidet nicht zwischen echt und tot.
6. Ein Treffer im fal-Modellindex (`fal.ai/api/models?keywords=...`) oder in einer Websuche ist
   **kein** Liveness-Beweis — dort haengen veraltete Geist-Eintraege (so geschehen bei
   `fal-ai/wan/v2.6/text-to-video`).

## 3D Models (GLB output)

| Endpoint | Price | Output | Use |
|---|---|---|---|
| `fal-ai/hyper3d/rodin` | $0.40 pro Generation · `/v2.5` und `/v2.5/text-to-3d` $0.40 (+$0.80 mit HighPack-Addon) · `/v2.5/fast` und `/v2.5/text-to-3d/fast` $0.10 | GLB + PBR + separate textures | **HERO / brand-critical**. Clean quad topology, production-ready, no Blender cleanup needed. Gen-2, 10B params. |
| `fal-ai/hunyuan-3d/v3.1/pro/text-to-3d` | $0.375 pro Generation | GLB, up to 1.5M poly, optional PBR | High-quality Allround. Multi-view input up to 8 angles. |
| `fal-ai/hunyuan-3d/v3.1/rapid/text-to-3d` | $0.225 pro Generation | GLB, fixed poly | **RUNTIME default**. Best balance of price/quality/latency. |
| `fal-ai/hunyuan3d/v2` | $0.16 untexturiert (white) · $0.48 texturiert | GLB, configurable octree 1–1024 | Quality-speed tradeoff via inference steps. |
| `fal-ai/meshy/v6/multi-image-to-3d` | $0.80 pro untexturiertem Modell · $1.20 pro texturiertem Modell · +$0.20 Auto-Rigging · +$0.12 Animation | GLB | Image-to-3D, **nicht** text-to-3D. Teuerste Option der Tabelle — nur wenn Rigging/Animation gebraucht wird. |
| `fal-ai/trellis` | $0.02 pro Generation · Nachfolger `fal-ai/trellis-2`: $0.25 @512p · $0.30 @1024p · $0.35 @1536p | GLB | Game-asset focus. **PREVIEW-Default seit 2026-07-23** (Ersatz fuer SF3D, siehe Notiz). |
| `fal-ai/stable-point-aware-3d` (SF3D) | — | — | **NICHT MEHR VERFUEGBAR (geprueft 2026-07-23).** 404 auf Modellseite und Queue-OpenAPI; Index-Suche nach `point-aware`, `spar3d`, `stable-point` = 0 Treffer. Der frueher hier stehende Preis ($0.07, sub-second, albedo-only) gilt nicht mehr. |

**Preview-Tier nach dem SF3D-Ausfall:** `fal-ai/stable-point-aware-3d` war der Preview-/Thumbnail-
Default und ist ersatzlos verschwunden — es wurde bewusst **kein** Nachfolger erfunden. Neuer Default
ist `fal-ai/trellis` ($0.02 pro Generation), die preislich naechstliegende live Preview-Option. Das
ist **kein Drop-in-Ersatz**: anderes Modell, anderes Output-Profil. Wer die SF3D-Eigenschaften
(sub-second, albedo-only) fachlich braucht, muss die Preview-Stufe neu bewerten statt blind zu
tauschen.

## Image Models

| Endpoint | Price | License | Use |
|---|---|---|---|
| `fal-ai/flux/schnell` | $0.003 pro Megapixel, aufgerundet auf volle MP | Apache 2.0 (commercial OK) | **DEFAULT for iteration & textures**. |
| `fal-ai/flux/dev` | $0.025 pro Megapixel, aufgerundet auf volle MP | ⚠ Lizenzlage strittig — siehe Notiz unter der Tabelle | Bis zur rechtlichen Klaerung nicht in Produktion. |
| `fal-ai/flux-pro` | $0.05 pro Megapixel | ⚠ **DEPRECATED** (antwortet 200, traegt aber "This model is no longer supported") | Nicht mehr verwenden — auf `fal-ai/flux-pro/v1.1` wechseln. |
| `fal-ai/flux-pro/v1.1` | $0.04 pro Megapixel, aufgerundet auf volle MP | Commercial via fal | Brand-critical fallback. |
| `fal-ai/flux-2-pro` | $0.03 fuer das erste Output-Megapixel · danach +$0.015 je weiterem Megapixel Input **und** Output, aufgerundet auf volle MP | Commercial | **DEFAULT for high-quality stills**. Current flagship. |
| `fal-ai/flux-lora` | $0.035 pro Megapixel, aufgerundet auf volle MP | Commercial via fal | LoRA-Inference, u.a. fuer Tile-Texture-LoRAs (siehe unten). |
| `fal-ai/nano-banana-pro` | $0.15 pro Bild (1K und 2K) · $0.30 bei 4K-Output (doppelter Satz) · +$0.015 wenn Web-Search genutzt wird | Commercial via fal, SynthID watermark | Premium, multi-image consistency. |

**Achtung Megapixel-Staffel:** die Flux-Preise sind Pro-Megapixel-Preise mit Aufrundung auf volle MP.
Ein 1-MP-Still kostet bei `fal-ai/flux-2-pro` $0.03, ein 2048×1024-Panorama (≈2,1 MP → 3 MP
aufgerundet) entsprechend mehr. Vor jeder Budgetierung mit der tatsaechlichen Zielaufloesung
nachrechnen, nie mit dem Einstiegspreis multiplizieren.

**Lizenz-Notiz `fal-ai/flux/dev` (offen, Stand 2026-07-23):** Diese Referenz fuehrte das Modell als
"NON-COMMERCIAL — never use in production". Die fal-Modellseite sagt dagegen ausdruecklich, FLUX.1
[dev] sei ueber fal.ai "suitable for both personal and commercial use" — die kommerzielle Nutzung
liefe dann ueber die fal-Plattformlizenz statt ueber die Original-BFL-Lizenz. Geprueft wurde nur die
Modellseite, **nicht** die Lizenz-AGB. Bis zur rechtlichen Gegenpruefung bleibt die konservative
Regel bestehen (SKILL.md, Hard Rule 5): `fal-ai/flux/schnell` oder `fal-ai/flux-pro/v1.1` benutzen.

## Video Models

| Endpoint | Price | Use |
|---|---|---|
| `fal-ai/wan/v2.7/text-to-video` | $0.10/s @720p · $0.15/s @1080p | **DEFAULT for hero loops**. Cheapest viable. Ersetzt `fal-ai/wan/v2.6/text-to-video` (tot, 404 auf beiden Routen). |
| `fal-ai/kling-video/v2.5-turbo/pro/text-to-video` | $0.35 pauschal fuer 5 s Video · danach $0.07 je weiterer Sekunde | Better motion quality. **Kein reiner Pro-Sekunde-Tarif** — 5-s-Mindestblock, ein 2-s-Clip kostet ebenfalls $0.35. |
| `fal-ai/kling-video/v3/pro/text-to-video` (ebenso `/image-to-video`, `/motion-control`) | $0.112/s Audio off · $0.168/s Audio on · $0.196/s Audio + Voice-Control | Top-tier, optional audio. |
| `fal-ai/veo3.1` (+ `/fast`, `/lite`, `/image-to-video`, `/first-last-frame-to-video`, `/reference-to-video`, `/extend-video`) | Standard: $0.20/s @720p und @1080p ohne Audio · $0.40/s mit Audio · $0.40/s @4K ohne Audio · $0.60/s @4K mit Audio. `/fast`: $0.10/s bzw. $0.15/s @720p und @1080p · $0.30/s bzw. $0.35/s @4K. `/lite`: $0.03/s @720p ohne Audio · $0.05/s @720p mit Audio · $0.05/s @1080p ohne Audio · $0.08/s @1080p mit Audio | Highest quality, native audio. |

- **`fal-ai/veo3` ist deprecated** (200, aber "This model is no longer supported"), Preis war $0.20/s
  ohne Audio / $0.40/s mit Audio. Ersatz ist `fal-ai/veo3.1` mit der Staffel oben.
- **Wan 2.6:** nur `fal-ai/wan/v2.6/text-to-video` ist tot. Im selben Namespace sind
  `fal-ai/wan/v2.6/image-to-video`, `/reference-to-video` und `/text-to-image` weiterhin erreichbar —
  reicht image-to-video fachlich aus, ist `fal-ai/wan/v2.6/image-to-video` die live verifizierte
  v2.6-Alternative.

## HDRI / Environment Maps

No true HDR generation exists on fal.ai. Workaround:

1. Use `fal-ai/flux-2-pro` (FLUX.2 Pro) with prompt: `"360 degree equirectangular HDR panorama, seamless, [scene description], no visible horizon line"`
2. Image size: `{ width: 2048, height: 1024 }` (2:1 ratio) — das sind ≈2,1 MP, also 3 MP nach
   Aufrundung. Preis entsprechend der MP-Staffel oben, nicht $0.03 pauschal.
3. Pass to R3F: `<Environment files={url} background={false} />`
4. Accept: this is LDR, not physically correct HDR. Sufficient for web hero scenes.

## Seamless Video Loops

No model generates seamless loops natively. Workarounds:

- **First-frame = last-frame trick** (Kling, Wan support this): pass the same image as both endpoints
- **ffmpeg crossfade polish** in `optimize.ts` (overlay first 0.5 s alpha-faded into last 0.5 s) — see `optimizeVideo({ loop: true })`
- **Boomerang** (video + reversed): only for symmetric motion, often looks artificial

## Texture Tileability

Flux is NOT tileable by default. Three approaches:

1. **Prompt trick**: `"seamless tileable texture, repeating pattern, no borders, top-down view"`
2. **Sharp post-process**: mirror-mode tile in `optimize.ts`
3. **Tile-Texture-LoRA** via `fal-ai/flux-lora` ($0.035 pro Megapixel, aufgerundet auf volle MP) —
   most precise but more setup
