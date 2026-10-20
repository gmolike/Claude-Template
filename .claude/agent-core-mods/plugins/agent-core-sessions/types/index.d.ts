/**
 * The `$.state` contract of the `agent-core-sessions` mod.
 *
 * `claude plugin validate` holds every `$.state` key the hooks module names to this file, so a key
 * that is not declared here fails validation instead of failing silently at runtime.
 */

/**
 * One local Claude Code session, as the engine's own session registry records it.
 *
 * Every field is read from `<config dir>/sessions/<pid>.json` — written by the engine for EVERY
 * session, whether this mod is loaded there or not. That is why the registry is the source and not
 * a row each session publishes itself: a session that started before the mod existed is still here.
 */
export type SessionRow = {
  /** The session process's pid, which is also its registry file's basename. */
  pid: number;
  /** The engine's session id (`$.session.id()` in that session). */
  sessionId: string;
  /** The session's display name as the engine derived or the person set it; the pid when absent. */
  name: string;
  /** Its working directory, as the registry spells it (native separators). */
  cwd: string;
  /** The word the session last wrote: `busy`, `idle`, … — a dead process leaves its last one standing. */
  status: string;
  /** `interactive`, or whatever kind the registry records. */
  kind: string;
  /** The engine version that WROTE this record — not necessarily the newest binary on the machine. */
  version: string;
  /** When that session began, in `$.clock.now()` milliseconds. */
  startedAt: number;
  /** When that session last touched its record, in `$.clock.now()` milliseconds. */
  updatedAt: number;
  /** Whether this row is the session the mod instance runs in (matched by `sessionId`). */
  isSelf: boolean;
};

/**
 * What the pane draws: the rows, when they were read, and what could not be read.
 *
 * `note` is the fail-loud channel — a board with no rows and no note would be indistinguishable
 * from "no sessions", so an unreadable registry says so in the pane instead of drawing empty.
 */
export type Board = {
  /** The sessions found, newest-touched first. */
  rows: SessionRow[];
  /** Which directory the rows were read from; `null` when none was found. */
  registryDir: string | null;
  /** When the read ran, in `$.clock.now()` milliseconds. */
  readAt: number;
  /** How many registry files were present but unreadable or unparsable; part of the reach. */
  skipped: number;
  /** A human-readable reason the board is incomplete, or `null` when it is not. */
  note: string | null;
  /** The own session's context-window fill in percent, or `null` when the engine reports none. */
  ownContextPercent: number | null;
  /** The own session's cost so far in USD, or `null` where the host keeps no ledger. */
  ownCostUsd: number | null;
  /** How many agent loops the own session is running now (`$.agent.list()`, own session only). */
  ownAgentsRunning: number;
};

declare module 'claude-code' {
  interface PluginState {
    'agent-core-sessions': { board: Board | null };
  }
}
