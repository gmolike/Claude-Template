# Claude Code PreToolUse hook (PowerShell variant): multi-session push-target reminder.
# LAUNCHER: `powershell -NoProfile -ExecutionPolicy Bypass -File <this>.ps1` (src/targets/claude.ts) -
# Windows PowerShell 5.1, NOT `pwsh`. `-NoProfile` is load-bearing HERE in particular, and this is a
# REASON rather than a measurement: a profile runs before the script and shares its stdout, so
# anything a profile PRINTS (banner, oh-my-posh, update notice) lands AHEAD of the envelope below and
# JSON.parse dies on the first token - the reminder is then simply lost. The reference machine has no
# PowerShell profile (all four $PROFILE paths Test-Path False, and $PROFILE derives from the
# MyDocuments known folder, so one cannot be planted outside the real user directory for a test), so
# the corrupting case is shown by an explicitly labelled SIMULATION in ADR-0027, not claimed as a
# measurement here. There is deliberately no shebang: nothing ever execs
# this file, and the old `#!/usr/bin/env pwsh` named an interpreter that is not installed on the
# target machines - since ADR-0027 a UTF-8 BOM precedes the first line in the DEPLOYED copy anyway.
# 1:1 port of origin-divergence-check.sh for Windows machines where Claude Code routes hook commands
# through PowerShell (Git Bash optional / absent). Matcher "Bash"; acts only on a `git push`.
#
# Two Claude sessions cannot see each other. Verified: two parallel sessions built wave 1 TWICE,
# divergently, and nothing caught it but a manual `git log` diff (rule 26-autonomy, ADR-0025).
#
# WHICH REF IS COMPARED - identical to the .sh (see there for the measurements):
#   PRIMARY: the current branch's UPSTREAM (@{upstream}) - the ref this push actually updates.
#   INFO   : origin/<default-branch>, only when it is not already the primary ref AND holds commits
#            HEAD lacks AND there is a primary finding to attach it to - or when the branch has NO
#            upstream, where it is the only thing that can be said. A routine feature push whose
#            upstream is in sync stays SILENT even after the default branch moved.
# WHAT IT CLAIMS - only what it measured: which ref, how many commits, taken after a fetch. Never WHO
# pushed or WHY: that reading belongs to the human.
#
# NEVER BLOCKS - by construction, and the choice is deliberate (live hook docs, fetched 2026-07-23):
#   - nothing to say -> exit 0 with NO output. "Exit code 0 with no output means the hook has no
#     decision to report, so the tool call continues through the normal permission flow."
#   - a finding      -> a top-level "systemMessage" (the documented warning channel that surfaces to
#     the user without blocking) PLUS an explicit permissionDecision "defer" ("defers the decision to
#     the normal permission flow"). Both silence and "defer" are non-blocking; "defer" is chosen for
#     the reporting path so the emitted JSON itself proves the hook deliberately made no decision and
#     cannot be misread as a forgotten field. "allow" would be WRONG - it auto-approves the push and
#     bypasses the permission system. "deny"/"ask" are never emitted anywhere in this script.
# Fail-open everywhere: no parser, no git, no repo, no origin, a failed fetch -> silent exit 0.
#
# PAYLOAD CASCADE - the SAME shape as orchestrator-guard.ps1, and every stage reads BOTH fields:
#   jq (precise) -> node -e (precise, SINGLE-LINE) -> regex (tolerant, last resort). ConvertFrom-Json
#   is deliberately NOT used: a parser only this variant has is exactly how the two files drifted
#   apart before. Reading only ONE field was the whole bug on the .sh side - `cwd` went unread there,
#   so git ran in the HOOK PROCESS's directory instead of the session's.
#
# The payload's cwd is the ONLY repo this hook ever inspects - every git call goes through
# `git -C <cwd>`, and an unusable cwd means silent exit, never a fallback to the process directory.
# `.git` is NEVER addressed literally (it is a FILE in a worktree): repo detection goes through
# `git rev-parse --git-dir`. The default branch is derived from origin/HEAD, falling back to `main`.
#
# CONSOLE ENCODING - Windows PowerShell 5.1 defaults to the OEM code page (measured here: ibm850 for
#   [Console]::InputEncoding/OutputEncoding, us-ascii for $OutputEncoding). Left alone, this hook went
#   COMPLETELY SILENT whenever the payload `cwd` held a non-ASCII character while the .sh reported
#   normally - one payload, two answers: stdin was decoded as CP850, the path was piped on to node as
#   us-ascii (U+00E4 -> "?"), so `Test-Path -LiteralPath` failed and the script exited 0 with no output.
#   Every channel is pinned to UTF-8 PROCESS-LOCALLY: an own stdin reader, an own stdout byte writer,
#   and file-redirected child I/O for git/jq/node. Nothing here writes [Console]::InputEncoding
#   / [Console]::OutputEncoding any more - those setters call SetConsoleCP / SetConsoleOutputCP and
#   would rewrite the code page of the user's console for the rest of the session (measured: 850/850
#   -> 65001/65001 across one hook run). See the prologue.
#
# Decisions and strings are CHARACTER-IDENTICAL to origin-divergence-check.sh - change both together.
$ErrorActionPreference = 'SilentlyContinue'
$FetchTimeoutSeconds = 10

