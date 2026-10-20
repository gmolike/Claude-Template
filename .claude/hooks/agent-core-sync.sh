#!/usr/bin/env bash
# Claude Code SessionStart hook: auto-sync agent-core global config on every chat start.
# Receives the session event as JSON on stdin (Claude Code convention; not evaluated here).
# C:/Entwicklung/claude-skills is replaced by the sync adapter with the absolute PKG_ROOT path at
# install time, so the path is baked into the deployed script and never depends on CWD.
# This is the Claude-only path — OpenCode uses a separate bundle distribution mechanism
# with no 1:1 equivalent for session-startup shell hooks.
set -euo pipefail

# Optional throttle: skip sync if the last run is fresher than AGENT_CORE_SYNC_THROTTLE_SEC
# seconds. Default 0 = sync on every session start.
# Example: export AGENT_CORE_SYNC_THROTTLE_SEC=3600  # at most once per hour
_THROTTLE="${AGENT_CORE_SYNC_THROTTLE_SEC:-0}"
_MARKER="$HOME/.claude/hooks/.last-global-sync"
_SKIP_SYNC=0

if [ "$_THROTTLE" -gt 0 ] 2>/dev/null; then
  _NOW="$(date +%s 2>/dev/null || echo 0)"
  _LAST="$(cat "$_MARKER" 2>/dev/null || echo 0)"
  _ELAPSED=$(( _NOW - _LAST ))
  if [ "$_ELAPSED" -lt "$_THROTTLE" ]; then
    # Throttled: skip the sync, but do NOT exit — an unresolved warning from the last run is still
    # unresolved, and throttling a sync must not throttle the report about it (see the block below).
    _SKIP_SYNC=1
  fi
fi

# Invocation strategy — try in order, all output to /dev/null, never fail the session:
#   1. agent-core on PATH  →  use it directly
#   2. node dist/cli.js    →  use the baked-in PKG_ROOT path
#   3. neither found       →  silent no-op (machines without a checkout)
# The sync inherits CLAUDE_PROJECT_DIR, which Claude Code exports into every hook process, and
# REPORTS agent-core session-default keys pinned in that project's .claude/settings.json (ADR-0050,
# issue #69). Nothing is passed on the command line on purpose: an older agent-core on PATH would
# reject an unknown flag — silently, behind `|| true` — and skip the whole sync; an unknown
# environment variable it simply ignores.
_SYNCED=0
if [ "$_SKIP_SYNC" -eq 0 ]; then
  if command -v agent-core >/dev/null 2>&1; then
    agent-core sync --scope global >/dev/null 2>&1 || true
    _SYNCED=1
  elif [ -f "C:/Entwicklung/claude-skills/dist/cli.js" ]; then
    node "C:/Entwicklung/claude-skills/dist/cli.js" sync --scope global >/dev/null 2>&1 || true
    _SYNCED=1
  fi
fi

# Update the throttle marker after a successful sync attempt.
if [ "$_SYNCED" -eq 1 ] && [ "$_THROTTLE" -gt 0 ] 2>/dev/null; then
  _NOW="$(date +%s 2>/dev/null || echo 0)"
  echo "$_NOW" > "$_MARKER" 2>/dev/null || true
fi

# --- THE LOUD CHANNEL, DURABLE HALF (ADR-0050) -------------------------------
# The two invocations above discard stdout AND stderr, deliberately: one sync prints ~122 progress
# bullets that have no business in a session. But the sync's WARNINGS — everything it could not do
# and a human must — travelled on that same stderr, so for the path that runs on every machine at
# every session start they were unreachable by construction. Any promise of "we warn loudly" made
# over stderr alone could therefore never meet its own precondition, while looking like it did.
#
# The sync now also leaves those warnings as a READY-MADE SessionStart envelope next to the manifest,
# and this hook copies those bytes to its own stdout. It builds no JSON and escapes nothing: the
# escaping happens ONCE, in the CLI, instead of twice in two shell dialects that this repo has
# measured drifting into OPPOSITE verdicts on identical input.
#
# An absent (or empty) file is the "nothing to report" state — the sync REMOVES it on every clean
# run, so a stale block can never be replayed as if it were current. A corrupt file is fail-open:
# Claude Code ignores hook output it cannot parse, exactly as it does today for a silent hook.
# The emptiness test is "no non-whitespace byte", not `-s`: the PowerShell twin trims before it
# decides, and a `-s` here made the two disagree on a whitespace-only file — .sh emitted `0a20200a`,
# .ps1 emitted nothing. Found by running BOTH over one payload table, which is the only way this
# class of drift is ever visible (the sources read identically). `grep -a` because a warning block
# carries UTF-8 and grep must not decide it is binary.
#
# A THROTTLED run replays the LAST artifact — and the global sync puts a warning about the project
# the session opened into it (a pinned session default). Replayed into a session of ANOTHER project,
# that warning would name a file the session never touched as its own. The sync therefore records the
# project such an artifact is bound to in a plain-text sidecar (absent when nothing is project-bound),
# and a throttled run replays a bound artifact only into the same project. Plain string equality on
# purpose — no JSON parsing here, none in the twin. The artifact's last line also names its time.
_WARN="$HOME/.claude/.agent-core-warnings.json"
_EMIT=1
if [ "$_SKIP_SYNC" -eq 1 ]; then
  _BOUND="$(cat "$HOME/.claude/.agent-core-warnings.project" 2>/dev/null || true)"
  if [ -n "$_BOUND" ] && [ "$_BOUND" != "${CLAUDE_PROJECT_DIR:-}" ]; then
    _EMIT=0
  fi
fi
if [ "$_EMIT" -eq 1 ] && [ -s "$_WARN" ] && grep -qa '[^[:space:]]' "$_WARN" 2>/dev/null; then
  cat "$_WARN" 2>/dev/null || true
fi

exit 0
