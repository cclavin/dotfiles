#!/usr/bin/env bash
# scripts/cloud/go.sh — Install Go from the official tarball.
#
# Version is sourced from scripts/versions.sh (GO_VERSION).
# Never uses apt or PPAs per AGENTS.md rules.
#
# Called by scripts/linux-cloud.sh. Can also be run standalone.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$DOTFILES/scripts/lib.sh"
source "$DOTFILES/scripts/versions.sh"

section "Installing Go"

if command -v go &>/dev/null && go version | grep -q "go1.22"; then
  success "Go 1.22+ already installed: $(go version)"
  exit 0
fi

if is_dry_run; then
  info "[dry-run] would install Go ${GO_VERSION} from go.dev/dl (linux-amd64 tarball to /usr/local/go)"
  exit 0
fi

GO_TAR="go${GO_VERSION}.linux-amd64.tar.gz"
GO_URL="https://go.dev/dl/${GO_TAR}"

info "Downloading Go ${GO_VERSION}..."
wget -qO "/tmp/${GO_TAR}" "${GO_URL}"

info "Removing any old Go installation and extracting tarball to /usr/local/go..."
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "/tmp/${GO_TAR}"
rm -f "/tmp/${GO_TAR}"

# Ensure /usr/local/go/bin is on PATH in ~/.zshrc
if ! grep -q "/usr/local/go/bin" "$HOME/.zshrc"; then
  info "Appending /usr/local/go/bin to ~/.zshrc..."
  echo '' >> "$HOME/.zshrc"
  echo '# Added by dotfiles cloud/go.sh setup' >> "$HOME/.zshrc"
  echo 'export PATH=$PATH:/usr/local/go/bin' >> "$HOME/.zshrc"
fi

export PATH=$PATH:/usr/local/go/bin

success "Go installed: $(go version)"
