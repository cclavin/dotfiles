#!/usr/bin/env bash
# scripts/linux-cloud.sh — Cloud/DevOps Toolchain installation for Linux/WSL.
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

# Pre-requisites for adding repositories and downloading binaries
sudo apt-get update -qq
sudo apt-get install -y -qq apt-transport-https ca-certificates curl gnupg lsb-release wget tar

# Determine OS ID (ubuntu/debian) and Release Codename for repository URLs
DISTRO_ID=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
DISTRO_CODENAME=$(lsb_release -cs)

# Ensure modern keyring path exists and has correct permissions
sudo install -m 0755 -d /etc/apt/keyrings

# ---- 1. Go 1.22+ ------------------------------------------------------------
section "Installing Go"

install_go() {
  local GO_TAR="go${GO_VERSION}.linux-amd64.tar.gz"
  local GO_URL="https://go.dev/dl/${GO_TAR}"
  
  if command -v go &>/dev/null && go version | grep -q "go1.22"; then
    success "Go 1.22+ already installed: $(go version)"
    return
  fi

  info "Downloading Go ${GO_VERSION}..."
  wget -qO "/tmp/${GO_TAR}" "${GO_URL}"
  
  info "Removing any old Go installation and extracting new tarball to /usr/local/go..."
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "/tmp/${GO_TAR}"
  rm -f "/tmp/${GO_TAR}"
  
  # Ensure /usr/local/go/bin is added to PATH in ~/.zshrc
  if ! grep -q "/usr/local/go/bin" "$HOME/.zshrc"; then
    info "Appending /usr/local/go/bin to ~/.zshrc..."
    echo '' >> "$HOME/.zshrc"
    echo '# Added by linux-cloud.sh setup' >> "$HOME/.zshrc"
    echo 'export PATH=$PATH:/usr/local/go/bin' >> "$HOME/.zshrc"
  fi
  
  # Export to current shell so later steps (if they need Go) succeed
  export PATH=$PATH:/usr/local/go/bin
  
  success "Go installed: $(go version)"
}

if ! $SKIP_GO; then install_go; else info "Skipping Go (--skip-go)"; fi

# ---- 2. Docker Engine -------------------------------------------------------
section "Installing Docker Engine"

if $SKIP_DOCKER; then
  info "Skipping Docker Engine (--skip-docker)"
elif command -v docker &>/dev/null; then
  success "Docker already available (Docker Desktop or existing install)"
else
  info "Adding Docker repository..."
  curl -fsSL "https://download.docker.com/linux/$DISTRO_ID/gpg" | \
    sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$DISTRO_ID $DISTRO_CODENAME stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt-get update -qq
  sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo usermod -aG docker "$USER"
  success "Docker installed. (Re-login required to fully apply 'docker' group)"
fi

# ---- 3. Google Cloud SDK ----------------------------------------------------
section "Installing Google Cloud CLI"

if $SKIP_GCLOUD; then
  info "Skipping Google Cloud CLI (--skip-gcloud)"
elif command -v gcloud &>/dev/null; then
  success "Google Cloud CLI already installed"
else
  info "Adding Google Cloud repository..."
  curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
    sudo gpg --dearmor --yes -o /etc/apt/keyrings/cloud.google.gpg
  sudo chmod a+r /etc/apt/keyrings/cloud.google.gpg

  echo "deb [signed-by=/etc/apt/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
    sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list > /dev/null

  sudo apt-get update -qq
  sudo apt-get install -y -qq google-cloud-cli
  success "Google Cloud CLI installed"
fi

# ---- 4. HashiCorp Terraform CLI ---------------------------------------------
section "Installing HashiCorp Terraform CLI"

if $SKIP_TERRAFORM; then
  info "Skipping Terraform (--skip-terraform)"
elif command -v terraform &>/dev/null; then
  success "Terraform already installed"
else
  info "Adding HashiCorp repository..."
  curl -fsSL https://apt.releases.hashicorp.com/gpg | \
    sudo gpg --dearmor --yes -o /etc/apt/keyrings/hashicorp-archive-keyring.gpg
  sudo chmod a+r /etc/apt/keyrings/hashicorp-archive-keyring.gpg

  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $DISTRO_CODENAME main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null

  sudo apt-get update -qq
  sudo apt-get install -y -qq terraform
  success "Terraform installed"
fi

section "Cloud Toolchain Infrastructure Installation Complete!"
