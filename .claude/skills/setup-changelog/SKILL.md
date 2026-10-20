---
name: setup-changelog
description: 'Changelog + Versionierung + Release-Mechanik in einem Projekt aufsetzen und standardisieren: Keep-a-Changelog-Standard, ein Version-Bump-Scaffold (greift auch bei Hand-Commits), Mechanismus-Wahl (fail-loud CI-Gate ODER Changesets) und eine konfigurierbare Merge-/Branch-/Release-Policy (Default trunk-based). Nutze, wenn ein Projekt Changelog, SemVer-Bump oder Release-Automation einrichten, reparieren oder vereinheitlichen will — und ebenso, wenn ein geteiltes Paket veröffentlicht oder ein Konsument auf eine neue Version gehoben wird (Changeset-Level und Konsumenten-Bump).'
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Setup Changelog

Dieses Skill richtet den **Changelog-, Versionierungs- und Release-Standard** in einem beliebigen
Projekt ein. Es verallgemeinert das Muster, das agent-core selbst fährt (`CHANGELOG.md` im
Keep-a-Changelog-Format, SemVer-Bump mit der Änderung, tag-getriggerter Release-Workflow mit
`tag == package.json version`-Gate), zu einem **wiederverwendbaren** Rezept.

> **agent-core liefert keine Datei aus, nur das Rezept.** Die vier Scaffolding-Dateien stehen
> **wörtlich und vollständig** im Anhang unten und werden im Zielprojekt selbst angelegt — kein
> `assets/`-Verzeichnis, kein Kopiervorgang aus dem Skill heraus. Das ist Absicht: ein ausgeliefertes
> Skript ist eine zweite Kopie, die still von diesem Rezept wegdriftet.

> **Paketmanager-neutral.** Das Skill setzt keinen bestimmten Paketmanager voraus: Mechanismus A
> (Default) braucht **gar keinen** — pures `node` + `npx`, dependency-frei; Mechanismus B (Changesets)
> läuft gleichwertig mit **npm, pnpm oder yarn**. Die Beispiele nutzen **npm** bzw. `npx`; das
> pnpm-/yarn-Äquivalent ist trivial (`pnpm changeset` / `yarn changeset`).

> **Prosa deutsch, Code/Identifiers/Commit-Prefixe englisch** (Repo-Konvention). Alle Datei- und
> Feldnamen, `feat:`/`fix:`-Prefixe und Script-Bezeichner bleiben englisch.

## Wann invoken

