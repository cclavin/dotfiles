#!/usr/bin/env bash
# scripts/cloud/aws.sh — Install AWS CLI.
#
# TODO: Implement AWS CLI installation.
# Reference: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
#
# Called by scripts/linux-cloud.sh when --aws flag is added.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$DOTFILES/scripts/lib.sh"

section "Installing AWS CLI"
warn "AWS CLI installation not yet implemented"
warn "See: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
exit 1
