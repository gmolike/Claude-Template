# Claude Code PreToolUse hook (PowerShell variant): main-chat orchestrator guard.
# LAUNCHER: `powershell -NoProfile -ExecutionPolicy Bypass -File <this>.ps1` (src/targets/claude.ts) -
# Windows PowerShell 5.1, NOT `pwsh`. `-NoProfile` is load-bearing HERE in particular, and this is a
# REASON rather than a measurement: a profile runs before the script and shares its stdout, so
# anything a profile PRINTS (banner, oh-my-posh, update notice) lands AHEAD of the envelope below and
# JSON.parse dies on the first token - the deny decision is then simply lost. The reference machine
# has no PowerShell profile (all four $PROFILE paths Test-Path False, and $PROFILE derives from the
# MyDocuments known folder, so one cannot be planted outside the real user directory for a test), so
# the corrupting case is shown by an explicitly labelled SIMULATION in ADR-0027, not claimed as a
# measurement here. There is deliberately no shebang: nothing ever execs
# this file, and the old `#!/usr/bin/env pwsh` named an interpreter that is not installed on the
# target machines - since ADR-0027 a UTF-8 BOM precedes the first line in the DEPLOYED copy anyway.
# 1:1 port of orchestrator-guard.sh for Windows machines where Claude Code routes hook
# commands through PowerShell (Git Bash optional / absent). Denies Edit/Write in the MAIN
# Claude session so the orchestrator delegates all implementation to subagents.
#
# Decision order - CHARACTER-IDENTICAL to orchestrator-guard.sh; change both together:
#   (a) top-level agent_id present   -> ALLOW (exit 0, no output). Never deadlock a subagent.
#   (b) payload UNREADABLE           -> ALLOW + a top-level "systemMessage": fail-open by design
#                                       (ADR-0012), but never SILENTLY - the message says the guard
#                                       did not enforce this call (30-quality "fail loud").
#                                       PRECONDITION, stated because it does not always hold: only a
#                                       PRECISE stage (jq or node) can tell "not JSON at all" apart
#                                       from "JSON without agent_id". With NEITHER installed the
#                                       tolerant stage classifies an unparsable payload as `main`, so
#                                       it is DENIED, not allowed - and (d) then says exactly that.
#   (c) audited emergency marker set -> ALLOW + a top-level "systemMessage" (shown to the user)
#                                       naming the reason, the remaining TTL and how to remove the
#                                       marker. Every permitted inline edit announces itself.
#   (d) otherwise                    -> DENY; the reason ALSO spells out the escape hatch, says why a
#                                       marker that WAS found does not count, and - when no precise
#                                       parser existed - that this verdict came from the tolerant
#                                       stage, which cannot see an unparsable payload at all.
#
# PAYLOAD CASCADE - identical in both variants, so both classify a payload the same way:
#   jq (precise) -> node -e (precise, SINGLE-LINE) -> regex (tolerant, last resort). Every stage
#   reports WHICH KIND decided (`precise` | `tolerant`) alongside the verdict, so (b)/(d) above can
#   name the difference out loud instead of quietly changing direction. ConvertFrom-Json
#   is deliberately NOT used: a parser only this variant has is exactly how the two files drifted
#   apart before (verified: unparsable payload allowed here, denied by the .sh). RESIDUAL RISK, regex
#   stage only: it matches "agent_id" ANYWHERE, including nested inside tool_input - a main-session
#   Edit whose CONTENT holds that literal would be waved through. It is reached only when neither jq
#   nor node exists; both precise stages read the TOP-LEVEL field only. Documented in ADR-0023.
#
# CASCADE TEST COVERAGE - stage 2 (node) and stage 3 (regex, forced by removing node+jq from PATH)
#   are proven by real runs of BOTH variants. Stage 1 (jq) is proven only against a jq STUB put on
#   PATH by the suite (jq is not installed on the reference machine); a REAL jq binary is NOT covered
#   by any test. src/targets/claude.test.ts names this in its describe title; ADR-0023 records it.
#
# CONSOLE ENCODING - Windows PowerShell 5.1 defaults to the OEM code page (measured here: ibm850 for
#   [Console]::InputEncoding/OutputEncoding, us-ascii for $OutputEncoding). Left alone, that produced
#   "one payload, two answers" for any non-ASCII input: a repo path with an umlaut came back from
#   `git rev-parse` as CP850 mojibake, so Test-Path was False and a VALID marker was never found
#   (.sh ALLOW vs .ps1 DENY); and a GERMAN reason (the normal case per rule 40-language) was emitted
#   in CP850 - best-fit mapping even turned typographic quotes into a RAW `"` AFTER JSON escaping and
#   destroyed the envelope. Every channel is therefore pinned to UTF-8 PROCESS-LOCALLY: an own stdin
#   reader, an own stdout byte writer, and file-redirected child I/O for git/jq/node. Nothing
#   here writes [Console]::InputEncoding / [Console]::OutputEncoding any more - those setters call
#   SetConsoleCP / SetConsoleOutputCP and would rewrite the code page of the user's console for the
#   rest of the session (measured: 850/850 -> 65001/65001 across one hook run). See the prologue.
#
# The emergency marker (ADR-0023):
#   file : "$(git rev-parse --git-dir)/agent-core-emergency-inline" - never the literal ".git/..."
#          (`.git` is a FILE in a worktree). Content = the MANDATORY reason; empty/whitespace-only
#          does NOT grant permission. TTL = 60 min from mtime; expired does NOT grant permission.
#          Remaining TTL is rounded UP, the overdue minutes of an EXPIRED marker (elapsed time) DOWN.
#          The path is printed with forward slashes, so both variants emit the same audit line.
#   env  : AGENT_CORE_EMERGENCY_INLINE - value is the reason ("1" stays valid, reported as
#          "no reason given"). Checked after the file - also when the file exists but is empty or
#          expired. No mtime, hence no TTL.
#
# FAIL-OPEN: on any parse/IO problem, allow - but loudly (never deadlock edits because of a guard
# defect, and never pretend the guard checked when it did not).
$ErrorActionPreference = 'SilentlyContinue'
$TtlSeconds = 3600
$MarkerName = 'agent-core-emergency-inline'

