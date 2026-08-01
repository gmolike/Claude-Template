# Claude Code PostToolUse hook (PowerShell variant): format files after Edit/Write.
# LAUNCHER: `powershell -NoProfile -ExecutionPolicy Bypass -File <this>.ps1` (src/targets/claude.ts) -
# Windows PowerShell 5.1, NOT `pwsh`. There is deliberately no shebang (ADR-0023): nothing ever execs
# this file, and the old `#!/usr/bin/env pwsh` named an interpreter that is not installed on the
# target machines. Since ADR-0027 the sync adapter also writes every .ps1 with a UTF-8 BOM, so a
# shebang would sit BEHIND those three bytes and could not work even if something did exec it.
# 1:1 port of format-on-edit.sh for Windows machines where Claude Code routes hook
# commands through PowerShell (Git Bash optional / absent).
# Receives the event as JSON on stdin (Claude Code convention).
#
# CONSOLE ENCODING - Windows PowerShell 5.1 defaults to the OEM code page (measured here: ibm850 for
#   [Console]::InputEncoding/OutputEncoding, us-ascii for $OutputEncoding). Left alone, this hook was
#   a SILENT no-op for every edited file whose path holds a non-ASCII character: `[Console]::In` (the
#   reader $StdInUtf8 below replaces) decoded the payload as CP850, so `tool_input.file_path` arrived
#   as mojibake, `Test-Path -LiteralPath` said False and the script exited 0 without ever running
#   Prettier. Measured on the pre-fix file with a pnpm stub on PATH: ASCII path -> stub invoked with
#   the exact path; "Muller-Grun" with umlauts -> stub NEVER invoked, exit 0, no output at all.
$ErrorActionPreference = 'SilentlyContinue'

# --- deterministic UTF-8 I/O, BEFORE anything is read or written ----------------------------------
# The three-line block below is ONE shared form - byte-for-byte the same in every agent-core .ps1
# hook that decodes non-ASCII text - the roster is PS_WITH_PROLOGUE in
# src/targets/claude.test.ts, which pins the block byte-for-byte with a lockstep test. Deliberately
# NOT enumerated here: a hand-kept list of names in every header is what drifts the moment a hook is
# added, which is how improvement-reflect.ps1 and worktree-bootstrap.ps1 first went unclassified.
# Every statement in it is PROCESS-LOCAL: none of them touches the console.
#   $OutputEncoding  a PowerShell VARIABLE, not a console API - the encoding of text piped INTO a
#                    native command. Nothing is piped here; carried for the shared form. Measured
#                    side-effect-free with GetConsoleCP/GetConsoleOutputCP across a child process
#                    (850/850 before, 850/850 after).
#   $StdInUtf8       stdin is read through OUR OWN reader on [Console]::OpenStandardInput(), never
#                    [Console]::In, so decoding depends on no console setting at all. THIS is the
#                    channel that was broken here - see the measurement above. Also measured
#                    side-effect-free (850/850 before and after).
# NOT here any more, and this is the point: [Console]::InputEncoding / [Console]::OutputEncoding were
# assigned until ADR-0027 R2. Their setters call SetConsoleCP / SetConsoleOutputCP, i.e. they rewrite
# the code page of the console the hook INHERITED - permanently, for every later process in it.
# Measured from a separate process around one run of this hook: before ConsoleCP=850
# ConsoleOutputCP=850, after 65001/65001, exit 0. All three channels were redirected during that run
# ([Console]::IsInputRedirected = True), so the old comment's "only when a channel is NOT redirected"
# was false as written. A formatter hook must not reconfigure the user's terminal.
# In THIS file both setters were also functionless: the hook has its own reader and writes no stdout.
# Native-command OUTPUT is the one channel that genuinely needed [Console]::OutputEncoding; the hooks
# that read one decode it per child process via Invoke-NativeUtf8. This hook reads none - pnpm/npx
# output goes to $null - and hands the path over as an ARGUMENT, which travels as UTF-16 through
# CreateProcessW and never meets a code page (measured: hex 4dc3bc6c6c65722d4772c3bc6e for
# "M<U+00FC>ller-Gr<U+00FC>n").
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$OutputEncoding = $Utf8NoBom
$StdInUtf8 = New-Object System.IO.StreamReader([Console]::OpenStandardInput(), $Utf8NoBom)

# Extract the edited file path from the event JSON.
# Read stdin through the explicit UTF-8 reader from the prologue - never [Console]::In.
$raw = $StdInUtf8.ReadToEnd()
if (-not $raw) { exit 0 }
try {
    $data = $raw | ConvertFrom-Json
} catch {
    exit 0
}
$file = $data.tool_input.file_path
if (-not $file) { exit 0 }
if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { exit 0 }

$ext = [System.IO.Path]::GetExtension($file).ToLowerInvariant()
if ($ext -in '.ts', '.tsx', '.js', '.jsx', '.json', '.css', '.md') {
    if (Get-Command pnpm -ErrorAction SilentlyContinue) {
        & pnpm exec prettier --write $file *> $null
    } elseif (Get-Command npx -ErrorAction SilentlyContinue) {
        & npx --no-install prettier --write $file *> $null
    }
}

exit 0
