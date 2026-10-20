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
- Ein **still eingesetzter Vorgabewert**: der Nutzer wählt A und bekommt B — kein Fehler, kein Log,
  keine gestrippte Eigenschaft. Das ist keines der Symptome darüber, und wer nach Symptom triagiert,
  erreicht dieses Skill sonst gar nicht erst.

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
const parsed = SaveSchema.safeParse(wire);                  // save path validates the WIRE form
expect(parsed.success).toBe(true);                          // it parsed at all …
expect(parsed.data?.activePanelId).toBe('p2');              // … AND the value that was at stake
const keys = [...SLOT_V2_KEYS].sort();                      // the field SET, from the fixture package
expect(Object.keys(wire).sort()).toEqual(keys);             // … the producer SENDS exactly these
expect(Object.keys(parsed.data ?? {}).sort()).toEqual(keys); // … and the save path KEEPS all of them
expect(migrateOnRead(wire)).toEqual(built);                 // read path
// RED-verify: swap in the OLD (v1) migrate → must fail.
```

**Die Zusicherungen in der Mitte sind nicht austauschbar** — `success`, der Wert und die
Schlüsselmenge (was der Producer **sendet** und was der Save-Pfad **behält**) decken verschiedene
Blindstellen ab; der nächste Abschnitt misst sie einzeln aus.

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

Vollständiges, lauffähiges Template: Anhangsblock `contract.golden.test.ts` — wörtlich unten, zum
Abtippen. agent-core liefert dafür **keine Datei** aus (F3 = b); der Konsument legt sie selbst an.

## Worauf die Zusicherung zeigt: Wert, Feldmenge, Grenzwert

Der Round-Trip sagt, **welche Schritte** ein Golden-Test fahren muss — nicht, **worauf** seine
Zusicherungen zeigen. Genau dort liegen drei Blindstellen, und sie sind komplementär: keine der drei
fängt eine der beiden anderen.

| Blindstelle | Was durchrutscht | Die Zusicherung, die sie schließt |
|---|---|---|
| **Wert** | ein Schema führt Alt- **und** Neunamen; der Aufrufer schickt den Alten, die Gegenseite liest den Neuen und setzt still ihren Vorgabewert | `success` **und** der Wert |
| **Feldmenge** | einer Kopie fehlt ein Feld; ein nicht-`strict` Schema strippt es auf **beiden** Seiten des Vergleichs | sortierte Schlüsselmenge dessen, was der Save-Pfad **behält**, gegen eine wörtliche Liste |
| **Grenzwert** | eine Grenze, die auf beiden Seiten ein nacktes Literal ist, trägt nirgends ein Symbol | Attribut gegen die kleinste vom Schema **abgelehnte** Eingabe |

### Der Wert — `success` **und** der Wert, nie der Wert statt `success`

`expect(result.success).toBe(true)` sagt, **dass** geparst wurde, nicht **was**. Zugesichert wird
zusätzlich der Wert, auf den es ankommt — gegen das **installierte** Schema, nicht gegen eine
Nachbildung und nicht gegen eine Fixture.

Belegter Vorfall (Flammenreiter, 2026-08-14): ein Create-Schema führte den Neunamen scharf
(`roomType`, Zwölf-Werte-Enum) **und daneben** den Altnamen frei (`type: z.string().optional()`).
Der Aufrufer schickte den Altnamen, Zod parste anstandslos, der Dienst fiel auf
`roomType ?? 'social'` zurück — der Nutzer wählte A und bekam B, ohne Fehler, ohne Log, ohne
gestrippte Eigenschaft. Nachgemessen mit zod 4.4.3:

```
A: Altname statt Neuname   success: true · data: {"name":"Kammer","type":"npc_dialog"} · roomType: undefined
B: Neuname korrekt         success: true · roomType: npc_dialog
Positivkontrolle           roomType: "gibt_es_nicht"  ->  success: false (Invalid option)
```

- **`success` bleibt stehen, der Wert kommt dazu — nie der Wert STATT `success`.** Gemessen gegen ein
  Schema, das **alles** ablehnt: `expect(parsed.success).toBe(true)` wird rot,
  `expect(parsed.data?.note).toBeUndefined()` bleibt **grün**. Für jedes optionale Feld ist ein
  Totalausfall des Parsens von einem legitim abwesenden Wert nicht zu unterscheiden — die reine
  Wert-Zusicherung ist damit selbst fail-open, also genau die Klasse, die sie schließen soll.
  Nebenkosten einer Ersetzung: der ZodError als Diagnose geht verloren, die Meldung lautet nur noch
  `expected undefined to be 'p2'`.
- **Ein Schema, das Alt- und Neunamen nebeneinander führt, ist eine Falle mit Ansage.** Solange beide
  deklariert sind, ist der Altname keine Toleranz, sondern ein zweiter, stiller Eingang auf den
  Vorgabewert. Entweder er verschwindet, oder `.transform()` bildet ihn auf den Neuen ab. Muss er aus
  Rückwärtskompatibilität bleiben, gehört ein Test daneben, der den **Altnamen** schickt und den
  **erwarteten Neuwert** einfordert.
- **Den Körper gegen den Vertragstyp zu tippen rettet hier nichts.** Mit `tsc --strict` gemessen: ein
  Objektliteral mit dem Altnamen gegen `z.infer<typeof Schema>` erzeugt **keinen** Fehler, weil der
  Altname deklariert **ist**; ein unbekannter Schlüssel fällt daneben mit `TS2353`. Solange der
  Altname im Schema steht, trägt kein Typ-Gate — nur die Wert-Zusicherung an der Drahtgrenze.
- **Ein neuer Aufrufer eines alten Vertrags löst keine Vertragspflicht aus.** Die Pflicht aus
  `30-quality` hängt an der Vertrags*änderung* und prüft den **Vertrag**, nicht seine Aufrufer — im
  belegten Fall war der fehlerhafte Aufrufer knapp drei Monate **älter** als das neue Feld. Prüfsatz
  bei jedem neuen Aufrufer eines bestehenden Endpunkts: *welche Schlüssel gehen wirklich über die
  Leitung, und welche davon liest die Gegenseite?*

### Die Feldmenge — der Round-Trip sieht sie nicht

Der Round-Trip prüft die **Form**, nicht die **Feldmenge**. Ohne `.strict()` strippt Zod einen
unbekannten Schlüssel still — und **unter einer Vorbedingung** auf beiden Seiten des Vergleichs
zugleich: wenn Producer, Save-Schema und Reader aus **derselben** Kopie stammen. Das ist der reale
Konsumentenfall, weil beide Enden vor dem Senden parsen. Kommt der Producer dagegen aus einem
**anderen** Paket und baut das Feld weiter, während das Schema es verloren hat, **fällt** der
Round-Trip. Der Satz gilt also mit Vorbedingung, nicht als Blankett — und ein identischer
Fixture-sha256 belegt, dass die **Fixtures** gleich sind, nie dass die **Schemas** es sind.

Gemessen (zod 4.4.3; eine Kopie ohne das Feld, geteilte Fixture MIT dem Feld):

```
roundTrip(Schema)(fixture) gegen Schema.parse(fixture)        -> PASS   parse ergibt {"id","body"}
build->serialize->validate->read, alle drei DIESELBE Kopie    -> PASS
build->serialize->validate->read, Producer aus anderem Paket  -> FAIL   built {id,body,feld} vs read {id,body}
Object.keys(Schema.shape).sort() gegen WÖRTLICHE Liste        -> FAIL   keys = ["body","id"]
.strict() auf demselben Pfad                                  -> FAIL   unrecognized_keys: ["feld"]
```

- **Die erwartete Schlüsselliste steht wörtlich — und im EINEN Fixture-Paket**, nicht pro Kopie. Eine
  Liste pro Kopie verschiebt die Pflicht nur von N Schemas auf N Listen; die N-te Kopie, die beides
  vergisst, bleibt grün. Die Liste ist **kein zweites Schema**, also darf jeder Konsument sie
  importieren wie den Fixture-Satz — und genau wie ihn **nicht umbiegen** (Setup-Schritt 3). Der
  Anhangsblock `fixtures.ts` führt sie als `SLOT_V2_KEYS` vor.
- **Verglichen wird mit `.sort()` auf beiden Seiten und `toEqual`, nie mit „enthält".** `toContain`
  sieht ein **zusätzliches** Feld nicht, und ein zusätzliches ist derselbe Vertragsbruch. Und **nie**
  gegen `Object.keys(EinAnderesSchema.shape)`: zwei Exporte derselben Quelle verlieren ein Feld
  gemeinsam, der Vergleich bleibt grün — belegt, drei solcher abgeleiteten Zusicherungen standen in
  vier Vertragskopien und waren alle grün.
- **`.shape` gibt es nur am `ZodObject`.** Bei `z.discriminatedUnion`, `z.lazy`, `z.intersection` und
  nach `.optional()` ist es `undefined` (zod 4.4.3); `Object.keys(undefined)` **wirft** dann einen
  TypeError, statt als Zusicherung rot zu werden — fail-closed, aber die Meldung sagt etwas anderes,
  als der Leser erwartet. Erst auspacken, dann festnageln.
- **Ohne `.shape` entscheidet, WO die Schlüssel abgelesen werden — der Draht allein genügt nicht.**
  `Object.keys(wire)` sieht nur, was der **Producer** schickt. Ein Save-Schema, das ein Feld verloren
  hat, strippt es erst beim Parsen, und der Lesepfad sieht `parsed.data` nie. Gemessen (zod 4.4.3,
  die Vorlage unten mit einem echten `z.object` als Save-Schema, dem `panels` fehlt): nur mit der
  Draht-Zusicherung **4 von 4 grün**; mit `Object.keys(parsed.data ?? {})` daneben rot —
  `expected [ 'activePanelId', 'version' ] to deeply equal [ Array(3) ]`. Beide zusammen brauchen kein
  Schema-Innenleben. Was keine der beiden sieht, ist ein **deklarierter, aber nie gesendeter** Name —
  die Alt/Neu-Falle aus „Der Wert": ein Schema mit zusätzlichem `panelId` lässt `parsed.data` bei drei
  Schlüsseln, grün. Den zeigt nur `Object.keys(Schema.shape)`
  (`["activePanelId","panelId","panels","version"]`, rot).
- **`.strict()` ist die Alternative, kein Ersatz.** Es fängt die Kopie, der ein Feld **fehlt**. Ein
  zusätzliches **optionales** Feld läuft durch; ein zusätzliches **Pflicht**feld fällt nur deshalb,
  weil die geteilte Fixture es nicht trägt. Die Zusicherung hängt also daran, dass die Fixture jedes
  Feld wirklich führt — und `.strict()` auf einem Lesepfad, der Legacy-Formen akzeptieren muss, ist
  eine andere Entscheidung als auf dem Save-Pfad.

### Der Grenzwert — was kein Symbol trägt, findet kein Symbol-Grep

Die Review-Zeile aus `25-orchestration` („grep the same type/schema definition across packages")
findet strukturell nur, was einen **Namen** trägt. Eine Grenze, die auf **beiden** Seiten ein nacktes
Literal ist — Zeichengrenzen, Schwellwerte, Zeitfenster, Ereignisnamen —, hat nirgends ein Symbol.
Ein Kommentar, der eine Spiegelung behauptet („Spiegel der Obergrenze aus dem Contract"), ist ein
**Fundzeichen, keine Kopplung**: er steht typischerweise genau dort, wo die Verbindung fehlt.
Belegter Vorfall (Flammenreiter, 2026-08-12/13): vier Zeichengrenzen, im Vertrag an neun Kanten
gezogen, in der Oberfläche als nackte Literale — der Symbol-Abgleich fand null davon, eine
adversarielle Gegenprüfung alle vier.

- **Nach WERT greppen, nicht nach Syntax — und die Reichweite mitschreiben.** Nimm die auffälligen
  Zahlen und Zeichenketten aus der **geteilten Quelle** und suche sie im Konsumenten
  (`rg -n --glob '!**/node_modules/**' -e '\b2000\b' -e '\b200\b'`). Ein Grep über die
  **Schreibweise** von Grenzen (`maxLength={…}`, `.max(…)`) ist stack-spezifisch: in einem Kotlin-,
  Python- oder Swift-Konsumenten trifft er null und **liest sich als sauber**. Null Treffer ist hier
  RED, nicht grün — `30-quality` misst die Reichweite als „wie viele an ihrer EIGENEN Zusicherung
  scheitern können, nicht wie viele angesehen wurden (0 ist ROT; …)".
- **Die Zusicherung bindet an die WIRKUNG des Schemas, nie an dieselbe Konstante.** Gegen dieselbe
  Konstante zu prüfen ist Selbstbezug — dieselbe Krankheit wie die Positions-Adressierung im
  Abschnitt „Zellen über Schlüssel adressieren" weiter unten. Suche binär — ausgehend von einer
  Länge, die das Feld **annimmt** — die kleinste längere Eingabe, die es **ablehnt**, und fordere
  `expect(uiLimit).toBe(firstRejectedLength(schemaField) - 1)`. Der angenommene Startpunkt ist
  tragend: bei `z.string().min(1).max(2000)` ist die kleinste abgelehnte Eingabe überhaupt die leere
  (gemessen: naiv 0, also `uiLimit` −1; ab Länge 1 gesucht 2001, also 2000). RED-verifiziert im
  Konsumenten: die Oberflächen-Grenze auf 2500 gesetzt → `AssertionError: expected 2500 to be 2000`;
  zurückgenommen, 63/63 grün.

## EIN Fixture-Satz, N Konsumenten

Das **Serialize-Prinzip**, auf den Test angewandt: Der Fixture-Satz lebt in **genau einem** Paket und
wird von **jedem** Konsumenten **importiert**.

```
packages/contract-fixtures/src/fixtures.ts   ← der EINE Satz (Anhangsblock fixtures.ts)
   ↑            ↑              ↑
