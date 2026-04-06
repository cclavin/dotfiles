#!/usr/bin/env bash
# tests/run.sh — Run the dotfiles test suite in Docker.
#
# Usage:
#   bash tests/run.sh            # from repo root
#   bash tests/run.sh --no-pull  # skip docker pull

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
DOTFILES="$(pwd)"

NO_PULL=false
for arg in "$@"; do
  case "$arg" in
    --no-pull) NO_PULL=true ;;
    *) echo "Unknown flag: $arg"; exit 1 ;;
  esac
done

echo ""
echo "── dotfiles test suite ──────────────────────────────"
echo "  image:  ubuntu:22.04"
echo "  mount:  $DOTFILES → /dotfiles (read-only)"
echo ""

if ! command -v docker &>/dev/null; then
  echo "  ERROR: docker not found"
  echo "  Install Docker Desktop or run tests directly: bash tests/test.sh"
  exit 1
fi

if ! $NO_PULL; then
  echo "  Pulling ubuntu:22.04..."
  docker pull ubuntu:22.04 -q
fi

echo "  Running tests..."
echo ""

# Try Docker first, fall back to WSL2 if Docker is not available
if docker info &>/dev/null 2>&1; then
  docker run --rm \
    --name dotfiles-test \
    -v "${DOTFILES}:/dotfiles:ro" \
    -e DOTFILES=/dotfiles \
    ubuntu:22.04 \
    bash /dotfiles/tests/test.sh
elif command -v wsl &>/dev/null 2>&1; then
  echo "  (Docker not available — falling back to WSL2)"
  # Convert Windows path to WSL path for the volume mount
  WSL_PATH="$(wsl -d Ubuntu-24.04 wslpath "$DOTFILES" 2>/dev/null || echo "/mnt/c${DOTFILES#C:}" | tr '\\' '/')"
  wsl -d Ubuntu-24.04 -e bash -c "bash '${WSL_PATH}/tests/test.sh'"
else
  echo "  Neither Docker nor WSL2 found — running tests directly"
  bash "${DOTFILES}/tests/test.sh"
fi

EXIT_CODE=$?

if [[ $EXIT_CODE -eq 0 ]]; then
  echo "  All tests passed."
else
  echo "  Tests FAILED (exit $EXIT_CODE)"
fi

exit $EXIT_CODE
