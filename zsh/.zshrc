export PATH="$HOME/.local/bin:$PATH"

# Claude Code - start in projects directory
alias claude='cd ~/projects && claude'

# API Keys (stored securely in macOS Keychain)
export ANTHROPIC_API_KEY=$(security find-generic-password -a "$USER" -s ANTHROPIC_API_KEY -w 2>/dev/null)
