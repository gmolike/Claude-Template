#!/usr/bin/env bash
# agent-core: multi-session push-target reminder (Claude Code PreToolUse hook, matcher "Bash").
#
# Two Claude sessions cannot see each other. Verified: two parallel sessions built wave 1 TWICE,
# divergently, and nothing caught it but a manual `git log` diff (rule 26-autonomy, ADR-0025). This
# hook is the mechanical half of that rule: on a `git push` it fetches and reports, as COMMIT COUNTS,
# which refs hold work HEAD does not — so the divergence is seen BEFORE more work is stacked on it.
#
# WHICH REF IS COMPARED — the org workflow is feature-branch + one PR (20-workflow), and comparing
# only against origin/<default-branch> was measured to be both too loud AND blind:
#   PRIMARY: the current branch's UPSTREAM (@{upstream}) — the ref this push actually updates.
#            Foreign commits THERE are a real push conflict. Measured before this change: a second
#            session pushed to origin/feat/x and the reminder never named that ref at all.
#   INFO   : origin/<default-branch>, and only when it is not already the primary ref AND holds
#            commits HEAD lacks AND there is a primary finding to attach it to — or when the branch
#            has NO upstream, where it is the only thing that can be said. A routine feature push
#            whose upstream is in sync therefore stays SILENT even after the default branch moved.
#            Measured before this change: exactly that safe push fired the full alarm — alarm fatigue
#            on the one channel ADR-0025 is built on.
# WHAT IT CLAIMS — only what it measured: which ref, how many commits, and that the counts were taken
# after a fetch. It never asserts WHO pushed or WHY; that reading belongs to the human. The earlier
# wording ("another session pushed since this one started") was a causal claim the hook cannot make.
#
# NEVER BLOCKS — by construction, and the choice is deliberate (live hook docs, fetched 2026-07-23):
#   - nothing to say -> exit 0 with NO output. "Exit code 0 with no output means the hook has no
#     decision to report, so the tool call continues through the normal permission flow."
#   - a finding      -> a top-level "systemMessage" (the documented warning channel that surfaces to
#     the user without blocking) PLUS an explicit permissionDecision "defer" ("defers the decision to
#     the normal permission flow"). Both silence and "defer" are non-blocking; "defer" is chosen for
#     the reporting path so the emitted JSON itself proves the hook deliberately made no decision and
#     cannot be misread as a forgotten field. "allow" would be WRONG — it auto-approves the push and
#     bypasses the permission system. "deny"/"ask" are never emitted anywhere in this script, so no
#     network hiccup, no missing tool and no bug in here can ever stop a push.
# Fail-open everywhere: no parser, no git, no repo, no origin, a failed fetch -> silent exit 0 (or,
# for a failed fetch, a comparison against the remote-tracking refs we already have).
#
# PAYLOAD CASCADE — the SAME shape as orchestrator-guard.sh, and every stage reads BOTH fields:
#   jq (precise) -> node -e (precise, SINGLE-LINE: a multi-line `node -e` runs an EMPTY program under
#   Git-Bash) -> grep (tolerant, last resort). Reading only ONE field was the whole bug: `cwd` went
#   unread on the no-jq path, so git ran in the HOOK PROCESS's directory. Measured on this machine
#   (no jq): payload cwd = a diverged clone, process cwd elsewhere -> NOTHING reported; and the
#   mirror, payload cwd = a synced repo, process cwd = a diverged one -> divergence reported for a
#   repo the payload never named (false positive). RESIDUAL RISK, grep stage only: it takes the first
#   "cwd"/"command" string ANYWHERE in the payload and un-escapes only \" \/ \\ — a command holding a
#   double quote is truncated at it. Reached only when neither jq nor node exists; a miss there costs
#   a reminder, never a block.
#
# The payload's cwd is the ONLY repo this hook ever inspects — every git call goes through
# `git -C "$cwd"`, and an unusable cwd means silent exit, never a fallback to the process directory.
# `.git` is NEVER addressed literally (it is a FILE in a worktree): repo detection goes through
# `git rev-parse --git-dir`. The default branch is derived from origin/HEAD, falling back to `main`.
#
# origin-divergence-check.ps1 makes the SAME decisions with the SAME strings — change both together.
FETCH_TIMEOUT_SECONDS=10

