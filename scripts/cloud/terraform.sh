#!/usr/bin/env bash
# scripts/cloud/terraform.sh — Install HashiCorp Terraform from HashiCorp's apt repo.
#
# Called by scripts/linux-cloud.sh. Can also be run standalone.
# Respects DISTRO_CODENAME exported by linux-cloud.sh if set.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$DOTFILES/scripts/lib.sh"

section "Installing HashiCorp Terraform CLI"

if command -v terraform &>/dev/null; then
  success "Terraform already installed"
  exit 0
fi

if is_dry_run; then
  info "[dry-run] would install Terraform from apt.releases.hashicorp.com apt repo"
  exit 0
fi

DISTRO_CODENAME="${DISTRO_CODENAME:-$(lsb_release -cs)}"

info "Adding HashiCorp repository..."
curl -fsSL https://apt.releases.hashicorp.com/gpg | \
  sudo gpg --dearmor --yes -o /etc/apt/keyrings/hashicorp-archive-keyring.gpg
sudo chmod a+r /etc/apt/keyrings/hashicorp-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $DISTRO_CODENAME main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null

sudo apt-get update -qq
sudo apt-get install -y -qq terraform

success "Terraform installed"