# --- deterministic UTF-8 I/O, BEFORE anything is read or written ----------------------------------
# The three-line block below is ONE shared form - byte-for-byte the same in every agent-core .ps1
# hook that decodes non-ASCII text - the roster is PS_WITH_PROLOGUE in
# src/targets/claude.test.ts, which pins the block byte-for-byte with a lockstep test. Deliberately
# NOT enumerated here: a hand-kept list of names in every header is what drifts the moment a hook is
# added, which is how improvement-reflect.ps1 and worktree-bootstrap.ps1 first went unclassified.
# Every statement in it is PROCESS-LOCAL: none of them touches the console.
#   $OutputEncoding  a PowerShell VARIABLE, not a console API - the encoding of text piped INTO a
#                    native command. Default us-ascii turned a non-ASCII payload into "?" before a
#                    piped node/jq saw it; best-fit mapping of the German quotes even produced a RAW
#                    `"`. Measured side-effect-free with GetConsoleCP/GetConsoleOutputCP across a
#                    child process (850/850 before, 850/850 after).
#   $StdInUtf8       stdin is read through OUR OWN reader on [Console]::OpenStandardInput(), never
#                    [Console]::In, so decoding depends on no console setting at all. Also measured
#                    side-effect-free (850/850 before and after).
# NOT here any more, and this is the point: [Console]::InputEncoding / [Console]::OutputEncoding were
# assigned until ADR-0027 R2. Their setters call SetConsoleCP / SetConsoleOutputCP, i.e. they rewrite
# the code page of the console the hook INHERITED - permanently, for every later process in it.
# Measured from a separate process around one hook run: before ConsoleCP=850 ConsoleOutputCP=850,
# after 65001/65001, exit 0 - while all three channels were redirected ([Console]::IsInputRedirected
# = True), so the old comment's "only when a channel is NOT redirected" was false as written. A
# PreToolUse guard fires on every edit; it must not reconfigure the user's terminal.
# The two channels that really needed those setters are covered process-locally below instead:
# Invoke-NativeUtf8 gives each git/jq/node CHILD file-redirected I/O it decodes itself, Write-Stdout
# emits the envelope as raw UTF-8 bytes.
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$OutputEncoding = $Utf8NoBom
$StdInUtf8 = New-Object System.IO.StreamReader([Console]::OpenStandardInput(), $Utf8NoBom)