# --- deterministic UTF-8 I/O, BEFORE anything is read or written ----------------------------------
# The three-line block below is ONE shared form - byte-for-byte the same in every agent-core .ps1
# hook that decodes non-ASCII text - the roster is PS_WITH_PROLOGUE in
# src/targets/claude.test.ts, which pins the block byte-for-byte with a lockstep test. Deliberately
# NOT enumerated here: a hand-kept list of names in every header is what drifts the moment a hook is
# added, which is how improvement-reflect.ps1 and worktree-bootstrap.ps1 first went unclassified.
# Every statement in it is PROCESS-LOCAL: none of them touches the console.
#   $OutputEncoding  a PowerShell VARIABLE, not a console API - the encoding of text piped INTO a
#                    native command. Default us-ascii turned a non-ASCII `cwd` into "?" before a
#                    piped node/jq saw it. Measured side-effect-free with
#                    GetConsoleCP/GetConsoleOutputCP across a child process (850/850 before and after).
#   $StdInUtf8       stdin is read through OUR OWN reader on [Console]::OpenStandardInput(), never
#                    [Console]::In, so decoding depends on no console setting at all. Also measured
#                    side-effect-free (850/850 before and after).
# NOT here any more, and this is the point: [Console]::InputEncoding / [Console]::OutputEncoding were
# assigned until ADR-0027 R2. Their setters call SetConsoleCP / SetConsoleOutputCP, i.e. they rewrite
# the code page of the console the hook INHERITED - permanently, for every later process in it.
# Measured from a separate process around one hook run: before ConsoleCP=850 ConsoleOutputCP=850,
# after 65001/65001, exit 0 - while all three channels were redirected ([Console]::IsInputRedirected
# = True), so the old comment's "only when a channel is NOT redirected" was false as written. A
# PreToolUse hook fires on every Bash call; it must not reconfigure the user's terminal.
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

# Precise stage-2 decoder - the SAME source line as NODE_DECODER in origin-divergence-check.sh.
# Free of ", $, backticks and backslashes, so it is safe verbatim in a bash AND a PowerShell string.
$NodeDecoder = "let s='';process.stdin.on('data',function(d){s+=d}).on('end',function(){var v;try{v=JSON.parse(s)}catch(e){process.stdout.write('unparsable');return}var o=(v&&typeof v==='object'&&Array.isArray(v)===false)?v:{};var i=(o.tool_input&&typeof o.tool_input==='object')?o.tool_input:{};var n=String.fromCharCode(10);var f=function(x){if(typeof x!=='string')return '';var r='';for(var k=0;k<x.length;k++){var c=x.charCodeAt(k);r+=(c<32)?' ':x.charAt(k)}return r};process.stdout.write('ok'+n+f(o.cwd)+n+f(i.command))})"

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
Collapse every control character to a space (mirrors flatten() in the .sh variant), so all three
decode stages hand on ONE line and both variants regex-match exactly the same text.
.PARAMETER Value
Raw decoded field value.
.OUTPUTS
System.String - the same text with every character below 0x20 replaced by a space.
#>
function Format-Flat([string]$Value) {
  if (-not $Value) { return '' }
  return ($Value -creplace '[\x00-\x1f]', ' ')
}

