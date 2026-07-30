---
name: setup-changelog
description: 'Changelog + Versionierung + Release-Mechanik in einem Projekt aufsetzen und standardisieren: Keep-a-Changelog-Standard, ein Version-Bump-Scaffold (greift auch bei Hand-Commits), Mechanismus-Wahl (fail-loud CI-Gate ODER Changesets) und eine konfigurierbare Merge-/Branch-/Release-Policy (Default trunk-based). Nutze, wenn ein Projekt Changelog, SemVer-Bump oder Release-Automation einrichten, reparieren oder vereinheitlichen will.'
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Setup Changelog

Dieses Skill richtet den **Changelog-, Versionierungs- und Release-Standard** in einem beliebigen
Projekt ein. Es verallgemeinert das Muster, das agent-core selbst fährt (`CHANGELOG.md` im
Keep-a-Changelog-Format, SemVer-Bump mit der Änderung, tag-getriggerter Release-Workflow mit
`tag == package.json version`-Gate), zu einem **wiederverwendbaren, mitgelieferten** Rezept — inklusive
Scaffolding-Dateien unter [`assets/`](./assets).

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

## Der Standard (non-negotiable)

Diese Punkte gelten **immer**, egal welcher Mechanismus (siehe unten) gewählt wird:

- **Keep a Changelog + SemVer.** `CHANGELOG.md` beginnt mit dem Kopf, der auf
  [keepachangelog.com](https://keepachangelog.com/) **und** [semver.org](https://semver.org/) verlinkt
  (siehe [`assets/CHANGELOG.template.md`](./assets/CHANGELOG.template.md)).
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
| Git-Hook nötig | optional (Bump in `pre-commit` **oder** CI) | **nein** — kein Hook, keine Snapshot-Falle |
| Extra-Dependency | keine (dependency-freies `.mjs`) | `@changesets/cli` |
| Ehrliche Schwäche | Gate ist durch **eine Whitespace-Zeile** erfüllbar → **nie 100 % fail-loud** | leerer Changeset (`--empty`) ist ein Loch → im Gate ablehnen |

### A — handgeschrieben + fail-loud CI-Gate (Default)

- `[Unreleased]` wird **von Hand** (oder vom Agenten) gepflegt.
- Ein **CI-Check wird rot**, wenn geänderte Pakete `[Unreleased]` nicht angefasst haben — Variante A in
  [`assets/changelog-guard.yml`](./assets/changelog-guard.yml).
- **commitlint** erzwingt die Commit-Grammatik ([`assets/commitlint.config.mjs`](./assets/commitlint.config.mjs)),
  die die Bump-Ableitung liest.
- Ein **`version-bump`-Script** ([`assets/version-bump.mjs`](./assets/version-bump.mjs)) leitet den
  SemVer-Level aus den Commits ab, bumpt `package.json`, verschiebt `[Unreleased]` → `[x.y.z] - <date>`
  und ergänzt den Compare-Footer.
- **Ehrlich dokumentieren:** Der Gate prüft nur, **dass** `[Unreleased]` berührt wurde — **eine
  Whitespace-Änderung erfüllt ihn**. Er fängt das „Changelog komplett vergessen"-Versagen, **nicht**
  einen faulen oder falschen Eintrag. Er ist ein Stolperdraht, **kein** Beweis eines guten Changelogs.

### B — Changesets

- `npx changeset` (bzw. `pnpm changeset`; Mensch **und** Agent, **gleicher** Handgriff) legt eine
  reviewbare `.changeset/*.md` mit Paket + Bump-Level an.
- `changeset version` erzeugt beim Merge der **Version-PR** `CHANGELOG` **und** Bump; `changeset publish`
  veröffentlicht.
- `changeset status --since=origin/main` als **REQUIRED CI-Check** (fail-loud) — Variante B in
  [`assets/changelog-guard.yml`](./assets/changelog-guard.yml).
- **Monorepo-first**, **KEIN Git-Hook** (damit keine Snapshot-Falle, siehe unten).
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

## Fail-loud-Notizen

Cross-Ref: `shared/memory/00-knowledge.md` (agent-cores gesammelte Gotchas) und `30-quality`
(Fail-loud-Prinzip: ein Gate mit gebrochener Vorbedingung wird ROT/LAUT, nie grün).

1. **Git snapshottet den Commit-Tree VOR `prepare-commit-msg`.** `prepare_to_commit()` ruft
   `update_main_cache_tree()` **vor** dem Hook und liest danach nie neu. Ein `git add package.json
   CHANGELOG.md` beim Bump fällt **NUR in `pre-commit`** in den laufenden Commit; in
   `prepare-commit-msg`/`commit-msg` **leakt** er in den **NÄCHSTEN** Commit („reitet einen Commit
   hinterher", oft mit `git commit --amend --no-edit` gepflastert). → Bump **nur in `pre-commit`
   ODER in CI**, **nie in `commit-msg`**.
2. **Windows / Git-Bash: mehrzeiliges `node -e` läuft leer und exit 0.** Ein Inline-Bump per
   `node -e "…"` „passiert" grün, ohne etwas zu tun. → Bump-Logik in eine **`.mjs`-Datei** legen und
   als `node scripts/version-bump.mjs` aufrufen (genau das ist [`assets/version-bump.mjs`](./assets/version-bump.mjs)).
3. **Commit-Message mit `-F <file>` statt `-m` bei deutscher Prosa/Backticks.** Git-Bash führt
   Backticks in `git commit -m "… \`x\` …"` als Command-Substitution aus und korrumpiert die Message. →
   für Messages mit Markdown/Backticks `git commit -F <file>`. **Ein message-lesender Marker-Hook
   (z. B. der Release-Flag- oder Bump-Trigger) muss auch den `-F`-Pfad lesen**, nicht nur `-m`.
4. **commitlint/husky-Hook-Pfade auf Windows.** Husky-Hooks laufen über Git-Bash; `.mjs`/PowerShell
   nicht mischen. `commit-msg` ruft `npx --no-install commitlint --edit "$1"`; der Bump-Hook ist ein
   **`pre-commit`**-Hook (siehe Punkt 1). `core.hooksPath` prüfen, wenn Hooks nicht feuern.

## Scaffolding-Schritte

Das Skill legt — je nach Mechanismus — diese `assets/`-Dateien ins Zielprojekt und verdrahtet sie:

**Immer:**

1. `CHANGELOG.md` aus [`assets/CHANGELOG.template.md`](./assets/CHANGELOG.template.md) (Kopf,
   `[Unreleased]`, leere Kategorien, Compare-Footer) — `OWNER/REPO` ersetzen.
2. `commitlint.config.mjs` aus [`assets/commitlint.config.mjs`](./assets/commitlint.config.mjs); als
   `commit-msg`-Hook verdrahten.

**Mechanismus A (Default):**

3. `scripts/version-bump.mjs` aus [`assets/version-bump.mjs`](./assets/version-bump.mjs) — an
   Monorepo-Pfade/Tag-Prefix anpassen; als **`pre-commit`**-Hook **oder** CI-Step (nicht `commit-msg`).
4. `.github/workflows/changelog-guard.yml` aus [`assets/changelog-guard.yml`](./assets/changelog-guard.yml):
   **Job `unreleased-touched` behalten**, Job `changeset-status` löschen.
5. `release.yml` nach dem agent-core-Muster: Trigger nur auf Tag `v*`, Gate `tag == package.json
   version`.

**Mechanismus B (Changesets):**

3. `npm i -D @changesets/cli && npx changeset init` (pnpm: `pnpm add -Dw @changesets/cli && pnpm changeset init`);
   Keep-a-Changelog-Formatter in `.changeset/config.json` setzen.
4. `.github/workflows/changelog-guard.yml`: **Job `changeset-status` behalten** (inkl.
   `fetch-depth: 0` + Empty-Changeset-Ablehnung), Job `unreleased-touched` löschen.
5. Release über `changesets/action` (Version-PR + Publish); **kein** `version-bump.mjs`, **kein**
   Git-Hook.

**Nach dem Scaffolding:** In beiden Fällen das **gewählte Merge-/Branch-Modell** oben ausfüllen und in
`CLAUDE.md`/`project-standards.md` festhalten. Dann verifizieren: Gate rot machen (Code ohne
`[Unreleased]`-Eintrag bzw. ohne Changeset) und beobachten, dass CI wirklich fällt — ein Gate ist erst
bewiesen, wenn es einmal **verifiziert rot** war.

## Wie es mitgeliefert wird

- **Das Skill selbst** wird über `sync` (Claude Code) / `bundle` (OpenCode) in **jedes** Projekt
  mitgeliefert — es ist untagged, also `core`, und shippt in allen Profilen.
- **Der Default-Output** (die `assets/`-Dateien als initiales Setup) gehört zusätzlich ins
  **Claude-Template**, damit **neue** Projekte den Standard von Anfang an haben.
- **agent-core besitzt den laufenden Hook NICHT.** agent-core liefert das **Rezept** und die
  **Referenz-Dateien**; den konkreten `pre-commit`-/`commit-msg`-Hook, das CI-Gate und die
  Branch-Policy **verdrahtet dieses Skill im Zielprojekt** (bzw. leben im Claude-Template/dnd). Das ist
  Absicht: Hooks, Version-Bump und ESLint-Preset sind Projekt-Infrastruktur, nicht agent-core-Kern.