apps/api    apps/web-gm    apps/web-player   ← jeder importiert, keiner kopiert
```

- **Nie** kopieren, **nie** pro Paket „leicht anpassen". Eine kopierte Fixture driftet mit der Kopie
  mit — dann bestätigt der Test nur noch die lokale Wahrheit und ist wertlos.
- Der **Test** läuft dagegen in **jedem** Konsumenten-Gate (N-mal). Ein einzelner zentraler Lauf würde
  genau die lokale Kopie nicht sehen — das ist der Sinn der Übung, nicht ein Versehen.
- Der Fixture-Satz deckt **je eine** Fixture pro relevanter Contract-Variante ab (v1-Legacy, v2,
  Randfälle wie leere Collections und optionale Felder) — siehe Anhangsblock `fixtures.ts`.

## Zellen über Schlüssel adressieren, nie über Positionen

Eine Fixture-Zelle wird über einen **stabilen Namen** verglichen, nie über ihren Index. Stammt die
**Reihenfolge** der Erwartung aus derselben Quelle wie die Reihenfolge der Ist-Werte, prüft der Test
nur noch, dass die Quelle mit sich selbst übereinstimmt — und das ist immer wahr.

```ts
// blind: ROLE_NAMES ist selbst nach Sprosse sortiert, ein Tausch permutiert BEIDE Seiten gleich
for (let rung = 0; rung < ROLE_NAMES.length; rung += 1)
  expect(derive(ROLE_NAMES[rung])).toBe(goldenRow[rung]);

