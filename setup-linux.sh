#!/usr/bin/env bash
# setup-linux.sh — Bootstrap dotfiles on Debian/Ubuntu or WSL2.
# Run once after cloning: bash setup-linux.sh
#
# Supports:
#   - Debian / Ubuntu (native)
#   - WSL2 (Windows Subsystem for Linux) with Debian/Ubuntu
#
# What this does:
#   1. Detects WSL vs native Linux
#   2. Installs required packages via apt
#   3. Installs gh CLI (GitHub's apt repo) and fnm (Node version manager)
#   4. Symlinks config files to their expected locations
#   5. Sets up pass (GPG-encrypted secret store) as the credential helper
#   6. Creates ~/.gitconfig.local with appropriate credential helper
#   7. Prints manual steps for secrets

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---- Helpers ----------------------------------------------------------------

info()    { echo "  [·] $*"; }
success() { echo "  [✓] $*"; }
warn()    { echo "  [!] $*" >&2; }
section() { echo ""; echo "── $* ──────────────────────────────────────────"; }

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

# ---- Guard: Linux only ------------------------------------------------------

if [[ "$OSTYPE" != "linux-gnu"* ]]; then
  warn "This script is for Linux/WSL. For macOS, run setup.sh instead."
  exit 1
fi

# ---- Detect WSL -------------------------------------------------------------

IS_WSL=false
if grep -qi microsoft /proc/version 2>/dev/null; then
  IS_WSL=true
  info "WSL2 environment detected"
else
  info "Native Linux environment detected"
fi

# ---- Package installation ---------------------------------------------------

section "Installing packages via apt"

if ! command -v sudo &>/dev/null; then
  warn "sudo not found — you may need to run as root or install sudo"
fi

sudo apt-get update -qq

# Core tools
sudo apt-get install -y -qq \
  git \
  curl \
  gnupg \
  pass \
  jq \
  ripgrep \
  fzf \
  xz-utils

success "Core packages installed"

# ---- gh CLI (GitHub's official apt repo) ------------------------------------

section "Installing gh CLI"

if command -v gh &>/dev/null; then
  success "gh already installed: $(gh --version | head -1)"
else
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
  sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt-get update -qq
  sudo apt-get install -y -qq gh
  success "gh CLI installed"
fi

# ---- fnm (Node version manager) ---------------------------------------------

section "Installing fnm"

if command -v fnm &>/dev/null; then
  success "fnm already installed: $(fnm --version)"
else
  curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "$HOME/.local/bin" --skip-shell
  success "fnm installed to ~/.local/bin"
  info "fnm will be activated on next shell reload (via .zshrc)"
fi

# ---- zsh (if not installed) -------------------------------------------------

if ! command -v zsh &>/dev/null; then
  section "Installing zsh"
  sudo apt-get install -y -qq zsh
  info "zsh installed. To set as default shell: chsh -s \$(which zsh)"
fi

# ---- Symlinks ---------------------------------------------------------------

section "Symlinking config files"
link "$DOTFILES/zsh/.zshrc"             "$HOME/.zshrc"
link "$DOTFILES/git/.gitconfig"         "$HOME/.gitconfig"
link "$DOTFILES/.editorconfig"          "$HOME/.editorconfig"
link "$DOTFILES/.prettierrc"            "$HOME/.prettierrc"
link "$DOTFILES/claude/CLAUDE.md"       "$HOME/.claude/CLAUDE.md"
link "$DOTFILES/claude/settings.json"   "$HOME/.claude/settings.json"

# ---- .gitconfig.local -------------------------------------------------------

section "Git local config"

GITCONFIG_LOCAL="$HOME/.gitconfig.local"
if [ ! -f "$GITCONFIG_LOCAL" ]; then
  cp "$DOTFILES/git/.gitconfig.local.example" "$GITCONFIG_LOCAL"

  # On WSL2: use Git Credential Manager from Windows if available
  if $IS_WSL && command -v "/mnt/c/Program Files/Git/mingw64/bin/git-credential-manager.exe" &>/dev/null; then
    cat >> "$GITCONFIG_LOCAL" <<'EOF'

[credential]
	helper = /mnt/c/Program\ Files/Git/mingw64/bin/git-credential-manager.exe
EOF
    success "~/.gitconfig.local created — using Windows Git Credential Manager (WSL)"

  # Try libsecret first (GNOME keyring, good for desktop Debian)
  elif [ -f "/usr/share/doc/git/contrib/credential/libsecret/git-credential-libsecret" ]; then
    cat >> "$GITCONFIG_LOCAL" <<'EOF'

[credential]
	helper = /usr/share/doc/git/contrib/credential/libsecret/git-credential-libsecret
EOF
    success "~/.gitconfig.local created — using libsecret credential helper"

  # Fall back to pass (GPG store) — works headless and in WSL
  else
    cat >> "$GITCONFIG_LOCAL" <<'EOF'

# git-credential-pass requires: pass init <gpg-key-id>
# Then: sudo apt install git-credential-pass  (or build from source)
# [credential]
# 	helper = pass
EOF
    warn "~/.gitconfig.local created — credential helper commented out (see instructions below)"
  fi
else
  info "~/.gitconfig.local already exists — skipping"
fi

# ---- Summary ----------------------------------------------------------------

section "Done"
echo ""
echo "  Reload your shell:"
echo "    source ~/.zshrc   # or: exec zsh"
echo ""
echo "  Remaining manual steps:"
echo ""
echo "  1. Authenticate GitHub CLI:"
echo "       gh auth login"
echo ""

if $IS_WSL; then
echo "  2. Store API keys using pass (GPG-encrypted, cross-platform):"
echo "       # First create a GPG key if you don't have one:"
echo "       gpg --full-generate-key"
echo "       # Note the key ID from: gpg --list-secret-keys"
echo "       # Initialize pass:"
echo "       pass init <your-gpg-key-id>"
echo "       # Store the key:"
echo "       pass insert api-keys/ANTHROPIC_API_KEY"
echo ""
echo "     WSL tip: if you installed Git Credential Manager via Git for Windows,"
echo "     the credential helper in ~/.gitconfig.local already points to it."
echo ""
else
echo "  2. Store API keys using pass (GPG-encrypted):"
echo "       gpg --full-generate-key"
echo "       pass init <your-gpg-key-id>"
echo "       pass insert api-keys/ANTHROPIC_API_KEY"
echo ""
echo "     Or use GNOME keyring (desktop only):"
echo "       secret-tool store --label='ANTHROPIC_API_KEY' application ANTHROPIC_API_KEY"
echo ""
fi

echo "  3. (Optional) Enable GPG commit signing:"
echo "       See the GPG section in ~/dotfiles/git/.gitconfig.local.example"
echo ""
echo "  4. Install Claude Code:"
echo "       npm install -g @anthropic-ai/claude-code"
echo "       # Requires Node — install via fnm first:"
echo "       fnm install 20 && fnm use 20"
echo ""
