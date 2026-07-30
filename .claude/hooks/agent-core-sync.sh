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

if [ "$_THROTTLE" -gt 0 ] 2>/dev/null; then
  _NOW="$(date +%s 2>/dev/null || echo 0)"
  _LAST="$(cat "$_MARKER" 2>/dev/null || echo 0)"
  _ELAPSED=$(( _NOW - _LAST ))
  if [ "$_ELAPSED" -lt "$_THROTTLE" ]; then
    exit 0
  fi
fi

# Invocation strategy — try in order, all output to /dev/null, never fail the session:
#   1. agent-core on PATH  →  use it directly
#   2. node dist/cli.js    →  use the baked-in PKG_ROOT path
#   3. neither found       →  silent no-op (machines without a checkout)
_SYNCED=0
if command -v agent-core >/dev/null 2>&1; then
  agent-core sync --scope global >/dev/null 2>&1 || true
  _SYNCED=1
elif [ -f "C:/Entwicklung/claude-skills/dist/cli.js" ]; then
  node "C:/Entwicklung/claude-skills/dist/cli.js" sync --scope global >/dev/null 2>&1 || true
  _SYNCED=1
fi

# Update the throttle marker after a successful sync attempt.
if [ "$_SYNCED" -eq 1 ] && [ "$_THROTTLE" -gt 0 ] 2>/dev/null; then
  _NOW="$(date +%s 2>/dev/null || echo 0)"
  echo "$_NOW" > "$_MARKER" 2>/dev/null || true
fi

exit 0