// dicht: der Schlüssel steht als Literal im Test, die Reihenfolge trägt nichts mehr
expect(derive('designer')).toBe(GOLDEN['designer']);
expect(ROLE_RUNGS).toEqual({ project: 0, /* … */ designer: 5, content: 6, qa: 8 });
```

Belegter Vorfall (agent-core, 2026-08-03): ein Golden-Test verglich 99 veröffentlichte Werte Zelle
für Zelle und adressierte die Spalten über `ROLE_NAMES[rung]` gegen `row[rung]` — `ROLE_NAMES` wird
selbst **nach Sprosse sortiert** abgeleitet. Zwei Sprossen getauscht (`designer: 6, content: 5`)
änderte jede veröffentlichte Farbe zweier Rollen, und **22 von 22 Tests blieben grün**:
Eindeutigkeit, Lückenlosigkeit, Wertebereich, Kontrast über 99 Kombinationen und 99 nachgerechnete
Zellen — keine dieser Zusicherungen war an einen **Namen** gebunden. Die zweite Achse derselben
Tabelle war nie betroffen, weil sie namentlich adressiert wurde; genau diese Asymmetrie war die
Lücke. Nachgestellt mit zwei Läufen desselben Programms, einmal mit getauschten Einträgen:

```
positional: 2 cells compared · 0 deviation(s) · SWAP=false → pass 2 · fail 0
keyed:      2 cells compared · 0 deviation(s) · SWAP=false

