#!/usr/bin/env bash
# ============================================================================
# Claude Code Statusline (bash) — agent-core managed
#
# Shows: directory | git branch | model | context usage
#        + optional rate-limit warning
# Deployed by `agent-core sync`; used as the statusLine command on non-Windows
# (and on Windows when Claude Code routes through Git Bash). The PowerShell
# sibling statusline-command.ps1 is used when Claude Code routes through
# PowerShell (Git Bash optional / absent).
# ============================================================================

# Read JSON from stdin
input=$(cat)

# --- ANSI escape codes (Tokyo-Night palette) --------------------------------
ESC=$'\033'
RESET="$ESC[0m"
BOLD="$ESC[1m"
DIM="$ESC[2m"

PINK="$ESC[38;5;211m"
CYAN="$ESC[38;5;117m"
PURPLE="$ESC[38;5;141m"
BLUE="$ESC[38;5;111m"
GRAY="$ESC[38;5;245m"
GREEN="$ESC[38;5;114m"
YELLOW="$ESC[38;5;221m"
ORANGE="$ESC[38;5;215m"
RED="$ESC[38;5;203m"

SEP="${GRAY}│${RESET}"

# --- Helper: threshold color ------------------------------------------------
threshold_color() {
  local val=$1
  if   [ "$val" -lt 50 ]; then printf '%s' "$GREEN"
  elif [ "$val" -lt 80 ]; then printf '%s' "$YELLOW"
  elif [ "$val" -lt 95 ]; then printf '%s' "$ORANGE"
  else                         printf '%s' "$RED"
  fi
}

# --- Helper: format reset time ----------------------------------------------
format_reset() {
  local ts=$1
  [ -z "$ts" ] || [ "$ts" = "null" ] || [ "$ts" -le 0 ] 2>/dev/null && return
  local now diff hours mins days
  now=$(date +%s 2>/dev/null) || return
  diff=$(( ts - now ))
  [ "$diff" -le 0 ] && printf 'now' && return
  hours=$(( diff / 3600 ))
  mins=$(( (diff % 3600) / 60 ))
  days=$(( hours / 24 ))
  if   [ "$days"  -gt 0 ]; then printf '%dd'      "$days"
  elif [ "$hours" -gt 0 ]; then printf '%dh%dm'   "$hours" "$mins"
  else                          printf '%dm'       "$mins"
  fi
}

# --- Extract data from JSON -------------------------------------------------
model=$(echo "$input"     | jq -r '.model.display_name // empty')
ctx_pct=$(echo "$input"   | jq -r '.context_window.used_percentage // empty')
cwd=$(echo "$input"       | jq -r '.workspace.current_dir // empty')
rl5_pct=$(echo "$input"   | jq -r '.rate_limits.five_hour.used_percentage // empty')
rl5_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
rl7_pct=$(echo "$input"   | jq -r '.rate_limits.seven_day.used_percentage // empty')

# --- Segment 1: directory (relative to HOME, else basename) -----------------
parts=()

if [ -n "$cwd" ] && [ "$cwd" != "null" ]; then
  short_cwd="$cwd"
  # Collapse the home directory to ~ (both unix and Windows-style separators).
  if [ -n "$HOME" ]; then
    short_cwd="${short_cwd/$HOME/\~}"
    home_bs="${HOME//\//\\}"
    short_cwd="${short_cwd/$home_bs/\~}"
  fi
  # Still long (>30 chars): show only the last path segment.
  if [ ${#short_cwd} -gt 30 ]; then
    short_cwd="…/$(basename "$cwd")"
  fi
  parts+=("${BLUE}${short_cwd}${RESET}")
fi

# --- Segment 2: git branch --------------------------------------------------
if [ -n "$cwd" ] && [ "$cwd" != "null" ]; then
  # Normalize path separators for git.
  git_cwd="${cwd//\\//}"
  branch=$(git -C "$git_cwd" branch --show-current --no-optional-locks 2>/dev/null)
  if [ -n "$branch" ]; then
    git -C "$git_cwd" diff --quiet 2>/dev/null
    dirty_unstaged=$?
    git -C "$git_cwd" diff --cached --quiet 2>/dev/null
    dirty_staged=$?
    if [ "$dirty_unstaged" -ne 0 ] || [ "$dirty_staged" -ne 0 ]; then
      branch_color="$YELLOW"
      branch_suffix="±"
    else
      branch_color="$GREEN"
      branch_suffix=""
    fi
    parts+=("${PURPLE}${RESET}${branch_color}${branch}${branch_suffix}${RESET}")
  fi
fi

# --- Segment 3: model -------------------------------------------------------
if [ -n "$model" ]; then
  parts+=("${PINK}${BOLD}${model}${RESET}")
fi

# --- Segment 4: context usage -----------------------------------------------
if [ -n "$ctx_pct" ]; then
  ctx_int=$(printf '%.0f' "$ctx_pct" 2>/dev/null || echo "$ctx_pct")
  ctx_color=$(threshold_color "$ctx_int")
  parts+=("${CYAN}ctx${RESET} ${ctx_color}${ctx_int}%${RESET}")
fi

# --- Segment 5: rate limits (only above 50%) --------------------------------
if [ -n "$rl5_pct" ]; then
  rl5_int=$(printf '%.0f' "$rl5_pct" 2>/dev/null || echo "$rl5_pct")
  if [ "$rl5_int" -ge 50 ] 2>/dev/null; then
    rl5_color=$(threshold_color "$rl5_int")
    reset_str=$(format_reset "$rl5_reset")
    rl5_seg="${rl5_color}5h:${rl5_int}%${RESET}"
    [ -n "$reset_str" ] && rl5_seg="${rl5_seg}${DIM}(${reset_str})${RESET}"
    parts+=("$rl5_seg")
  fi
fi

if [ -n "$rl7_pct" ]; then
  rl7_int=$(printf '%.0f' "$rl7_pct" 2>/dev/null || echo "$rl7_pct")
  if [ "$rl7_int" -ge 50 ] 2>/dev/null; then
    rl7_color=$(threshold_color "$rl7_int")
    parts+=("${rl7_color}7d:${rl7_int}%${RESET}")
  fi
fi

# --- Assemble output --------------------------------------------------------
output=""
for i in "${!parts[@]}"; do
  if [ "$i" -gt 0 ]; then
    output="${output} ${SEP} "
  fi
  output="${output}${parts[$i]}"
done

printf '%s' "$output"