# Precise stage-2 decoder. Prints either `unparsable`, or `ok` + a line for cwd + a line for command
# (control characters flattened to spaces, so the output is exactly three lines).
# Kept free of ", $, backticks AND backslashes, so the SAME source line survives verbatim inside a
# bash double-quoted string, inside a PowerShell double-quoted string (origin-divergence-check.ps1
# carries it character-for-character) and through any JSON transport in between — hence the charCode
# loop instead of a control-character class, and String.fromCharCode(10) instead of a newline escape.
NODE_DECODER="let s='';process.stdin.on('data',function(d){s+=d}).on('end',function(){var v;try{v=JSON.parse(s)}catch(e){process.stdout.write('unparsable');return}var o=(v&&typeof v==='object'&&Array.isArray(v)===false)?v:{};var i=(o.tool_input&&typeof o.tool_input==='object')?o.tool_input:{};var n=String.fromCharCode(10);var f=function(x){if(typeof x!=='string')return '';var r='';for(var k=0;k<x.length;k++){var c=x.charCodeAt(k);r+=(c<32)?' ':x.charAt(k)}return r};process.stdout.write('ok'+n+f(o.cwd)+n+f(i.command))})"

# --- helpers -------------------------------------------------------------------------------------
# Escape for a JSON string literal: control characters flattened/dropped, backslash and quote escaped.
json_escape() {
  printf '%s' "$1" | tr '\n\r\t' '   ' | tr -d '\000-\037' | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

# Collapse every control character to a space, so all three decode stages hand on ONE line.
flatten() {
  printf '%s' "$1" | tr '\000-\037' ' '
}

# Strip leading/trailing whitespace (the decoded cwd is used as a filesystem path).
trim() {
  printf '%s' "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

# Last-resort extraction of a JSON string value by key, minimally un-escaped (\" \/ \\).
json_field() {
  printf '%s' "$input" |
    grep -oE '"'"$1"'"[[:space:]]*:[[:space:]]*"([^"\\]|\\.)*"' |
    head -n1 |
    sed -e 's/^[^:]*:[[:space:]]*"//' -e 's/"$//' -e 's/\\"/"/g' -e 's/\\\//\//g' -e 's/\\\\/\\/g'
}

# --- payload: cwd AND command, via the shared cascade ----------------------------------------------
input="$(cat 2>/dev/null || true)"
cmd=""
cwd=""
decoded=""

if command -v jq >/dev/null 2>&1; then
  # Two quote-free filters (PowerShell mangles double quotes when handing arguments to a native
  # command, so the .ps1 variant must be able to pass these byte-for-byte). `objects` yields nothing
  # for a non-object payload / a non-object tool_input, exactly like the node stage.
  if jq_cwd="$(printf '%s' "$input" | jq -r 'objects | .cwd // empty' 2>/dev/null)" &&
    jq_cmd="$(printf '%s' "$input" | jq -r 'objects | .tool_input | objects | .command // empty' 2>/dev/null)"; then
    cwd="$jq_cwd"
    cmd="$jq_cmd"
    decoded=1
  fi
fi

if [ -z "$decoded" ] && command -v node >/dev/null 2>&1; then
  node_out="$(printf '%s' "$input" | node -e "$NODE_DECODER" 2>/dev/null || true)"
  case "$node_out" in
    unparsable)
      decoded=1 # definitive: the payload is not JSON, so there is nothing to read — stay silent
      ;;
    ok*)
      cwd="$(printf '%s\n' "$node_out" | sed -n '2p')"
      cmd="$(printf '%s\n' "$node_out" | sed -n '3p')"
      decoded=1
      ;;
  esac
fi

if [ -z "$decoded" ]; then
  cwd="$(json_field cwd)"
  cmd="$(json_field command)"
fi

cmd="$(flatten "$cmd")"
cwd="$(trim "$(flatten "$cwd")")"

