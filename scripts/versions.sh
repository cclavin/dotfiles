#!/usr/bin/env bash
# scripts/versions.sh — Pinned tool versions (single source of truth).
# Source this file; do not execute it directly.
#
# Usage: source "$DOTFILES/scripts/versions.sh"
#
# To upgrade a tool: change the version here. All scripts that install
# the tool reference this file, so nothing else needs to change.

# Guard against double-sourcing
[[ -n "${_DOTFILES_VERSIONS_LOADED:-}" ]] && return 0
_DOTFILES_VERSIONS_LOADED=1

# ---- Pinned Versions --------------------------------------------------------

BW_CLI_VERSION="2026.5.0"
DELTA_VERSION="0.18.2"
FASTFETCH_VERSION="2.64.2"
YQ_VERSION="4.53.3"
GO_VERSION="1.26.1"

# Runtime versions managed by mise (see mise/config.toml for authoritative values)
NODE_VERSION="lts"      # LTS release; mise/config.toml is the active config
PYTHON_VERSION="3.12"   # global default; per-project .python-version overrides

# Future additions:
# LAZYGIT_VERSION=""    # currently fetched from GitHub API (latest)
# TERRAFORM_VERSION=""  # currently installed via apt (latest)