- Ein Projekt hat **keinen** oder einen inkonsistenten Changelog / keine Versionsdisziplin.
- Der Version-Bump passiert nicht zuverlässig (fehlt bei Hand-Commits, „reitet einen Commit hinterher").
- Es ist unklar, **welcher Merge wohin** einen Bump/Tag/Prerelease auslöst.
- Ein Changelog-/Release-Setup soll gegen die Standards vereinheitlicht werden.
- Ein geteiltes Paket wird **veröffentlicht**, oder ein Konsument wird auf eine neue Version **gehoben**.

## Der Standard (non-negotiable)

Diese Punkte gelten **immer**, egal welcher Mechanismus (siehe unten) gewählt wird:

- **Keep a Changelog + SemVer.** `CHANGELOG.md` beginnt mit dem Kopf, der auf
  [keepachangelog.com](https://keepachangelog.com/) **und** [semver.org](https://semver.org/) verlinkt
  (Anhangsblock `CHANGELOG.template.md`).
- **`[Unreleased]` ist immer aktuell** — auf **demselben** Commit wie der Code, **ob Hand-Commit ODER
  Agent**. Ein Change ohne Changelog-Zeile ist unfertig.
- **Kategorien:** `Added` · `Changed` · `Deprecated` · `Removed` · `Fixed` · `Security` — genau diese
  Namen, ungenutzte weglassen.
- **SemVer-Bump mit der Änderung.** `feat` → **minor**, `fix`/`perf` → **patch**, `type!:` oder ein
  `BREAKING CHANGE:`-Footer → **major**. Bump und Changelog-Finalisierung passieren **zusammen**, nie
  eines ohne das andere.
- **Compare-Links im Footer.** Am Dateiende hält eine `[Unreleased]:`-Zeile auf den neuesten Tag, plus
  je Release eine `[x.y.z]:`-Compare-Zeile (`.../compare/vPREV...vX.Y.Z`; die erste Version verlinkt
  auf die Tag-Seite, da es keinen Vorgänger gibt).
- **`CHANGELOG.md` bleibt eine gerenderte Markdown-Datei.** Sie ist die Quelle der Wahrheit im Repo.
  Optionales Website-Muster (wie in agent-core): den `CHANGELOG.md`-Blob beim Release in eine
  DB-Zeile (z. B. Supabase `site_meta`) spiegeln und im Frontend via `react-markdown` rendern — die
  Datei bleibt SSOT, die Website ist nur ein Renderer.
- **Tagging ist ein deliberater Schritt.** `[Unreleased]` aktuell halten und frei auf `main` committen
  ist gratis; ein **getaggter Release** triggert CI (Publish/Bundle/Seed) und **kostet** — also
  **batchen** und **auf Go-ahead / Meilenstein** taggen, nie reflexartig pro Patch. Wenn Changes
  shippable sind: **Release-Pending flaggen**, den Menschen taggen lassen.

## Breaking ist eine Eigenschaft des Konsumenten, keine Meinung des Autors

Die Level-Ableitung oben beschreibt, was das **Paket** tut — nicht, was beim **Konsumenten** rot wird.
Gemessen an `@flammenreiter/shared` 9.54.0 → 9.56.0 (2026-08-22/23): neun Changesets, **alle** als
`minor` deklariert, im CHANGELOG-Abschnitt genau eine `### Minor Changes`-Überschrift und keine Patch-
oder Major-Überschrift. Zwei Konsumenten scheiterten am **reinen** Versionssprung gegen den
unmittelbaren Vorgänger `^9.54.0` (api: 1 Typecheck-Fehler, session-gm: 3, beide mit `^9.54.0`: 0);
ein dritter (lore-admin, 4 Fehler) sprang von `^9.20.0` und mass damit 36 Minors auf einmal.

Vor dem Setzen des Levels genau eine Frage — **welches Feld eines veröffentlichten Schemas ändert
Form, Pflichtigkeit oder Wertebereich?** — und vier Formen, in denen sie mit ja beantwortet ist:

1. **Neues Pflichtfeld in einem Response-/Wire-Schema.** `nullable` ist **nicht** `optional`: der
   Schlüssel bleibt in `z.infer` Pflicht, und jeder Handler, der das Objekt baut, wird rot (gemessen:
   ein `.nullable()`-Objektfeld → TS2345, „Property … is missing in type … but required in").
2. **Erweitertes Enum.** Jede exhaustive `Record<Enum, …>` beim Konsumenten wird rot — und jede, die
   *nicht* rot wird, ist ein `Record<string, …>` und damit ein zweiter Befund: dort waren 8 von 16
   Werten in der UI gar nicht auswählbar, darunter der mit 37 von 86 Datensätzen größte.
3. **Verengung `z.string()` → Literal-Union.** Bricht `useState('side')`-Inferenzen und
   `(value: string) => void`-Signaturen fremder Bibliotheken, nicht nur eigene Zuweisungen. **Beide
   Richtungen gehören genannt:** dieselbe Verengung hat in denselben zwei Frontends zwei stille
   Produktionsdefekte aufgedeckt (ein Vergleich gegen einen Status, den es nie gab — TS2367; und die
   8 unauswählbaren Werte aus Punkt 2). Die Form ist für Konsumenten teuer und trotzdem richtig: sie
   ist `major`, nicht verboten.
4. **`nullable`/`optional` → required an einem bestehenden Feld.**

Trifft eine der vier zu, ist der Level `major` — auch wenn kein Commit ein `!` trägt. **Und das wirkt
nur, weil eine `^`-Spanne einen Major ausschließt:** der Bruch kann dann nicht mehr durch ein bloßes
Re-Resolve ankommen, der Konsument hebt die Spanne bewusst und in seinem eigenen Takt. Ohne diesen
Mechanismus ist „major" ein Etikett ohne Wirkung — im gemessenen Fall hätte es keinen der Bumps
verhindert, weil alle vier Konsumenten die Spanne ohnehin von Hand angehoben haben.

Der **dauerhafte** Schutz liegt beim Konsumenten und wurde dort zweimal unabhängig gefunden: die
Label-/Icon-Tabellen an `Record<Enum, …>` binden (der Compiler prüft Vollständigkeit) **und** ein
Laufzeittest, der dieselben Tabellen gegen das Enum vergleicht. Ein Typ-only-Test taugt dafür nicht,
wo Tests vom Typecheck ausgenommen sind — Muster und RED-Pflicht in `skill:contract-golden-test`.

## Entscheidungshilfe: welcher Mechanismus

Zwei tragfähige Wege. **Default ist A** (weniger Abhängigkeiten, passt zu Single-Package und kleinen
Repos). **B (Changesets)** ab dem Moment, wo mehrere veröffentlichte Pakete im Monorepo je eigen
versioniert werden.

| Kriterium | **A — Hand + fail-loud CI-Gate** (Default) | **B — Changesets** |
|---|---|---|
| Wer schreibt den Eintrag | Mensch **oder** Agent, direkt in `CHANGELOG.md#[Unreleased]` | Mensch **und** Agent, gleicher Handgriff: `npx changeset` (npm/pnpm/yarn) |
| Bump-Ableitung | `version-bump.mjs` aus Conventional Commits | `changeset version` aus den `.changeset/*.md` |
| Monorepo, je Paket eigene Version | mühsam (ein Changelog) | **nativ** (per-Paket Changelog + Bump) |
| CI-Gate (fail-loud) | „`[Unreleased]` berührt, wenn Code geändert" | `changeset status --since=origin/main` (**required**) |
| Git-Hook nötig | **nein** — Default ist der Release-/CI-Bump; `pre-commit` nur als Opt-in mit `--stage` | **nein** — kein Hook, keine Snapshot-Falle |
| Extra-Dependency | keine (dependency-freies `.mjs`) | `@changesets/cli` |
| Kombinierbar mit dem anderen | **nein** | **nein** — B gewinnt, A muss raus |
| Ehrliche Schwäche | Gate ist durch **eine Whitespace-Zeile** erfüllbar → **nie 100 % fail-loud** | leerer Changeset (`--empty`) ist ein Loch → im Gate ablehnen |

> **A und B schließen einander AUS — genau EIN Bump-Mechanismus pro Repo.** Laufen beide, ist
> `package.json` keine SSOT mehr: Bump-Script und `changeset version` schreiben dasselbe Feld, und CI
> publisht genau `package.json`. **Existiert beides, gewinnt B** — Changesets besitzt dann die
> Version, der Per-Commit-Bump muss **entfernt** werden. Das ist nicht mehr nur Doku:
> `version-bump.mjs` (Anhang) erkennt `.changeset/config.json` und macht
> **no-op + laute Meldung + exit 0** (ADR-0024, Fail-loud-Notiz 5).

### A — handgeschrieben + fail-loud CI-Gate (Default)

- `[Unreleased]` wird **von Hand** (oder vom Agenten) gepflegt.
- Ein **CI-Check wird rot**, wenn geänderte Pakete `[Unreleased]` nicht angefasst haben — Job A im
  Anhangsblock `changelog-guard.yml`.
- **commitlint** erzwingt die Commit-Grammatik (Anhangsblock `commitlint.config.mjs`),
  die die Bump-Ableitung liest.
- Ein **`version-bump`-Script** (Anhangsblock `version-bump.mjs`) leitet den
  SemVer-Level aus den Commits ab, bumpt `package.json`, verschiebt `[Unreleased]` → `[x.y.z] - <date>`
  und ergänzt den Compare-Footer. **Es läuft standardmäßig beim Release, nicht bei jedem Commit**;
  nur der Opt-in-Hook braucht `--stage` (Scaffolding-Schritt 3, Fail-loud-Notiz 6).
- **Ehrlich dokumentieren:** Der Gate prüft nur, **dass** `[Unreleased]` berührt wurde — **eine
  Whitespace-Änderung erfüllt ihn**. Er fängt das „Changelog komplett vergessen"-Versagen, **nicht**
  einen faulen oder falschen Eintrag. Er ist ein Stolperdraht, **kein** Beweis eines guten Changelogs.

### B — Changesets

- `npx changeset` (bzw. `pnpm changeset`; Mensch **und** Agent, **gleicher** Handgriff) legt eine
  reviewbare `.changeset/*.md` mit Paket + Bump-Level an.
- `changeset version` erzeugt beim Merge der **Version-PR** `CHANGELOG` **und** Bump; `changeset publish`
  veröffentlicht.
- `changeset status --since=origin/main` als **REQUIRED CI-Check** (fail-loud) — Job B im
  Anhangsblock `changelog-guard.yml`.
- **Monorepo-first**, **KEIN Git-Hook** (damit keine Snapshot-Falle, siehe unten).
- **Ein vorhandener Per-Commit-Bump-Hook MUSS weg** — entfernen oder auf no-op stellen, bevor
  Changesets scharf geschaltet wird. Ein `post-commit`/`pre-commit`-Bump neben Changesets ist genau
  der Fall aus Fail-loud-Notiz 5. `version-bump.mjs` **erzwingt
  das inzwischen selbst**: es erkennt `.changeset/config.json` und beendet sich als **no-op mit lauter
  stderr-Meldung + exit 0** (nie still, nie blockierend). Der Escape `--force-with-changesets` umgeht
  den Guard **bewusst und geloggt** — er ist ein Notausgang, keine Betriebsart.
- **`fetch-depth: 0`** im Checkout ist nötig — sonst ist `origin/main` unerreichbar und der Check
  passiert **still** auf nichts (fail-open).
- **Leerer Changeset (`--empty`) ist ein Loch** → im selben CI-Schritt ablehnen oder als **explizit
  geloggten** Escape behandeln (nie stillschweigend).
- **Custom Keep-a-Changelog-Formatter** verdrahten (`@changesets/changelog-*` bzw. eigener), damit die
  MD-Hausform (`Added/Changed/…`) **und** die Prosa-Intros pro Release erhalten bleiben — die
  Default-Ausgabe ist eine flache Bullet-Liste ohne Kategorien.

## Branch-/Merge-/Version-Policy (konfigurierbar)

> **Dieses Modell MUSS pro Projekt einmal festgelegt und hier — im projektlokalen Skill bzw. in der
> `CLAUDE.md`/`project-standards.md` — eingetragen werden.** Ohne festgelegtes Modell ist „was löst
> einen Bump/Tag aus" undefiniert, und der Bump reitet Commits hinterher oder passiert doppelt.

### Default — trunk-based

| Merge / Aktion | Was passiert | Bump? | Tag? | Prerelease? | Wer |
|---|---|---|---|---|---|
| `feat/*` → `main` (squash) | Feature landet, `[Unreleased]` ist bereits gepflegt | **Bump vorbereitet + Release-Flag** | nein | nein | Agent/Mensch (Bump), CI (Gate) |
| Commit direkt auf `main` | `[Unreleased]` mitgepflegt | optional (`version-bump`) | nein | nein | Mensch/Agent |
| **Tag `vX.Y.Z`** setzen | CI: publish + bundle + seed | ist schon gebumpt | **ja** | nein | **Mensch (Go-ahead)** |

- **`never-push-main` ohne Freigabe** — besonders bei Auto-Deploy-Targets (z. B. Cloudflare Pages).
- **Tag = deliberater Schritt** mit explizitem Go-ahead; er triggert den kostenpflichtigen Release.
- Das CI-Release-Gate spiegelt agent-cores `release.yml`: Trigger **nur** auf `push` von Tags `v*`, mit
  Vorab-Check **`tag == package.json version`** (bricht laut ab, wenn sie divergieren).

### Opt-in — Gitflow (`develop` → `main`)

| Merge / Aktion | Was passiert | Bump? | Tag? | Prerelease? | Wer |
|---|---|---|---|---|---|
| `feature/*` → `develop` | sammelt Changes, `[Unreleased]` pflegen | nein | nein | optional Channel `next` | Agent/Mensch |
| Push auf `develop` | Prerelease-Publish möglich | Prerelease-Bump | `vX.Y.Z-next.N` | **ja** (`next`-Channel) | CI |
| `develop` → `main` | stabiler Release | Finaler Bump | **ja** (`vX.Y.Z`) | nein | **Mensch (Go-ahead)** |

- Prerelease/Channel lebt auf `develop`; der **stabile** Release entsteht beim Merge auf `main`.
- Bei Changesets: `changeset pre enter next` / `pre exit` steuert den Prerelease-Modus.

## Der Konsumenten-Bump: typecheck, dann build, dann tests

„Spanne hoch, Lockfile dazu, committen" ist ein ungeprüfter Bump. Je Konsument lokal, in dieser
Reihenfolge, **vor** dem Merge:

- **`typecheck` zuerst** — findet die vier Formen oben, bevor ein Testlauf Zeit kostet.
- **`build` als eigener zweiter Schritt**, nicht als Nebenprodukt von CI. Er sieht, was `tsc` nie
  sieht: Bundler-Plugins über dem Fremdpaket, Tree-Shaking, Env-Baking. Gemessener Fall: ein eigenes
  Vite-Plugin entfernte `.openapi(…)` per Klammerzählung und zerbrach an einem `a)` **innerhalb** einer
  Schema-Beschreibung — `typecheck` 0 Fehler, 620 Tests grün, `build` `[PARSE_ERROR]`. Die Klammer war
  dabei **nicht neu**: die betroffene Quelldatei ist über die drei fraglichen Tags hinweg
  sha256-identisch. Der Konsument lag 36 Minors zurück und konnte seinen eigenen Rotlauf deshalb nicht
  mehr zuordnen — **die Spanne aktuell zu halten ist Teil des Verfahrens**, nicht Kosmetik.
- **`tests` zuletzt** — und erst danach ist der Bump geprüft.

**Der pre-push-Hook ist nicht dieser Schritt.** In allen vier Konsumenten des gemessenen Falls fährt
`.husky/pre-push` `typecheck` + `test` und **kein** `build` (4 von 4, 2026-09-16 gemessen). Wo
zusätzlich `ci.yml` auf `disabled_manually` steht — dort ebenfalls 4 von 4 —, baut in GitHub Actions
gar nichts; in zweien ist auch der Deploy-Workflow abgeschaltet, erstes bauendes Gate ist dann die
Git-Integration des Hosters **außerhalb** von GitHub. Genau so fiel ein gebrochener Build erst am
**ausbleibenden** Deploy auf. Konsequenz: `typecheck && build && test` je Konsument lokal vor dem
Merge, und `build` gehört in den pre-push-Hook.

## Fail-loud-Notizen

Cross-Ref: `shared/memory/00-knowledge.md` (agent-cores gesammelte Gotchas) und `30-quality`
(Fail-loud-Prinzip: ein Gate mit gebrochener Vorbedingung wird ROT/LAUT, nie grün).

1. **Git snapshottet den Commit-Tree VOR `prepare-commit-msg`.** `prepare_to_commit()` ruft
   `update_main_cache_tree()` **vor** dem Hook und liest danach nie neu. Ein **Index-Schreibvorgang**
   beim Bump — `--stage` heute, `git add` im alten Rezept — fällt **NUR in `pre-commit`** in den
   laufenden Commit; in `prepare-commit-msg`/`commit-msg` **leakt** er in den **NÄCHSTEN** Commit
   („reitet einen Commit hinterher", oft mit `git commit --amend --no-edit` gepflastert). → Bump
   **nur in `pre-commit` ODER in CI**, **nie in `commit-msg`**. Diese Notiz beantwortet **wo**
   gestaged werden darf; **wie viel** beantwortet Notiz 6, und die Antworten sind unabhängig
   voneinander — `pre-commit` allein macht ein `git add` nicht harmlos.
2. **Windows / Git-Bash: mehrzeiliges `node -e` läuft leer und exit 0.** Ein Inline-Bump per
   `node -e "…"` „passiert" grün, ohne etwas zu tun. → Bump-Logik in eine **`.mjs`-Datei** legen und
   als `node scripts/version-bump.mjs` aufrufen (genau das ist der Anhangsblock `version-bump.mjs`).
3. **Commit-Message mit `-F <file>` statt `-m` bei deutscher Prosa/Backticks.** Git-Bash führt
   Backticks in `git commit -m "… \`x\` …"` als Command-Substitution aus und korrumpiert die Message. →
   für Messages mit Markdown/Backticks `git commit -F <file>`. **Ein message-lesender Marker-Hook
   (z. B. der Release-Flag- oder Bump-Trigger) muss auch den `-F`-Pfad lesen**, nicht nur `-m`.
4. **commitlint/husky-Hook-Pfade auf Windows.** Husky-Hooks laufen über Git-Bash; `.mjs`/PowerShell
   nicht mischen. `commit-msg` ruft `npx --no-install commitlint --edit "$1"`; der Bump-Hook ist ein
   **`pre-commit`**-Hook (siehe Punkt 1). `core.hooksPath` prüfen, wenn Hooks nicht feuern.
5. **Zwei Bump-Quellen in einem Repo ⇒ `package.json` ist keine SSOT mehr.** Verifiziert
   (Flammenreiter): ein Per-Commit-Bump-Hook (husky `post-commit` → `version-bump.mjs`) schob
   `@flammenreiter/shared` von published **9.0.1** auf lokal **9.2.0**, während Changesets **9.1.0**
   berechnet hatten. Beide Mechanismen liefen im selben Repo — die korrekte Publish-Version war aus
   `package.json` nicht mehr ablesbar, und CI publisht genau `package.json`. → **Genau ein
   Bump-Mechanismus pro Repo** (A **oder** B, siehe Matrix). `version-bump.mjs` erkennt das inzwischen
   selbst und macht **no-op + laute Meldung + exit 0** — laut statt still (`30-quality`), aber **kein**
   harter Fehler, der laufende Commits blockieren würde (ADR-0024).
6. **Wer eine GANZE Datei staged oder amendet, erbt jede ungestagte fremde Zeile darin.** `git add`
   staged eine **Datei**, nie eine Zeile — es kann den Bump nicht von dem unterscheiden, was sonst
   noch offen in derselben Datei liegt. Verifiziert am 2026-08-05 in einem Wegwerf-Repo
   (`core.autocrlf=true`): fremde, **ungestagte** Dependency-Änderung im Arbeitsbaum, gewollt im
   Commit ist nur `other.ts`. Mit `pre-commit` + `git add package.json CHANGELOG.md` trägt
   `git show HEAD:package.json` danach `"left-pad": "9.9.9"` **und** `"chalk": "5.0.0"`
   (`package.json | 5 +++--`); mit `git commit --amend --only -- package.json` dasselbe **plus** eine
   neue Commit-SHA — die Kurz-SHA, die `git commit` gerade ausgegeben hat, zeigt danach ins Leere.
   Nicht `--amend` ist die Ursache, sondern das Ganzdatei-Staging. → **Der Hook staged nichts.**
   `version-bump.mjs --stage` schreibt die Versionszeile selbst in den Index (`git ls-files -s` +
   `git cat-file blob` → `git hash-object -w` → `git update-index`); das Ergebnis ist
   `package.json | 2 +-`, und die fremde Zeile steht danach unverändert als ungestagt im
   `git status`. Ohne `--stage` **nennt** das Script die fremden Zeilen und warnt vor genau diesem
   `git add`. **`--amend` in einem Hook ist verboten** — es schreibt bei jedem Commit die SHA um,
   also systematischer History-Rewrite ohne Freigabe (`20-workflow`). **Ehrliche Grenze:** ein
   Consumer-Hook, der den Bump **selbst rechnet**, statt dieses Script aufzurufen, wird von `--stage`
   nicht erreicht — dort trägt allein dieses Rezept.

## Scaffolding-Schritte

Das Skill **schreibt** — je nach Mechanismus — diese Dateien im Zielprojekt aus dem Anhang unten und
verdrahtet sie. Es kopiert nichts aus agent-core heraus; jeder Block ist vollständig und abtippfähig:

**Immer:**

1. `CHANGELOG.md` aus dem Anhangsblock `CHANGELOG.template.md` (Kopf,
   `[Unreleased]`, leere Kategorien, Compare-Footer) — `OWNER/REPO` ersetzen.
2. `commitlint.config.mjs` aus dem Anhangsblock `commitlint.config.mjs`; als
   `commit-msg`-Hook verdrahten.

**Mechanismus A (Default):**

3. `scripts/version-bump.mjs` aus dem Anhangsblock `version-bump.mjs` — an
   Monorepo-Pfade/Tag-Prefix anpassen. **Default ist der Release-/CI-Bump, nicht der Hook:** von Hand
   oder im Release-Job laufen lassen, Diff ansehen, als `release: vX.Y.Z` committen. agent-core selbst
   fährt genau so und betreibt deshalb **keinen** Bump-Hook.

   **Der `pre-commit`-Hook ist Opt-in und hat drei Vorbedingungen.** Ist eine nicht erfüllt, bleib beim
   Release-Bump:
   - **Er ruft das Script mit `--stage` auf und staged selbst nichts** — kein `git add`, kein
     `--amend` (Fail-loud-Notiz 6).
   - **Nur `pre-commit`**, nie `prepare-commit-msg`/`commit-msg` (Fail-loud-Notiz 1).
   - **Der abgeleitete Level ist im `pre-commit` systematisch unvollständig:** der Commit, den du
     gerade schreibst, steht noch nicht in `git log` — seine Message existiert dort noch gar nicht.
     Ein `feat:` hebt also erst beim **nächsten** Commit auf minor, und der erste Commit nach einem
     Tag hat überhaupt keine Range (das Script macht daraus einen lauten No-op mit exit 0, statt den
     Commit zu blockieren). Wer den Level exakt braucht, nimmt den Release-Bump.

   Der Hook-Body steht **wörtlich** hier — er ist der einzige Ort, an dem der `git add`-Umfang als
   Artefakt existiert, und `src/targets/version-bump.golden.test.ts` führt genau diesen Block aus:

   <!-- BEGIN pre-commit-hook -->
   ```sh
   #!/bin/sh
   # .husky/pre-commit — SemVer-Bump + Changelog-Roll, zeilengenau gestaged.
   # NIEMALS `git add` oder `--amend` hier ergaenzen: beide stagen die GANZE Datei und
   # falten jede ungestagte Zeile in diesen Commit (Fail-loud-Notiz 6 / TRAP 4).
   node scripts/version-bump.mjs --stage
   ```
   <!-- END pre-commit-hook -->

   Der Exit-Code des Scripts ist der des Hooks: `0` in jedem „konnte nicht" (Changesets erkannt,
   leere Range, Index nicht vorbereitbar), `≠ 0` nur bei einem echten Fehler. Ein Bump ist es nicht
   wert, einen Commit zu blockieren.
4. `.github/workflows/changelog-guard.yml` aus dem Anhangsblock `changelog-guard.yml`:
   **Job `unreleased-touched` behalten**, Job `changeset-status` löschen.
5. `release.yml` nach dem agent-core-Muster: Trigger nur auf Tag `v*`, Gate `tag == package.json
   version`.

**Mechanismus B (Changesets):**

3. `npm i -D @changesets/cli && npx changeset init` (pnpm: `pnpm add -Dw @changesets/cli && pnpm changeset init`);
   Keep-a-Changelog-Formatter in `.changeset/config.json` setzen.
4. `.github/workflows/changelog-guard.yml`: **Job `changeset-status` behalten** (inkl.
   `fetch-depth: 0` + Empty-Changeset-Ablehnung), Job `unreleased-touched` löschen.
5. Release über `changesets/action` (Version-PR + Publish); **kein** `version-bump.mjs`, **kein**
   Git-Hook. **Einen bereits verdrahteten Bump-Hook aktiv entfernen** (`.husky/pre-commit` /
   `post-commit`, `package.json`-Scripts, CI-Bump-Step) — nicht nur „nicht neu anlegen". Verifizieren:
   `node scripts/version-bump.mjs --dry-run` im Repo muss die **Changesets-Skip-Meldung** ausgeben und
   nichts schreiben (Fail-loud-Notiz 5).

**Nach dem Scaffolding:** In beiden Fällen das **gewählte Merge-/Branch-Modell** oben ausfüllen und in
`CLAUDE.md`/`project-standards.md` festhalten. Dann verifizieren: Gate rot machen (Code ohne
`[Unreleased]`-Eintrag bzw. ohne Changeset) und beobachten, dass CI wirklich fällt — ein Gate ist erst
bewiesen, wenn es einmal **verifiziert rot** war.

## Wie es mitgeliefert wird

- **Das Skill selbst** wird über `sync` (Claude Code) / `bundle` (OpenCode) in **jedes** Projekt
  mitgeliefert — es ist untagged, also `core`, und shippt in allen Profilen.
- **Der Default-Output** (die vier Anhangsdateien als initiales Setup) gehört als **Datei** ins
  **Claude-Template**, damit **neue** Projekte den Standard von Anfang an haben — dorthin, wo ein
  Scaffold hingehört. agent-core selbst liefert sie **nicht** aus.
- **agent-core besitzt den laufenden Hook NICHT.** agent-core liefert **nur** das Rezept; den
  konkreten `pre-commit`-/`commit-msg`-Hook, das CI-Gate und die
  Branch-Policy **verdrahtet dieses Skill im Zielprojekt** (bzw. leben im Claude-Template/dnd). Das ist
  Absicht: Hooks, Version-Bump und ESLint-Preset sind Projekt-Infrastruktur, nicht agent-core-Kern.
- **Deshalb wirkt auch der Changesets-Guard (ADR-0024) nicht über einen agent-core-Hook**, sondern
  allein über dieses **Rezept**: agent-core kann einen fremden
  `post-commit`-Hook nicht abschalten — es kann nur dafür sorgen, dass das Script, das er aufruft,
  sich in einem Changesets-Repo weigert. Ein Projekt, das eine **eigene**, abgewandelte Kopie des
  Scripts fährt, muss den Guard beim nächsten Abgleich **selbst nachziehen** — dasselbe gilt für den
  `--stage`-Pfad aus Fail-loud-Notiz 6.

## Anhang — die vier Dateien, wörtlich

Alles, was das Rezept braucht, steht hier: vier Blöcke, jeder **vollständig**, keiner gekürzt. Anlegen
heißt: Block in die genannte Datei kopieren, die drei genannten Stellen anpassen, fertig. Jeder Block
steht zwischen zwei HTML-Markern, damit ein Test ihn maschinell herausschneiden kann — und
`src/targets/version-bump.golden.test.ts` tut genau das mit dem ersten: es schneidet ihn heraus,
schreibt ihn in ein Wegwerf-Verzeichnis und **führt ihn aus**. Ein Rezept, das ein Test fährt, ist
keine Prosa mehr, die verrotten kann.

Der englische Spiegel dieses Skills wiederholt die Blöcke **nicht**. Ein zweiter Abzug eines
641-Zeilen-Skripts im selben Repo wäre genau die Kopie, die `25-orchestration` verbietet — die Blöcke
leben genau einmal, hier.

### `CHANGELOG.template.md` → `CHANGELOG.md`

Anzupassen: `OWNER/REPO` in beiden Footer-Zeilen, und die Beispielsektion `[0.1.0]` durch das eigene
erste Release ersetzen (oder vom ersten `version-bump`-Lauf erzeugen lassen).

<!-- BEGIN file CHANGELOG.template.md -->

```md
# Changelog

All notable changes to this project are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/), versioning follows [SemVer](https://semver.org/).

<!--
  KEEP `[Unreleased]` CURRENT ON EVERY CHANGE — by hand or by an agent, on the same commit
  as the code. Add entries under the matching category below (drop the ones you don't use).
  Categories (Keep a Changelog):
    Added       — new features
    Changed     — changes to existing behavior
    Deprecated  — soon-to-be-removed features
    Removed      — now-removed features
    Fixed       — bug fixes
    Security    — vulnerabilities / hardening

  A RELEASE moves this block down under `## [x.y.z] - <date>` and adds a compare link at the
  bottom — the version-bump.mjs recipe below does this for you. Tagging is deliberate, never
  per commit.
-->

## [Unreleased]

### Added

### Changed

### Deprecated

### Removed

### Fixed

### Security

## [0.1.0] - 1970-01-01

_First release. Replace this section with your real initial release, or let the first
`version-bump` run generate it from `[Unreleased]`._

### Added

- Initial project scaffold.

<!--
  COMPARE-FOOTER LINKS — replace OWNER/REPO with your repository. version-bump.mjs keeps the
  `[Unreleased]` line pointing at the newest tag and inserts one `[x.y.z]:` line per release.
  The first release has no predecessor, so it links to the tag page instead of a compare range.
-->

[Unreleased]: https://github.com/OWNER/REPO/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/OWNER/REPO/releases/tag/v0.1.0
```

<!-- END file CHANGELOG.template.md -->

### `commitlint.config.mjs` → Repo-Wurzel

Anzupassen: nichts, wenn die Hausregeln gelten. Als `commit-msg`-Hook verdrahten:
`npx --no-install commitlint --edit "$1"`. `release` steht bewusst in der `type-enum` — ohne diesen
Eintrag weist die Config genau den Commit zurück, den dieses Rezept vorschreibt.

<!-- BEGIN file commitlint.config.mjs -->

```js
// commitlint.config.mjs — Conventional Commits gate (reference; adapt per project).
//
// Enforces the commit grammar the version-bump derivation reads: `type(scope)?: subject`.
// Wire it as a `commit-msg` husky hook:  npx --no-install commitlint --edit "$1"
// Note: commitlint only checks the MESSAGE — it is NOT the [Unreleased] gate (that is CI,
// see changelog-guard.yml). A well-formed message can still forget the changelog.
//
// SUBJECT: what this config checks is the CASING, not the language. `subject-case` is inherited
// from config-conventional and rejects a subject whose FIRST character is a capital — verified:
// `feat: Grundgerüst` fails with [subject-case], `feat: grundgerüst` passes. Umlauts and capitals
// later in the line are irrelevant (`feat: grundgerüst mit Turborepo` passes), and a subject that
// does not START with a cased letter is not checked at all (`subject-case.js` bails on
// `startsWithLetterRegex`) — so "begins lowercase" as a house rule is STRICTER than this gate, and
// a counter-example does not disprove it. Which language subjects are written in is a project
// convention — no rule here checks it, so do not switch `subject-case` off to fit one.
// TYPE PREFIX: lowercase English (`type-case` + `type-enum` below).

/** @type {import('@commitlint/types').UserConfig} */
export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    // Allowed types — same set the version-bump.mjs level derivation understands.
    'type-enum': [
      2,
      'always',
      [
        'feat', // new feature            → minor
        'fix', // bug fix                → patch
        'perf', // performance            → patch
        'docs', // documentation only
        'chore', // tooling / deps / config
        'refactor', // no feature / no fix
        'test', // tests only
        'style', // formatting only
        'ci', // CI / pipelines
        'build', // build system
        'revert', // revert a prior commit
        // `release: vX.Y.Z` — the commit that carries the bump + the finalized CHANGELOG
        // section. It is NOT in `@commitlint/config-conventional`, and without it this very
        // config rejects the release commit the recipe itself prescribes (verified:
        // `release: v1.9.0` → exit 1 `[type-enum]`). It derives no level: the bump it carries
        // is already written, so `release` must never be the reason a NEW bump is computed.
        'release',
      ],
    ],
    'type-case': [2, 'always', 'lower-case'],
    'type-empty': [2, 'never'],
    'subject-empty': [2, 'never'],
    'subject-full-stop': [2, 'never', '.'],
    'header-max-length': [2, 'always', 100], // subject ≤ 100 chars
  },
};
```

<!-- END file commitlint.config.mjs -->

### `changelog-guard.yml` → `.github/workflows/changelog-guard.yml`

Anzupassen: **genau einen** der beiden Jobs behalten, den anderen löschen (Job B steht auskommentiert
da, damit die Datei mit Job A sofort läuft), und `IGNORE_RE` auf das eigene Repo einstellen.

<!-- BEGIN file changelog-guard.yml -->

```yaml
# changelog-guard.yml — CI gate that keeps releases honest (reference; adapt per project).
#
# Drop this at .github/workflows/changelog-guard.yml. It carries BOTH mechanisms; KEEP EXACTLY
# ONE job and delete the other:
#
#   • Mechanism A (unreleased-touched) — hand-written CHANGELOG + fail-loud gate.
#   • Mechanism B (changeset-status)   — Changesets-driven monorepos.
#
# ── FAIL-LOUD HONESTY (read this) ─────────────────────────────────────────────────────────────
# Mechanism A proves only that `[Unreleased]` was *touched* when code changed — a single added
# whitespace line satisfies it. It catches the "forgot the changelog entirely" case, NOT a lazy or
# wrong entry. It is a tripwire, never a proof of a good changelog. Mechanism B is stronger (a
# changeset is a real, reviewable file) but has its own hole: an EMPTY changeset (`--empty`) passes
# `changeset status` while shipping no version intent — reject it explicitly (job B does).

name: changelog-guard

on:
  pull_request:
    branches: [main]

# ════════════════════════════════════════════════════════════════════════════════════════════════
# MECHANISM A — "[Unreleased] touched when packages changed" (hand-written + fail-loud)
# Keep this job for the hand-written CHANGELOG + version-bump.mjs setup. Delete job `changeset-status`.
# ════════════════════════════════════════════════════════════════════════════════════════════════
jobs:
  unreleased-touched:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          # Need the PR base to diff against — a shallow clone cannot see origin/main.
          fetch-depth: 0

      - name: Require a [Unreleased] edit whenever shippable code changed
        run: |
          set -euo pipefail
          BASE="origin/${{ github.base_ref }}"
          git fetch --no-tags --depth=1 origin "${{ github.base_ref }}"

          CHANGED="$(git diff --name-only "$BASE"...HEAD)"
          echo "Changed files:"; echo "$CHANGED"

          # Paths that DON'T require a changelog entry (docs/tests/CI/the changelog itself).
          # Tune this regex to your repo. Everything else counts as "shippable code".
          IGNORE_RE='^(CHANGELOG\.md$|docs/|\.github/|.*\.test\.[jt]sx?$|.*\.spec\.[jt]sx?$|.*\.md$)'

          CODE_CHANGED="$(echo "$CHANGED" | grep -vE "$IGNORE_RE" || true)"
          if [ -z "$CODE_CHANGED" ]; then
            echo "No shippable code changed — changelog entry not required. OK."
            exit 0
          fi

          # Did the PR touch the [Unreleased] section of CHANGELOG.md?
          if ! git diff "$BASE"...HEAD -- CHANGELOG.md | grep -qE '^\+'; then
            echo "::error::Shippable code changed but CHANGELOG.md was not updated."
            echo "Add an entry under ## [Unreleased] (Added/Changed/Fixed/…)."
            echo "Changed code files:"; echo "$CODE_CHANGED"
            exit 1
          fi

          # Fail loud if the added lines are all outside [Unreleased] (e.g. only footer links moved).
          ADDED_IN_UNRELEASED="$(
            git diff "$BASE"...HEAD -- CHANGELOG.md \
              | awk '/^\+## \[Unreleased\]/{f=1} /^\+## \[[0-9]/{f=0} f && /^\+[^+]/{print}'
          )"
          if [ -z "$ADDED_IN_UNRELEASED" ]; then
            echo "::error::CHANGELOG.md changed, but nothing was added under [Unreleased]."
            exit 1
          fi

          echo "CHANGELOG [Unreleased] updated. OK."