positional: 2 cells compared · 0 deviation(s) · SWAP=true  → pass 1 · fail 1
keyed:      2 cells compared · 2 deviation(s) · SWAP=true
```

- **Die Erwartung ist eine Map mit Schlüsseln**, kein Array „in derselben Reihenfolge wie …".
- **Braucht die Serialisierung wirklich Positionen** (Wire-Arrays, CSV-Zeilen), dann nagle die
  Reihenfolgen-Quelle **zusätzlich namentlich** fest — `expect(ORDER_TABLE).toEqual({ … })`. Dann
  trägt der Test den Schlüssel, und die Ordnung bleibt eine abgeleitete Größe.
- **Nicht auf Farben beschränkt:** Spaltenlisten gegen CSV-Zeilen, Enum-Reihenfolge gegen
  serialisierte Arrays, Slot-Nummern gegen Positionen einer Fixture-Zeile — jede geordnete Tabelle,
  deren Reihenfolge aus derselben Quelle stammt wie die Erwartung, trägt diese Blindstelle.

Kandidaten im eigenen Repo aufzählen (eine **Liste**, kein Gate — sie findet die Schreibweise, nicht
die Blindheit):

```bash
rg -n --glob '**/*.{test,spec}.{ts,tsx,js,mjs,cjs}' --glob '!**/node_modules/**' \
   '(toBe|toEqual|toStrictEqual)\(\s*[A-Za-z_$][\w$.]*\[\s*[a-z]{1,5}\s*\]'