<#
.SYNOPSIS
Last-resort extraction of a JSON string value by key, minimally un-escaped (mirrors json_field()).
.PARAMETER Raw
The raw payload text.
.PARAMETER Key
JSON key whose first string value is wanted.
.OUTPUTS
System.String - the decoded value, or '' when the key is absent.
#>
function Get-JsonField([string]$Raw, [string]$Key) {
  $m = [regex]::Match($Raw, '"' + $Key + '"\s*:\s*"(([^"\\]|\\.)*)"')
  if (-not $m.Success) { return '' }
  $v = $m.Groups[1].Value
  $v = $v -creplace '\\"', '"'
  $v = $v -creplace '\\/', '/'
  $v = $v -creplace '\\\\', '\'
  return $v
}

<#
.SYNOPSIS
Run git in a repository and return its first output line, or $null when it exited non-zero.
.DESCRIPTION
The whole stdout is materialized BEFORE the exit code is read, and `Select-Object -First 1` is
deliberately NOT used: it stops the upstream pipeline the moment it holds an object, which tears
down the still-running native command and makes the recorded exit code non-deterministic. Measured
on `git rev-parse --verify --quiet @{upstream}` against a clone that demonstrably HAS an upstream:
the `Select-Object` form reported "no upstream" in 3 of 250 runs, this form in 0 of 250. The `.sh`
reads `$(...)`, which always captures fully - so the two variants disagreed at random, and the
parity assertion went red roughly every third full suite. This helper makes both read alike, and
Invoke-NativeUtf8 keeps the property structurally: it reads the child's stdout to the end and then
takes $proc.ExitCode, so no pipeline can be torn down early and no $LASTEXITCODE is involved.
.PARAMETER Repo
Repository directory, taken from the PAYLOAD.
.PARAMETER GitArgs
Git arguments (no shell involved - nothing is word-split or expanded).
.OUTPUTS
System.String - the first trimmed output line ('' when git printed nothing), or $null on failure.
#>
function Invoke-Git([string]$Repo, [string[]]$GitArgs) {
  $run = Invoke-NativeUtf8 'git' (@('-C', $Repo) + $GitArgs)
  if ((-not $run) -or ($run.ExitCode -ne 0)) { return $null }
  $lines = ConvertTo-NativeLines $run.Stdout
  if ($lines.Count -lt 1) { return '' }
  return ([string]$lines[0]).Trim()
}