# ════════════════════════════════════════════════════════════════════════════════════════════════
# MECHANISM B — `changeset status --since=origin/main` (Changesets)
# Keep this job for a Changesets-driven monorepo. Delete job `unreleased-touched` above.
# Requires: npm i -D @changesets/cli && npx changeset init
# ════════════════════════════════════════════════════════════════════════════════════════════════
#  changeset-status:
#    runs-on: ubuntu-latest
#    steps:
#      - uses: actions/checkout@v4
#        with:
#          # REQUIRED: `changeset status --since` diffs against the base branch; a shallow
#          # clone makes `origin/main` unreachable and the check silently passes on nothing.
#          fetch-depth: 0
#
#      - uses: actions/setup-node@v4
#        with:
#          node-version: 22
#          cache: npm
#      # pnpm/yarn: set the setup-node cache accordingly (cache: pnpm / cache: yarn) and run
#      # `pnpm changeset status` / `yarn changeset status` below (install:
#      # `pnpm install --frozen-lockfile` / `yarn install --immutable`).
#
#      - run: npm ci
#
#      # Fails the PR if no changeset was added for the changed packages — the required gate.
#      - name: Require a changeset for changed packages
#        run: npx changeset status --since=origin/main
#
#      # Fail loud on an EMPTY changeset — `changeset status` accepts `--empty` markers, which
#      # ship a release with no bump intent. Reject them (allow ONLY as a logged, explicit escape).
#      - name: Reject empty changesets
#        run: |
#          set -euo pipefail
#          if grep -rlZ '^---[[:space:]]*$' .changeset/*.md 2>/dev/null \
#               | xargs -0 -r grep -L '"' >/dev/null 2>&1; then
#            : # placeholder — replace with your real empty-marker detection
#          fi
#          for f in .changeset/*.md; do
#            [ -e "$f" ] || continue
#            # An empty changeset has no `"package": bump` lines between its two `---` fences.
#            if ! awk '/^---$/{c++; next} c==1 && /:/{found=1} END{exit found?0:1}' "$f"; then
#              echo "::error file=$f::Empty changeset — add a real bump (patch/minor/major) or remove it."
#              exit 1
#            fi
#          done
#          echo "All changesets carry a bump. OK."
```

<!-- END file changelog-guard.yml -->

### `version-bump.mjs` → `scripts/version-bump.mjs`

Anzupassen: Monorepo-Pfade (`PKG_PATH`/`CHANGELOG_PATH`, falls nicht Repo-Wurzel) und `--tag-prefix`,
falls die Tags nicht `v*` heißen. Dependency-frei, Node ≥ 18, ausführbares Bit nicht nötig — der
Aufruf lautet immer `node scripts/version-bump.mjs`.

<!-- BEGIN file version-bump.mjs -->

```js
#!/usr/bin/env node
// @ts-check
/**
 * version-bump.mjs — dependency-free reference SemVer bumper (ESM, Node >= 18).
 *
 * WHAT IT DOES
 *   0. Refuses to run at all in a Changesets-managed repo — `.changeset/config.json`
 *      anywhere from cwd UP to the repo root — no-op + loud notice (TRAP 3).
 *   1. Reads Conventional Commits since the last `v*` tag (via `git`, no deps).
 *   2. Derives the SemVer level:  feat → minor ·  fix/perf → patch ·
 *      `type!:` OR a `BREAKING CHANGE:` footer → major.
 *   3. Bumps `package.json#version`.
 *   4. Moves `## [Unreleased]` → `## [x.y.z] - <YYYY-MM-DD>` in CHANGELOG.md
 *      (leaving a fresh, empty `## [Unreleased]` above it).
 *   5. Appends/updates the compare-footer links at the bottom of CHANGELOG.md.
 *
 * ┌─ REFERENCE SCRIPT — ADAPT, DON'T SHIP VERBATIM ────────────────────────────┐
 * │ This is a starting point the `setup-changelog` skill drops into a target    │
 * │ project. Wire it to that project's layout (monorepo package paths, tag      │
 * │ prefix, remote host) before trusting it in CI or a hook.                     │
 * └─────────────────────────────────────────────────────────────────────────────┘
 *
 * ── TRAP 1 · WHERE you may run this as a git hook (git snapshots the tree EARLY)
 *    git builds the in-progress commit's tree BEFORE `prepare-commit-msg` and never
 *    re-reads it (`prepare_to_commit()` calls `update_main_cache_tree()` ahead of the hook).
 *    `pre-commit` is therefore the ONLY stage where an index write still reaches the CURRENT
 *    commit — that holds for `--stage` below exactly as it held for the `git add` this script
 *    used to recommend. Run either one in `prepare-commit-msg` / `commit-msg` and it mutates
 *    only the on-disk index: the bump leaks into the NEXT commit ("rides one commit behind",
 *    usually pasted over with `git commit --amend --no-edit`). Therefore: bump in `pre-commit`
 *    ONLY, or in CI — NEVER in `commit-msg`. See shared/memory/00-knowledge.md.
 *
 * ── TRAP 2 · WHY this is a .mjs file and not an inline `node -e`
 *    On Windows / Git-Bash a multi-line `node -e "…"` silently runs empty and exits
 *    0 — a bump that never happened, green. Keep the logic in a real file and invoke
 *    it as `node scripts/version-bump.mjs`. See shared/memory/00-knowledge.md.
 *
 * ── TRAP 3 · WHO owns the version — never two bump sources in ONE repo
 *    Verified (Flammenreiter): a per-commit bump hook (husky `post-commit` → this
 *    script) pushed `@flammenreiter/shared` from the published 9.0.1 to a local 9.2.0
 *    while Changesets had computed 9.1.0. Both mechanisms ran in the same repo, so
 *    `package.json` no longer told anyone which version would be published — and CI
 *    publishes exactly `package.json`. Therefore this script REFUSES to bump a repo
 *    that has `.changeset/config.json`: loud stderr notice naming the FOUND file +
 *    `process.exit(0)` — never a silent skip, and never a hard failure (a blocking
 *    hook would stop real commits in a running repo). Override with
 *    `--force-with-changesets` — logged, never silent. See ADR-0024 and the
 *    `setup-changelog` skill: mechanisms A (this script) and B (Changesets) EXCLUDE
 *    each other.
 *    The lookup walks UP from cwd to the repo root (`git rev-parse --show-toplevel`,
 *    falling back to the filesystem root when git is unavailable): Changesets is
 *    monorepo-first, so `.changeset/` sits ONLY in the workspace root while the bump
 *    hook usually runs with cwd = the PACKAGE dir. The verified case was exactly that —
 *    `@flammenreiter/shared` is a package, not the root. A cwd-local check would fail
 *    OPEN there, which is the whole scenario this guard exists for.
 *
 * ── TRAP 4 · HOW MUCH of the file you stage — a whole file inherits foreign lines
 *    Verified in a throw-away repo: with an unrelated, UNSTAGED dependency edit sitting in
 *    `package.json`, a `pre-commit` hook that bumps and then runs `git add package.json`
 *    commits BOTH hunks — the version line AND the foreign `"chalk": "5.0.0"`. The same holds
 *    for `git commit --amend --only -- package.json`, which additionally rewrites the SHA the
 *    commit just printed, so the short SHA on screen points at nothing. The culprit is NOT
 *    `--amend`: it is WHOLE-FILE staging. `git add` stages a FILE, never a line, so it cannot
 *    tell the bump apart from whatever else is open in that file. Therefore the hook must not
 *    stage at all — this script does it, with `--stage`: it reads the copy git already has in
 *    the INDEX, applies its own edit to THAT, and writes the result back as a blob
 *    (`git hash-object -w` + `git update-index`). Everything the script did not write stays
 *    unstaged. Without `--stage` it stages nothing and says so, naming the foreign lines a
 *    `git add` would have swallowed. NEVER pair this script with `git add <file>` or `--amend`
 *    in a hook. See the `setup-changelog` skill, fail-loud note 6.
 *
 * USAGE
 *    node scripts/version-bump.mjs                 # derive level from commits, write
 *    node scripts/version-bump.mjs --level minor   # force a level (major|minor|patch)
 *    node scripts/version-bump.mjs --dry-run       # print the plan, write nothing
 *    node scripts/version-bump.mjs --tag-prefix v  # tag prefix (default "v")
 *    node scripts/version-bump.mjs --stage         # ALSO stage just the lines it wrote
 *                                                  # (pre-commit hook only — TRAP 1 + TRAP 4)
 *    node scripts/version-bump.mjs --force-with-changesets   # bump despite .changeset/
 */

