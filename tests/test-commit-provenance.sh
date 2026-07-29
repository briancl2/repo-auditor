#!/usr/bin/env bash
# Deterministic adversarial tests for the commit-provenance gate.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VALIDATOR="$ROOT/scripts/validate-commit-provenance.sh"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/repo-auditor-commit-provenance.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

REPO="$TMP_ROOT/repo"
mkdir -p "$REPO"
git -C "$REPO" init -q
git -C "$REPO" config user.name "Owner Test"
git -C "$REPO" config user.email "owner@example.invalid"

EMPTY_TREE=$(git -C "$REPO" mktree </dev/null)

commit_tree() {
    local message="$1"
    shift
    printf '%s\n' "$message" | git -C "$REPO" commit-tree "$EMPTY_TREE" "$@"
}

assert_pass() {
    local label="$1"
    local commit="$2"
    if (cd "$REPO" && bash "$VALIDATOR" "$commit") >"$TMP_ROOT/out" 2>&1; then
        echo "  PASS: $label"
    else
        echo "  FAIL: $label"
        sed -n '1,20p' "$TMP_ROOT/out"
        exit 1
    fi
}

assert_fail() {
    local label="$1"
    local commit="$2"
    if (cd "$REPO" && bash "$VALIDATOR" "$commit") >"$TMP_ROOT/out" 2>&1; then
        echo "  FAIL: $label"
        sed -n '1,20p' "$TMP_ROOT/out"
        exit 1
    else
        echo "  PASS: $label"
    fi
}

ARBITRARY=$(commit_tree "Trailerless arbitrary commit")
assert_fail "arbitrary trailerless commit fails" "$ARBITRARY"

SPOOFED_SUFFIX=$(commit_tree "Spoofed pull request suffix (#999)")
assert_fail "pull-request suffix with ordinary committer fails" "$SPOOFED_SUFFIX"

SPEC_ID=$(commit_tree $'Explicit specification\n\nSpec-ID: NOEM-RC1.1')
assert_pass "Spec-ID trailer passes" "$SPEC_ID"

SPEC_EXEMPT=$(commit_tree $'Explicit exemption\n\nSpec-Exempt: deterministic test')
assert_pass "Spec-Exempt trailer passes" "$SPEC_EXEMPT"

FIRST_PARENT=$(commit_tree "First parent without trailer" -p "$ARBITRARY")
SECOND_PARENT=$(commit_tree $'Reviewed head\n\nSpec-Exempt: reviewed branch provenance' -p "$ARBITRARY")
MERGE=$(commit_tree "Merge without trailer" -p "$FIRST_PARENT" -p "$SECOND_PARENT")
assert_pass "merge-parent trailer fallback passes" "$MERGE"

AUTHENTIC_SQUASH=$(
    GIT_COMMITTER_NAME="GitHub" \
    GIT_COMMITTER_EMAIL="noreply@github.com" \
    commit_tree "Authentic modeled settlement (#216)" -p "$ARBITRARY"
)
assert_pass "modeled GitHub squash metadata passes" "$AUTHENTIC_SQUASH"

GITHUB_NO_SUFFIX=$(
    GIT_COMMITTER_NAME="GitHub" \
    GIT_COMMITTER_EMAIL="noreply@github.com" \
    commit_tree "GitHub metadata without pull request suffix" -p "$ARBITRARY"
)
assert_fail "GitHub committer without exact suffix fails" "$GITHUB_NO_SUFFIX"

GITHUB_MALFORMED_SUFFIX=$(
    GIT_COMMITTER_NAME="GitHub" \
    GIT_COMMITTER_EMAIL="noreply@github.com" \
    commit_tree "Malformed suffix (#216) extra" -p "$ARBITRARY"
)
assert_fail "GitHub committer with malformed suffix fails" "$GITHUB_MALFORMED_SUFFIX"

echo ""
echo "=== test-commit-provenance.sh: 8 pass, 0 fail ==="
