export PATH="$HOME/.local/bin:$PATH"

# Auto-attach to (or create) the main tmux session on every interactive open.
# Guards: skip if already inside tmux, inside VS Code's terminal, or tmux is absent.
if [[ -z "$TMUX" && -z "$VSCODE_INJECTION" ]] && command -v tmux &>/dev/null; then
  exec tmux new-session -A -s main
fi

# mise — polyglot runtime manager (Node, Python, Go, etc.)
# Falls back to fnm on machines not yet migrated to mise.
if command -v mise &>/dev/null; then
  eval "$(mise activate zsh)"
elif command -v fnm &>/dev/null; then
  eval "$(fnm env --use-on-cd --shell zsh)"
fi

# Go — PATH for /usr/local/go installs (cloud/go.sh); no-op when Go is absent
[[ -d /usr/local/go/bin ]] && export PATH="$PATH:/usr/local/go/bin"

# Starship prompt
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
fi

# Zoxide (smart cd — use 'z' instead of 'cd')
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
fi

# fzf key bindings (Ctrl+R fuzzy history, Ctrl+T file search)
[[ -f /opt/homebrew/opt/fzf/shell/key-bindings.zsh ]] && source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
[[ -f /usr/local/opt/fzf/shell/key-bindings.zsh ]]    && source /usr/local/opt/fzf/shell/key-bindings.zsh
[[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]] && source /usr/share/doc/fzf/examples/key-bindings.zsh
[[ -f /usr/share/fzf/key-bindings.zsh ]]               && source /usr/share/fzf/key-bindings.zsh

# zsh-autosuggestions (grey ghost completions as you type)
[[ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]          && source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Syntax highlighting — fast-syntax-highlighting preferred (avoids per-keystroke
# filesystem probes on WSL); falls back to the stock package on macOS/Homebrew.
[[ -f ~/.fsh/fast-syntax-highlighting.plugin.zsh ]]                               && source ~/.fsh/fast-syntax-highlighting.plugin.zsh
[[ ! -f ~/.fsh/fast-syntax-highlighting.plugin.zsh && -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
[[ ! -f ~/.fsh/fast-syntax-highlighting.plugin.zsh && -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]          && source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Better ls/cat (eza + bat — graceful fallback if not installed)
if command -v eza &>/dev/null; then
  alias ls='eza --color=auto --group-directories-first'
  alias ll='eza -alF --git'
  alias tree='eza --tree'
fi
if command -v batcat &>/dev/null; then
  alias cat='batcat --style=plain --paging=never'
elif command -v bat &>/dev/null; then
  alias cat='bat --style=plain --paging=never'
fi

# Workspace navigation
alias cw='cd ~/workspace/code'

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

  local code_base="$HOME/workspace/code"

  local dest="$code_base/$name"
  if [[ -d "$dest" ]]; then
    echo "Error: $dest already exists" >&2
    return 1
  fi

  cp -r "$code_base/_template" "$dest"
  cd "$dest" || return 1
  git init && git add . && git commit -m "Initial commit"
  gh repo create "$name" "$visibility" --source=. --remote=origin --push
  echo "Ready: https://github.com/cclavin/$name"
}

# ---- Sync workspace/code repos ----------------------------------------------
# Shows git status for every repo in workspace/code, then pulls on confirmation.
# Usage: sync-code
sync-code() {
  local code_dir="$HOME/workspace/code"
  local repos=()
  for d in "$code_dir"/*/; do
    [[ -d "$d/.git" ]] && repos+=("$d")
  done

  if [[ ${#repos[@]} -eq 0 ]]; then
    echo "No git repos found in $code_dir"
    return 0
  fi

  echo ""
  echo "── Repos in workspace/code ──────────────────────────"
  local dirty_repos=()
  for repo in "${repos[@]}"; do
    local name tracking dirty
    name="$(basename "$repo")"
    git -C "$repo" fetch --quiet 2>/dev/null
    tracking="$(git -C "$repo" status -sb 2>/dev/null | head -1)"
    dirty="$(git -C "$repo" status --short 2>/dev/null)"
    if [[ -n "$dirty" ]]; then
      echo "  $name  →  $tracking  [UNCOMMITTED CHANGES]"
      dirty_repos+=("$name")
    else
      echo "  $name  →  $tracking"
    fi
  done

  if [[ ${#dirty_repos[@]} -gt 0 ]]; then
    echo ""
    echo "  Repos with uncommitted changes: ${dirty_repos[*]}"
    echo "  Commit or stash before pulling to avoid conflicts."
  fi

  echo ""
  read -r -p "Pull all repos? [y/N] " -n 1 answer
  echo ""
  [[ "$answer" =~ ^[Yy]$ ]] || return 0

  for repo in "${repos[@]}"; do
    local name
    name="$(basename "$repo")"
    echo "  Pulling $name..."
    git -C "$repo" pull --ff-only 2>&1 | sed 's/^/    /'
  done
  echo ""
  echo "Done."
}

# ---- Clone repos missing from workspace/code --------------------------------
# Compares ~/workspace/code against your GitHub repos and clones any absent ones.
# Usage: clone-missing [--dry-run]
clone-missing() {
  local code_dir="$HOME/workspace/code"
  local dry_run=false
  [[ "${1:-}" == "--dry-run" ]] && dry_run=true

  if ! command -v gh &>/dev/null; then
    echo "gh CLI not found" >&2
    return 1
  fi

  echo ""
  echo "── Checking GitHub repos vs $code_dir ──────────────────"

  local missing=()
  while IFS= read -r repo; do
    local name
    name="$(basename "$repo")"
    if [[ ! -d "$code_dir/$name/.git" ]]; then
      missing+=("$repo")
    fi
  done < <(gh repo list --limit 100 --json nameWithOwner --jq '.[].nameWithOwner')

  if [[ ${#missing[@]} -eq 0 ]]; then
    echo "  All GitHub repos already cloned."
    echo ""
    return 0
  fi

  echo ""
  for repo in "${missing[@]}"; do
    echo "  missing: $repo"
  done
  echo ""

  if $dry_run; then
    echo "  (dry-run — nothing cloned)"
    return 0
  fi

  read -r -p "Clone ${#missing[@]} missing repo(s) into $code_dir? [y/N] " -n 1 answer
  echo ""
  [[ "$answer" =~ ^[Yy]$ ]] || return 0

  for repo in "${missing[@]}"; do
    local name
    name="$(basename "$repo")"
    echo "  Cloning $repo..."
    gh repo clone "$repo" "$code_dir/$name" -- --quiet 2>&1 | sed 's/^/    /'
  done
  echo ""
  echo "Done."
}

# Machine-local shell customizations (not tracked in dotfiles)
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