import { execFileSync } from 'node:child_process';
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { dirname, relative, resolve, sep as PATH_SEP } from 'node:path';

/** @typedef {'major' | 'minor' | 'patch'} Level */

const ROOT = process.cwd();
const PKG_PATH = resolve(ROOT, 'package.json');
const CHANGELOG_PATH = resolve(ROOT, 'CHANGELOG.md');

// ── CLI args ────────────────────────────────────────────────────────────────
const argv = process.argv.slice(2);
const DRY_RUN = argv.includes('--dry-run');
const STAGE = argv.includes('--stage');
const FORCED_LEVEL = /** @type {Level | undefined} */ (readFlag('--level'));
const TAG_PREFIX = readFlag('--tag-prefix') ?? 'v';

/**
 * Read a `--flag value` pair from argv.
 * @param {string} flag
 * @returns {string | undefined}
 */
function readFlag(flag) {
  const i = argv.indexOf(flag);
  return i !== -1 && i + 1 < argv.length ? argv[i + 1] : undefined;
}

/**
 * Run git and return trimmed stdout ('' on non-zero exit — e.g. no tags yet, or no repo
 * at all: this script must also work outside a git repository).
 * @param {string[]} args
 * @param {{ quiet?: boolean }} [opts] `quiet: true` also swallows git's own stderr —
 *   used for probes whose failure is an expected, non-noteworthy case.
 * @returns {string}
 */
