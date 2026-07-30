#!/usr/bin/env pwsh
# Claude Code PostToolUse hook (PowerShell variant): format files after Edit/Write.
# 1:1 port of format-on-edit.sh for Windows machines where Claude Code routes hook
# commands through PowerShell (Git Bash optional / absent).
# Receives the event as JSON on stdin (Claude Code convention).
$ErrorActionPreference = 'SilentlyContinue'

# Extract the edited file path from the event JSON.
$raw = [Console]::In.ReadToEnd()
if (-not $raw) { exit 0 }
try {
    $data = $raw | ConvertFrom-Json
} catch {
    exit 0
}
$file = $data.tool_input.file_path
if (-not $file) { exit 0 }
if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { exit 0 }

$ext = [System.IO.Path]::GetExtension($file).ToLowerInvariant()
if ($ext -in '.ts', '.tsx', '.js', '.jsx', '.json', '.css', '.md') {
    if (Get-Command pnpm -ErrorAction SilentlyContinue) {
        & pnpm exec prettier --write $file *> $null
    } elseif (Get-Command npx -ErrorAction SilentlyContinue) {
        & npx --no-install prettier --write $file *> $null
    }
}

exit 0
