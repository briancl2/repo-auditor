#!/usr/bin/env bash
# scripts/check.sh — Gate 2 pre-commit check for repo-auditor
#
# Runs: shellcheck, inventory match, co-evolution, convergence, trailer check.
# Deterministic. macOS bash 3.2 compatible.
#
# Usage: bash scripts/check.sh
# Exit: 0 if all pass, 1 if any fail

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

FAIL=0

python3 scripts/closure_identity.py \
    --phase "${CLOSURE_PHASE:-check}" \
    --parent-command "${PARENT_COMMAND:-make check}"

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
EXPECTED=97  # shell scripts only; AS-37 and AS-45 wrappers are retired
COUNTED=$(find scripts -maxdepth 1 -name '*.sh' -type f | wc -l | tr -d ' ')
if [ "$COUNTED" != "$EXPECTED" ]; then
    echo "  FAIL: expected $EXPECTED scripts, found $COUNTED"
    FAIL=1
else
    echo "  PASS: inventory ($COUNTED scripts)"
fi

# ── Co-evolution guard ──────────────────────────────────────────────────
echo "── co-evolution ──"
if ! bash scripts/check-coevolution.sh; then
    FAIL=1
fi

# ── Owner convergence ─────────────────────────────────────────────────
echo "── owner convergence ──"
CONVERGENCE_ARGS=(
    --repo .
    --base-ref "${OWNER_CONVERGENCE_BASE_REF:-e8b42763eb3e323d0e0238e84fe81c4c87898627}"
    --core-ref "${CORE_BASELINE_REF:-9da7b41b83a10b9fd71ad24b0529a50425a8d373}"
)
if [ -n "${CORE_REPO:-}" ]; then
    CONVERGENCE_ARGS+=(--core-repo "$CORE_REPO")
fi
if ! python3 scripts/validate_owner_convergence.py "${CONVERGENCE_ARGS[@]}"; then
    FAIL=1
fi

# ── Trailer check ─────────────────────────────────────────────────────
echo "── trailer ──"
if ! bash scripts/validate-commit-provenance.sh HEAD; then
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
