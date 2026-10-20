# fal.ai Model Reference (Juli 2026)

> **Stand:** 2026-07-23 · Tabellen nachgemessen 2026-09-17 — Modell-Preise und Endpoint-IDs ändern
> sich öfter. **„Halbjährlich reviewen" reicht nachweislich nicht:** eine hier am 2026-07-23 als
> „live verifiziert" ausgezeichnete ID war 47 Tage später tot (Issue #63, aus einem
> Konsumentenprojekt gemeldet). Diese Datei ist ein **datierter Stand, keine Garantie** — jede ID vor
> Nutzung selbst nach der Prüfmethode unten prüfen, auch wenn sie hier steht.
> Reichweite der Nachmessung 2026-09-17: **28 IDs, jede auf beiden Routen.** Genau eine antwortet
> nicht (`fal-ai/stable-point-aware-3d`, 404/404), genau zwei tragen den per-Modell-Deprecation-Marker
> (`fal-ai/veo3`, `fal-ai/flux-pro`) — alle drei führt diese Datei bereits so. Die einzige **tote ID**
> stand im Wan-2.6-Absatz unter „Video Models"; er ist unten widerrufen.
> **Im selben Durchgang korrigiert (Issue #64): die Loop-Aussagen.** `fal-ai/wan/v2.7/text-to-video`
> stand als „DEFAULT for hero loops" in der Video-Tabelle, obwohl ein `text-to-video`-Endpoint kein
> Start-/Endbild annimmt und deshalb keine Naht halten kann; „Seamless Video Loops" nannte nur die
> Primitive und einen Helfer (`optimizeVideo`), den es nur als unausgefülltes Template gibt. Der
> Abschnitt trägt jetzt das Rezept (Anker aus dem Pilot-Video, Sterntopologie, Endpoint-Anforderung)
> und verweist für die Naht auf die **eine** Skala in `skill:scroll-world`.
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
4. **Statuscode allein reicht nicht — aber "steht 'deprecated' auf der Seite?" ist selbst ein
   Falschbefund-Generator.** Richtig bleibt: `fal-ai/veo3` und `fal-ai/flux-pro` antworten mit 200
   und tragen trotzdem "This endpoint is deprecated", der Seiteninhalt muss also gelesen werden.
   Aber **jede** fal.ai-Modellseite trägt zusätzlich eine globale Bannerkonfiguration — am
   2026-09-17 wörtlich `"value":"fal-ai/ltx-2/","message":"This endpoint will be deprecated on
   August 15, 2026"`. Ein naives `/deprecated/i` auf dem HTML färbt darum auch die Positivkontrolle
   `fal-ai/flux/schnell` rot. Nur der **per-Modell-Marker** unterscheidet: exakt "This endpoint is
   deprecated" bzw. "This model is no longer supported", bezogen auf die abgefragte ID. Gemessen
   2026-09-17 über 28 IDs: Marker true genau bei `veo3` und `flux-pro`, false bei den anderen 26.
   Wer nur den Text "deprecated" sucht, wiederholt die Fehlerklasse, die diese Datei korrigiert.
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
| `fal-ai/wan/v2.7/text-to-video` | $0.10/s @720p · $0.15/s @1080p | **DEFAULT for hero clips**. Cheapest viable. Ersetzt `fal-ai/wan/v2.6/text-to-video` (tot, 404 auf beiden Routen). Kann **keinen** frame-gelockten Loop — dafür braucht es getrennte Start-/Endbild-Felder, siehe "Seamless Video Loops". |
| `fal-ai/wan/v2.7/image-to-video` | $0.10/s @720p · $0.15/s @1080p | Image-to-video derselben Familie. Modi: `image_url` (first frame), `image_url` + `end_image_url` (first/last), `video_url` (continuation). Gemessen 2026-09-17: 200 auf beiden Routen, kein per-Modell-Deprecation-Marker. Ersatz für das tote `fal-ai/wan/v2.6/image-to-video`. |
| `fal-ai/kling-video/v2.5-turbo/pro/text-to-video` | $0.35 pauschal fuer 5 s Video · danach $0.07 je weiterer Sekunde | Better motion quality. **Kein reiner Pro-Sekunde-Tarif** — 5-s-Mindestblock, ein 2-s-Clip kostet ebenfalls $0.35. |
| `fal-ai/kling-video/v3/pro/text-to-video` (ebenso `/image-to-video`, `/motion-control`) | $0.112/s Audio off · $0.168/s Audio on · $0.196/s Audio + Voice-Control | Top-tier, optional audio. |
| `fal-ai/veo3.1` (+ `/fast`, `/lite`, `/image-to-video`, `/first-last-frame-to-video`, `/reference-to-video`, `/extend-video`) | Standard: $0.20/s @720p und @1080p ohne Audio · $0.40/s mit Audio · $0.40/s @4K ohne Audio · $0.60/s @4K mit Audio. `/fast`: $0.10/s bzw. $0.15/s @720p und @1080p · $0.30/s bzw. $0.35/s @4K. `/lite`: $0.03/s @720p ohne Audio · $0.05/s @720p mit Audio · $0.05/s @1080p ohne Audio · $0.08/s @1080p mit Audio | Highest quality, native audio. |

- **`fal-ai/veo3` ist deprecated** (200, aber "This model is no longer supported"), Preis war $0.20/s
  ohne Audio / $0.40/s mit Audio. Ersatz ist `fal-ai/veo3.1` mit der Staffel oben.
- **Wan 2.6 ist als Ganzes tot — es gibt keinen v2.6-Notnagel (gemessen 2026-09-17).** Nicht nur
  `fal-ai/wan/v2.6/text-to-video`: auch `fal-ai/wan/v2.6/image-to-video`,
  `fal-ai/wan/v2.6/reference-to-video` und `fal-ai/wan/v2.6/text-to-image` liefern **404 auf beiden
  Routen**. Die früher hier stehende Empfehlung, `fal-ai/wan/v2.6/image-to-video` sei "die live
  verifizierte v2.6-Alternative", ist **widerrufen** — sie stand am 2026-07-23 als live verifiziert
  in dieser Datei und war 47 Tage später tot. Ersatz für image-to-video:
  `fal-ai/wan/v2.7/image-to-video` (Tabellenzeile oben) oder
  `fal-ai/kling-video/v3/pro/image-to-video` — letzteres nimmt `duration` als **String** ("3".."15"),
  hat `generate_audio` mit Default **true** und **kein** `aspect_ratio`.
  Kontrollen dieses Durchgangs bestanden: Positiv `fal-ai/flux/schnell` 200 auf beiden Routen,
  Negativ (erfundene ID) `fal-ai/kling-video/v9/ultra/image-to-video` 404 auf beiden Routen.

## HDRI / Environment Maps

No true HDR generation exists on fal.ai. Workaround:

1. Use `fal-ai/flux-2-pro` (FLUX.2 Pro) with prompt: `"360 degree equirectangular HDR panorama, seamless, [scene description], no visible horizon line"`
2. Image size: `{ width: 2048, height: 1024 }` (2:1 ratio) — das sind ≈2,1 MP, also 3 MP nach
   Aufrundung. Preis entsprechend der MP-Staffel oben, nicht $0.03 pauschal.
3. Pass to R3F: `<Environment files={url} background={false} />`
4. Accept: this is LDR, not physically correct HDR. Sufficient for web hero scenes.

## Seamless Video Loops

Nativ generiert kein Modell einen Loop. Ein Loop **beliebiger Länge** lässt sich aber KOMPONIEREN
— das ist eine andere Aussage als "geht nicht". In dieser Reihenfolge:

- **Ankerverankerte Sterntopologie (empfohlen; 70 s belegt).** Zuerst einen Pilot-Clip erzeugen und
  aus ihm EINEN Frame als Anker A entnehmen — ausdrücklich **nicht** das Originalbild. Jeder
  weitere Clip läuft dann `A -> A` (Kling: `start_image_url` == `end_image_url`; Wan 2.7:
  `image_url` == `end_image_url`; veo3.1-FLF: `first_frame_url` == `last_frame_url`) mit eigenem
  zyklischem Bewegungsmotiv; die fertigen Clips sind in **beliebiger Reihenfolge** aneinanderhängbar, weil
  jeder an demselben Frame beginnt und endet. Warum der Anker aus dem VIDEO kommen muss, ist im Haus
  schon Gesetz und wird hier nur angewandt: `skill:scroll-world`, `SKILL.md` Kern-Prinzip — "echte
  gerenderte Frames, niemals die Original-Stills, sonst sichtbarer Pop". Gemessen am selben Motiv
  (SSIM auf der Gebäude-Region, Bild-Edit gegen Original / Videomodell gegen sein eigenes
  Ausgangsbild): 1440 px 0,6475 / 0,8566 · 720 px 0,8655 / 0,9822 · 480 px 0,9257 / 0,9936 — ein
  Bild-Edit zeichnet die Architektur neu, das Videomodell reproduziert sie. Genuin neu gegenüber
  scroll-world ist allein die **geschlossene** Stern-Form: scroll-world baut eine LINEARE Kette
  (Clip i endet, wo Clip i+1 beginnt), hier beginnen und enden ALLE Clips am selben Anker.
- **First-frame = last-frame trick** (Kling, Wan support this): pass the same image as both endpoints
  — das ist die Primitive der Sterntopologie, angewandt auf einen EINZELNEN Clip.
- **ffmpeg crossfade polish** (overlay first 0.5 s alpha-faded into last 0.5 s). Der hier früher
  genannte Helfer `optimizeVideo({ loop: true })` gehört zu `templates/backend/`, und dieses
  Template ist **noch nicht ausgefüllt** (`templates/backend/README.md` führt
  `src/services/{fal-client,cache,storage,optimize}.ts` als TODO) — bis dahin Handarbeit.
- **Boomerang** (video + reversed): only for symmetric motion, often looks artificial

**Endpoint-Anforderung — ein `text-to-video`-Endpoint kann das konstruktiv nicht.** `A -> A` braucht
einen Endpoint, der Start- UND Endbild **getrennt** annimmt. Im Haus belegt, Feldnamen live aus der
OpenAPI-Route abgelesen: `fal-ai/kling-video/v3/pro/image-to-video` und
`fal-ai/kling-video/o1/image-to-video` (`start_image_url` required, `end_image_url` optional), dazu
die nativen FLF-Endpoints `fal-ai/veo3.1/first-last-frame-to-video` (ebenso `/fast/...`, `/lite/...`)
und `fal-ai/wan-flf2v` (beide Frames Pflicht). Vollständige Tabelle mit Feldnamen und Preisstaffel:
`skill:scroll-world`, `SKILL.md` Abschnitt "Asset-Generierung". Vor Nutzung nach der Prüfmethode
oben zweiroutig nachprüfen — `fal-ai/wan/v2.7/image-to-video` aus der Tabelle oben ist der Kandidat
aus dieser Datei, der `image_url` + `end_image_url` annimmt (Input-Schema `WanV27ImageToVideoInput`
am 2026-09-22 über die OpenAPI-Route gelesen, beide Felder optional; zum Vergleich trägt
`fal-ai/veo3.1` ohne Suffix gar kein Bildfeld — die Basis-ID ist `text-to-video`).

**Die Naht prüfen — mit EINEM Instrument, nicht mit einem zweiten.** Die Nahtprüfung ist im Haus
bereits kanonisch und laufbereit: `skill:scroll-world`, `references/pipeline.md` Abschnitt 7 —
browser-freies `seam_check()` (ffmpeg-Frameextraktion + PSNR), Skala `>~40 dB = frame-tight`. Sie
gilt auch für die Loop-Naht; hier wird **keine zweite Skala** aufgemacht. Zwei Zusätze gelten nur
für den Loop:

1. **Der Maßstab ist relativ.** Der Loop ist gut, wenn die Loop-Naht IM FELD der inneren Nähte
   derselben Kette liegt — nicht, wenn sie eine absolute Schwelle reißt.
2. **Wer statt PSNR eine Ähnlichkeitszahl wie SSIM nimmt, kalibriert sie vorher.** Referenzpunkte
   EINES solchen Aufbaus (Konsumentenmessung, nicht agent-cores Skala): identische Frames 1,0000 ·
   verlustbehaftetes Re-Encode 0,93 · **3 px Versatz 0,3017**. Drei Pixel drücken den Wert auf 0,30
   — wer ohne diese Skala misst, hält 0,93 für "fast identisch". PSNR und SSIM sind zwei
   Instrumente für dieselbe Größe: nie Zahlen aus beiden gegeneinander lesen.

**Belegter Lauf mit Geltungsbereich, damit niemand mehr ableitet als gemessen wurde.**
Konsumentenprojekt, 2026-09-08/10, sieben Clips, in agent-core nicht nachstellbar: Loop 70,29 s ·
Loop-Naht SSIM 0,9872 · sieben innere Nähte 0,9885-0,9893 · Kamera-Drift über zehn Stichproben
0,8052-0,8227 ohne Trend · 9,08 $ für diesen einen Lauf, kein Tarif. Geltungsbereich: EINE
Motivgattung (Architektur/Umgebung, statische Kamera, zyklische Bewegung), EIN Videomodell in der
Anker-Rolle (vom Melder nicht benannt — die Kostenzahl lässt mindestens drei Endpoints zu), kein
Vergleich gegen Crossfade unter sonst gleichen Bedingungen.

## Texture Tileability

Flux is NOT tileable by default. Three approaches:

1. **Prompt trick**: `"seamless tileable texture, repeating pattern, no borders, top-down view"`
2. **Sharp post-process**: mirror-mode tile in `optimize.ts`
3. **Tile-Texture-LoRA** via `fal-ai/flux-lora` ($0.035 pro Megapixel, aufgerundet auf volle MP) —
   most precise but more setup
