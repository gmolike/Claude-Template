# PROVENANCE — scroll-world

Dieser Skill wurde aus einem externen Repository übernommen ("gevendort") und
lokal angepasst. Diese Datei hält Herkunft, gepinnten Stand, Lizenz, die lokal
vorgenommenen Änderungen und den Update-Pfad fest. Die wörtliche Lizenz-Notice
steht in der Repo-Root-Datei `NOTICE.md`.

## Herkunft

- **Upstream:** https://github.com/oso95/scroll-world (`oso95/scroll-world`)
- **Gepinnter Commit:** `2912048246d057cdfe134dfc0b4dfb7e6a12f30e`
- **Stand/Datum:** 2026-07-16
- **Lizenz:** MIT (wörtliche Copyright-/Permission-Notice: siehe `NOTICE.md` im
  Repo-Root, Abschnitt "scroll-world").
- **Upstream-Layout an diesem Commit:**
  - `skills/scroll-world/SKILL.md`
  - `skills/scroll-world/references/prompts.md`
  - `skills/scroll-world/references/pipeline.md`
  - `skills/scroll-world/references/scrub-engine.js`
  - `skills/scroll-world/references/index-template.html`
  - `skills/scroll-world/references/knockout.py`

## Wortgetreu übernommene Dateien (byte-identisch zum Upstream)

Beleg: byte-genau via GitHub-Contents-API (`Accept: application/vnd.github.raw`)
am gepinnten Commit geholt; sha256 des Inhalts:

| Lokale Datei | Upstream-Pfad | sha256 |
| --- | --- | --- |
| `references/index-template.html` | `skills/scroll-world/references/index-template.html` | `b59814abbe21bff1f39321eb53f9c9cd8ddf9d6a16fc861558647bf30213e3c0` |
| `references/knockout.py` | `skills/scroll-world/references/knockout.py` | `c06bfc916592ba4f3dfd3e37070b20529298707ca3f94c9dcc51d508222e7792` |

- `index-template.html` wurde auf Higgsfield-spezifische Kommentare/URLs geprüft
  (keine gefunden) und bleibt offline-/`file://`-tauglich: ausschließlich relative
  Pfade (`scrub-engine.js`, `assets/…`), kein externes CDN, kein Remote-Asset.
- `knockout.py` ist das unveränderte reine-PIL-Skript (border-connected
  Background-Knockout für Diorama-Stills; keine numpy-/ImageMagick-Abhängigkeit).

## Lokale Änderungen gegenüber dem Upstream

Die folgenden Anpassungen unterscheiden diesen Vendor-Stand vom Upstream. Der
autoritative Diff je Änderung ist die Git-Historie dieses Branches; diese Liste
ist der inhaltliche Index dazu.

- **fal.ai-Rewrite:** Die Bild-/Video-Generierungspipeline (Prompts und Pipeline)
  wurde von der ursprünglich Higgsfield-orientierten Vorlage auf fal.ai
  First-Last-Frame-Endpunkte umgeschrieben.
- **Teardown-Patch:** Ergänzt bzw. korrigiert das saubere Abräumen (Teardown) der
  Scroll-Engine im Mount-Lifecycle (`mountScrollWorld`), damit Ressourcen/Listener
  beim Unmount deterministisch freigegeben werden.
- **A11y-Patch:** Barrierefreiheits-Anpassungen (u.a. Bewegungsreduktion via
  `prefers-reduced-motion`, semantische/fokussierbare Bedienelemente).
- **Gekürzte `SKILL.md`:** Die `SKILL.md` wurde gegenüber dem Upstream gestrafft;
  schwere Details liegen in `references/` (Repo-Konvention: schlanke `SKILL.md`,
  Tiefe in `references/`).

Die wortgetreu übernommenen Dateien (`references/index-template.html`,
`references/knockout.py`) sind von diesen Änderungen **nicht** betroffen.

## Update-Pfad

Der Upstream führt **keine Tags/Releases** — der Stand ist ausschließlich über
den Commit-SHA gepinnt. Zum Aktualisieren:

1. Neuen Upstream-Commit auf `oso95/scroll-world` bestimmen.
2. Manuellen Diff des Upstream gegen den bisher gepinnten Commit
   `2912048246d057cdfe134dfc0b4dfb7e6a12f30e` bilden (kein Tag-Vergleich möglich).
3. Die wortgetreuen Dateien neu ziehen (byte-genau, z.B. via
   GitHub-Contents-API `Accept: application/vnd.github.raw`) und ihren sha256
   gegen die obige Tabelle prüfen; bei Abweichung Tabelle aktualisieren.
4. `index-template.html` erneut auf Higgsfield-spezifische Kommentare/URLs prüfen
   und ggf. neutralisieren; `file://`-Tauglichkeit (nur relative Pfade) sichern.
5. Die lokalen Patches (fal.ai-Rewrite, Teardown, A11y, `SKILL.md`-Kürzung) erneut
   auf den neuen Stand anwenden.
6. Gepinnten Commit + Datum hier **und** in `NOTICE.md` aktualisieren.