function git(args, opts = {}) {
  try {
    return execFileSync('git', args, {
      encoding: 'utf8',
      stdio: opts.quiet ? ['ignore', 'pipe', 'ignore'] : undefined,
    }).trim();
  } catch {
    return '';
  }
}

/**
 * Run git for CONTENT, keeping stdout byte-exact and reporting failure instead of swallowing it.
 *
 * The `git()` helper above trims and returns '' on error — right for probes, wrong here: a trimmed
 * trailing newline is a real, silent one-line diff, and a swallowed error would turn "could not
 * stage" into "staged nothing", i.e. a fail-open. Used for `cat-file` / `hash-object` /
 * `update-index`, which is why `input` takes a Buffer (no re-encoding on the way in).
 *
 * @param {string[]} args
 * @param {Buffer} [input] stdin for the child, verbatim.
 * @returns {{ ok: boolean, out: string, err: string }}
 */
function gitIO(args, input) {
  try {
    const out = execFileSync('git', args, {
      encoding: 'utf8',
      input,
      maxBuffer: 64 * 1024 * 1024, // a long CHANGELOG.md outgrows the 1 MB default
    });
    return { ok: true, out, err: '' };
  } catch (err) {
    const e = /** @type {{ stderr?: string | Buffer; message?: string }} */ (err);
    return { ok: false, out: '', err: String(e?.stderr ?? e?.message ?? err).trim() };
  }
}