# agent-core am 2026-08-05: 1 Treffer — src/colorRegistry.test.ts:393
```

## RED-Verify ist Pflicht

Ein Golden-Test, der nie gegen die **kaputte** Implementierung lief, ist unbewiesen
(`30-quality`: „Regression tests — verified RED, not assumed"). **Eine** Mutation genügt nicht: jede
Klasse unten trifft eine Blindstelle, die keine andere sieht. Eine Wertänderung deckt die
Permutationsklasse oben nicht ab — die RED-Verifikation kann lehrbuchmäßig durchgeführt sein und der
Test trotzdem gegen jede Vertauschung blind bleiben. Gemutiert wird immer der **ausgelieferte Pfad**
(Producer, Schema bzw. Shim, Lesepfad und ihr produktiver Aufrufer) — nie die Fixture, nie eine
Hilfsfunktion, die nur der Test ruft.

1. **Wertmutation:** die **alte** (v1-)Variante einsetzen — `migrateOnRead` durch die v1-Migration
   ersetzen **oder** den Producer auf die v1-Form zurückdrehen.
2. **Vertauschungsmutation:** zwei Einträge der geordneten Tabelle **tauschen** (zwei Enum-Glieder,
   zwei Spalten, zwei Slots) und sonst nichts ändern.
3. **Feldmengen- und Namensmutation:** ein Feld im **Schema bzw. Shim** löschen — nie in der Fixture,
   eine Fixture-Mutation provoziert die falsche Divergenz und prüft wieder nur die Fixture — **und**
   im **Producer** einen Feldnamen gegen einen zweiten, ebenfalls deklarierten Namen tauschen.
   Belegte Zahlen aus dem Konsumenten: Feld aus der Shape entfernt → `5 failed | 60 passed` in der
   Quelle bzw. `4 failed | 75 passed` im Shim (dort war ein anderes Schema mutiert), zurückgerollt
   `65 passed` / `79 passed`.
4. **Aufrufformmutation:** die Mutation an der **produktiven Aufrufstelle** einbauen — dort, wo die
   Produktion Producer, Save-Pfad oder Lesepfad wirklich ruft —, nicht in der Funktion, die der Test
   direkt aufruft. Vorher die echte Aufrufstelle lesen: Argumentgestalt, Zahl der Aufrufe, welche
   Optionalparameter dort wirklich gesetzt sind. Belegter Vorfall (Konsument, 2026-08-12): der Test
   rief eine Verteilfunktion mit **fünf** Würfelnden in **einem** Array, die Produktion übergab ein
   **einelementiges** Array und rief N-mal — der Test wurde auf Kommando rot, ausgeliefert wurde das
   Dreifache der beabsichtigten Wirkung. Ein Optionalparameter, den nur der Test setzt, ist
   ungetestet. Dieselbe Klasse im eigenen Repo (agent-core, 2026-07-23; Herkunft ADR-0027): ein
   Verhaltenstest fiel nur unter `-t`-Filter, im vollen Lauf bestand er auch gegen die kaputte
   Implementierung — ein RED-Beleg aus einer anderen Aufrufform als der, in der das Gate wirklich
   läuft, belegt nichts.
5. `vitest run` — der Test **muss** in **allen** Fällen fallen, und zwar im **vollen** Lauf, nicht
   unter `-t`. Die Fehlermeldung notieren (die Zahl/Diff, die das Gate selbst emittiert — nicht
   „lief rot").
6. Zurücktauschen, erneut laufen lassen — grün.

Fällt der Test bei der **Wert**mutation nicht, testet er nicht das, was du glaubst (typischer Grund:
Producer und Assertion stammen aus derselben Kopie, oder der Fixture-Satz wurde mitmigriert). Fällt
er bei der **Vertauschung** nicht, adressiert er seine Zellen über Positionen — siehe den Abschnitt
darüber. Fällt er bei der **Feldmengen- und Namens**mutation nicht, zeigt die Zusicherung auf
`success` statt auf Wert und Schlüsselmenge — oder die Schlüsselmenge wird nur am Draht abgelesen
statt an dem, was der Save-Pfad behält, oder die erwartete Liste ist aus einem zweiten Export
derselben Quelle abgeleitet und verliert das Feld mit. Fällt er bei der **Aufrufform**mutation nicht,
ruft er eine Form, die die Produktion nie erzeugt: dann ist er eine Absichtsbeschreibung, kein
Regressionsnachweis — und wird auch so benannt.

**Gotcha:** Ein reiner Typ-Test ist hier wertlos — `import type` wird wegtranspiliert, der Test
behauptet dann nur seine eigenen Literale und bleibt grün, nachdem das Feld gelöscht wurde. Der
Golden-Test muss zur **Laufzeit** gegen die echten Module laufen.

## Setup-Schritte

1. **Kopien finden — zwei Durchgänge, nicht einer.** Erst `grep` die Typ-/Schema-Definition über alle
   Pakete: `rg -n "activePanelId|panelId" --glob '!**/node_modules/**'` (bzw. den Namen deines
   Contracts). Jede Fundstelle außerhalb der Quelle ist eine Kopie.
   **Zweiter Durchgang, nach WERT statt nach Namen.** Der Symbol-Abgleich findet nur, was einen Namen
   trägt; eine Grenze, die auf beiden Seiten ein nacktes Literal ist, hat nirgends ein Symbol. Nimm
   die auffälligen **Zahlen und Zeichenketten aus der geteilten Quelle** und suche sie im
   Konsumenten — nicht die Schreibweise von Grenzen, die ist stack-spezifisch und trifft in einem
   fremden Stack null. **Notiere die Trefferzahl beider Durchgänge:** null Treffer ist hier RED, nicht
   sauber (Abschnitt „Der Grenzwert").
2. **Fixture-Paket anlegen** (oder ein bestehendes wählen) und den Anhangsblock `fixtures.ts` als
   Startpunkt hineinschreiben. Er lebt ab jetzt an **genau einer** Stelle.
3. **Template ausrollen:** den Anhangsblock `contract.golden.test.ts`
   in **jeden** Konsumenten schreiben — unter genau diesem Namen (`src/**/contract.golden.test.ts`,
   erst dann sammelt es das Test-Glob ein) — und die drei Platzhalter-Imports auf die lokalen Module
   zeigen lassen — **den Fixture-Import NICHT umbiegen** —, dann STAND-IN und RED-verify-Kanarienvogel
   löschen (Anhang, „Anzupassen").
4. **RED verifizieren** (siehe oben) — einmal pro Konsument, nicht nur im ersten.
5. **Ins Gate hängen:** der Test läuft in `npm test` / `turbo test` jedes Konsumenten mit; keine
   Sonderbehandlung, kein eigener CI-Job.
6. **Review-Zeile befolgen** (`25-orchestration`): *grep the same type/schema definition across
   packages; every copy needs the SAME golden-fixture import.* — und denselben Abgleich ein zweites
   Mal **nach Wert** fahren (Schritt 1), sonst deckt er nur die benannte Hälfte des Contracts ab.

## Ehrliche Grenzen

- **Form-Gleichheit ≠ fachliche Richtigkeit.** Der Test zeigt, dass alle Kopien **dieselbe** Form
  sprechen — nicht, dass die Form die richtige ist. Ein gemeinsam falsches Schema bleibt grün.
- **Die N-te Kopie, die den Fixture-Import vergisst, bleibt unsichtbar.** Ein neuer Shim ohne den
  geteilten Fixture-Satz wird von keinem Golden-Test berührt und ist trotzdem grün — dieselbe
  fail-open-Klasse wie ein Lint-Gate ohne Resolver. **Einzige** Abdeckung: die grep-Checklist aus
  Schritt 1/6. Dasselbe gilt für die Schlüsselliste: eine Kopie, die weder das Feld noch die Liste
  führt, ist in sich konsistent und bleibt grün — deshalb liegt die Liste im Fixture-Paket und nicht
  neben dem Schema, und deshalb bleibt der Wert-Grep aus Schritt 1 Pflicht.
- **Zwei Zahlen, die heute gleich sind, sind nicht dieselbe Grenze.** Zusammenlegen koppelt sie für
  immer, und nichts wird rot, wenn sie einmal auseinanderlaufen **sollen**. Und die Nacharbeit teilt
  sich: fehlt der Wert in der geteilten Quelle ganz, braucht die Behebung dort erst eine Konstante
  und damit einen Publish — das ist kein Nachzug im Konsumenten und passt nicht nebenbei in eine
  laufende Welle.
- **Kosten:** N Konsumenten = N Testläufe für dieselbe Zusicherung. Bewusst in Kauf genommen.
- **Serialize und Generate bleiben besser.** Wenn du die Kopie ganz vermeiden (eine Quelle, N
  Konsumenten) oder mechanisch ableiten kannst (Codegen), tu das — und behalte den Golden-Test
  **zusätzlich**.

## Anhang — die Dateien, wörtlich

Jeder Block steht **vollständig** hier, keiner gekürzt. agent-core liefert sie **nicht als Datei**
aus (F3 = b) — der Konsument legt sie selbst an. Jeder Block steht zwischen zwei HTML-Markern, damit
ein Test ihn maschinell herausschneiden kann.

> **Die Namensfalle, die dadurch verschwindet — und die niemand zurückbauen soll.** Solange die
> Vorlagen **Dateien** waren, mussten sie `*.example.ts` heißen: Vitests Default-`include`
> (`**/*.{test,spec}.?(c|m)[jt]s?(x)`) hätte sie im **Zielprojekt** eingesammelt, und der
> Default-`exclude` deckt `.claude/**` nicht ab — der Adoptierende hätte einen still grünen Test für
> einen Contract bekommen, den sein Code gar nicht hat. Als Prosa kann das nicht mehr passieren, ein
> Block liegt in keinem Glob. **Wer je wieder eine Vorlagen-Datei ausliefert, erbt die Falle sofort
> zurück** — dann heißt sie wieder `*.example.ts` plus Umbenennungsanweisung.

Der englische Spiegel wiederholt die Blöcke **nicht**: eine zweite Kopie derselben Contract-Form im
selben Repo ist genau der Defekt, gegen den dieses Skill geschrieben ist.

### `contract.golden.test.ts` → `src/**/contract.golden.test.ts` in JEDEM Konsumenten

Anzupassen: die drei Imports im Block `REAL IMPORTS` auf die eigenen Module zeigen lassen, dann den
Block zwischen `STAND-IN START` und `STAND-IN END` **löschen** — und den RED-verify-Kanarienvogel am
Ende mit, es sei denn, du importierst deinen eigenen alten Lesepfad unter dem Namen
`migrateOnReadV1`. Stehen gelassen, scheitert die übernommene Datei an genau diesem Namen
(nachgestellt: `TS2552: Cannot find name 'migrateOnReadV1'`, im Lauf `ReferenceError`,
`1 failed | 3 passed`). Den Fixture-Import **nicht** umbiegen.

<!-- BEGIN file contract.golden.test.ts -->

```ts
/**
 * Golden test template — ONE shared fixture set, run in EVERY consumer's gate.
 *
 * agent-core ships this as PROSE, never as a file (F3 = b): write it into the consumer yourself, at
 * `src/**\/contract.golden.test.ts`. While it was a shipped file it had to be called `*.example.ts`,
 * because a consumer's default test glob would otherwise have collected it out of
 * `.claude/skills/…/assets/` and run a green test for a contract that repo does not have.
 *
 * It exercises the only path that catches shim drift:
 *
 *     build → serialize → validate → read
 *
 * The order is load-bearing: the save schema validates the **serialized wire form**, not the
 * in-memory object. Validating before `JSON.stringify` is what let the shipped bug through — the
 * API never sees the object, it sees the payload, and `Date` / `undefined` / `Map` / class
 * instances differ between the two.
 *
 * A renderer/unit test does NOT catch shim drift: producer and assertion come from the SAME local
 * copy, so the test is internally consistent and stays green while the copies diverge from each
 * other. Only the round-trip crosses a real package boundary.
 *
 * Canonical pattern + rationale: `skill:contract-golden-test` (SKILL.md).
 * Rule: `25-orchestration` ("Consolidate shared semantics"). Decision: ADR-0021.
 *
 * HOW TO ADOPT:
 *   1. Create it as `contract.golden.test.ts` in the consumer (`src/**\/contract.golden.test.ts`).
 *   2. Uncomment the REAL IMPORTS block and point it at your modules.
 *      Do NOT re-point the fixture import at a local copy — the fixture set lives in exactly ONE
 *      package and every consumer imports THAT one (see the `fixtures.ts` block).
 *   3. Delete everything between the STAND-IN markers — and the RED-verify canary at the very end,
 *      unless you import your own OLD read path as `migrateOnReadV1`: the canary pins the stand-in's
 *      one, and left alone the adopted file fails with "Cannot find name 'migrateOnReadV1'".
 *
 * Then RED-verify (mandatory, per `30-quality` "verified RED, not assumed"): swap the OLD (v1)
 * migrate/producer back in, run `vitest run`, watch this file FAIL, note the emitted diff, swap back.
 * One mutation is never enough — the skill's "RED-Verify ist Pflicht" section lists every class.
 */
