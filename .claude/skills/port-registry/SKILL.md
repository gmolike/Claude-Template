---
name: port-registry
description: 'Lokale Dev-Server-Ports: welche Ports im agent-core-Ökosystem schon belegt sind (Registry mit Fundstelle) und welcher Port für einen neuen Dev-Server zu nehmen ist (deterministischer Vergabeplan pro Projekt + Worktree). Nutze, wenn ein Dev-Server nicht startet, ein Port belegt ist, EADDRINUSE / "port already in use" auftritt, `strictPort` hart scheitert, geklärt werden muss "welcher Port ist frei" oder "wer hält Port 3000", wenn ein Dev-Server auf einem anderen Port landet als angefordert oder ein `--port`-Flag wirkungslos bleibt, wenn ein fremder Prozess einen Port hält, oder wenn in einem Worktree ein Dev-/Preview-/Storybook-Server hochgezogen wird.'
allowed-tools: Read, Bash, Glob, Grep
---

# Port Registry & Vergabeplan

Zwei Dinge: eine **Registry** der belegten Ports (mit Fundstelle, damit sie prüfbar bleibt) und ein
**deterministischer Vergabeplan** für neue Dev-Server. Der Plan braucht **kein** Buch pro Worktree —
derselbe Worktree bekommt reproduzierbar denselben Port, auf jeder Maschine, ohne Zustand.

> **Prosa deutsch, Code/Identifier/Portnamen englisch** (Repo-Konvention). Alle Zeilennummern unten
> **driften** — vor dem Zitieren nachgreppen, nicht dieser Datei glauben.

## Wann invoken

- Ein Dev-/Preview-/Storybook-Server soll hochgezogen werden — **besonders in einem Worktree**.
- `EADDRINUSE`, „port already in use", oder `strictPort: true` scheitert hart.
- Die Frage „welcher Port ist frei" / „wer hält Port 3000" steht an.
- Ein Dev-Server landet auf einem **anderen Port als angefordert**, ein `--port`-Flag bleibt
  wirkungslos, oder ein fremder Prozess soll beendet werden.
- Ein neuer belegter Port oder ein neues Projekt ist entstanden und braucht einen Eintrag — der wird
  **angefordert**, nicht selbst geschrieben (letzter Abschnitt).

## Die Registry — belegte Ports in diesem Repo

Zwei Sorten: **hart gekoppelt** heißt, Verschieben bricht etwas **Externes** (eine Allowlist, eine CSP)
und ist ohne Nachziehen dieser externen Config kaputt. **Skill-Default** heißt frei verschiebbar — es
kostet nur einen Flag.

| Port | Belegt von | Fundstelle | Art |
|---|---|---|---|
| **3000** | `apps/web` Vite-Dev-Server, `strictPort: true` | `apps/web/vite.config.ts:23` | **hart gekoppelt** — GoTrue-Redirect-Allowlist |
| 3000 | Login-Basis-URL (Kommentar) bzw. Redirect-Allowlist-Eintrag | `apps/web/src/shared/config/env.ts:18`, `docs/admin-content-editing.md:112` | **hart gekoppelt** (dieselbe Kopplung, andere Stelle) |
| 54321 | Supabase lokal (REST/API) | `apps/web/src/shared/api/supabaseClient.ts:61` | Standard (Supabase-CLI-Vorgabe) |
| **3002** | `hyperframes preview` — **echter Default** | `shared/skills/hyperframes-cli/SKILL.md:75` | Skill-Default |
| 3017 | `hyperframes preview` — Doku-**Beispiel**, wird von Agents wörtlich kopiert | `shared/skills/hyperframes-cli/SKILL.md:88`, `shared/skills/website-to-hyperframes/references/step-7-validate.md:84`, `i18n/skills/hyperframes-cli/de.md:86` | Skill-Default (Beispiel) |
| 4567 | `hyperframes preview --port` — Doku-**Beispiel** „custom port" | `shared/skills/hyperframes-cli/SKILL.md:75` | Skill-Default (Beispiel) |
| **8400+** | impeccable live-server — **scannt bei Belegung aufwärts** (8401, 8402, …) | `shared/skills/impeccable/scripts/live-server.mjs:47` (`findOpenPort(start = 8400)`), `:54` (Retry `start + 1`) | **hart gekoppelt** — das Zielprojekt muss `http://localhost:8400` in seiner CSP allowlisten (`shared/skills/impeccable/reference/live.md:557`, `:563`, `:584`, `:606`, `:628`) |
| 8723 | hyperframes design-picker (`python3 -m http.server`) | `shared/skills/hyperframes/references/design-picker.md:114` | Skill-Default |
| 8765 | css-animation (`python3 -m http.server`) | `shared/skills/css-animation/SKILL.md:476`, `:480`, `i18n/skills/css-animation/de.md:474` | Skill-Default |

### Nachbar-Repos auf derselben Maschine — der eigentliche Kollisionsherd

Die Registry endet nicht am Repo-Rand: alle Projekte unter `C:\Entwicklung` teilen dieselbe
Loopback-Adresse. Verifiziert per `grep -rn "strictPort\|port:"` über die `vite.config.ts` der
Nachbarprojekte:

**Auch diese Tabelle ist Auslieferung, kein Formular.** Ein neu entstandener Port wird **gemeldet**,
nicht hier eingetragen — der Weg steht unter „Einen neuen Eintrag anfordern".

| Port | Belegt von | Fundstelle |
|---|---|---|
| 3000 | global-login `apps/login` — **ohne** `strictPort` | `global-login/apps/login/vite.config.ts:19` |
| 3001 | global-login `apps/admin` | `global-login/apps/admin/vite.config.ts:33` |
| 3000 | Claude-Template `apps/web` | `Claude-Template/apps/web/vite.config.ts:17` |
| 3000 / 3001 / 3002 | faninitiative-platform `apps/web` / `apps/dashboard` / `apps/scanner` | `faninitiative-platform/apps/{web,dashboard,scanner}/vite.config.ts:21`, `:65`, `:79` |
| 3000 | smart-home-app `apps/web` | `smart-home-app/apps/web/vite.config.ts:84` |
| 6345 | doppelklick `apps/shell`, `strictPort: true` | `doppelklick/apps/shell/vite.config.ts:10` |
| 40900 / 40903 | canu-camp-hennig `apps/web` — Dev bzw. Preview, beide `strictPort: true` | `canu-camp-hennig/apps/web/vite.config.ts:140`, `:141` |
| 40901 | canu-camp-hennig `apps/api` (`next dev` / `next start --port`) | `canu-camp-hennig/apps/api/package.json:11`, `:13` |
| 40905 | canu-camp-hennig `apps/mobile` (`expo start --port`, vier Skripte) | `canu-camp-hennig/apps/mobile/package.json:8`–`:11` |

**Fünf Projekte wollen 3000, drei wollen 3001, zwei wollen 3002.** Das ist der Grund für diesen Skill.

`canu-camp-hennig` ist die Ausnahme und zugleich der Beleg: es ist das einzige Nachbarprojekt, das
seine Ports **aus dem Vergabeplan unten** bezieht — `40900 = 30000 + 10·1000 + 90·10 + 0`, also Web im
Hauptbaum (Slot 90) — und folgerichtig das einzige, das mit niemandem kollidiert. `+5` ist im Plan
frei und wird dort faktisch für `apps/mobile` (Expo) belegt; wer als nächstes eine Mobile-App
aufsetzt, nimmt sinnvollerweise denselben Offset, statt einen neuen zu erfinden.

## Der harte Fall: Port 3000 ist nicht verschiebbar

`apps/web/vite.config.ts:23` steht auf `strictPort: true`, und der Kommentar darüber nennt den Grund:
die GoTrue-Redirect-Allowlist im **global-login-Projekt** erlaubt genau
`http://localhost:3000/auth/callback`. Der Port hängt damit an einer **externen Auth-Config in einem
anderen Repo** — ihn zu verschieben bricht den Login, bis die Allowlist nachgezogen ist, und das ist
kein lokaler Commit.

`strictPort: true` ist dabei **korrekt** und kein Ärgernis: es ist fail-loud (`shared/rules/30-quality.md`).
Der zweite Dev-Server scheitert **hart**, statt still auf 3001 auszuweichen und dort einen Login zu
liefern, dessen Redirect die Allowlist nicht kennt — ein Fehler, der sonst erst im Auth-Round-Trip
auffällt.

**Wenn 3000 gebraucht wird und schon läuft: nicht ausweichen.** Sondern:

1. **Feststellen, wer ihn hält** (Befehl unten). Der Prozess verrät über seine Kommandozeile den
   Worktree.
