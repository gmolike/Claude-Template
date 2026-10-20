/**
 * The mod's own tests, run by `claude plugin test <mod folder>` against the delivered copy.
 *
 * ## Why this file is NOT named `*.test.ts` here
 *
 * `claude plugin test` selects by name only ("Runs every `*.test.ts` and `*.test.tsx` under dir") —
 * but `scripts/gate.mjs:364` walks this whole repository and reports every `*.test.ts(x)` outside
 * its three `TEST_ROOTS` as "test file in no vitest project, silently never run", which is a gate
 * problem. Measured on this tree: 67 tracked test files = 23 under `src/` + 8 under a `tooling`
 * package's `src/` + 36 under `apps/web/src/`, so **0 orphans** today and this file would be first.
 *
 * (Those root patterns are not spelled with a glob here on purpose: a `*` followed by a `/` inside a
 * block comment ends the comment, and the rest of the file is then parsed as code. That is not a
 * theory — it is what `claude plugin test` reported about this very file, `(fail) the file did not
 * load`, before this line was rewritten.)
 *
 * `agent-core sync` therefore renames it to `verzicht.test.ts` in the delivered mod
 * (`src/targets/claude-mods.ts`, `renameModTests`), and the delivered copy is the one that runs.
 * Run it here with a renamed copy: see that module's header for the whole reasoning.
 *
 * ## What these tests are for
 *
 * The first is the ADR-0057 Klasse-E condition under which this mod may be shipped at all: it must
 * not decide a tool call, so it can never outvote agent-core's own delegate-only PreToolUse guard.
 * The assertion is a positive one — the bottom hook must SEE the `Edit` unchanged and must be what
 * answers it — because "the mod registered no handler" is not something an absence can prove.
 *
 * RED-VERIFIED against the broken implementation, 2026-10-20, by mutating the SHIPPED module and
 * watching it fall: with one line added to `hooks/register.tsx`,
 * `on('tool.call', { tool: 'Edit' }, () => ({ deny: '…' }))`, this file reported
 * `(fail) entscheidet bei einem Edit nichts … Expected: 1 Received: 0` at exit 1, 9 pass / 1 fail.
 * `claude plugin validate` caught the same mutation at the artifact in the same run — its `hooks:`
 * line grew `tool.call{tool=Edit}` and it added "gating hook without .catch: tool.call{tool=Edit}"
 * — which is exactly the two-channel check ADR-0057 rests the class on. The mutation was reverted
 * and the revert proved byte-exact: sha256 of `hooks/register.tsx` back to
 * `493fd8f88dab055cb11d2792cc30e9cb5bf9a611631af91d0bb751540daba55b` at 11,261 bytes.
 *
 * Note which test did NOT fall under that mutation: the `Write` one stayed green, because the
 * mutation matched `tool: 'Edit'` alone. The two are not redundant, and that is why there are two.
 */

import { expect, test } from 'claude-code/testing';

import { formatAge, isSessionRecord, isStale, registryCandidates, toRow } from '../hooks/registry';

/** The pane id the mod draws under, as `register.tsx` names it. */
const PANE = 'agent-core-sessions';

/**
 * A session record exactly as the engine writes it — copied field for field out of a real
 * `~/.claude/sessions/<pid>.json` on 2026-10-20, build 2.1.299, with the ids shortened.
 *
 * This is the mod's whole input contract, and the reason it is a fixture and not a hand-written
 * shape: the parser is keyed by NAME, so a field the engine renames must show up as a failing
 * assertion here rather than as a column that silently reads `?` in the pane.
 */
const REAL_RECORD = {
  pid: 30548,
  sessionId: 'd069b855-0646-41b9-b4cb-24ac12e9c079',
  cwd: 'C:\\Entwicklung\\claude-skills',
  startedAt: 1792474572997,
  procStart: '134369481705710982',
  version: '2.1.299',
  peerProtocol: 1,
  peerFeatures: ['notify_idle', 'artifact_yield'],
  kind: 'interactive',
  entrypoint: 'cli',
  pidDomain: 'win32:gmo-pc',
  messagingSocketPath: '\\\\.\\pipe\\LOCAL\\cc-msg-6cc0f670',
  name: 'claude-skills-39',
  nameSource: 'derived',
  nameSince: 1792474572997,
  status: 'busy',
  updatedAt: 1792493380899,
  statusUpdatedAt: 1792493380899,
  bridgeSessionId: 'session_01UcZrAoA9',
} as const;

