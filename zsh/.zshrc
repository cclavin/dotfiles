export PATH="$HOME/.local/bin:$PATH"

# Show system info only when a fresh tmux session is about to be created (not on re-attach).
if [[ -z "$TMUX" && -t 0 ]] \
   && { [[ "$OSTYPE" == "darwin"* && "$TERM_PROGRAM" != "vscode" ]] \
        || [[ -n "$WT_SESSION" ]] \
        || [[ ( -n "$SSH_CLIENT" || -n "$SSH_TTY" ) && -z "$VSCODE_INJECTION" ]]; } \
   && command -v fastfetch &>/dev/null \
   && command -v tmux &>/dev/null \
   && ! tmux has-session -t main 2>/dev/null; then
  fastfetch
fi

# Auto-attach to (or create) the main tmux session.
# macOS: skip only VS Code (TERM_PROGRAM is reliable on native macOS).
# WSL/Linux: Windows Terminal (WT_SESSION) or SSH (SSH_CLIENT/SSH_TTY), but not VS Code Remote.
if [[ -z "$TMUX" && -t 0 ]] \
   && { [[ "$OSTYPE" == "darwin"* && "$TERM_PROGRAM" != "vscode" ]] \
        || [[ -n "$WT_SESSION" ]] \
        || [[ ( -n "$SSH_CLIENT" || -n "$SSH_TTY" ) && -z "$VSCODE_INJECTION" ]]; } \
   && command -v tmux &>/dev/null; then
  exec tmux new-session -A -s main
fi

# mise — polyglot runtime manager (Node, Python, Go, etc.)
# Falls back to fnm on machines not yet migrated to mise.
if command -v mise &>/dev/null; then
  eval "$(mise activate zsh)"
elif command -v fnm &>/dev/null; then
  eval "$(fnm env --use-on-cd --shell zsh)"
fi

# Go — compiler and installed tools (go install puts binaries in $GOPATH/bin)
[[ -d /usr/local/go/bin ]] && export PATH="$PATH:/usr/local/go/bin"
[[ -d "$HOME/go/bin" ]]    && export PATH="$PATH:$HOME/go/bin"

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

# Syntax highlighting — fsh on WSL (avoids per-keystroke filesystem probes over
# VirtioFS); falls back to zsh-syntax-highlighting on macOS/Linux. To switch
# any machine to zsh-syntax-highlighting, simply remove ~/.fsh and restart.
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

# Auto-fetch git remote in background on directory change (keeps Starship ahead/behind counts fresh)
# After fetch completes, SIGUSR1 triggers a prompt redraw so behind/ahead shows on first visit.
# Guarded to interactive shells only — non-interactive shells (agents, scripts) lack ZLE.
# _zle_at_prompt flag prevents reset-prompt firing during command execution (which would print
# the raw $PROMPT string literally because zle returns true whenever ZLE is enabled, not only
# when sitting at the prompt).
if [[ -o interactive ]]; then
  _zle_at_prompt=0
  precmd_functions+=( _zle_mark_at_prompt )
  preexec_functions+=( _zle_mark_not_at_prompt )
  _zle_mark_at_prompt() { _zle_at_prompt=1 }
  _zle_mark_not_at_prompt() { _zle_at_prompt=0 }
  _git_fetch_and_refresh() { git fetch --quiet 2>/dev/null; kill -USR1 $$ }
  TRAPUSR1() { (( _zle_at_prompt )) && zle reset-prompt 2>/dev/null }
  chpwd() { git rev-parse --git-dir &>/dev/null && _git_fetch_and_refresh &| }
fi

# ---- Secure secret loading --------------------------------------------------
# Preferred stores (encrypted, never committed):
#   macOS:        macOS Keychain (security command)
#   Linux/WSL:    pass (GPG-encrypted) — preferred; falls back to GNOME libsecret
# Pre-GPG fallback: ~/.env.secrets (plain-text, chmod 600, never committed)
#
# To store a secret:
#   macOS:  security add-generic-password -a "$USER" -s KEY_NAME -w
#   Linux:  pass insert api-keys/KEY_NAME
#           or: secret-tool store --label="KEY_NAME" application KEY_NAME
#   Any:    echo 'export KEY_NAME=value' >> ~/.env.secrets && chmod 600 ~/.env.secrets
_load_secret() {
  local key="$1"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    security find-generic-password -a "$USER" -s "$key" -w 2>/dev/null
  elif command -v pass &>/dev/null; then
    pass "api-keys/$key" 2>/dev/null
  elif command -v secret-tool &>/dev/null; then
    secret-tool lookup application "$key" 2>/dev/null
  fi
  # Returns empty string when no store is configured — key falls through to ~/.env.secrets
}

# Source flat fallback first; credential store is checked next and wins when it returns a value.
[[ -f ~/.env.secrets ]] && source ~/.env.secrets
for _secret_key in ANTHROPIC_API_KEY EXA_API_KEY; do
  _secret_val=$(_load_secret "$_secret_key")
  [[ -n "$_secret_val" ]] && export "$_secret_key=$_secret_val"
done
unset _secret_key _secret_val

# ---- New project scaffold ---------------------------------------------------
# Copies _template, runs ai-init, inits git, creates a private GitHub repo.
# Usage: new-project <name> [--lang <template>] [--public]
#   --lang go | python | nextjs   runs ai-init to populate CLAUDE.md
#   --public                       creates a public GitHub repo
new-project() {
  local name="${1:?Usage: new-project <name> [--lang <template>] [--public]}"
  local visibility="--private"
  local lang=""

  shift
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --public) visibility="--public" ;;
      --lang)   lang="${2:?--lang requires a value}"; shift ;;
    esac
    shift
  done

  local code_base="$HOME/workspace/code"
  local template="$code_base/_template"
  local dest="$code_base/$name"

  if [[ -d "$dest" ]]; then
    echo "Error: $dest already exists" >&2
    return 1
  fi

  if [[ ! -d "$template" ]]; then
    echo "Error: _template not found at $template" >&2
    return 1
  fi

  cp -r "$template" "$dest"
  cd "$dest" || return 1

  if [[ -n "$lang" ]]; then
    ai-init "$lang"
  fi

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
  read -rk 1 "answer?Pull all repos? [y/N] "
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

  read -rk 1 "answer?Clone ${#missing[@]} missing repo(s) into $code_dir? [y/N] "
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
