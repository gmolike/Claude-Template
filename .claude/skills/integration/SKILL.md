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
  `tsx src/cli.ts <cmd>`)? Prüfe mit `agent-core --version`.

### Schritt 2: Scope bestimmen

- `global` → schreibt nach `~/.claude/`, gilt für alle Projekte des Users.
- `project` → `CLAUDE.md` + `.mcp.json` im **Projekt-Root**; `skills/`, `agents/`, `hooks/`, `settings.json` unter **`.claude/`**.
- Lies den Scope aus `$ARGUMENTS`; im Zweifel `project` annehmen und die Annahme nennen.

### Schritt 3: Claude-Code-Target erzeugen (`sync`)

Nicht-destruktiv und idempotent. Genau einen Befehl wählen:

- installiert, global: `agent-core sync --scope global`
- installiert, projekt: `agent-core sync --scope project --dir .`
- lokaler Checkout, global: `pnpm sync` — Achtung: `pnpm sync` läuft IMMER global
- lokaler Checkout, projekt: `pnpm dev sync --scope project --dir .`

`sync` schreibt: `CLAUDE.md` (+ `.claude/skills|agents|hooks`, gemergte `settings.json`, im project-Scope zusätzlich `.mcp.json`).

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
- Standard ist nicht-destruktiv & idempotent. Vor `--overwrite` oder jeder destruktiven bzw. scope-ändernden Aktion erst fragen.
- Eine handgeschriebene `CLAUDE.md` (ohne `<!-- GENERATED`-Kopf) wird nie überschrieben.
- `pnpm sync` ist immer global; für ein Projekt `--scope project --dir <pfad>` nutzen.
- OpenCode hat keinen `sync`: das Target wird als consume-only `.tgz`-Bundle bezogen (Release-Download oder selbst
  via `agent-core bundle`) und nach `~/.config/opencode/` entpackt — kein Materialisieren wie bei Claude Code.
- Keine Secrets in Code oder Config — nur Env-Var-Namen.
- Windows: Pfade in JSON erst parsen, dann Token ersetzen und auf Forward-Slashes normalisieren.
- Conventional Commits; niemals `main` ohne Freigabe pushen.
