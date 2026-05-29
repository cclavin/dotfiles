#!/usr/bin/env bash
# scripts/vscode-deploy.sh — Deploy settings and AI instructions to VS Code and Antigravity on Windows.
#
# Safe to re-run. Only runs on WSL where /mnt/c is accessible.
# Antigravity (CLI and IDE) are VS Code forks sharing the same settings format.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES/scripts/lib.sh"

if ! grep -qi microsoft /proc/version 2>/dev/null; then
  info "Not WSL — skipping Windows VS Code deploy"
  exit 0
fi

SRC="$DOTFILES/vscode/settings.json"

deploy_settings() {
  local dest_dir="$1"
  local app_name="$2"
  if [[ -d "$dest_dir" ]]; then
    cp "$SRC" "$dest_dir/settings.json"
    success "$app_name settings deployed → $dest_dir/settings.json"
  else
    info "$app_name config dir not found — skipping ($dest_dir)"
  fi
}

deploy_instructions() {
  local dest_dir="$1"
  local app_name="$2"
  local instructions_src="$DOTFILES/antigravity/instructions.md"
  if [[ -d "$dest_dir" ]]; then
    cp "$instructions_src" "$dest_dir/instructions.md"
    success "$app_name instructions deployed → $dest_dir/instructions.md"
  else
    info "$app_name dir not found — skipping ($dest_dir)"
  fi
}

section "Deploying VS Code / Antigravity settings"

# Derive Windows username: prefer explicit override, fall back to Linux $USER.
# Set WIN_USERNAME in ~/.zshrc.local if your Windows and Linux usernames differ.
WIN_USER="${WIN_USERNAME:-$USER}"
WINUSER="/mnt/c/Users/$WIN_USER"

if [[ ! -d "$WINUSER" ]]; then
  warn "Windows user path not found at $WINUSER — set WIN_USERNAME in ~/.zshrc.local"
  exit 0
fi

deploy_settings "$WINUSER/AppData/Roaming/Code/User"           "VS Code"
deploy_settings "$WINUSER/AppData/Roaming/Antigravity/User"    "Antigravity"
deploy_settings "$WINUSER/AppData/Roaming/Antigravity IDE/User" "Antigravity IDE"

section "Deploying Antigravity instructions"

deploy_instructions "$WINUSER/.antigravitycli"  "Antigravity CLI"
deploy_instructions "$WINUSER/.antigravity-ide" "Antigravity IDE"
