# ============================================================================
# Claude Code SessionStart hook (PowerShell variant): auto-sync agent-core global config
# on every chat start. 1:1 port of agent-core-sync.sh for Windows machines where Claude Code
# routes hook commands through PowerShell (Git Bash optional / absent).
#
# LAUNCHER: `powershell -NoProfile -ExecutionPolicy Bypass -File <this>.ps1` (src/targets/claude.ts) -
# Windows PowerShell 5.1, NOT `pwsh`. There is deliberately no shebang (ADR-0023): nothing ever execs
# this file, and the old `#!/usr/bin/env pwsh` named an interpreter that is not installed on the
# target machines. Since ADR-0027 the sync adapter also writes every .ps1 with a UTF-8 BOM, so a
# shebang would sit BEHIND those three bytes and could not work even if something did exec it.
# Receives the session event as JSON on stdin (Claude Code convention; not evaluated here).
# C:/Entwicklung/claude-skills is replaced by the sync adapter with the absolute PKG_ROOT path at
# install time, so the path is baked into the deployed script and never depends on CWD.
#
# THIS HOOK NOW CARRIES BOTH SHARED FORMS, and the reason it used to carry neither is exactly the
# reason it must carry them now. The old header argued: "this hook never reads stdin, never pipes
# text into a native command, and never writes to stdout - all three native invocations discard
# their output with `*> $null`. Those are the only channels the prologue pins, so here it would pin
# nothing." That was true, and it was the same fact as the defect ADR-0050 closes: because this hook
# threw away every stream, the sync's WARNINGS - everything it could not do and a human must - were
# unreachable on the one path that runs on every machine at every session start. It now WRITES TO
# STDOUT (the SessionStart envelope below) and READS A UTF-8 FILE, so both channels are live and
# both shared forms are carried whole, byte-for-byte, pinned by the lockstep test in
# src/targets/claude.test.ts. What has NOT changed: the C:/Entwicklung/claude-skills literal below is a
# PARSE-time exposure - Windows PowerShell 5.1 reads a BOM-less UTF-8 file as the legacy ANSI code
# page - and no runtime prologue can repair a string the parser already mis-decoded. That one is
# fixed where it happens, at write time, by the UTF-8 BOM the adapter writes (ADR-0027).
#
# FAIL-OPEN: this hook must NEVER fail a session - every step is guarded and the script always
# exits 0.
# ============================================================================
$ErrorActionPreference = 'SilentlyContinue'

# --- deterministic UTF-8 I/O, BEFORE anything is read or written ----------------------------------
# The three-line block below is ONE shared form - byte-for-byte the same in every agent-core .ps1 hook
# that decodes non-ASCII text, pinned as such by a lockstep test in src/targets/claude.test.ts. Every
# statement in it is PROCESS-LOCAL: none of them touches the console (ADR-0027 R2).
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$OutputEncoding = $Utf8NoBom
$StdInUtf8 = New-Object System.IO.StreamReader([Console]::OpenStandardInput(), $Utf8NoBom)

