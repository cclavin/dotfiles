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

DELTA_VERSION="0.18.2"
GO_VERSION="1.22.1"

# Future additions:
# LAZYGIT_VERSION=""    # currently fetched from GitHub API (latest)
# TERRAFORM_VERSION=""  # currently installed via apt (latest)