/**
 * Normalize an absolute path for comparison (Windows paths are case-insensitive, and
 * `git rev-parse` reports forward slashes there while `process.cwd()` reports backslashes).
 * @param {string} p
 * @returns {string}
 */
function normalizePath(p) {
  const abs = resolve(p);
  return process.platform === 'win32' ? abs.toLowerCase() : abs;
}

/**
 * Find `.changeset/config.json` anywhere from `startDir` up to and including `stopDir`.
 * ONE hit anywhere on that chain is enough — Changesets is monorepo-first, so the config
 * lives only in the workspace root while the bump may run with cwd = a package dir.
 * @param {string} startDir absolute directory to start the ascent at (usually cwd)
 * @param {string} stopDir  absolute directory to stop at, inclusive; '' = ascend to the
 *   filesystem root (the fallback when git cannot name a repo root)
 * @returns {string} absolute path of the first hit, or '' when there is none
 */
function findChangesetConfig(startDir, stopDir) {
  const stop = stopDir ? normalizePath(stopDir) : '';
  let dir = resolve(startDir);
  for (;;) {
    const candidate = resolve(dir, '.changeset', 'config.json');
    if (existsSync(candidate)) return candidate;
    if (stop && normalizePath(dir) === stop) return '';
    const parent = dirname(dir);
    if (parent === dir) return ''; // filesystem root reached
    dir = parent;
  }
}

// ── 0 · changeset guard — ONE bump source per repo (TRAP 3) ──────────────────
// Runs before ANY commit analysis and ANY file write: in a Changesets-managed repo
// `changeset version` owns package.json, and a second bumper makes the publish version
// unreadable. The ONLY thing that runs earlier is the read-only `rev-parse` probe below.
//
// Search cwd → repo root, not just cwd: with a monorepo (`.changeset/` in the workspace
// root, cwd = the package dir) a cwd-local check finds nothing and fails OPEN — which is
// precisely the verified `@flammenreiter/shared` case this guard was written for.
// '' when git is missing or this is not a repo → the ascent then runs to the filesystem root.
const TOPLEVEL = git(['rev-parse', '--show-toplevel'], { quiet: true });
const REPO_ROOT = TOPLEVEL ? resolve(TOPLEVEL) : ''; // git reports `/`-separators on Windows
const CHANGESET_CONFIG_PATH = findChangesetConfig(ROOT, REPO_ROOT);
const FORCE_WITH_CHANGESETS = argv.includes('--force-with-changesets');

if (CHANGESET_CONFIG_PATH) {
  if (!FORCE_WITH_CHANGESETS) {
    // Loud, but exit 0: a hard failure here would block every commit in a running repo.
    console.error('');
    console.error('version-bump: SKIPPED — this repo is managed by Changesets.');
    console.error(`  found:     ${CHANGESET_CONFIG_PATH}`);
    console.error(`  ran in:    ${ROOT}${REPO_ROOT ? `  (repo root: ${REPO_ROOT})` : ''}`);
    console.error('  why:       two bump sources make package.json ambiguous, and CI publishes');
    console.error('             exactly package.json. A per-commit bump races `changeset version`');
    console.error('             and overwrites the version Changesets computed.');
    console.error('  instead:   `npx changeset` per change, release via `changeset version`');
    console.error('             (+ `changeset publish`). REMOVE this bump hook — see the');
    console.error('             `setup-changelog` skill, mechanism B.');
    console.error('  stale?     if the file above is only a leftover and Changesets is NOT in use,');
    console.error('             delete that `.changeset/` directory — then this script bumps again.');
    console.error('  override:  --force-with-changesets (deliberate + logged, still not advised)');
    console.error('');
    process.exit(0);
  }
  console.warn(
    `version-bump: --force-with-changesets — bumping ANYWAY despite ${CHANGESET_CONFIG_PATH}. ` +
      'package.json is no longer the single source of truth for the publish version.',
  );
}

// ── 1 · last tag + commit range ───────────────────────────────────────────────
/** Newest `v*` tag by SemVer order, or '' when the repo has none yet. */
const lastTag = git(['tag', '--list', `${TAG_PREFIX}*`, '--sort=-v:refname']).split('\n')[0] ?? '';
const range = lastTag ? `${lastTag}..HEAD` : 'HEAD';

