#!/usr/bin/env bash
# scripts/state.sh — Local state tracking for dotfiles.
# Source this file; do not execute it directly.
#
# State is stored in ~/.local/share/dotfiles/state.env as flat key=value pairs.
# This file is local to each machine and is never committed to git.
#
# Usage:
#   source "$DOTFILES/scripts/state.sh"
#   state_set "ROLE" "wsl-dev"
#   role="$(state_get ROLE)"

# Guard against double-sourcing
[[ -n "${_DOTFILES_STATE_LOADED:-}" ]] && return 0
_DOTFILES_STATE_LOADED=1

STATE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles"
STATE_FILE="$STATE_DIR/state.env"

# Ensure the state directory and file exist
_init_state() {
  mkdir -p "$STATE_DIR"
  [[ -f "$STATE_FILE" ]] || touch "$STATE_FILE"
}

# Read a value by key. Returns empty string if not found.
state_get() {
  local key="$1"
  _init_state
  grep "^${key}=" "$STATE_FILE" 2>/dev/null | head -1 | cut -d'=' -f2-
}

# Write a key=value pair (upsert — replaces any existing entry for that key).
state_set() {
  local key="$1"
  local value="$2"
  _init_state
  local tmp="${STATE_FILE}.tmp"
  grep -v "^${key}=" "$STATE_FILE" > "$tmp" 2>/dev/null || true
  echo "${key}=${value}" >> "$tmp"
  mv "$tmp" "$STATE_FILE"
}

# Returns the current git short hash of the dotfiles repo, or "unknown".
dotfiles_version() {
  git -C "${DOTFILES:-$HOME/.dotfiles}" rev-parse --short HEAD 2>/dev/null || echo "unknown"
}
