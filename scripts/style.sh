#!/usr/bin/env bash
# scripts/style.sh — Optional styling and theming.
#
# Usage:
#   bash style.sh [minimal|enhanced]
#   ./bootstrap.sh --style enhanced
#
# Tiers:
#   minimal   Default. No changes — use the shell as configured.
#   enhanced  Install JetBrainsMono Nerd Font for richer terminal icons.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES/scripts/lib.sh"

STYLE_LEVEL="${1:-minimal}"

section "Styling: $STYLE_LEVEL"

case "$STYLE_LEVEL" in

  minimal)
    info "Minimal styling — no changes needed"
    ;;

  enhanced)
    # ---- Nerd Font: JetBrainsMono ----
    if $IS_MACOS; then
      if brew list --cask font-jetbrains-mono-nerd-font &>/dev/null 2>&1; then
        success "JetBrainsMono Nerd Font already installed"
      else
        info "Installing JetBrainsMono Nerd Font via Homebrew..."
        run brew tap homebrew/cask-fonts 2>/dev/null || true
        run brew install --cask font-jetbrains-mono-nerd-font
        success "JetBrainsMono Nerd Font installed"
      fi

    elif $IS_LINUX; then
      FONT_DIR="$HOME/.local/share/fonts"
      if fc-list 2>/dev/null | grep -qi "JetBrainsMono Nerd"; then
        success "JetBrainsMono Nerd Font already installed"
      else
        info "Installing JetBrainsMono Nerd Font..."
        run mkdir -p "$FONT_DIR"
        FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
        run curl -sLo /tmp/JetBrainsMono.tar.xz "$FONT_URL"
        run tar -xf /tmp/JetBrainsMono.tar.xz -C "$FONT_DIR"
        run rm -f /tmp/JetBrainsMono.tar.xz
        fc-cache -f "$FONT_DIR" 2>/dev/null || true
        success "JetBrainsMono Nerd Font installed"
      fi
    fi

    echo ""
    info "Set your terminal font to 'JetBrainsMono Nerd Font Mono' to see icons."
    if $IS_WSL; then
      info "In Windows Terminal: Settings → Profiles → Appearance → Font face."
    fi
    ;;

  *)
    warn "Unknown style level: '$STYLE_LEVEL' (use 'minimal' or 'enhanced')"
    exit 1
    ;;

esac
