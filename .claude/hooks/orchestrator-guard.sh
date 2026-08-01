#!/usr/bin/env bash
# agent-core: main-chat orchestrator guard (Claude Code PreToolUse hook).
# Denies Edit/Write in the MAIN Claude session so the orchestrator delegates all implementation to
# subagents; subagent tool calls (which carry a non-empty top-level "agent_id") pass through untouched.
#
# Decision order — orchestrator-guard.ps1 makes the SAME decisions with the SAME strings; change both:
#   (a) top-level "agent_id" present -> ALLOW (exit 0, no output). Never deadlock a delegated worker.
#   (b) payload UNREADABLE            -> ALLOW + a top-level "systemMessage": fail-open by design
#                                       (ADR-0012), but never SILENTLY — the message says the guard
#                                       did not enforce this call (30-quality "fail loud").
#                                       PRECONDITION, stated because it does not always hold: only a
#                                       PRECISE stage (jq or node) can tell "not JSON at all" apart
#                                       from "JSON without agent_id". With NEITHER installed the
#                                       tolerant stage classifies an unparsable payload as `main`, so
#                                       it is DENIED, not allowed — and (d) then says exactly that.
#   (c) audited emergency marker set -> ALLOW + a top-level "systemMessage" (shown to the user) naming
#                                       the reason, the remaining TTL and how to remove the marker.
#                                       Every permitted inline edit announces itself — never silent.
#   (d) otherwise                    -> DENY; the reason ALSO spells out the escape hatch, says why a
#                                       marker that WAS found does not count, and — when no precise
#                                       parser existed — that this verdict came from the tolerant
#                                       stage, which cannot see an unparsable payload at all.
#
# PAYLOAD CASCADE — identical in both variants, so both classify a payload the same way:
#   jq (precise) -> node -e (precise, SINGLE-LINE: a multi-line `node -e` runs an EMPTY program under
#   Git-Bash) -> grep (tolerant, last resort). Every stage reports WHICH KIND decided (`precise` |
#   `tolerant`) alongside the verdict, so (b)/(d) above can name the difference out loud instead of
#   quietly changing direction. RESIDUAL RISK, grep stage only: the regex matches
#   "agent_id" ANYWHERE, including nested inside tool_input — a main-session Edit whose CONTENT holds
#   that literal would be waved through. It is reached only when neither jq nor node exists; both
#   precise stages read the TOP-LEVEL field only. Documented in ADR-0023.
#
# CASCADE TEST COVERAGE — stage 2 (node) and stage 3 (grep, forced by removing node+jq from PATH) are
#   proven by real runs of BOTH variants. Stage 1 (jq) is proven only against a jq STUB put on PATH by
#   the suite (jq is not installed on the reference machine); a REAL jq binary is NOT covered by any
#   test. src/targets/claude.test.ts names this in its describe title; ADR-0023 records it.
#
# The emergency marker (ADR-0023) is the mechanical counterpart of rule 25-orchestration's "it writes
# code itself only in a genuine emergency — when delegation is truly unavailable":
#   file : "$(git rev-parse --git-dir)/agent-core-emergency-inline" — NEVER the literal ".git/…":
#          `.git` is a FILE in a worktree. Content = the MANDATORY reason; empty/whitespace-only does
#          NOT grant permission. TTL = 60 min from the file's mtime; an expired marker does NOT grant
#          permission either — a forgotten marker must never silently disable the guard for good.
#          Remaining TTL is rounded UP (a marker with 30 s left reports "1 min", never "0 min");
#          the overdue minutes of an EXPIRED marker are elapsed time, hence rounded DOWN.
#          The path is printed with forward slashes on every platform, so both variants read alike.
#   env  : AGENT_CORE_EMERGENCY_INLINE — value is the reason ("1" stays valid, reported as
#          "no reason given"). Checked after the file — also when the file exists but is empty or
#          expired. It covers the case where there is no git dir; it carries no mtime, hence no TTL.
#
# FAIL-OPEN by design (unchanged): any problem inside the guard — no parser, unreadable payload, no
# usable stat/date — resolves toward ALLOW, but says so out loud. The guard must never block work
# because of its own defect, and must never pretend it checked when it did not.
TTL_SECONDS=3600
MARKER_NAME="agent-core-emergency-inline"

