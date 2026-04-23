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

# Ensure tools installed to ~/.local/bin are findable within this session.
# .zshrc sets this for interactive shells; we need it here for command -v
# checks that run immediately after installing mise, uv, zoxide, etc.
export PATH="$HOME/.local/bin:$PATH"

section "Workspace"
bash "$DOTFILES/scripts/workspace-init.sh"

# ---- Package installation ---------------------------------------------------

section "Installing packages via apt"

if ! command -v sudo &>/dev/null; then
  warn "sudo not found — you may need to run as root or install sudo"
fi

if is_dry_run; then
  info "[dry-run] would install via apt: git curl unzip gnupg pass jq ripgrep fzf xz-utils tmux zsh-autosuggestions zsh-syntax-highlighting bat"
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

# ---- eza (better ls) --------------------------------------------------------
# eza is in Ubuntu 24.04+ apt repos; install from GitHub releases on 22.04.

section "Installing eza"

if command -v eza &>/dev/null; then
  success "eza already installed: $(eza --version | head -1)"
elif is_dry_run; then
  info "[dry-run] would install eza (apt on Ubuntu 24.04+, GitHub release otherwise)"
elif apt-cache show eza &>/dev/null 2>&1; then
  sudo apt-get install -y -qq eza
  success "eza installed via apt"
else
  EZA_VERSION=$(curl -s "https://api.github.com/repos/eza-community/eza/releases/latest" \
    | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')
  wget -qO /tmp/eza.deb \
    "https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/eza_${EZA_VERSION}_amd64.deb"
  sudo dpkg -i /tmp/eza.deb
  rm -f /tmp/eza.deb
  success "eza installed from GitHub release (v${EZA_VERSION})"
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

# ---- mise (polyglot runtime manager — replaces fnm) -------------------------

section "Installing mise"

if command -v mise &>/dev/null; then
  success "mise already installed: $(mise --version)"
elif is_dry_run; then
  info "[dry-run] would install mise via mise.run"
else
  curl https://mise.run | sh
  success "mise installed to ~/.local/bin/mise"
  info "mise will be activated on next shell reload (via .zshrc)"
fi

# ---- uv (Python package/project/tool manager) -------------------------------

section "Installing uv"

if command -v uv &>/dev/null; then
  success "uv already installed: $(uv --version)"
elif is_dry_run; then
  info "[dry-run] would install uv via astral.sh/uv"
else
  curl -LsSf https://astral.sh/uv/install.sh | sh
  success "uv installed to ~/.local/bin/uv"
fi

# ---- fnm (Node version manager — legacy fallback) ---------------------------
# Kept for machines not yet migrated to mise. The .zshrc activates fnm only
# when mise is absent. Remove after all machines confirm mise is working.

section "Installing fnm"

if command -v fnm &>/dev/null; then
  success "fnm already installed: $(fnm --version)"
elif command -v mise &>/dev/null; then
  info "mise is present — skipping fnm install"
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
link "$DOTFILES/ghostty/config"        "$HOME/.config/ghostty/config"
link "$DOTFILES/mise/config.toml"      "$HOME/.config/mise/config.toml"
# Trust the symlinked config — mise requires explicit trust for files that
# resolve outside ~/.config/mise/ (i.e. symlinks into the dotfiles repo).
if command -v mise &>/dev/null; then
  run mise trust "$HOME/.config/mise/config.toml"
fi
link "$DOTFILES/git/.gitconfig"         "$HOME/.gitconfig"
link "$DOTFILES/.editorconfig"          "$HOME/.editorconfig"
link "$DOTFILES/.prettierrc"            "$HOME/.prettierrc"
link "$DOTFILES/claude/CLAUDE.md"       "$HOME/.claude/CLAUDE.md"

# settings.json — create from template if missing (machine-owned, not symlinked).
# MCP servers get merged in by mcp/deploy.py after this step.
if [ ! -f "$HOME/.claude/settings.json" ] && [ ! -L "$HOME/.claude/settings.json" ]; then
  run mkdir -p "$HOME/.claude"
  run cp "$DOTFILES/claude/settings.json.example" "$HOME/.claude/settings.json"
  success "created ~/.claude/settings.json from template"
else
  info "~/.claude/settings.json already exists -- skipping"
fi

# Agent Rules Polyfills (points IDEs to the repository source of truth)
link "$DOTFILES/AGENTS.md"              "$DOTFILES/.cursorrules"
link "$DOTFILES/AGENTS.md"              "$DOTFILES/.windsurfrules"
link "$DOTFILES/AGENTS.md"              "$DOTFILES/.github/copilot-instructions.md"
link "$DOTFILES/AGENTS.md"              "$DOTFILES/CLAUDE.md"

# Agent Template CLI (Strategy B) - Adds ai-init to $PATH
link "$DOTFILES/bin/ai-init"            "$HOME/.local/bin/ai-init"

# ---- Git Templates & Config -------------------------------------------------

section "Git config & templates"

GITCONFIG_LOCAL="$HOME/.gitconfig.local"
if [ ! -f "$GITCONFIG_LOCAL" ]; then
  if is_dry_run; then
    info "[dry-run] would create ~/.gitconfig.local with credential helper"
  else
    cp "$DOTFILES/git/.gitconfig.local.example" "$GITCONFIG_LOCAL"

    # On WSL2: use Git Credential Manager from Windows if available
    if $IS_WSL && command -v "/mnt/c/Program Files/Git/mingw64/bin/git-credential-manager.exe" &>/dev/null; then
      # ! prefix tells git to run the value as a shell command, so the quoted
      # path with spaces is handled correctly by the shell at execution time.
      git config --file "$GITCONFIG_LOCAL" credential.helper \
        '!"/mnt/c/Program Files/Git/mingw64/bin/git-credential-manager.exe"'
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

# templatedir is a machine-specific absolute path — write to .gitconfig.local,
# not the tracked .gitconfig, so bootstrap never dirties the repo.
if is_dry_run; then
  info "[dry-run] would set init.templatedir in ~/.gitconfig.local"
else
  git config --file "$GITCONFIG_LOCAL" init.templatedir "$DOTFILES/agent-base/git-templates"
  success "Git templates configured → ~/.gitconfig.local"
fi

# ---- MCP servers ------------------------------------------------------------

section "MCP servers"
bash "$DOTFILES/scripts/mcp-setup.sh"

# ---- Summary ----------------------------------------------------------------

section "Core Setup Done"
echo ""
echo "  Reload your shell:"
echo "    source ~/.zshrc   # or: exec zsh"
echo ""
echo "  Then install runtimes (Node LTS + Python 3.12):"
echo "    mise install"
echo ""