# --- process-local native I/O helpers -------------------------------------------------------------
# The block from ConvertTo-NativeArgument down to the end of Write-Stdout is the SECOND shared form:
# byte-for-byte identical in every hook that reads a native command's stdout or writes its own
# - roster PS_WITH_NATIVE_IO in
# src/targets/claude.test.ts - and pinned by the same lockstep test.
# format-on-edit.ps1 carries the prologue but not this block - it reads no native output and writes
# no stdout, so there is nothing here for it to keep in step.

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

# Precise stage-2 classifier - the SAME source line as NODE_CLASSIFIER in orchestrator-guard.sh.
# Free of ", $ and backticks, so it is safe verbatim in a bash AND a PowerShell double-quoted string.
$NodeClassifier = "let s='';process.stdin.on('data',function(d){s+=d}).on('end',function(){var v;try{v=JSON.parse(s)}catch(e){process.stdout.write('unparsable');return}var a=(v&&typeof v==='object'&&Array.isArray(v)===false)?v.agent_id:null;var t=(a===null||a===undefined||a===false)?'':String(a);process.stdout.write(t.trim()?'agent':'main')})"

<#
.SYNOPSIS
Escape a string for embedding inside a JSON string literal (same normalization as the .sh helper).
.PARAMETER Value
Raw text, possibly containing control characters, backslashes or double quotes.
.OUTPUTS
System.String - control characters flattened to spaces/dropped, backslash and quote escaped.
#>
function Format-JsonString([string]$Value) {
  $t = $Value -replace "[`r`n`t]", ' '
  $t = $t -replace '[\x00-\x1f]', ''
  $t = $t -replace '\\', '\\'
  $t = $t -replace '"', '\"'
  return $t
}

<#
.SYNOPSIS
Collapse a string to a single trimmed line (mirrors trim_line in the .sh variant).
.PARAMETER Value
Raw text.
.OUTPUTS
System.String - whitespace-collapsed and trimmed; empty when the input held only whitespace.
#>
function Format-TrimLine([string]$Value) {
  if (-not $Value) { return '' }
  return ($Value -replace "[`r`n`t]", ' ').Trim()
}

<#
.SYNOPSIS
Render a filesystem path with forward slashes (mirrors norm_path in the .sh variant).
.PARAMETER Value
Path in platform-native form.
.OUTPUTS
System.String - the same path with every backslash replaced by a forward slash.
#>
function Format-Path([string]$Value) {
  return ($Value -replace '\\', '/')
}

