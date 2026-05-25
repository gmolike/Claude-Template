## Worker-Frontend Output: Scrum Board Integration (vscode-session)

### Implementierte Dateien

- `/c/Entwicklung/Claude-Template/apps/vscode-session/src/session/scrumBoard.ts`
  — Neues Modul: `ScrumTask` interface, `ScrumTaskStatus` type, `getScrumTasks()`, `moveTask()`.
  Scannt `.scrum/{domain}/{status}/*.md`, skippt `.gitkeep`, behandelt fehlende Verzeichnisse graceful.

- `/c/Entwicklung/Claude-Template/apps/vscode-session/src/shared/messages.ts`
  — `ScrumTask` import type hinzugefügt. `ExtensionToWebview` um `scrumTasks` erweitert.
  `WebviewToExtension` um `moveTask` und `refreshScrum` erweitert.

- `/c/Entwicklung/Claude-Template/apps/vscode-session/src/panel.ts`
  — Import von `getScrumTasks`, `moveTask`, `ScrumTaskStatus`. Neue Methode `sendScrumTasks()`.
  Handler für `moveTask` und `refreshScrum` in `handleWebviewMessage()`. `sendScrumTasks()` im `ready`-Handler.

- `/c/Entwicklung/Claude-Template/apps/vscode-session/src/extension.ts`
  — `panel!.sendScrumTasks()` in `envTick()` (alle 10s) und in `onReady`-Callback.

- `/c/Entwicklung/Claude-Template/apps/vscode-session/src/webview/body.html`
  — Neuer `scrum-section` div mit Domain-Filter und Task-Container, eingefügt zwischen
  `session-history-section` und `mcp-section`.

- `/c/Entwicklung/Claude-Template/apps/vscode-session/src/webview/index.ts`
  — `_allScrumTasks`, `_scrumDomainFilter`, `SCRUM_STATUS_COLORS`, `SCRUM_STATUS_LABELS`,
  `renderScrumBoard()`, `initScrumFilters()` vor `// ─── CLI Tools`.
  `scrumTasks` message handler im `window.addEventListener('message', ...)` Block.

### Tests

Kein dediziertes Test-Verzeichnis in der Extension vorhanden (`pnpm test` läuft Vitest
aber es existieren keine bestehenden Unit-Tests für Extension-Module).
Die Implementierung ist direkt gegen `tsc --noEmit` verifiziert: 0 Fehler, 0 Warnungen.

### FSD-Check

Diese Extension folgt nicht FSD-Architektur (eigenständige VS Code Extension, kein FSD).
Gemäß `apps/vscode-session/CLAUDE.md`: "Kein Full Scrum nötig (eigenständige Extension)".

- Layer: N/A (VS Code Extension, eigene Schichtenstruktur: `session/`, `shared/`, `webview/`)
- Public API: `scrumBoard.ts` exportiert `ScrumTask`, `ScrumTaskStatus`, `getScrumTasks`, `moveTask`
- Imports: `scrumBoard.ts` nutzt nur Node.js builtins (`fs`, `path`) — keine internen Abhängigkeiten
- CommonJS: Ja, kein `import/export` in tsconfig-Ausgabe, `module: commonjs`
- TypeScript strict: `tsc --noEmit` sauber

### Status: Bereit für Review in .scrum/review/