# Precise stage-2 classifier. Prints exactly one of: agent | main | unparsable.
# Kept free of ", $ and backticks so the SAME source line works inside a bash double-quoted string
# and inside a PowerShell double-quoted string (orchestrator-guard.ps1 carries it verbatim).
NODE_CLASSIFIER="let s='';process.stdin.on('data',function(d){s+=d}).on('end',function(){var v;try{v=JSON.parse(s)}catch(e){process.stdout.write('unparsable');return}var a=(v&&typeof v==='object'&&Array.isArray(v)===false)?v.agent_id:null;var t=(a===null||a===undefined||a===false)?'':String(a);process.stdout.write(t.trim()?'agent':'main')})"

# --- helpers -------------------------------------------------------------------------------------
# Escape an arbitrary string for embedding in a JSON string literal: control characters (which a
# reason file may well contain) are flattened to spaces/dropped, then backslash and quote are escaped.
json_escape() {
  printf '%s' "$1" | tr '\n\r\t' '   ' | tr -d '\000-\037' | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

# Trim a string to a single whitespace-collapsed line (used for both the marker file and the env var).
trim_line() {
  printf '%s' "$1" | tr '\n\r\t' '   ' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

# Render a filesystem path with forward slashes — the .ps1 variant normalizes identically, so the
# audit line is character-identical on both platforms.
norm_path() {
  printf '%s' "$1" | tr '\\' '/'
}

# emit <allow|deny> <permissionDecisionReason> [systemMessage]
emit() {
  if [ -n "$3" ]; then
    printf '{"systemMessage":"%s","hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"%s","permissionDecisionReason":"%s"}}' \
      "$(json_escape "$3")" "$1" "$(json_escape "$2")"
  else
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"%s","permissionDecisionReason":"%s"}}' \
      "$1" "$(json_escape "$2")"
  fi
}

# Classify the payload on stdin. Prints "<verdict> <stage>": verdict is agent | main | unparsable,
# stage is precise | tolerant. The stage rides along (rather than being a global) because the caller
# reads this through a subshell — and because decision (b) is only reachable from a PRECISE stage.
# Get-PayloadVerdict in orchestrator-guard.ps1 honors the SAME two-token contract.
classify_payload() {
  if command -v jq >/dev/null 2>&1; then
    # `objects` yields nothing for a non-object payload -> "main", exactly like the node stage.
    # Deliberately free of double quotes so the .ps1 variant can pass the SAME filter to jq.
    jq_out="$(printf '%s' "$input" | jq -r 'objects | .agent_id // empty' 2>/dev/null)"
    if [ $? -eq 0 ]; then
      if [ -n "$(trim_line "$jq_out")" ]; then printf 'agent precise'; else printf 'main precise'; fi
      return 0
    fi
  fi
  if command -v node >/dev/null 2>&1; then
    node_out="$(printf '%s' "$input" | node -e "$NODE_CLASSIFIER" 2>/dev/null)"
    case "$node_out" in
      agent | main | unparsable)
        printf '%s precise' "$node_out"
        return 0
        ;;
    esac
  fi
  # Last resort — tolerant, and blind to nesting (see RESIDUAL RISK in the header).
  if printf '%s' "$input" | grep -qE '"agent_id"[[:space:]]*:[[:space:]]*"[^"]+"'; then
    printf 'agent tolerant'
  else
    printf 'main tolerant'
  fi
}

# --- (a)/(b) who is calling? ----------------------------------------------------------------------
input="$(cat 2>/dev/null || true)"
classified="$(classify_payload)"
verdict="${classified%% *}"
stage="${classified#* }"
if [ "$verdict" = "agent" ]; then exit 0; fi
if [ "$verdict" = "unparsable" ]; then
  emit "allow" \
    "Guard could not parse the PreToolUse payload - failing open (allow) instead of blocking work. This call was NOT checked against the delegate-only posture." \
    "[agent-core] orchestrator-guard could NOT read the PreToolUse payload (no jq/node parser succeeded) - the delegate-only guard did NOT enforce this call. Fail-open by design (ADR-0012); if this repeats, the payload shape changed and the guard needs fixing."
  exit 0
