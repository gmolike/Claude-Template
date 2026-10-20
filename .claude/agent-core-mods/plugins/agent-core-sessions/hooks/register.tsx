/**
 * `agent-core-sessions` — agent-core's own mod (Klasse E, Anzeige-Fläche).
 *
 * It draws one pane listing EVERY local Claude Code session: its name, what it last said it was
 * doing, its working directory and how long ago it said so — plus, for the session the pane is drawn
 * in, the context-window fill, the cost so far and how many agent loops are running.
 *
 * WHY THE SESSION REGISTRY AND NOT `$.store`. The reach asked for is "all local sessions", and
 * `$.agent.list()` and `$.session.usage()` are both own-session only (measured against this build's
 * own type declarations: AgentInfo is "One agent loop of this session"). The only cross-session
 * source is the engine's own registry under `<config dir>/sessions/<pid>.json`, which the engine
 * writes for every session whether this mod is loaded there or not — so a session that started
 * before the mod existed is still on the board. Publishing a row per session through `$.store`
 * would cover only sessions that already have the mod, and `$.store` is one JSON file per plugin
 * shared by every session, so two sessions writing at once lose each other's row.
 *
 * WHAT IT DELIBERATELY DOES NOT DO (ADR-0057, Klasse E — the surrender is the condition of being
 * shipped at all). No `tool.check` hook, and no `tool.call` hook of any kind, so this mod cannot
 * decide a tool call and cannot outvote agent-core's own delegate-only PreToolUse guard. No
 * `$.fs.write`, `$.process.*`, `$.env.set`, `$.prompt.submit`, `$.session.send`, `$.mcp.call`,
 * `$.model.complete` and no `agent.spawn` — a mod that sets a model would override the per-call
 * model parameter. `claude plugin validate` reads the `hooks:` and `calls:` lines out of this file
 * without running it, so the surrender is checkable at the artifact.
 */

import { atom, read, update } from 'claude-code';
import type { EngineInterface, Register } from 'claude-code';

import type { Board, SessionRow } from '../types';

import {
  formatAge,
  isSessionRecord,
  isStale,
  registryCandidates,
  shortCwd,
  sortRows,
  toRow,
} from './registry';

/** The pane's id, and the slash command that reopens it after a close. */
const PANE = 'agent-core-sessions';

/** How often the board is re-read. The registry is a handful of small files; 5 s is cheap and live. */
const REFRESH_MS = 5_000;

/** After this long without a touch, a session's own status word is no longer treated as current. */
const STALE_AFTER_MS = 60_000;

/** Never read more than this many records, so a registry left full of dead pids cannot stall a draw. */
const MAX_RECORDS = 64;

const board = atom({ plugin: 'agent-core-sessions', key: 'board' } as const, null);

/**
 * Find the engine's session registry by probing upwards from the plugin's own folder.
 *
 * @param $ - the engine interface
 * @returns the first existing `…/sessions` directory, or `null` when none of the candidates exists
 */
async function findRegistry($: EngineInterface): Promise<string | null> {
  for (const candidate of registryCandidates($.plugin.root)) {
    const exists = await $.fs.exists(candidate).catch(() => false);
    if (exists) return candidate;
  }
  return null;
}

/**
 * Read the registry and the own session's figures, and write the result into `$.state`.
 *
 * Writing the state is what redraws the pane — a `$.state.set` draws exactly the sites that read
 * the value while drawing, so no `$.ui.invalidate` is needed. Every failure arrives as `note` or
 * `skipped` rather than as an empty board: a board with no rows and no reason would read as "no
 * sessions", which is the one thing this display must never claim by accident.
 *
 * @param $ - the engine interface
 * @returns nothing; the board is handed over through `$.state`
 */
async function refresh($: EngineInterface): Promise<void> {
  const readAt = await $.clock.now();
  const ownSessionId = await $.session.id().catch(() => '');

  let ownContextPercent: number | null = null;
  let ownCostUsd: number | null = null;
  let ownAgentsRunning = 0;
  try {
    // The field names are this build's own: SessionContextUsage is `{ tokens?, window, percent? }`
    // and SessionCost is `{ usd }`. Guessing them (`used`/`size`/`totalCostUsd`) costs nothing at
    // load or validate time and leaves the figure silently `null` forever — measured, and the reason
    // these two reads are spelled against the declaration rather than from memory.
    const usage = await $.session.usage();
    const percent = usage.context?.percent;
    const tokens = usage.context?.tokens;
    const window = usage.context?.window;
    if (typeof percent === 'number') {
      ownContextPercent = Math.round(percent);
    } else if (typeof tokens === 'number' && typeof window === 'number' && window > 0) {
      ownContextPercent = Math.round((tokens / window) * 100);
    }
    if (typeof usage.cost?.usd === 'number') ownCostUsd = usage.cost.usd;
  } catch {
    /* the engine reports no figures for this session — the row simply carries none */
  }
  try {
    ownAgentsRunning = (await $.agent.list()).filter((a) => a.status === 'running').length;
  } catch {
    /* no agent list available — 0 is then "not reported", which `note` does not claim otherwise */
  }

  const registryDir = await findRegistry($);
  if (registryDir === null) {
    await update($, board, () => ({
      rows: [],
      registryDir: null,
      readAt,
      skipped: 0,
      note: 'Sitzungsregister nicht gefunden — diese Anzeige kennt nur die eigene Sitzung.',
      ownContextPercent,
      ownCostUsd,
      ownAgentsRunning,
    }));
    return;
  }

  let entries: readonly { name: string }[] = [];
  try {
    entries = await $.fs.list(registryDir);
  } catch (error) {
    await update($, board, () => ({
      rows: [],
      registryDir,
      readAt,
      skipped: 0,
      note: `Sitzungsregister nicht lesbar: ${String(error)}`,
      ownContextPercent,
      ownCostUsd,
      ownAgentsRunning,
    }));
    return;
  }

  // `<pid>.<hash>.key` files live in the same directory and carry a peer token. Only `<pid>.json`
  // passes this test, so no credential is ever read into the plugin's environment.
  const records = entries.map((entry) => entry.name).filter(isSessionRecord);
  const budget = records.slice(0, MAX_RECORDS);
  const rows: SessionRow[] = [];
  let skipped = records.length - budget.length;

  for (const name of budget) {
    const text = await $.fs.read(`${registryDir}/${name}`).catch(() => undefined);
    if (typeof text !== 'string') {
      skipped += 1;
      continue;
    }
    let parsed: unknown;
    try {
      parsed = JSON.parse(text);
    } catch {
      skipped += 1;
      continue;
    }
    const row = toRow(parsed, ownSessionId);
    if (row === null) skipped += 1;
    else rows.push(row);
  }

  const board_: Board = {
    rows: sortRows(rows),
    registryDir,
    readAt,
    skipped,
    note: skipped > 0 ? `${skipped} Satz/Sätze übersprungen (nicht lesbar oder ohne Kennung).` : null,
    ownContextPercent,
    ownCostUsd,
    ownAgentsRunning,
  };
  await update($, board, () => board_);
}

