---
name: integration
description: 'agent-core in ein Projekt integrieren: Kontext und Scope erkennen, das richtige Target erzeugen (sync für Claude Code, bundle für OpenCode), MCP-Env-Vars prüfen und das Ergebnis verifizieren. Nutze, wenn der User agent-core in ein Projekt einbinden oder synchronisieren will.'
argument-hint: '[scope: global|project] [pfad]'
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
disable-model-invocation: true
---

# agent-core Integration

Du integrierst agent-core in ein Projekt. agent-core ist die **einzige Quelle der Wahrheit** für
KI-Agent-Konfiguration (Rules, Skills, Agents, MCP). Aus dieser Quelle werden zwei Targets erzeugt:
**Claude Code** über `sync` und **OpenCode** über `bundle`. Beide erzeugen unterschiedliche Artefakte —
trenne sie sauber, sonst formulierst du Prüfungen, die im jeweils anderen Target nie zutreffen.

`$ARGUMENTS` enthält optional den Scope (`global` | `project`) und optional einen Pfad. Fehlt der Scope, frage nach.

## Prozess

### Schritt 1: Kontext & Verfügbarkeit erkennen

- Bestehendes Repo (`package.json` / `.git` vorhanden) oder frisches Projekt? Frisches Projekt → vom
  **Claude-Template-Monorepo** bootstrappen (separates Repo: klonen/initialisieren, NICHT aus diesem Repo ableiten).
- agent-core als installiertes Bin (`agent-core <cmd>`) oder lokaler Checkout (`pnpm dev <cmd>` /
  `npx tsx src/cli.ts <cmd>`, beides **im Checkout** ausführen)? Prüfe mit `agent-core --version`.

### Schritt 2: Scope bestimmen

- `global` → schreibt nach `~/.claude/`, gilt für alle Projekte des Users.
- `project` → `CLAUDE.md` + `.mcp.json` im **Projekt-Root**; `skills/`, `agents/`, `hooks/`, `settings.json` unter **`.claude/`**.
- Lies den Scope aus `$ARGUMENTS`; im Zweifel `project` annehmen und die Annahme nennen.

### Schritt 3: Claude-Code-Target erzeugen (`sync`)

Idempotent; nicht-destruktiv nur für die gemergten Senken — was in den Datei-Eimern gilt, steht unter „Regeln". Genau einen Befehl wählen:

- installiert, global: `agent-core sync --scope global`
- installiert, projekt: `agent-core sync --scope project --dir .` (im Projekt ausführen)
- lokaler Checkout, global: `pnpm sync` — ohne Flags ist der Scope global
- lokaler Checkout, projekt: im Checkout `pnpm dev sync --scope project --dir <projektpfad>`. `--dir` gilt relativ zum **Checkout**, nicht zum Aufrufort: pnpm fährt jedes Script in der Paketwurzel, `--dir .` synct also in agent-core selbst. **Nur mit pnpm** — `npm run dev sync --scope project …` verschluckt `--scope project` still (`scope` ist ein npm-Config-Schlüssel; übrig bleibt `sync <pfad>`, und die überzählige Angabe ignoriert die CLI) und fährt einen **globalen** Sync. Unter npm nur mit `--` vor `sync`; paketmanagerfrei: `npx tsx src/cli.ts sync --scope project --dir <projektpfad>`.

`sync` schreibt: `CLAUDE.md` (+ `.claude/skills|agents|hooks`, gemergte `settings.json`, im project-Scope zusätzlich `.mcp.json`).

Ist der Arbeitsbaum nicht sauber, gilt vor einem `sync --scope project`:

- **WIP-Commit statt Stash.** `sync` erzeugt genau die Dateien neu, die ein Stash mitnimmt. Gemessen
  am 2026-08-05 in einem Wegwerf-Repo: Stash → Generat neu geschrieben → `git stash apply` endet mit
  Exit 1 und `UU CLAUDE.md` (1 unmerged path); derselbe Ablauf mit WIP-Commit statt Stash ergibt
  `unmerged-count=0` bei erhaltener Arbeit. Generierte Dateien von Hand zu mergen ist der falsche
  Weg — der richtige ist, den Sync erneut zu erzeugen.
- **Nie den Branch wechseln, um zu syncen.** Der Default-Branch ist bei Cloudflare Pages / Vercel /
  Netlify ein Auto-Deploy-Target; ein Checkout dorthin plus ein späterer Commit ist ein Schritt in
  Richtung ungewollter Veröffentlichung. `sync` selbst wechselt nichts — das ist die Auflage an den,
  der es aufruft.

### Schritt 4: OpenCode installieren — Bundle beziehen, KEIN sync

OpenCode wird **nicht gesynct**. Das OpenCode-Target ist ein **consume-only `.tgz`-Bundle**, das man bezieht und
entpackt — es gibt dafür keinen `sync`-Befehl. `bundle` ist der **Build**-Schritt (erzeugt die `.tgz` aus dem
Quellcode), nicht der Nutzungs-Schritt.

