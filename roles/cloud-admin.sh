#!/usr/bin/env bash
# roles/cloud-admin.sh — Cloud administration role.
#
# Installs: core Linux tools + full cloud toolchain
# (Go, Docker Engine, Google Cloud CLI, Terraform).

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
source "$DOTFILES/scripts/lib.sh"

section "Role: cloud-admin"

bash "$DOTFILES/scripts/linux-core.sh"
bash "$DOTFILES/scripts/linux-cloud.sh"

success "Role cloud-admin applied"
