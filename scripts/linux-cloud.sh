#!/usr/bin/env bash
# scripts/linux-cloud.sh — Cloud/DevOps Toolchain dispatcher for Linux/WSL.
#
# Usage: bash linux-cloud.sh [--skip-docker] [--skip-gcloud] [--skip-terraform] [--skip-go]
#
# Flags:
#   --skip-docker     Skip Docker Engine install (use when Docker Desktop manages Docker)
#   --skip-gcloud     Skip Google Cloud CLI install
#   --skip-terraform  Skip Terraform CLI install
#   --skip-go         Skip Go install

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES/scripts/lib.sh"
source "$DOTFILES/scripts/versions.sh"

# ---- Flags ------------------------------------------------------------------

SKIP_DOCKER=false
SKIP_GCLOUD=false
SKIP_TERRAFORM=false
SKIP_GO=false

for arg in "$@"; do
  case "$arg" in
    --skip-docker)    SKIP_DOCKER=true ;;
    --skip-gcloud)    SKIP_GCLOUD=true ;;
    --skip-terraform) SKIP_TERRAFORM=true ;;
    --skip-go)        SKIP_GO=true ;;
    *) warn "Unknown flag: $arg"; exit 1 ;;
  esac
done

# ---- Guard: Linux only ------------------------------------------------------

if [[ "$OSTYPE" != "linux-gnu"* ]]; then
  warn "This script is for Linux/WSL."
  exit 1
fi

section "Preparing for Cloud/DevOps toolchain"

# ---- Prerequisites ----------------------------------------------------------
# lsb_release fallbacks handle minimal containers (e.g., dry-run in Docker).

DISTRO_ID=$(lsb_release -is 2>/dev/null | tr '[:upper:]' '[:lower:]' || echo "ubuntu")
DISTRO_CODENAME=$(lsb_release -cs 2>/dev/null || echo "unknown")
export DISTRO_ID DISTRO_CODENAME

if is_dry_run; then
  info "[dry-run] would install prerequisites: apt-transport-https ca-certificates curl gnupg lsb-release wget tar"
  info "[dry-run] distro: ${DISTRO_ID}/${DISTRO_CODENAME}"
else
  sudo apt-get update -qq
  sudo apt-get install -y -qq apt-transport-https ca-certificates curl gnupg lsb-release wget tar
  sudo install -m 0755 -d /etc/apt/keyrings
fi

# ---- Dispatch to individual tool scripts ------------------------------------

CLOUD_DIR="$DOTFILES/scripts/cloud"

$SKIP_GO        || bash "$CLOUD_DIR/go.sh"
$SKIP_DOCKER    || bash "$CLOUD_DIR/docker.sh"
$SKIP_GCLOUD    || bash "$CLOUD_DIR/gcp.sh"
$SKIP_TERRAFORM || bash "$CLOUD_DIR/terraform.sh"

section "Cloud Toolchain Installation Complete!"
