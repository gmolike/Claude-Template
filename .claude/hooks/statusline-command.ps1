# ============================================================================
# Claude Code Statusline (PowerShell) - agent-core managed
#
# PowerShell sibling of statusline-command.sh. Deployed by `agent-core sync`;
# used as the statusLine command on Windows, where Claude Code routes commands
# through PowerShell when Git Bash is optional / absent. Invoke via:
#   powershell -ExecutionPolicy Bypass -File <path>/statusline-command.ps1
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
#   break string parsing).
# ============================================================================

# Force UTF-8 console encoding so the codepoint glyphs render (not the file
# encoding - the source is ASCII - but the terminal output stream).
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Read JSON from stdin
$input_json = [Console]::In.ReadToEnd()
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

# Git branch + line counts
if ($cwd -and (Test-Path $cwd)) {
    Push-Location $cwd
    try {
        $branch = git branch --show-current 2>$null
        if ($branch) {
            $isDirty = $false
            git diff --quiet 2>$null
            if ($LASTEXITCODE -ne 0) { $isDirty = $true }
            git diff --cached --quiet 2>$null
            if ($LASTEXITCODE -ne 0) { $isDirty = $true }

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
    } finally {
        Pop-Location
    }
}

# --- Output -----------------------------------------------------------------
$output = $parts -join " $SEP "
[Console]::Out.Write($output)
