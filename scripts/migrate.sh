#!/usr/bin/env bash
# scripts/migrate.sh — Apply pending versioned migrations.
#
# Migrations are numbered shell scripts in migrations/ (format: NNN-description.sh).
# Each migration is applied once and recorded in the local state file.
# Migrations run in numeric order; a failure halts the sequence.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES/scripts/lib.sh"
source "$DOTFILES/scripts/state.sh"

MIGRATIONS_DIR="$DOTFILES/migrations"

if [[ ! -d "$MIGRATIONS_DIR" ]]; then
  info "No migrations directory found — skipping"
  exit 0
fi

# Get comma-separated list of already-applied migration numbers
APPLIED="$(state_get MIGRATIONS_APPLIED)"

PENDING=0
APPLIED_NOW=0

for migration in "$MIGRATIONS_DIR"/[0-9][0-9][0-9]-*.sh; do
  [[ -f "$migration" ]] || continue

  basename_="$(basename "$migration")"
  number="${basename_%%-*}"   # extract "001" from "001-some-name.sh"
  ((PENDING++))

  # Check if already applied (match ",NNN," in ",applied,list,")
  if echo ",${APPLIED}," | grep -q ",${number},"; then
    info "Migration $basename_ already applied — skipping"
    continue
  fi

  section "Applying migration: $basename_"
  if bash "$migration"; then
    # Append number to the applied list
    if [[ -z "$APPLIED" ]]; then
      APPLIED="$number"
    else
      APPLIED="${APPLIED},${number}"
    fi
    state_set "MIGRATIONS_APPLIED" "$APPLIED"
    ((APPLIED_NOW++))
    success "Migration $basename_ applied"
  else
    warn "Migration $basename_ FAILED — stopping"
    exit 1
  fi
done

if [[ $PENDING -eq 0 ]]; then
  info "No migrations found"
elif [[ $APPLIED_NOW -eq 0 ]]; then
  info "All migrations already applied"
else
  success "$APPLIED_NOW migration(s) applied"
fi