import { describe, expect, it } from 'vitest';

// ─────────────────────────────────────────────────────────────────────────────────────────────────
// 1. REAL IMPORTS — uncomment and re-point at your own modules.
// ─────────────────────────────────────────────────────────────────────────────────────────────────
// import { editorBuild } from '@repo/editor';                              // the producer
// import { SaveSchema, migrateOnRead } from '@repo/shared-contract';       // save path + read path
// import { tabGroupLayout, legacyV1Slot, SLOT_V2_KEYS } from '@repo/contract-fixtures'; // fixtures + key set

// ─────────────────────────────────────────────────────────────────────────────────────────────────
// 2. STAND-IN START — delete this whole block once (2) is wired.
//    It exists only so the template runs green out of the box and shows the exact shapes the four
//    round-trip steps expect. It is a v2 "slot" contract: `panels[]` + `activePanelId` (the v1 form
//    it replaced carried a single `panelId`).
// ─────────────────────────────────────────────────────────────────────────────────────────────────

/** One panel inside a slot. Replace with your contract's own child node type. */
export interface Panel {
  readonly id: string;
  readonly kind: string;
}

/** v2 wire form: an ordered `panels[]` plus the focused `activePanelId`. */
export interface SlotV2 {
  readonly version: 2;
  readonly panels: readonly Panel[];
  readonly activePanelId: string | null;
}

/** v1 wire form — kept ONLY so the RED-verify canary below has something old to swap in. */
export interface SlotV1 {
  readonly version: 1;
  readonly panelId: string | null;
}

/** What the producer consumes. Replace with your editor's/builder's own input type. */
export interface LayoutInput {
  readonly panels: readonly Panel[];
  readonly focused: string | null;
}

/** Zod-compatible result shape, so a real `z.ZodType` drops in unchanged. */
export interface SafeParseResult<T> {
  readonly success: boolean;
  readonly data?: T;
}

/** Minimal `safeParse` surface — a real Zod schema satisfies this structurally. */
export interface Validator<T> {
  safeParse(value: unknown): SafeParseResult<T>;
}

/**
 * Producer stand-in: builds the v2 form from a layout input.
 * Replace with your editor/builder entry point.
 *
 * @param input - the layout the editor is holding
 * @returns the v2 slot the editor would hand to the save path
 */
export function editorBuild(input: LayoutInput): SlotV2 {
  return { version: 2, panels: [...input.panels], activePanelId: input.focused };
}

/**
 * Save-path stand-in: the schema the API validates the WIRE payload against. Replace with your real
 * `SaveSchema` (a Zod schema satisfies `Validator<T>` as-is).
 */
export const SaveSchema: Validator<SlotV2> = {
  safeParse(value: unknown): SafeParseResult<SlotV2> {
    if (typeof value !== 'object' || value === null) return { success: false };
    const v = value as Record<string, unknown>;
    const ok =
      v.version === 2 &&
      Array.isArray(v.panels) &&
      v.panels.every((p) => typeof p === 'object' && p !== null && typeof (p as Panel).id === 'string') &&
      (typeof v.activePanelId === 'string' || v.activePanelId === null);
    return ok ? { success: true, data: v as unknown as SlotV2 } : { success: false };
  },
};

