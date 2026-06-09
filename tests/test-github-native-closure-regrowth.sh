#!/usr/bin/env bash
# Verify AS-22 detects closure ceremony regrowth while preserving fallback/neutral docs.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

assert_fired_count() {
  local repo="$1"
  local expected="$2"
  local output="$TMPDIR/result.json"
  bash "$REPO_ROOT/scripts/detect-as-github-native-closure-regrowth.sh" "$repo" > "$output"
  python3 - "$output" "$expected" <<'PY'
import json
import sys

payload = json.load(open(sys.argv[1], encoding="utf-8"))
expected = int(sys.argv[2])
actual = payload["signals"]["github_native_closure_regrowth_count"]
assert actual == expected, payload
assert payload["fired"] is (expected > 0), payload
PY
}

POSITIVE="$TMPDIR/positive"
mkdir -p "$POSITIVE/docs"
cat > "$POSITIVE/docs/issue164-closeout.md" <<'EOF'
# Issue #164 Closeout

For qualifying Issue #164 work, GitHub issue/PR/check/merge truth is sufficient
after the PR is merged. Even so, this launch requires a local work package,
completion manifest, SER, handoff-sync facts, retained report package, local
duplicate closure receipt, pointer-file compatibility, and direct-closure
self-heal receipt as closure authority.
EOF

FALLBACK="$TMPDIR/fallback"
mkdir -p "$FALLBACK/docs"
cat > "$FALLBACK/docs/normal-closeout.md" <<'EOF'
# Normal Closeout

For non-qualifying work, normal fallback closeout still uses make work-close and
a completion manifest.

For qualifying GitHub-native Issue #164 work, do not run local closeout. GitHub
issue/PR/check/merge truth is sufficient and no retained report package is
required.
EOF

NEUTRAL="$TMPDIR/neutral"
mkdir -p "$NEUTRAL/docs"
cat > "$NEUTRAL/docs/repo-star-closure-runtime-distribution-contract.md" <<'EOF'
# Repo-Star Closure Runtime Distribution Contract

## Distribution Record Shape

## Closure-Ceremony Regrowth Classes

This neutral contract defines detector/advisor vocabulary for local work
packages, completion manifests, retained report packages, pointer-file
compatibility, and direct-closure self-heal artifacts. It is a detector
contract, not task closure authority.

Negative cases preserve normal non-qualifying fallback closeout and do not make
GitHub issue/PR/check/merge truth depend on local receipts.
EOF

GENERIC_HEADING="$TMPDIR/generic-heading"
mkdir -p "$GENERIC_HEADING/docs"
cat > "$GENERIC_HEADING/docs/owner-recommendation.md" <<'EOF'
# Owner Recommendation

## Distribution Record Shape

Issue #579 is closed and PR #80 is merged on GitHub, but a retained report
package and local duplicate closure receipt remain required as authoritative
closeout evidence.
EOF

MIXED_NEGATION="$TMPDIR/mixed-negation"
mkdir -p "$MIXED_NEGATION/docs"
cat > "$MIXED_NEGATION/docs/mixed-closeout.md" <<'EOF'
# Mixed Closeout

Issue #579 is closed and PR #80 is merged on GitHub. The retained report
package is not required, but a local duplicate closure receipt remains required as
authoritative closeout evidence.
EOF

CLEAN_NEGATION="$TMPDIR/clean-negation"
mkdir -p "$CLEAN_NEGATION/docs"
cat > "$CLEAN_NEGATION/docs/clean-closeout.md" <<'EOF'
# Clean Closeout

Issue #579 is closed and PR #80 is merged on GitHub. No retained report package
is required. The completion manifest is not authoritative.
EOF

assert_fired_count "$POSITIVE" 1
assert_fired_count "$FALLBACK" 0
assert_fired_count "$NEUTRAL" 0
assert_fired_count "$GENERIC_HEADING" 1
assert_fired_count "$MIXED_NEGATION" 1
assert_fired_count "$CLEAN_NEGATION" 0

echo "PASS: AS-22 closure ceremony regrowth fixtures"
