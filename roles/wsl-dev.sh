#!/usr/bin/env bash
# roles/wsl-dev.sh — WSL2 development workstation role.
#
# Installs: core Linux tools + cloud toolchain (Docker skipped — Docker
# Desktop manages the Docker daemon on WSL2).

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
source "$DOTFILES/scripts/lib.sh"

section "Role: wsl-dev"

bash "$DOTFILES/scripts/linux-core.sh"
bash "$DOTFILES/scripts/linux-cloud.sh" --skip-docker

success "Role wsl-dev applied"