// Field sep = US (\x1f), record sep = RS (\x1e) — safe against newlines in bodies.
const raw = git(['log', range, '--no-merges', '--format=%s%x1f%b%x1e']);
const commits = raw
  .split('\x1e')
  .map((rec) => rec.replace(/^\n/, ''))
  .filter((rec) => rec.trim().length > 0)
  .map((rec) => {
    const [subject = '', body = ''] = rec.split('\x1f');
    return { subject: subject.trim(), body: body.trim() };
  });

if (commits.length === 0 && !FORCED_LEVEL) {
  if (STAGE) {
    // In a `pre-commit` hook the commit being made is not in `git log` yet — so an empty range is
    // the NORMAL state of the first commit after every tag. Exiting non-zero there would block
    // that commit, which no bump is worth. Loud no-op instead, same line as the ADR-0024 guard.
    console.error('');
    console.error(`version-bump: SKIPPED — no commits since ${lastTag || 'repo start'} to derive a level from.`);
    console.error('  why:    in `pre-commit` the commit you are writing is not in `git log` yet, so this');
    console.error('          is the expected state of the first commit after a tag.');
    console.error('  effect: nothing written, nothing staged, commit NOT blocked. Pass --level to force.');
    console.error('');
    process.exit(0);
  }
  console.error(`No commits since ${lastTag || 'repo start'} — nothing to bump. Use --level to force.`);
  process.exit(1);
}

// ── 2 · derive SemVer level ───────────────────────────────────────────────────
const TYPE_RE = /^(\w+)(\([^)]*\))?(!)?:/; // feat| fix(scope)| feat(x)!:
const BREAKING_RE = /^BREAKING[ -]CHANGE:/m;

let hasBreaking = false;
let hasFeat = false;
let hasPatch = false;

for (const { subject, body } of commits) {
  if (BREAKING_RE.test(subject) || BREAKING_RE.test(body)) hasBreaking = true;
  const m = TYPE_RE.exec(subject);
  if (!m) continue;
  const [, type, , bang] = m;
  if (bang === '!') hasBreaking = true;
  if (type === 'feat') hasFeat = true;
  if (type === 'fix' || type === 'perf') hasPatch = true;
}

/** @type {Level} */
const level =
  FORCED_LEVEL ??
  (hasBreaking ? 'major' : hasFeat ? 'minor' : hasPatch ? 'patch' : 'patch');

if (!FORCED_LEVEL && !hasBreaking && !hasFeat && !hasPatch) {
  console.warn('No feat/fix/perf/breaking commits found — defaulting to a patch bump.');
}

// ── 3 · bump package.json#version ─────────────────────────────────────────────
if (!existsSync(PKG_PATH)) {
  console.error(`package.json not found at ${PKG_PATH}`);
  process.exit(1);
}
const pkgText = readFileSync(PKG_PATH, 'utf8');
const pkg = JSON.parse(pkgText);
const current = String(pkg.version ?? '0.0.0');
const next = applyBump(current, level);

/**
 * Apply a SemVer bump. Drops any pre-release/build metadata (reference behavior).
 * @param {string} version
 * @param {Level} lvl
 * @returns {string}
 */
function applyBump(version, lvl) {
  const core = version.split(/[-+]/)[0];
  const [maj = 0, min = 0, pat = 0] = core.split('.').map((n) => Number.parseInt(n, 10) || 0);
  if (lvl === 'major') return `${maj + 1}.0.0`;
  if (lvl === 'minor') return `${maj}.${min + 1}.0`;
  return `${maj}.${min}.${pat + 1}`;
}

const today = new Date().toISOString().slice(0, 10); // YYYY-MM-DD (UTC)

console.log(`Level:   ${level}${FORCED_LEVEL ? ' (forced)' : ''}`);
console.log(`Version: ${current} → ${next}`);
console.log(`Date:    ${today}`);
console.log(`Commits: ${commits.length} since ${lastTag || 'repo start'}`);

if (DRY_RUN) {
  console.log('--dry-run: no files written.');
  if (STAGE) console.log('--dry-run wins over --stage: nothing was staged either.');
  process.exit(0);
}

// ── 4 · the two edits, as PURE functions ──────────────────────────────────────
// Pure, because each one is applied TWICE: to the WORKING TREE copy (what you review) and to the
// copy git already holds in the INDEX (what `--stage` puts into the commit). Running the identical
// transformation on both is what makes "stage the version line, not the file" possible at all —
// a whole-file `git add` cannot tell the two apart and inherits every unstaged line (TRAP 4).

/**
 * Replace `package.json#version`, preserving the file's own 2-space style + trailing newline.
 * @param {string} text
 * @returns {string}
 * @throws {Error} when the text carries no `"version"` field.
 */
