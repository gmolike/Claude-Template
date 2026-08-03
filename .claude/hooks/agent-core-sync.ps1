# Claude Code SessionStart hook (PowerShell variant): auto-sync agent-core global config
# on every chat start. 1:1 port of agent-core-sync.sh for Windows machines where Claude Code
# routes hook commands through PowerShell (Git Bash optional / absent).
# LAUNCHER: `powershell -NoProfile -ExecutionPolicy Bypass -File <this>.ps1` (src/targets/claude.ts) -
# Windows PowerShell 5.1, NOT `pwsh`. There is deliberately no shebang (ADR-0023): nothing ever execs
# this file, and the old `#!/usr/bin/env pwsh` named an interpreter that is not installed on the
# target machines. Since ADR-0027 the sync adapter also writes every .ps1 with a UTF-8 BOM, so a
# shebang would sit BEHIND those three bytes and could not work even if something did exec it.
# Receives the session event as JSON on stdin (Claude Code convention; not evaluated here).
# C:/Users/Anwender/AppData/Local/npm-cache/_npx/0e26d8a440c77845/node_modules/@gmolike/agent-core is replaced by the sync adapter with the absolute PKG_ROOT path at
# install time, so the path is baked into the deployed script and never depends on CWD.
#
# NO UTF-8 PROLOGUE HERE, deliberately - and the reason is measured, not assumed (the sibling hooks
# orchestrator-guard.ps1 / origin-divergence-check.ps1 / format-on-edit.ps1 all carry one):
#   - This hook never reads stdin, never pipes text into a native command, and never writes to
#     stdout - all three native invocations discard their output with `*> $null`. Those are the only
#     channels the prologue pins, so here it would pin nothing.
#   - Its one path-shaped input is $env:USERPROFILE. Environment variables reach PowerShell through
#     the .NET environment block as UTF-16, so no code page is involved. Measured on the pre-BOM
#     file with USERPROFILE set to a directory holding an umlaut: run 1 invoked node once and wrote
#     the throttle marker INTO that directory, run 2 read it back and skipped the sync (nodeCalls
#     stayed 1). Join-Path / Test-Path / Get-Content / Set-Content all handled the umlaut correctly.
#   - The one thing that DOES break here is the C:/Users/Anwender/AppData/Local/npm-cache/_npx/0e26d8a440c77845/node_modules/@gmolike/agent-core literal below when the checkout
#     path holds a non-ASCII character. That is a PARSE-time defect - Windows PowerShell 5.1 reads a
#     BOM-less UTF-8 file as the legacy ANSI code page - and NO runtime prologue can repair a string
#     the parser already mis-decoded. It is fixed where it happens, at write time: the sync adapter
#     writes every .ps1 as UTF-8 WITH a BOM (ADR-0027).
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

# Invocation strategy - try in order, all output discarded, never fail the session:
#   1. agent-core on PATH  ->  use it directly
#   2. node dist/cli.js    ->  use the baked-in PKG_ROOT path
#   3. neither found       ->  silent no-op (machines without a checkout)
$synced = $false
if (Get-Command agent-core -ErrorAction SilentlyContinue) {
    & agent-core sync --scope global *> $null
    $synced = $true
} elseif (Test-Path -LiteralPath 'C:/Users/Anwender/AppData/Local/npm-cache/_npx/0e26d8a440c77845/node_modules/@gmolike/agent-core/dist/cli.js') {
    & node 'C:/Users/Anwender/AppData/Local/npm-cache/_npx/0e26d8a440c77845/node_modules/@gmolike/agent-core/dist/cli.js' sync --scope global *> $null
    $synced = $true
}

# Update the throttle marker after a successful sync attempt.
if ($synced -and $throttle -gt 0) {
    $now = [DateTimeOffset]::Now.ToUnixTimeSeconds()
    Set-Content -LiteralPath $marker -Value $now -ErrorAction SilentlyContinue
}

exit 0
