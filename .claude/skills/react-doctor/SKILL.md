---
name: react-doctor
description: 'React-spezifisches Advisory-Gate (oxlint-basiert) auf dem geänderten Scope: null neue error-Findings via `react-doctor`, belegt über `--json`-Parsing statt Exit-Code. Nutze beim Abschließen einer web-react-Änderung. Advisory, bis die modifizierte-MIT-AI-Training-Klausel rechtlich geklärt ist; `--no-score`/`--no-supply-chain` sind Pflicht, sonst verlässt der Projekt-Fingerprint die Maschine.'
paths:
  - 'apps/web/**'
  - '**/*.tsx'
allowed-tools: Bash, Read
---

# React Doctor

_Applies when: finishing any React / web-react change — the React-specific advisory layer on `31-quality-web.md`._

React-spezifisches Gate auf **oxlint**-Basis (`react-doctor`, npm-Paket von millionco/Aiden Bai). Es läuft **advisory** — es meldet, **blockiert aber noch nicht** —, bis die modifizierte-MIT-Lizenz mit ihrer ungeklärten AI-Training-Klausel rechtlich geklärt ist. Der Beleg kommt aus dem `--json`-Report, **nie** aus dem Exit-Code und **nie** aus dem remote berechneten Score.

> **Prosa deutsch, Code/Identifiers/Flags englisch** (Repo-Konvention).

## Kommando

`react-doctor` an die **exakte** Version `0.9.1` pinnen und als **devDependency** installieren — **nicht** `npx react-doctor@latest` (reproduzierbar, kein stiller Versions-Drift, kein Score-/Client-Bump hinter dem Rücken):

```bash
react-doctor . \
  --scope changed --base <target-branch> \
  --blocking error \
  --no-score --no-supply-chain \
  --json --json-out .react-doctor.json
```

- `--scope changed --base <target-branch>` prüft nur den geänderten Scope gegen den Ziel-Branch (z. B. `origin/main`), nicht das ganze Repo.
- `--blocking error` wertet nur `error`-Severity als Blocker; `warn`/`info` bleiben advisory.
- `--no-score --no-supply-chain` sind **Pflicht** — siehe Datenschutz unten.
- `--json --json-out .react-doctor.json` schreibt den maschinenlesbaren Report, aus dem der Beleg gezogen wird.

## Belegzahl (Pflicht — nie der Exit-Code)

Aus `.react-doctor.json` muss **alles** von diesem gelten, sonst ist das Gate **ROT (fail closed)**:

- `ok !== false`
- `complete !== false`
- `filesScanned > 0`
- `newErrors === 0`

Report-Format: `react-doctor: <N> Dateien gescannt, <M> neue error-Findings`.

Fehlt der Report **oder** ist `ok:false` **oder** `complete:false` **oder** `filesScanned == 0` ⇒ **ROT**, nicht grün. Ein fehlender/unvollständiger Report ist ein Gate mit gebrochener Vorbedingung (`30-quality.md`, fail-loud) — er wird laut, nie stillschweigend übersprungen.

Beleg-Check als sichere Einzeiler-Variante (mehrzeiliges `node -e` läuft unter Git-Bash leer und exit 0 — daher eine Zeile, single-quoted, keine Backticks/Template-Literals):

```bash
node -e 'const r=require("./.react-doctor.json"); const bad=r.ok===false||r.complete===false||!(r.filesScanned>0)||r.newErrors>0; console.log("react-doctor: "+r.filesScanned+" Dateien gescannt, "+r.newErrors+" neue error-Findings"); process.exit(bad?1:0)'
```

**Nie nur auf den Exit-Code branchen.** Belegte Fail-open-Pfade, die exit 0 liefern, ohne dass wirklich sauber gescannt wurde:

- `--blocking none` short-circuitet und exitet 0.
- `--max-duration`-Truncation bricht den Scan ab und exitet 0.
- Issue #1242: exit 0 **ohne** JSON-Ausgabe.

Jeder dieser Pfade produziert ein grünes Signal ohne Deckung — nur die vier `.json`-Bedingungen oben fangen sie.

## Warum nicht auf den Score gaten

Der Score ist **als Gate untauglich** und wird deshalb mit `--no-score` abgeschaltet:

- Er wird **remote** berechnet (`POST react.doctor/api/score`), nicht lokal.
- Er ist **size-normalisiert** und hat **keinen** lokalen Fallback.
- Er ist **ohne Client-Bump** serverseitig änderbar ⇒ derselbe Code kann morgen einen anderen Score liefern.

Ein remote berechneter, nicht reproduzierbarer, still verschiebbarer Wert ist kein Gate. Gegated wird ausschließlich auf die lokal reproduzierbaren `newErrors`/`filesScanned` aus dem JSON.

## FSD-Hinweis

Die Regel `no-barrel-import` prüft nur **relative** Pfade (`startsWith('.')`) und kollidiert daher **nicht** mit FSD-Alias-Imports (`@features/*`, `@entities/*`, …) — die laufen sauber durch. Falls eine Kategorie doch stört, abschaltbar über `react-doctor.config.json` (`rules` > `categories` > `tags`), z. B. `ignore.tags: [design, test-noise]`. Nur gezielt abschalten, nie das ganze Gate.

## RED-Verify (sonst ist das Gate nicht verdrahtet)

Einen bekannten `error`-Fund einbauen (z. B. eine Regel, die `react-doctor` als `error` meldet), das Gate laufen lassen ⇒ es **MUSS rot** werden (`newErrors > 0`), dann den Fund wieder entfernen ⇒ grün. Ein Gate, das nie **verifiziert rot** war, beweist nichts (`30-quality.md`).

## Datenschutz

`--no-score` **und** `--no-supply-chain` sind **Pflicht**. Beide sind per Default **an** und schicken bei jedem Lauf Daten nach außen (Score-Endpoint bzw. Socket.dev-Supply-Chain-Check, plus Sentry) — d. h. der **Projekt-Fingerprint verlässt die Maschine**. Ohne beide Flags leakt jeder Gate-Lauf Projektdaten; mit ihnen bleibt der Scan lokal.

## Rollout

- **Stufe 1 — advisory (jetzt).** `--blocking none` fahren, eine Baseline der Findings aufnehmen und False-Positives via `react-doctor.config.json` tunen. Nur melden, nicht blockieren.
- **Stufe 2 — blockierend (NACH Rechtsklärung).** Erst wenn die modifizierte-MIT-AI-Training-Klausel legal geklärt ist, im Claude-Template als **Pre-Commit** (geänderter Scope) + **PR-CI** verdrahten und auf `--blocking error` schalten.