# --- process-local native I/O helpers -------------------------------------------------------------
# The block from ConvertTo-NativeArgument down to the end of Write-Stdout is the SECOND shared form:
# byte-for-byte identical in every hook that reads a native command's stdout or writes its own, and
# pinned by the same lockstep test. THIS hook uses exactly one half of it - Write-Stdout, to emit the
# SessionStart envelope as raw UTF-8 bytes instead of through the console's own writer, whose encoding
# is the console code page and would turn the German warning text into mojibake in the session
# context. The other half is unused here; the block is carried WHOLE because a partial hand copy is
# exactly how the two forms drift apart.
<#
.SYNOPSIS
Quote one argument the way CommandLineToArgvW parses it back, so a path holding a space or a
backslash reaches the child intact.
.DESCRIPTION
The quoting PowerShell would do for `&` has to be done here, because Invoke-NativeUtf8 hands
Start-Process ONE command-line string. That is deliberate: PowerShell 5.1 joins an -ArgumentList
ARRAY with spaces and quotes nothing, so an array element holding a space silently splits into two
arguments - measured against a repo path holding both a space and U+00FC, git died with "cannot
change to '...\my'". Passing a single, self-quoted string is the only form that survives; with this
quoter the same path arrives intact (Test-Path True).
.PARAMETER Value
The raw argument.
.OUTPUTS
System.String - the argument, quoted only when it has to be.
#>
function ConvertTo-NativeArgument([string]$Value) {
  if ($Value -cmatch '^[A-Za-z0-9_.:/=+@%-]+$') { return $Value }
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.Append('"')
  $slashes = 0
  foreach ($ch in $Value.ToCharArray()) {
    if ($ch -eq '\') { $slashes++; continue }
    if ($ch -eq '"') { [void]$sb.Append('\', ($slashes * 2) + 1); [void]$sb.Append('"'); $slashes = 0; continue }
    if ($slashes -gt 0) { [void]$sb.Append('\', $slashes); $slashes = 0 }
    [void]$sb.Append($ch)
  }
  if ($slashes -gt 0) { [void]$sb.Append('\', $slashes * 2) }
  [void]$sb.Append('"')
  return $sb.ToString()
}

<#
.SYNOPSIS
Run a native command and read its stdout as UTF-8 - PROCESS-LOCALLY, without touching the console.
.DESCRIPTION
Windows PowerShell 5.1 decodes a native command's stdout with [Console]::OutputEncoding, and that
SETTER calls SetConsoleOutputCP - it rewrites the inherited console's code page for every later
process in it. Here every byte goes through a TEMP FILE instead, so nothing but this process is
involved: the child writes raw bytes, and THIS code decides they are UTF-8. Measured on
`git rev-parse --absolute-git-dir` in a repo path holding U+00FC: plain `& git` with the console
left alone -> U+251C U+255D, Test-Path False; `& git` after the old setter -> U+00FC, Test-Path
True, but ConsoleOutputCP moved 850 -> 65001; this helper -> U+00FC, Test-Path True, console
unchanged at 850/850.
FILE redirection, not a pipe, and that is the load-bearing detail. A redirected ProcessStartInfo
pipe hands stdin to a .NET StreamWriter built from [Console]::InputEncoding, whose AutoFlush emits
that encoding's PREAMBLE at Process.Start - before this code writes anything. On a console left at
CP 65001 (a `chcp 65001` terminal is common) that preamble is a UTF-8 BOM: measured, the child read
`efbbbf7b226167656e745f6964...` instead of `7b226167656e745f6964...`, JSON.parse threw, node
answered "unparsable" and the guard flipped from DENY to fail-open ALLOW while the .sh still denied
- one payload, two answers, decided by the user's code page. Start-Process -RedirectStandardInput
opens the file itself, so the child gets exactly the bytes written here: measured identical
(`7b22637764223a22433a2f78227d`) from a console at 850 AND at 65001.
The executable is resolved through Get-Command because Start-Process does not apply PATHEXT to a
bare name the way `&` does (a bare "jq" would miss a jq.cmd shim, which is exactly what the suite
puts on PATH). $proc.Handle is read once because a Start-Process object drops its handle on exit and
ExitCode then reads back empty - and the exit code is what the jq stage and Invoke-Git branch on.
.PARAMETER Command
Command name to resolve on PATH.
.PARAMETER CommandArgs
Arguments, each passed through untouched - no shell is involved, nothing is word-split or expanded.
.PARAMETER StdinText
Optional text written to the child as UTF-8 bytes; '' or $null sends an empty stdin (immediate EOF).
.PARAMETER WorkingDirectory
Optional working directory. Without it PowerShell 5.1 hands the child ITS OWN location rather than
the process directory - measured: after a Push-Location the child reported the pushed path. No
shipped hook uses Push-Location, so the two coincide; the guard passes nothing on purpose and
therefore resolves in the session's directory, the status line passes the payload's cwd.
.OUTPUTS
System.Collections.Hashtable - @{ ExitCode = <int>; Stdout = <string> }, or $null when the command
could not be resolved, started or read.
#>
function Invoke-NativeUtf8([string]$Command, [string[]]$CommandArgs, [string]$StdinText, [string]$WorkingDirectory) {
  $exe = @(Get-Command $Command -CommandType Application -ErrorAction SilentlyContinue)[0]
  if (-not $exe) { return $null }
  $inFile = [IO.Path]::GetTempFileName()
  $outFile = [IO.Path]::GetTempFileName()
  $errFile = [IO.Path]::GetTempFileName()
  try {
    [IO.File]::WriteAllBytes($inFile, $Utf8NoBom.GetBytes([string]$StdinText))
    $spawn = @{
      FilePath               = $exe.Source
      NoNewWindow            = $true
      PassThru               = $true
      ErrorAction            = 'SilentlyContinue'
      RedirectStandardInput  = $inFile
      RedirectStandardOutput = $outFile
      RedirectStandardError  = $errFile
    }
    $argLine = (@($CommandArgs | ForEach-Object { ConvertTo-NativeArgument $_ }) -join ' ')
    if ($argLine) { $spawn['ArgumentList'] = $argLine }
    if ($WorkingDirectory) { $spawn['WorkingDirectory'] = $WorkingDirectory }
    $proc = Start-Process @spawn
    if (-not $proc) { return $null }
    $null = $proc.Handle
    $proc.WaitForExit()
    return @{ ExitCode = $proc.ExitCode; Stdout = [IO.File]::ReadAllText($outFile, $Utf8NoBom) }
  }
  catch { return $null }
  finally { Remove-Item -LiteralPath $inFile, $outFile, $errFile -Force -ErrorAction SilentlyContinue }
}

<#
.SYNOPSIS
Split a native command's stdout into lines the way PowerShell's OWN native-output enumeration did:
one trailing newline terminates the last line, it does not add an empty one.
.DESCRIPTION
Keeping that rule in one place is what makes the move off `& command` a mechanical 1:1 port - every
call site below reads `$lines[0]` / `-join` exactly as it did when PowerShell produced the array.
.PARAMETER Text
Raw stdout as returned by Invoke-NativeUtf8.
.OUTPUTS
System.String[] - the lines; an empty array when the command printed nothing.
#>
function ConvertTo-NativeLines([string]$Text) {
  if (-not $Text) { return , @() }
  return , @(($Text -creplace '\r?\n$', '') -split '\r?\n')
}

<#
.SYNOPSIS
Write text to stdout as raw UTF-8 bytes, bypassing [Console]::Out and its code page entirely.
.PARAMETER Text
The already-assembled output - a JSON envelope, or the status line.
.OUTPUTS
None. Writes bytes to the standard output stream.
#>
function Write-Stdout([string]$Text) {
  $bytes = $Utf8NoBom.GetBytes($Text)
  $stream = [Console]::OpenStandardOutput()
  $stream.Write($bytes, 0, $bytes.Length)
  $stream.Flush()
}

# Drain stdin (Claude Code convention; not evaluated here) - through the prologue's reader, never
# the console's own reader, so the drain cannot fail on a payload byte the console code page has no
# mapping for.
[void]$StdInUtf8.ReadToEnd()

# Optional throttle: skip sync if the last run is fresher than AGENT_CORE_SYNC_THROTTLE_SEC
# seconds. Default 0 = sync on every session start.
# Example: $env:AGENT_CORE_SYNC_THROTTLE_SEC = 3600  # at most once per hour
$throttle = 0
if ($env:AGENT_CORE_SYNC_THROTTLE_SEC) {
    [int]::TryParse($env:AGENT_CORE_SYNC_THROTTLE_SEC, [ref]$throttle) | Out-Null
}
$homeDir = if ($env:USERPROFILE) { $env:USERPROFILE } else { $HOME }
$marker = Join-Path $homeDir '.claude/hooks/.last-global-sync'
$skipSync = $false

if ($throttle -gt 0) {
    $now = [DateTimeOffset]::Now.ToUnixTimeSeconds()
    $last = [long]0
    if (Test-Path -LiteralPath $marker) {
        [long]::TryParse((Get-Content -LiteralPath $marker -Raw -ErrorAction SilentlyContinue), [ref]$last) | Out-Null
    }
    # Throttled: skip the sync, but do NOT exit - an unresolved warning from the last run is still
    # unresolved, and throttling a sync must not throttle the report about it (see the block below).
    if (($now - $last) -lt $throttle) { $skipSync = $true }
}

# Invocation strategy - try in order, all output discarded, never fail the session:
#   1. agent-core on PATH  ->  use it directly
#   2. node dist/cli.js    ->  use the baked-in PKG_ROOT path
#   3. neither found       ->  silent no-op (machines without a checkout)
# The sync inherits CLAUDE_PROJECT_DIR, which Claude Code exports into every hook process, and
# REPORTS agent-core session-default keys pinned in that project's .claude/settings.json (ADR-0050,
# issue #69). Nothing is passed on the command line on purpose: an older agent-core on PATH would
# reject an unknown flag - silently, behind `*> $null` - and skip the whole sync; an unknown
# environment variable it simply ignores.
$synced = $false
if (-not $skipSync) {
    if (Get-Command agent-core -ErrorAction SilentlyContinue) {
        & agent-core sync --scope global *> $null
        $synced = $true
    } elseif (Test-Path -LiteralPath 'C:/Entwicklung/claude-skills/dist/cli.js') {
        & node 'C:/Entwicklung/claude-skills/dist/cli.js' sync --scope global *> $null
        $synced = $true
    }
}

# Update the throttle marker after a successful sync attempt.
if ($synced -and $throttle -gt 0) {
    $now = [DateTimeOffset]::Now.ToUnixTimeSeconds()
    Set-Content -LiteralPath $marker -Value $now -ErrorAction SilentlyContinue
}

# --- THE LOUD CHANNEL, DURABLE HALF (ADR-0050) --------------------------------------------------
# The two invocations above discard every stream with `*> $null`, deliberately: one sync prints ~122
# progress bullets that have no business in a session. But the sync's WARNINGS travelled on that same
# stderr, so on the path that runs on every machine at every session start they were unreachable by
# construction - any promise of "we warn loudly" made over stderr alone could never meet its own
# precondition, while looking like it did.
#
# The sync now also leaves those warnings as a READY-MADE SessionStart envelope next to the manifest,
# and this hook copies those bytes to its own stdout. It builds no JSON and escapes nothing: the
# escaping happens ONCE, in the CLI, instead of twice in two shell dialects that this repo has
# measured drifting into OPPOSITE verdicts on identical input. That is also why this file and its
# .sh twin can be read side by side and say the same thing - neither of them formats anything.
#
# An absent (or empty) file is the "nothing to report" state - the sync REMOVES it on every clean
# run, so a stale block can never be replayed as if it were current. A corrupt file is fail-open:
# Claude Code ignores hook output it cannot parse, exactly as it does today for a silent hook.
#
# A THROTTLED run replays the LAST artifact - and the global sync puts a warning about the project
# the session opened into it (a pinned session default). Replayed into a session of ANOTHER project,
# that warning would name a file the session never touched as its own. The sync therefore records the
# project such an artifact is bound to in a plain-text sidecar (absent when nothing is project-bound),
# and a throttled run replays a bound artifact only into the same project. Plain string equality on
# purpose - no JSON parsing here, none in the twin. Trailing newlines are stripped exactly like the
# .sh twin's $(cat ...) strips them, or the two would disagree on a sidecar ending in a newline.
$warn = Join-Path $homeDir '.claude/.agent-core-warnings.json'
$emit = $true
if ($skipSync) {
    $bound = ''
    $boundFile = Join-Path $homeDir '.claude/.agent-core-warnings.project'
    if (Test-Path -LiteralPath $boundFile) {
        try { $bound = [IO.File]::ReadAllText($boundFile, $Utf8NoBom) } catch { $bound = '' }
    }
    $bound = $bound -replace '\n+$', ''
    if ($bound -and ($bound -cne [string]$env:CLAUDE_PROJECT_DIR)) { $emit = $false }
}
if ($emit -and (Test-Path -LiteralPath $warn)) {
    $text = ''
    try { $text = [IO.File]::ReadAllText($warn, $Utf8NoBom) } catch { $text = '' }
    if ($text.Trim()) { Write-Stdout $text }
}

exit 0
