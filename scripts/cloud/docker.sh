#!/usr/bin/env bash
# scripts/cloud/docker.sh — Install Docker Engine from Docker's official apt repo.
#
# Called by scripts/linux-cloud.sh. Can also be run standalone.
# Respects DISTRO_ID and DISTRO_CODENAME exported by linux-cloud.sh if set.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$DOTFILES/scripts/lib.sh"

section "Installing Docker Engine"

if command -v docker &>/dev/null; then
  success "Docker already available (Docker Desktop or existing install)"
  exit 0
fi

if is_dry_run; then
  info "[dry-run] would install Docker Engine from download.docker.com apt repo"
  exit 0
fi

DISTRO_ID="${DISTRO_ID:-$(lsb_release -is | tr '[:upper:]' '[:lower:]')}"
DISTRO_CODENAME="${DISTRO_CODENAME:-$(lsb_release -cs)}"

info "Adding Docker repository..."
curl -fsSL "https://download.docker.com/linux/$DISTRO_ID/gpg" | \
  sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$DISTRO_ID $DISTRO_CODENAME stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -qq
sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker "$USER"

success "Docker installed. (Re-login required to fully apply 'docker' group)"