<#
.SYNOPSIS
Decode `cwd` AND `tool_input.command` from the payload via the shared jq -> node -> regex cascade.
.PARAMETER Raw
The raw payload text read from stdin.
.OUTPUTS
System.Collections.Hashtable - @{ cwd = <string>; cmd = <string> }; both '' when nothing is readable.
#>
function Get-PayloadFields([string]$Raw) {
  # Both precise stages run through Invoke-NativeUtf8: it resolves the command itself (so a missing
  # jq/node yields $null and the cascade falls through, exactly as the old `Get-Command` probe did),
  # writes the payload as UTF-8 BYTES and reads the answer back as UTF-8 - all without a console.
  # Quote-free filters: PowerShell mangles embedded double quotes when handing an argument to a
  # native command, so these must be passable byte-for-byte in BOTH variants.
  $jqCwdRun = Invoke-NativeUtf8 'jq' @('-r', 'objects | .cwd // empty') $Raw
  if ($jqCwdRun) {
    $jqCwd = ConvertTo-NativeLines $jqCwdRun.Stdout
    $okCwd = ($jqCwdRun.ExitCode -eq 0)
    $jqCmdRun = Invoke-NativeUtf8 'jq' @('-r', 'objects | .tool_input | objects | .command // empty') $Raw
    $jqCmd = if ($jqCmdRun) { ConvertTo-NativeLines $jqCmdRun.Stdout } else { @() }
    $okCmd = ($jqCmdRun -and $jqCmdRun.ExitCode -eq 0)
    if ($okCwd -and $okCmd) { return @{ cwd = ($jqCwd -join ' '); cmd = ($jqCmd -join ' ') } }
  }
  $nodeRun = Invoke-NativeUtf8 'node' @('-e', $NodeDecoder) $Raw
  if ($nodeRun) {
    $nodeOut = ConvertTo-NativeLines $nodeRun.Stdout
    if ($nodeOut.Count -ge 1) {
      # Definitive: the payload is not JSON, so there is nothing to read - stay silent.
      if ($nodeOut[0] -ceq 'unparsable') { return @{ cwd = ''; cmd = '' } }
      if ($nodeOut[0] -ceq 'ok') {
        $c = if ($nodeOut.Count -ge 2) { [string]$nodeOut[1] } else { '' }
        $m = if ($nodeOut.Count -ge 3) { [string]$nodeOut[2] } else { '' }
        return @{ cwd = $c; cmd = $m }
      }
    }
  }
  return @{ cwd = (Get-JsonField $Raw 'cwd'); cmd = (Get-JsonField $Raw 'command') }
}

