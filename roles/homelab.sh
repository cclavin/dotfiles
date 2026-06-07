#!/usr/bin/env bash
# roles/homelab.sh — Self-hosted services / homelab server role.
#
# Installs: core Linux tools + Docker. Skips cloud-provider tooling
# (GCP CLI, Terraform) since a homelab host runs containers, not cloud
# deploys. Go is kept — service repos built on the box (e.g. esa) need it.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
source "$DOTFILES/scripts/lib.sh"

section "Role: homelab"

bash "$DOTFILES/scripts/linux-core.sh"
bash "$DOTFILES/scripts/linux-cloud.sh" --skip-gcloud --skip-terraform

success "Role homelab applied"