<#
.SYNOPSIS
Classify the PreToolUse payload via the shared jq -> node -> regex cascade.
.DESCRIPTION
Returns the verdict AND the kind of stage that produced it, so the caller can say out loud when a
verdict came from the tolerant stage - which cannot distinguish an unparsable payload from a
main-session one, and therefore silently inverts the documented "unparsable -> allow" direction.
.PARAMETER Raw
The raw payload text read from stdin.
.OUTPUTS
System.String - "<verdict> <stage>": verdict is agent | main | unparsable, stage is precise |
tolerant. The SAME two-token contract as classify_payload in orchestrator-guard.sh.
#>
function Get-PayloadVerdict([string]$Raw) {
  # Both precise stages run through Invoke-NativeUtf8: it resolves the command itself (so a missing
  # jq/node yields $null and the cascade falls through, exactly as the old `Get-Command` probe did),
  # writes the payload as UTF-8 BYTES and reads the answer back as UTF-8 - all without a console.
  $jq = Invoke-NativeUtf8 'jq' @('-r', 'objects | .agent_id // empty') $Raw
  if ($jq -and $jq.ExitCode -eq 0) {
    $jqLines = ConvertTo-NativeLines $jq.Stdout
    if (Format-TrimLine ($jqLines -join ' ')) { return 'agent precise' } else { return 'main precise' }
  }
  $node = Invoke-NativeUtf8 'node' @('-e', $NodeClassifier) $Raw
  if ($node) {
    $nodeOut = ((ConvertTo-NativeLines $node.Stdout) -join '')
    if ($nodeOut -eq 'agent' -or $nodeOut -eq 'main' -or $nodeOut -eq 'unparsable') { return "$nodeOut precise" }
  }
  # Last resort - tolerant, and blind to nesting (see RESIDUAL RISK in the header).
  if ($Raw -match '"agent_id"\s*:\s*"[^"]+"') { return 'agent tolerant' }
  return 'main tolerant'
}

<#
.SYNOPSIS
Write the PreToolUse hook decision to stdout as the documented JSON envelope.
.PARAMETER Decision
"allow" or "deny" (permissionDecision).
.PARAMETER Reason
permissionDecisionReason text.
.PARAMETER SystemMessage
Optional top-level systemMessage - the LOUD channel that is displayed to the user.
.OUTPUTS
None. Writes JSON to stdout.
#>
function Write-Decision([string]$Decision, [string]$Reason, [string]$SystemMessage) {
  $r = Format-JsonString $Reason
  if ($SystemMessage) {
    $m = Format-JsonString $SystemMessage
    Write-Stdout ('{"systemMessage":"' + $m + '","hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"' + $Decision + '","permissionDecisionReason":"' + $r + '"}}')
  }
  else {
    Write-Stdout ('{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"' + $Decision + '","permissionDecisionReason":"' + $r + '"}}')
  }
}

# --- (a)/(b) who is calling? ----------------------------------------------------------------------
# Read stdin through the explicit UTF-8 reader from the prologue - never [Console]::In.
$raw = $StdInUtf8.ReadToEnd()
$classified = (Get-PayloadVerdict $raw) -split ' ', 2
$verdict = $classified[0]
$stage = $classified[1]
if ($verdict -eq 'agent') { exit 0 }                    # subagent -> allow
if ($verdict -eq 'unparsable') {
  Write-Decision 'allow' `
    'Guard could not parse the PreToolUse payload - failing open (allow) instead of blocking work. This call was NOT checked against the delegate-only posture.' `
    '[agent-core] orchestrator-guard could NOT read the PreToolUse payload (no jq/node parser succeeded) - the delegate-only guard did NOT enforce this call. Fail-open by design (ADR-0012); if this repeats, the payload shape changed and the guard needs fixing.'
  exit 0
}

# --- (c) audited emergency override ---------------------------------------------------------------
$reason = ''
$sourceDesc = ''
$remainingDesc = ''
$markerPath = ''
$markerState = ''   # '' | empty | expired
$markerDetail = ''

