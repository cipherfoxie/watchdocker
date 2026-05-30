#!/usr/bin/env bash
# Smoke tests for watchdocker. Does not touch docker; only verifies CLI
# surface, config loader, hook validation, and lock behaviour.
#
# Run: bash tests/smoke.sh

set -Eeuo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$REPO/bin/watchdocker"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

OK=0
FAIL=0

note() { printf '\n[%s] %s\n' "$1" "$2"; }
pass() { printf '  ✓ %s\n' "$1"; OK=$((OK+1)); }
fail() { printf '  ✗ %s\n' "$1"; FAIL=$((FAIL+1)); }

assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        pass "$desc"
    else
        fail "$desc"
        printf '    expected: %s\n    actual:   %s\n' "$expected" "$actual"
    fi
}

run_warden() {
    # Run binary with locked /tmp lockdir so tests do not collide with prod.
    WATCHDOCKER_LOCKDIR="$TMP/lock" "$BIN" "$@"
}

echo "=== watchdocker smoke tests ==="

# ────────────────────────────────────────────────────────────────────────
note "1" "--version"
out="$(run_warden --version 2>&1)"
assert_eq "version output" "watchdocker 0.1.0" "$out"

# ────────────────────────────────────────────────────────────────────────
note "2" "--help"
if run_warden --help >/dev/null 2>&1; then pass "help exits 0"; else fail "help non-zero"; fi

# ────────────────────────────────────────────────────────────────────────
note "3" "unknown arg → exit 2"
set +e
run_warden --bogus >/dev/null 2>&1
rc=$?
set -e
assert_eq "unknown arg exit code" "2" "$rc"

# ────────────────────────────────────────────────────────────────────────
note "4" "missing --config argument → exit 2"
set +e
run_warden --config >/dev/null 2>&1
rc=$?
set -e
assert_eq "--config missing arg exit code" "2" "$rc"

# ────────────────────────────────────────────────────────────────────────
note "5" "empty config + --list"
echo "projects: []" > "$TMP/empty.yaml"
out="$(run_warden --config "$TMP/empty.yaml" --list 2>&1 || true)"
if grep -q "no projects" <<<"$out" || grep -q "discovered" <<<"$out"; then
    pass "list mode handles empty config"
else
    fail "list mode failed on empty config"
    printf '    got: %s\n' "$out"
fi

# ────────────────────────────────────────────────────────────────────────
note "6" "explicit projects in config"
mkdir -p "$TMP/proj1" "$TMP/proj2"
touch "$TMP/proj1/compose.yml" "$TMP/proj2/compose.yml"
cat > "$TMP/with-projects.yaml" <<EOF
projects:
  - $TMP/proj1
  - $TMP/proj2
EOF
out="$(run_warden --config "$TMP/with-projects.yaml" --list 2>&1 || true)"
if grep -q "proj1" <<<"$out" && grep -q "proj2" <<<"$out"; then
    pass "both projects discovered from config"
else
    fail "config projects not all found"
    printf '    got: %s\n' "$out"
fi

# ────────────────────────────────────────────────────────────────────────
note "7" "comment-handling: '#' outside quotes is a comment"
cat > "$TMP/comments.yaml" <<EOF
projects:
  - $TMP/proj1    # trailing comment after value
# whole line comment
  - $TMP/proj2
EOF
out="$(run_warden --config "$TMP/comments.yaml" --list 2>&1 || true)"
if grep -q "proj1" <<<"$out" && grep -q "proj2" <<<"$out"; then
    pass "comments stripped without harming values"
else
    fail "comment stripping broke value extraction"
fi

# ────────────────────────────────────────────────────────────────────────
note "8" "comment-handling: '#' inside quotes is preserved"
mkdir -p "$TMP/has#hash"
touch "$TMP/has#hash/compose.yml"
cat > "$TMP/quoted-hash.yaml" <<EOF
projects:
  - "$TMP/has#hash"
EOF
out="$(run_warden --config "$TMP/quoted-hash.yaml" --list 2>&1 || true)"
if grep -q "has#hash" <<<"$out"; then
    pass "quoted '#' preserved"
else
    fail "quoted '#' was stripped (parser bug)"
    printf '    got: %s\n' "$out"
fi

# ────────────────────────────────────────────────────────────────────────
note "9" "skip_projects takes precedence"
cat > "$TMP/skip.yaml" <<EOF
projects:
  - $TMP/proj1
  - $TMP/proj2
skip_projects:
  - $TMP/proj2
EOF
out="$(run_warden --config "$TMP/skip.yaml" --list 2>&1 || true)"
if grep -q "\[skip\] $TMP/proj2" <<<"$out" && grep -q "\[act \] $TMP/proj1" <<<"$out"; then
    pass "skip_projects correctly tagged as [skip]"
else
    fail "skip_projects logic broken"
    printf '    got: %s\n' "$out"
fi

# ────────────────────────────────────────────────────────────────────────
note "10" "invalid hook path → exit 2"
cat > "$TMP/bad-hook.yaml" <<EOF
projects:
  - $TMP/proj1
pre_hook: relative/path/script.sh
EOF
set +e
run_warden --config "$TMP/bad-hook.yaml" >/dev/null 2>&1
rc=$?
set -e
assert_eq "non-absolute hook exit code" "2" "$rc"

# ────────────────────────────────────────────────────────────────────────
note "11" "lock behaviour: second concurrent run → exit 10"
# Hold the lock by setting up the dir ourselves
mkdir -p "$TMP/lock"
echo $$ > "$TMP/lock/pid"
set +e
run_warden --list >/dev/null 2>&1
rc=$?
set -e
rmdir "$TMP/lock"/* 2>/dev/null || true
rm -rf "$TMP/lock"
assert_eq "concurrent run blocked with exit 10" "10" "$rc"

# ────────────────────────────────────────────────────────────────────────
note "12" "--once overrides existing lock"
mkdir -p "$TMP/lock"
echo $$ > "$TMP/lock/pid"
set +e
run_warden --once --list >/dev/null 2>&1
rc=$?
set -e
[[ "$rc" == "0" ]] && pass "--once works while another lock exists" || fail "--once didn't override (rc=$rc)"

# clean lock state for subsequent tests
rm -rf "$TMP/lock"

# ────────────────────────────────────────────────────────────────────────
note "13" "prune config: invalid age is rejected gracefully"
cat > "$TMP/bad-prune.yaml" <<EOF
projects:
  - $TMP/proj1
prune:
  enabled: true
  age: notatime
EOF
out="$(run_warden --config "$TMP/bad-prune.yaml" --list 2>&1 || true)"
if grep -q "proj1" <<<"$out"; then
    pass "invalid prune.age does not abort"
else
    fail "invalid prune.age broke run"
fi

# ────────────────────────────────────────────────────────────────────────
note "14" "dry-run prints would-do"
cat > "$TMP/dry.yaml" <<EOF
projects:
  - $TMP/proj1
EOF
out="$(run_warden --config "$TMP/dry.yaml" --dry-run --once 2>&1 || true)"
if grep -q "DRY-RUN" <<<"$out" && grep -q "would docker compose pull" <<<"$out"; then
    pass "dry-run output is correct"
else
    fail "dry-run output missing expected markers"
    printf '    got: %s\n' "$out"
fi

# ────────────────────────────────────────────────────────────────────────
echo ""
echo "=== Results: $OK ok, $FAIL failed ==="
[[ "$FAIL" -eq 0 ]] && exit 0 || exit 1
