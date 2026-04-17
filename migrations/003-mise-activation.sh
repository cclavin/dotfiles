#!/usr/bin/env bash
# migrations/003-mise-activation.sh
#
# Marker: mise is now the standard runtime manager, replacing fnm for Node
# and adding Python version management.
#
# No destructive action is taken here. fnm is left in place so machines not
# yet migrated continue to work. The .zshrc fallback activates fnm when mise
# is absent.
#
# To complete the migration on this machine after bootstrap:
#   mise install           # install Node LTS + Python 3.12 from mise/config.toml
#   node --version         # should resolve via ~/.local/share/mise/shims/node
#   python3 --version      # should resolve via mise shims
#
# Once confirmed on all machines, fnm can be removed:
#   macOS:  brew remove fnm
#   Linux:  rm ~/.local/bin/fnm

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES/scripts/lib.sh"

success "mise-activation marker applied — run 'mise install' to install runtimes"