1. **Bundle beziehen** — eines von beiden:
   - **Herunterladen** (Normalfall für Nutzer): das veröffentlichte `agent-core-opencode-*.tgz` vom Release-Asset
     des Repos bzw. der Download-Seite. Keine npm-Quelle, kein Build nötig.
   - **Selbst bauen** (nur mit agent-core-Quellcode): `agent-core bundle` (oder `pnpm bundle`) → `build/agent-core-opencode-*.tgz`.
2. **Entpacken** ins OpenCode-Config-Verzeichnis — der entpackte Inhalt **ist** die aktive Config, kein Repo
   nötig (global empfohlen `~/.config/opencode/`, nativ Windows `%USERPROFILE%\.config\opencode\`, alternativ
   projektweit `.opencode/`):

   ```bash
   # macOS / Linux / WSL
   mkdir -p ~/.config/opencode
   tar -xzf <pfad>/agent-core-opencode-*.tgz -C ~/.config/opencode --strip-components=1
   # Windows (PowerShell): tar -xzf agent-core-opencode-*.tgz -C "$env:USERPROFILE\.config\opencode" --strip-components=1
   ```

3. **Env-Vars** aus der im Bundle mitgelieferten `SETUP.md` setzen (aktuell `GITHUB_TOKEN`).

Das Bundle enthält `AGENTS.md`, `opencode.json`, `skills/`, `agents/`, `plugins/`, `SETUP.md`, `VERSION`. Es ist
consume-only: lokale Edits überschreibt das nächste Bundle — geändert wird upstream in agent-core, dann neu veröffentlicht.
`AGENTS.md` und `SETUP.md` gibt es nur im Bundle, nie durch `sync`.

### Schritt 5: MCP verdrahten

- Benötigte Env-Var-**Namen** ermitteln und melden — Primärquelle `shared/mcp/servers.json` (das `env`-Array je Server,
  nur Namen). Aktuell trägt real nur `github` eine Variable (`GITHUB_TOKEN`); `SETUP.md` (nur im Bundle) ist die lesbare Referenz.
- NIE Secret-Werte hardcoden — ausschließlich Variablennamen referenzieren.

### Schritt 6: Verifizieren (Definition of Done — target-getrennt)

**Claude-`sync`:** `CLAUDE.md` beginnt mit dem `<!-- GENERATED`-Kopf (project: Root, global: `~/.claude/`); der Skill
liegt im Ziel-`skills/`; `.claude/agents` ist befüllt; `settings.json` wurde gemergt OHNE Verlust von
`statusLine` / `enabledPlugins` / `env` / `theme`; im project-Scope ist `.mcp.json` im Root.

**OpenCode (Bundle):** Nach dem Entpacken enthält `~/.config/opencode/` `AGENTS.md`, `opencode.json`, `skills/`,
`agents/`, `plugins/`; `cat ~/.config/opencode/VERSION` zeigt die erwartete Version; OpenCode startet ohne Schema-Fehler
(Agents + MCP-Server erscheinen). Beim Selbst-Bauen zusätzlich: `validate` (bzw. `pnpm validate`) grün — prüft jedoch
NUR `opencode.json`, nicht einzelne `SKILL.md`.

### Schritt 7: Output

Deutsche Zusammenfassung: gewähltes Target + geschriebene Pfade + welche Env-Var(s) noch fehlen (insbesondere `GITHUB_TOKEN`).

## Regeln

- agent-core ist **kanonisch**: Rules/Skills/Agents upstream hier fixen und dann syncen — NIE Regeltext ins Projekt forken.
- Nicht-destruktiv & idempotent gilt für die **gemergten** Senken: `CLAUDE.md` / `AGENTS.md` (nur eine Datei mit `<!-- GENERATED`-Kopf wird ersetzt), `settings.json` (Deep-Merge, `env` und `permissions` additiv, Session-Defaults seed-only) und `.mcp.json` (eigene Server hinein, fremde bleiben, solange die Datei lesbar ist). Vor `--overwrite` oder jeder destruktiven bzw. scope-ändernden Aktion erst fragen.
- **Für die Datei-Eimer gilt sie je Eimer verschieden.** Unter `.claude/skills/<name>/` wird eine **fremde** Fassung nicht überschrieben: eine gleichnamige, projekteigene `SKILL.md` bleibt stehen, der Sync meldet `skills/foreign-name-collision`, und agent-cores Fassung dieses Skills kommt dort nicht an; ein Skill-Verzeichnis, das ein Link (Symlink/Junction) ist, wird nie durchgeschrieben (`skills/linked-target`). Beide behalten: die eigene Fassung **umbenennen — Verzeichnis UND `name:`-Feld** (z. B. `<projekt-präfix>-<name>`); agent-cores Fassung wollen: `--replace-foreign-skills` — **nicht** `--overwrite`, das ersetzt nur `CLAUDE.md`, `AGENTS.md` und `settings.json`. `.claude/agents/<name>.md` und `.claude/hooks/*` werden dagegen weiter **bedingungslos** geschrieben: Hooks sind agent-cores eigene Sicherheitsfläche. Und eine eigene Datei **neben** einer unveränderten agent-core-`SKILL.md` schützt nichts — ein verengender Sync löscht das ganze Verzeichnis mitsamt ihr. Die Meldungen gehen nicht mehr verloren: ein Sync druckt sie auf stderr und legt sie zusätzlich als Datei ab — global `~/.claude/.agent-core-warnings.json`, im Projekt `agent-core-warnings.json` im Git-Verzeichnis, wenn `--dir` eine Repo-Wurzel ist, sonst `.claude/.agent-core-warnings.json`; der SessionStart-Hook spielt die globale Datei in die Sitzung ein, `worktree-bootstrap` die seines Worktree-Syncs. Die übrige Sync-Ausgabe geht weiter nach `/dev/null`.
- **Ein einzelnes ausgeliefertes Artefakt lösen:** `agent-core sync --exclude agent:<slug>` (analog `skill:` / `rule:` / `mcp:` / `memory:`; kommasepariert und wiederholbar, `sync --help` führt es). Die Abwahl wird ins Manifest geschrieben und bei jedem weiteren blanken `sync` klebrig nachgespielt; eine **unveränderte** Kopie entfernt schon dieser Lauf, eine **hand-geänderte** bleibt als `preserved: user-modified` stehen. Für ein core/ungetaggtes Artefakt zusätzlich `--allow-core-exclude`. Die Abwahl wirkt **pro Scope**: ein Projekt-Manifest berührt die globale Kopie unter `~/.claude/` nicht — der SessionStart-Hook syncht global weiter.
- Eine handgeschriebene `CLAUDE.md` (ohne `<!-- GENERATED`-Kopf) wird ohne `--overwrite` nie überschrieben.
- `pnpm sync` ohne Flags ist global (Default-Scope); für ein Projekt `--scope project --dir <pfad>` anhängen — mit pnpm, nicht mit npm (siehe Schritt 3).
- OpenCode hat keinen `sync`: das Target wird als consume-only `.tgz`-Bundle bezogen (Release-Download oder selbst
  via `agent-core bundle`) und nach `~/.config/opencode/` entpackt — kein Materialisieren wie bei Claude Code.
- Keine Secrets in Code oder Config — nur Env-Var-Namen.
- Windows: Pfade in JSON erst parsen, dann Token ersetzen und auf Forward-Slashes normalisieren.
- Conventional Commits; niemals `main` ohne Freigabe pushen.

### Worktree — welcher Skill-Satz gilt

Ein Worktree löst **Projekt-Skills ausschließlich aus seinem eigenen `.claude/skills` auf**: der Harness läuft von `cwd` aufwärts und bricht an der Worktree-Wurzel ab. Anders als `agents/`, `commands/` und `output-styles/` haben Skills **keinen Rückfall** auf die Hauptarbeitskopie — es ist eine Ersetzung, keine Ergänzung. Beide Lagen sind gleich betroffen: `.claude/worktrees/<agent-id>/` (Agent-Werkzeug) und die Geschwisterlage `<repo>-worktrees/<slug>` aus ADR-0030.

- **`CLAUDE.md` liegt im Worktree (getrackt) ⇒ der eingefrorene Satz gewinnt.** `worktree-bootstrap` steigt bei der bloßen **Anwesenheit** von `CLAUDE.md` aus, und Anwesenheit ist nicht Frische; er sagt zum Sitzungsbeginn nur an, welcher Zustand gilt — getrackte Skill-Dateien, eingefroren auf den Commit dieses Worktrees, oder gar kein `.claude/skills` —, und repariert nichts. Gemessener Fall: 23 Skills im Stand vom 2026-04-13 gegen 82 in der Hauptarbeitskopie desselben Repos — darunter einer unter seinem Namen von **vor** einer Umbenennung.
- **`CLAUDE.md` fehlt ⇒ der Bootstrap-Zweig synct agent-core hinein.** Eine getrackte, projekteigene `SKILL.md` gleichen Namens bleibt dabei stehen und wird gemeldet (Datei-Eimer-Punkt oben); ohne diesen Schutz wurde sie ersetzt, und der Worktree war danach dirty (gemessen gegen v2.0.0). Ein älteres, installiertes `agent-core` ohne den Schutz ersetzt sie weiterhin.
- **Nachsehen statt raten:** `claude --debug --debug-file d.log -p "ok"`, dann `grep "Loading skills from" d.log` — die Zeile nennt den Pfad, den die Sitzung wirklich benutzt, und `Loaded … project: N` die Zahl. Zweiter Einfrier-Vektor ohne jedes Liegenbleiben: `worktree.baseRef` steht per Default auf `fresh`, ein frisch angelegter Agent-Worktree zweigt also von `origin/<default-branch>` ab, nicht vom lokalen HEAD.
