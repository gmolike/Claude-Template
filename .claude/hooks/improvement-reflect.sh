#!/usr/bin/env bash
# agent-core: feedback-loop reflect nudge (Claude Code PreToolUse hook, matcher Bash).
# A deterministic, NON-BLOCKING reminder: on a `git commit`/`git push` from the MAIN session, emit
# `additionalContext` asking whether this session exposed an agent-core improvement (a rule, skill or
# hook) that must be fed back as a `skill-improvement` issue rather than fixed inline — 22-session-close
# step 6. It NEVER denies (no permissionDecision); the worst case is one extra system reminder.
# Two silence gates, then the nudge:
#   1. agent_id present -> subagent -> exit 0 (only the main session is nudged).
#   2. tool_input.command does NOT match `git\s+(commit|push)` -> exit 0 (any non-commit/push Bash).
# jq is used when available (precise); otherwise a tolerant grep decides identically for these gates.
# DRIFT CONTRACT: this file and improvement-reflect.ps1 MUST reach the SAME verdict on the SAME
# payload — verified over a shared payload table (subagent / git push / non-git / unparsable). On an
# unparsable payload BOTH fail-open to SILENT.
input="$(cat 2>/dev/null || true)"

agent_id=""
command_str=""
if command -v jq >/dev/null 2>&1; then
  agent_id="$(printf '%s' "$input" | jq -r '.agent_id // empty' 2>/dev/null || true)"
  command_str="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
else
  # No jq: match the top-level "agent_id" (non-empty value) and the "command" string. Both greps can
  # only fail toward SILENT here (they never manufacture a nudge), the safe direction; the .ps1 path
  # (Windows) parses precisely via ConvertFrom-Json.
  agent_id="$(printf '%s' "$input" | grep -oE '"agent_id"[[:space:]]*:[[:space:]]*"[^"]+"' | head -n1 || true)"
  command_str="$(printf '%s' "$input" | grep -oE '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -n1 || true)"
fi

# Gate 1: subagent -> silent.
if [ -n "$agent_id" ]; then exit 0; fi
# Gate 2: not a git commit/push -> silent (case-sensitive, mirroring the .ps1 -cmatch and the JS regex).
if ! printf '%s' "$command_str" | grep -qE 'git[[:space:]]+(commit|push)'; then exit 0; fi

cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"agent-core-Reflexion faellig? Falls diese Session eine Regel/Skill/Hook-Verbesserung aufgedeckt hat: 22-session-close Schritt 6 — dedup + gh issue create --label skill-improvement, niemals inline."}}
JSON
exit 0
