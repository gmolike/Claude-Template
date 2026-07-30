#!/usr/bin/env bash
# agent-core: main-chat orchestrator guard (Claude Code PreToolUse hook).
# Denies Edit/Write in the MAIN Claude session so the orchestrator delegates all implementation to
# subagents; subagent tool calls (which carry a non-empty "agent_id") pass through untouched.
# FAIL-OPEN by design: whenever an "agent_id" is detected, ALLOW — so a subagent edit is never
# blocked (no delegation deadlock). Only a call with NO detectable agent_id (the main session) is
# denied. jq is used when available (precise); otherwise a tolerant grep still enforces.
input="$(cat 2>/dev/null || true)"
agent_id=""
if command -v jq >/dev/null 2>&1; then
  agent_id="$(printf '%s' "$input" | jq -r '.agent_id // empty' 2>/dev/null || true)"
else
  # No jq: match a non-empty string value for the top-level "agent_id" field. A present match ->
  # subagent -> allow. This can only fail toward ALLOW (never denies a subagent), which is the safe
  # direction; the .ps1 path (Windows) parses precisely via ConvertFrom-Json.
  agent_id="$(printf '%s' "$input" | grep -oE '"agent_id"[[:space:]]*:[[:space:]]*"[^"]+"' | head -n1 || true)"
fi
if [ -n "$agent_id" ]; then exit 0; fi
cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Main chat is orchestrator-only: editing tools are denied for the main session. Delegate this change to a subagent (Task) or a Workflow."}}
JSON
exit 0
