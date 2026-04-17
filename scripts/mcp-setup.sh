#!/usr/bin/env bash
# scripts/mcp-setup.sh — Source MCP secrets and run the deploy script.
#
# Usage:
#   bash scripts/mcp-setup.sh                    # deploy all tools
#   bash scripts/mcp-setup.sh --dry-run           # preview
#   bash scripts/mcp-setup.sh --tool claude-code  # single tool
#   bash scripts/mcp-setup.sh --force             # overwrite existing entries
#
# All flags are passed through to mcp/deploy.py.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES/scripts/lib.sh"

section "MCP Deploy"

# ---- Source secrets if available --------------------------------------------

ENV_FILE="$DOTFILES/mcp/env"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  source "$ENV_FILE"
  set +a
  success "loaded secrets from mcp/env"
else
  info "mcp/env not found -- deploying with system env vars only"
  info "Copy mcp/env.example to mcp/env and fill in values for full setup"
fi

# ---- Deploy -----------------------------------------------------------------
# Prefer uv run — automatically provides tomli on Python < 3.11 via PEP 723
# inline deps declared in deploy.py. Falls back to system Python if uv is
# not yet installed on this machine.

if is_dry_run; then
  if command -v uv &>/dev/null; then
    info "[dry-run] would run: uv run $DOTFILES/mcp/deploy.py $*"
  else
    info "[dry-run] would run: python3 $DOTFILES/mcp/deploy.py $*"
  fi
elif command -v uv &>/dev/null; then
  uv run "$DOTFILES/mcp/deploy.py" "$@"
else
  # Fallback: locate system Python (uv not yet installed)
  PYTHON=""
  for cmd in python3 python py; do
    if command -v "$cmd" &>/dev/null && "$cmd" --version &>/dev/null; then
      PYTHON="$cmd"
      break
    fi
  done
  if [[ -z "$PYTHON" ]]; then
    warn "Python not found — install uv (brew install uv) or Python 3.8+"
    exit 1
  fi
  "$PYTHON" "$DOTFILES/mcp/deploy.py" "$@"
fi
