#!/usr/bin/env bash
# setup.sh — Bootstrap dotfiles on macOS.
# Run once after cloning: bash setup.sh
#
# What this does:
#   1. Symlinks config files to their expected locations
#   2. Sets the macOS Keychain as the git credential helper
#   3. Creates ~/.gitconfig.local from the example if it doesn't exist
#   4. Prints manual steps for secrets and tool installation
#
# Safe to re-run — skips already-linked files, backs up plain files.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---- Helpers ----------------------------------------------------------------

info()    { echo "  [·] $*"; }
success() { echo "  [✓] $*"; }
warn()    { echo "  [!] $*" >&2; }
section() { echo ""; echo "── $* ──────────────────────────────────────────"; }

# Create a symlink; backs up any existing plain file first.
link() {
  local src="$1"
  local dest="$2"

  if [ -L "$dest" ]; then
    success "already linked: $dest"
    return
  fi

  if [ -f "$dest" ]; then
    warn "backing up existing file: $dest → $dest.bak"
    mv "$dest" "$dest.bak"
  fi

  mkdir -p "$(dirname "$dest")"
  ln -s "$src" "$dest"
  success "linked: $(basename "$dest")"
}

# ---- Guard: macOS only ------------------------------------------------------

if [[ "$OSTYPE" != "darwin"* ]]; then
  warn "This script is for macOS. For Debian/WSL, run setup-linux.sh instead."
  exit 1
fi

section "Workspace"
bash "$DOTFILES/scripts/workspace-init.sh"

section "Symlinking config files"
link "$DOTFILES/zsh/.zshrc"             "$HOME/.zshrc"
link "$DOTFILES/git/.gitconfig"         "$HOME/.gitconfig"
link "$DOTFILES/.editorconfig"          "$HOME/.editorconfig"
link "$DOTFILES/.prettierrc"            "$HOME/.prettierrc"
link "$DOTFILES/claude/CLAUDE.md"       "$HOME/.claude/CLAUDE.md"
link "$DOTFILES/claude/settings.json"   "$HOME/.claude/settings.json"

# Agent Rules Polyfills (points IDEs to the repository source of truth)
link "$DOTFILES/AGENTS.md"              "$DOTFILES/.cursorrules"
link "$DOTFILES/AGENTS.md"              "$DOTFILES/.windsurfrules"
link "$DOTFILES/AGENTS.md"              "$DOTFILES/.github/copilot-instructions.md"
link "$DOTFILES/AGENTS.md"              "$DOTFILES/CLAUDE.md"

# Agent Template CLI (Strategy B) - Adds ai-init to $PATH
link "$DOTFILES/bin/ai-init"            "$HOME/.local/bin/ai-init"

# ---- Git Templates & Config -------------------------------------------------

section "Git config & templates"

# Configure Git Templates (Strategy A)
git config --global init.templatedir "$DOTFILES/agent-base/git-templates"
success "Git templates configured to use dotfiles/agent-base/git-templates"

GITCONFIG_LOCAL="$HOME/.gitconfig.local"
if [ ! -f "$GITCONFIG_LOCAL" ]; then
  cp "$DOTFILES/git/.gitconfig.local.example" "$GITCONFIG_LOCAL"
  # Write the macOS credential helper automatically
  cat >> "$GITCONFIG_LOCAL" <<'EOF'

[credential]
	helper = osxkeychain
EOF
  success "created ~/.gitconfig.local with osxkeychain credential helper"
else
  info "~/.gitconfig.local already exists — skipping (edit manually if needed)"
fi

# ---- Tools check ------------------------------------------------------------

section "Checking tools"

need() {
  if command -v "$1" &>/dev/null; then
    success "$1 found: $(command -v "$1")"
  else
    warn "$1 not found — install with: $2"
  fi
}

need "brew"   "/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
need "git"    "brew install git"
need "gh"     "brew install gh"
need "fnm"    "brew install fnm"
need "gpg"    "brew install gnupg"
need "pass"   "brew install pass"

# ---- Summary ----------------------------------------------------------------

section "Done"
echo ""
echo "  Reload your shell:"
echo "    source ~/.zshrc"
echo ""
echo "  Remaining manual steps:"
echo ""
echo "  1. Install all Homebrew tools at once:"
echo "       cd ~/dotfiles && brew bundle"
echo ""
echo "  2. Authenticate GitHub CLI:"
echo "       gh auth login"
echo ""
echo "  3. Store API keys in macOS Keychain (never in files):"
echo "       security add-generic-password -a \"\$USER\" -s ANTHROPIC_API_KEY -w"
echo "       # Paste the key value when prompted"
echo ""
echo "  4. (Optional) Enable GPG commit signing:"
echo "       See the GPG section in git/.gitconfig.local.example"
echo ""
