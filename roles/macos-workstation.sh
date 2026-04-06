#!/usr/bin/env bash
# roles/macos-workstation.sh — macOS development workstation role.
#
# Installs: dotfiles symlinks + all Homebrew packages from Brewfile.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
source "$DOTFILES/scripts/lib.sh"

section "Role: macos-workstation"

bash "$DOTFILES/setup.sh"
run brew bundle --file="$DOTFILES/Brewfile"

success "Role macos-workstation applied"
