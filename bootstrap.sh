#!/usr/bin/env bash
# bootstrap.sh — Master entrypoint for dotfiles setup
#
# Usage: ./bootstrap.sh

set -euo pipefail

# Change to dotfiles root regardless of where script was called from
cd "$(dirname "${BASH_SOURCE[0]}")"

OS="$(uname -s)"

if [ "$OS" = "Darwin" ]; then
    echo "🍏 macOS detected."
    bash setup.sh
    echo "📦 Installing Homebrew dependencies..."
    brew bundle
elif [ "$OS" = "Linux" ]; then
    echo "🐧 Linux / WSL detected."
    bash scripts/linux-core.sh

    echo ""
    read -r -p "Install Cloud/DevOps Toolchain (Go 1.22+, GCP CLI, Terraform, Docker)? [y/N] " -n 1 answer
    echo ""
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        bash scripts/linux-cloud.sh
    fi
else
    echo "Unsupported OS: $OS"
    exit 1
fi