function bumpPkgText(text) {
  const out = text.replace(/("version"\s*:\s*")[^"]*(")/, (_all, a, b) => `${a}${next}${b}`);
  if (out === text) throw new Error('Could not locate the "version" field in package.json.');
  return out;
}

/**
 * Move `## [Unreleased]` down into `## [<next>] - <today>` and refresh the compare-footer links.
 * @param {string} md
 * @returns {string}
 * @throws {Error} when the document cannot carry a release (no heading, or an empty body).
 */
function rollChangelog(md) {
  // `[ \t]*` (not `\s*`) so the match does NOT swallow the trailing newline — otherwise the
  // rebuilt section gains an extra blank line under `## [Unreleased]`.
  const hUn = /^##[ \t]*\[Unreleased\][ \t]*$/m.exec(md);
  if (!hUn) throw new Error('No `## [Unreleased]` heading in CHANGELOG.md — cannot roll a release.');

  // Slice the Unreleased body: from just after its heading to the next `## [` heading (or EOF).
  const bodyStart = hUn.index + hUn[0].length;
  const relIdx = md.slice(bodyStart).search(/^##\s*\[/m);
  const bodyEnd = relIdx === -1 ? md.length : bodyStart + relIdx;
  const unreleasedBody = md.slice(bodyStart, bodyEnd).trim();

  if (unreleasedBody.length === 0 && !FORCED_LEVEL) {
    throw new Error('`## [Unreleased]` is empty — write your changes there before releasing (or pass --level).');
  }

  const releasedSection = `## [${next}] - ${today}\n\n${unreleasedBody}\n\n`;
  const rolled =
    md.slice(0, bodyStart) + `\n\n${releasedSection}` + md.slice(bodyEnd).replace(/^\n+/, '');

  return repoUrl ? updateFooterLinks(rolled, repoUrl, lastTag, next) : rolled;
}

if (!existsSync(CHANGELOG_PATH)) {
  console.error(`CHANGELOG.md not found at ${CHANGELOG_PATH} — start from the CHANGELOG.template.md asset.`);
  process.exit(1);
}
const changelogText = readFileSync(CHANGELOG_PATH, 'utf8');

// ── 5 · compare-footer links ──────────────────────────────────────────────────
const repoUrl = deriveRepoUrl();
if (!repoUrl) {
  console.warn('Could not derive the repository URL from `git remote` — skipping compare-footer links.');
}

/**
 * Turn `git remote get-url origin` into an https base URL (handles SSH + `.git`).
 * @returns {string}
 */
function deriveRepoUrl() {
  const remote = git(['remote', 'get-url', 'origin']);
  if (!remote) return '';
  // git@github.com:owner/repo.git → https://github.com/owner/repo
  const ssh = /^git@([^:]+):(.+?)(?:\.git)?$/.exec(remote);
  if (ssh) return `https://${ssh[1]}/${ssh[2]}`;
  return remote.replace(/^https?:\/\//, 'https://').replace(/\.git$/, '');
}

/**
 * Rewrite the `[Unreleased]:` compare link and insert the new `[version]:` link.
 * @param {string} md
 * @param {string} baseUrl
 * @param {string} prevTag  previous `v*` tag, or '' for the first release
 * @param {string} version  the just-bumped version (no `v` prefix)
 * @returns {string}
 */
function updateFooterLinks(md, baseUrl, prevTag, version) {
  const newTag = `${TAG_PREFIX}${version}`;
  const unreleasedLink = `[Unreleased]: ${baseUrl}/compare/${newTag}...HEAD`;
  const versionLink = prevTag
    ? `[${version}]: ${baseUrl}/compare/${prevTag}...${newTag}`
    : `[${version}]: ${baseUrl}/releases/tag/${newTag}`;

  const hasUnreleasedLink = /^\[Unreleased\]:.*$/m.test(md);
  if (hasUnreleasedLink) {
    // Replace the existing [Unreleased]: line and drop the new version link right under it.
    return md.replace(/^\[Unreleased\]:.*$/m, `${unreleasedLink}\n${versionLink}`);
  }
  // No footer yet → append one.
  const sep = md.endsWith('\n') ? '' : '\n';
  return `${md}${sep}\n${unreleasedLink}\n${versionLink}\n`;
}

// ── 6 · line-granular staging (TRAP 4) ────────────────────────────────────────

/** One file's index-side plan: the body to stage, and where/how git must record it. */
/**
 * @typedef {object} StagePlan
 * @property {string} label     the file's name as the user knows it
 * @property {string} indexPath the path git indexes it under (repo-relative, `/`-separated)
 * @property {string} mode      the index mode to keep (`100644`, `100755`, …)
 * @property {boolean} tracked  `false` = the index has no copy yet; the whole file is new
 * @property {string} text      the body to stage
 */

/**
 * Read the copy git holds in the INDEX — the base a staged edit must be applied to.
 *
 * A file the index does not know has no such base: its whole body is new to the commit, so the
 * working-tree text is returned instead and `tracked` says so.
 *
 * @param {string} rel path relative to cwd, as git is asked for it.
 * @param {string} abs absolute path, used to name an untracked file inside the repo.
 * @param {string} worktreeText the working-tree body, used only when the file is untracked.
 * @returns {{ ok: true, mode: string, indexPath: string, tracked: boolean, text: string }
 *   | { ok: false, reason: string }}
 */
function indexSource(rel, abs, worktreeText) {
  const ls = gitIO(['ls-files', '-s', '--full-name', '--', rel]);
  if (!ls.ok) return { ok: false, reason: `\`git ls-files\` failed — ${ls.err}` };
  const line = ls.out.split('\n').find((l) => l.trim().length > 0) ?? '';
  const m = /^(\d{6}) ([0-9a-f]+) (\d)\t(.*)$/.exec(line);
  if (!m) {
    if (!REPO_ROOT) return { ok: false, reason: 'not inside a git repository' };
    return {
      ok: true,
      mode: '100644',
      indexPath: relative(REPO_ROOT, abs).split(PATH_SEP).join('/'),
      tracked: false,
      text: worktreeText,
    };
  }
  const [, mode = '100644', sha = '', stageNo = '0', indexPath = rel] = m;
  if (stageNo !== '0') {
    return { ok: false, reason: `${indexPath} is unmerged (index stage ${stageNo})` };
  }
  const blob = gitIO(['cat-file', 'blob', sha]);
  if (!blob.ok) return { ok: false, reason: `\`git cat-file blob ${sha}\` failed — ${blob.err}` };
  return { ok: true, mode, indexPath, tracked: true, text: blob.out };
}

/**
 * Put `plan.text` into git's object store and point the index entry at it — the working-tree file
 * is not touched, and neither is any other line of the file.
 *
 * `--path` is passed ONLY for a body that came from the working tree (an untracked file), because
 * that body still has to go through git's clean filter — `core.autocrlf` above all. An INDEX body
 * has been through it already; filtering it twice is how a CRLF repo grows a phantom diff.
 *
 * @param {StagePlan} plan
 * @returns {{ ok: boolean, err: string }}
 */
function stageText(plan) {
  const hashArgs = plan.tracked
    ? ['hash-object', '-w', '--stdin']
    : ['hash-object', '-w', '--path', plan.indexPath, '--stdin'];
  const hashed = gitIO(hashArgs, Buffer.from(plan.text, 'utf8'));
  if (!hashed.ok) return { ok: false, err: hashed.err };
  const blobSha = hashed.out.trim();
  const updated = gitIO([
    'update-index',
    '--add',
    '--cacheinfo',
    `${plan.mode},${blobSha},${plan.indexPath}`,
  ]);
  return updated.ok ? { ok: true, err: '' } : { ok: false, err: updated.err };
}

/**
 * The lines in which the working tree differs from the index, minus the `"version"` line this
 * script owns — i.e. exactly what a `git add <file>` would drag into the commit.
 *
 * `git diff` is asked rather than two strings compared, because git applies the repository's own
 * eol configuration: under `core.autocrlf` a naive comparison reports EVERY line and the notice
 * becomes noise nobody reads.
 *
 * @param {string} rel path relative to cwd.
 * @returns {string[]} `+`/`-` prefixed diff lines; empty when there are none.
 */
function foreignUnstagedLines(rel) {
  const diff = gitIO(['diff', '--unified=0', '--no-color', '--', rel]);
  if (!diff.ok) return [];
  return diff.out
    .split('\n')
    .filter(
      (l) =>
        (l.startsWith('+') || l.startsWith('-')) && !l.startsWith('+++') && !l.startsWith('---'),
    )
    .filter((l) => !/"version"\s*:/.test(l));
}

// Read BEFORE anything is written — afterwards this script's own bump is part of that diff.
const foreignPkgLines = REPO_ROOT ? foreignUnstagedLines('package.json') : [];

// With --stage the INDEX side is built FIRST, and a failure there means nothing is written at all.
// A half state — a bumped package.json next to an un-rolled CHANGELOG, or a rolled CHANGELOG the
// commit never sees — is what the standard forbids ("bump and changelog finalized together, never
// one without the other"), and inside a hook it is worse than that: the next run would abort on the
// already-emptied `[Unreleased]` and block the commit. So: loud no-op, exit 0, working tree intact.
/** @type {StagePlan[]} */
const stagePlans = [];
if (STAGE) {
  /** @type {{ label: string, rel: string, abs: string, text: string, edit: (t: string) => string }[]} */
  const targets = [
    { label: 'package.json', rel: 'package.json', abs: PKG_PATH, text: pkgText, edit: bumpPkgText },
    {
      label: 'CHANGELOG.md',
      rel: 'CHANGELOG.md',
      abs: CHANGELOG_PATH,
      text: changelogText,
      edit: rollChangelog,
    },
  ];
  for (const target of targets) {
    const source = indexSource(target.rel, target.abs, target.text);
    if (!source.ok) {
      refuseToStage(`${target.label}: ${source.reason}`);
    } else {
      try {
        stagePlans.push({
          label: target.label,
          indexPath: source.indexPath,
          mode: source.mode,
          tracked: source.tracked,
          text: target.edit(source.text),
        });
      } catch (err) {
        refuseToStage(`${target.label}, as it is STAGED: ${err instanceof Error ? err.message : String(err)}`);
      }
    }
  }
}

/**
 * Abandon the run without writing anything — loud on stderr, exit 0, so a `pre-commit` hook never
 * blocks a real commit (the ADR-0024 shape, for the same reason).
 *
 * @param {string} reason what could not be prepared.
 * @returns {never}
 */
function refuseToStage(reason) {
  console.error('');
  console.error('version-bump: SKIPPED — --stage could not prepare the index, so NOTHING was written.');
  console.error(`  reason:    ${reason}`);
  console.error('  why:       staging only half of the pair would leave the commit with a bump and no');
  console.error('             changelog section (or the reverse), and the next run would then abort on');
  console.error('             an already-emptied [Unreleased] — inside a hook that blocks the commit.');
  console.error('  usual fix: stage YOUR OWN changelog entry first (`git add CHANGELOG.md`) and commit');
  console.error('             again; --stage releases exactly what is staged, never more.');
  console.error('  never:     `git add package.json` to force it through — that stages the whole file');
  console.error('             and folds every unstaged line into this commit (TRAP 4).');
  console.error('');
  process.exit(0);
}

/** @type {string} */
let nextPkgText;
/** @type {string} */
let nextChangelogText;
try {
  nextPkgText = bumpPkgText(pkgText);
  nextChangelogText = rollChangelog(changelogText);
} catch (err) {
  console.error(err instanceof Error ? err.message : String(err));
  console.error('Aborting — nothing written.');
  process.exit(1);
}

writeFileSync(PKG_PATH, nextPkgText);
writeFileSync(CHANGELOG_PATH, nextChangelogText);

for (const plan of stagePlans) {
  const staged = stageText(plan);
  if (staged.ok) continue;
  console.error('');
  console.error(`version-bump: FAILED to stage ${plan.indexPath} — ${staged.err}`);
  console.error('  The working tree carries the bump, the index does not. Do NOT repair this with');
  console.error('  `git add`: it stages the whole file (TRAP 4). Re-run this script, or stage the');
  console.error('  version line by hand.');
  console.error('');
  process.exit(1);
}

console.log('');
console.log('Wrote package.json + CHANGELOG.md.');
if (STAGE) {
  console.log(`Staged ${stagePlans.length} file(s) via \`git update-index\` — the hook must NOT run \`git add\`:`);
  for (const plan of stagePlans) {
    console.log(`  ${plan.indexPath}${plan.tracked ? '' : '   (new to the index — whole file)'}`);
  }
}
console.log('Next steps (deliberate — never reflexive):');
console.log(`  1. Review the diff, commit:   git commit -m "release: ${TAG_PREFIX}${next}"`);
console.log(`  2. On explicit go-ahead, tag: git tag ${TAG_PREFIX}${next}`);
console.log('  Tagging is what costs money (CI publish) — batch patches, tag on a milestone.');

// The foreign lines are named LAST and on stderr, so they are the thing left on screen.
if (foreignPkgLines.length > 0) {
  console.error('');
  console.error(
    STAGE
      ? `version-bump: ${foreignPkgLines.length} foreign unstaged line(s) in package.json were LEFT OUT of the index.`
      : `version-bump: package.json carries ${foreignPkgLines.length} unstaged line(s) this script did not write.`,
  );
  for (const line of foreignPkgLines) console.error(`      ${line}`);
  console.error('  A `git add package.json` stages the FILE, so those lines would ride into THIS');
  console.error('  commit — the bug this script exists to stop (TRAP 4). They stay in your working');
  console.error(
    STAGE
      ? '  tree; commit them when they are ready.'
      : '  tree. In a `pre-commit` hook run this script with `--stage`: it writes the version line',
  );
  if (!STAGE) console.error('  into the index on its own, and the hook adds nothing.');
  console.error('');
}
```

<!-- END file version-bump.mjs -->
