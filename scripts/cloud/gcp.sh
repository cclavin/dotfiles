#!/usr/bin/env bash
# scripts/cloud/gcp.sh — Install Google Cloud CLI from Google's official apt repo.
#
# Called by scripts/linux-cloud.sh. Can also be run standalone.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$DOTFILES/scripts/lib.sh"

section "Installing Google Cloud CLI"

if command -v gcloud &>/dev/null; then
  success "Google Cloud CLI already installed"
  exit 0
fi

if is_dry_run; then
  info "[dry-run] would install Google Cloud CLI from packages.cloud.google.com apt repo"
  exit 0
fi

info "Adding Google Cloud repository..."
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
  sudo gpg --dearmor --yes -o /etc/apt/keyrings/cloud.google.gpg
sudo chmod a+r /etc/apt/keyrings/cloud.google.gpg

echo "deb [signed-by=/etc/apt/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
  sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list > /dev/null

sudo apt-get update -qq
sudo apt-get install -y -qq google-cloud-cli

success "Google Cloud CLI installed"
