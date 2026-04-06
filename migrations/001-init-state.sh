#!/usr/bin/env bash
# Migration 001 — Initialize local state directory.
#
# Creates ~/.local/share/dotfiles/ if it does not exist.
# This migration records that the state tracking system is in place.
# Safe to run on both fresh installs and existing systems.

set -euo pipefail

STATE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles"
mkdir -p "$STATE_DIR"
echo "  [✓] State directory ready: $STATE_DIR"
