#!/bin/bash
# Bootstrap dotfiles on a new Mac.
# Run once after cloning: ./setup.sh

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Setting up dotfiles from $DOTFILES_DIR..."

# Helper: create symlink, backing up any existing file first
link() {
    local src="$1"
    local dest="$2"

    if [ -L "$dest" ]; then
        echo "  already linked: $dest"
        return
    fi

    if [ -f "$dest" ]; then
        echo "  backing up: $dest → $dest.bak"
        mv "$dest" "$dest.bak"
    fi

    mkdir -p "$(dirname "$dest")"
    ln -s "$src" "$dest"
    echo "  linked: $dest → $src"
}

link "$DOTFILES_DIR/zsh/.zshrc"            "$HOME/.zshrc"
link "$DOTFILES_DIR/git/.gitconfig"        "$HOME/.gitconfig"
link "$DOTFILES_DIR/claude/CLAUDE.md"      "$HOME/.claude/CLAUDE.md"
link "$DOTFILES_DIR/claude/settings.json"  "$HOME/.claude/settings.json"

echo ""
echo "Done. Reload your shell: source ~/.zshrc"
echo ""
echo "Remaining manual steps:"
echo "  1. Store API keys in Keychain:"
echo "       security add-generic-password -a \"\$USER\" -s ANTHROPIC_API_KEY -w"
echo "  2. Place Google credentials at ~/.gsc-intelligence/credentials.json"