2. **Bewusst entscheiden**: den fremden Server stoppen (**gezielt per PID**, siehe „Ist-Stand
   prüfen"), oder akzeptieren, dass diese Session den
   Auth-Round-Trip nicht fahren kann (für reine UI-Arbeit: `VITE_DEV_BYPASS_AUTH=true`, siehe
   `docs/admin-content-editing.md:115`).
3. **Niemals** `vite.config.ts` auf einen anderen Port umschreiben. Das repariert eine Session und
   bricht die Allowlist für alle anderen — und die Allowlist liegt nicht in diesem Repo.

> **Verifizierter Sonderfall.** global-logins eigene `apps/login` will auch 3000, hat aber **kein**
> `strictPort` (`global-login/apps/login/vite.config.ts:19`) — sie weicht also **still** auf 3001 aus,
> wo sie mit global-logins eigenem `apps/admin` (`:33`) kollidiert. agent-cores Web-App und der lokale
> Login können deshalb **nicht gleichzeitig** laufen. Dieser Fall wird **sequenziert**, nicht vergeben.

## Der Vergabeplan

Ein Port entsteht aus drei Summanden — nichts davon wird gepflegt, alles ist berechenbar:

```
port = 30000 + PROJECT_INDEX * 1000 + WORKTREE_SLOT * 10 + SERVICE_OFFSET
```

| Summand | Wert | Woher |
|---|---|---|
| Band-Basis | `30000` | fest; siehe Bandwahl unten |
| `PROJECT_INDEX` | `0…18` (1000 Ports je Projekt) | die Projekt-Tabelle unten — **nie umnummerieren** |
| `WORKTREE_SLOT` | `0…89` (10 Ports je Worktree) | `slugSum(<worktree-slug>) mod 90`, deterministisch |
| `SERVICE_OFFSET` | `0…9` | `+0` web · `+1` api · `+2` storybook · `+3` preview · `+4` e2e · `+5…+9` frei |

`slugSum` = Summe der Zeichencodes des Worktree-Slugs. Reproduzierbar in jeder Sprache, ohne Zustand:
derselbe Slug ergibt für immer denselben Port.

**Warum `PROJECT_INDEX` als einziger Summand vergeben und nicht gerechnet wird.** Die Frage kommt
wieder, weil jeder andere Summand berechenbar ist — die Antwort ist gemessen, nicht Geschmack: elf
reale Projektnamen über zwölf Fächer kollidieren mit **99,94 %** (Geburtstagsproblem, kein
Hash-Qualitätsproblem); dieselbe `slugSum`-Prozedur ließe an der geteilten Tabelle zwischen zwei
Projekten nur 1° Farbtonabstand, FNV-1a kollidiert glatt bei 0°. Die Messung steht im Kopfkommentar von
`PROJECT_SLOTS` (`src/colorRegistry.ts`) — derselbe Index ist dort der Slot der **Fensterfarbe**.
Ein gerechneter Index verschöbe still jeden bestehenden Port **und** jede Fensterfarbe.

**Slots 90–99** (also `+900…+999` je Projekt) vergibt der Plan **nie** automatisch. Sie sind zwei
Dinge: der Platz des **Hauptbaums** (kein Worktree → Slot 90) und die **Ausweich-Reserve** bei einer
Hash-Kollision (siehe unten).

### Projekt-Tabelle

| Index | Projekt | Basis | Index | Projekt | Basis |
|---|---|---|---|---|---|
| 0 | claude-skills | 30000 | 5 | global-login | 35000 |
| 1 | dnd | 31000 | 6 | smart-home-app | 36000 |
| 2 | Claude-Template | 32000 | 7 | San | 37000 |
| 3 | doppelklick | 33000 | 8 | claude-code-session-source | 38000 |
| 4 | faninitiative-platform | 34000 | 9 | Projects | 39000 |
| 10 | canu-camp-hennig | 40000 | | | |

Index 11–18 (41000–48999) sind **noch nicht vergeben**. „Frei" heißt hier *zu vergeben*, nicht *zu
nehmen*: die Zeile schreibt agent-core, angefordert wird sie über „Einen neuen Eintrag anfordern"
unten — mit dem Befehl, der dort ausgeschrieben steht. **Bestehende Indizes werden nie umnummeriert** —
eine Umnummerierung verschiebt still jeden Port jedes Worktrees dieses Projekts.

> **Index 10 ist Bestand, kein Vorrat — und war es schon, bevor er hier stand.** `canu-camp-hennig`
> fährt seine vier Dev-Server längst nach diesem Plan (40900 · 40901 · 40903 · 40905, Fundstellen in
> der Nachbar-Tabelle oben), tauchte in dieser Tabelle aber nie auf; sie endete bei 9. Aufgefallen ist
> die Lücke erst von der anderen Seite: `color-registry` führt den Projekt-Slot **als** diesen
> `PROJECT_INDEX` und trug `"canu-camp-hennig": 10` ein (`PROJECT_SLOTS` in `src/colorRegistry.ts`,
> am 2026-08-05 Zeile 124 — die Zeilenzahl `113` stand hier bis dahin falsch, sie war schon
> **innerhalb** ihres eigenen Commits verrutscht) — die zugesagte
> eine Tabelle war damit zwei. Ohne diesen Nachtrag hätte das nächste regulär aufgenommene Projekt
> Index 10 bekommen und wäre in Ports **und** Fensterfarbe kollidiert.
>
> Verifiziert am 2026-08-03: `canu-camp-hennig` ist ein echtes Git-Repo unter `C:/Entwicklung`
> (`git rev-parse --is-inside-work-tree` → `true`, Remote `github.com/gmolike/canu-camp-hennig.git`,
> vier Commits) mit einem Worktree — `canu-camp-hennig-worktrees/ultraplan-w0-w1`, Slot 54, also
> 40540 ff. Eine ältere Erhebung, die es als bloßes Verzeichnis ohne Repo führte, ist damit überholt.
>
> **Asymmetrie, die hier stehen muss:** dieser Plan reicht bis Index 18, die geteilte Farb-Tabelle nur
> bis Slot 11 (zwölf Farbtöne, gemessene Kapazität). Ein Projekt ab Index 12 bekommt also einen Port,
> aber keinen Farbton mehr — das ist dann eine Entscheidung, kein Eintrag
> (`shared/skills/color-registry/SKILL.md`).

### Beispiel — die realen claude-skills-Worktrees

| Worktree | Slot | web (`+0`) | api (`+1`) |
|---|---|---|---|
| `recipe` | 2 | 30020 | 30021 |
| `fdesign` | 16 | 30160 | 30161 |
| `umlaut` | 34 | 30340 | 30341 |
| `rdoctor` | 45 | 30450 | 30451 |
| `governance` | 74 | 30740 | 30741 |
| `feedback` | 85 | 30850 | 30851 |
| *Hauptbaum* | 90 | 30900 | 30901 |

Gegengeprüft über die 6 claude-skills- **und** die 14 dnd-Worktrees dieser Maschine: **20 Slugs, 20
verschiedene Slots, 0 Kollisionen.** (`recipe` und `sp-quickwins` landen beide auf Slot 2 — verschiedene
Projekte, verschiedene Basis, kein Konflikt. Genau dafür ist der Projekt-Summand da.)

### Reservierte Bereiche — vergibt der Plan nie

| Bereich | Grund |
|---|---|
| 1–1023 | privilegiert / well-known (Windows-Systemdienste) |
| 3000–3002 | die hart gekoppelte, fünffach umkämpfte Zone oben |
| 3017, 4567 | Skill-Doku-Beispiele, die Agents wörtlich kopieren |
| 5173 | Vites **eigener** Default — jede App ohne `server.port` landet hier |
| 5432, 54320–54329 | Postgres bzw. der lokale Supabase-Stack (belegt ist 54321; die Band-Reservierung ist bewusst konservativ, weil die CLI je Version mehrere Nachbarports belegt) |
| 6345 | doppelklick `apps/shell`, `strictPort` |
| 8000, 8080 | die häufigsten Fremd-Defaults überhaupt |
| 8400–8409 | impeccable live-server, **scannt aufwärts** und ist CSP-gekoppelt |
| 8723, 8765 | design-picker, css-animation |
| **49152–65535** | Windows-Ephemeral-Range — verifiziert: `netsh int ipv4 show dynamicport tcp` → Startport 49152, 16384 Ports |

**Warum 30000–48999.** Oberhalb jedes verbreiteten Framework-Defaults und **unterhalb** des
Ephemeral-Floors 49152, damit nichts aus dem Plan mit einem dynamisch zugeteilten Client-Socket
kollidiert. **Ehrlich:** das Band ist damit frei von *Defaults*, nicht garantiert leer. Auf dieser
Maschine lauschten zur Autorenzeit 42050 und 45191 (app-zugeteilt). Deshalb ist die Ist-Stand-Prüfung
unten **Pflicht** und nicht optional.

### Hash-Kollision im selben Projekt

Zwei Slugs desselben Projekts können auf denselben Slot fallen (bei 14 Worktrees über 90 Slots
rechnerisch ~10 %). Das ist **kein** Grund für stilles Ausweichen:

1. Der zweite Server scheitert **laut** (mit `strictPort: true`, das auch für Plan-Ports gilt).
2. Halter feststellen (Befehl unten).
3. Der **später** angelegte Worktree nimmt einen Slot aus der Reserve **90–99** und schreibt ihn in
   sein eigenes `.env.local` bzw. `--port`-Flag — **nie** in eine getrackte Config, sonst wandert die
   Ausnahme in alle anderen Worktrees. Wie dieses Flag den Server überhaupt erreicht, steht direkt
   darunter — das Übergeben ist die eigentliche Falle.

## Dev-Server auf einem festen Port starten

Der berechnete Port nützt nichts, wenn das Flag den Server nie erreicht. **Die beiden Paketmanager
verlangen entgegengesetzte Aufrufe, und die falsche Form scheitert nicht — sie startet den Server
leise woanders.** Gemessen am 2026-09-17 mit einem Wegwerf-Paket, dessen `dev`-Script
`process.argv.slice(2)` druckt (pnpm 10.32.1 · npm 11.13.0):

| Aufruf | pnpm übergibt | npm übergibt |
|---|---|---|
| `<pm> run dev -- --port 5177 --strictPort` | `["--","--port","5177","--strictPort"]` — **kaputt** | `["--port","5177","--strictPort"]` — richtig |
| `<pm> run dev --port 5177 --strictPort` | `["--port","5177","--strictPort"]` — richtig | `["5177"]` — **kaputt** |

pnpm reicht das literale `--` an das Script durch; vites CLI (cac) schneidet dort das Options-Parsing
ab — `const doubleDashesIndex = argv.indexOf("--"); … argv = argv.slice(0, doubleDashesIndex)`
(`vite/dist/node/cli.js:599-602`, gelesen in vite 6.4.3) — und verwirft den Rest samt `--strictPort`.
npm frisst umgekehrt genau die Flags, die nach dem Script-Namen **ohne** `--` stehen.

**Welche Hälfte laut ist und welche still, ist gemessen — und es ist nicht die, die man vermutet:**
npm warnt dreimal (`"5177" is being parsed as a normal command line argument.` · `Unknown cli config
"--port"` · dasselbe für `"--strictPort"`), pnpm sagt zu seiner kaputten Form **nichts**. Und zu
einem Flag, dessen Name ein **echter npm-Config-Schlüssel** ist, sagt npm gar nichts: bei
`npm run dev sync --scope project --dir .` warnt es nur über `--dir` und übergibt dem Script
`["sync","."]` — `--scope project` ist spurlos weg. Die Regel dahinter: npm nimmt **jedes** Flag vor
dem `--` für sich — laut nur bei denen, die es nicht kennt, spurlos bei denen, die es kennt.

**Das Rezept, das unter beiden gilt — weder den Paketmanager fragen noch `npx`, sondern die lokale
vite-Datei direkt starten:**

```bash
cd <verzeichnis-mit-dem-dev-script> && node node_modules/vite/bin/vite.js --port <plan-port> --strictPort
```

- **Aus dem Verzeichnis mit dem `dev`-Script fahren, nie aus der Workspace-Wurzel.** pnpm hoistet
  `vite` nicht: in diesem Repo fehlt es in `node_modules/.bin` (dort stehen `tsc`, `tsserver`, `tsx`,
  `vitest`) und liegt in `apps/web/node_modules/.bin`. Aus dem falschen Verzeichnis scheitert der
  direkte Aufruf laut und nennt den Pfad, an dem er gesucht hat: `Error: Cannot find module
  '…\node_modules\vite\bin\vite.js'`, Exit 1 — gemessen in der Wurzel dieses Repos und in einem
  leeren Verzeichnis; in `apps/web` startet derselbe Befehl vite 6.4.3 auf dem angeforderten Port.
- **Nicht `npx vite`.** Liegt `vite` nicht im Baum des Verzeichnisses, holt npx eine **fremde**
  Version und startet sie auf genau dem angeforderten Port. Gemessen am 2026-09-22 (npm 11.13.0) in
  einem Verzeichnis ohne vite: `npx vite --version` lud `vite@8.3.0` — eine einzige
  `npm warn exec`-Zeile, Exit 0 —, und danach starteten auch `npx --no -- vite` und
  `npx --no-install vite` diese zwischengespeicherte 8.3.0 ohne jede Meldung: `--no` verhindert nur
  den Download, nicht den Griff in den Cache. Das ready-Banner zeigt dann den richtigen Port, aber
  die falsche Version im falschen Verzeichnis. Nur wo vite transitiv im Baum liegt — in der Wurzel
  dieses Repos über `vitest` —, scheitert `npx vite` stattdessen mit einer lokalisierten
  cmd.exe-Meldung, die das Arbeitsverzeichnis mit keinem Wort erwähnt.
- **Den Plan-Port einsetzen, nicht ein Beispiel abschreiben.** `apps/web` dieses Repos ist der harte
  Fall oben (3000, GoTrue-Allowlist): dort ist ein abweichendes `--port` genau die Handlung, die
  dieser Skill verbietet.
- **`--strictPort` ist die Probe, nicht die Bequemlichkeit.** Es scheitert hart — gemessen gegen
  einen belegten Port: `rc=1`, `error when starting dev server: Error: Port 30997 is already in use`
  — statt still auszuweichen. Ohne das Flag ist „Server läuft" keine Aussage über den Port.
- **Der direkte Aufruf überspringt `pre<script>`-Hooks — wie `npx` und `pnpm exec`.**
  `pnpm run dev` fährt `predev` mit, `pnpm exec` nicht (gemessen); auf dieser Maschine tragen 17
  `package.json` unter `C:/Entwicklung` eines (ohne `node_modules` gezählt), und manche erzeugen
  dabei eine **getrackte** Datei — `dnd/lore-admin` etwa schreibt
  `src/pages/development-todos/data.json`, das `git ls-files` führt. Also entweder vorher einmal
  `pnpm run predev`, oder bewusst ohne — nicht aus Versehen.
- **Den tatsächlichen Port aus der ready-Zeile lesen und unten gegenprüfen, nie aus dem Kommando
  schließen.** Der Ausfall ist restlos stumm: `vite -- --port 30998 --strictPort` gegen eine Config
  mit `port: 30999` lieferte ein völlig normales `VITE v6.4.3 ready` / `Local:
  http://localhost:30999/` — keine „in use"-Zeile, keine Warnung, nichts. Das Merkmal ist nicht eine
  Meldung, sondern: **im ready-Banner steht ein anderer Port als der angeforderte.**

Die Paketmanager-Hälfte gilt werkzeugunabhängig — pnpm reicht nach dem Script-Namen sogar eigene
Flags durch (`pnpm run dev --filter foo` → `["--filter","foo"]`). Die `--`-Hälfte ist cac/vite; für
`next dev --port` und `expo start --port` aus der Nachbar-Tabelle oben ist nur die
Paketmanager-Hälfte gemessen, der Rest wäre unbelegt.

## Ist-Stand prüfen

**Primär: PowerShell** (die primäre Shell dieses Repos), strukturiert und sprachunabhängig.

**Dieser Abschnitt ist Windows-Messtechnik** — PowerShell bzw. Git-Bash, und die `netstat`-Spalten
unten sind die von Windows. Dieser Skill geht über den OpenCode-Bundle auch auf Unix-Maschinen
(`src/targets/opencode.ts` kopiert jedes Skill mit): dort gilt der Vergabeplan oben unverändert,
die Befehle hier gelten dort **nicht** — das Gegenstück heißt `ss` bzw. `lsof`, und dieser Skill
hat es nicht gemessen.

Alles im Vergabeband plus Nachbarschaft:

```powershell
Get-NetTCPConnection -State Listen |
  Where-Object { $_.LocalPort -ge 3000 -and $_.LocalPort -lt 49152 } |
  Select-Object -ExpandProperty LocalPort | Sort-Object -Unique
```

Ein Port und **wer ihn hält** (das ist der Befehl für den harten Fall oben):

```powershell
Get-NetTCPConnection -LocalPort 3000 -State Listen | ForEach-Object {
  $p = Get-CimInstance Win32_Process -Filter "ProcessId=$($_.OwningProcess)"
  '{0}  PID {1}  {2}' -f $_.LocalPort, $p.ProcessId, $p.CommandLine
}
```

Die Kommandozeile zeigt bei einem Vite-/Node-Server den Pfad und damit den Worktree. Bei einem
Systemdienst, der einem nicht gehört, ist `CommandLine` leer — dann hilft `Get-Process -Id <pid>`.

**Ist der Port frei, ist die Antwort ein roter Fehler, kein leeres Ergebnis — aber nur ein
bestimmter.** `Get-NetTCPConnection -LocalPort 49999 -State Listen` meldet dann die Kategorie
`ObjectNotFound` (nicht-terminierend; der Meldungstext ist lokalisiert, hier „…wurden keine
übereinstimmenden MSFT_NetTCPConnection-Objekte gefunden") — gemessen. Das ist **die Freimeldung**,
kein defekter Befehl und kein Grund, auf `netstat` auszuweichen. Jede **andere** Kategorie ist eine
gescheiterte Messung, und die Zahl sieht dann genauso aus: gegen eine absichtlich unerreichbare
CIM-Sitzung (`-CimSession`, Stellvertreter einer gescheiterten Abfrage) kam für den belegten Port
135 `ResourceUnavailable` — und `.Count` → `0`, gemessen am 2026-09-22. Wer eine Zahl statt einer
Meldung will, braucht deshalb dieselbe Reichweite wie der `netstat`-Rückfall unten: erst
`@(Get-NetTCPConnection -State Listen).Count` (hier 47; `0` heißt nichts gemessen, NICHT frei),
dann `@(Get-NetTCPConnection -LocalPort 49999 -State Listen -ErrorAction SilentlyContinue).Count`
→ `0`.

**Und dann: genau diese eine PID beenden — nie einen Image-Namen.** Ein Kill, der auf den
Image-Namen `node.exe` zielt statt auf eine PID, trifft **jeden** node-Prozess der Maschine: fremde
Dev-Server, fremde Test-Runner, den Sprachserver der IDE, die eigene Sitzung. Auf einer geteilten
Entwicklungsmaschine ist das kein Aufräumen — es ist ein Ausfall in fremden Sitzungen, der dort als
stiller Abbruch ankommt, oft erst Minuten später bemerkt.

```powershell
Get-NetTCPConnection -LocalPort 3002 -State Listen |
  Select-Object -ExpandProperty OwningProcess | Sort-Object -Unique |
  ForEach-Object { Stop-Process -Id $_ }
```

`Sort-Object -Unique` macht aus den Listen-Zeilen die Liste der **Halter**: ein Dual-Stack-Lauscher
hat **zwei** Listen-Zeilen mit derselben PID, `.OwningProcess` ist dann ein Array (am 2026-09-17 auf
dieser Maschine 8 solche Ports, z. B. `135` → `1416,1416`). Ohne `-Unique` bekäme derselbe Prozess
zwei Kill-Aufrufe — gemessen folgenlos (0 Fehler in drei Läufen, PowerShell 5.1), die eindeutige
Liste ist aber die, die man zuerst lesen will. Und vor dem Beenden gehört die Kommandozeile
des Halters gelesen (Befehl darüber): ein fremder Worktree ist eine **Entscheidung**, kein Aufräumen.

`netstat` ist für diesen Schritt der falsche Weg — nicht unbequem, sondern falsch: es nennt den
Halter nicht zuverlässig (siehe den Gotcha unten). Eine **Teilstring-Suche** auf `:3002`, wie sie
naheliegt, lieferte an einer netstat-Probe **drei Zeilen mit drei verschiedenen PIDs**: den Halter,
ein fremdes `0.0.0.0:30020` und eine ausgehende Verbindung, die `3002` nur als **Remote**-Port
führt. Wer daraus „den" PID zieht, beendet einen fremden Prozess.

Slot berechnen:

```powershell
([int[]][char[]]'fdesign' | Measure-Object -Sum).Sum % 90     # -> 16  =>  30160
```

Plattformneutral (Git-Bash), **zwingend einzeilig** — mehrzeiliges `node -e` läuft unter Git-Bash als
leeres Programm und endet mit Exit 0, siehe `shared/memory/00-knowledge.md`:

```bash
node -e "const s=process.argv[1];console.log([...s].reduce((a,c)=>a+c.charCodeAt(0),0)%90)" fdesign
```

### Gotcha: `netstat | grep` ist dreifach fail-open

Drei **unabhängige** Wege, auf denen `netstat | grep` einen belegten Port als frei meldet. Alle drei
am 2026-09-17 auf dieser Maschine gemessen (deutsches Windows, Codepage 850, GNU grep 3.0 unter
`LANG=en_US.UTF-8`): die **Erscheinungsform** hängt an genau dieser Umgebung, der Ausfall nicht —
wer ein anderes grep oder eine andere Codepage hat, misst sie nach, statt sie für ungefährlich zu
halten.

- **Das Statuswort ist lokalisiert.** Hier steht `ABHÖREN`, nicht `LISTENING`:
  `netstat -ano -p tcp | grep -c "LISTENING"` liefert `0` bei **Exit 1**, während zeitgleich 31
  IPv4-Ports lauschten. `grep -a` hilft dagegen **nicht** (ebenfalls `0`) — das Wort steht schlicht
  nicht da. Greppbar ist nur der ASCII-Präfix `ABH`; `ABHÖREN` (UTF-8) und `ABH?REN` treffen beide
  nichts, weil in der Pipe das Rohbyte `0x99` ankommt und das `?` nur die Terminal-Darstellung ist.
- **`grep` hält den Strom für binär.** Genau dieses `0x99` ist in einer UTF-8-Locale ungültig: ohne
  `-a` ersetzt grep **alle** Trefferzeilen durch die eine Zeile `Binary file (standard input)
  matches` — auf stdout, mit **Exit 0**. Ein `| wc -l` liest das als „1 Treffer", ein Agent als Fund
  ohne PID. Gemessen an `grep ":135 "`; mit `-a` kommt die echte Zeile mit PID, ebenso mit `LC_ALL=C`
  **vor dem grep** (vor dem `netstat` wirkt es nicht — die Variable erreicht dann das falsche
  Programm). Zählen ist davon nicht betroffen (`grep -c` und `grep -ac` liefern beide 31), `-a`
  gehört also an jedes grep, das Zeilen **ausgeben** soll.
- **`-p tcp` ist IPv4-only.** Node und damit Vite lösen `localhost` unter Windows auf `::1` auf; der
  Dev-Server steht dann unter `[::1]:5173` und `-p tcp` zeigt ihn **überhaupt nicht**. Gegen einen
  eigens gestarteten `[::1]:5173` gemessen: `netstat -ano -p tcp | grep -a ":5173 "` → Exit 1 und
  keine Ausgabe, `Get-NetTCPConnection -LocalPort 5173 -State Listen` → `::1  5173  <pid>`. Die
  beiden Familien sind disjunkt und ergeben zusammen erst das Ganze (hier 31 + 13 = 44).

**Also: `Get-NetTCPConnection`** — es sieht beide Adressfamilien, kennt kein Statuswort und steht als
Befehl oben. Muss es `netstat` sein, dann **zwei Zeilen, in dieser Reihenfolge**:

```bash
netstat -ano | awk '$2 ~ /:/ {n++} END {print n+0}'   # Reichweite. 0 => nichts gemessen, NICHT "frei"
netstat -ano | awk '$2 ~ /:3000$/'                    # beide Familien, LOKALE Adressspalte
```

Kein `-p`, weil `-p tcp` IPv6 ausblendet. `awk` auf **Spalte 2** statt `grep` auf einem Teilstring,
weil eine Teilstring-Suche die **Remote**-Spalte mittrifft: gemessen liefert
`netstat -ano | grep -a -E ":443[[:space:]]"` 40 Zeilen, angeführt von einer **ausgehenden**
Verbindung mit fremder PID, während laut `Get-NetTCPConnection` **kein** Prozess auf 443 lauscht —
der Befehl nennt dann einen Halter, den es nicht gibt. Das Leerzeichen verankert das Ende der
**Zahl**, nicht die **Spalte**; ohne Leerzeichen kommt `:30020` für `:3002` dazu.

Und: `awk` endet **immer** mit Exit 0 — auch für den garantiert freien Port 49999, gemessen. Der
Exit-Code ist hier keine Antwort. Entschieden wird an der **Ausgabe** plus der Reichweitenzahl, und
das Statuswort liest man selbst.

## Einen neuen Eintrag anfordern — schreiben kann hier nur agent-core

**Diese Datei ist eine Auslieferung, kein Formular.** Die Quelle liegt in agent-core unter
`shared/skills/port-registry/SKILL.md`; was ein Konsument liest, ist die vendorte Kopie in
`~/.claude/skills/port-registry/SKILL.md`, und die wird bei **jedem** Sitzungsstart überschrieben:
`src/targets/claude.ts` kopiert das Skill-Verzeichnis **bedingungslos** (`copyDir(join(SHARED,
"skills", name), …)` — keine Bedingung, kein Hash-Vergleich; der Hash-Schutz greift nur beim
**Prune**, also gegen das Löschen), und der SessionStart-Hook
`targets/claude/hooks/agent-core-sync.sh` löst den Sync dafür bei jedem Chat-Start aus. Ein Eintrag,
den ein Konsument hier schreibt, überlebt die Sitzungsgrenze nicht. Auf OpenCode liegt die Kopie im
`skills/`-Verzeichnis des von Hand entpackten Bundles; die überschreibt kein Sitzungsstart, sondern
erst das nächste entpackte Release (`targets/opencode/plugins/version-check.ts`: „delivered manually
… cannot refresh itself") — der Eintrag hält dort länger und geht trotzdem verloren. Und
`shared/rules/50-agent-core.md` verbietet den Fork ohnehin („never fork rule text into a project").

**Welcher der beiden Fälle gilt, entscheidet ein Befehl:** `git remote -v` im Repo, in dem gearbeitet
wird. Steht dort `gmolike/agent-core`, wird eingetragen (zweiter Block). Steht dort etwas anderes,
wird angefordert (erster Block). Einen dritten Weg gibt es nicht — insbesondere keinen
Selbstbedienungsbereich: der `PROJECT_INDEX` ist zugleich der Slot der Fensterfarbe
(`shared/skills/color-registry/SKILL.md`), ein selbst genommener Index nähme still eine Farbe mit.

### Anfordern — der Normalfall, aus einem Konsumenten-Repo

1. **Antrag stellen**, wörtlich:

```bash
gh issue create --repo gmolike/agent-core --label skill-improvement \
  --title "port-registry: PROJECT_INDEX <verzeichnisname>" \
  --body "Projekt: <verzeichnisname unter C:/Entwicklung>, Remote: <url>
Provisorisch belegt: <ports> -- Fundstellen <datei:zeile>, gegreppt
Ist-Stand vor der Belegung: <Ausgabe der Ist-Stand-Prüfung, unter Windows Get-NetTCPConnection>"
```

   Der **Verzeichnisname** ist der Schlüssel — case-sensitive, unübersetzt, nicht geglättet; derselbe
   Schlüssel vergibt die Fensterfarbe. Ohne Fundstellen und ohne geprüften Ist-Stand ist der Antrag
   nicht überprüfbar; dann wird nachgefordert, nicht vergeben. Der Befehl steht hier ausgeschrieben,
   damit dieser Skill für sich steht — der allgemeine Rückkanal in `shared/rules/22-session-close.md`
   ist derselbe Weg, aber er kommt erst am Ende einer Sitzung vorbei.
2. **Bis zur Vergabe weiterarbeiten — provisorisch belegen, nicht blockieren.** Nimm das Band des
   nächsten in der Tabelle oben **nicht vergebenen** Index und schreibe die Ports in **dein eigenes**
   Repo. Das ist eine Reservierung, keine Vergabe: kollidieren zwei Anträge, entscheidet agent-core
   nach Eingangsreihenfolge der Issues, und der spätere zieht um. Der Fall ist real eingetreten —
   `canu-camp-hennig` fuhr vier Server tagelang auf Index 10, bevor die Zeile existierte.
3. **Das Issue ist die Notiz.** Die provisorische Nummer gehört in den Issue-Text, nicht in eine
   Notizdatei nebenher: der Hauptsitzung ist das Schreiben ohnehin verwehrt
   (`shared/rules/25-orchestration.md`), und was das eigene Repo braucht, steht dort in seiner Config
   (`vite.config.ts`, `package.json`) — genau der `datei:zeile`, die der Antrag zitiert.
4. **Alles andere in dieser Datei läuft denselben Weg**: ein neu entstandener belegter Port, ein zu
   reservierender Bereich, eine Zeile in der Nachbar-Tabelle. Es sind Zeilen in einer Datei, an die
   der Adressat nicht herankommt — also derselbe Antrag, mit derselben Belegpflicht.

### Eintragen — nur in agent-core selbst

1. **Belegten Port eintragen** — Zeile in die passende Tabelle, mit `datei:zeile` als Fundstelle
   (vorher gegreppt, nicht aus dem Kopf) und der Einordnung **hart gekoppelt** vs. **Skill-Default**.
   Bei „hart gekoppelt" **dazuschreiben, woran** er hängt (Allowlist, CSP, …) — ohne das ist die
   Einordnung nicht überprüfbar und der nächste Leser verschiebt ihn.
2. **Reservieren**, falls hart gekoppelt oder aufwärts scannend (dann als **Bereich**, nicht als
   einzelner Port — siehe impeccable).
3. **Neues Projekt** → nächsten nicht vergebenen `PROJECT_INDEX` oben anhängen — und **dieselbe Zahl**
   in `shared/skills/color-registry/SKILL.md` und in `PROJECT_SLOTS` in `src/colorRegistry.ts`.
   Bestehende **nie** umnummerieren. Der Golden Test `src/projectSlots.golden.test.ts` vergleicht alle
   Kopien gegen `PROJECT_SLOTS`, nennt die Zahl der verglichenen Projektzeilen und wird rot, sobald
   eine Tabelle zurückbleibt.
4. **Drift-Check** — findet neu entstandene Ports im Repo:

```bash
rg -n "localhost:[0-9]{2,5}|--port[= ][0-9]{2,5}|http\.server [0-9]{2,5}|port:\s*[0-9]{2,5}"
```

   Über die Nachbarprojekte dasselbe auf `vite.config.ts`. Was der Check findet und hier fehlt, ist
   ein fehlender Eintrag — kein Fund ohne `datei:zeile` gilt.
