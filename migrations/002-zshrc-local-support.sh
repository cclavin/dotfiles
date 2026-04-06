#!/usr/bin/env bash
# Migration 002 — Record that ~/.zshrc.local sourcing is now supported.
#
# The actual change (sourcing ~/.zshrc.local) is in zsh/.zshrc. This migration
# is a marker so upgrade runs know this version is applied.
# No filesystem changes needed.

set -euo pipefail

echo "  [✓] ~/.zshrc.local sourcing supported (no action needed)"