/**
 * Read-path stand-in: normalizes any accepted wire form (v1 or v2) to the CURRENT form.
 * Replace with your real `migrateOnRead`.
 *
 * @param wire - the JSON-decoded payload as it arrives from the API
 * @returns the current (v2) form
 */
export function migrateOnRead(wire: unknown): SlotV2 {
  const v = wire as Partial<SlotV2> & Partial<SlotV1>;
  if (v.version === 2) {
    return { version: 2, panels: [...(v.panels ?? [])], activePanelId: v.activePanelId ?? null };
  }
  const id = v.panelId ?? null;
  return { version: 2, panels: id ? [{ id, kind: 'unknown' }] : [], activePanelId: id };
}

/**
 * The OLD (v1) read path — the exact drift that shipped: it only understands `panelId`, so every v2
 * payload degrades to an empty slot SILENTLY (no throw, no log). Used by the canary below.
 *
 * @param wire - the JSON-decoded payload as it arrives from the API
 * @returns the v1 form the stale shim produced
 */
export function migrateOnReadV1(wire: unknown): SlotV1 {
  const v = wire as Partial<SlotV1>;
  return { version: 1, panelId: v.panelId ?? null };
}

/** The ONE shared fixture set — in a real adoption this comes from the fixture package. */
const tabGroupLayout: LayoutInput = {
  panels: [
    { id: 'p1', kind: 'map' },
    { id: 'p2', kind: 'sheet' },
  ],
  focused: 'p2',
};

/** Legacy payload still sitting in the database — the read path must lift it to the current form. */
const legacyV1Slot: SlotV1 = { version: 1, panelId: 'p1' };

/**
 * The field SET of the v2 wire form — written out LITERALLY and sorted. In a real adoption it comes
 * from the fixture package next to the fixtures (one copy, imported by every consumer), NEVER from a
 * second schema: `Object.keys(SomeOtherSchema.shape)` compares two exports of the same source, which
 * lose a field together, so that comparison stays green while the contract breaks.
 */
const SLOT_V2_KEYS: readonly string[] = ['activePanelId', 'panels', 'version'];

// ─────────────────────────────────────────────────────────────────────────────────────────────────
// STAND-IN END
// ─────────────────────────────────────────────────────────────────────────────────────────────────

describe('contract golden test — slot form', () => {
  it('round-trips build → serialize → validate → read', () => {
    const built = editorBuild(tabGroupLayout); // producer
    const wire: unknown = JSON.parse(JSON.stringify(built)); // api boundary (serialize)
    const parsed = SaveSchema.safeParse(wire); // save path validates the WIRE form
    // BOTH lines, never only the second one: against a schema that rejects EVERYTHING,
    // `expect(parsed.data?.someOptional).toBeUndefined()` stays GREEN — a total parse failure reads
    // exactly like a legitimately absent optional value. And never only the first one: `success:
    // true` is satisfied by a schema that also declares the OLD field name, while the new one stays
    // `undefined` and the server quietly falls back to its default.
    expect(parsed.success).toBe(true);
    expect(parsed.data?.activePanelId).toBe('p2');
    expect(migrateOnRead(wire)).toEqual(built); // read path
    // RED-verify: swap in the OLD (v1) migrate → must fail.
  });

  it('lifts the legacy payload to the SAME form the producer builds', () => {
    // Without this case a consumer can keep reading v1 forever and still look green: the
    // round-trip above only ever shows it payloads its own producer just made.
    const legacyWire: unknown = JSON.parse(JSON.stringify(legacyV1Slot));
    const migrated = migrateOnRead(legacyWire);
    // Serialize again before validating: what gets saved back is the payload, not the object.
    expect(SaveSchema.safeParse(JSON.parse(JSON.stringify(migrated))).success).toBe(true);
    expect(migrated.version).toBe(2);
    expect(migrated.activePanelId).toBe('p1'); // the VALUE the legacy payload carried, not just "it parsed"
  });

  it('pins the field SET the producer sends AND the save path keeps', () => {
    // KEY SET: the round-trip above is blind to a MISSING field. Without `.strict()` a schema strips
    // an unknown key, and when producer, save schema and reader are the SAME copy, both sides of the
    // comparison lose it together and stay green. Compare with `.sort()` on BOTH sides and
    // `toEqual`, never `toContain`: "contains" cannot see an EXTRA field, and an extra field is the
    // same breach. The expected list is a LITERAL from the fixture package, never derived from a
    // second schema.
    // Read the keys on BOTH sides of the save path: the wire only shows what the producer SENDS; a
    // save schema that lost a field strips it while parsing, and the read path never sees
    // `parsed.data`. Measured with a real `z.object` missing `panels`: wire-only stays 4/4 green.
    const expected = [...SLOT_V2_KEYS].sort();
    const wire = JSON.parse(JSON.stringify(editorBuild(tabGroupLayout))) as Record<string, unknown>;
    const parsed = SaveSchema.safeParse(wire);
    expect(Object.keys(wire).sort()).toEqual(expected); // what the producer SENDS
    expect(parsed.success).toBe(true);
    expect(Object.keys(parsed.data ?? {}).sort()).toEqual(expected); // what the save path KEEPS
  });

  // ── RED-verify canary ──────────────────────────────────────────────────────────────────────────
  // Mutates the GATE, not the fixture (`30-quality`): it pins that the OLD read path really does
  // fail the assertion above, so `toEqual` is load-bearing and not vacuously true.
  // It does NOT replace the manual swap in your own consumer — your old implementation differs from
  // this stand-in. Do the swap once per consumer and watch the real test fall. Delete this canary
  // together with the STAND-IN unless you import your own old read path as `migrateOnReadV1`.
  it('RED-verify: the OLD (v1) read path must NOT satisfy the round-trip', () => {
    const built = editorBuild(tabGroupLayout);
    const wire: unknown = JSON.parse(JSON.stringify(built));
    expect(migrateOnReadV1(wire)).not.toEqual(built);
  });
});
```

<!-- END file contract.golden.test.ts -->

### `fixtures.ts` → `packages/contract-fixtures/src/fixtures.ts`, genau EINMAL

Anzupassen: die Typen und Fixtures durch den eigenen Contract ersetzen. Die Deckungsregel bleibt: je
eine Fixture pro Variante, die es wirklich gibt — aktuelle Form, jede noch lesbare Legacy-Form, die
entarteten Randfälle.

<!-- BEGIN file fixtures.ts -->

```ts
/**
 * The ONE shared fixture set — example.
 *
 * THIS FILE LIVES IN EXACTLY ONE PACKAGE (e.g. `packages/contract-fixtures/src/fixtures.ts`) AND IS
 * IMPORTED BY EVERY CONSUMER. Never copy it into a consumer, never "adjust it slightly" per package:
 * a copied fixture drifts along with the copy it lives next to, and the golden test then only
 * confirms the local truth — exactly the failure it exists to catch.
 *
 *     packages/contract-fixtures/src/fixtures.ts   ← the ONE set (this file)
 *        ↑              ↑                 ↑
 *     apps/api     apps/web-gm      apps/web-player   ← each IMPORTS, none copies
 *
 * The test itself does run N times (once per consumer's gate) — that is the point: a single central
 * run would never see the local copy. Rule: `25-orchestration`. Decision: ADR-0021.
 *
 * Coverage rule of thumb — one fixture per contract variant that actually exists in the wild:
 *   - the CURRENT form (the one the producer builds today),
 *   - every LEGACY form still readable from storage,
 *   - the degenerate edge cases (empty collection, all-optional-fields-absent).
 * Anything the read path must accept needs a fixture, or drift hides in the untested variant.
 */

