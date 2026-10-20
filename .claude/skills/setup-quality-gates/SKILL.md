---
name: setup-quality-gates
description: 'Die Gates verdrahten, die in den Vorlagen fail-open sind: die jscpd-Duplikationsschranke (ohne Pfadargument prüft sie NULL Dateien und ist grün bei Exit 0), das FSD-Boundary-Gate (ohne settings["import/resolver"].typescript verwirft eslint-plugin-boundaries jeden aliased Import still — ein 100-%-No-op bei Severity error) und ein Gate, das einen Code-Graph-Skill verlangt, obwohl im Regelfall kein Graph da ist. Liefert die korrekte Script-Form, den Resolver-Block, die .gitattributes-Wurzeldatei gegen CRLF-verseuchte Checkouts und einen Kanarienvogel, der das GATE mutiert statt der Fixture, jeweils wörtlich zum Abtippen. Nutze, wenn ein Projekt cpd:ci oder FSD-Boundaries einrichtet, wenn ein Gate verdächtig schnell grün ist, wenn ein Lint-/Duplikations-Gate nie etwas gefunden hat, oder wenn format:check ab dem ersten Klon rot ist.'
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Setup Quality Gates

Dieses Skill verdrahtet die Gates, die `30-quality` und `31-quality-web` **fordern** und die in den
bestehenden Vorlagen **grün sind, ohne irgendetwas geprüft zu haben**: die jscpd-Schranke, das
FSD-Boundary-Gate und ein Gate, dessen Werkzeug im Regelfall gar keine Datengrundlage hat. Alle
fallen in dieselbe Klasse — sie melden nicht „nichts gefunden", sondern „nichts geprüft", und das
sieht identisch aus.

> **agent-core liefert hier keine Datei aus, nur das Rezept** (F3 = b). Jeder Block unten ist
> vollständig und abtippfähig; die Datei entsteht im Zielprojekt. Das ist kein Verzicht: ein
> ausgeliefertes Gate-Script wäre eine zweite Kopie, die genau so still von diesem Text wegdriftet,
> wie die fünf gemessenen cpd-Kopien voneinander weggedriftet sind.

> **Prosa deutsch, Code/Identifier/Kommandos englisch** (Repo-Konvention).

## Wann invoken

- Ein Projekt richtet `cpd:ci` oder FSD-Boundaries **neu** ein — oder erbt sie aus einer Vorlage.
- Ein Gate ist **verdächtig schnell** grün (`Detection time: 0.088ms` für ein Monorepo).
- Ein Lint-/Duplikations-Gate hat **noch nie** etwas gefunden, und niemand weiß, ob das ein Lob ist.
- Ein Review fragt „ist das Gate eigentlich verdrahtet?" — die Antwort ist ein Kanarienvogel, kein Ja.

## Die Fail-opens, mit Messung

