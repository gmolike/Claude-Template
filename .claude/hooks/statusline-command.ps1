# ============================================================================
# Claude Code Statusline (PowerShell) - agent-core managed
#
# PowerShell sibling of statusline-command.sh. Deployed by `agent-core sync`;
# used as the statusLine command on Windows, where Claude Code routes commands
# through PowerShell when Git Bash is optional / absent. Invoke via:
#   powershell -NoProfile -ExecutionPolicy Bypass -File <path>/statusline-command.ps1
# `-NoProfile` since ADR-0027. This is a REASON, not a measurement: a profile
# runs before the script and shares its stdout, so whatever a profile PRINTS
# (banner, oh-my-posh, update notice) is prepended to the status line - and, in
# the two hooks that emit a decision, to the JSON envelope, where it costs the
# decision outright. A hook must not be breakable by a machine-local user file.
# What WAS measured here: the reference machine has no PowerShell profile at all
# (all four $PROFILE paths Test-Path False; $PROFILE derives from the MyDocuments
# known folder - C:\Users\<user>\Documents - so one cannot be planted outside the
# real user directory for a test, and no test writes there). Against a payload
# carrying model + workspace + context + cost, this script emits byte-identical
# output with and without -NoProfile: 282 bytes each, exit 0. The flag therefore
# costs nothing here and removes the dependency. The corrupting case is shown by
# an explicitly labelled SIMULATION in ADR-0027, not by an invented measurement.
#
# Shows: directory | model | context % | 5h/7d rate limits | cost | git branch
#        with dirty indicator and +/- line counts.
#
# Encoding robustness:
#   Every non-ASCII glyph (emoji icons, box separator, plus-minus, ellipsis) is
#   built from an explicit Unicode codepoint via [char]::ConvertFromUtf32() /
#   [char]. The source file therefore stays pure ASCII, so Windows PowerShell
#   5.1 cannot mangle the glyphs even when it reads the file as the legacy ANSI
#   codepage (a no-BOM UTF-8 file otherwise turns emoji into mojibake and can
#   break string parsing). Since ADR-0027 this is no longer a convention only
#   this file keeps: it is an invariant over ALL agent-core .ps1 sources, gated
#   by a test in src/targets/claude.test.ts, and the sync adapter additionally
#   writes every DEPLOYED .ps1 with a UTF-8 BOM so an installation path holding
#   a non-ASCII character survives the parser too.
#
#   The stdin side needed the same treatment and did not have it: with
#   [Console]::In the payload was decoded as the OEM code page, so a workspace
#   path holding an umlaut arrived as mojibake and `Test-Path $cwd` said False -
#   the whole git segment (branch, dirty marker, +/- counts) silently vanished.
#   Measured on the pre-fix file: ASCII repo -> branch rendered; "Gruen-repo"
#   with an umlaut -> path shown as "Gr<U+251C><U+255D>n-repo", no git segment.
# ============================================================================

# --- deterministic UTF-8 I/O, BEFORE anything is read or written ----------------------------------
# The three-line block below is ONE shared form - byte-for-byte the same in every agent-core .ps1
# hook that decodes non-ASCII text - the roster is PS_WITH_PROLOGUE in
# src/targets/claude.test.ts, which pins the block byte-for-byte with a lockstep test. Deliberately
# NOT enumerated here: a hand-kept list of names in every header is what drifts the moment a hook is
# added, which is how improvement-reflect.ps1 and worktree-bootstrap.ps1 first went unclassified.
# Every statement in it is PROCESS-LOCAL: none of them touches the console.
#   $OutputEncoding  a PowerShell VARIABLE, not a console API - the encoding of text piped INTO a
#                    native command. Measured side-effect-free with GetConsoleCP/GetConsoleOutputCP
#                    across a child process (850/850 before, 850/850 after).
#   $StdInUtf8       stdin is read through OUR OWN reader on [Console]::OpenStandardInput(), never
#                    [Console]::In, so decoding depends on no console setting at all. THIS is the
#                    channel that was broken here - see the measurement above. Also measured
#                    side-effect-free (850/850 before and after).
# NOT here any more, and this is the point: [Console]::InputEncoding / [Console]::OutputEncoding were
# assigned until ADR-0027 R2. Their setters call SetConsoleCP / SetConsoleOutputCP, i.e. they rewrite
# the code page of the console this script INHERITED - permanently, for every later process in it.
# Measured from a separate process around one hook run: before ConsoleCP=850 ConsoleOutputCP=850,
# after 65001/65001, exit 0 - while all three channels were redirected ([Console]::IsInputRedirected
# = True), so the old comment's "only when a channel is NOT redirected" was false as written. A
# status line renders many times a session; it must not reconfigure the user's terminal even once.
# The two channels that really needed those setters are covered process-locally instead:
#   - git's stdout (a branch name may hold a non-ASCII character) -> Invoke-NativeUtf8 below, which
#     gives the CHILD file-redirected I/O and decodes the bytes as UTF-8 itself;
#   - this script's own stdout (the codepoint glyphs) -> Write-Stdout below, raw UTF-8 bytes through
#     [Console]::OpenStandardOutput(), so [Console]::Out and its code page are never involved.
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

