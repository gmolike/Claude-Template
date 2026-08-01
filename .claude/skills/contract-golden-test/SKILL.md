---
name: contract-golden-test
description: 'Golden-Test gegen EINEN geteilten Fixture-Satz aufsetzen, sobald ein Contract/Schema in mehr als einem Paket gespiegelt oder geshimmt wird (Shim, Mirror, lokale Re-Deklaration, Versions-Skew zwischen installiertem und lokalem shared). Liefert das Round-Trip-Muster build→serialize→validate→read, ein lauffähiges Vitest-Template und die RED-Verify-Pflicht. Nutze, wenn du eine zweite Kopie eines Contracts anlegst oder vorfindest, wenn Agenten parallel an derselben Form arbeiten, oder wenn ein Layout/Payload zwischen zwei Paketen still divergiert (HTTP 400, ZodError beim Save, lautlos übersprungene Datensätze).'
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Contract Golden Test

Dieses Skill setzt den **Golden-Test** auf, der eine über mehrere Pakete **gespiegelte** Contract-Form
zusammenhält. Es ist die **Untergrenze** aus `25-orchestration` („Consolidate shared semantics") —
nicht die beste Option, sondern der Boden, auf den man fällt, wenn Serialize/Generate nicht erreichbar
sind. Grundlage: **ADR-0021**.

> **Prosa deutsch, Code/Identifier/Dateinamen englisch** (Repo-Konvention).

## Wann invoken

- Du legst eine **zweite Kopie** eines Contracts an (Shim, Mirror, lokale Re-Deklaration eines
  Zod-Schemas / Typs / Wire-Formats) — oder findest eine vor.
- Zwischen **installiertem** `shared`-Paket und **lokaler** Quelle besteht ein **Versions-Skew**
  (das ist eine Kopie, auch wenn sie nicht so heißt).
- Mehrere Agenten arbeiten **parallel** an derselben Form/Protokoll/Migration.
- Symptome, die Shim-Drift verraten: **HTTP 400** auf ein neues Layout, **ZodError beim Save** bei
  grünem Editor, **lautlos** übersprungene Datensätze in einer Lese-Query.

**Trigger ist die Kopie, nicht die Agentenzahl.** Vier Kopien divergieren auch, wenn ein einzelner
Mensch sie über drei Sessions pflegt.

## Warum ein Renderer-/Unit-Test es NICHT fängt

Jeder Konsument testet gegen **seine eigene** Kopie — und ist darin **in sich konsistent**. Der Test
ist grün, weil Producer und Assertion aus derselben Kopie stammen. Was niemand testet, ist der
**Übergang** zwischen zwei Kopien.

Belegter Vorfall (Flammenreiter, 2026-07-18): dieselbe v2-Slot-Form (`slot.panels[]`/`activePanelId`)
lag in **4 Kopien** (shared-Quelle + 3 Shims) und divergierte in **einem** Lauf **dreimal** —
api-Shim behielt v1 `panelId` → **HTTP 400** auf jedes v2-Layout; die Lese-Query migrierte über das
installierte v1-`shared` → übersprang v2-Profile **lautlos**; der Editor baute v1, das Save validierte
v2 → **ZodError**. **Alle** Agenten meldeten grüne Gates.

## Das Muster: build → serialize → validate → read

**Dieses SKILL.md ist die kanonische Quelle des Musters.** `25-orchestration`, `30-quality`,
`31-quality-web` und das `verify`-Skill nennen nur die vier Schritte und zeigen hierher — Code steht
genau an dieser einen Stelle, damit die Kopien nicht auseinanderlaufen.

Vier Schritte, jeder kreuzt eine echte Paketgrenze. Ein Test, der einen davon auslässt, ist kein
Golden-Test:

| Schritt | Was er ausführt | Welche Divergenz er fängt |
|---|---|---|
| **build** | der **Producer** (Editor/Builder) erzeugt aus dem Fixture die Form | Producer baut noch v1 |
| **serialize** | `JSON.parse(JSON.stringify(x))` — die **API-Grenze** | alles, was die JSON-Grenze nicht überlebt (`Date`, `undefined`, `Map`, Klassen-Instanzen) |
| **validate** | das **Save-Schema** parst die **serialisierte** Form | Save-Schema kennt die Wire-Form nicht (HTTP 400 / ZodError) |
| **read** | der **Reader/Migrator** liest die serialisierte Form zurück | Reader migriert über eine alte Version → lautloses Überspringen |

```ts
const built = editorBuild(tabGroupLayout);                  // producer
const wire = JSON.parse(JSON.stringify(built));             // api boundary (serialize)
expect(SaveSchema.safeParse(wire).success).toBe(true);      // save path validates the WIRE form
expect(migrateOnRead(wire)).toEqual(built);                 // read path
// RED-verify: swap in the OLD (v1) migrate → must fail.
```

**Die Reihenfolge ist tragend: erst serialisieren, dann validieren.** Die API sieht nie das Objekt,
sie sieht den Payload — genau daran hing der belegte HTTP 400. Validiert man vor `JSON.stringify`,
prüft das Save-Schema eine Form, die nie über die Leitung geht, und die Divergenzen, die der
serialize-Schritt fangen soll (`Date`, `undefined`, `Map`, Klassen-Instanzen), rutschen durch.

> **Zusätzlich `safeParse(built)` vor dem Serialisieren?** Nur als optionale Diagnose, nie als
> zweite Pflicht-Assertion: ein Save-Schema, das korrekt die *Wire*-Form modelliert (z. B.
> `z.iso.datetime()` für ein producer-seitiges `Date`), lehnt das In-Memory-Objekt **zu Recht** ab —
> die Assertion würde ausgerechnet die Drift-Klasse rot machen, für die es den serialize-Schritt
> gibt. Ist die gebaute Form per Contract JSON-identisch, kann die Zeile den Fehler früher
> lokalisieren (Producer vs. Serialisierung); tragend bleibt die Wire-Validierung.

Vollständiges, lauffähiges Template: [`assets/contract.golden.example.ts`](./assets/contract.golden.example.ts)
— beim Übernehmen in `contract.golden.test.ts` umbenennen (es heißt `.example.ts`, damit es
unadoptiert unter `.claude/skills/` in **keinem** Default-Test-Glob landet).

## EIN Fixture-Satz, N Konsumenten

Das **Serialize-Prinzip**, auf den Test angewandt: Der Fixture-Satz lebt in **genau einem** Paket und
wird von **jedem** Konsumenten **importiert**.

```
packages/contract-fixtures/src/fixtures.ts   ← der EINE Satz (siehe assets/fixtures.example.ts)
   ↑            ↑              ↑
apps/api    apps/web-gm    apps/web-player   ← jeder importiert, keiner kopiert
```

- **Nie** kopieren, **nie** pro Paket „leicht anpassen". Eine kopierte Fixture driftet mit der Kopie
  mit — dann bestätigt der Test nur noch die lokale Wahrheit und ist wertlos.
- Der **Test** läuft dagegen in **jedem** Konsumenten-Gate (N-mal). Ein einzelner zentraler Lauf würde
  genau die lokale Kopie nicht sehen — das ist der Sinn der Übung, nicht ein Versehen.
- Der Fixture-Satz deckt **je eine** Fixture pro relevanter Contract-Variante ab (v1-Legacy, v2,
  Randfälle wie leere Collections und optionale Felder) — siehe
  [`assets/fixtures.example.ts`](./assets/fixtures.example.ts).

## RED-Verify ist Pflicht

Ein Golden-Test, der nie gegen die **kaputte** Implementierung lief, ist unbewiesen
(`30-quality`: „Regression tests — verified RED, not assumed"). Also:

1. Die **alte** (v1-)Variante einsetzen — `migrateOnRead` durch die v1-Migration ersetzen **oder** den
   Producer auf die v1-Form zurückdrehen.
2. `vitest run` — der Test **muss fallen**. Die Fehlermeldung notieren (die Zahl/Diff, die das Gate
   selbst emittiert — nicht „lief rot").
3. Zurücktauschen, erneut laufen lassen — grün.

Fällt der Test in Schritt 2 **nicht**, testet er nicht das, was du glaubst (typischer Grund: Producer
und Assertion stammen aus derselben Kopie, oder der Fixture-Satz wurde mitmigriert).

**Gotcha:** Ein reiner Typ-Test ist hier wertlos — `import type` wird wegtranspiliert, der Test
behauptet dann nur seine eigenen Literale und bleibt grün, nachdem das Feld gelöscht wurde. Der
Golden-Test muss zur **Laufzeit** gegen die echten Module laufen.

## Setup-Schritte

1. **Kopien finden.** `grep` die Typ-/Schema-Definition über alle Pakete:
   `rg -n "activePanelId|panelId" --glob '!**/node_modules/**'` (bzw. den Namen deines Contracts).
   Jede Fundstelle außerhalb der Quelle ist eine Kopie.
2. **Fixture-Paket anlegen** (oder ein bestehendes wählen) und
   [`assets/fixtures.example.ts`](./assets/fixtures.example.ts) als Startpunkt hineinkopieren. Es lebt
   ab jetzt an **genau einer** Stelle.
3. **Template ausrollen:** [`assets/contract.golden.example.ts`](./assets/contract.golden.example.ts)
   in **jeden** Konsumenten kopieren, dabei in `src/**/contract.golden.test.ts` **umbenennen** (erst
   dann sammelt es das Test-Glob ein), und die drei Platzhalter-Imports auf die lokalen Module zeigen
   lassen — **den Fixture-Import NICHT umbiegen**.
4. **RED verifizieren** (siehe oben) — einmal pro Konsument, nicht nur im ersten.
5. **Ins Gate hängen:** der Test läuft in `npm test` / `turbo test` jedes Konsumenten mit; keine
   Sonderbehandlung, kein eigener CI-Job.
6. **Review-Zeile befolgen** (`25-orchestration`): *grep the same type/schema definition across
   packages; every copy needs the SAME golden-fixture import.*

## Ehrliche Grenzen

- **Form-Gleichheit ≠ fachliche Richtigkeit.** Der Test zeigt, dass alle Kopien **dieselbe** Form
  sprechen — nicht, dass die Form die richtige ist. Ein gemeinsam falsches Schema bleibt grün.
- **Die N-te Kopie, die den Fixture-Import vergisst, bleibt unsichtbar.** Ein neuer Shim ohne den
  geteilten Fixture-Satz wird von keinem Golden-Test berührt und ist trotzdem grün — dieselbe
  fail-open-Klasse wie ein Lint-Gate ohne Resolver. **Einzige** Abdeckung: die grep-Checklist aus
  Schritt 1/6.
- **Kosten:** N Konsumenten = N Testläufe für dieselbe Zusicherung. Bewusst in Kauf genommen.
- **Serialize und Generate bleiben besser.** Wenn du die Kopie ganz vermeiden (eine Quelle, N
  Konsumenten) oder mechanisch ableiten kannst (Codegen), tu das — und behalte den Golden-Test
  **zusätzlich**.
