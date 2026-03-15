# Mobile App (apps/mobile)

React Native + Expo.

## Struktur

- `src/screens/` — Screen-Komponenten
- `src/navigation/` — React Navigation Setup
- `src/components/` — Mobile-spezifische Komponenten
- `src/hooks/` — Custom Hooks
- `src/services/` — API-Anbindung

## Befehle

- `turbo run dev --filter=mobile` — Expo starten
- `turbo run build --filter=mobile` — Build erstellen

## Workflow-Level-Routing

### Level 3 — Full Scrum (5+ Dateien, mehrere Layer)

PO erstellt Spec → Seniors planen parallel → Workers implementieren → QS → PO Review
**Team:** Scrum Master, PO, Sr. Frontend, Sr. Backend, Workers, Sr. QS

### Level 2 — Lite (2–5 Dateien, klares Scope)

Senior plant + implementiert selbst → QS reviewed
**Team:** Relevanter Senior + Sr. QS

### Level 1 — Bugfix (1–2 Dateien, klar lokalisiert)

Debugger analysiert + fixt → Senior reviewed
**Team:** Debugger + relevanter Senior
