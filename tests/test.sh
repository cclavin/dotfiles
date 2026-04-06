#!/usr/bin/env bash
# tests/test.sh — Dotfiles test suite.
#
# Designed to run inside Docker (ubuntu:22.04) or any bash environment.
# Tests library functions, state management, migration framework,
# flag parsing, and dry-run behavior — without performing real installs.
#
# Usage:
#   bash tests/test.sh                  # run from repo root
#   docker run ... bash /dotfiles/tests/test.sh

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

PASS=0
FAIL=0
SKIP=0

# ---- Test helpers -----------------------------------------------------------

_green()  { printf '\033[32m%s\033[0m' "$*"; }
_red()    { printf '\033[31m%s\033[0m' "$*"; }
_yellow() { printf '\033[33m%s\033[0m' "$*"; }

section_heading() {
  echo ""
  echo "── $* ──────────────────────────────────────────"
}

pass() {
  echo "  $(_green PASS) $1"
  PASS=$((PASS + 1))
}

fail() {
  echo "  $(_red FAIL) $1"
  FAIL=$((FAIL + 1))
}

skip() {
  echo "  $(_yellow SKIP) $1"
  SKIP=$((SKIP + 1))
}

# assert_eq <desc> <expected> <actual>
assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    pass "$desc"
  else
    fail "$desc  →  expected='$expected'  actual='$actual'"
  fi
}

# assert_exit <desc> <expected_exit_code> <cmd...>
assert_exit() {
  local desc="$1" expected="$2"
  shift 2
  local actual=0
  "$@" >/dev/null 2>&1 || actual=$?
  if [[ $actual -eq $expected ]]; then
    pass "$desc (exit $actual)"
  else
    fail "$desc  →  expected exit $expected, got $actual"
  fi
}

# assert_output_contains <desc> <pattern> <cmd...>
assert_output_contains() {
  local desc="$1" pattern="$2"
  shift 2
  local output
  output=$("$@" 2>&1) || true
  if echo "$output" | grep -q "$pattern"; then
    pass "$desc"
  else
    fail "$desc  →  pattern '$pattern' not found in output"
  fi
}

# assert_true <desc> <cmd...>
assert_true() {
  local desc="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    pass "$desc"
  else
    fail "$desc"
  fi
}

# assert_false <desc> <cmd...>
assert_false() {
  local desc="$1"
  shift
  if ! "$@" >/dev/null 2>&1; then
    pass "$desc"
  else
    fail "$desc  →  expected to fail"
  fi
}

# ============================================================================
# SUITE 1: lib.sh
# ============================================================================

section_heading "lib.sh"

# Use a fresh subshell to test sourcing behavior without polluting this env
assert_exit "sources without error" 0 bash -c "source '$DOTFILES/scripts/lib.sh'"

assert_exit "double-source guard works" 0 bash -c "
  source '$DOTFILES/scripts/lib.sh'
  source '$DOTFILES/scripts/lib.sh'   # second source should be no-op
  declare -f info >/dev/null          # function should still exist
"

