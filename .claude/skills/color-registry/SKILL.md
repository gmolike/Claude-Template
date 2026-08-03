---
name: color-registry
description: 'VS-Code-Fensterfarben: welche Farbe ein Fenster heute trägt (Registry mit Fundstelle) und welche ein neues bekommt (deterministischer Vergabeplan aus Projekt-Slot und Rollen-Sprosse, ohne Buchführung). Nutze, wenn eine `*.code-workspace` oder `.vscode/settings.json` angelegt oder umgefärbt wird, wenn ein neues Projekt oder eine neue Rolle einen Farbton braucht, wenn zwei Fenster gleich aussehen, ein Fenster grau bleibt, die Titelleiste rot oder grau ist, oder Kontrast/Lesbarkeit an Status- oder Titelleiste beanstandet wird.'
allowed-tools: Read, Bash, Glob, Grep
---

# Color Registry & Vergabeplan

Zwei Dinge: eine **Registry** der heute gesetzten Fensterfarben (mit Fundstelle, damit sie prüfbar
bleibt) und ein **deterministischer Vergabeplan** für neue Fenster. Der Plan führt **kein Buch** —
derselbe Projektname und dieselbe Rolle ergeben auf jeder Maschine dieselbe Farbe, ohne Zustand,
ohne Nachschlagen, ohne Aushandeln.

> **Prosa deutsch, Code/Identifier/Farbnamen/JSON-Schlüssel englisch** (Repo-Konvention). Alle
> Zeilennummern **driften** — vor dem Zitieren nachgreppen, nicht dieser Datei glauben.
>
> **Maschinelle Wahrheit ist `src/colorRegistry.ts`.** Dieser Skill beschreibt, das Modul
> entscheidet. Weichen Tabelle und Modul ab, hat das Modul recht und die Tabelle ist der Fehler.

## Wann invoken

- Eine neue `*.code-workspace` oder eine neue `.vscode/settings.json` wird angelegt — oder eine
  bestehende soll umgefärbt werden.
- Ein **neues Projekt** oder eine **neue Rolle** entsteht und braucht einen Farbton.
- Zwei Fenster **sehen gleich aus**, oder ein Fenster bleibt **grau**.
- Die Titelleiste ist **rot**, obwohl niemand Rot gesetzt hat — oder sie ist grau, während die
  Statusleiste Farbe hat.
