# Claude Code PreToolUse hook (PowerShell variant): feedback-loop reflect nudge.
# LAUNCHER: `powershell -NoProfile -ExecutionPolicy Bypass -File <this>.ps1` (src/targets/claude.ts) -
# Windows PowerShell 5.1, NOT `pwsh`. There is deliberately no shebang: nothing ever execs this file,
# the old `#!/usr/bin/env pwsh` named an interpreter that is not installed on the target machines, and
# since ADR-0027 a UTF-8 BOM precedes the first line in the DEPLOYED copy anyway.
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

# --- deterministic UTF-8 I/O, BEFORE anything is read or written ----------------------------------
# The three-line block below is ONE shared form - byte-for-byte the same in every agent-core .ps1 hook
# that decodes non-ASCII text, pinned as such by a lockstep test in src/targets/claude.test.ts. Every
# statement in it is PROCESS-LOCAL: none of them touches the console, so nothing here rewrites the
# code page of the terminal the hook INHERITED (that is what the removed [Console]::InputEncoding /
# [Console]::OutputEncoding setters did - ADR-0027 R2). Load-bearing here because the payload carries
# a `command` string that routinely holds a non-ASCII path or a German commit message: read through
# [Console]::In it would arrive as CP850 mojibake, and ConvertFrom-Json would then decide on text this
# hook never received.
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$OutputEncoding = $Utf8NoBom
$StdInUtf8 = New-Object System.IO.StreamReader([Console]::OpenStandardInput(), $Utf8NoBom)

# --- process-local native I/O helpers -------------------------------------------------------------
# The block from ConvertTo-NativeArgument down to the end of Write-Stdout is the SECOND shared form:
# byte-for-byte identical in every hook that reads a native command's stdout or writes its own, and
# pinned by the same lockstep test. This hook runs NO native command, so only Write-Stdout is reached;
# it is carried whole rather than hand-copied because a hand copy of the one function it does use is
# precisely how the two forms drift apart.

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

# Read stdin through the explicit UTF-8 reader from the prologue - never [Console]::In.
$raw = $StdInUtf8.ReadToEnd()
try { $j = $raw | ConvertFrom-Json } catch { exit 0 }   # fail-open -> silent
if ($j.agent_id) { exit 0 }                             # gate 1: subagent -> silent
$cmd = $j.tool_input.command
if (-not ($cmd -cmatch 'git\s+(commit|push)')) { exit 0 }  # gate 2: not git commit/push -> silent

# Emit the nudge through Write-Stdout, i.e. as raw UTF-8 bytes, so it survives regardless of the
# console's output encoding (Windows PowerShell 5.1 does not default to UTF-8). The em-dash is built
# at RUNTIME from its code point ([char]0x2014) so this SOURCE file stays pure ASCII: PS 5.1 reads a
# BOM-less .ps1 as ANSI (cp1252), which would mis-decode a literal UTF-8 em-dash in the source and
# double-encode it. Keeping the source ASCII sidesteps that entirely and makes the bytes
# byte-identical to improvement-reflect.sh.
$emDash = [char]0x2014
$json = '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"agent-core-Reflexion faellig? Falls diese Session eine Regel/Skill/Hook-Verbesserung aufgedeckt hat: 22-session-close Schritt 6 ' + $emDash + ' dedup + gh issue create --label skill-improvement, niemals inline."}}'
Write-Stdout $json
exit 0
