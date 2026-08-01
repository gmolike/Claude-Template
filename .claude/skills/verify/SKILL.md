---
name: verify
description: 'Den GEÄNDERTEN Flow real fahren und das Ergebnis mit einer Belegzahl protokollieren — nicht nur Tests grün melden. Liest zuerst den Projekt-Kontext (package.json-Scripts, README, Projektstandards), startet App/Service, löst genau den geänderten Pfad aus und trennt hart: visuelle Verifikation ist mit Vermerk verschiebbar, der Daten-Round-Trip nie. Nutze vor jedem Commit an Produktcode.'
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
- Welcher **Einstiegspunkt** löst genau sie aus (Button, URL, CLI-Kommando, API-Call, Cron)?
- Welche **beobachtbare Wirkung** beweist, dass sie lief (Response-Body, DB-Zeile, Log, Datei,
  UI-Zustand)? Diese Wirkung ist später deine Belegzahl.
- Berührt der Diff einen Contract (Schema, Wire-Format, Persistenz)? → Round-Trip ist **Pflicht**.
  Zum Erkennen den **Review check** aus `25-orchestration` bzw. Setup-Schritt 1 des Skills
  `contract-golden-test` fahren (grep die Typ-/Schema-Definition über alle Pakete), nicht dem
  Gedächtnis vertrauen.

### 3. App/Service starten

Mit den in Schritt 1 **gelesenen** Kommandos. Backgroundfähig starten, Port/URL notieren, auf
Bereitschaft warten (Health-Endpoint/Log-Zeile), Startfehler nicht wegignorieren.

### 4. Den Pfad auslösen und beobachten

- Bevorzugt **automatisiert und headless**: HTTP-Call, CLI-Aufruf, Skript, DB-Query. Das ist der
  billige Teil und läuft überall.
- **Fehlerpfad mitnehmen**, nicht nur den Happy Path — der Vorfall oben war ein *lautloser* Skip,
  kein Crash. Prüfe deshalb aktiv, ob etwas **still übersprungen** wurde (Anzahl vorher/nachher!).
- UI-Anteil: im Browser öffnen und **hinsehen** (`31-quality-web`) — oder sauber verschieben (s. o.).

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
driftet genauso wie eine zweite Kopie eines Contracts.

## Gotchas (belegtes Repo-Wissen)

- **`file://` ist im Browser-Tool blockiert** (fetch/Module). Offline-Single-File-Builds über
  `python -m http.server` ausliefern, Vite `base: './'`.
- **TanStack Query in Automations-/Headless-Browsern**: `navigator` meldet offline, Queries bleiben
  ewig in `fetchStatus: 'paused'` → `networkMode: 'always'` setzen, sonst verifizierst du einen
  Ladespinner.
- **Vor dem Re-Test neu bauen.** Sonst prüfst du das alte Bundle und bestätigst dir den Fix, den du
  nie geladen hast. Dev-Server liest `.env` beim Start — nach Änderung neu starten; `preview`/`prod`
  **backen** `VITE_*` zur Build-Zeit ein.
- **rAF friert in versteckten Tabs** — Animationen/Polling im Hintergrundtab wirken „hängend".
- **Demo-/Seed-Daten laden**, sonst verifizierst du leere Zustände und siehst die reichen nie.
- **PostgREST nach direktem Postgres-DDL**: neue Tabellen sind erst nach
  `NOTIFY pgrst, 'reload schema'` über die REST-API sichtbar (Symptom: 404 auf existierende Tabelle).

## Report-Vorlage

```md
## Verify — <kurzer Name des geänderten Flows>
- Kontext: <gelesene Quelle für die Kommandos, z. B. package.json:scripts.dev>
- Start: <Kommando> → <URL/Port>, ready nach <n>s
- Ausgelöst: <konkreter Einstiegspunkt>
- Beobachtet: <BELEGZAHL — Status/Zeilen/Anzahl/Testzahl>
- Fehlerpfad: <was passiert bei ungültiger Eingabe — BELEGZAHL>
- Round-Trip: <Golden Test: n passed, RED gegen alte Impl bestätigt> | n/a (kein Contract berührt)
- Visuell: verifiziert (Screenshot <pfad>) | DEFERRED → <wer> fährt es <wann>
```

Die Zeile `Visuell: DEFERRED` **ohne** Wer/Wann ist ungültig — dann ist der Flow nicht verifiziert.
