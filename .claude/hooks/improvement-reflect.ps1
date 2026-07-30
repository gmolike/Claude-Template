#!/usr/bin/env pwsh
# Claude Code PreToolUse hook (PowerShell variant): feedback-loop reflect nudge.
# 1:1 port of improvement-reflect.sh for Windows machines where Claude Code routes hook commands
# through PowerShell (Git Bash optional / absent). A deterministic, NON-BLOCKING reminder: on a
# `git commit`/`git push` from the MAIN session, emit `additionalContext` asking whether this session
# exposed an agent-core improvement (rule/skill/hook) to feed back as a `skill-improvement` issue
# rather than fix inline - 22-session-close step 6. It NEVER denies (no permissionDecision).
# Two silence gates, then the nudge:
#   1. agent_id present -> subagent -> exit 0 (only the main session is nudged).
#   2. tool_input.command does NOT match `git\s+(commit|push)` -> exit 0.
# DRIFT CONTRACT: this file and improvement-reflect.sh MUST reach the SAME verdict on the SAME payload
# (subagent / git push / non-git / unparsable). On an unparsable payload BOTH fail-open to SILENT
# (here: ConvertFrom-Json throws -> catch -> exit 0). `-cmatch` is case-sensitive to mirror the .sh
# `grep -E` (and the JS regex in the OpenCode plugin) so no case drift creeps in.
$ErrorActionPreference = 'SilentlyContinue'
$raw = [Console]::In.ReadToEnd()
try { $j = $raw | ConvertFrom-Json } catch { exit 0 }   # fail-open -> silent
if ($j.agent_id) { exit 0 }                             # gate 1: subagent -> silent
$cmd = $j.tool_input.command
if (-not ($cmd -cmatch 'git\s+(commit|push)')) { exit 0 }  # gate 2: not git commit/push -> silent

# Emit the nudge as raw UTF-8 bytes so it survives regardless of the console's output encoding
# (Windows PowerShell 5.1 does not default to UTF-8). The em-dash is built at RUNTIME from its code
# point ([char]0x2014) so this SOURCE file stays pure ASCII: PS 5.1 reads a BOM-less .ps1 as ANSI
# (cp1252), which would mis-decode a literal UTF-8 em-dash in the source and double-encode it. Keeping
# the source ASCII sidesteps that entirely and makes the bytes byte-identical to improvement-reflect.sh.
$emDash = [char]0x2014
$json = '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"agent-core-Reflexion faellig? Falls diese Session eine Regel/Skill/Hook-Verbesserung aufgedeckt hat: 22-session-close Schritt 6 ' + $emDash + ' dedup + gh issue create --label skill-improvement, niemals inline."}}'
$bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
$stdout = [Console]::OpenStandardOutput()
$stdout.Write($bytes, 0, $bytes.Length)
$stdout.Flush()
exit 0