export const register: Register = (on) => {
  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: PANE,
      description: 'Die Pane mit allen lokalen Sitzungen öffnen',
    });

    // Opened unasked on purpose: the point of the board is to be there without being summoned. The
    // surface decides whether it is seated — a pane opened unasked waits below ~110 columns instead
    // of taking the room, and the slash command above brings it back after a close.
    void $.ui.open({ id: PANE, title: 'Sitzungen' });

    void refresh($);
    $.clock.every(REFRESH_MS, () => {
      void refresh($);
    });

    return next(e);
  });

  // `.catch` is mandatory, not decoration: `claude plugin validate` reports a gating hook without
  // one ("gating hook without .catch"), and without it a failed hook is simply ABSENT — the person
  // would type the command and get the engine's "unknown command" instead of a reason.
  on('command.run', { command: PANE }, async ($) => {
    await $.ui.open({ id: PANE, title: 'Sitzungen' });
    await refresh($);

    return { text: 'Pane "Sitzungen" geöffnet.' };
  }).catch(($, e, next) =>
    next.called ? next(e) : { text: `${$.plugin.name}: Die Pane konnte nicht geöffnet werden.` },
  );

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const { Box, Text } = $.ui.resolve(e);
    const shown = await read($, board);
    const now = await $.clock.now();

    if (shown === null) {
      return (
        <Box flexDirection="column">
          <Text color="subtle">Sitzungsregister wird gelesen …</Text>
        </Box>
      );
    }

    const columns = e.props.bodyColumns;
    const room = Math.max(1, (e.props.scroll?.bodyRows ?? e.viewport?.rows ?? 24) - 3);
    // The directory column gets whatever the fixed columns leave: name 18, status 9, age 5, gaps 3.
    const cwdRoom = Math.max(8, columns - 35);
    const visible = shown.rows.slice(0, room);

    return (
      <Box flexDirection="column">
        <Text color="subtle">
          {shown.rows.length === 1 ? '1 Sitzung' : `${shown.rows.length} Sitzungen`} · gelesen vor{' '}
          {formatAge(now - shown.readAt)}
        </Text>

        {shown.rows.length === 0 && shown.note === null && (
          <Text color="subtle">Keine Sitzung im Register.</Text>
        )}

        {visible.map((row) => {
          const stale = isStale(row, now, STALE_AFTER_MS);
          const status = stale ? `${row.status}?` : row.status;
          return (
            <Box key={`s:${row.pid}`} flexDirection="row" gap={1}>
              <Text
                color={row.isSelf ? 'claude' : 'text'}
                bold={row.isSelf}
                wrap="truncate-end"
                key={`n:${row.pid}`}
              >
                {(row.isSelf ? `▸ ${row.name}` : `  ${row.name}`).padEnd(18).slice(0, 18)}
              </Text>
              <Text
                color={stale ? 'warning' : row.status === 'busy' ? 'success' : 'subtle'}
                key={`st:${row.pid}`}
              >
                {status.padEnd(9).slice(0, 9)}
              </Text>
              <Text color="subtle" key={`c:${row.pid}`}>
                {shortCwd(row.cwd, cwdRoom).padEnd(cwdRoom).slice(0, cwdRoom)}
              </Text>
              <Text color="inactive" key={`a:${row.pid}`}>
                {formatAge(now - row.updatedAt).padStart(5)}
              </Text>
            </Box>
          );
        })}

        {shown.rows.length > visible.length && (
          <Text color="subtle">… {shown.rows.length - visible.length} weitere</Text>
        )}

        <Box flexDirection="column" marginTop={1}>
          <Text color="subtle">
            Eigene Sitzung: Kontext{' '}
            {shown.ownContextPercent === null ? '—' : `${shown.ownContextPercent} %`} · Agenten{' '}
            {shown.ownAgentsRunning}
            {shown.ownCostUsd === null ? '' : ` · ${shown.ownCostUsd.toFixed(2)} USD`}
          </Text>
          {shown.note !== null && <Text color="warning">{shown.note}</Text>}
        </Box>
      </Box>
    );
  });
};