**Die Überschrift trägt bewusst keine Zahl.** Eine gezählte Überschrift („die zwei Fail-opens") wird
still falsch, sobald jemand einen weiteren Fall darunterhängt — und genau das ist hier schon zweimal
beantragt worden. Wer einen Fall ergänzt, hängt ihn als nächstes `### Fail-open N` hier an und muss
nichts umbenennen; dasselbe gilt für jede Zählung im Fließtext dieses Skills (Herkunft: ADR-0051).

Die ersten beiden Befunde stammen aus dem Einzelgutachten zu Issue #9
(`docs/issue-triage-2026-08-03/issue-09.md:24-29`, gemessen 2026-08-03), der dritte aus der Triage zu
Issue #15 (gemessen 2026-09-16/17) — hier zitiert, nicht neu gefahren. Die Fundstellen sind
Consumer-Repos, nicht agent-core.

### Fail-open 1 — `jscpd` ohne Pfadargument prüft null Dateien

`"cpd:ci": "jscpd --reporters console --threshold 5"` sieht vollständig aus und ist es nicht: ohne
Pfadargument bekommt jscpd **nichts zu tun**. Gemessen an zwei Dateien mit 50 % Duplikat:

```
$ jscpd --reporters console --threshold 5      # ohne Pfad
Detection time:: 0.088ms
EXIT=0                                          # und KEINE "Files analyzed"-Zeile

$ jscpd . --reporters console --threshold 5    # mit Pfad
typescript | 2 | 18 | 330 | 1 | 9 (50%)
Found 1 clones.
ERROR: jscpd found too many duplicates (50%) over threshold (5%)
EXIT=1
```

**Warum die naive Form fail-open ist:** die Schranke wird nie unterschritten, weil nie gemessen wird.
Exit 0 heißt hier nicht „sauber", sondern „nicht gelaufen" — und die beiden sind an der Ausgabe **nur**
daran zu unterscheiden, dass die Zeile mit der Dateizahl **fehlt**. Eine Assertion auf „Zahl == 0"
greift also zu kurz; das Fehlen der Zeile muss genauso hart rot sein (`30-quality`: Exit-Codes lügen,
prüfe was ein Gate **emittiert**).

### Fail-open 2 — das Boundary-Gate ohne TS-Resolver

`eslint-plugin-boundaries` verwirft **still** jeden Import, den es nicht zu einer Datei auflösen kann:
die Vorprüfung `checkAllOrigins`/`checkUnknownLocals` (beide Default `false`) läuft **vor** der
Regelauswertung. In einem TS-Projekt mit Pfad-Aliassen ist das Gate damit ein **100-%-No-op — grün bei
Severity `error`**.

- Es braucht `settings["import/resolver"].typescript` (`eslint-import-resolver-typescript`; er liest
  die tsconfig-`paths` selbst, ein `baseUrl` beim Konsumenten ist nicht nötig).
- Der `node`-Resolver genügt **nicht** — er kann `paths` nicht lesen, also bleiben aliased Imports
  stumm, während relative Imports fehlerfrei erkannt werden. Wer den Fix an einer **relativen**
  Fixture prüft, feiert einen falschen Sieg.
- Unter pnpm muss der Resolver **direkte devDependency jeder App** sein: `eslint-module-utils` löst
  ihn relativ zur **gelinteten Quelldatei** auf, geerbt aus einem geteilten Preset findet er sich nicht.
- Eine gate-tragende Regel fällt außerdem per **Deprecation** offen: `eslint-plugin-boundaries@6`
  deprecated `no-private`/`entry-point`, v7 entfernt sie — Major pinnen und jede deprecated Regel,
  die eine Grenze bewacht, ticketen.

### Fail-open 3 — ein Gate, das einen Code-Graph-Skill verlangt, hat im Normalfall keinen Graphen

Dieselbe Klasse eine Ebene höher: das Gate blockt **hart**, aber die Vorbedingung des Skills, den es
verlangt, ist im Regelfall nicht erfüllt. Gemessen 2026-09-16/17 (nachgemessen 2026-09-22: unverändert)
an einem Consumer-Workspace, dessen Pre-Commit-Gate vier Skills fordert, davon zwei graphgestützte:

```
Registry (list_repos)           ->  6 Repos registriert, 0 Worktree-Pfade
Staleness (commitsBehind)       ->  72 / 245 / 60 / 229 / 274 / 160   (6 von 6 Indizes veraltet; 72 = agent-core selbst)
.gitnexus im verlinkten Worktree->  fehlt in 21 von 21 (Vollzensus über 6 Repos: 27 Einträge)
.gitnexus in der Repo-Wurzel    ->  fehlt auch dort — genau das Repo, in dem das Gate-Skript liegt
```

Der Index hängt am Haupt-Checkout — `.gitnexus/` ist untracked, `git worktree add` bringt ihn nie
mit — **und** ist dort veraltet. Zwei der vier Gates stehen damit auf einem Graphen, den es im
Worktree nicht gibt und der im Haupt-Checkout veraltet ist. Wo die Worktree-Spur trotzdem antwortet
(`detect_changes` mit `worktree`-Parameter), beruhigt sie, statt zu warnen: gemessen 2026-09-22 an
einem Diff über 153 Dateien `changed_count: 157 · affected_count: 0 · risk_level: low`. Das Gate
blockt trotzdem, man armt, und hält vier grüne Gates in der Hand, von denen zwei nichts gesehen
haben.

**Drei Ausfallarten, nicht eine — sie brauchen verschiedene Gegenmittel.** (a) **Kein Index**: der
verlinkte Worktree, und in der Messung oben auch die Repo-Wurzel selbst. (b) **Veralteter Index**:
60 bis 274 Commits, in 6 von 6 registrierten Repos. (c) **Vorhandener Index, der trotzdem null
meldet**: eine Upstream-Traversierung verlor eine Kante, die dieselbe Traversierung in der
Gegenrichtung findet, und etikettierte die Antwort als `exact` bei `risk: LOW`. Gemessen wurde (c)
an einem Index 72 Commits hinter `HEAD` — aber der Aufruf stand schon im indizierten Stand, und die
Kante liegt im selben Graphen: Veraltung erklärt (c) nicht. (a) und (b) heilt ein `analyze` im
Haupt-Checkout; für (c) ist es nicht das Gegenmittel (nach einem `analyze` nicht nachgemessen), und
(c) ist der gefährlichste, weil er wie ein bestandenes Gate aussieht. Zusätzlich exitet
`gitnexus status` in **jedem** Fall 0, auch bei „Repository not indexed." — ein `status || block`
feuert nie, also stdout parsen statt Exit-Code.

**Pflicht statt Stillschweigen** (`30-quality`, „Code-intelligence safety"): der Deny-Text eines
solchen Gates muss die Vorbedingung **benennen** und die Ersatzleistung **fordern** —
Quellcode-Evidenz als deklarierte **Ersatzleistung**, nie als „Gate grün"; bei echtem Umbau-Risiko
(Umbenennungen, Signaturänderungen, Verschieben eines geteilten Contracts) stattdessen fail-closed
plus adversarisches Zweitreview, offengelegt im PR-Text. **Die Erkennung des verlinkten Worktrees und
die Spuren, die daraus folgen, stehen an genau einer Stelle: `skill:gitnexus-guide`, Abschnitt
„Worktrees" — hier bewusst nicht wiederholt.**

**Und das Gate-Skript, das der Hook fährt, ist nicht zwingend das, das du liest.** Gemessen im selben
Workspace: 20 Kopien eines Guard-Skripts, **vier** verschiedene Fassungen. Der Prädiktor ist nicht
„Worktree", sondern das **Alter des HEAD** — 7 von 14 Worktree-Kopien tragen die kanonische Fassung,
abweichend sind ausnahmslos die, deren HEAD älter ist als der Commit, der die Byte-Gleichheit
wiederhergestellt hat. Zwei verschiedene Schäden entstehen daraus, und beide sehen gleich aus: die
eine Fassung ist schlicht **alt** (ihr fehlen Korrekturen, die auf `main` längst stehen), die andere
rechnet ihr Sentinel mit einer **anderen Hash-Formel** und schreibt zwei statt vier Hashes — der
kanonische Hook vergleicht per `grep -qxF`, findet nie eine Übereinstimmung und **blockt weiter,
obwohl das Armen „armed" gemeldet hat**. Zwei Konsequenzen: das Gate-Skript aus dem
**Haupt-Checkout** fahren (dessen Pfad ist der erste Eintrag von `git worktree list --porcelain`),
und die `--arm`-Meldung ihre eigene Fassung ausweisen lassen —
`git -C "$(dirname "$0")" log -1 --format=%h -- "$(basename "$0")"` in die „armed"-Zeile —, damit
eine Drift beim **Armen** auffällt statt erst beim Blocken. `basename` ist tragend: `-C` verlegt auch
die Pfadangabe, und mit `-- "$0"` druckt ein relativer Aufruf aus der Repo-Wurzel
(`sh .claude/scripts/gate.sh`, so ruft ein Hook) eine **leere** Fassung bei Exit 0 — gemessen, in
derselben Wegwerf-Kopie liefert die `basename`-Form in allen drei Aufrufarten den Hash.

## Die korrekte Form, wörtlich

Jeder Block unten ist vollständig. Anlegen heißt: Block in die genannte Datei schreiben, die
benannten Stellen anpassen, dann **rot verifizieren** — vorher ist nichts davon ein Gate.

### `cpd-gate.mjs` → `scripts/cpd-gate.mjs`

Anzupassen: `PATHS` (die Verzeichnisse, die es wirklich gibt), `THRESHOLD`, `EXTENSIONS`. Verdrahten
als `"cpd:ci": "node scripts/cpd-gate.mjs"`. Das Skript zählt seine **eigene** Reichweite, bevor es
jscpd startet, und weigert sich bei null — damit ist die pfadlose Form konstruktiv unerreichbar.

<!-- BEGIN file cpd-gate.mjs -->

```js
#!/usr/bin/env node
// @ts-check
/**
 * cpd-gate.mjs — jscpd with a REACH NUMBER, so "nothing found" cannot pass as "nothing scanned".
 *
 * THE BUG THIS EXISTS FOR
 *   `jscpd --reporters console --threshold 5` (no path argument) analyses NOTHING and exits 0. Its
 *   whole output is one `Detection time::` line: the files-analyzed row is not printed at all. A CI
 *   job wired that way is green forever and the duplication limit does not exist.
 *
 * WHAT THIS ADDS
 *   1. The paths are explicit AND counted here, before jscpd runs. Zero files is a hard RED — that is
 *      the missing-path bug, made unreachable.
 *   2. jscpd's OWN file count is read back out of its output. If it cannot be found, that is RED too,
 *      never "assume fine": jscpd's console table is version-dependent, and an unparsable output is
 *      exactly the state this gate exists to distinguish from a clean run.
 *   3. jscpd's exit code is passed through, so the threshold still fails the build on its own.
 *
 * USAGE   node scripts/cpd-gate.mjs
 */
import { spawnSync } from 'node:child_process';
import { readdirSync, statSync } from 'node:fs';
import { join, extname } from 'node:path';

/** Directories jscpd must scan. Every one of them has to exist — a typo here is a silent hole. */
const PATHS = ['apps', 'packages'];
/** Duplication threshold in percent, same value the rule states. */
const THRESHOLD = '5';
/** Extensions counted as reach. Keep in sync with what jscpd is configured to read. */
const EXTENSIONS = ['.ts', '.tsx', '.js', '.jsx', '.mjs', '.cjs'];
/** Directories never worth scanning — they would inflate the reach number without being reviewed. */
const SKIP_DIRS = new Set(['node_modules', 'dist', 'build', 'coverage', '.git', '.turbo', '.next']);

/**
 * Count the files this gate is about to hand to jscpd.
 *
 * @param {string} dir Directory to descend into.
 * @returns {number} Number of matching files below `dir`.
 */
function countFiles(dir) {
  let n = 0;
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    if (entry.isDirectory()) {
      if (SKIP_DIRS.has(entry.name)) continue;
      n += countFiles(join(dir, entry.name));
    } else if (entry.isFile() && EXTENSIONS.includes(extname(entry.name))) {
      n += 1;
    }
  }
  return n;
}

let reach = 0;
for (const p of PATHS) {
  try {
    if (!statSync(p).isDirectory()) throw new Error('not a directory');
  } catch {
    console.error(`cpd-gate: RED — configured path "${p}" does not exist. Fix PATHS; do not drop it.`);
    process.exit(1);
  }
  reach += countFiles(p);
}

if (reach === 0) {
  console.error(`cpd-gate: RED — 0 files under [${PATHS.join(', ')}]. A duplication gate that scans`);
  console.error('  nothing is green forever. Check PATHS and EXTENSIONS before touching the threshold.');
  process.exit(1);
}
console.log(`cpd-gate: reach ${reach} file(s) under [${PATHS.join(', ')}], threshold ${THRESHOLD}%`);

const res = spawnSync(
  'npx',
  ['jscpd', ...PATHS, '--reporters', 'console', '--threshold', THRESHOLD],
  { encoding: 'utf8', shell: process.platform === 'win32' },
);
const out = `${res.stdout ?? ''}${res.stderr ?? ''}`;
process.stdout.write(out);

if (res.error) {
  console.error(`cpd-gate: RED — could not run jscpd: ${res.error.message}`);
  process.exit(1);
}

// jscpd prints one row per format: `<format> | <files> | <lines> | <tokens> | <clones> | <dup> (<pct>)`.
// Sum the SECOND column across those rows — that is jscpd's own answer to "how many files did I read".
const analysed = [...out.matchAll(/^\s*(\w[\w+#-]*)\s*\|\s*(\d+)\s*\|/gm)].reduce(
  (sum, m) => sum + Number.parseInt(m[2], 10),
  0,
);
if (analysed === 0) {
  console.error('cpd-gate: RED — jscpd reported no analysed files (or its output could not be read).');
  console.error(`  This gate refuses to translate that into "clean". Reach counted here: ${reach}.`);
  console.error('  If jscpd changed its console table, fix the parser — do NOT delete this branch.');
  process.exit(1);
}
console.log(`cpd-gate: jscpd analysed ${analysed} file(s) · exit ${res.status ?? 'null'}`);
process.exit(res.status ?? 1);
```

<!-- END file cpd-gate.mjs -->

### Der Resolver-Block → `eslint.config.mjs` **jeder** App

Anzupassen: der tsconfig-Pfad. Dazu `eslint-import-resolver-typescript` als **direkte** devDependency
**dieser App** — nicht im geteilten Preset, nicht in der Wurzel.

<!-- BEGIN file eslint-resolver.mjs -->

```js
// apps/<app>/eslint.config.mjs — the settings block WITHOUT which `boundaries` is a no-op.
//
// Reference that is verified to work: global-login/apps/login/eslint.config.mjs:46-48 plus
// apps/login/package.json:43 `"eslint-import-resolver-typescript": "^4.4.5"` — the resolver is a
// DIRECT devDependency of the app, because eslint-module-utils resolves it relative to the linted
// source file. Inheriting it transitively from a shared preset does not resolve under pnpm.
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const rootDir = dirname(fileURLToPath(import.meta.url));

export default [
  // … your other config objects …
  {
    files: ['src/**/*.{ts,tsx}'],
    settings: {
      // WITHOUT this block every aliased import is silently DROPPED before the rule runs.
      'import/resolver': {
        typescript: { project: join(rootDir, 'tsconfig.app.json') },
      },
      'boundaries/elements': [
        { type: 'app', pattern: 'src/app/*' },
        { type: 'routes', pattern: 'src/routes/*' },
        { type: 'pages', pattern: 'src/pages/*' },
        { type: 'widgets', pattern: 'src/widgets/*' },
        { type: 'features', pattern: 'src/features/*' },
        { type: 'entities', pattern: 'src/entities/*' },
        { type: 'shared', pattern: 'src/shared/*' },
      ],
    },
    rules: {
      // Pin the plugin's MAJOR: v6 deprecates no-private/entry-point, v7 drops them, and a
      // deprecation is not a lint finding — a gate rule can vanish at a routine major upgrade.
      'boundaries/element-types': ['error', { default: 'disallow', rules: [/* your FSD rules */] }],
    },
  },
];
```

<!-- END file eslint-resolver.mjs -->

### Der Kanarienvogel → Dateien in der App

Anzupassen: die Slice-Pfade und der Alias im Import. **Der Import muss ein ALIAS sein** — ein
relativer Import wird auch von einem toten Resolver erkannt und macht den Kanarienvogel wertlos.
Die Fixture liegt im **Slice-Root**, nicht unter `__tests__/`: Test-Globs schalten `boundaries`
üblicherweise ab, dort wäre sie stumm. Die Positivkontrolle im Test braucht zusätzlich eine Datei
mit einem **legalen** Alias-Import (`legal-import.ts` neben der Fixture), für die unten kein Block
steht — fehlt sie, scheitert der Test laut, nicht still (gemessen, ESLint 9.39.4:
`NoFilesFoundError: No files matching '…/legal-import.ts' were found.`). **Über dem Import steht
keine Disable-Direktive** — auch keine, deren Beschreibung „nicht deaktiviert" sagt:
`// eslint-disable-next-line -- …` schaltet jede Regel der nächsten Zeile ab, die Beschreibung ist
nur Text (gemessen: 0 Meldungen, 1 unterdrückt; ohne die Zeile 1 Meldung). Grün hält den
App-weiten Lint stattdessen das Lint-**Skript**: `eslint . --max-warnings=0 --ignore-pattern
<Pfad der Fixture>` endet mit Exit 0, während die ESLint-API im Test die Datei weiter sieht.

<!-- BEGIN file boundary-canary.ts -->

```ts
// apps/<app>/src/features/canary/boundary-canary.ts
//
// GATE CANARY — this file is SUPPOSED to be a lint error. It is not dead code and not a mistake:
// it is the only proof that `boundaries/element-types` is wired at all.
//
// The import is ALIASED on purpose. A relative `../../app/router` errors even with a dead resolver,
// so a canary built from one reports a green gate that does not exist.
// It lives in the slice root, NOT under `__tests__/`: those paths usually switch `boundaries` off.
//
// features -> app is an UPWARD import and therefore illegal under FSD (`10-fsd`).
// NO disable directive above the import — not even one whose description says "not disabled":
// `eslint-disable-next-line -- …` silences EVERY rule on the next line, the description included,
// so the canary could never fire (measured, ESLint 9.39.4: 0 messages, 1 suppressed). Keep the
// app-wide lint green from the lint SCRIPT instead: `--ignore-pattern` with this file's path.
import { router } from '@app/router';

export const canary = router;
```

<!-- END file boundary-canary.ts -->

<!-- BEGIN file boundary-canary.test.ts -->

```ts
// apps/<app>/src/features/canary/__tests__/boundary-canary.test.ts
//
// Runs the project's OWN shipped ESLint config over the canary and asserts the exact rule id and
// severity — `30-quality`: a canary mutates the GATE, not the fixture. Rebuilding a config inside the
// test would only prove that the rebuilt config works.
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { ESLint } from 'eslint';
import { describe, expect, it } from 'vitest';

const HERE = dirname(fileURLToPath(import.meta.url));
const APP_ROOT = resolve(HERE, '../../../..'); // __tests__ -> canary -> features -> src -> app root
const CANARY = join(HERE, '..', 'boundary-canary.ts');
const LEGAL = join(HERE, '..', 'legal-import.ts'); // any file with a legal, aliased import

const RULE = 'boundaries/element-types';

/**
 * Lint one file with the app's own flat config.
 *
 * @param file Absolute path of the file to lint.
 * @returns The rule's messages plus everything ESLint said about the file.
 */
async function lint(file: string): Promise<{ ruleMessages: ESLint.LintResult['messages']; all: ESLint.LintResult }> {
  const eslint = new ESLint({ cwd: APP_ROOT });
  const [result] = await eslint.lintFiles([file]);
  return { ruleMessages: result.messages.filter((m) => m.ruleId === RULE), all: result };
}

describe('FSD boundary gate is wired (not a 100% no-op)', () => {
  it('flags the ALIASED illegal import with the exact rule id at severity error', async () => {
    const { ruleMessages, all } = await lint(CANARY);
    // An ignored file yields zero messages, which reads exactly like a clean file. Rule it out first.
    expect(all.messages.map((m) => m.message).join(' ')).not.toMatch(/ignored/i);
    expect(ruleMessages.length, `${RULE} did not fire — the resolver is probably missing`).toBeGreaterThan(0);
    expect(ruleMessages[0].severity, `${RULE} is not at error severity`).toBe(2);
  });

  it('POSITIVE CONTROL: a legal aliased import produces no boundary error', async () => {
    // Without this a rule that rejects EVERYTHING would pass the assertion above.
    const { ruleMessages, all } = await lint(LEGAL);
    expect(all.messages.map((m) => m.message).join(' ')).not.toMatch(/ignored/i);
    expect(ruleMessages).toEqual([]);
  });
});
```

<!-- END file boundary-canary.test.ts -->

### Die Zeilenenden → `.gitattributes` in der Projektwurzel

**Dies ist ausdrücklich KEIN weiterer Fail-open.** Die Gates oben werden falsch **grün**; dieses hier
wird falsch **rot** — `format:check` meldet ab dem ersten Klon Hunderte Befunde, die niemand
geschrieben hat. Der Unterschied gehört mitgesagt, sonst verwässert er den Begriff, den dieses Skill
trägt. Ein Gate, das immer rot ist, wird genauso zuverlässig abgeschaltet wie eines, das immer grün
ist — nur lauter.

Anzupassen: der Pfad der generierten Datei am Ende, und die zwei auskommentierten Windows-Zeilen,
falls das Repo `.bat`/`.cmd` wirklich führt. Gemessen an einem Vorlagen-Monorepo ohne diese Datei:
997 von 1045 Dateien tragen mindestens ein CR-Byte, und `prettier --check .` meldet 207 Dateien bei
Exit 1. Mit der Datei: 8 von 1046 (nur gif/mp4/png; die neue Datei zählt selbst mit) und 12 Befunde —
**der Fix senkt 207 auf 12, nicht auf 0**; die restlichen 12 sind vorbestehende Formatdrift und ein
eigener Vorgang. Die CR-Zahlen sind am 2026-09-22 mit Kommando (2) unten nachgemessen (Vorlage
`ba08ca3`, Wegwerf-Klon): 997/1045 vorher, 8/1046 nachher, 964/1046 mit nur `*.sh text eol=lf`.

<!-- BEGIN file .gitattributes -->

```gitattributes
# .gitattributes — the working tree gets LF, whatever `core.autocrlf` says.
#
# THE BUG THIS EXISTS FOR
#   Without this file every checkout on a machine with `core.autocrlf=true` — the Windows default,
#   written system-wide by the Git for Windows installer — puts CRLF into the working tree. Measured
#   on a template monorepo: 997 of 1045 files carry at least one CR byte and `prettier --check .`
#   reports 207 files at exit 1. From the first clone, forever, for everyone on Windows.
#
# WHAT IS LOAD-BEARING
#   The single line `* text=auto eol=lf`. `*.sh text eol=lf` is NOT the fix and naming it as one
#   makes the repair ~29x too small: measured, `*.sh` covers 34 of 989 text files, and the
#   extension-less husky hooks are not among them. Every explicit line below is documentation and
#   hardening — with the `*` line present they change the attr column, not the bytes.
#
# WHO ACTUALLY GETS HURT
#   A CR in a hook BODY only bites a POSIX host running a repo checked out under Windows. Git-Bash's
#   own bash 5.2.37 swallows it (`ARG=[lint-staged]`, byte-identical to the LF variant), which is
#   exactly why this stays invisible where it is created; a real POSIX `sh` carries it into the last
#   argument (`dash -e` -> `ARG=[lint-staged\r]`). A Linux CI runner clones with
#   `core.autocrlf=false` and never sees CRLF at all — do not sell this as a CI fix.

# ── the load-bearing line ─────────────────────────────────────────────────────────────────────────
* text=auto eol=lf

# ── hooks and shell scripts ───────────────────────────────────────────────────────────────────────
# The husky hooks have no extension, so `*.sh` never matches them. The `*` line above already covers
# them; these lines pin `text` instead of leaving it to the binary heuristic.
.husky/*                     text eol=lf
*.sh                         text eol=lf
*.bash                       text eol=lf

# ── Windows-only scripts ──────────────────────────────────────────────────────────────────────────
# PowerShell reads LF, so `.ps1` stays LF. `.bat`/`.cmd` are the only files that may want CRLF —
# uncomment those two lines ONLY if the repo really carries such files.
# NEVER write this as a brace glob: git does not expand braces in attribute patterns. Measured —
# `*.{cmd,bat,ps1} text eol=crlf` then `git check-attr text eol -- a.cmd` answers `text: auto` /
# `eol: lf`, i.e. it fell straight through to the `*` line; the same file with `*.cmd text eol=crlf`
# answers `text: set` / `eol: crlf`. A brace line is a silent no-op, and no path-based acceptance
# criterion can see it.
*.ps1                        text eol=lf
# *.bat                      text eol=crlf
# *.cmd                      text eol=crlf

# ── text formats (documentation; the `*` line already covers them) ────────────────────────────────
*.ts                         text eol=lf
*.tsx                        text eol=lf
*.js                         text eol=lf
*.jsx                        text eol=lf
*.mjs                        text eol=lf
*.cjs                        text eol=lf
*.json                       text eol=lf
*.jsonc                      text eol=lf
*.md                         text eol=lf
*.css                        text eol=lf
*.html                       text eol=lf
*.yml                        text eol=lf
*.yaml                       text eol=lf
*.toml                       text eol=lf
*.sql                        text eol=lf
*.prisma                     text eol=lf
*.py                         text eol=lf
*.dart                       text eol=lf
*.code-workspace             text eol=lf
.gitkeep                     text eol=lf
.editorconfig                text eol=lf
.env.example                 text eol=lf

# ── binaries: never converted, never diffed as text ───────────────────────────────────────────────
# A PNG signature contains a literal 0x0D byte. Without these lines the `text=auto` heuristic is the
# only thing standing between it and a rewrite.
*.png                        binary
*.jpg                        binary
*.jpeg                       binary
*.gif                        binary
*.webp                       binary
*.avif                       binary
*.ico                        binary
*.mp4                        binary
*.webm                       binary
*.woff                       binary
*.woff2                      binary
*.ttf                        binary
*.pdf                        binary
*.zip                        binary

# ── generated: keep them out of review diffs ──────────────────────────────────────────────────────
# Adjust the second path to whatever your router actually generates; delete the line if nothing does.
pnpm-lock.yaml               text eol=lf linguist-generated=true -diff
apps/web/src/routeTree.gen.ts text eol=lf linguist-generated=true -diff
```

<!-- END file .gitattributes -->

**Verifizieren — und die zweite Zahl ist die tragende.** Das naheliegende Kommando allein genügt
nicht: `git ls-files --eol` **verschluckt einen unbekannten Pfad stumm und endet mit Exit 0**, ein
Kriterium aus drei festen Pfaden kann also schweigend nur die halbe Antwort drucken. Nimm beide:

```bash
# (1) attribute per path — expected: 2x `i/lf  w/lf  attr/text eol=lf`, 1x `i/-text w/-text attr/-text`
git ls-files --eol -- .husky/pre-commit .husky/commit-msg <a-tracked-binary-file>

# (2) the REACH: how many files does a fresh checkout bring out with a CR byte?
#     `-U` is load-bearing: without it Git-Bash's grep strips a CR at line end before matching, and
#     the count is a constant (measured on the template: 8 before AND after, where -U says 997 -> 8).
tmp=$(mktemp -d) && git -c core.autocrlf=true checkout-index -a --prefix="$tmp/" \
  && find "$tmp" -type f -exec grep -aUl $'\r' {} + | wc -l && find "$tmp" -type f | wc -l
# template before: 997 / 1045   ·   after, expected: 8 / 1046 (gif/mp4/png only; +1 = .gitattributes)

# (3) does it need a renormalisation commit? Only if `i/crlf` or `i/mixed` shows up here —
#     `i/-text` is every binary file and expected, `i/none` an empty one.
git ls-files --eol | awk '{print $1}' | sort | uniq -c
```

**Es gibt schon eine `.gitattributes` — dann gilt diese Politik, und sie ist Pflicht.** Die Datei
**existiert** ist kein Beweis, dass die Eigenschaft **geschützt** ist; genau diesen Proxy verbietet
`30-quality`. Gemessen über elf Repos: sieben ungeschützt, und eines davon führte eine
`.gitattributes` mit drei engen Pfaden und **ohne** `*`-Muster — es stand in der Spalte „behoben" und
trug mit 4074 von 4170 CR-Dateien den größten Schaden im Sample. Prüfe deshalb die **Zeile**, nicht
die Datei: `grep -aqE '^\*[[:space:]]+text=auto[[:space:]]+eol=lf' .gitattributes`. Trifft sie nicht,
**ergänze** die `*`-Zeile ganz oben und lass alles Bestehende stehen. Oben, weil in `.gitattributes`
bei mehreren Treffern die **spätere** Zeile gewinnt, nicht die spezifischere — gemessen:
`*.cmd text eol=crlf` vor `* text=auto eol=lf` ergibt für `a.cmd` `eol: lf`, dahinter `eol: crlf`.
Ans Ende gehängt, überschriebe die `*`-Zeile jede bestehende Ausnahme. **Ersetze** die Datei nur,
wenn ihre Zeilen nachweislich tot sind (Brace-
Globs, Pfade, die es nicht mehr gibt). **Melde** statt zu ändern, wenn `git ls-files --eol` auch nur
eine Zeile `i/crlf` oder `i/mixed` zeigt: dort schreibt die `*`-Zeile Arbeitsbaum-**Bytes** um, das
ist ein Renormalisierungs-Commit mit eigenem Review und kein Nebenbei-Fix (gemessen: eines der elf
Repos hat `i/crlf=2`).

## RED verifizieren, sonst ist es nur eine Behauptung

1. **cpd:** `PATHS` testweise auf ein leeres Verzeichnis zeigen lassen → `cpd-gate: RED — 0 files`,
   Exit 1. Zurückstellen → die Reichweitenzahl steht wieder da. Danach zwei Dateien mit echtem
   Duplikat anlegen → Exit 1 mit `ERROR: jscpd found too many duplicates`.
2. **Boundaries:** den Resolver-Block auskommentieren und den Kanarienvogel-Test fahren. Er **muss**
   fallen (`boundaries/element-types did not fire`). Wieder einkommentieren → grün. **Nur diese
   Mutation zählt** — die Fixture zu ändern beweist nichts über das Gate.
3. **Zeilenenden:** die Zeile `* text=auto eol=lf` aus der neuen `.gitattributes` **entfernen** und
   nur `*.sh text eol=lf` stehen lassen, dann Kommando (2) oben erneut fahren → die CR-Zahl muss
   zurück in die Hunderte springen. Genau diese Mutation prüft die Behauptung, `*.sh` sei der Fix.
   Zurücknehmen → wieder 8. Zweite Mutation, die die Härtung von der Ursache trennt: die
   `.husky/*`-Zeile entfernen → die attr-Spalte fällt von `text eol=lf` auf `text=auto eol=lf`, die
   CR-Zahl bleibt unverändert (in der Vorlage 8, nur die Binärdateien). Die Datei ist der
   Produktionspfad; mutiert wird in ihr, nicht daneben. Springt die Zahl bei der ersten Mutation
   **nicht**, prüfe zuerst das Kommando: ohne `-U` zählt Git-Bashs grep kein CR am Zeilenende.
4. Alle Ausgaben in den PR schreiben, nicht „lief rot".

## Ehrliche Grenzen

- **Das cpd-Gate zählt Dateien, nicht Qualität.** Reichweite > 0 heißt nur, dass gemessen wurde.
- **Die Reichweitenzahl des Skripts und jscpds eigene Zahl sind zwei verschiedene Messungen**, und das
  ist Absicht: die erste kann die pfadlose Form nicht haben, die zweite kann eine falsch konfigurierte
  Erweiterungsliste aufdecken. Weichen sie stark ab, ist die Konfiguration schief — kein Grund, eine
  der beiden abzuschalten.
- **Der Kanarienvogel deckt eine Regel ab, nicht alle.** `no-private`/`entry-point` brauchen je eigene
  Fixtures; ohne die bleibt ihr Verschwinden bei einem Major unsichtbar.
- **agent-core kann das nicht für dich einbauen.** Es hat keine `package.json`-Scaffold-Fläche
  (`55-templates`: neue Projekte starten aus dem Claude-Template); der Rollout ist ein PR pro Repo,
  und er färbt CI beim ersten Lauf rot — das ist der Sinn, aber es gehört bewusst geplant.
