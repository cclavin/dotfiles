#!/usr/bin/env bash
# scripts/linux-core.sh — Core dotfiles setup for Linux/WSL.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES/scripts/lib.sh"
source "$DOTFILES/scripts/versions.sh"

# ---- Guard: Linux only ------------------------------------------------------

if [[ "$OSTYPE" != "linux-gnu"* ]]; then
  warn "This script is for Linux/WSL."
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

section "Workspace"
bash "$DOTFILES/scripts/workspace-init.sh"

# ---- Package installation ---------------------------------------------------

section "Installing packages via apt"

if ! command -v sudo &>/dev/null; then
  warn "sudo not found — you may need to run as root or install sudo"
fi

if is_dry_run; then
  info "[dry-run] would install via apt: git curl unzip gnupg pass jq ripgrep fzf xz-utils tmux zsh-autosuggestions zsh-syntax-highlighting eza bat"
else
  sudo apt-get update -qq
  sudo apt-get install -y -qq \
    git \
    curl \
    unzip \
    gnupg \
    pass \
    jq \
    ripgrep \
    fzf \
    xz-utils \
    tmux \
    zsh-autosuggestions \
    zsh-syntax-highlighting \
    eza \
    bat
  success "Core packages installed"
fi

# ---- lazygit (terminal UI for git) -----------------------------------------

section "Installing lazygit"

if command -v lazygit &>/dev/null; then
  success "lazygit already installed: $(lazygit --version | head -1)"
elif is_dry_run; then
  info "[dry-run] would install lazygit (latest release from GitHub)"
else
  LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')
  curl -sLo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
  tar -C /tmp -xzf /tmp/lazygit.tar.gz lazygit
  sudo install /tmp/lazygit /usr/local/bin/lazygit
  rm -f /tmp/lazygit.tar.gz /tmp/lazygit
  success "lazygit installed"
fi

# ---- delta (better git diff) ------------------------------------------------

section "Installing delta"

if command -v delta &>/dev/null; then
  success "delta already installed: $(delta --version)"
elif is_dry_run; then
  info "[dry-run] would install delta v${DELTA_VERSION} (.deb from GitHub)"
else
  DELTA_DEB="git-delta_${DELTA_VERSION}_amd64.deb"
  wget -qO "/tmp/${DELTA_DEB}" "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/${DELTA_DEB}"
  sudo dpkg -i "/tmp/${DELTA_DEB}"
  rm -f "/tmp/${DELTA_DEB}"
  success "delta installed"
fi

# ---- starship prompt --------------------------------------------------------

section "Installing starship"

if command -v starship &>/dev/null; then
  success "starship already installed: $(starship --version | head -1)"
elif is_dry_run; then
  info "[dry-run] would install starship via starship.rs/install.sh"
else
  curl -sS https://starship.rs/install.sh | sh -s -- --yes
  success "starship installed"
fi

# ---- zoxide (smart cd) ------------------------------------------------------

section "Installing zoxide"

if command -v zoxide &>/dev/null; then
  success "zoxide already installed"
elif is_dry_run; then
  info "[dry-run] would install zoxide via ajeetdsouza/zoxide install.sh"
else
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
  success "zoxide installed to ~/.local/bin"
fi

# ---- gh CLI (GitHub's official apt repo) ------------------------------------

section "Installing gh CLI"

if command -v gh &>/dev/null; then
  success "gh already installed: $(gh --version | head -1)"
elif is_dry_run; then
  info "[dry-run] would install gh CLI from cli.github.com apt repo"
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
elif is_dry_run; then
  info "[dry-run] would install fnm to ~/.local/bin"
else
  curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "$HOME/.local/bin" --skip-shell
  success "fnm installed to ~/.local/bin"
  info "fnm will be activated on next shell reload (via .zshrc)"
fi

# ---- zsh (if not installed) -------------------------------------------------

if ! command -v zsh &>/dev/null; then
  section "Installing zsh"
  if is_dry_run; then
    info "[dry-run] would install zsh via apt"
  else
    sudo apt-get install -y -qq zsh
    info "zsh installed. To set as default shell: chsh -s \$(which zsh)"
  fi
fi

# ---- Symlinks ---------------------------------------------------------------

section "Symlinking config files"
link "$DOTFILES/zsh/.zshrc"             "$HOME/.zshrc"
link "$DOTFILES/tmux/.tmux.conf"        "$HOME/.tmux.conf"
link "$DOTFILES/starship/starship.toml" "$HOME/.config/starship.toml"
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

run git config --global init.templatedir "$DOTFILES/agent-base/git-templates"
success "Git templates configured to use dotfiles/agent-base/git-templates"

GITCONFIG_LOCAL="$HOME/.gitconfig.local"
if [ ! -f "$GITCONFIG_LOCAL" ]; then
  if is_dry_run; then
    info "[dry-run] would create ~/.gitconfig.local with credential helper"
  else
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
  fi
else
  info "~/.gitconfig.local already exists — skipping"
fi

# ---- Summary ----------------------------------------------------------------

section "Core Setup Done"
echo ""
echo "  Reload your shell:"
echo "    source ~/.zshrc   # or: exec zsh"
echo ""