fi

# --- (c) audited emergency override ---------------------------------------------------------------
reason=""
source_desc=""
remaining_desc=""
marker_path=""
marker_state=""   # "" | empty | expired
marker_detail=""

gitdir="$(git rev-parse --absolute-git-dir 2>/dev/null || git rev-parse --git-dir 2>/dev/null || true)"
if [ -n "$gitdir" ] && [ -f "$gitdir/$MARKER_NAME" ]; then
  marker_file="$gitdir/$MARKER_NAME"
  marker_path="$(norm_path "$marker_file")"
  trimmed="$(trim_line "$(cat "$marker_file" 2>/dev/null || true)")"
  if [ -z "$trimmed" ]; then
    marker_state="empty"
  else
    mtime="$(stat -c %Y "$marker_file" 2>/dev/null || stat -f %m "$marker_file" 2>/dev/null || true)"
    now="$(date +%s 2>/dev/null || true)"
    if [ -z "$mtime" ] || [ -z "$now" ]; then
      # Fail-open, but LOUD: without a usable mtime the TTL cannot be enforced, so say so.
      reason="$trimmed"
      source_desc="$marker_path"
      remaining_desc="TTL NOT verifiable here (no usable stat/date) - remove the marker by hand"
    else
      age=$((now - mtime))
      if [ "$age" -gt "$TTL_SECONDS" ]; then
        marker_state="expired"
        marker_detail="$(((age - TTL_SECONDS) / 60))"   # elapsed -> round DOWN
      else
        reason="$trimmed"
        source_desc="$marker_path"
        remaining_desc="expires in $(((TTL_SECONDS - age + 59) / 60)) min"   # remaining -> round UP
      fi
    fi
  fi
fi

if [ -z "$reason" ]; then
  env_trimmed="$(trim_line "${AGENT_CORE_EMERGENCY_INLINE:-}")"
  if [ -n "$env_trimmed" ]; then
    if [ "$env_trimmed" = "1" ]; then reason="no reason given"; else reason="$env_trimmed"; fi
    source_desc="env AGENT_CORE_EMERGENCY_INLINE"
    remaining_desc="no TTL on the env fallback - unset it when the incident is over"
  fi
fi

if [ -n "$reason" ]; then
  emit "allow" \
    "Emergency inline override active (audited marker) - the delegate-only guard was bypassed on purpose." \
    "[agent-core] EMERGENCY INLINE EDIT allowed - the delegate-only guard was bypassed. Reason: ${reason}. Marker: ${source_desc} (${remaining_desc}). Remove it the moment delegation works again."
  exit 0
fi

# --- (d) deny, and point at the legitimate way out ------------------------------------------------
case "$marker_state" in
  empty)
    note=" An emergency marker exists at ${marker_path} but is EMPTY - a marker without a written reason does NOT grant permission."
    ;;
  expired)
    note=" The emergency marker at ${marker_path} EXPIRED ${marker_detail} min ago (TTL 60 min) - it does NOT grant permission; rewrite it with a current reason to re-arm."
    ;;
  *)
    note=""
    ;;
esac
# Fail LOUD about the one precondition of decision (b): without jq AND without node the tolerant
# stage cannot see an unparsable payload, so such a payload lands HERE (deny) instead of in the
# documented fail-open branch. Never let that swap happen quietly (30-quality).
parser_note=""
if [ "$stage" = "tolerant" ]; then
  parser_note=" NOTE: neither jq nor node was available, so this payload was classified by the tolerant regex stage, which cannot tell an UNPARSABLE payload from a main-session one - on this machine an unparsable payload is DENIED here rather than allowed with a fail-open warning (ADR-0023)."
fi
emit "deny" \
  "Main chat is orchestrator-only: editing tools are denied for the main session. Delegate this change to a subagent (Task) or a Workflow.${note}${parser_note} Genuine emergency (delegation itself is unavailable)? Open the audited escape hatch: printf 'why' > \"\$(git rev-parse --git-dir)/${MARKER_NAME}\" - it allows inline edits for 60 min, announces every single one, and must be deleted afterwards (env fallback: AGENT_CORE_EMERGENCY_INLINE=\"why\")."
exit 0
