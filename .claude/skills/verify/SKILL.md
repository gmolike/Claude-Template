---
name: verify
description: 'Den GEÄNDERTEN Flow real fahren und das Ergebnis mit einer Belegzahl protokollieren — nicht nur Tests grün melden. Liest zuerst den Projekt-Kontext (package.json-Scripts, README, Projektstandards), startet App/Service unter der ECHTEN Laufzeit, löst genau den geänderten Pfad aus und trennt hart: visuelle Verifikation ist mit Vermerk verschiebbar, der Daten-Round-Trip nie. Beantwortet vier Fragen an jedes Grün — Laufzeit, Richtung (auch der Positivfall), Läufer (CI-Ergebnis SHA-gebunden nach dem Push) und Umgebung. Nutze vor jedem Commit an Produktcode und nach jedem Push.'
allowed-tools: Read, Glob, Grep, Bash, Write, Edit
---

# Verify

Dieses Skill ist der **Mechanismus hinter der Pflichtregel** aus `30-quality`
(„Drive the changed flow end-to-end via the `verify` skill"). Es beantwortet **eine** Frage mit
Beleg: *Läuft der Pfad, den ich gerade geändert habe, in Wirklichkeit?*

> **Grüne Tests sind kein Verify.** Tests prüfen, was jemand aufgeschrieben hat. Verify prüft, was
> die Software tut. Beides ist Pflicht, keins ersetzt das andere.

> **Prosa deutsch, Code/Identifier/Kommandos englisch** (Repo-Konvention).

## Wann invoken

- **Vor jedem Commit**, dessen Diff Produktcode berührt (`30-quality`: Definition of Done).
- Nach jedem Fix, für den behauptet wird „ist behoben" — bevor das jemand glaubt.
- Wenn ein Agent-Report „verified" sagt, aber keine Zahl liefert (dann fährst du es nach).
- **Nach dem Push** für das CI-Bein (Frage 3) — der lokale Gate-Lauf beantwortet es nicht.
- **Nicht nötig** bei Diffs ohne Runtime-Fläche: tests-only, docs-/markdown-only.

## Die harte Trennung (ADR-0022) — vorab, nicht am Ende

„Verify" ist **kein** Monolith. Es gibt zwei Flächen mit völlig verschiedenen Kosten:

| Fläche | Braucht | Verschiebbar? |
| --- | --- | --- |
| **Visuell** (UI ansehen, Screenshots, UX) | Browser, Live-Session, Auth, Window-Management | **Ja — mit Vermerk** |
| **Daten-Round-Trip** (Contract/Schema/Serialization) | nichts davon — reine Datenfunktion | **Nein. Nie.** |

- **Visuell verschiebbar heißt: mit Namen und Termin.** Ein blankes „browser-verify deferred" ist
  **kein** Aufschub, sondern ein stiller Skip und zählt als *nicht verifiziert*. Der Vermerk gehört
  in den Report (Vorlage unten): **wer** fährt es, **wann**.
- **Der Round-Trip wandert nie mit.** Er ist browserfrei, also kann kein Browser-Blocker ihn
  entschuldigen. Kernsatz aus `30-quality`: *a schema/contract/serialization change ALWAYS has an
  automatable round-trip surface — a golden test is required even when the visual surface defers to
  manual QA.* Muster, Template und Begründung stehen an **genau einer** Stelle:
  Skill `contract-golden-test` (Web-Overlay `31-quality-web` verweist ebenfalls dorthin).

**Belegter Vorfall (2026-07-18):** Jeder UI-Build-Agent meldete „Browser-Verify deferred (braucht
Live-Session/Auth/window-management)" — und damit wurde die **komplette Speicher-/Lade-Runde nie
gefahren**. Ein reiner Daten-Round-Trip (`build → serialize → validate → read`, ohne Browser) hätte
die v1/v2-Slot-Divergenz (HTTP 400, v2-Profile lautlos übersprungen) sofort gefangen.

## Ablauf

### 1. Projekt-Kontext lesen — Kommandos NICHT raten

agent-core kennt die Startbefehle deines Projekts nicht. Lies sie, statt sie zu erfinden:

- `package.json` → `scripts` (`dev`, `start`, `preview`, `test`, `build`, `seed`, `db:*`) und
  Workspace-Layout (`apps/*`, `packages/*`); bei Monorepos: welches Paket ist betroffen?
- `README.md` / `docs/` → Setup-Schritte, benötigte Services (DB, Supabase, Emulator).
- `project-standards.md` / `CLAUDE.md` / `AGENTS.md` → projektspezifische Run-Konventionen.
- `.env.example` → welche Variablen der Flow braucht. **Fehlt eine Variable, ist der Lauf ungültig**
  — nicht „läuft halt nicht ganz". Erst beschaffen, dann fahren.
- Nicht-JS-Stacks analog: `build.gradle.kts`/`Makefile`/`*.csproj`/`pyproject.toml`.

> Existiert im Projekt bereits ein Start-Skill/Runbook, nimm **das** — dieses Skill ersetzt es nicht,
> es hängt die Nachweis-Pflicht daran.

### 2. Den geänderten Pfad bestimmen — aus dem Diff, nicht aus dem Bauch

„Die App startet" ist **kein** Verify. Leite aus `git diff`/`git status` ab:

- Welche Funktion/Route/Query/Migration hat sich geändert?
- Welcher **Einstiegspunkt** löst genau sie aus (Button, URL, CLI-Kommando, API-Call, Cron) — und in
  welcher **Aufrufform**? Argumentgestalt, Zahl der Aufrufe, welche Optionalparameter dort wirklich
  gesetzt sind. Ein Test, der eine Form aufruft, die die Produktion nie erzeugt (fünf Würfelnde in
  EINEM Array gegen N Einzelaufrufe mit je einem), wird auf Kommando rot und sichert nichts.
- Welche **beobachtbare Wirkung** beweist, dass sie lief (Response-Body, DB-Zeile, Log, Datei,
  UI-Zustand)? Diese Wirkung ist später deine Belegzahl.
- Berührt der Diff einen Contract (Schema, Wire-Format, Persistenz)? → Round-Trip ist **Pflicht**.
  Zum Erkennen den **Review check** aus `25-orchestration` bzw. Setup-Schritt 1 des Skills
  `contract-golden-test` fahren (grep die Typ-/Schema-Definition über alle Pakete), nicht dem
  Gedächtnis vertrauen.

### 3. App/Service starten — unter der echten Laufzeit

Mit den in Schritt 1 **gelesenen** Kommandos. Backgroundfähig starten, Port/URL notieren, auf
Bereitschaft warten (Health-Endpoint/Log-Zeile), Startfehler nicht wegignorieren. Der Start zählt
nur unter der Laufzeit, die auch in Produktion lädt: `tsx`, `vite-node` und der Testrunner bringen
Bundler-Auflösung mit und starten Quellen, die der Dienst selbst nicht laden kann (Frage 1 unten,
mit Messung).

### 4. Den Pfad auslösen und beobachten

- Bevorzugt **automatisiert und headless**: HTTP-Call, CLI-Aufruf, Skript, DB-Query. Das ist der
  billige Teil und läuft überall.
- **Fehlerpfad mitnehmen**, nicht nur den Happy Path — der Vorfall oben war ein *lautloser* Skip,
  kein Crash. Prüfe deshalb aktiv, ob etwas **still übersprungen** wurde (Anzahl vorher/nachher!).
  Und **beide Richtungen**: eine Ablehnung allein beweist nichts, solange der Positivfall gegen die
  echte Konfiguration fehlt (Frage 2 unten).
- UI-Anteil: im Browser öffnen und **hinsehen** (`31-quality-web`) — oder sauber verschieben (s. o.).
  Läuft der Browser gegen **abgefangene Routen**, lautet der Beleg exakt „bei DIESER Nutzlast rendert
  die Oberfläche so"; die **Reichweite der Vorrichtung** ist dann eine Zahl an beiden Enden
  (registrierte Regeln gegen Anfragen, die den echten Dienst erreicht haben), keine Selbstauskunft, und
  ein Auffang über die ganze Herkunft macht sie null statt klein. Belegt, an zwei Läufen: ein solcher
  Auffang ließ 73 gefilmte Schritte 0 Drahtgrenzen ausüben; und ein Prüfbericht meldete „alle Routen
  abgefangen", während die Konsole desselben Laufs durchgängig `AxiosError 500` trug — abgefangen
  waren nur die Routen dieses Bildschirms.

### 5. Mit Belegzahl protokollieren

`30-quality`, Gate-Evidenz: **„lief grün" ist keine Evidenz.** Belegt ist nur, was ohne den
Durchlauf nicht existieren könnte:

- gut: `POST /api/profiles → 201, 3 rows in profiles (vorher 0)`, `12 slots serialized, 12 read back`,
  `47 tests passed`, `HTTP 400 reproduced on the v1 payload, 200 after the fix`
- wertlos: „funktioniert", „verified", „sieht gut aus", „Tests grün"

## Der Daten-Round-Trip (nie verschiebbar)

Vier Schritte, alle ohne Browser: **build → serialize → validate → read** — der Producer baut, die
**Wire-Grenze** (`JSON.parse(JSON.stringify(x))`) serialisiert, das Save-Schema validiert die
**serialisierte** Form (nicht das In-Memory-Objekt — an dieser Reihenfolge hing der belegte HTTP 400),
der Read-/Migrations-Pfad liest sie zurück und muss dasselbe Objekt liefern.

Dazu **RED-Verify**: ein Round-Trip-Test, der gegen die **alte, kaputte** Implementierung nicht rot
wird, beweist gar nichts (`30-quality`, „Regression tests — verified RED, not assumed") — also die
alte (v1-)Migration einsetzen, fallen sehen, zurücktauschen.

Kanonischer Code-Schnipsel, lauffähiges Template und Varianten leben an **genau einer** Stelle:
Skill `contract-golden-test`. Hier absichtlich **nicht** wiederholt — eine zweite Kopie des Musters
driftet genauso wie eine zweite Kopie eines Contracts. Dort steht auch, **worauf** die Zusicherungen
zeigen (Abschnitt „Worauf die Zusicherung zeigt: Wert, Feldmenge, Grenzwert"): „validiert" heißt nicht
„parst" — ein `success: true` besteht auch, wenn ein mitdeklarierter Altname durchgeht und der Neuname
`undefined` bleibt, also werden `success` UND der Wert zugesichert.

## Vier Fragen an jedes Grün

Vier Belege, ein Satz: **„grün" ohne benannte Instanz ist kein Beleg.** Zu jeder der vier Fragen
gibt es einen Vorfall, in dem genau ihr Fehlen einen Defekt durchgelassen hat, und jede hat ihre
Stelle in der Report-Vorlage. Eine Frage mit `n/a` zu beantworten ist erlaubt — ohne den Grund
dahinter nicht.

### Frage 1 — unter welcher Laufzeit lief es?

`lint`, `typecheck`, Vitest und Vite lösen Module über **Bundler-Semantik** auf, der Node-ESM-Resolver
nicht. Ein Workspace-Paket, dessen `main` auf `src/*.ts` zeigt und das keinen Build-Schritt hat, wird
zur Laufzeit von einem **anderen Auflöser** gelesen als von jedem Gate. Vier grüne Gates über einem
Dienst, der nie gestartet ist, sind deshalb kein Ausrutscher, sondern die Bauart.

Der **Smoke-Import unter blankem `node` ist Pflicht, nicht Rückfall** — er ist die einzige Messung,
die grün-und-kaputt von grün-und-lauffähig trennt. Dieselbe Quelle, vier Läufe, hier gemessen:

| Start | `export * from './common'` | `export * from './common.ts'` |
| --- | --- | --- |
| `npx tsx <entry>` | `EXPORTS=4` — **startet** | `EXPORTS=4` |
| blankes `node` | `FAIL=ERR_MODULE_NOT_FOUND` | `EXPORTS=4` |

- **Die reparierte Paketform behebt die Wurzel — die Messung ersetzt sie nicht.** Liest Node das
  Paket zur Laufzeit (`main` auf `src/*.ts`, kein Build-Schritt), gehören explizite Endungen und
  `"type": "module"` + `moduleResolution: "nodenext"` dazu — dann meldet ein `typecheck`, das das Paket
  erreicht, den Defekt selbst, aber mit wechselndem Code je Quelle (gemessen: `TS2835` für `'./user'`,
  `TS2307` für den gepunkteten Basenamen `'./queries/user.queries'`), also nie EINEN Code als Signatur
  festschreiben. Zwei Vorbehalte, beide gemessen: ohne `"type": "module"` bleibt auch NodeNext stumm,
  und in der Vorlage erreicht das Wurzel-`typecheck` das Paket gar nicht (16 Dateien, alle unter
  `apps/web/src`) — eine Diagnose, die niemand ausführt; die Reichweite des Gates gehört also VOR seine
  Verschärfung. Der Smoke-Import bleibt deshalb die Primärmessung, nicht der Rückfall (Paketform:
  `55-templates`).
- **Ein Werkzeug mit Bundler-Auflösung beweist nur sich selbst.** Die Zelle oben links ist der ganze
  Grund für diese Frage: `tsx` und Verwandte starten dieselbe Quelle erfolgreich, an der die
  Produktionslaufzeit scheitert — der grüne Lauf ist dann die Fehlerklasse, nicht ihr Ausschluss.
- **Der Smoke-Import gehört in eine `.mjs`-Datei, nicht in ein `node -e`.** Mehrzeiliges `-e` ist
  unter Git-Bash ein leeres Programm mit Exit 0, und jede Transportschicht frisst ein
  Backslash-Paar: aus `replace(/\\/g,'/')` in doppelten Anführungszeichen wird `/\/g` →
  `SyntaxError: missing ) after argument list`. Zweimal gemessen, an genau dieser Zeile.
- **`file:///$PWD` ist unter Git-Bash kaputt.** `$PWD` ist der MSYS-Pfad, das ergibt vier Slashes
  (`file:////tmp/...`) → `ERR_INVALID_FILE_URL_PATH`. Die Basis baut deshalb der Prozess selbst:

```js
// scripts/smoke.mjs — ein Argument: der Entrypoint, relativ zur Repo-Wurzel
const base = "file:///" + process.cwd().replace(/\\/g, "/") + "/";
const m = await import(new URL(process.argv[2], base));
console.log("EXPORTS=" + Object.keys(m).length);
```

`node scripts/smoke.mjs packages/shared-types/src/index.ts` → `EXPORTS=<n>` (in der Messung oben
`EXPORTS=4`). Die Zahl kann ohne den echten Ladevorgang nicht entstehen; `ERR_MODULE_NOT_FOUND` an
derselben Stelle ist der Defekt, den kein Bundler-Gate sehen kann.

### Frage 2 — in welche Richtung wurde geprüft?

Fail-closed wird fast immer nur gegen **Ablehnung** verifiziert. Eine Allowlist, die nie befüllt
wurde, lehnt alles ab und ist von einer korrekten nicht zu unterscheiden: Tests grün (sie injizieren
ihre eigene Registry — genau die Zeile, die in Produktion fehlt), Typecheck grün (`entities: []` ist
typkorrekt), kein Fehler im Log, denn die Ablehnung **ist** die dokumentierte Antwort. „Immer rot"
sieht dann aus wie bestandene Sicherheit.

- **Beide Nachweise, nicht einer.** Jede Allowlist, Registry und Berechtigungstabelle muss zeigen,
  dass sie das Verbotene ablehnt **und** dass sie das Erlaubte durchlässt.
- **Sortiert ein Prüfmittel seine Prüflinge in Klassen, braucht jede Klasse ihren eigenen
  Kanarienvogel** — die Ablehn-Richtung, nicht die Positivkontrolle: gefragt ist, ob ein Prüfling dieser
  Klasse an seiner EIGENEN Zusicherung scheitern kann, nicht, ob er irgendwie rot werden kann. Belegt:
  ein Abnahmelauf über 73 Schritte in fünf Klassen; eine klassenunabhängige Sichtfeldprüfung konnte
  jeden Schritt rot färben, aber in vier Klassen (28 Schritte) fing der Zweig die gescheiterte
  Gegenprobe ab, schrieb „GEGENPROBE GESCHEITERT" ins Band und setzte den Ausgang trotzdem auf
  bestanden. Billigste Gegenprobe beim Bauen: je Zweig fragen, welche Zuweisung den Ausgang setzt —
  steht sie unbedingt außerhalb des `try`, kann der Zweig nicht fallen. Die Form braucht kein `catch`
  (`verdict()` in agent-cores `src/i18n-parity.test.ts` assertiert nur unter `if (ENFORCING)` — dort
  deklariert, nicht defekt), und die Reichweite gehört je Klasse ausgegeben, wie dort `reach:` je
  Familie.
- **Die Positivkontrolle läuft gegen die ECHTE Konfiguration**, nie gegen eine im Test injizierte —
  sonst prüft sie die Testvorrichtung statt den Dienst —, **und mit DERSELBEN Kommandoform**: eine
  Kontrolle ohne die Alternation, ohne die Pipe oder mit einem anderen Werkzeug zertifiziert die Suche
  nicht, die sie decken soll (belegter Fall: eine alternationslose Kontrolle über einer `grep`-Suche,
  deren Alternation in BRE nie traf — 0 Treffer, Exit 1, und beides las sich wie „es gibt nichts").
  Hausbeispiel, selbst gefahren:
  `[emergency-marker golden] impls: 3/3 (sh+ps1+ts-plugin) · scenarios: 7 · decisions: 21`, davon
  vier Szenarien mit `allowed=true`, gefahren gegen die **ausgelieferten** Hook-Kopien.
- **Wer `default deny` einführt, zeigt den Schreibpfad.** Ein leerer Default ohne Aufrufer mit echten
  Daten ist unfertig, nicht sicher. Ist er absichtlich leer, steht der Grund als Kommentar am Ort —
  Muster im Haus: `shared/editors.json:7` und `:32` sagen, warum `sinks` leer ist und leer bleibt.
- **Als Erkennungshilfe, nicht als Gate:** `: []`, `?? []`, `new Map()` in Konstruktoren und
  Options-Defaults von Registry-/Gate-Typen greppen. Die rohe Signatur trifft in agent-cores eigenem
  `src/` **68**-mal (25 außerhalb der Tests), fast nur Akkumulatoren — als Automat wäre sie ein
  Ermüdungsgenerator und damit selbst ein Fail-open-Kandidat.

### Frage 3 — auf welchem Läufer lief es?

Der lokale Gate-Lauf und CI sind nicht dieselbe Prüfung: anderes Betriebssystem, kalter Cache,
andere Zone und Sprache. Ein Push, dessen Ergebnis niemand gelesen hat, ist kein abgeschlossener
Schritt — und ein CI-Ergebnis ohne SHA-Bindung antwortet für einen fremden Commit.

- **Primär, PR-gebunden:** `gh pr checks <nr> --json name,bucket,state`. Es sieht auch
  Nicht-Actions-Checks — hier gemessen: drei Checks, darunter ein `Cloudflare Pages`, für das
  `gh run list` strukturell blind ist. `bucket` ist `pass|fail|pending|skipping|cancel`,
  **Exit 8 = pending**, und `--watch` (mit `--fail-fast`, `-i <sek>`) wartet gebunden statt endlos.
- **Rückfall ohne PR:** `gh run list --commit <sha>`, nie `--limit 1`. Gemessen: `--limit 1` meldete
  `success` für einen fremden Merge-Commit auf `main`, während `--commit <HEAD>` für denselben Stand
  leer blieb — **beide mit Exit 0.**
- **Leere Ausgabe bei Exit 0 vereint vier Zustände** — kein CI konfiguriert / Lauf noch nicht
  eingereiht / `gh` nicht angemeldet bzw. falsches Repo / **der Push ist nie angekommen**. Das ist eine
  fehlende Prämisse, kein Bestanden: benenne, welcher der vier es ist. Den vierten schließt nur der
  gedruckte SHA aus: `git ls-remote origin refs/heads/<branch>` muss deinen Commit NENNEN — für einen
  Ref, den das Remote nicht kennt, druckt es nichts und endet mit 0. RED-verifiziert: die
  Exit-Code-Variante (`… >/dev/null || fail`) meldet für genau so einen Branch grün, der
  Ausgabevergleich meldet rot, Positivkontrolle auf `main` grün. Vergleiche die **Ausgabe**, nie den
  Exit-Code.
- **Eine Dauer ist emittiert und trotzdem kein Beleg.** Die volle Suite dieses Repos trägt vier eigene
  Werte — bei 57 Dateien/733 Tests `seconds=146.4` lokal gegen `seconds=174.2` in CI (dort rot) und am
  selben Tag 348 s ausdrücklich grün, einen Tag später `Duration 77,05 s` bei 62/773. Belegkraft hat
  erst das **Verhältnis mit Bezugsgröße** („12,9 s → 8,3 s über 43 Fixtures"), nie die nackte Zahl, und
  wer eine Zeit zitiert, nennt Maschine und Wiederholungszahl daneben. Als **Signatur** eines
  registrierten Flakes ist eine Laufzeit zulässig (Kopf von `vitest.config.ts`) — als Beleg einer
  Verbesserung nie.
- **Ein Hook-Gate emittiert im Normalfall gar nichts**, anders als CI: „kein Deny" ist deshalb kein
  Befund, sondern Stille. Befrage das Skript statt sie zu deuten — Payload nachbauen
  (`{"cwd":…,"tool_name":"Bash","tool_input":{"command":"cd <repo> && git commit -m probe"}}`) und
  hineinpipen; erwartet wird das Verdikt UND der genannte Repo-Pfad, dazu im selben Atemzug die
  Positivkontrolle mit `git status` statt `git commit`. Ob die Harness den Hook überhaupt startet, steht
  nur im Transkript (`"hookName":"PreToolUse"`, je Datensatz `"isSidechain"`), ob er ein Verdikt
  lieferte, erst im Typ desselben Datensatzes: `"type":"hook_cancelled"` mit `"timedOut":true` trägt
  denselben `hookName` und hat keins (gemessen: 490 von 814 `PreToolUse:Bash`-Datensätzen in
  Subagent-Transkripten, alle an fremden Hooks). Und Transkripte verfallen: hier gemessen 39
  abgeschlossene Läufe genau dieses Gates in Subagent-Datensätzen, 0 Abbrüche, 9 echte Denies, während
  das älteste erhaltene Transkript sechs Tage alt war. Wer einen Hook-Ausfall nicht IN der Sitzung
  misst, misst ihn nie.
- **Ein N-mal in Folge rotes Gate ist ein eigener Defekt**, unabhängig von seiner Ursache — ab dem
  dritten roten Lauf trägt „CI ist rot" keine Information mehr. Zählbar:
  `gh run list --branch <b> --limit N --json conclusion`.

### Frage 4 — in welcher Umgebung lief es?

Was in der Umgebung nicht festgenagelt ist, prüft die Umgebung statt den Code: Zeitzone, Locale,
Pfad-Trennzeichen, Zeilenenden, ICU-Umfang — und, weniger offensichtlich, der Arbeitsbaum selbst
(installierte Pakete, generierte Clients) und die Maschinenlast. Die Achsen, von denen der geänderte
Pfad liest, werden **gemessen und gepinnt**, nicht geerbt — und das Messergebnis gehört in die Ausgabe,
sonst ist der nächste Lauf wieder eine Selbstauskunft.

- **Die Leiter, in dieser Reihenfolge:** (a) den Wert zur **Laufzeit** setzen (`test.env` in der
  Vitest-Config) — nur das wirkt auf beiden Plattformen; ein `TZ` in `.env.test` erreicht
  `process.env` nie, weil der einzige Pfad dorthin über Vites **prefix-gefilterte** `env`-Menge
  läuft und `envPrefix` ungesetzt bleibt (nachgesehen in der installierten Quelle, vitest 4.1.10) —
  ein stiller No-op, der wie ein Fix aussieht; (b) die Suite ein **zweites Mal** mit gekippter Achse
  fahren; (c) Docker mit dem CI-Image als schwerste Stufe, nicht als Vorschrift.
- **Ein Fix gegen Umgebungsabhängigkeit ist erst belegt, wenn er in der ABWEICHENDEN Umgebung
  gemessen wurde.** „Lokal weiterhin grün" belegt nichts — lokal war es das schon vorher.
- **Eine Achse zu kippen genügt nicht, und der Name ist keine Messung.** Wer nur nach UTC kippt,
  verfehlt die Fälle, die erst unter einer dritten Zone auffallen; und derselbe Locale-Name kann
  verschiedene ctype-Regime tragen, also zählt das gemessene Verhalten, nie die Bezeichnung.
- **Der Gegenstand einer Messung ist ein ARBEITSBAUM, kein Commit.** Installierte Pakete, generierte
  Clients und der Abstand zum Push-Ziel gehen ein und stehen in keinem Commit. Nach `git fetch` gehören
  deshalb in die `Gegenstand:`-Zeile: der Abstand zu dem Ref, den dieser Branch wirklich aktualisiert
  (`git rev-list --left-right --count HEAD...@{upstream}`, ohne Upstream `origin/<default>`) UND zu
  `origin/<default-branch>` (`26-autonomy` verlangt beide), dazu die Versionen, von denen das Ergebnis
  abhängt (`pnpm ls <paket>`, Generat-Datum gegen Schema-Datum). Belegt: ein `typecheck` meldete 87
  Fehlerzeilen in 11 Dateien, davon 61 `Property … does not exist on type 'PrismaClient'`; nach
  `pnpm install --frozen-lockfile` + `pnpm db:generate` waren es 0. Beinahe ein Blocker-Bericht über
  nichts.
- **Eine Mutationsmessung braucht eine Klammer — mit Positivkontrolle.** Fingerabdruck der mutierten
  Datei vor und nach dem Lauf (`git hash-object -- <datei>`); weichen sie ab, ist das Ergebnis Messmüll
  und keine Teilreichweite. Aber `vorher == nachher` allein unterscheidet „unverändert UND mutiert"
  nicht von „unverändert UND nie mutiert": nenne den **erwarteten mutierten Blob**, sonst läuft ein
  Fremd-Reset vor der öffnenden Klammer lautlos durch. Belegt: ein Fremdschreibvorgang mitten in einem
  Playwright-Lauf ergab „5 rot / 8 grün"; der Wiederholungslauf mit Klammer ergab „13 von 13 fallen
  ohne den mutierten Zweig", danach 13 grün.
- **Maschinenlast ist eine Umgebungsachse — und sie fälscht ROT, nicht grün.** Vitest fordert im
  Run-Modus `max(availableParallelism − 1, 1)` Worker je Suite, zwei gleichzeitige Suiten also fast die
  doppelte Maschine. „Nur `Test timed out`, nie eine Assertion" taugt NICHT als Kennung: im belegten
  Fall (ein Playwright-Gate, sechs Versuche) kamen erst Timeouts, ab etwa Test 15 nach einem
  Dev-Server-Absturz Schnellfehler binnen 2–3 s und eine Assertion (`data: undefined` aus einer Query →
  `.map`-TypeError). Zwei Signaturen tragen: die **wechselnde Fehlermenge** (zwei Läufe derselben Suite,
  5 bzw. 2 rote Tests — was in JEDEM Lauf fällt, bleibt Code-Verdacht) und **Schnellfehler oder
  Prozesstod statt eines Fehlschlags an der Sache** (ab einem Punkt der Suite fällt alles in Sekunden,
  oder ein Worker stirbt mit einem Startfehler-Code). Dann Last senken (`VITEST_MAX_WORKERS` unter der
  gemessenen Parallelität; ein `pre-push`-Hook erbt die exportierte Env, und die Zuweisung sticht ein
  `maxWorkers` aus der Projekt-Config — bei Playwright `--workers=<n>` bzw. ein projekteigener Regler
  wie `PW_WORKERS`, wo er verdrahtet ist), wiederholen und am CI-Lauf des gepushten SHA entscheiden.
  Niemals mit `--no-verify`: das Verbot ist absolut (`20-workflow`). Wiederholt sich das Rot, gehört es
  ins BESTEHENDE Flake-Register des Projekts (in agent-core: Kopf von `vitest.config.ts`), nicht in ein
  zweites Zuhause.
- **Das Messgerät selbst ist eine Fehlerquelle.** Unter Git-Bash verschwindet `TZ` aus der Umgebung
  eines nativen Windows-Kindes, sobald der Wert eines von `/ _ . , :` oder ein Leerzeichen enthält:
  gemessen kommen `TZ=UTC` und `TZ=JST-9` an, `TZ=Asia/Tokyo` dagegen als `seen=undefined`
  (`resolved=Europe/Berlin`), während `FOO=Asia/Tokyo` unbeschadet durchkommt. Dieselbe Zuweisung
  unter PowerShell liefert `seen="Asia/Tokyo" resolved=Asia/Tokyo`. Das ist eine gemessene
  **Zeichenklasse**, keine TZ-Validität — und eine Beobachtung, keine Ursache.

## Gotchas (belegtes Repo-Wissen)

- **`file://` ist im Browser-Tool blockiert** (fetch/Module). Offline-Single-File-Builds über
  `python -m http.server` ausliefern, Vite `base: './'`.
- **TanStack Query in Automations-/Headless-Browsern**: `navigator` meldet offline, Queries bleiben
  ewig in `fetchStatus: 'paused'` → `networkMode: 'always'` setzen, sonst verifizierst du einen
  Ladespinner.
- **Vor dem Re-Test neu bauen.** Sonst prüfst du das alte Bundle und bestätigst dir den Fix, den du
  nie geladen hast. Dev-Server liest `.env` beim Start — nach Änderung neu starten; `preview`/`prod`
  **backen** `VITE_*` zur Build-Zeit ein.
- **PWA: der erste Load beweist nichts — der Service Worker antwortet vor dem Netz.** Ein Rebuild räumt
  seinen Precache nicht ab, die Seite zeigt also weiter das ALTE Bundle (ein fehlendes Element ist dann
  ein falsches Negativ), und derselbe Worker macht jeden `route()`-Mock lautlos wirkungslos — Playwright
  sieht die von ihm abgefangenen Anfragen nicht und empfiehlt dafür `serviceWorkers: 'block'` am
  Context; der Playwright-MCP-Server führt denselben Schalter als Startflag `--block-service-workers`
  (Server-Konfiguration, kein Werkzeugparameter). Er verhindert nur NEUE Registrierungen — Playwright
  überschreibt dafür `navigator.serviceWorker.register` (nachgelesen in `playwright-core`) —, ein
  Profil, das schon einen Worker trägt, behält ihn; und der MCP-Server startet per Default mit einem
  persistenten Profil je Workspace, claude-in-chrome mit dem echten. Lies deshalb VOR jeder Assertion
  die Identität des geladenen Builds (gehashter Asset-Name im ausgelieferten HTML; eine per `define`
  injizierte Version nur, wo die App sie liefert — zwei Deploys derselben Versionsnummer sind
  ununterscheidbar) und erkenne den Worker falsifizierbar per
  `navigator.serviceWorker.getRegistrations()` bzw. `.controller`, statt „ist das eine PWA?" zu raten;
  gegen ein Profil mit Worker helfen `unregister()` + `caches.delete()` + Neuladen. Ein Update-Toast
  ist kein Hebel — er erscheint je nach Timing gar nicht.
- **Ein Automations-Browser kann ein gültiges Video nicht dekodieren und feuert KEIN `error`.** Gemessen:
  `readyState` bleibt 0, `networkState` 2, weder `loadedmetadata` noch `error` feuern, `window.load`
  kommt nie — nur der Harness-Timeout merkt es, ein `onError`-Fallback ist dort strukturell tot; wer
  absichern will, pollt `readyState` gegen eine Frist. `canPlayType` taugt nicht als Weiche (derselbe
  Build meldete `"probably"` für den erfundenen Codec `vp99`), und `<video>`-Kandidaten stehen **mp4 vor
  webm**: der Algorithmus nimmt den ersten, den die Engine zu können BEHAUPTET, und nimmt ihn nie zurück
  (`[webm, mp4]` lief in allen drei Playwright-Engines in die Zeitüberschreitung, `[mp4, webm]` spielte
  in allen drei).
- **Werkzeuge, die einen toten Prozess für lebend halten.** `tasklist /FI "PID eq <n>"` endet für
  lebende und tote PID BEIDE mit 0, und seine Leermeldung ist lokalisiert („INFORMATION: Es werden keine
  Aufgaben …") — eine Warteschleife über seinen Exit-Code oder über die englische Leermeldung ist
  fail-open; nimm `Get-Process -Id <n>` (`$null`, wenn tot). `$p.ExitCode` ist nach
  `WaitForExit()` leer, das Fertig-Signal kommt aus dem Log. `Monitor` ist bei 30 Minuten hart gekappt.
  Und ein `powershell -Command`-Einzeiler überlebt aus der Git-Bash nur in EINFACHEN Anführungszeichen —
  in doppelten frisst Bash `$env:` und `$p`.
- **rAF friert in versteckten Tabs** — Animationen/Polling im Hintergrundtab wirken „hängend".
- **Demo-/Seed-Daten laden**, sonst verifizierst du leere Zustände und siehst die reichen nie.
- **PostgREST nach direktem Postgres-DDL**: neue Tabellen sind erst nach
  `NOTIFY pgrst, 'reload schema'` über die REST-API sichtbar (Symptom: 404 auf existierende Tabelle).

## Report-Vorlage

Jede Zeile trägt entweder ihren Beleg (eine Zahl; bei `Kontext:` die gelesene Quelle, bei `Ausgelöst:`
den konkreten Einstiegspunkt), ihren ausdrücklichen `n/a`-Zweig mit Grund oder — nur `CI:` und
`Visuell:` — ihren Aufschub mit Wer/Wann. Die Vorlage ist absichtlich **nicht durchgezählt**: eine
Zählung in der Prosa wäre beim nächsten Zusatz still falsch, und das Paritätsgate sieht in den Fence
nicht hinein (`shape()` überspringt Fenced-Blöcke). Lies die Marken, nicht die Positionen:

```md
## Verify — <kurzer Name des geänderten Flows>
- Kontext: <gelesene Quelle für die Kommandos, z. B. package.json:scripts.dev> · Umgebung: <gemessene Achse + wo gepinnt> | n/a (Pfad liest keine)
- Gegenstand: <sha> · nach `git fetch` <n>/<m> Commits hinter Upstream/origin-<default> · <installierte Versionen> · Mutation <datei>: <erwarteter Blob> gesehen | n/a (keine Mutation)
- Start: <Kommando> unter <echter Laufzeit> → <URL/Port>, ready nach <n>s, <BELEGZAHL aus dem echten Start>
- Ausgelöst: <konkreter Einstiegspunkt> in der <Aufrufform der Produktion>
- Ränder: <n Regeln registriert · m Anfragen, davon k am echten Dienst> | n/a (der geänderte Pfad hat keinen Netzrand)
- Beobachtet: <BELEGZAHL — Status/Zeilen/Anzahl/Testzahl>
- Beide Richtungen: Ablehnung <BELEGZAHL> · Positivfall gegen die echte Konfiguration, gleiche Kommandoform <BELEGZAHL> | Positivfall n/a (nichts fail-closed berührt)
- Round-Trip: <Golden Test: n passed, `success` UND Wert zugesichert, RED gegen alte Impl bestätigt> | n/a (kein Contract berührt)
- CI: <`git ls-remote` nennt <sha>> · <Lauf für <sha>: <conclusion>, gelesen mit <Kommando>> | kein Lauf, weil <welcher der vier Leerfälle> → <wer> liest es <wann>
- Visuell: verifiziert (Screenshot <pfad>, geladenes Bundle <Marker>=<Wert>) | DEFERRED → <wer> fährt es <wann>
```

**Nicht verifiziert** ist jeder Report, dessen Start-Zeile die Laufzeit nicht nennt, dessen einzige
Belegzahl eine Ablehnung ist, dessen `CI:`-Zeile das Ankommen des Pushes nicht belegt, dessen
Mutationslauf keine Klammer trägt, dessen `Visuell:`-Zeile auf einer Seite mit registriertem Service
Worker (`navigator.serviceWorker.getRegistrations()`) keine Bundle-Identität nennt, oder dessen `CI:`-
bzw. `Visuell:`-Zeile aufschiebt, ohne **wer** und **wann** zu nennen.