/** A Pane's props, filled as the engine fills them for a docked terminal pane. */
const PANE_PROPS = {
  title: 'Sitzungen',
  isFocused: false,
  bodyColumns: 72,
  placement: 'dock',
  scroll: { offset: 0, bodyRows: 20 },
  view: {},
} as const;

test('entscheidet bei einem Edit nichts und laesst das Ereignis unveraendert durch', async ($, on) => {
  let seenTool: string | undefined;
  let seenPath: string | undefined;
  let calls = 0;

  // Beneath every plugin, so this hook runs only if no plugin above it answered the event. It
  // answers instead of calling `next`, because beneath the test's own hook the kit's bottom throws.
  on('tool.call', (_$, e) => {
    calls += 1;
    seenTool = (e as { tool?: string }).tool;
    seenPath = (e as { file_path?: string }).file_path;

    return { deny: 'bottom-reached' };
  });

  const ran = await $.tool.call({
    tool: 'Edit',
    file_path: 'C:/does/not/exist/guarded.ts',
    old_string: 'a',
    new_string: 'b',
  });

  // A count, not a name: a mod that answered `tool.call` itself would leave this at 0, and the
  // assertion would fail for that reason and no other.
  expect(calls).toBe(1);
  expect(seenTool).toBe('Edit');
  // Handed through byte-for-byte: a mod that rewrote the event would change this.
  expect(seenPath).toBe('C:/does/not/exist/guarded.ts');
  // The bottom hook's own verdict came back, so nothing above it produced the answer.
  expect(ran.deny).toBe('bottom-reached');
});

test('entscheidet auch bei einem Write nichts', async ($, on) => {
  let calls = 0;
  on('tool.call', () => {
    calls += 1;

    return { deny: 'bottom-reached' };
  });

  const ran = await $.tool.call({
    tool: 'Write',
    file_path: 'C:/does/not/exist/new.ts',
    content: 'x',
  });

  expect(calls).toBe(1);
  expect(ran.deny).toBe('bottom-reached');
});

test('zeichnet die Pane, und vor dem ersten Lesen sagt sie das auch', async ($, on) => {
  // The kit has no engine beneath the plugins, so every call the mod makes needs a bottom here or
  // its hook is skipped — measured: without the `clock.now` bottom the engine reported
  // "agent-core-sessions's ui.render hook was skipped: no implementation for clock.now", which is a
  // SKIPPED hook and not a failing one. A render test without these bottoms therefore asserts the
  // kit's own fallback and would pass over a mod that never drew at all.
  on('clock.now', () => ({ value: 1_700_000_000_000 }));
  // Stands for the engine's own drawing. The mod answers `ui.render` without `next`, so this value
  // is never what the pane shows — it only has to exist for the dispatch to run.
  on('ui.render', () => ({ value: null }));

  // No `session.start` here: the point is the state BEFORE the first read, where the board is still
  // `null`. An empty pane at that moment would read as "no sessions" — the one claim this display
  // must never make by accident — so the loading branch is asserted by its own text.
  const pane = await $.ui.mount({
    plugin: PANE,
    surface: 'terminal',
    component: 'Pane',
    requestId: PANE,
    props: PANE_PROPS,
  });

  const lines = await pane.findAll({ type: 'Text' });
  expect(lines.length).toBeGreaterThan(0);
  // The mod's own tree, not the engine's fallback, and the loading wording and not an empty box.
  const loading = await pane.findAll({ type: 'Text', text: /Sitzungsregister wird gelesen/ });
  expect(loading.length).toBe(1);

  await pane.unmount();
});

test('liest einen echten Sitzungssatz, Feld fuer Feld und nach Namen', () => {
  const row = toRow(REAL_RECORD, REAL_RECORD.sessionId);
  expect(row).not.toBe(null);
  // Every field the pane draws, asserted by its VALUE and not merely by its presence: a parser
  // reading the wrong key would answer the default here and the pane would show `?` for ever.
  expect(row!.pid).toBe(30548);
  expect(row!.name).toBe('claude-skills-39');
  expect(row!.cwd).toBe('C:\\Entwicklung\\claude-skills');
  expect(row!.status).toBe('busy');
  expect(row!.kind).toBe('interactive');
  expect(row!.version).toBe('2.1.299');
  expect(row!.startedAt).toBe(1792474572997);
  expect(row!.updatedAt).toBe(1792493380899);
  // And the own-session mark, which is the only field the registry does not carry itself.
  expect(row!.isSelf).toBe(true);

  // The key set, so a renamed field is a failure and not a silent default.
  expect(Object.keys(row!).sort()).toEqual(
    ['cwd', 'isSelf', 'kind', 'name', 'pid', 'sessionId', 'startedAt', 'status', 'updatedAt', 'version'],
  );
});