<#
.SYNOPSIS
Run `git fetch --quiet origin` in a repository with a hard timeout and fully captured output.
.DESCRIPTION
This is the ONE native call that deliberately does NOT go through Invoke-NativeUtf8: it needs a hard
timeout with a kill, and it reads no output at all, so there is nothing here to decode - and nothing
that could touch the console either. KNOWN LIMIT, pre-existing and deliberately not fixed in this
round: -ArgumentList is passed as an ARRAY, and PowerShell 5.1 does not quote array elements, so a
repo path holding a space makes the fetch fail. Fail-open by design - the caller then compares
against the remote-tracking refs it already has (ADR-0027).
Output is redirected to temp files so nothing can contaminate the hook's stdout (which must stay
pure JSON). GIT_TERMINAL_PROMPT=0 turns a credential prompt into an instant failure instead of a
hang; the process is killed once the timeout elapses. Failure is never fatal - the caller then
compares against the remote-tracking refs it already has.
.PARAMETER Repo
Repository directory, taken from the PAYLOAD (never the hook process's own directory).
.OUTPUTS
None.
#>
function Invoke-GitFetch([string]$Repo) {
  $out = [IO.Path]::GetTempFileName()
  $err = [IO.Path]::GetTempFileName()
  try {
    $env:GIT_TERMINAL_PROMPT = '0'
    $p = Start-Process -FilePath 'git' -ArgumentList @('-C', $Repo, 'fetch', '--quiet', 'origin') `
      -NoNewWindow -PassThru -WorkingDirectory $Repo `
      -RedirectStandardOutput $out -RedirectStandardError $err
    if ($p -and -not $p.WaitForExit($FetchTimeoutSeconds * 1000)) { $p.Kill() }
  }
  catch {
    # fetch is best-effort - never fail the hook over it
  }
  finally {
    Remove-Item -LiteralPath $out, $err -Force -ErrorAction SilentlyContinue
  }
}

<#
.SYNOPSIS
How many commits `Ref` holds that HEAD does not (mirrors count_behind() in the .sh variant).
.PARAMETER Repo
Repository directory from the payload.
.PARAMETER Ref
Fully qualified ref to compare HEAD against.
.OUTPUTS
System.Int32 - the commit count, or -1 when the ref is missing or the count is unreadable.
#>
function Get-BehindCount([string]$Repo, [string]$Ref) {
  if ($null -eq (Invoke-Git $Repo @('rev-parse', '--verify', '--quiet', $Ref))) { return -1 }
  $n = Invoke-Git $Repo @('rev-list', '--count', "HEAD..$Ref")
  if ([string]::IsNullOrEmpty($n)) { return -1 }
  if ($n -cnotmatch '^\d+$') { return -1 }
  return [int]$n
}

# --- payload: cwd AND command, via the shared cascade --------------------------------------------------
# Read stdin through the explicit UTF-8 reader from the prologue - never [Console]::In.
$raw = $StdInUtf8.ReadToEnd()
$fields = Get-PayloadFields $raw
$cmd = Format-Flat ([string]$fields.cmd)
$cwd = (Format-Flat ([string]$fields.cwd)).Trim()

# --- only `git push` is interesting --------------------------------------------------------------------
# Tolerant of leading option tokens and their values (`git -C /path push`, `git -c k=v push`) and of any
# remote/branch/flags after `push`, while `push` must still sit in the git SUBCOMMAND position - so
# `git commit -m 'fix push flow'` does NOT match. -cnotmatch, not -notmatch: PowerShell matches
# case-INSENSITIVELY by default while `grep -Eq` does not, so a payload of "GIT PUSH" used to fire here
# and stay silent on the .sh - one payload, two answers.
if ($cmd -cnotmatch '(^|[^\w.\-])git(\s+-\S+(\s+[^-\s]\S*)?)*\s+push([^\w\-]|$)') { exit 0 }

# --- the repo is the one the PAYLOAD named - never the hook process's directory ---------------------------
if (-not $cwd) { exit 0 }
if (-not (Test-Path -LiteralPath $cwd -PathType Container)) { exit 0 }
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { exit 0 }
if ($null -eq (Invoke-Git $cwd @('rev-parse', '--git-dir'))) { exit 0 }   # not a repo -> silent no-op

$branch = Invoke-Git $cwd @('symbolic-ref', '--quiet', '--short', 'refs/remotes/origin/HEAD')
if ($branch) { $branch = ($branch -replace '^origin/', '') }
if (-not $branch) { $branch = 'main' }                  # never hard-wire main; only fall back to it
$defaultRef = "refs/remotes/origin/$branch"

Invoke-GitFetch $cwd

# PRIMARY: the ref this push updates. Resolved AFTER the fetch, so a freshly created upstream counts.
$primaryRef = Invoke-Git $cwd @('rev-parse', '--symbolic-full-name', '--verify', '--quiet', '@{upstream}')
if (-not $primaryRef) { $primaryRef = '' }

$primaryN = 0
if ($primaryRef) {
  $primaryN = Get-BehindCount $cwd $primaryRef
  if ($primaryN -lt 0) { $primaryRef = ''; $primaryN = 0 }   # configured but unusable == no upstream
}

# INFO: the default branch - skipped when it IS the primary ref (a push to the default branch).
$infoN = 0
if ($primaryRef -cne $defaultRef) {
  $infoN = Get-BehindCount $cwd $defaultRef
  if ($infoN -lt 0) { $infoN = 0 }
}

# --- report observable facts, decide nothing ----------------------------------------------------------------
$facts = ''
if ($primaryRef -and $primaryN -gt 0) {
  $facts = "$primaryRef (the upstream of this branch) holds $primaryN commit(s) that HEAD does not, measured after fetching origin."
  if ($infoN -gt 0) { $facts = "$facts $defaultRef holds $infoN commit(s) that HEAD does not." }
}
elseif ((-not $primaryRef) -and $infoN -gt 0) {
  $facts = "this branch has no upstream on origin, so the ref this push updates cannot be named here; $defaultRef holds $infoN commit(s) that HEAD does not, measured after fetching origin."
}
if (-not $facts) { exit 0 }                             # push target in sync (or ahead) -> nothing to say

$msg = "[agent-core] ORIGIN AHEAD: $facts Observed counts only - this hook cannot tell who pushed or why. If a second session may share this branch, the living status log and its session-ownership section are the shared state (rule 26-autonomy). Reminder only: this hook never blocks."
$reason = "$facts Advisory only: this hook defers to the normal permission flow and never blocks."
Write-Stdout ('{"systemMessage":"' + (Format-JsonString $msg) + '","hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"defer","permissionDecisionReason":"' + (Format-JsonString $reason) + '"}}')
exit 0
