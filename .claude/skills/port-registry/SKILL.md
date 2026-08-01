---
name: port-registry
description: 'Lokale Dev-Server-Ports: welche Ports im agent-core-Ökosystem schon belegt sind (Registry mit Fundstelle) und welcher Port für einen neuen Dev-Server zu nehmen ist (deterministischer Vergabeplan pro Projekt + Worktree). Nutze, wenn ein Dev-Server nicht startet, ein Port belegt ist, EADDRINUSE / "port already in use" auftritt, `strictPort` hart scheitert, geklärt werden muss "welcher Port ist frei" oder "wer hält Port 3000", oder wenn in einem Worktree ein Dev-/Preview-/Storybook-Server hochgezogen wird.'
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
- Ein neuer belegter Port ist entstanden und soll eingetragen werden.

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

| Port | Belegt von | Fundstelle |
|---|---|---|
| 3000 | global-login `apps/login` — **ohne** `strictPort` | `global-login/apps/login/vite.config.ts:19` |
| 3001 | global-login `apps/admin` | `global-login/apps/admin/vite.config.ts:33` |
| 3000 | Claude-Template `apps/web` | `Claude-Template/apps/web/vite.config.ts:17` |
| 3000 / 3001 / 3002 | faninitiative-platform `apps/web` / `apps/dashboard` / `apps/scanner` | `faninitiative-platform/apps/{web,dashboard,scanner}/vite.config.ts:21`, `:65`, `:79` |
| 3000 | smart-home-app `apps/web` | `smart-home-app/apps/web/vite.config.ts:84` |
| 6345 | doppelklick `apps/shell`, `strictPort: true` | `doppelklick/apps/shell/vite.config.ts:10` |

**Fünf Projekte wollen 3000, drei wollen 3001, zwei wollen 3002.** Das ist der Grund für diesen Skill.

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
2. **Bewusst entscheiden**: den fremden Server stoppen, oder akzeptieren, dass diese Session den
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

Index 10–18 (40000–48999) sind frei für neue Projekte. **Bestehende Indizes werden nie umnummeriert** —
eine Umnummerierung verschiebt still jeden Port jedes Worktrees dieses Projekts.

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
   Ausnahme in alle anderen Worktrees.

## Ist-Stand prüfen

**Primär: PowerShell** (die primäre Shell dieses Repos), strukturiert und sprachunabhängig.

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

Slot berechnen:

```powershell
([int[]][char[]]'fdesign' | Measure-Object -Sum).Sum % 90     # -> 16  =>  30160
```

Plattformneutral (Git-Bash), **zwingend einzeilig** — mehrzeiliges `node -e` läuft unter Git-Bash als
leeres Programm und endet mit Exit 0, siehe `shared/memory/00-knowledge.md`:

```bash
node -e "const s=process.argv[1];console.log([...s].reduce((a,c)=>a+c.charCodeAt(0),0)%90)" fdesign
```

### Gotcha: `netstat | grep LISTENING` ist fail-open

Die Status-Spalte von `netstat` ist **lokalisiert**. Auf einem deutschen Windows steht dort `ABHÖREN`,
nicht `LISTENING` — verifiziert: `netstat -ano -p tcp | grep -c "LISTENING"` liefert **0 Treffer und
Exit 0**, während 36 Ports lauschen. Das liest sich exakt wie „Port frei" und ist der Lehrbuchfall aus
`shared/rules/30-quality.md`: der Befehl lief, gab nichts aus, und der fehlende Treffer wurde zur
Freigabe. Der Umlaut wird in der Git-Bash-Pipe zusätzlich durch die OEM-Codepage zerlegt (`ABH?REN`),
ein Grep auf `ABHÖREN` ist also auch nicht verlässlich.

**Also:** `Get-NetTCPConnection` benutzen. Wenn es `netstat` sein muss, auf der **Adress**-Spalte
filtern und den Status selbst lesen — nie auf dem Statuswort:

```bash
netstat -ano -p tcp | grep ":3000 "
```

## Einen neuen Eintrag hinzufügen

Damit die Registry nicht driftet:

1. **Belegten Port eintragen** — Zeile in die passende Tabelle, mit `datei:zeile` als Fundstelle
   (vorher gegreppt, nicht aus dem Kopf) und der Einordnung **hart gekoppelt** vs. **Skill-Default**.
   Bei „hart gekoppelt" **dazuschreiben, woran** er hängt (Allowlist, CSP, …) — ohne das ist die
   Einordnung nicht überprüfbar und der nächste Leser verschiebt ihn.
2. **Reservieren**, falls hart gekoppelt oder aufwärts scannend (dann als **Bereich**, nicht als
   einzelner Port — siehe impeccable).
3. **Neues Projekt** → nächster freier `PROJECT_INDEX` unten anhängen. Bestehende **nie** umnummerieren.
4. **Drift-Check** — findet neu entstandene Ports im Repo:

```bash
rg -n "localhost:[0-9]{2,5}|--port[= ][0-9]{2,5}|http\.server [0-9]{2,5}|port:\s*[0-9]{2,5}"
```

   Über die Nachbarprojekte dasselbe auf `vite.config.ts`. Was der Check findet und hier fehlt, ist
   ein fehlender Eintrag — kein Fund ohne `datei:zeile` gilt.
