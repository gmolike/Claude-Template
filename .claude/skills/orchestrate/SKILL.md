---
name: orchestrate
description: 'Substanzielle UI-/Feature-Aufgabe über den bewährten Liefer-Zyklus abwickeln: Plan-First + Approval-Gates → parallele Workflow-Wellen (delegieren statt selbst implementieren) → adversariale Verifikation → voller Grün-Gate → PFLICHT visuelle Browser-Prüfung → Commit/PR nach Freigabe. Nutze für mehrstufige Features, Redesigns, Migrationen, Audits.'
argument-hint: '[aufgaben-beschreibung]'
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Task, Workflow, AskUserQuestion
disable-model-invocation: true
---

# Orchestrierter Liefer-Zyklus

Du lieferst eine **substanzielle, mehrstufige Aufgabe** (`$ARGUMENTS`) über den in EPIC-DKL-500/510
bewährten Zyklus. Verbindlich ist die Rule `[[working-method]]` — dieser Skill ist ihr **ausführbares
Rezept**. Die Haupt-Instanz arbeitet als **Orchestrator** (`[[orchestrator-mode]]`): sie delegiert Lesen
UND Implementieren an Subagenten/`Workflow` und behält nur die Schlussfolgerungen.

## 0. Plan-First + Approval-Gates

- Erst kartieren, dann planen. **Kritische Nachfragen mit `AskUserQuestion` — eine Entscheidung pro Runde**
  (`[[user-workflow]]`). Freigabe vor schwer umkehrbaren Schritten.