/** One panel inside a slot. */
export interface Panel {
  readonly id: string;
  readonly kind: string;
}

/** v2 wire form: an ordered `panels[]` plus the focused `activePanelId`. */
export interface SlotV2 {
  readonly version: 2;
  readonly panels: readonly Panel[];
  readonly activePanelId: string | null;
}

/** v1 wire form — still present in storage, so the read path must keep lifting it. */
export interface SlotV1 {
  readonly version: 1;
  readonly panelId: string | null;
}

/** What the producer (editor/builder) consumes. */
export interface LayoutInput {
  readonly panels: readonly Panel[];
  readonly focused: string | null;
}

// ── producer inputs ──────────────────────────────────────────────────────────────────────────────

/** The everyday case: a multi-panel tab group with a focused panel. */
export const tabGroupLayout: LayoutInput = {
  panels: [
    { id: 'p1', kind: 'map' },
    { id: 'p2', kind: 'sheet' },
  ],
  focused: 'p2',
};

/** Degenerate case: no panels at all — catches shims that assume `panels[0]` exists. */
export const emptyLayout: LayoutInput = { panels: [], focused: null };

// ── wire payloads (what the read path receives) ──────────────────────────────────────────────────

/** Current form, as the API returns it. */
export const currentSlot: SlotV2 = {
  version: 2,
  panels: [
    { id: 'p1', kind: 'map' },
    { id: 'p2', kind: 'sheet' },
  ],
  activePanelId: 'p2',
};

/** Legacy form still sitting in storage — must be lifted, never skipped. */
export const legacyV1Slot: SlotV1 = { version: 1, panelId: 'p1' };

/** Legacy form with nothing selected — the `null` branch of the migration. */
export const legacyV1EmptySlot: SlotV1 = { version: 1, panelId: null };

// ── the field SET (belongs here, for the same reason the fixtures do) ────────────────────────────

/**
 * Every key the CURRENT wire form must carry, written out LITERALLY and sorted.
 *
 * WHY IT LIVES HERE AND NOT NEXT TO A SCHEMA
 *   A round-trip test checks the SHAPE, not the FIELD SET: without `.strict()` a schema strips an
 *   unknown key, and when producer, save schema and reader are the same copy, both sides of the
 *   comparison lose a field together and stay green. A list kept per consumer only moves the duty
 *   from N schemas to N lists — the Nth copy that forgets both is still invisible. One list, in the
 *   one package every consumer already imports, is the same serialize principle as the fixtures.
 *
 * HOW TO COMPARE
 *   On BOTH sides of the save path, each against `[...SLOT_V2_KEYS].sort()` with `toEqual`:
 *   `Object.keys(wire).sort()` (what the producer SENDS) AND `Object.keys(parsed.data ?? {}).sort()`
 *   (what the save schema KEEPS — a schema that lost a field strips it only there). `.sort()` on
 *   BOTH sides, never `toContain`: "contains" cannot see an EXTRA field, and an extra field is the
 *   same breach of contract. With Zod, `Object.keys(Schema.shape).sort()` additionally sees a name
 *   that is declared but never sent — but only on a `ZodObject`: on `z.discriminatedUnion`,
 *   `z.lazy`, `z.intersection` and after `.optional()` `.shape` is `undefined` and
 *   `Object.keys(undefined)` THROWS instead of failing as an assertion.
 *
 * WHAT NEVER WORKS
 *   Deriving the expectation from a second schema (`Object.keys(OtherSchema.shape)`). Two exports of
 *   the same source lose a field together, so the comparison is green while the contract is broken.
 *
 * Extend this list in the SAME commit that adds a field to the contract, or the new field is
 * optional in practice no matter what the schema says.
 */
export const SLOT_V2_KEYS: readonly string[] = ['activePanelId', 'panels', 'version'];

/**
 * Every wire payload the read path must accept, for table-driven golden tests.
 * Extend this list when a new variant becomes readable — a variant that is not in here is a variant
 * no consumer's gate covers.
 */
export const allReadableSlots: ReadonlyArray<SlotV1 | SlotV2> = [currentSlot, legacyV1Slot, legacyV1EmptySlot];
```

<!-- END file fixtures.ts -->
