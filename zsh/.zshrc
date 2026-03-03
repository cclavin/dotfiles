export PATH="$HOME/.local/bin:$PATH"

# Claude Code - start in projects directory
alias claude='cd ~/projects && claude'

# API Keys (stored securely in macOS Keychain)
export ANTHROPIC_API_KEY=$(security find-generic-password -a "$USER" -s ANTHROPIC_API_KEY -w 2>/dev/null)

# New project scaffold: copies _template, inits git, creates private GitHub repo
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