# Read JSON from stdin through the explicit UTF-8 reader from the prologue - never [Console]::In.
$input_json = $StdInUtf8.ReadToEnd()
try {
    $data = $input_json | ConvertFrom-Json
} catch {
    Write-Host "statusline parse error" -ForegroundColor Red
    exit 0
}

# --- ANSI escape codes ------------------------------------------------------
$ESC = [char]27
$RESET  = "$ESC[0m"
$BOLD   = "$ESC[1m"
$DIM    = "$ESC[2m"

# Tokyo-Night palette
$PINK   = "$ESC[38;5;211m"
$CYAN   = "$ESC[38;5;117m"
$PURPLE = "$ESC[38;5;141m"
$BLUE   = "$ESC[38;5;111m"
$GRAY   = "$ESC[38;5;245m"

$GREEN  = "$ESC[38;5;114m"
$YELLOW = "$ESC[38;5;221m"
$ORANGE = "$ESC[38;5;215m"
$RED    = "$ESC[38;5;203m"

# --- Glyphs (explicit codepoints - never literal bytes) ---------------------
$ICON_MODEL = [char]::ConvertFromUtf32(0x1F916)  # robot face
$ICON_CTX   = [char]::ConvertFromUtf32(0x1F9E0)  # brain
$ICON_5H    = [char]::ConvertFromUtf32(0x23F1)   # stopwatch
$ICON_7D    = [char]::ConvertFromUtf32(0x1F4C5)  # calendar
$ICON_COST  = [char]::ConvertFromUtf32(0x1F4B0)  # money bag
$DIRTY      = [char]0x00B1                        # plus-minus sign
$ELLIPSIS   = [char]0x2026                        # horizontal ellipsis
$BAR        = [char]0x2502                        # box drawings light vertical

$SEP = "$GRAY$BAR$RESET"

# Locale-independent number formatting
$INV = [System.Globalization.CultureInfo]::InvariantCulture

# --- Helpers ----------------------------------------------------------------
function Get-ThresholdColor {
    param([int]$Value, [int]$Green = 50, [int]$Yellow = 80, [int]$Orange = 95)
    if ($Value -lt $Green)  { return $script:GREEN }
    if ($Value -lt $Yellow) { return $script:YELLOW }
    if ($Value -lt $Orange) { return $script:ORANGE }
    return $script:RED
}

function Format-Reset {
    param([long]$Timestamp)
    if (-not $Timestamp -or $Timestamp -le 0) { return "" }

    $now = [DateTimeOffset]::Now.ToUnixTimeSeconds()
    $diff = $Timestamp - $now
    if ($diff -le 0) { return "now" }

    $hours = [math]::Floor($diff / 3600)
    $mins  = [math]::Floor(($diff % 3600) / 60)
    $days  = [math]::Floor($hours / 24)

    if ($days -gt 0)  { return "${days}d" }
    if ($hours -gt 0) { return "${hours}h${mins}m" }
    return "${mins}m"
}

# --- Extract data -----------------------------------------------------------
$model     = $data.model.display_name
$ctxPct    = if ($data.context_window) { [int]$data.context_window.used_percentage } else { $null }
$cost      = $data.cost.total_cost_usd
$linesAdd  = $data.cost.total_lines_added
$linesDel  = $data.cost.total_lines_removed
$cwd       = $data.workspace.current_dir

$rl5       = if ($data.rate_limits.five_hour) { [int]$data.rate_limits.five_hour.used_percentage } else { $null }
$rl5Reset  = $data.rate_limits.five_hour.resets_at
$rl7       = if ($data.rate_limits.seven_day) { [int]$data.rate_limits.seven_day.used_percentage } else { $null }
$rl7Reset  = $data.rate_limits.seven_day.resets_at

# --- Build segments ---------------------------------------------------------
$parts = @()

