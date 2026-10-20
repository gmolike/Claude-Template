/**
 * Pure helpers of the `agent-core-sessions` mod: reading the engine's session registry is the only
 * thing this mod does, and everything here is the part of it that needs no `$`.
 *
 * Deliberately free of every engine call. `claude plugin validate` reports a module's `calls:` line
 * from its source, and keeping the `$` calls in `register.tsx` alone makes that line the whole truth
 * about what this mod reaches — a reviewer does not have to chase a helper to be sure.
 */

import type { SessionRow } from '../types';

/**
 * How many levels above the plugin's own folder are probed for a `sessions/` registry.
 *
 * Four, because that is what the two measured layouts need and no more: delivered at
 * `<config dir>/agent-core-mods/plugins/<name>/` the configuration directory is three up, and a
 * plugin read out of `<config dir>/plugins/<something>/<name>/` is four. The bound matters in both
 * directions — too few never finds it, too many could hit an unrelated `sessions` directory further
 * up, and the probe takes the NEAREST hit.
 */
const MAX_WALK_UP = 4;

/**
 * Split a path on either separator, so one helper serves Windows and POSIX.
 *
 * @param path - an absolute or relative path in native or POSIX spelling
 * @returns its non-empty segments, plus a leading `''` for a POSIX root
 */
function segmentsOf(path: string): string[] {
  return path.split(/[\\/]/);
}

/**
 * The candidate configuration directories to probe for a `sessions/` registry, nearest first.
 *
 * Derived from the plugin's own folder rather than from `$.env` or a pinned path: a delivered mod
 * sits at `<config dir>/skills/<name>/`, so the configuration directory is two levels up — but the
 * mod must also behave when it is loaded from somewhere else (a `--plugin-dir` folder while it is
 * being written). Walking up and probing each level with an existence check decides by measurement
 * instead of by a name, and works for a configuration directory that is not called `.claude`.
 *
 * ADR-0050: no machine-bound path may be pinned into a shipped artifact, so this is computed at
 * runtime, every time, from what the engine reports as the plugin's own root.
 *
 * @param pluginRoot - `$.plugin.root`, the absolute folder holding `plugin.json`
 * @returns the directories to probe, nearest first; empty when `pluginRoot` has no segments
 */
export function registryCandidates(pluginRoot: string): string[] {
  const parts = segmentsOf(pluginRoot).filter((s, i) => s !== '' || i === 0);
  const sep = pluginRoot.includes('\\') ? '\\' : '/';
  const out: string[] = [];
  for (let up = 1; up <= MAX_WALK_UP && parts.length - up >= 1; up += 1) {
    out.push(`${parts.slice(0, parts.length - up).join(sep)}${sep}sessions`);
  }
  return out;
}

/**
 * Whether a registry directory entry is a session record this mod may read.
 *
 * Strictly `<digits>.json`. The same directory also holds `<pid>.<hash>.key` files, which carry a
 * peer token: this mod never reads one, and the shape of this test — not a `.key` exclusion — is
 * what keeps it that way when a further file kind appears there.
 *
 * @param name - a bare directory entry name
 * @returns whether it is a `<pid>.json` session record
 */
export function isSessionRecord(name: string): boolean {
  return /^[0-9]+\.json$/.test(name);
}

/** A number from an unknown field, or `undefined` when it is not a finite number. */
function numberOf(value: unknown): number | undefined {
  return typeof value === 'number' && Number.isFinite(value) ? value : undefined;
}

/** A non-empty string from an unknown field, or `undefined`. */
function stringOf(value: unknown): string | undefined {
  return typeof value === 'string' && value !== '' ? value : undefined;
}

/**
 * Turn one parsed session record into a row, or `null` when it carries no usable identity.
 *
 * Every field is defaulted rather than assumed: the registry is the engine's own file and its shape
 * may grow, so a record missing a field still shows as a session instead of dropping out of the
 * board unseen. A record with neither `pid` nor `sessionId` is the one case that cannot be drawn.
 *
 * @param raw - the parsed JSON of one `<pid>.json`
 * @param ownSessionId - `$.session.id()` of the session this mod instance runs in
 * @returns the row, or `null` when the record has no identity
 */
export function toRow(raw: unknown, ownSessionId: string): SessionRow | null {
  if (raw === null || typeof raw !== 'object') return null;
  const r = raw as Record<string, unknown>;
  const pid = numberOf(r.pid);
  const sessionId = stringOf(r.sessionId);
  if (pid === undefined && sessionId === undefined) return null;
  const startedAt = numberOf(r.startedAt) ?? 0;
  return {
    pid: pid ?? 0,
    sessionId: sessionId ?? '',
    name: stringOf(r.name) ?? (pid === undefined ? '?' : `pid ${pid}`),
    cwd: stringOf(r.cwd) ?? '',
    status: stringOf(r.status) ?? '?',
    kind: stringOf(r.kind) ?? '?',
    version: stringOf(r.version) ?? '?',
    startedAt,
    updatedAt: numberOf(r.updatedAt) ?? startedAt,
    isSelf: sessionId !== undefined && sessionId === ownSessionId,
  };
}

/**
 * Order the board: the own session first, then the most recently active.
 *
 * @param rows - the rows as they were read
 * @returns a new array, own session first, then by `updatedAt` descending
 */
export function sortRows(rows: readonly SessionRow[]): SessionRow[] {
  return [...rows].sort((a, b) => {
    if (a.isSelf !== b.isSelf) return a.isSelf ? -1 : 1;
    return b.updatedAt - a.updatedAt;
  });
}

/**
 * A compact age, in unit symbols rather than words so the column stays narrow in any language.
 *
 * @param ms - an age in milliseconds; a negative value is treated as 0
 * @returns `12s`, `7m`, `3h`, `5d`
 */
export function formatAge(ms: number): string {
  const s = Math.max(0, Math.floor(ms / 1000));
  if (s < 60) return `${s}s`;
  if (s < 3600) return `${Math.floor(s / 60)}m`;
  if (s < 86400) return `${Math.floor(s / 3600)}h`;
  return `${Math.floor(s / 86400)}d`;
}

/**
 * The tail of a path, cut to `max` characters with a leading ellipsis, for a narrow pane.
 *
 * @param cwd - the working directory as the registry spelled it
 * @param max - how many characters the column has
 * @returns the last `max` characters, `…`-led when something was cut; `—` for an empty path
 */
export function shortCwd(cwd: string, max: number): string {
  if (cwd === '') return '—';
  if (cwd.length <= max) return cwd;
  return `…${cwd.slice(cwd.length - Math.max(1, max - 1))}`;
}

/**
 * Whether a row's own record looks stale: it says `busy` but has not been touched for a while.
 *
 * The registry's own doc property, measured: a session that is closed or dies leaves its last status
 * word standing. So `busy` alone is not evidence that work is running — only `busy` plus a recent
 * `updatedAt` is, and the pane marks the difference instead of repeating a word it cannot trust.
 *
 * @param row - the row to judge
 * @param now - the current time in milliseconds
 * @param staleAfterMs - how long an untouched record stays trustworthy
 * @returns whether the row's status word is older than `staleAfterMs`
 */
export function isStale(row: SessionRow, now: number, staleAfterMs: number): boolean {
  return now - row.updatedAt > staleAfterMs;
}
