#!/usr/bin/env bash
# scripts/validate.sh — Validate dotfiles installation state.
#
# Checks that required commands, symlinks, configs, and workspace
# directories are all in the expected state for this machine.
#
# Usage:
#   bash validate.sh              # run directly
#   ./bootstrap.sh --audit        # called via bootstrap

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES/scripts/lib.sh"
source "$DOTFILES/scripts/state.sh"

ERRORS=0

# ---- Helpers ----------------------------------------------------------------

check_cmd() {
  local name="$1"
  local bin="${2:-$1}"
  if command -v "$bin" &>/dev/null; then
    success "command: $name"
  else
    warn "FAIL command not found: $name"
    ((ERRORS++))
  fi
}

check_link() {
  local path="$1"
  if [[ -L "$path" ]]; then
    success "symlink: $path"
  else
    warn "FAIL symlink missing: $path"
    ((ERRORS++))
  fi
}

check_file() {
  local path="$1"
  local desc="${2:-$path}"
  if [[ -f "$path" ]]; then
    success "file: $desc"
  else
    warn "FAIL file missing: $desc"
    ((ERRORS++))
  fi
}

check_dir() {
  local path="$1"
  if [[ -d "$path" ]]; then
    success "dir: $path"
  else
    warn "FAIL directory missing: $path"
    ((ERRORS++))
  fi
}

check_git_config() {
  local key="$1"
  if git config "$key" &>/dev/null; then
    success "git config: $key = $(git config "$key")"
  else
    warn "FAIL git config not set: $key"
    ((ERRORS++))
  fi
}

# ---- Required commands ------------------------------------------------------

section "Commands"

check_cmd "git"
check_cmd "gh"
check_cmd "jq"
check_cmd "fzf"
check_cmd "ripgrep" "rg"
check_cmd "starship"
check_cmd "zoxide"
check_cmd "fnm"
check_cmd "delta"

# bat is batcat on Debian/Ubuntu
if command -v bat &>/dev/null || command -v batcat &>/dev/null; then
  success "command: bat"
else
  warn "FAIL command not found: bat"
  ((ERRORS++))
fi

if $IS_LINUX; then
  check_cmd "eza"
  check_cmd "lazygit"
  check_cmd "tmux"
fi

# ---- Symlinks ---------------------------------------------------------------

section "Symlinks"

check_link "$HOME/.zshrc"
check_link "$HOME/.gitconfig"
check_link "$HOME/.editorconfig"
check_link "$HOME/.prettierrc"
check_link "$HOME/.claude/CLAUDE.md"
check_link "$HOME/.claude/settings.json"

if $IS_LINUX; then
  check_link "$HOME/.tmux.conf"
  check_link "$HOME/.config/starship.toml"
fi

# ---- Config validity --------------------------------------------------------

section "Config validity"

if git config --list &>/dev/null; then
  success "git config readable"
else
  warn "FAIL git config --list failed"
  ((ERRORS++))
fi

if command -v starship &>/dev/null && starship config &>/dev/null 2>&1; then
  success "starship config valid"
elif command -v starship &>/dev/null; then
  warn "FAIL starship config invalid"
  ((ERRORS++))
fi

# ---- Git config -------------------------------------------------------------

section "Git config"

check_git_config "user.name"
check_git_config "user.email"
check_file "$HOME/.gitconfig.local" "~/.gitconfig.local"

# ---- Workspace directories --------------------------------------------------

section "Workspace"

check_dir "$HOME/workspace/code"
check_dir "$HOME/workspace/vault"

# ---- Role-specific checks ---------------------------------------------------

CURRENT_ROLE="$(state_get ROLE)"
if [[ -n "$CURRENT_ROLE" ]]; then
  section "Role: $CURRENT_ROLE"
  case "$CURRENT_ROLE" in
    cloud-admin|wsl-dev)
      check_cmd "go"
      check_cmd "gcloud"
      check_cmd "terraform"
      if [[ "$CURRENT_ROLE" == "cloud-admin" ]]; then
        check_cmd "docker"
      fi
      ;;
    linux-dev)
      info "No additional role requirements"
      ;;
    macos-workstation)
      check_cmd "brew"
      ;;
  esac
fi

# ---- Summary ----------------------------------------------------------------

section "Validation Summary"

if [[ $ERRORS -eq 0 ]]; then
  success "All checks passed"
  exit 0
else
  warn "$ERRORS check(s) failed"
  exit 1
fi
