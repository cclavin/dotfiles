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
    ERRORS=$((ERRORS + 1))
  fi
}

check_link() {
  local path="$1"
  if [[ -L "$path" ]]; then
    success "symlink: $path"
  else
    warn "FAIL symlink missing: $path"
    ERRORS=$((ERRORS + 1))
  fi
}

check_file() {
  local path="$1"
  local desc="${2:-$path}"
  if [[ -f "$path" ]]; then
    success "file: $desc"
  else
    warn "FAIL file missing: $desc"
    ERRORS=$((ERRORS + 1))
  fi
}

check_dir() {
  local path="$1"
  if [[ -d "$path" ]]; then
    success "dir: $path"
  else
    warn "FAIL directory missing: $path"
    ERRORS=$((ERRORS + 1))
  fi
}

check_git_config() {
  local key="$1"
  local value
  value="$(git config --global "$key" 2>/dev/null)"
  if [[ -n "$value" ]]; then
    success "git config: $key = $value"
  else
    warn "FAIL git config not set: $key"
    ERRORS=$((ERRORS + 1))
  fi
}

# ---- Required commands ------------------------------------------------------

section "Commands"

check_cmd "git"
check_cmd "gh"
check_cmd "jq"
check_cmd "yq"
check_cmd "fzf"
check_cmd "ripgrep" "rg"
check_cmd "starship"
check_cmd "zoxide"
check_cmd "mise"
check_cmd "uv"
check_cmd "delta"

# fnm: soft warning — only needed on machines not yet migrated to mise
if ! command -v mise &>/dev/null && ! command -v fnm &>/dev/null; then
  warn "WARN neither mise nor fnm found — no Node version manager present"
  ERRORS=$((ERRORS + 1))
elif command -v fnm &>/dev/null && ! command -v mise &>/dev/null; then
  warn "WARN fnm found but mise not installed — run bootstrap to migrate"
fi

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
  check_cmd "fastfetch"
fi

# ---- Symlinks ---------------------------------------------------------------

section "Symlinks"

check_link "$HOME/.zshrc"
check_link "$HOME/.gitconfig"
check_link "$HOME/.editorconfig"
check_link "$HOME/.prettierrc"
check_link "$HOME/.claude/CLAUDE.md"
check_link "$HOME/.claude/commands"
check_file "$HOME/.claude/settings.json" "~/.claude/settings.json"

check_link "$HOME/.tmux.conf"
check_link "$HOME/.config/starship.toml"
check_link "$HOME/.config/mise/config.toml"
if $IS_LINUX; then
  check_link "$HOME/.config/fastfetch/config.jsonc"
fi

# ---- Config validity --------------------------------------------------------

section "Config validity"

if git config --global user.name &>/dev/null; then
  success "git config readable"
else
  warn "FAIL git config not readable"
  ((ERRORS++))
fi

if command -v starship &>/dev/null && starship print-config &>/dev/null 2>&1; then
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

# ---- MCP config -------------------------------------------------------------

section "MCP"

check_file "$DOTFILES/mcp/deploy.py" "mcp/deploy.py"

_has_python() {
  command -v uv &>/dev/null || command -v python3 &>/dev/null || command -v python &>/dev/null
}
if [[ -f "$HOME/.claude/settings.json" ]] && _has_python; then
  if jq -e '.mcpServers | length > 0' "$HOME/.claude/settings.json" &>/dev/null; then
    mcp_count=$(jq '.mcpServers | length' "$HOME/.claude/settings.json" 2>/dev/null)
    success "claude settings.json has $mcp_count MCP server(s)"
  else
    warn "FAIL ~/.claude/settings.json has no MCP servers -- run: bash scripts/mcp-setup.sh"
    ((ERRORS++))
  fi
fi

if [[ -f "$DOTFILES/mcp/env" ]]; then
  success "mcp/env secrets file present"
else
  info "mcp/env not found -- MCP servers needing keys will deploy with literals"
fi

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
    homelab)
      check_cmd "docker"
      check_cmd "go"
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
