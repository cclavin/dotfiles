#!/usr/bin/env bash
# bootstrap.sh — Machine bring-up entrypoint.
#
# Usage:
#   ./bootstrap.sh                           # Interactive (default behavior)
#   ./bootstrap.sh --role <name>             # Apply a role after platform setup
#   ./bootstrap.sh --cloud                   # Install cloud toolchain (no prompt)
#   ./bootstrap.sh --no-cloud                # Skip cloud toolchain (no prompt)
#   ./bootstrap.sh --yes                     # Auto-accept all interactive prompts
#   ./bootstrap.sh --dry-run                 # Preview actions without making changes
#   ./bootstrap.sh --audit                   # Validate current state and exit
#   ./bootstrap.sh --style <level>           # Apply styling: minimal|enhanced
#
# Roles (in roles/):
#   wsl-dev, linux-dev, macos-workstation, cloud-admin

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
DOTFILES="$(pwd)"

source "$DOTFILES/scripts/lib.sh"
source "$DOTFILES/scripts/versions.sh"
source "$DOTFILES/scripts/state.sh"

# ---- Flag parsing -----------------------------------------------------------

ROLE=""
CLOUD=""        # "" = ask interactively, "yes" = install, "no" = skip
AUTO_YES=false
DRY_RUN=false
AUDIT_ONLY=false
STYLE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --role)
      ROLE="${2:?--role requires an argument}"
      shift 2
      ;;
    --cloud)      CLOUD="yes";    shift ;;
    --no-cloud)   CLOUD="no";     shift ;;
    --yes|-y)     AUTO_YES=true;  shift ;;
    --dry-run)    DRY_RUN=true;   shift ;;
    --audit)      AUDIT_ONLY=true; shift ;;
    --style)
      STYLE="${2:?--style requires an argument}"
      shift 2
      ;;
    --help|-h)
      echo "Usage: ./bootstrap.sh [options]"
      echo ""
      echo "Options:"
      echo "  --role <name>    Apply a role after platform setup"
      echo "  --cloud          Install cloud toolchain without prompting"
      echo "  --no-cloud       Skip cloud toolchain without prompting"
      echo "  --yes, -y        Auto-accept all interactive prompts"
      echo "  --dry-run        Preview actions without making changes"
      echo "  --audit          Validate current system state and exit"
      echo "  --style <level>  Apply styling: minimal or enhanced"
      echo "  --help, -h       Show this help"
      echo ""
      echo "Roles: wsl-dev, linux-dev, macos-workstation, cloud-admin"
      exit 0
      ;;
    *)
      warn "Unknown flag: $1"
      echo "Run ./bootstrap.sh --help for usage."
      exit 1
      ;;
  esac
done

export DRY_RUN  # lib.sh run() checks this variable

# ---- Audit-only mode --------------------------------------------------------

if [[ "$AUDIT_ONLY" == "true" ]]; then
  bash "$DOTFILES/scripts/validate.sh"
  exit $?
fi

# ---- Run pending migrations -------------------------------------------------

bash "$DOTFILES/scripts/migrate.sh"

# ---- OS routing -------------------------------------------------------------

OS="$(uname -s)"

if [[ "$OS" == "Darwin" ]]; then
  section "macOS detected"
  bash "$DOTFILES/setup.sh"
  info "Installing Homebrew dependencies..."
  run brew bundle --file="$DOTFILES/Brewfile"

elif [[ "$OS" == "Linux" ]]; then
  section "Linux / WSL detected"
  bash "$DOTFILES/scripts/linux-core.sh"

  # Cloud toolchain decision: flag overrides prompt
  if [[ "$CLOUD" == "yes" ]]; then
    bash "$DOTFILES/scripts/linux-cloud.sh"
  elif [[ "$CLOUD" == "no" ]]; then
    info "Skipping cloud toolchain (--no-cloud)"
  elif [[ "$AUTO_YES" == "true" ]]; then
    bash "$DOTFILES/scripts/linux-cloud.sh"
  else
    # Original interactive prompt — unchanged default behavior
    echo ""
    read -r -p "Install Cloud/DevOps Toolchain (Go, GCP CLI, Terraform, Docker)? [y/N] " -n 1 answer
    echo ""
    if [[ "$answer" =~ ^[Yy]$ ]]; then
      bash "$DOTFILES/scripts/linux-cloud.sh"
    fi
  fi

else
  warn "Unsupported OS: $OS"
  exit 1
fi

# ---- Role application -------------------------------------------------------

if [[ -n "$ROLE" ]]; then
  role_file="$DOTFILES/roles/${ROLE}.sh"
  if [[ -f "$role_file" ]]; then
    section "Applying role: $ROLE"
    bash "$role_file"
    state_set "ROLE" "$ROLE"
  else
    warn "Role not found: $ROLE (looked for roles/${ROLE}.sh)"
    exit 1
  fi
fi

# ---- Styling ----------------------------------------------------------------

if [[ -n "$STYLE" ]]; then
  bash "$DOTFILES/scripts/style.sh" "$STYLE"
fi

# ---- Update state -----------------------------------------------------------

state_set "DOTFILES_VERSION" "$(dotfiles_version)"
state_set "LAST_RUN" "$(date -u +%Y-%m-%dT%H:%M:%S)"
if [[ "$CLOUD" == "yes" ]]; then
  state_set "CLOUD_INSTALLED" "true"
fi

# ---- Post-run validation ----------------------------------------------------

section "Validating"
bash "$DOTFILES/scripts/validate.sh" || warn "Some validation checks failed — run ./bootstrap.sh --audit for details"
