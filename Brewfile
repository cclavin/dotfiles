# Brewfile — reproducible macOS tool installation
# Usage: brew bundle
# Install everything: cd ~/dotfiles && brew bundle

# ---- Core tools -------------------------------------------------------------
brew "git"
brew "gh"           # GitHub CLI
brew "gnupg"        # GPG for commit signing and pass encryption

# ---- Node -------------------------------------------------------------------
brew "fnm"          # Fast Node version manager (replaces nvm, much faster)

# ---- Shell / terminal -------------------------------------------------------
brew "fzf"                      # Fuzzy finder (Ctrl+R history, Ctrl+T file search)
brew "ripgrep"                  # Fast grep — used by Claude Code and VS Code search
brew "jq"                       # JSON processor
brew "starship"                 # Cross-shell prompt
brew "zoxide"                   # Smart cd (use 'z' instead of 'cd')
brew "zsh-autosuggestions"      # Grey ghost completions as you type
brew "zsh-syntax-highlighting"  # Syntax coloring in shell (must source last)
brew "git-delta"                # Better git diffs (referenced in .gitconfig)

# ---- Productivity (optional) ------------------------------------------------
# Comment out anything you don't want
brew "bat"          # Better cat with syntax highlighting
brew "eza"          # Better ls with colours and git status
brew "tldr"         # Simplified man pages

# ---- Fonts ------------------------------------------------------------------
cask "ghostty"                        # GPU-accelerated terminal emulator
cask "font-jetbrains-mono-nerd-font"  # Required for Starship glyphs

# ---- Security ---------------------------------------------------------------
brew "pass"         # GPG-encrypted password store (cross-platform compatible)
