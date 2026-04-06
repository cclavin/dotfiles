#!/usr/bin/env bash
# roles/linux-dev.sh — Native Linux development workstation role.
#
# Installs: core Linux tools only. No cloud toolchain.
# Use cloud-admin role if cloud tools are needed.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
source "$DOTFILES/scripts/lib.sh"

section "Role: linux-dev"

bash "$DOTFILES/scripts/linux-core.sh"

success "Role linux-dev applied"