- Mehrdeutiges Scope NIE stillschweigend annehmen. Default-Vorschläge nennen, die echte Architektur-Gabel fragen.
- Liefere in **kleinen Wellen / kleinen PRs**, nicht einem Riesen-Diff (so kam EPIC-DKL-510 sauber voran:
  PR #7 Fundament+DAM, #8 Umfrage+Sportfest, #9 Scrum-Closure).

## 1. Discovery-Welle (Recon)

Eine `Workflow`-Welle aus **parallelen `Explore`-Recon-Agenten**, die je ein Subsystem kartieren und ein
**strukturiertes Spec** (via `schema`) zurückgeben — keine Datei-Dumps in den Hauptkontext. Danach ein
**Synthese-Agent**, der den priorisierten Plan + offene Fragen liefert. Die Haupt-Instanz behält nur das Spec.

## 2. Bau-Welle (delegieren, disjunkt parallelisieren)

Bewährtes Wellen-Muster:

```
Recon → Schema/Fundament (Single Source of Truth zuerst) →
parallele Feature-Agenten in DISJUNKTEN Verzeichnissen →
Kompositions-/Integrations-Agent (besitzt geteilte Dateien/Barrels) →
voller Grün-Gate → adversariale Verifikation
```

Regeln, die Kollisionen vermeiden (hart erkämpft):

- **Disjunkte Datei-Ownership.** Jeder Bau-Agent ändert NUR sein Verzeichnis/Slice. **Genau ein**
  Kompositions-Agent besitzt geteilte Dateien (z. B. `stage-overview.tsx`) und alle Barrels/`index.ts`.
- **Vertrag zuerst.** Das Schema/Fundament (z. B. `@doppelklick/shared-types`, `@doppelklick/ui`) landet
  VOR den Feature-Agenten; deren `publicApi`-Rückgabe wird in die nachgelagerten Prompts interpoliert,
  damit sie gegen stabile Verträge bauen.
- **Additiv & rückwärtskompatibel.** Geteilte Bausteine als **Opt-in-Props** heben (Default = bisheriges
  Verhalten); bestehende Consumer + PDF-/Druck-Pfade dürfen nicht brechen.
- **Leitplanken in JEDEN Agenten-Prompt:** App-Shell-Pflicht, kein `:root`-Override, Akzent nur via Prop,
  `prefers-reduced-motion`, nur `transform`/`opacity`, offline/`file://`-fest, **echte Umlaute**
  (`[[umlaute-anzeige]]`), TS strict (kein `any`/`@ts-ignore`), Tests anpassen statt löschen.

## 3. Adversariale Verifikation

Ein eigener **Verify-/Design-Kritiker-Agent** prüft VOR Übernahme: Korrektheit/Lücken, App-Shell-Konformität,
Hierarchie/Spacing, **Augenweide (`[[visual-quality-first]]`)**, reduced-motion, echte Umlaute. Findings →
nachbessern. **Aber:** dem Verify-Agenten NICHT blind glauben — die Haupt-Instanz prüft das tatsächliche
Ergebnis selbst im Browser (Schritt 5). Blocker zuerst, dann Minors.

## 4. Voller Grün-Gate

`pnpm exec turbo run typecheck lint test --filter=<betroffene Pakete>` **+ Shell-Build**. Selbst ausführen
(nicht „pass" eines Agenten vertrauen). Fixen bis grün: keine Typaufweichung, keine gelöschten Tests, eigener
Lazy-Chunk ohne `INEFFECTIVE_DYNAMIC_IMPORT`.

## 5. PFLICHT: visuelle Browser-Prüfung — siehe das tatsächliche Artefakt an

Nicht „grün" = nicht „gut/funktioniert". So prüft die Haupt-Instanz wirklich:

- **Servieren:** `pnpm --filter <tool> build:single`, dann `python -m http.server <port> --directory <tool>/dist-single`
  (auth-frei; `file://` wird vom Browser-Tool blockiert) — ODER die hosted Shell (`pnpm --filter @doppelklick/shell dev`, `#/tool/<slug>`).
- **Demo laden:** ohne Demo-Daten zeigt das UI nur Empty-States → die Reichhaltigkeit ist unsichtbar. Immer das Demo aktivieren.
- **Interaktion deterministisch testen:** SVG-Balken/Segmente per **Element-Referenz** klicken (`read_page filter=interactive` → Ref → Klick),
  NICHT per Pixel-Raten (unzuverlässig im skalierten Tab). Nach 2–3 Fehlklicks auf Ref-Klick wechseln.
- **rAF-Drossel umgehen:** Chrome drosselt `requestAnimationFrame` in versteckten/verdeckten Automations-Tabs →
  Count-up/Ring-/Balken-Eingangs-Animationen frieren bei 0 ein, obwohl die DATEN korrekt sind. Workaround:
  `requestAnimationFrame`→`setTimeout`-Shim + `visibilitychange`-Toggle (hidden→visible) erzwingen; sonst Endwerte
  via `aria-valuenow`/Legende auslesen. (`[[browser-check-gotchas]]`)
- **Artefakt-Frische sicherstellen:** ein vom Orchestrierungs-Lauf gebautes Single-File kann **stale** sein
  (wirkt z. B. nicht-klickbar), obwohl die QUELLE korrekt + grün ist. Im Zweifel **selbst frisch bauen** und erneut prüfen.
- **Screenshots** der Schlüssel-Screens (`save_to_disk`), beide Themes, ehrlich beurteilen. Bei „steril/flach" → nachbessern → **erneut ansehen** (Loop).

## 6. Abschluss & Persistenz (nach Freigabe)

- Conventional Commits, **gruppiert nach Paket** (z. B. `feat(shared-types)` / `fix(shared-print)` / `feat(tool-*)` / `docs`).
  Commit/Push/PR **erst nach Freigabe**; Merge nur auf ausdrückliches „merge".
- **Build-Artefakte NICHT committen** (`dist-single/`, `dist/`, `downloads/*.zip`).
- Pflegen: CHANGELOG `[Unreleased]`, `.scrum`-Ticket (in-progress→done bei Merge), ADR bei Architektur-Entscheidungen,
  **Memory**. Nach Merge `main` synchronisieren; bei stale Dev-Server (`6345`, strictPort) neu starten + hart neu laden.

## Wann diesen Skill nutzen

Mehrstufige Features, Redesigns/Design-Uplift, Migrationen, breite Audits — alles, was über `[[working-method]]`
laufen soll. Für reines FSD-Scaffolding eines einzelnen Slices: `/new-feature`. Für reine Design-Kritik/Politur:
die Impeccable-/Taste-Skills.