- Kontrast/Lesbarkeit wird beanstandet („Schrift in der Leiste kaum lesbar").
- Ein Farbwert soll **von Hand** geändert werden. (Antwort: nein — siehe Vergabeplan.)

## Zuerst: was hier NICHT automatisch passiert

**Es gibt keinen VS-Code-Emitter.** `shared/editors.json` führt für den Editor `vscode`
`"sinks": []`, mit dem `$comment` „empty and stays empty until the VS Code emitter exists".
agent-core schreibt heute ausschließlich nach `~/.claude/*` und in die Bundle-Stage.

Daraus folgt, ungeschönt:

| Frage | Antwort heute |
|---|---|
| Schreibt `agent-core sync` die Farbe? | **Nein.** Kein Sink, kein Emitter. |
| Wer schreibt die `*.code-workspace`? | Ein Mensch oder ein Agent — **jetzt**, von Hand, mit den Werten aus diesem Skill. Diese Hälfte wartet auf nichts. |
| Wer schreibt die `.vscode/settings.json`? | **Niemand von Hand.** Diese Hälfte wartet auf den VS-Code-Emitter und wird dann **werkzeuggeschrieben unter `seed-only`** — entschieden in `docs/decisions/ADR-0043-window-color-second-location-awaits-emitter.md`. Bis dahin bleibt sie in **jedem** Repo ohne Farbblock. |
| Schreibt agent-core in Claude-Template / faninitiative-platform / dnd / smart-home-app? | **Nie.** agent-core emittiert nur in das Repo, in dem es läuft. Der Rollout dort ist cross-repo-Handarbeit. |
| Wird ein vorhandener Peacock-Block überschrieben? | **Nein**, auch später nicht — siehe „Peacock" bei den Fallen. |

Ein Skill, der Automatik verspricht, die es nicht gibt, ist schlimmer als keiner. Wenn hier später
`sinks` gefüllt wird, ist **dieser Abschnitt** die Stelle, die als Erstes falsch wird.

## Der Vergabeplan

Eine Fensterfarbe entsteht aus drei Zahlen. Zwei stehen in einer Tabelle, die dritte ist konstant.
**Nichts wird pro Fenster gepflegt, nichts pro Worktree, nichts pro Maschine.**

```
hue (Farbton)    = PROJECT_SLOT * 30°        Slot aus der Projekt-Tabelle
L   (Helligkeit) = 54% - ROLE_RUNG * 3%      Sprosse aus der Rollen-Tabelle
C   (Buntheit)   = min(0.12, Cmax(L, hue))   sRGB-Gamut-Deckel
Vordergrund      = #ffffff                   immer, ausnahmslos
```

| Summand | Wert | Woher |
|---|---|---|
| `PROJECT_SLOT` | `0…11` (12 Fächer à 30°) | die Projekt-Tabelle unten — **nie umnummerieren** |
| `ROLE_RUNG` | `0…8` (9 Sprossen à 3 %) | die Rollen-Tabelle unten — **nie neu belegen** |
| `C` | Gamut-Projektion | rechnet das Modul; der Deckel `0.12` hält die Palette als **ein** System zusammen |

Gerechnet wird in **oklch**, ausgeliefert wird **Hex**. Beides ist Pflicht, keins ist Geschmack: in
HSL zu rechnen produziert die zwei kaputten Ist-Farben (siehe Fallen), und ein `oklch(…)` in der
Datei wird von VS Code **kommentarlos rot**.

**Kein Hash für das Projekt.** An den 11 echten Namen nachgerechnet: `charCodeSum` (das Verfahren
von `port-registry`) lässt 1° Abstand, FNV-1a kollidiert glatt bei 0°. 11 Namen auf 12 Fächer
kollidieren mit 99,94 % — Geburtstagsparadoxon, kein Qualitätsproblem des Hashs. Die Tabelle **ist**
die Ableitung.

### Projekt-Tabelle — der Slot ist `PROJECT_INDEX` aus `port-registry`

Das Projekt hat in diesem Ökosystem bereits eine kanonische Nummer. Eine zweite Tabelle wäre eine
zweite Driftquelle: **wer den Port kennt, kennt die Farbe.** Fundstelle der Nummer ist
`shared/skills/port-registry/SKILL.md` (Projekt-Tabelle), Fundstelle des Projekts sein Repo-Pfad.

| Slot | Projekt | h | Anker (Sprosse 0) | Slot | Projekt | h | Anker (Sprosse 0) |
|---|---|---|---|---|---|---|---|
| 0 | `claude-skills` | 0° | `#a54d6c` · 5.42 | 6 | `smart-home-app` | 180° | `#008171` · 4.80 |
| 1 | `dnd` | 30° | `#a95043` · 5.36 | 7 | `San` | 210° | `#007d8d` · 4.86 |
| 2 | `Claude-Template` | 60° | `#a05b11` · 5.25 | 8 | `claude-code-session-source` | 240° | `#0d76ad` · 4.99 |
| 3 | `doppelklick` | 90° | `#886b00` · 5.06 | 9 | `Projects` | 270° | `#5469b4` · 5.18 |
| 4 | `faninitiative-platform` | 120° | `#667815` · 4.93 | 10 | `canu-camp-hennig` | 300° | `#7a5da9` · 5.29 |
| 5 | `global-login` | 150° | `#2f8247` · 4.77 | 11 | *frei* | 330° | — |

- Ein **bestehender Slot wird nie umnummeriert.** Er verschiebt sonst still jedes Fenster jedes
  Worktrees dieses Projekts — und, weil die Tabelle geteilt ist, zusätzlich jeden Port.
- **Neues Projekt → nächster freier Slot**, eingetragen in **beide** Registries.
- **Nach Slot 11 ist Schluss.** Kein 13. Farbton: er behauptet eine Information, die er nicht mehr
  trägt (siehe Fallen). Entweder räumt ein totes Projekt seinen Slot, oder der Kanal wird als voll
  gemeldet.

### Rollen-Tabelle — die Abstufung

Die Sprosse ist **projektunabhängig**: `web` ist in jedem Projekt Sprosse 3.

| Sprosse | L | Rolle | Fenster enthält |
|---|---|---|---|
| 0 | 54 % | `project` | das ganze Repo — Root, alle Apps, alle Packages, Board, Docs |
| 1 | 51 % | `shared` | `packages/*` |
| 2 | 48 % | `api` | `apps/api` + zugehörige Packages |
| 3 | 45 % | `web` | `apps/web` + zugehörige Packages |
| 4 | 42 % | `mobile` | `apps/mobile` + zugehörige Packages |
| 5 | 39 % | `designer` | `apps/web` + `packages/shared-ui` + Board + Docs |
| 6 | 36 % | `content` | `docs`, `guides`, `.scrum/content` |
| 7 | 33 % | `po` | `.scrum`, `docs`, Root |
| 8 | 30 % | `qa` | Root + alle Apps + `shared-types` |

Die Reihenfolge ist nicht willkürlich: Sprosse 0 **ist** das Projekt und trägt den reinsten Ankerton;
1–4 folgen der Release-Ordnung aus `shared/rules/20-workflow.md` (shared-types → api → web/mobile);
5–8 sind die Rollen ohne eigene Code-Schicht (Design → Dokument → Planung → Test). Wer die
Release-Ordnung kennt, kennt die Leiter.

- **Eine bestehende Sprosse wird nie neu belegt.**
- **`team` hat keine Sprosse.** Es ist `project` ∪ `docs` — eine exakte Obermenge, keine eigene
  Rolle. `team.code-workspace` wird gelöscht, seine Ordnerliste wandert in `project`.
- **Sprosse 9 gibt es nicht.** Sie läge bei L=27 %; dort fällt die Projekt-Trennung unter die
  Rollen-Trennung — die Rolle wäre besser lesbar als das Projekt, also genau verkehrt herum. Eine
  zehnte Rolle kostet eine Entscheidung, keine Zeile.

### Worktrees erben unverändert

**Ein Worktree bekommt Slot und Sprosse seines Projekts, ohne jede Abwandlung.** Kein Suffix, keine
Ableitung aus dem Slug. Ein `claude-skills`-Worktree mit Rolle `web` ist exakt `#883352`, wie der
Hauptbaum.

Bewusst anders als `port-registry`, und der Grund ist konkret: zwei Worktrees können sich einen Port
**nicht teilen**, eine Farbe sehr wohl. Sie kollidieren nicht, sie sind nur nicht auseinanderzuhalten
— und den Ordnernamen trägt VS Code ohnehin als Text in der Titelleiste. 19 Arbeitsbäume × 9 Rollen
wären 171 Zustände statt 99.

### Die fertige Palette — 99 Werte, nichts auszuhandeln

Jede Zelle: **Hintergrund · Kontrast gegen `#ffffff`**. Der Vordergrund ist überall `#ffffff`.

| Projekt | h | `project` | `shared` | `api` | `web` | `mobile` | `designer` | `content` | `po` | `qa` |
|---|---|---|---|---|---|---|---|---|---|---|
| **claude-skills** | 0° | `#a54d6c` · 5.42 | `#9b4563` · 6.13 | `#913c5b` · 7.00 | `#883352` · 7.95 | `#7e2a4a` · 9.06 | `#752142` · 10.23 | `#6b183a` · 11.56 | `#620d33` · 12.93 | `#58012b` · 14.44 |
| **dnd** | 30° | `#a95043` · 5.36 | `#9f473b` · 6.11 | `#953e32` · 6.97 | `#8c352a` · 7.90 | `#822d22` · 8.95 | `#78231a` · 10.22 | `#6f1a11` · 11.46 | `#650f08` · 12.92 | `#5c0300` · 14.30 |
| **Claude-Template** | 60° | `#a05b11` · 5.25 | `#965200` · 5.99 | `#8a4b00` · 6.80 | `#7f4400` · 7.69 | `#733e00` · 8.68 | `#683700` · 9.84 | `#5c3000` · 11.18 | `#512a00` · 12.49 | `#472400` · 13.81 |
| **doppelklick** | 90° | `#886b00` · 5.06 | `#7d6200` · 5.80 | `#735a00` · 6.58 | `#695200` · 7.48 | `#5f4a00` · 8.52 | `#564200` · 9.66 | `#4c3b00` · 10.86 | `#433300` · 12.27 | `#3a2c00` · 13.63 |
| **faninitiative-platform** | 120° | `#667815` · 4.93 | `#5e6f03` · 5.60 | `#566600` · 6.37 | `#4e5d00` · 7.27 | `#465400` · 8.31 | `#3f4c00` · 9.35 | `#384300` · 10.65 | `#303b00` · 11.99 | `#293300` · 13.39 |
| **global-login** | 150° | `#2f8247` · 4.77 | `#25793f` · 5.40 | `#197037` · 6.15 | `#09672e` · 7.02 | `#005e28` · 7.98 | `#005423` · 9.16 | `#004b1e` · 10.37 | `#00421a` · 11.70 | `#003915` · 13.16 |
| **smart-home-app** | 180° | `#008171` · 4.80 | `#007768` · 5.47 | `#006d5f` · 6.26 | `#006457` · 7.09 | `#005a4f` · 8.15 | `#005146` · 9.27 | `#00483e` · 10.52 | `#003f36` · 11.90 | `#00362f` · 13.39 |
| **San** | 210° | `#007d8d` · 4.86 | `#007382` · 5.56 | `#006a77` · 6.31 | `#00616d` · 7.17 | `#005763` · 8.26 | `#004e59` · 9.40 | `#00464f` · 10.56 | `#003d45` · 11.98 | `#00353c` · 13.34 |
| **claude-code-session-source** | 240° | `#0d76ad` · 4.99 | `#006da2` · 5.66 | `#006495` · 6.45 | `#005b88` · 7.36 | `#00537c` · 8.31 | `#004a70` · 9.49 | `#004264` · 10.70 | `#003958` · 12.17 | `#00314c` · 13.60 |
| **Projects** | 270° | `#5469b4` · 5.18 | `#4c60aa` · 5.90 | `#4458a1` · 6.65 | `#3c4f97` · 7.62 | `#34468e` · 8.70 | `#2d3e84` · 9.84 | `#26357b` · 11.18 | `#1f2d72` · 12.53 | `#182469` · 14.05 |
| **canu-camp-hennig** | 300° | `#7a5da9` · 5.29 | `#7154a0` · 6.04 | `#694b96` · 6.89 | `#60438d` · 7.82 | `#583a84` · 8.92 | `#50327b` · 10.08 | `#482971` · 11.47 | `#402168` · 12.84 | `#38185f` · 14.34 |

Gemessen über alle 99 Kombinationen: Kontrast **4,77 … 14,44** — alle bestehen WCAG AA; AAA (7:1)
erreichen alle 11 Projekte erst **ab Sprosse 3** (dort min 7,02), Sprosse 2 liegt im schlechtesten
Fall bei 6,15. Kleinste Trennung zweier gleichzeitig sichtbarer Fenster in Normalsicht
**0,026** (geplant) bzw. **0,029** (die 20 real belegten Fenster). Beispiel für die gelöste Aufgabe:
`Claude-Template/web` `#7f4400` gegen `faninitiative-platform/web` `#4e5d00` = **dE 0,107** statt
heute identisch.

### Nachrechnen

Zwei Menschen kommen unabhängig auf dasselbe Ergebnis, weil beide dasselbe Modul aufrufen. Aus der
Repo-Wurzel von agent-core:

```bash
npx tsx -e "import {deriveColor} from './src/colorRegistry.ts'; console.log(deriveColor('Claude-Template','web'))"
```

Die vier Schlüssel fertig zum Einfügen:

```bash
npx tsx -e "import {windowColors} from './src/colorRegistry.ts'; console.log(JSON.stringify(windowColors('Claude-Template','web'),null,2))"
```

**Einzeiler oder Datei — nie mehrzeilig.** Mehrzeiliges `node -e` läuft unter Git-Bash als **leeres
Programm** und endet mit Exit 0 (`shared/memory/00-knowledge.md`): es sieht aus wie ein Erfolg und
hat nichts gerechnet.

Unbekannter Projekt- oder Rollenname ⇒ das Modul **wirft**. Das ist Absicht: eine geratene Farbe ist
von einer richtigen nicht zu unterscheiden.

## Die Registry — was heute wo steht

20 Fenster in 5 Repos (nach dem `team`-Merge, inklusive des Dogfood-Fensters von agent-core). Jede
Zeile: Soll-Farbe aus dem Plan, Kontrast gegen `#ffffff`, die Datei als Fundstelle, und was heute
wirklich drinsteht.

### claude-skills — Slot 0, h 0° (Dogfood)

| Rolle | Soll | Kontrast | Fundstelle | Ist |
|---|---|---|---|---|
| `project` | `#a54d6c` | 5.42 | `claude-skills/claude-skills.code-workspace` | `#a54d6c` — **Soll = Ist** |

Der Dateiname trägt hier den **Projektschlüssel** (`PROJECT_SLOTS` in `src/colorRegistry.ts` führt
`"claude-skills"`, Verzeichnisname, case-sensitive), nicht die Rolle — anders als in
Claude-Template/faninitiative-platform, wo `web.code-workspace` die **Rolle** trägt. Welche der
beiden Konventionen der spätere Emitter liest, ist offen und in
`.scrum/tech-specs/SPEC-color-registry.md` §6.2 (b) als Entscheidung vermerkt.

### Claude-Template — Slot 2, h 60°

| Rolle | Soll | Kontrast | Fundstelle | Ist |
|---|---|---|---|---|
| `project` | `#a05b11` | 5.25 | `Claude-Template/project.code-workspace` | *kein Farbblock* |
| `shared` | `#965200` | 5.99 | `Claude-Template/shared.code-workspace` | `#E2B714` — **1,91:1, defekt** |
| `api` | `#8a4b00` | 6.80 | `Claude-Template/api.code-workspace` | `#1e8449` |
| `web` | `#7f4400` | 7.69 | `Claude-Template/web.code-workspace` | `#1565C0` |
| `mobile` | `#733e00` | 8.68 | `Claude-Template/mobile.code-workspace` | `#C62828` |
| `designer` | `#683700` | 9.84 | `Claude-Template/designer.code-workspace` | `#db2777` Titel / `#be185d` Status — **zwei Farben** |
| `content` | `#5c3000` | 11.18 | `Claude-Template/content.code-workspace` | `#6c3483` |
| `po` | `#512a00` | 12.49 | `Claude-Template/po.code-workspace` | *kein Farbblock* |
| `qa` | `#472400` | 13.81 | `Claude-Template/qa.code-workspace` | `#b7950b` — **2,87:1, defekt** |

`Claude-Template/team.code-workspace` entfällt: Ordnerliste nach `project` (das ist `project` + `docs`), Datei löschen.

### faninitiative-platform — Slot 4, h 120°

| Rolle | Soll | Kontrast | Fundstelle | Ist |
|---|---|---|---|---|
| `project` | `#667815` | 4.93 | `faninitiative-platform/project.code-workspace` | *kein Farbblock* |
| `shared` | `#5e6f03` | 5.60 | `faninitiative-platform/shared.code-workspace` | `#E2B714` — **defekt** |
| `api` | `#566600` | 6.37 | `faninitiative-platform/api.code-workspace` | `#1e8449` |
| `web` | `#4e5d00` | 7.27 | `faninitiative-platform/web.code-workspace` | `#1565C0` |
| `designer` | `#3f4c00` | 9.35 | `faninitiative-platform/designer.code-workspace` | `#db2777` / `#be185d` — **zwei Farben** |
| `content` | `#384300` | 10.65 | `faninitiative-platform/content.code-workspace` | `#6c3483` |
| `po` | `#303b00` | 11.99 | `faninitiative-platform/po.code-workspace` | `#7c3aed` / `#6d28d9` — **zwei Farben** |
| `qa` | `#293300` | 13.39 | `faninitiative-platform/qa.code-workspace` | `#b7950b` — **defekt** |

Kein `mobile`-Workspace vorhanden. `team.code-workspace` entfällt wie oben — vor dem Merge klären,
ob `apps/mobile` dort überhaupt existiert (die `team`-Datei kennt den Ordner, die `project`-Datei nicht).

### dnd und smart-home-app — je ein Fenster

| Projekt | Rolle | Soll | Kontrast | Fundstelle | Ist |
|---|---|---|---|---|---|
| `dnd` (Slot 1) | `project` | `#a95043` | 5.36 | `dnd/flammenreiter.code-workspace` | *kein Farbblock* |
| `smart-home-app` (Slot 6) | `project` | `#008171` | 4.80 | `smart-home-app/smart-home-app.code-workspace` | *kein Farbblock — Datei ist kaputtes JSON* |

### Der zweite Ablageort — `.vscode/settings.json` je Repo-Wurzel

Immer Sprosse 0 (`project`), weil die Datei für den **ganzen** Ordner gilt. Sechs existieren heute,
fünf Repos haben noch gar kein `.vscode/`.

**Die Soll-Spalte ist hier ein Zielwert, keine Arbeitsanweisung.** Dieser Ablageort wird **nicht von
Hand** befüllt: er wartet auf den VS-Code-Emitter und wird dann werkzeuggeschrieben unter `seed-only`
(ADR-0043). Deshalb steht in der Ist-Spalte auf absehbare Zeit weiter „keine Farbe":

| Repo | Soll | Kontrast | Fundstelle | Ist |
|---|---|---|---|---|
| `claude-skills` | `#a54d6c` | 5.42 | `claude-skills/.vscode/settings.json` | keine Farbe — Block **namentlich ausgeschlossen** (s. u.) |
| `Claude-Template` | `#a05b11` | 5.25 | `Claude-Template/.vscode/settings.json` | keine Farbe |
| `dnd` | `#a95043` | 5.36 | `dnd/.vscode/settings.json` | **Peacock, 24 Farbschlüssel** — wird nicht angefasst |
| `faninitiative-platform` | `#667815` | 4.93 | `faninitiative-platform/.vscode/settings.json` | keine Farbe |
| `San` | `#007d8d` | 4.86 | `San/.vscode/settings.json` | keine Farbe |
| `smart-home-app` | `#008171` | 4.80 | `smart-home-app/.vscode/settings.json` | keine Farbe |
| `doppelklick` · `global-login` · `claude-code-session-source` · `Projects` · `canu-camp-hennig` | s. Projekt-Tabelle | — | **Datei fehlt** | — |

**Nebenbestände, die beim Zählen dazugehören:** dnd hat **acht** `.vscode/settings.json` (Wurzel plus
`api`, `docs`, `lore-admin`, `session-gm`, `session-player`, `shared`, `ue5`) — alle Peacock, alle
tabu. Und unter `faninitiative-platform/.claude/worktrees/` liegen neun Kopien der Workspace-Dateien;
sie erben dieselben Werte und sind kein Sonderfall, aber „19 Dateien" darf nicht zu „19 von 28" werden.

## Die vier Schlüssel — an beiden Orten dieselben

| Schlüssel | Wert |
|---|---|
| `statusBar.background` | die Farbe aus dem Plan |
| `statusBar.foreground` | `#ffffff` |
| `titleBar.activeBackground` | **dieselbe** Farbe |
| `titleBar.activeForeground` | `#ffffff` |

Beide Hintergründe tragen denselben Wert — eine Rolle, **eine** Farbe. Das ist die Festlegung gegen
den Ist-Zustand, in dem `designer` und `po` je zwei verschiedene tragen.

**Warum zwei Ablageorte sich nicht widersprechen können:** `workbench.colorCustomizations` ist ohne
`scope` registriert, gilt also als `window`-scoped. Ist eine `*.code-workspace` geöffnet, gewinnt
deren Wert und die `settings.json` der eingebundenen Ordner werden ignoriert; wird der Ordner direkt
geöffnet, **ist** `.vscode/settings.json` die Workspace-Ebene. Komplementär, nie konkurrierend —
und genau deshalb muss der Hex an beiden Orten **derselbe** sein: dem Nutzer soll nicht auffallen,
wie er die Datei geöffnet hat.

```jsonc
// Generated -- do not hand-edit. Regenerate with:
//   npx tsx -e "import {windowColors} from './src/colorRegistry.ts'; console.log(JSON.stringify(windowColors('Claude-Template','web'),null,2))"
// color-registry: project=Claude-Template (slot 2, hue 60) x role=web (rung 3, L 45%)
// oklch(45% 0.12 60) -> #7f4400 -- contrast 7.69:1 vs #ffffff (WCAG AA)
"workbench.colorCustomizations": {
  "statusBar.background": "#7f4400",
  "statusBar.foreground": "#ffffff",
  "titleBar.activeBackground": "#7f4400",
  "titleBar.activeForeground": "#ffffff"
}
```

**Bewusst NICHT gesetzt:** `titleBar.inactiveBackground`/`-Foreground` (das inaktive Fenster fällt
auf die Theme-Farbe zurück; wer es will, nimmt denselben Hex plus Alpha `99` — Opt-in, weil ein
Alpha-Wert gegen einen unbekannten Untergrund keinen garantierbaren Kontrast mehr hat).
`workbench.colorTheme` und alles übrige `workbench.*` (ein Theme in einer geteilten Datei nimmt
jedem Mitleser seins weg). Die ~20 weiteren Peacock-Schlüssel (`activityBar.*`, `commandCenter.*`,
`statusBarItem.*`, …) — jede weitere Fläche wäre eine weitere, die kontrastgeprüft werden muss.
Vier reichen.

## Die Fallen

### `oklch(…)` in der Datei ergibt eine **rote** Titelleiste — ohne jede Meldung

Die schlimmste, weil sie aussieht wie ein Tippfehler und keiner ist. VS Code nimmt **nur Hex**; der
Parser lautet sinngemäß `static fromHex(i){ return parseHex(i) || red }`. Ein `oklch(...)`, `hsl(...)`,
`rgb(...)` oder ein Farbname wird **`#ff0000`** — kein Log, kein Theme-Fallback, keine Meldung. Die
JSON-Sprachserver-Warnung („Invalid color format. Use #RGB, #RGBA, #RRGGBB or #RRGGBBAA.") sieht nur,
wer die Datei offen hat.

**Regel: oklch ist der Autorenraum, Hex das Lieferformat.** Nachprüfbar in der eigenen Installation:
`grep -o "fromHex(i){[^}]*}"` über `resources/app/out/vs/workbench/workbench.desktop.main.js`.

### In HSL zu rechnen ist der Fehler, den man nicht sieht

Bei identischem `hsl(h, 100%, 50%)` schwankt die tatsächliche Luminanz über den Farbkreis um **Faktor
12,9**, der Kontrast zu Weiß von 8,59:1 bis 1,07:1 — **10 von 12 Farbtönen fallen durch**. Dieselbe
Messung in `oklch(52% 0.13 h)`: Faktor **1,20**, alle bestehen. HSLs „Lightness" ist keine Helligkeit.
„Rolle = L minus 10 %" bedeutet in HSL je Farbton etwas völlig anderes — daraus entstehen `shared`
mit 1,91:1 und `qa` mit 2,87:1.

### Die Leiter geht nur abwärts

Deckel ist **L ≤ 54 %** (gerechnet: 55,2 % im ungünstigsten Farbton, h=150). Darüber trägt weißer
Text keine 4,5:1 mehr. Und man kann **nicht** einfach auf Schwarz wechseln: das Fenster, in dem
beide Vordergründe funktionieren, ist **0,0083 breit** — 4,5 % des Weiß-Bandes. Eine Leiter, die die
Grenze überschreitet, müsste den Vordergrund mitwechseln, und dann ist „Vordergrund ist immer
`#ffffff`" keine Regel mehr, sondern eine Fallunterscheidung, die irgendwann jemand vergisst.

Die zwei defekten Ist-Farben sind exakt dieser Fehler: `shared` liegt bei L=79,5 % (**2,7× über dem
Deckel**), `qa` bei L=68,2 %. Beide wollten die Rolle durch **Aufhellen** kenntlich machen.

### Der Farbtonkanal ist bei 12 voll — nicht bei 20

Gemessen, je Anzahl gleichmäßig verteilter Töne, kleinster Abstand über Normalsicht + Deuteranopie +
Protanopie:

| N Töne | 6 | 8 | 10 | 11 | 12 | 14 | 16 |
|---|---|---|---|---|---|---|---|
| min dE | **0,057** | 0,037 | 0,026 | 0,025 | 0,019 | 0,013 | 0,012 |

Ein 13. Ton ist schlimmer als gar keine Farbe: er behauptet eine Information, die er nicht trägt.
**Wenn Slot 11 vergeben ist, wird nicht die Schwelle gesenkt** — ein totes Projekt räumt seinen Slot,
oder der Kanal wird als voll gemeldet.

### Farbfehlsichtigkeit: der Abstand darf nicht im Farbkreis gemessen werden

Bei festem L schrumpft die OKLab-**a**-Achse von Spanne 0,248 (Normalsicht) auf 0,028 unter
Deuteranopie — **Faktor 8,8**; die b-Achse bleibt (0,237 → 0,242). Rot-Grün kollabiert, Blau-Gelb
überlebt. Deshalb ist der Winkel als Kriterium **wertlos**, messbar in beide Richtungen: `api` und
`mobile` liegen **126°** auseinander und verlieren 82 % (0,289 → 0,052); `designer` und `content`
liegen **46°** auseinander und verlieren 7 %. **Gemessen wird `dE` in OKLab nach der Simulation,
nie ein Winkel.**

Die unbequeme Zahl dieser Palette: über alle drei Sichten liegt die kleinste Trennung bei **0,002** —
die Slots 2, 3 und 4 fallen unter Deuteranopie auf dasselbe Oliv zusammen. WCAG-konform bleibt es,
weil VS Code den Ordnernamen als **Text** führt (redundante Kodierung, 1.4.1) und der Rollenkanal
Helligkeit praktisch verlustfrei überlebt (0,028 → 0,025). **Rollen bleiben für Dichromaten
unterscheidbar, Projekte nicht.** Ist der Nutzer rot-grün-blind, trägt der Farbton 6 Projekte statt
11 — dann muss die Grundentscheidung neu fallen, nicht die Palette nachjustiert werden.

### Das Theme überschreibt nichts — der **native** Fensterrahmen schon

`workbench.colorCustomizations` gewinnt gegen jedes Theme. Was wirklich droht:
`window.titleBarStyle: "native"` — dann zeichnet das Betriebssystem die Titelleiste und **kein
`titleBar.*` greift**. Symptom: „die Farbe ist halb da", Statusleiste bunt, Titelleiste grau. Das ist
der zweite, unabhängige Grund, **beide** Flächen zu setzen: bei nativem Rahmen trägt die Statusleiste
die Information allein.

### Graues Fenster: die Workspace-Datei ist gar nicht geöffnet

Wer `code C:/Entwicklung/Claude-Template` tippt statt `code Claude-Template/web.code-workspace`,
öffnet einen **Ordner** — die Workspace-Datei liegt nur herum. Genau dafür steht die Farbe zusätzlich
in `.vscode/settings.json`.

**Rest-Lücke:** wer einen **Unterordner** direkt öffnet (`code Claude-Template/apps/web`), bekommt
weder das eine noch das andere — es sei denn, dort liegt eine eigene `.vscode/settings.json`. Das ist
dnds Muster mit acht Dateien. Dieser Skill deckt **eine** Datei je Repo-Wurzel ab; ein
Unterordner-Rollout ist eine eigene Entscheidung.

### Peacock: die Farbe kommt an, wo nichts steht — und nur dort

`dnd/.vscode/settings.json` trägt einen Peacock-Block mit **24 Farbschlüsseln** plus
`"peacock.color"`, darunter alle vier dieser Registry. Dort passiert **nie** etwas — kein
Endlos-Diff gegen ein Werkzeug des Nutzers. Von außen sieht das aus wie ein kaputter Emitter.

**Deshalb: den Konflikt melden, nicht lösen** — mit Dateipfad und dem gefundenen Wert. Ein Mensch
entscheidet, ob Peacock weicht. Ein Gate, das still nichts tut, ist von einem kaputten nicht zu
unterscheiden.

```bash
rg -n "workbench.colorCustomizations|peacock.color" --glob "**/.vscode/settings.json" --glob "*.code-workspace"
```

### Zwei Orte driften — der Ist-Zustand ist der Beweis

Jeder Hex steht künftig **zweimal** je Projekt/Rolle. Das ist eine gespiegelte Kopie eines Contracts,
und die driftet — nicht theoretisch: **heute schon** trägt `designer` `#db2777` in der Titelleiste und
`#be185d` in der Statusleiste, `po` entsprechend `#7c3aed`/`#6d28d9`, in **einer** Datei, für **eine**
Rolle. Zwei Dateien werden es zuverlässiger tun.

Konsolidierungs-Rangfolge nach `shared/rules/25-orchestration.md`: **generieren** ist möglich, also
wird generiert — beide Orte aus **einer** Funktion (`src/colorRegistry.ts`). Der Golden Test gegen
**eine** Fixture ist der Boden darunter, nicht die Alternative; er liegt neben dem Modul
(`src/colorRegistry.test.ts`) und läuft im normalen Gate mit (`pnpm test`).

### Kleinkram, der Zeit kostet

- **`smart-home-app/smart-home-app.code-workspace` ist kein gültiges JSON** — `Unexpected token ']'`,
  ein Komma vor einer schließenden Klammer. Jedes Skript mit `JSON.parse` über den Bestand stirbt
  dort; ein JSONC-Strip hilft nicht, es ist kein Kommentarproblem. Erst reparieren, dann umfärben.
- **`claude-skills/.vscode/settings.json` schließt `workbench.colorCustomizations` namentlich aus**
  (Block „DELIBERATELY NOT IN THE TEAM REPO … (Peacock!)"). Die Begründung zielt auf
  `workbench.colorTheme`; **entschieden ist das inzwischen** (ADR-0043): der Ausschluss wird **nicht
  von Hand** aufgehoben, sondern **im selben Commit wie der Emitter** präzisiert — `colorTheme` und
  `iconTheme` bleiben draußen, die vier Chrome-Schlüssel kommen herein. Bis dahin gilt der Ausschluss
  unverändert: **kein Farbblock in dieser Datei.**
- **Der Rollout ist cross-repo**: fünf Repos, fünf Commits, kein gemeinsamer PR. Vor jedem Commit
  `git fetch` und gegen die eigene Upstream **und** `origin/<default-branch>` diffen — zwei Sitzungen
  sehen einander nicht (`shared/rules/26-autonomy.md`).
- **Umlaute:** JSON-Schlüssel, Farbnamen und Kommentare in den ausgelieferten Dateien bleiben
  englisch und ASCII; nur die Prosa hier ist deutsch (`shared/rules/40-language.md`).

## Einen neuen Eintrag hinzufügen

Damit die Registry nicht driftet:

1. **Neues Projekt** → nächster freier Slot, eingetragen in **beide** Registries (hier **und**
   `shared/skills/port-registry/SKILL.md`) und in `PROJECT_SLOTS` in `src/colorRegistry.ts`.
   Bestehende Slots **nie** umnummerieren. Nach Slot 11 ist der Kanal voll.
2. **Neue Rolle** → das ist eine **Entscheidung**, keine Zeile: Sprosse 9 gibt es nicht. Erst prüfen,
   ob die Rolle eine Obermenge einer bestehenden ist (so ist `team` weggefallen).
3. **Farbe holen**, nie ausdenken — `npx tsx -e "…deriveColor(…)"` aus der Repo-Wurzel.
4. **Die `*.code-workspace` schreiben** — vier Schlüssel, Vordergrund `#ffffff`, Hex aus dem Modul.
   **Die `.vscode/settings.json` der Repo-Wurzel dabei NICHT anfassen:** derselbe Hex, aber nicht
   derselbe Zeitpunkt — dieser Ablageort wartet auf den Emitter und wird dann unter `seed-only`
   werkzeuggeschrieben (ADR-0043). Ein Handeintrag dort kippt einen dokumentierten Ausschluss still.
5. **Zeile in die Registry oben** — mit `datei` als Fundstelle (vorher gegreppt, nicht aus dem Kopf)
   und dem Ist-Wert, falls schon einer dasteht.
6. **Drift-Check** — findet Farben, die von der Ableitung abweichen:

```bash
rg -n "statusBar\.background|titleBar\.activeBackground" --glob "*.code-workspace" --glob "**/.vscode/settings.json" C:/Entwicklung
```

   Was der Check findet und hier fehlt, ist ein fehlender Eintrag — **kein Fund ohne Fundstelle gilt.**
   Was er findet und was von der Tabelle abweicht, ist Drift: Modul aufrufen, Modul gewinnt.
