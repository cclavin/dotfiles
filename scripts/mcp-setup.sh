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

# ---- Find Python ------------------------------------------------------------

PYTHON=""
for cmd in python3 python py; do
  if command -v "$cmd" &>/dev/null && "$cmd" --version &>/dev/null; then
    PYTHON="$cmd"
    break
  fi
done

if [[ -z "$PYTHON" ]]; then
  warn "Python not found -- mcp/deploy.py requires Python 3.8+"
  exit 1
fi

# ---- Deploy -----------------------------------------------------------------

if is_dry_run; then
  info "[dry-run] would run: $PYTHON $DOTFILES/mcp/deploy.py $*"
else
  "$PYTHON" "$DOTFILES/mcp/deploy.py" "$@"
fi
