#!/usr/bin/env bash
# scripts/lib.sh — Shared helpers for all dotfiles scripts.
# Source this file; do not execute it directly.
#
# Usage: source "$DOTFILES/scripts/lib.sh"

# Guard against double-sourcing
[[ -n "${_DOTFILES_LIB_LOADED:-}" ]] && return 0
_DOTFILES_LIB_LOADED=1

# Resolve DOTFILES root from this file's location (scripts/lib.sh → parent = repo root).
# Respects an already-set DOTFILES variable from the calling script.
DOTFILES="${DOTFILES:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# ---- Output helpers ---------------------------------------------------------

info()    { echo "  [·] $*"; }
success() { echo "  [✓] $*"; }
warn()    { echo "  [!] $*" >&2; }
section() { echo ""; echo "── $* ──────────────────────────────────────────"; }

# ---- Dry-run gate -----------------------------------------------------------
# When DRY_RUN=true, commands that mutate state are printed instead of run.
# Usage: run mv "$src" "$dest"
run() {
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    info "[dry-run] $*"
    return 0
  fi
  "$@"
}

# Returns 0 (true) when DRY_RUN=true. Use in if-blocks for multi-command sections.
# Usage: if is_dry_run; then info "[dry-run] ..."; else <real commands>; fi
is_dry_run() { [[ "${DRY_RUN:-false}" == "true" ]]; }

# ---- Symlink helper ---------------------------------------------------------
# Creates a symlink from src to dest.
# - If dest is already a symlink, skips (idempotent).
# - If dest is a plain file, backs it up to dest.bak first.
link() {
  local src="$1"
  local dest="$2"

  if [ -L "$dest" ]; then
    success "already linked: $dest"
    return
  fi

  if [ -f "$dest" ]; then
    warn "backing up existing file: $dest → $dest.bak"
    run mv "$dest" "$dest.bak"
  fi

  run mkdir -p "$(dirname "$dest")"
  run ln -s "$src" "$dest"
  success "linked: $(basename "$dest")"
}

# ---- OS detection -----------------------------------------------------------
# Sets IS_MACOS, IS_LINUX, IS_WSL after being called.
# Called automatically at the bottom of this file on source.
detect_os() {
  local os
  os="$(uname -s)"
  IS_MACOS=false
  IS_LINUX=false
  IS_WSL=false

  case "$os" in
    Darwin)
      IS_MACOS=true
      ;;
    Linux)
      IS_LINUX=true
      if grep -qi microsoft /proc/version 2>/dev/null; then
        IS_WSL=true
      fi
      ;;
  esac
}

detect_os
