export PATH="$HOME/.local/bin:$PATH"

# fnm — fast Node version manager (installed via Homebrew on macOS, curl on Linux)
if command -v fnm &>/dev/null; then
  eval "$(fnm env --use-on-cd --shell zsh)"
fi

# Claude Code - start in projects directory
alias claude='cd ~/projects && claude'

# ---- Secure secret loading --------------------------------------------------
# Loads a secret from the OS-appropriate credential store.
# Never stores secrets in plain text files.
#
# macOS:        macOS Keychain (security command)
# Linux/WSL:    pass (gpg-encrypted password store) — preferred
#               Falls back to GNOME libsecret (secret-tool) if pass not found
#
# To store a secret:
#   macOS:  security add-generic-password -a "$USER" -s KEY_NAME -w
#   Linux:  pass insert api-keys/KEY_NAME
#           or: secret-tool store --label="KEY_NAME" application KEY_NAME
_load_secret() {
  local key="$1"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    security find-generic-password -a "$USER" -s "$key" -w 2>/dev/null
  elif command -v pass &>/dev/null; then
    pass "api-keys/$key" 2>/dev/null
  elif command -v secret-tool &>/dev/null; then
    secret-tool lookup application "$key" 2>/dev/null
  fi
  # Returns empty string if no store is available — keys will just be unset
}

export ANTHROPIC_API_KEY=$(_load_secret ANTHROPIC_API_KEY)

# ---- New project scaffold ---------------------------------------------------
# Copies _template, inits git, creates a private GitHub repo.
# Usage: new-project <name> [--public]
new-project() {
  local name="${1:?Usage: new-project <name> [--public]}"
  local visibility="--private"
  [[ "$*" == *--public* ]] && visibility="--public"

  local dest="$HOME/projects/$name"
  if [[ -d "$dest" ]]; then
    echo "Error: $dest already exists" >&2
    return 1
  fi

  cp -r "$HOME/projects/_template" "$dest"
  cd "$dest" || return 1
  git init && git add . && git commit -m "Initial commit"
  gh repo create "$name" "$visibility" --source=. --remote=origin --push
  echo "Ready: https://github.com/cclavin/$name"
}
