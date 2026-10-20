---
name: acceptance-doc
description: 'Ein Abnahme-, Prüf- oder Entscheidungsdokument so schreiben, dass es seine Herkunft trägt und die Antworten wirklich behält: Herkunftskopf mit Repos und SHA, „nicht ausgeliefert" markieren statt streichen, und — wenn es zum Anklicken geliefert wird — ein Artefakt, das seinen Antwortstand selbst veröffentlicht. Nutze, wenn eine Abnahmeliste, ein Testplan, Akzeptanzkriterien, ein Fragenkatalog oder eine Migrations-Checkliste entsteht oder an einen Agenten vergeben wird, und wenn ein Antwortstand aus einem Artefakt zurückgelesen werden soll.'
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Abnahme- und Entscheidungsdokumente

**Ein Prüfdokument, das ohne Code-Zugriff entsteht, ist die Prüfliste für einen Entwurf — nicht für das Produkt.** Belegt: eine DAU-Abnahmeliste über 73 Schritte wurde im Workspace-Repo geschrieben, während die sieben Sibling-Repos nicht vorlagen; keine Zeile Produktionscode gelesen, keine Oberfläche geöffnet. Beim Nachmessen am ausgelieferten Code mussten **33 der 73 Schritte** umgeschrieben werden (45 %). Die Liste sah vollständig aus. Das ist der Normalfall, nicht der Ausrutscher: ein Prüfmittel sieht seiner Form nicht an, gegen welchen Stand es geschrieben wurde.

Dieselbe Krankheit trifft die interaktive Form ein Stockwerk tiefer: ein Fragenkatalog als Artefakt sah vollständig aus, trug 148 Radios und 46 Freitextfelder — und **0** gesetzte Kreuze im veröffentlichten Stand, weil die Seite nie `publish()` rief. Der Antwortstand hatte den Browser nie verlassen.

## Wann dieses Skill gilt

- Ein **Prüfmittel** entsteht: Abnahmeliste, Testplan, Akzeptanzkriterien, Migrations-Checkliste, Fragenkatalog.
- Es wird **an einen Agenten vergeben** oder in einem **anderen Repo** geschrieben als dem, das es prüft.
- Ein Mensch soll **ab etwa fünf Entscheidungen** beantworten — dann lohnt die anklickbare Form; darunter reichen Fragen im Chat.

Trifft nichts davon zu, lass die Zeremonie weg.

## Der Herkunftskopf — der Auftrag nennt die Repos und den Stand

Schon der **Delegationsauftrag** zählt die Repos auf, gegen die geschrieben wird, plus den SHA je Repo. Liegt eines nicht vor, schreibt der Agent das in den Kopf, statt aus Entwurfsunterlagen zu improvisieren.

Der Kopf des Dokuments trägt, in dieser Reihenfolge:

- **Woraus die Liste entstand** — die gelesenen Quellen, namentlich. „Ausschließlich die Entwurfsunterlagen, nicht der Code" ist eine zulässige Antwort; sie zu verschweigen ist es nicht.
- **Gegen welchen Stand** — `<repo>@<sha>` je Repo, und die **nicht gelesenen** Repos ebenfalls namentlich. Ein Repo, das nicht vorlag, ist ein Befund, keine Fußnote.
- **Die eigene Reichweite als Zahl** — wie viele Schritte, wie viele als „nicht abnehmbar" markierte Flächen. Das Dokument spricht sie aus; sie wird nicht aus einem grep über das Dokument erschlossen (siehe nächster Abschnitt).
- **Den Rettungssatz**, wörtlich: „Findet die Abnahme etwas anderes vor als hier steht, ist die Liste im Zweifel falsch, nicht der Fund." Er dreht die Beweislast auf die Liste — sonst diskutiert die Abnahme gegen das Produkt an.

Beim Nachmessen bleibt die alte Behauptung **kursiv daneben stehen** und jede Richtigstellung trägt `Datei:Zeile`. Ein stilles Überschreiben macht aus der Korrektur wieder ein unbelegtes Dokument.

## Markieren, nicht streichen

Ein Schritt ohne Fläche wird **markiert**, nicht gelöscht: der Unterschied zwischen „bewusst nicht gebaut" und „vergessen" ist genau das, was die Abnahme entscheiden soll. Im belegten Fall: 11 ohne Fläche, 2 echte Produktbefunde, 20 Richtigstellungen — **0 gestrichen**.

Die Zähl-Falle dazu ist gemessen und gilt für jedes Prüfdokument:

- Ein **Literal-grep auf den Markierungstext** fand 9 von 11 Flächen — zwei trugen eine Variante des Wortlauts.
- Ein **grep auf das Marker-Zeichen** fand 15 — eine Abschnittsüberschrift, zwei Vorspannzeilen und eine Tabellenzelle zählen mit.
- **Beide Zahlen sind falsch.** Die Reichweite gehört als Zahl in den Kopf und als Spalte in die Nachmess-Tabelle, vom Dokument selbst ausgesprochen. Ein Kommando über ein Dokument misst den Text, nicht die Sache.

## Das Dokument zum Anklicken — und die Falle im Namen

Wird der Fragenkatalog als Artefakt geliefert, gilt zuerst die Korrektur, an der zwei Dokumente still verloren gingen:

- **Eine Deklaration ist keine Persistenz.** Ein veröffentlichtes Artefakt behält **nichts**, was ein Betrachter tippt, ankreuzt oder zieht, solange die Seite es nicht selbst veröffentlicht. Ein „Live-Dokument", auf dem Gesten von allein ankommen, legt die **Plattform** an — weder die Seite noch ihre Deklaration wählt das. Wer die beiden verwechselt, baut eine Seite, die aussieht wie ein Formular und sich verhält wie ein Ausdruck.
- **Das Repo bleibt die Wahrheit.** Das Artefakt ist der **Rückkanal**, nicht der Ablageort: die beantwortete Fassung kommt zurück ins Repo, bevor jemand darauf baut.
- **Stabile Frage-IDs `F1..Fn`**, entscheidbare Optionen und je Frage ein Freitextfeld („anders: ___"). IDs machen die Antwort zitierbar, auch wenn die Reihenfolge sich ändert.
- **Vor der ersten Zeile `window.claude.*`-Code den `artifact-capabilities`-Skill des Tages laden.** Dieses Skill nennt den Laufzeitvertrag beim **Namen**, nie bei der Zeilennummer: die Vertragsdatei liegt versions- und hashgepfadet im Temp-Verzeichnis, und ihre Ankerzeilen sind zwischen zwei Patch-Ständen desselben Vertrags bereits gewandert. Ein nacherzählter Vertrag ist eine zweite, ältere Kopie.

## Der Bauplan

Sechs Pflichtteile. Fehlt einer, ist der Ausfall still — die Seite sieht in jedem Fall richtig aus.

1. **Zustand als Daten im Markup.** Ein `<script type="application/json">` trägt den Antwortstand; die Seite rendert daraus und liest ihn nie aus dem DOM zurück.
2. **Die Fähigkeit holen — mit null-Zweig.** `claude.use('artifact')` liefert `null`, wenn diese Ansicht die Fähigkeit nicht ausführen kann. Eine **nur lesende** Ansicht bekommt den Namensraum trotzdem: sie erfährt es erst am abgelehnten `publish()` (`not_writer`/`not_granted`), nie als `null`. Beides schaltet **sichtbar** auf den Druckweg — Hinweis zeigen, Eingaben stehen lassen, damit Ausfüllen und Drucken weiter gehen. Die Antworten auszublenden ist derselbe stille Verlust in anderer Gestalt.
3. **Selbstreproduktion.** Die Seite bettet ihren **eigenen** Script-Quelltext in die Ersetzung ein, die sie veröffentlicht. Ohne das liefert der erste erfolgreiche `publish()` eine Seite **ohne Laufzeit** — ein toter Schnappschuss, und jeder weitere Klick ist wieder verloren. Das ist derselbe stille Totalverlust, nur eine Ebene tiefer.
4. **Rendern aus einer Template-Funktion**, niemals `document.documentElement.outerHTML`: das lebende DOM trägt Sitzungszustand und eingespielte Laufzeit-Skripte des Betrachters.
5. **Entprellen und vorher sichern.** Jeder Aufruf prägt eine volle Version — nie pro Tastendruck; Freitext trotzdem bei jedem Zeichen erfassen, nicht erst beim Verlassen des Feldes. Jeder **erfolgreiche** `publish(html)` lädt **auch die eigene Ansicht** neu: Bildlaufposition und Fokus vorher in `sessionStorage` legen — und die noch nicht gelandeten Antworten ebenso, denn ein `conflict` lädt die Ansicht auf die fremde Fassung und nimmt sie sonst still mit.
6. **Zustand als Attribut ausgeben.** Die Template-Funktion schreibt `checked`/`value` als **Attribut** aus dem Zustand — ein nur als DOM-Property gesetzter Wert steht in keinem veröffentlichten Stand. Notwendig, aber nie hinreichend: ohne (1)–(5) spiegelt sie nur den Verlust.

Lauffähiges Gerüst, vollständig — dokumentspezifisch sind allein `QUESTIONS`, `renderContent` und das CSS. Die Fehlercodes darin sind der Stand des Laufzeitvertrags 0.2.52; der Skill des Tages geht vor:

```html
<!doctype html>
<html lang="de">
  <head>
    <meta charset="utf-8" />
    <title>Abnahme</title>
    <style id="doc-style">
      #printnote { border-left: 3px solid; padding: .5rem 1rem; }
      @media print { .no-print { display: none; } }
    </style>
  </head>
  <body>
    <!-- (1) The answer state as DATA; the runtime renders everything visible from it -->
    <script type="application/json" id="answers">{}</script>
    <div id="doc"></div>

    <script id="runtime">
      (() => {
        // (3) Self-reproduction: the page's own source travels into every replacement.
        const RUNTIME_SRC =
          (document.currentScript && document.currentScript.textContent) ||
          (document.getElementById('runtime') || { textContent: '' }).textContent;
        const STYLE_CSS = (document.getElementById('doc-style') || { textContent: '' }).textContent;

        // document-specific:
        const QUESTIONS = [{ id: 'F1', text: 'Beispielfrage', options: ['a', 'b'] }];

        let state = {};
        try { state = JSON.parse(document.getElementById('answers').textContent || '{}'); } catch { state = {}; }

        const esc = (s) => String(s).replace(/[&<>"]/g, (c) =>
          ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[c]);

        // (6) The template writes checked/value as ATTRIBUTES from the state. The input type sits in a
        //     variable, so the probe after the first input can never count this source text itself.
        const RADIO = 'radio';
        const renderContent = (a) =>
          '<p id="status" class="no-print" role="status"></p>' +
          '<aside id="printnote" class="no-print" hidden>Diese Ansicht speichert nicht: ' +
          'vor dem Schließen einmal „Als PDF drucken".</aside>' +
          QUESTIONS.map((q) =>
            `<fieldset><legend>${esc(q.id)} — ${esc(q.text)}</legend>` +
            q.options.map((o, i) =>
              `<label><input type="${RADIO}" id="${esc(q.id)}__${i}" name="${esc(q.id)}" value="${esc(o)}"` +
              `${a[q.id] === o ? ' checked' : ''} /> ${esc(o)}</label>`).join('') +
            `<input type="text" id="${esc(q.id)}__frei" name="${esc(q.id)}__frei"` +
            ` value="${esc(a[q.id + '__frei'] || '')}" placeholder="anders: …" /></fieldset>`).join('');

        // (4) The replacement comes from the template function, never from the live DOM.
        const renderDocument = (a) =>
          '<!doctype html><html lang="de"><head><meta charset="utf-8" /><title>Abnahme</title>' +
          '<style id="doc-style">' + STYLE_CSS + '</style></head><body>' +
          '<script type="application/json" id="answers">' +
          JSON.stringify(a).replace(/</g, '\\u003c') + '<\/script>' +
          '<div id="doc">' + renderContent(a) + '</div>' +
          '<script id="runtime">' + RUNTIME_SRC + '<\/script></body></html>';

        // (5) After every reload: bring back answers that did not land (never drop them silently),
        //     restore scroll position and focus.
        const PENDING = 'doc:pending';
        const VIEW = 'doc:view';
        let note = '';
        try {
          const pending = sessionStorage.getItem(PENDING);
          if (pending && pending !== JSON.stringify(state)) {
            state = JSON.parse(pending);
            note = 'Nicht gespeichert — die nächste Eingabe sichert diese Antworten mit.';
          } else if (pending) {
            sessionStorage.removeItem(PENDING);
            note = 'gesichert';
          }
        } catch {}
        const doc = document.getElementById('doc');
        doc.innerHTML = renderContent(state);
        const setStatus = (t) => { document.getElementById('status').textContent = t; };
        setStatus(note);
        try {
          const v = JSON.parse(sessionStorage.getItem(VIEW) || 'null');
          sessionStorage.removeItem(VIEW);
          if (v) {
            window.scrollTo(0, v.y || 0);
            const el = v.focus ? document.getElementById(v.focus) : null;
            if (el) { el.focus({ preventScroll: true }); if (v.sel != null) el.setSelectionRange(v.sel, v.sel); }
          }
        } catch {}

        // (2) Acquire the capability. null: this view cannot run it. A READ-ONLY view still gets the
        //     namespace and only learns it from the rejected publish.
        //     Codes: runtime contract 0.2.52 — check them against the day's artifact-capabilities skill.
        const FINAL = ['not_writer', 'not_granted', 'not_declared', 'consent_required', 'capability_disabled',
          'capability_removed', 'too_large', 'invalid_content', 'read_only_path', 'transform_error'];
        let publisher; // undefined: still pending · null: this view never saves
        let blocked = false, waiting = false, retried = false, delay = 2000, timer = null;
        const toPrintPath = (why) => {
          blocked = true;
          document.getElementById('printnote').hidden = false; // visible; the inputs stay printable
          setStatus(why);
        };
        function schedule() { clearTimeout(timer); timer = setTimeout(publishNow, delay); }
        async function publishNow() {
          if (blocked) return;
          if (!publisher) { waiting = true; return; }
          try {
            const el = document.activeElement;
            const sel = el && el.type === 'text' ? el.selectionStart : null;
            sessionStorage.setItem(VIEW, JSON.stringify({ y: window.scrollY, focus: (el && el.id) || '', sel }));
          } catch {}
          setStatus('sichert …');
          try {
            await publisher.publish(renderDocument(state)); // success: THIS view reloads too
          } catch (err) {
            const code = (err && err.code) || 'upstream_error';
            if (code === 'conflict') return; // already reloading to the newer version; PENDING rescues the input
            if (code === 'rate_limited') { delay = Math.min(delay * 2, 30000); schedule(); return; } // slow down, batch
            if (FINAL.includes(code)) { toPrintPath('Diese Ansicht speichert nicht (' + code + ').'); return; }
            if (!retried) { retried = true; setTimeout(publishNow, 1000 + Math.random() * 2000); return; }
            setStatus('Nicht gespeichert (' + code + ') — die nächste Eingabe versucht es erneut.');
          }
        }
        (async () => {
          let api = null;
          try {
            api = window.claude && typeof window.claude.use === 'function' ? await window.claude.use('artifact') : null;
          } catch { api = null; }
          publisher = api && typeof api.publish === 'function' ? api : null;
          if (!publisher) toPrintPath('Diese Ansicht kann nicht speichern.');
          else if (waiting) schedule();
        })();

        // Radios via change, free text on EVERY character — not only when the field is left. Debounced,
        // because every publish mints a full version ("a few seconds after the user pauses"; 2 s is the
        // number chosen here, not a contract value).
        const onEdit = (e) => {
          const el = e.target;
          if (!el || !el.name) return;
          state[el.name] = el.type === 'checkbox' ? el.checked : el.value;
          retried = false;
          try { sessionStorage.setItem(PENDING, JSON.stringify(state)); } catch {}
          if (!blocked) { setStatus('ungespeichert …'); schedule(); }
        };
        doc.addEventListener('change', onEdit);
        doc.addEventListener('input', onEdit);
      })();
    </script>
  </body>
</html>
```

## Mechanische Proben

Eine Merkliste findet nur, was auf ihr steht — beide Verluste fielen erst auf, als jemand den veröffentlichten Stand zurücklas. Diese Proben ziehen das nach vorn und trennen an echten Daten:

- **Vor dem Veröffentlichen:** zwei Zählungen, **beide** > 0 — `grep -ac 'claude\.use(' <datei>` und `grep -ac '\.publish(' <datei>`. Gemessen: **0** und **0** am zerstörten Stand, je **1** und **1** an den beiden reparierten. Eine ODER-Zählung über beide Muster lässt genau den belegten Ausfall durch: ein reparierter Stand, dem nur der `publish`-Aufruf fehlt, zählt dort noch **2** — getrennt gezählt **0**. Eine Seite ohne beide Treffer ist ein Ausdruck, kein Formular.
- **Nach der ERSTEN echten Eingabe:** den veröffentlichten Stand zurücklesen und `grep -aoE 'type="(radio|checkbox)"[^>]*checked' <stand> | wc -l` fahren — muss **> 0** sein. Ausdrücklich mit `-a` (nicht-UTF-8-Bytes) und als **Treffer**zählung über `-o`: `grep -c` zählt Zeilen und täuscht doppelt, weil eine CSS-Regel `input:checked` mitzählt und mehrere Treffer auf einer Zeile liegen können. Die Laufzeit steht mit im Stand: trägt ihr Quelltext `type="radio"` und `checked` auf einer Zeile, zählt die Probe sich selbst — das Gerüst hält den Typ deshalb in einer Variablen.

Die zweite Probe gehört nach der ersten Eingabe gefahren, nicht am Ende. Ein Formular, das eine Stunde lang ausgefüllt und dann als leer veröffentlicht wird, ist der teuerste Fall.

## Was kein Durchlesen findet

- **`use()` kann `null` liefern** — nicht gewährt, nicht geladen, keine Antwort im Zeitfenster. Ohne null-Zweig kehrt exakt derselbe stumme Totalverlust zurück.
- **Ein erfolgreicher `publish` lädt die eigene Ansicht neu.** Die Reparatur eines kaputten Dokuments erst veröffentlichen, wenn der Nutzer gesichert hat — sonst nimmt die Reparatur die letzten ungespeicherten Eingaben mit.
- **Geltungsbereich:** Das anklickbare Muster gilt für den Claude-Artifact-Kanal. Ohne Artifact-Werkzeug (OpenCode) entfallen die Abschnitte „Bauplan" und „Proben"; Herkunftskopf, Markieren-statt-Streichen und die Nachmessung gelten unverändert.