# --- only `git push` is interesting ------------------------------------------------------------------
# Tolerant of leading option tokens and their values (`git -C /path push`, `git -c k=v push`) and of
# any remote/branch/flags after `push`, while `push` must still sit in the git SUBCOMMAND position, so
# `git commit -m 'fix push flow'` does NOT match. CASE-SENSITIVE in both variants (the .ps1 uses
# -cnotmatch): real git commands are lowercase, and a payload of "GIT PUSH" used to fire on the .ps1
# only — one payload, two answers.
printf '%s' "$cmd" |
  grep -Eq '(^|[^[:alnum:]_.-])git([[:space:]]+-[^[:space:]]+([[:space:]]+[^-[:space:]][^[:space:]]*)?)*[[:space:]]+push([^[:alnum:]_-]|$)' ||
  exit 0

# --- the repo is the one the PAYLOAD named — never the hook process's directory ---------------------
[ -n "$cwd" ] || exit 0
[ -d "$cwd" ] || exit 0
command -v git >/dev/null 2>&1 || exit 0
git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1 || exit 0 # not a repo -> silent no-op

branch="$(git -C "$cwd" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"
branch="${branch#origin/}"
[ -n "$branch" ] || branch="main" # never hard-wire main; only fall back to it
default_ref="refs/remotes/origin/$branch"

# Refresh the remote-tracking refs. GIT_TERMINAL_PROMPT=0 turns a credential prompt into an instant
# failure instead of a hang; `timeout` caps a slow network when it exists. A failed fetch is NOT fatal
# — we then compare against the refs we already have rather than going silent.
export GIT_TERMINAL_PROMPT=0
if command -v timeout >/dev/null 2>&1; then
  timeout "$FETCH_TIMEOUT_SECONDS" git -C "$cwd" fetch --quiet origin >/dev/null 2>&1 || true
else
  git -C "$cwd" fetch --quiet origin >/dev/null 2>&1 || true
fi

# How many commits $1 holds that HEAD does not. Prints the count, or fails when the ref is unusable.
count_behind() {
  git -C "$cwd" rev-parse --verify --quiet "$1" >/dev/null 2>&1 || return 1
  n="$(git -C "$cwd" rev-list --count "HEAD..$1" 2>/dev/null || true)"
  case "$n" in '' | *[!0-9]*) return 1 ;; esac
  printf '%s' "$n"
}

# PRIMARY: the ref this push updates. Resolved AFTER the fetch, so a freshly created upstream counts.
primary_ref="$(git -C "$cwd" rev-parse --symbolic-full-name --verify --quiet '@{upstream}' 2>/dev/null || true)"
primary_n=0
if [ -n "$primary_ref" ]; then
  primary_n="$(count_behind "$primary_ref")" || primary_ref="" # configured but unusable == no upstream
  [ -n "$primary_n" ] || primary_n=0
fi

# INFO: the default branch — skipped when it IS the primary ref (a push to the default branch).
info_n=0
if [ "$primary_ref" != "$default_ref" ]; then
  info_n="$(count_behind "$default_ref")" || info_n=0
  [ -n "$info_n" ] || info_n=0
fi

# --- report observable facts, decide nothing --------------------------------------------------------
facts=""
if [ -n "$primary_ref" ] && [ "$primary_n" -gt 0 ]; then
  facts="$primary_ref (the upstream of this branch) holds $primary_n commit(s) that HEAD does not, measured after fetching origin."
  if [ "$info_n" -gt 0 ]; then
    facts="$facts $default_ref holds $info_n commit(s) that HEAD does not."
  fi
elif [ -z "$primary_ref" ] && [ "$info_n" -gt 0 ]; then
  facts="this branch has no upstream on origin, so the ref this push updates cannot be named here; $default_ref holds $info_n commit(s) that HEAD does not, measured after fetching origin."
fi
[ -n "$facts" ] || exit 0 # push target in sync (or ahead) -> nothing to say

msg="[agent-core] ORIGIN AHEAD: $facts Observed counts only - this hook cannot tell who pushed or why. If a second session may share this branch, the living status log and its session-ownership section are the shared state (rule 26-autonomy). Reminder only: this hook never blocks."
reason="$facts Advisory only: this hook defers to the normal permission flow and never blocks."
printf '{"systemMessage":"%s","hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"defer","permissionDecisionReason":"%s"}}' \
  "$(json_escape "$msg")" "$(json_escape "$reason")"
exit 0
