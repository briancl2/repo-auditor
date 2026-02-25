#!/usr/bin/env bash
# scripts/check.sh — Gate 2 pre-commit check for repo-auditor
#
# Runs: shellcheck, inventory match, trailer check.
# Deterministic. macOS bash 3.2 compatible.
#
# Usage: bash scripts/check.sh
# Exit: 0 if all pass, 1 if any fail

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

FAIL=0

# ── Shellcheck ────────────────────────────────────────────────────────
echo "── shellcheck ──"
if ! command -v shellcheck > /dev/null 2>&1; then
    echo "  FAIL: shellcheck not installed (brew install shellcheck)"
    FAIL=1
else
    SC_PASS=0
    SC_FAIL=0
    SC_EXCLUDE="SC2034,SC2086,SC2155,SC2207,SC2064,SC2044,SC2038"
    for f in scripts/*.sh; do
        if shellcheck -S warning -e "$SC_EXCLUDE" "$f" > /dev/null 2>&1; then
            SC_PASS=$((SC_PASS + 1))
        else
            echo "  FAIL: $f"
            shellcheck -S warning -e "$SC_EXCLUDE" "$f" 2>&1 | head -20 || true
            SC_FAIL=$((SC_FAIL + 1))
            FAIL=1
        fi
    done
    echo "  shellcheck: $SC_PASS pass, $SC_FAIL fail"
fi

# ── Inventory match ───────────────────────────────────────────────────
echo "── inventory ──"
EXPECTED=17  # 16 prev + detect-grader-ceiling.sh (DS-30)
COUNTED=$(find scripts -maxdepth 1 -name '*.sh' -type f | wc -l | tr -d ' ')
if [ "$COUNTED" != "$EXPECTED" ]; then
    echo "  FAIL: expected $EXPECTED scripts, found $COUNTED"
    FAIL=1
else
    echo "  PASS: inventory ($COUNTED scripts)"
fi

# ── Trailer check ─────────────────────────────────────────────────────
echo "── trailer ──"
LAST_MSG=$(git log -1 --format=%B 2>/dev/null || echo "")
if echo "$LAST_MSG" | grep -qE '^(Spec-ID|Spec-Exempt):'; then
    echo "  PASS: last commit has Spec-ID or Spec-Exempt trailer"
elif [ -z "$LAST_MSG" ]; then
    echo "  SKIP: no commits yet"
else
    echo "  FAIL: last commit lacks Spec-ID or Spec-Exempt trailer"
    FAIL=1
fi

# ── Result ────────────────────────────────────────────────────────────
echo ""
if [ "$FAIL" -eq 0 ]; then
    echo "=== ALL PASS ==="
    exit 0
else
    echo "=== FAILED ==="
    exit 1
fi
