#!/usr/bin/env bash
# scripts/workspace-init.sh — Idempotent workspace directory setup.
#
# Creates ~/workspace/{code,vault} and optionally migrates
# an existing Obsidian vault from its legacy location.
#
# Safe to re-run — all operations are idempotent.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES/scripts/lib.sh"

# ---- Paths ------------------------------------------------------------------

WORKSPACE="$HOME/workspace"
CODE_DIR="$WORKSPACE/code"
VAULT_DIR="$WORKSPACE/vault"

# Override via env var for non-standard legacy vault locations
OLD_VAULT="${OBSIDIAN_VAULT_SRC:-$HOME/Documents/ObsidianVault/Vault}"

# ---- Create workspace structure ---------------------------------------------

section "Workspace directories"

run mkdir -p "$CODE_DIR"
success "code/   →  $CODE_DIR"

# Symlink _template into workspace/code so new-project can find it
TEMPLATE_LINK="$CODE_DIR/_template"
TEMPLATE_SRC="$DOTFILES/templates/_base"
if [[ -L "$TEMPLATE_LINK" ]]; then
  success "_template →  $TEMPLATE_LINK (symlink already exists)"
elif [[ -d "$TEMPLATE_LINK" ]]; then
  warn "_template exists as a real directory at $TEMPLATE_LINK — skipping symlink"
elif is_dry_run; then
  info "[dry-run] would symlink $TEMPLATE_LINK → $TEMPLATE_SRC"
else
  ln -sf "$TEMPLATE_SRC" "$TEMPLATE_LINK"
  success "_template →  $TEMPLATE_LINK → $TEMPLATE_SRC"
fi

# On WSL: if WINDOWS_VAULT_PATH is set, symlink vault to the Windows filesystem
# so Obsidian (Windows) and the terminal (WSL) share the same files.
# Set WINDOWS_VAULT_PATH in ~/.zshrc.local before running bootstrap.
if $IS_WSL && [[ -n "${WINDOWS_VAULT_PATH:-}" ]]; then
  if [[ -L "$VAULT_DIR" ]]; then
    success "vault/  →  $VAULT_DIR (symlink already exists)"
  elif is_dry_run; then
    info "[dry-run] would symlink $VAULT_DIR → $WINDOWS_VAULT_PATH"
  else
    # Remove empty dir created by a previous bootstrap run, if present
    if [[ -d "$VAULT_DIR" && -z "$(ls -A "$VAULT_DIR" 2>/dev/null)" ]]; then
      rmdir "$VAULT_DIR"
    fi
    ln -sf "$WINDOWS_VAULT_PATH" "$VAULT_DIR"
    success "vault/  →  $VAULT_DIR → $WINDOWS_VAULT_PATH (WSL symlink)"
  fi
else
  run mkdir -p "$VAULT_DIR"
  success "vault/  →  $VAULT_DIR"
fi

# ---- Vault migration (new machine only) -------------------------------------

section "Obsidian vault"

vault_has_content() {
  [ -n "$(ls -A "$VAULT_DIR" 2>/dev/null)" ]
}

if is_dry_run; then
  info "[dry-run] would check for legacy vault at $OLD_VAULT and migrate if found"
elif vault_has_content; then
  success "vault already populated — skipping migration"
elif [ -d "$OLD_VAULT" ]; then
  warn "Found legacy vault at: $OLD_VAULT"
  echo ""
  read -r -p "  Migrate vault to $VAULT_DIR? [y/N] " -n 1 answer
  echo ""
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    rsync -a "$OLD_VAULT/" "$VAULT_DIR/"
    success "vault migrated (legacy copy untouched at $OLD_VAULT)"
  else
    info "Migration skipped"
    info "To migrate later: rsync -a \"$OLD_VAULT/\" \"$VAULT_DIR/\""
  fi
else
  info "No legacy vault found at $OLD_VAULT"
  info "Set OBSIDIAN_VAULT_SRC to override the source path"
  info "Or clone your vault repo into: $VAULT_DIR"
fi

# ---- Vault git sync (opt-in: only if vault is a git repo) ------------------

if ! is_dry_run; then
  if git -C "$VAULT_DIR" rev-parse --git-dir &>/dev/null 2>&1; then
    if git -C "$VAULT_DIR" remote get-url origin &>/dev/null 2>&1; then
      info "Vault is a git repo — pulling latest..."
      git -C "$VAULT_DIR" pull --ff-only \
        && success "vault updated" \
        || warn "vault pull failed — check manually"
    else
      info "Vault is a local-only git repo — skipping pull"
    fi
  else
    info "Vault git sync not enabled"
    info "To enable: cd \"$VAULT_DIR\" && git init (local-only) or add a remote for sync"
  fi
fi

# ---- Summary ----------------------------------------------------------------

section "Done"
echo ""
echo "  Workspace: $WORKSPACE"
echo "    code/   $CODE_DIR"
echo "    vault/  $VAULT_DIR"
echo ""
echo "  If dotfiles were already installed on this machine, reload your shell:"
echo "    source ~/.zshrc"
echo ""