test('ein fremder Satz ist nicht die eigene Sitzung', () => {
  const row = toRow(REAL_RECORD, 'eine-andere-sitzung');
  expect(row!.isSelf).toBe(false);
});

test('ein Satz ohne Kennung faellt heraus, ein unvollstaendiger nicht', () => {
  // Positive control first, so "returns null" is not just what this parser always does.
  expect(toRow({ pid: 1 }, '')).not.toBe(null);
  expect(toRow({}, '')).toBe(null);
  expect(toRow(null, '')).toBe(null);
  expect(toRow('nicht einmal ein Objekt', '')).toBe(null);
  // An incomplete record still shows as a session rather than vanishing from the board.
  const thin = toRow({ pid: 42 }, '');
  expect(thin!.name).toBe('pid 42');
  expect(thin!.status).toBe('?');
  expect(thin!.updatedAt).toBe(0);
});

test('nur <pid>.json wird gelesen — die .key-Datei daneben traegt ein Token', () => {
  expect(isSessionRecord('30548.json')).toBe(true);
  expect(isSessionRecord('1.json')).toBe(true);
  // The real neighbour file in that directory, measured: `<pid>.<hash>.key`.
  expect(
    isSessionRecord('30548.c927dccb2e3bbe8d0d5d2e7c5e88f6888bfe2b53e72850035eb791a8c6326f56.key'),
  ).toBe(false);
  expect(isSessionRecord('30548.json.bak')).toBe(false);
  expect(isSessionRecord('notes.json')).toBe(false);
  expect(isSessionRecord('.json')).toBe(false);
});

test('das Register wird vom Plugin-Verzeichnis aus gesucht, nicht aus einem gepinnten Pfad', () => {
  // ADR-0050: nothing machine-bound may be pinned into a shipped artifact, so the candidates are
  // derived at runtime from where the engine says this plugin lives. Delivered, that is
  // `<config dir>/agent-core-mods/plugins/<name>/`, so the THIRD candidate is the one that hits.
  const windows = registryCandidates(
    'C:\\Users\\x\\.claude\\agent-core-mods\\plugins\\agent-core-sessions',
  );
  expect(windows[2]).toBe('C:\\Users\\x\\.claude\\sessions');
  const posix = registryCandidates('/home/x/.claude/agent-core-mods/plugins/agent-core-sessions');
  expect(posix[2]).toBe('/home/x/.claude/sessions');
  // The other measured layout: a plugin Claude Code reads out of its own plugins tree. Four levels
  // is what covers both, and the walk stops there — see MAX_WALK_UP in `registry.ts`.
  expect(registryCandidates('/home/x/.claude/plugins/cache/a/b')[3]).toBe('/home/x/.claude/sessions');
  // A configuration directory that is NOT called `.claude` is found the same way — the walk probes
  // by existence, never by matching that name.
  expect(registryCandidates('/srv/cfg/agent-core-mods/plugins/m')[2]).toBe('/srv/cfg/sessions');
  // Bounded, so a deep path cannot turn one refresh into an unbounded number of probes.
  expect(registryCandidates('/a/b/c/d/e/f/g/h').length).toBe(4);
});

test('ein busy-Satz, den niemand mehr anfasst, gilt nicht als aktuell', () => {
  // The registry's measured property: a session that is closed or dies leaves its last status word
  // standing. So `busy` alone is never evidence, and the pane marks the difference.
  const row = toRow(REAL_RECORD, '')!;
  expect(isStale(row, row.updatedAt + 1_000, 60_000)).toBe(false);
  expect(isStale(row, row.updatedAt + 61_000, 60_000)).toBe(true);
});

test('das Alter wird in Einheitenzeichen gesetzt, in jeder Groessenordnung', () => {
  expect(formatAge(0)).toBe('0s');
  expect(formatAge(59_000)).toBe('59s');
  expect(formatAge(60_000)).toBe('1m');
  expect(formatAge(3_600_000)).toBe('1h');
  expect(formatAge(86_400_000)).toBe('1d');
  // A clock that went backwards must not print a negative age.
  expect(formatAge(-5_000)).toBe('0s');
});
