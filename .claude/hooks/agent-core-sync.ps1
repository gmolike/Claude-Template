#!/usr/bin/env pwsh
# Claude Code SessionStart hook (PowerShell variant): auto-sync agent-core global config
# on every chat start. 1:1 port of agent-core-sync.sh for Windows machines where Claude Code
# routes hook commands through PowerShell (Git Bash optional / absent).
# Receives the session event as JSON on stdin (Claude Code convention; not evaluated here).
# C:/Entwicklung/claude-skills is replaced by the sync adapter with the absolute PKG_ROOT path at
# install time, so the path is baked into the deployed script and never depends on CWD.
$ErrorActionPreference = 'SilentlyContinue'

# Optional throttle: skip sync if the last run is fresher than AGENT_CORE_SYNC_THROTTLE_SEC
# seconds. Default 0 = sync on every session start.
# Example: $env:AGENT_CORE_SYNC_THROTTLE_SEC = 3600  # at most once per hour
$throttle = 0
if ($env:AGENT_CORE_SYNC_THROTTLE_SEC) {
    [int]::TryParse($env:AGENT_CORE_SYNC_THROTTLE_SEC, [ref]$throttle) | Out-Null
}
$homeDir = if ($env:USERPROFILE) { $env:USERPROFILE } else { $HOME }
$marker = Join-Path $homeDir '.claude/hooks/.last-global-sync'

if ($throttle -gt 0) {
    $now = [DateTimeOffset]::Now.ToUnixTimeSeconds()
    $last = [long]0
    if (Test-Path -LiteralPath $marker) {
        [long]::TryParse((Get-Content -LiteralPath $marker -Raw -ErrorAction SilentlyContinue), [ref]$last) | Out-Null
    }
    if (($now - $last) -lt $throttle) { exit 0 }
}

# Invocation strategy — try in order, all output discarded, never fail the session:
#   1. agent-core on PATH  ->  use it directly
#   2. node dist/cli.js    ->  use the baked-in PKG_ROOT path
#   3. neither found       ->  silent no-op (machines without a checkout)
$synced = $false
if (Get-Command agent-core -ErrorAction SilentlyContinue) {
    & agent-core sync --scope global *> $null
    $synced = $true
} elseif (Test-Path -LiteralPath 'C:/Entwicklung/claude-skills/dist/cli.js') {
    & node 'C:/Entwicklung/claude-skills/dist/cli.js' sync --scope global *> $null
    $synced = $true
}

# Update the throttle marker after a successful sync attempt.
if ($synced -and $throttle -gt 0) {
    $now = [DateTimeOffset]::Now.ToUnixTimeSeconds()
    Set-Content -LiteralPath $marker -Value $now -ErrorAction SilentlyContinue
}

exit 0
