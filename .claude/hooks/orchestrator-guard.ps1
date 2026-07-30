#!/usr/bin/env pwsh
# Claude Code PreToolUse hook (PowerShell variant): main-chat orchestrator guard.
# 1:1 port of orchestrator-guard.sh for Windows machines where Claude Code routes hook
# commands through PowerShell (Git Bash optional / absent). Denies Edit/Write in the MAIN
# Claude session so the orchestrator delegates all implementation to subagents; subagent
# calls (agent_id present) pass through. FAIL-OPEN: on any parse problem, allow (never
# deadlock subagent edits).
$ErrorActionPreference = 'SilentlyContinue'
$raw = [Console]::In.ReadToEnd()
try { $j = $raw | ConvertFrom-Json } catch { exit 0 }   # fail-open
if ($j.agent_id) { exit 0 }                             # subagent -> allow
[Console]::Out.Write('{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Main chat is orchestrator-only: editing tools are denied for the main session. Delegate this change to a subagent (Task) or a Workflow."}}')
exit 0