# Directory (collapse HOME to ~, shorten very long paths to .../basename)
if ($cwd) {
    $shortCwd = [string]$cwd
    if ($HOME) {
        $shortCwd = $shortCwd.Replace($HOME, "~")
        $homeBs = $HOME.Replace("/", "\")
        $shortCwd = $shortCwd.Replace($homeBs, "~")
    }
    if ($shortCwd.Length -gt 30) {
        $shortCwd = "$ELLIPSIS/" + (Split-Path -Leaf $cwd)
    }
    $parts += "$BLUE$shortCwd$RESET"
}

# Model
if ($model) {
    $parts += "$PINK$BOLD$ICON_MODEL $model$RESET"
}

# Context
if ($null -ne $ctxPct) {
    $color = Get-ThresholdColor -Value $ctxPct -Green 50 -Yellow 80 -Orange 95
    $parts += "$CYAN$ICON_CTX$RESET $color$ctxPct%$RESET"
}

# 5h rate limit (with reset countdown)
if ($null -ne $rl5) {
    $color = Get-ThresholdColor -Value $rl5 -Green 50 -Yellow 75 -Orange 90
    $resetStr = Format-Reset -Timestamp $rl5Reset
    if ($resetStr) {
        $parts += "$GRAY$ICON_5H$RESET ${color}5h:$rl5%$RESET$DIM($resetStr)$RESET"
    } else {
        $parts += "$GRAY$ICON_5H$RESET ${color}5h:$rl5%$RESET"
    }
}

# 7d rate limit
if ($null -ne $rl7) {
    $color = Get-ThresholdColor -Value $rl7 -Green 50 -Yellow 75 -Orange 90
    $parts += "$GRAY$ICON_7D$RESET ${color}7d:$rl7%$RESET"
}

# Cost (InvariantCulture for dot decimal separator)
if ($null -ne $cost) {
    $costFmt = ([double]$cost).ToString("F2", $INV)
    if ($cost -lt 1)      { $color = $GREEN }
    elseif ($cost -lt 5)  { $color = $YELLOW }
    else                  { $color = $ORANGE }
    $parts += "$BLUE$ICON_COST$RESET $color`$$costFmt$RESET"
}

# Git branch + line counts.
# Every git call runs through Invoke-NativeUtf8 with the workspace directory as the CHILD's working
# directory. Push-Location moved only PowerShell's own location; .NET hands a child the PROCESS
# directory, which Push-Location never touches - so the directory has to be passed explicitly here.
# The helper also decodes a branch name holding a non-ASCII character as UTF-8 without rewriting the
# console code page (see its .DESCRIPTION), which is what the removed [Console]::OutputEncoding
# setter used to do for the whole terminal.
if ($cwd -and (Test-Path $cwd)) {
    $branchRun = Invoke-NativeUtf8 'git' @('branch', '--show-current') '' $cwd
    $branchLines = if ($branchRun -and $branchRun.ExitCode -eq 0) { ConvertTo-NativeLines $branchRun.Stdout } else { @() }
    $branch = if ($branchLines.Count -ge 1) { ([string]$branchLines[0]).Trim() } else { '' }
    if ($branch) {
        $isDirty = $false
        $unstaged = Invoke-NativeUtf8 'git' @('diff', '--quiet') '' $cwd
        if ((-not $unstaged) -or ($unstaged.ExitCode -ne 0)) { $isDirty = $true }
        $staged = Invoke-NativeUtf8 'git' @('diff', '--cached', '--quiet') '' $cwd
        if ((-not $staged) -or ($staged.ExitCode -ne 0)) { $isDirty = $true }

        if ($isDirty) {
            $branchColor = $YELLOW
            $branchIcon  = $DIRTY
        } else {
            $branchColor = $GREEN
            $branchIcon  = ""
        }
        $gitPart = "$PURPLE$RESET$branchColor$branch$branchIcon$RESET"

        if ($linesAdd -and $linesAdd -gt 0) {
            $gitPart += " $GREEN+$linesAdd$RESET"
        }
        if ($linesDel -and $linesDel -gt 0) {
            $gitPart += " $RED-$linesDel$RESET"
        }
        $parts += $gitPart
    }
}

# --- Output -----------------------------------------------------------------
# Raw UTF-8 bytes, never [Console]::Out: [Console]::Out is built from [Console]::OutputEncoding, and
# the only way to make THAT UTF-8 is the setter that rewrites the whole console's code page.
$output = $parts -join " $SEP "
Write-Stdout $output
