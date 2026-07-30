# Cost Model Reference

> **Stand:** 2026-07-23 — Preise schwanken; vor jeder groesseren Kalkulation aktuelle fal.ai-Pricing-Seite gegenpruefen.
>
> **KORREKTUR 2026-07-23:** Alle Zahlen unten waren zu niedrig, weil die Video-Zeile mit $0.05/s
> gerechnet hat (real: $0.10/s @720p, $0.15/s @1080p) und weil zwei Endpoint-IDs tot waren
> (`flux-2/pro` → `fal-ai/flux-2-pro`, `wan/v2.6` → `fal-ai/wan/v2.7/text-to-video`). Preisquelle und
> Pruefmethode: `references/01-fal-models.md`.

## Build-time Hero (one-shot)

| Asset | Endpoint | Price |
|---|---|---|
| 3D model | `fal-ai/hyper3d/rodin` | $0.40 pro Generation |
| Fallback image | `fal-ai/flux-2-pro` | $0.03 bei 1 MP Output (jedes weitere MP +$0.015) |
| Panorama | `fal-ai/flux-2-pro` | $0.03 als Untergrenze — 2048×1024 sind ≈2,1 MP → 3 MP aufgerundet, also mehr |
| 5 s loop video | `fal-ai/wan/v2.7/text-to-video` | $0.50 @720p ($0.10/s) · $0.75 @1080p ($0.15/s) |
| **Single run** | | **$0.96 @720p · $1.21 @1080p** |

Beide `fal-ai/flux-2-pro`-Zeilen sind Untergrenzen. Beim Panorama steht die Aufloesung sogar fest
(2048×1024), liegt also sicher ueber 1 MP — der Single-Run liegt damit real ueber den $0.96–1.21,
sobald mit der tatsaechlichen Zielaufloesung gerechnet wird.

Design iteration realistic: 10–30 generations until final → **$10–36 Hero-Budget**
(10–30 × $0.96–1.21).

## Runtime (monthly, scaled with traffic)

Base scenario: 10k page views/month, 80 % cache-hit rate.

| Item | Endpoint | Calculation | Cost |
|---|---|---|---|
| Dynamic 3D (2k unique) | `fal-ai/hunyuan-3d/v3.1/rapid/text-to-3d` | $0.225 × 2000 | $450 |
| Textures (5k unique) | `fal-ai/flux/schnell` | $0.003 × 5000 (pro MP, aufgerundet) | $15 |
| Dynamic images (1k) | `fal-ai/flux-2-pro` | $0.03 × 1000 (erstes MP) | $30 |
| Video loops (100 × 5 s) | `fal-ai/wan/v2.7/text-to-video` | $0.50 × 100 @720p · $0.75 × 100 @1080p | $50–75 |
| R2 storage (~50 GB) | — | $0.015/GB | $0.75 |
| Upstash Redis | — | free tier or | $0–10 |
| Backend hosting (Fly/Railway) | — | | $5–20 |
| **Total / month** | | | **~$550–600** |

Die Spanne $550–600 ist gerundet und kommt aus drei Achsen zugleich: Video-Aufloesung (720p vs.
1080p), Redis-Tier und Hosting-Tier. Aufloesungen ueber 1 MP bei Texturen und Bildern sind darin
**nicht** eingepreist — die Zeilen `fal-ai/flux/schnell` und `fal-ai/flux-2-pro` rechnen mit 1 MP.

## Sensitivity

- Cache-hit 30 % instead of 80 % → costs ×3–4
- Pro statt Rapid fuer dynamisches 3D → ($0.375 − $0.225) × 2000 = **+$300/Monat**
- 1080p statt 720p bei den Video-Loops → +$25/Monat (100 × $0.25 Aufpreis)
- **No rate-limit + bot at 10 req/s × 24 h × $0.225 = $194 400 in ONE day**

## Optimizations

1. Spending limit in fal dashboard (daily cap)
2. Prompt normalization (lowercase, trim, stopword removal) to improve cache-hit
3. Tiered model selection (preview tier for low-stakes, pro tier only when needed)
4. R2 over S3 (zero egress for asset serving)
5. AVIF over WebP over PNG (60 % smaller typical)
6. Draco compression on GLB (60–90 % size reduction)
7. Zielaufloesung bewusst waehlen — die Flux-Preise sind Pro-Megapixel-Preise mit Aufrundung auf
   volle MP, und Video staffelt nach 720p/1080p/4K. Eine unbedacht hochgesetzte Aufloesung
   vervielfacht die Rechnung ohne sichtbaren Gewinn.