assert_exit "DOTFILES is set after source" 0 bash -c "
  source '$DOTFILES/scripts/lib.sh'
  [[ -n \"\$DOTFILES\" ]]
"

assert_exit "IS_LINUX is true in Linux container" 0 bash -c "
  source '$DOTFILES/scripts/lib.sh'
  \$IS_LINUX
"

assert_exit "IS_MACOS is false in Linux container" 0 bash -c "
  source '$DOTFILES/scripts/lib.sh'
  ! \$IS_MACOS
"

# run() in normal mode executes commands
assert_exit "run() executes command when DRY_RUN unset" 0 bash -c "
  source '$DOTFILES/scripts/lib.sh'
  tmpf=\$(mktemp)
  run touch \"\$tmpf\"
  [[ -f \"\$tmpf\" ]]
  rm -f \"\$tmpf\"
"

# run() in dry-run mode skips execution
assert_exit "run() skips command when DRY_RUN=true" 0 bash -c "
  source '$DOTFILES/scripts/lib.sh'
  export DRY_RUN=true
  tmpf=\"/tmp/dotfiles-test-\$\$\"
  run touch \"\$tmpf\"
  [[ ! -f \"\$tmpf\" ]]   # file should NOT exist
"

assert_output_contains "run() prints [dry-run] message" "\[dry-run\]" bash -c "
  source '$DOTFILES/scripts/lib.sh'
  export DRY_RUN=true
  run echo 'should not print'
"

# is_dry_run() behavior
assert_exit "is_dry_run() returns false when unset" 1 bash -c "
  source '$DOTFILES/scripts/lib.sh'
  is_dry_run
"

assert_exit "is_dry_run() returns true when DRY_RUN=true" 0 bash -c "
  source '$DOTFILES/scripts/lib.sh'
  export DRY_RUN=true
  is_dry_run
"

assert_exit "is_dry_run() returns false when DRY_RUN=false" 1 bash -c "
  source '$DOTFILES/scripts/lib.sh'
  export DRY_RUN=false
  is_dry_run
"

# link() behavior
TMPTEST=$(mktemp -d)
trap "rm -rf '$TMPTEST'" EXIT

assert_exit "link() creates symlink" 0 bash -c "
  source '$DOTFILES/scripts/lib.sh'
  src='$TMPTEST/src.txt'
  dest='$TMPTEST/dest.txt'
  echo 'content' > \"\$src\"
  link \"\$src\" \"\$dest\"
  [[ -L \"\$dest\" ]]
"

assert_exit "link() skips existing symlink (idempotent)" 0 bash -c "
  source '$DOTFILES/scripts/lib.sh'
  src='$TMPTEST/src2.txt'
  dest='$TMPTEST/dest2.txt'
  echo 'content' > \"\$src\"
  link \"\$src\" \"\$dest\"
  link \"\$src\" \"\$dest\"   # second call should be silent no-op
  [[ -L \"\$dest\" ]]
"

assert_exit "link() backs up existing plain file" 0 bash -c "
  source '$DOTFILES/scripts/lib.sh'
  src='$TMPTEST/src3.txt'
  dest='$TMPTEST/dest3.txt'
  echo 'original' > \"\$dest\"   # plain file, not symlink
  echo 'content' > \"\$src\"
  link \"\$src\" \"\$dest\"
  [[ -L \"\$dest\" && -f \"\${dest}.bak\" ]]
"

assert_exit "link() skips mutation in dry-run mode" 0 bash -c "
  source '$DOTFILES/scripts/lib.sh'
  export DRY_RUN=true
  src='$TMPTEST/src4.txt'
  dest='$TMPTEST/dest4.txt'
  echo 'content' > \"\$src\"
  link \"\$src\" \"\$dest\"
  [[ ! -e \"\$dest\" ]]   # should NOT be created in dry-run
"

# ============================================================================
# SUITE 2: versions.sh
# ============================================================================

section_heading "versions.sh"

assert_exit "sources without error" 0 bash -c "source '$DOTFILES/scripts/versions.sh'"

assert_exit "DELTA_VERSION is set" 0 bash -c "
  source '$DOTFILES/scripts/versions.sh'
  [[ -n \"\$DELTA_VERSION\" ]]
"

assert_exit "GO_VERSION is set" 0 bash -c "
  source '$DOTFILES/scripts/versions.sh'
  [[ -n \"\$GO_VERSION\" ]]
"

assert_exit "DELTA_VERSION has valid format (x.y.z)" 0 bash -c "
  source '$DOTFILES/scripts/versions.sh'
  echo \"\$DELTA_VERSION\" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'
"

assert_exit "GO_VERSION has valid format (x.y.z)" 0 bash -c "
  source '$DOTFILES/scripts/versions.sh'
  echo \"\$GO_VERSION\" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'
"

assert_exit "double-source guard works" 0 bash -c "
  source '$DOTFILES/scripts/versions.sh'
  source '$DOTFILES/scripts/versions.sh'
  [[ -n \"\$DELTA_VERSION\" ]]
"

# ============================================================================
# SUITE 3: state.sh
# ============================================================================

section_heading "state.sh"

# Override state dir so tests don't touch real state
export XDG_DATA_HOME="$TMPTEST/.local/share"

assert_exit "sources without error" 0 bash -c "
  export XDG_DATA_HOME='$TMPTEST/.local/share'
  source '$DOTFILES/scripts/lib.sh'
  source '$DOTFILES/scripts/state.sh'
"

assert_exit "state_set and state_get round-trip" 0 bash -c "
  export XDG_DATA_HOME='$TMPTEST/.local/share/test1'
  source '$DOTFILES/scripts/lib.sh'
  source '$DOTFILES/scripts/state.sh'
  state_set 'ROLE' 'wsl-dev'
  [[ \"\$(state_get ROLE)\" == 'wsl-dev' ]]
"

assert_eq "state_get returns empty for missing key" "" "$(
  XDG_DATA_HOME="$TMPTEST/.local/share/test2" bash -c "
    source '$DOTFILES/scripts/lib.sh'
    source '$DOTFILES/scripts/state.sh'
    state_get 'NONEXISTENT_KEY'
  " 2>/dev/null
)"

assert_exit "state_set overwrites existing key (upsert)" 0 bash -c "
  export XDG_DATA_HOME='$TMPTEST/.local/share/test3'
  source '$DOTFILES/scripts/lib.sh'
  source '$DOTFILES/scripts/state.sh'
  state_set 'KEY' 'first'
  state_set 'KEY' 'second'
  [[ \"\$(state_get KEY)\" == 'second' ]]
"

assert_exit "multiple keys coexist" 0 bash -c "
  export XDG_DATA_HOME='$TMPTEST/.local/share/test4'
  source '$DOTFILES/scripts/lib.sh'
  source '$DOTFILES/scripts/state.sh'
  state_set 'KEY_A' 'alpha'
  state_set 'KEY_B' 'beta'
  [[ \"\$(state_get KEY_A)\" == 'alpha' && \"\$(state_get KEY_B)\" == 'beta' ]]
"

assert_exit "state file created in correct location" 0 bash -c "
  TEST_DATA='$TMPTEST/.local/share/test5'
  export XDG_DATA_HOME=\"\$TEST_DATA\"
  source '$DOTFILES/scripts/lib.sh'
  source '$DOTFILES/scripts/state.sh'
  state_set 'INIT' 'yes'
  [[ -f \"\$TEST_DATA/dotfiles/state.env\" ]]
"

# ============================================================================
# SUITE 4: migrate.sh
# ============================================================================

section_heading "migrate.sh"

MIGRATE_TEST="$TMPTEST/migrate-test"
mkdir -p "$MIGRATE_TEST/scripts"
cp "$DOTFILES/scripts/lib.sh"   "$MIGRATE_TEST/scripts/"
cp "$DOTFILES/scripts/state.sh" "$MIGRATE_TEST/scripts/"

# Use a scratch dir with NO migrations/ to test the no-op path
NO_MIG_DOTFILES="$TMPTEST/no-mig-dotfiles"
mkdir -p "$NO_MIG_DOTFILES/scripts"
cp "$DOTFILES/scripts/lib.sh"     "$NO_MIG_DOTFILES/scripts/"
cp "$DOTFILES/scripts/state.sh"   "$NO_MIG_DOTFILES/scripts/"
cp "$DOTFILES/scripts/migrate.sh" "$NO_MIG_DOTFILES/scripts/"
# Intentionally no migrations/ directory

assert_exit "no-op when migrations/ dir is absent" 0 bash -c "
  export XDG_DATA_HOME='$TMPTEST/.local/share/migrate1'
  bash '$NO_MIG_DOTFILES/scripts/migrate.sh'
"

# Create a scratch dotfiles dir with one migration
SCRATCH_DOTFILES="$TMPTEST/scratch-dotfiles"
mkdir -p "$SCRATCH_DOTFILES/scripts"
mkdir -p "$SCRATCH_DOTFILES/migrations"
cp "$DOTFILES/scripts/lib.sh"     "$SCRATCH_DOTFILES/scripts/"
cp "$DOTFILES/scripts/state.sh"   "$SCRATCH_DOTFILES/scripts/"
cp "$DOTFILES/scripts/migrate.sh" "$SCRATCH_DOTFILES/scripts/"
cat > "$SCRATCH_DOTFILES/migrations/001-test.sh" << 'MIGEOF'
#!/usr/bin/env bash
echo "migration 001 ran"
MIGEOF
chmod +x "$SCRATCH_DOTFILES/migrations/001-test.sh"

assert_output_contains "applies pending migration" "migration 001 ran" bash -c "
  export XDG_DATA_HOME='$TMPTEST/.local/share/migrate2'
  DOTFILES='$SCRATCH_DOTFILES' bash '$SCRATCH_DOTFILES/scripts/migrate.sh'
"

assert_output_contains "records migration in state" "applied" bash -c "
  export XDG_DATA_HOME='$TMPTEST/.local/share/migrate3'
  DOTFILES='$SCRATCH_DOTFILES' bash '$SCRATCH_DOTFILES/scripts/migrate.sh'
"

assert_output_contains "skips already-applied migration" "already applied" bash -c "
  export XDG_DATA_HOME='$TMPTEST/.local/share/migrate4'
  DOTFILES='$SCRATCH_DOTFILES' bash '$SCRATCH_DOTFILES/scripts/migrate.sh'
  DOTFILES='$SCRATCH_DOTFILES' bash '$SCRATCH_DOTFILES/scripts/migrate.sh'
"

# Test failing migration halts sequence
FAIL_DOTFILES="$TMPTEST/fail-dotfiles"
mkdir -p "$FAIL_DOTFILES/scripts"
mkdir -p "$FAIL_DOTFILES/migrations"
cp "$DOTFILES/scripts/lib.sh"     "$FAIL_DOTFILES/scripts/"
cp "$DOTFILES/scripts/state.sh"   "$FAIL_DOTFILES/scripts/"
cp "$DOTFILES/scripts/migrate.sh" "$FAIL_DOTFILES/scripts/"
cat > "$FAIL_DOTFILES/migrations/001-will-fail.sh" << 'MIGEOF'
#!/usr/bin/env bash
exit 1
MIGEOF
chmod +x "$FAIL_DOTFILES/migrations/001-will-fail.sh"

assert_exit "halts on failed migration (exit non-zero)" 1 bash -c "
  export XDG_DATA_HOME='$TMPTEST/.local/share/migrate5'
  DOTFILES='$FAIL_DOTFILES' bash '$FAIL_DOTFILES/scripts/migrate.sh'
"

# ============================================================================
# SUITE 5: bootstrap.sh flag parsing
# ============================================================================

section_heading "bootstrap.sh flags"

assert_exit "--help exits 0" 0 bash "$DOTFILES/bootstrap.sh" --help
assert_output_contains "--help shows usage" "Usage" bash "$DOTFILES/bootstrap.sh" --help
assert_output_contains "--help lists roles" "wsl-dev" bash "$DOTFILES/bootstrap.sh" --help

assert_exit "unknown flag exits 1" 1 bash -c "
  export XDG_DATA_HOME='$TMPTEST/.local/share/flags1'
  bash '$DOTFILES/bootstrap.sh' --not-a-real-flag 2>/dev/null
"

assert_exit "--role with no argument exits 1" 1 bash -c "
  export XDG_DATA_HOME='$TMPTEST/.local/share/flags2'
  bash '$DOTFILES/bootstrap.sh' --role 2>/dev/null
"

assert_exit "--style with no argument exits 1" 1 bash -c "
  export XDG_DATA_HOME='$TMPTEST/.local/share/flags3'
  bash '$DOTFILES/bootstrap.sh' --style 2>/dev/null
"

assert_exit "--role nonexistent-role exits 1" 1 bash -c "
  export XDG_DATA_HOME='$TMPTEST/.local/share/flags4'
  bash '$DOTFILES/bootstrap.sh' --role this-role-does-not-exist --dry-run --no-cloud 2>/dev/null
"

# ============================================================================
# SUITE 6: dry-run integration (full bootstrap without installs)
# ============================================================================

section_heading "dry-run integration"

assert_exit "bootstrap.sh --dry-run --no-cloud exits 0" 0 bash -c "
  export XDG_DATA_HOME='$TMPTEST/.local/share/dryrun1'
  bash '$DOTFILES/bootstrap.sh' --dry-run --no-cloud 2>&1
"

assert_output_contains "dry-run shows [dry-run] markers" "\[dry-run\]" bash -c "
  export XDG_DATA_HOME='$TMPTEST/.local/share/dryrun2'
  bash '$DOTFILES/bootstrap.sh' --dry-run --no-cloud 2>&1
"

assert_output_contains "dry-run shows apt packages" "would install via apt" bash -c "
  export XDG_DATA_HOME='$TMPTEST/.local/share/dryrun3'
  bash '$DOTFILES/bootstrap.sh' --dry-run --no-cloud 2>&1
"

assert_output_contains "dry-run shows workspace creation" "\[dry-run\].*mkdir" bash -c "
  export XDG_DATA_HOME='$TMPTEST/.local/share/dryrun4'
  bash '$DOTFILES/bootstrap.sh' --dry-run --no-cloud 2>&1
"

assert_output_contains "dry-run shows symlink messages" "dry-run" bash -c "
  export XDG_DATA_HOME='$TMPTEST/.local/share/dryrun5'
  bash '$DOTFILES/bootstrap.sh' --dry-run --no-cloud 2>&1
"

assert_output_contains "dry-run shows Core Setup Done" "Core Setup Done" bash -c "
  export XDG_DATA_HOME='$TMPTEST/.local/share/dryrun6'
  bash '$DOTFILES/bootstrap.sh' --dry-run --no-cloud 2>&1
"

assert_exit "linux-cloud.sh --dry-run skips all tools" 0 bash -c "
  export XDG_DATA_HOME='$TMPTEST/.local/share/cloud-dry'
  export DRY_RUN=true
  bash '$DOTFILES/scripts/linux-cloud.sh' 2>&1
"

assert_output_contains "linux-cloud.sh --dry-run shows prerequisites message" "\[dry-run\].*prerequisites" bash -c "
  export DRY_RUN=true
  bash '$DOTFILES/scripts/linux-cloud.sh' 2>&1
"

assert_output_contains "cloud/go.sh --dry-run shows install message" "\[dry-run\].*Go" bash -c "
  export DRY_RUN=true
  bash '$DOTFILES/scripts/cloud/go.sh' 2>&1
"

# Cloud tool scripts exit 0 in dry-run mode (either tool is already installed, or dry-run message shown)
assert_exit "cloud/docker.sh exits 0 under DRY_RUN=true" 0 bash -c "
  export DRY_RUN=true
  bash '$DOTFILES/scripts/cloud/docker.sh' 2>&1
"

assert_exit "cloud/gcp.sh exits 0 under DRY_RUN=true" 0 bash -c "
  export DRY_RUN=true
  bash '$DOTFILES/scripts/cloud/gcp.sh' 2>&1
"

assert_exit "cloud/terraform.sh exits 0 under DRY_RUN=true" 0 bash -c "
  export DRY_RUN=true
  bash '$DOTFILES/scripts/cloud/terraform.sh' 2>&1
"

# ============================================================================
# SUITE 7: validate.sh
# ============================================================================

section_heading "validate.sh"

assert_exit "validate.sh exits non-zero on fresh system (missing tools)" 1 bash -c "
  export XDG_DATA_HOME='$TMPTEST/.local/share/validate1'
  bash '$DOTFILES/scripts/validate.sh' 2>&1
"

assert_output_contains "validate.sh reports FAIL for missing commands" "FAIL" bash -c "
  export XDG_DATA_HOME='$TMPTEST/.local/share/validate2'
  bash '$DOTFILES/scripts/validate.sh' 2>&1
"

assert_output_contains "validate.sh shows Validation Summary" "Validation Summary" bash -c "
  export XDG_DATA_HOME='$TMPTEST/.local/share/validate3'
  bash '$DOTFILES/scripts/validate.sh' 2>&1
"

# ============================================================================
# Summary
# ============================================================================

echo ""
echo "────────────────────────────────────────────────────"
TOTAL=$((PASS + FAIL + SKIP))
echo "  Results: $TOTAL tests — $(_green "$PASS passed") · $(_red "$FAIL failed") · $(_yellow "$SKIP skipped")"
echo "────────────────────────────────────────────────────"
echo ""

if [[ $FAIL -gt 0 ]]; then
  exit 1
fi
exit 0