# The one native-command OUTPUT this hook reads, and the one that used to arrive as CP850 mojibake
# for an umlaut repo path. Invoke-NativeUtf8 decodes it as UTF-8 per CHILD process; the exit-code
# fallback mirrors the `.sh`'s `git ... || git ...` chain rather than only testing for empty stdout.
$absRun = Invoke-NativeUtf8 'git' @('rev-parse', '--absolute-git-dir')
$gitDir = if ($absRun -and $absRun.ExitCode -eq 0) { @(ConvertTo-NativeLines $absRun.Stdout)[0] } else { '' }
if (-not $gitDir) {
  $relRun = Invoke-NativeUtf8 'git' @('rev-parse', '--git-dir')
  $gitDir = if ($relRun -and $relRun.ExitCode -eq 0) { @(ConvertTo-NativeLines $relRun.Stdout)[0] } else { '' }
}
if ($gitDir) {
  $markerFile = Join-Path ($gitDir.Trim()) $MarkerName
  $markerPath = Format-Path $markerFile
  if (Test-Path -LiteralPath $markerFile -PathType Leaf) {
    $trimmed = Format-TrimLine ([IO.File]::ReadAllText($markerFile))
    if (-not $trimmed) {
      $markerState = 'empty'
    }
    else {
      $mtime = (Get-Item -LiteralPath $markerFile).LastWriteTime
      if (-not $mtime) {
        # Fail-open, but LOUD: without a usable mtime the TTL cannot be enforced, so say so.
        $reason = $trimmed
        $sourceDesc = $markerPath
        $remainingDesc = 'TTL NOT verifiable here (no usable stat/date) - remove the marker by hand'
      }
      else {
        $age = [int][Math]::Floor(([DateTime]::Now - $mtime).TotalSeconds)
        if ($age -gt $TtlSeconds) {
          $markerState = 'expired'
          $markerDetail = [int][Math]::Floor(($age - $TtlSeconds) / 60)   # elapsed -> round DOWN
        }
        else {
          $reason = $trimmed
          $sourceDesc = $markerPath
          $remainingDesc = 'expires in ' + [int][Math]::Ceiling(($TtlSeconds - $age) / 60) + ' min'   # remaining -> round UP
        }
      }
    }
  }
}

if (-not $reason) {
  $envTrimmed = Format-TrimLine $env:AGENT_CORE_EMERGENCY_INLINE
  if ($envTrimmed) {
    $reason = if ($envTrimmed -eq '1') { 'no reason given' } else { $envTrimmed }
    $sourceDesc = 'env AGENT_CORE_EMERGENCY_INLINE'
    $remainingDesc = 'no TTL on the env fallback - unset it when the incident is over'
  }
}

if ($reason) {
  Write-Decision 'allow' `
    'Emergency inline override active (audited marker) - the delegate-only guard was bypassed on purpose.' `
    "[agent-core] EMERGENCY INLINE EDIT allowed - the delegate-only guard was bypassed. Reason: $reason. Marker: $sourceDesc ($remainingDesc). Remove it the moment delegation works again."
  exit 0
}

# --- (d) deny, and point at the legitimate way out ------------------------------------------------
$note = ''
if ($markerState -eq 'empty') {
  $note = " An emergency marker exists at $markerPath but is EMPTY - a marker without a written reason does NOT grant permission."
}
elseif ($markerState -eq 'expired') {
  $note = " The emergency marker at $markerPath EXPIRED $markerDetail min ago (TTL 60 min) - it does NOT grant permission; rewrite it with a current reason to re-arm."
}
# Fail LOUD about the one precondition of decision (b): without jq AND without node the tolerant
# stage cannot see an unparsable payload, so such a payload lands HERE (deny) instead of in the
# documented fail-open branch. Never let that swap happen quietly (30-quality).
$parserNote = ''
if ($stage -eq 'tolerant') {
  $parserNote = ' NOTE: neither jq nor node was available, so this payload was classified by the tolerant regex stage, which cannot tell an UNPARSABLE payload from a main-session one - on this machine an unparsable payload is DENIED here rather than allowed with a fail-open warning (ADR-0023).'
}
Write-Decision 'deny' ('Main chat is orchestrator-only: editing tools are denied for the main session. Delegate this change to a subagent (Task) or a Workflow.' + $note + $parserNote + ' Genuine emergency (delegation itself is unavailable)? Open the audited escape hatch: printf ''why'' > "$(git rev-parse --git-dir)/' + $MarkerName + '" - it allows inline edits for 60 min, announces every single one, and must be deleted afterwards (env fallback: AGENT_CORE_EMERGENCY_INLINE="why").')
exit 0
