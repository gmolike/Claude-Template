#!/usr/bin/env bash
# Claude Code PostToolUse hook: format files after Edit/Write.
# Receives the event as JSON on stdin (Claude Code convention).
# This is the Claude-only path. The OpenCode equivalent lives in
# targets/opencode/plugins/format-on-edit.ts (different mechanism, see COMPATIBILITY.md).
set -euo pipefail

# Extract the edited file path from the event JSON.
file_path="$(jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"
[ -z "$file_path" ] && exit 0
[ -f "$file_path" ] || exit 0

case "$file_path" in
  *.ts|*.tsx|*.js|*.jsx|*.json|*.css|*.md)
    if command -v pnpm >/dev/null 2>&1; then
      pnpm exec prettier --write "$file_path" >/dev/null 2>&1 || true
    elif command -v npx >/dev/null 2>&1; then
      npx --no-install prettier --write "$file_path" >/dev/null 2>&1 || true
    fi
    ;;
esac

exit 0
