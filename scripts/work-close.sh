#!/usr/bin/env bash
# scripts/work-close.sh — Work contract finalizer for repo-auditor
#
# Captures post-audit SCORECARD, computes integer delta vs baseline,
# writes DELTA.md. REFUSES (exit 1) without learnings extraction.
# Adapted from build-meta-analysis work-close.sh, stripped of outer-loop specifics.
# Deterministic. macOS bash 3.2 compatible.
#
# Usage:
#   work-close.sh <work-dir>
#   work-close.sh <work-dir> --no-novel-findings "rationale"
#   work-close.sh <work-dir> --github-native-closeout "rationale"
#
# Requires: pre-audit baseline from work-init.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

WORK_DIR="${1:?Usage: work-close.sh <work-dir> [--no-novel-findings \"rationale\"]}"
shift

# ── Parse flags ──────────────────────────────────────────────────────
NO_NOVEL_FINDINGS=""
GITHUB_NATIVE_CLOSEOUT=""
while [ $# -gt 0 ]; do
    case "$1" in
        --no-novel-findings) NO_NOVEL_FINDINGS="${2:?--no-novel-findings requires a rationale}"; shift 2 ;;
        --github-native-closeout) GITHUB_NATIVE_CLOSEOUT="${2:?--github-native-closeout requires a rationale}"; shift 2 ;;
        *) shift ;;
    esac
done

# ── Resolve work dir ─────────────────────────────────────────────────
if [[ ! "$WORK_DIR" = /* ]]; then
    WORK_DIR="$REPO_ROOT/$WORK_DIR"
fi

# ── Validate work directory ──────────────────────────────────────────
if [ ! -d "$WORK_DIR" ]; then
    echo "ERROR: Work directory not found: $WORK_DIR" >&2
    exit 1
fi

if [ ! -f "$WORK_DIR/WORK.md" ]; then
    echo "ERROR: No WORK.md found in $WORK_DIR" >&2
    echo "  Run 'make work DESC=\"...\"' to initialize a work contract first." >&2
    exit 1
fi

if [ -n "$GITHUB_NATIVE_CLOSEOUT" ] && [ "${#GITHUB_NATIVE_CLOSEOUT}" -lt 30 ]; then
    echo "ERROR: --github-native-closeout requires a concrete rationale (>=30 chars)." >&2
    exit 1
fi

# ── Validate hypothesis is not a placeholder ─────────────────────────
if grep -qF '{what you expect' "$WORK_DIR/WORK.md"; then
    echo "ERROR: Gate 3 — WORK.md still contains hypothesis placeholder text." >&2
    echo "  Fill in the Hypothesis section before closing the work contract." >&2
    exit 1
fi

echo "=== Work Close: $WORK_DIR ==="

POST_AUDIT_DIR=""
POST_AUDIT_TMP_DIR=""
POST_AUDIT_BACKUP_DIR=""
POST_AUDIT_SNAPSHOT_DIR=""
SNAPSHOT_HELPER="$REPO_ROOT/scripts/prepare-clean-audit-snapshot.py"

cleanup_post_audit_snapshot() {
    if [ -n "$POST_AUDIT_SNAPSHOT_DIR" ] && [ -d "$POST_AUDIT_SNAPSHOT_DIR" ]; then
        rm -rf "$POST_AUDIT_SNAPSHOT_DIR"
    fi
    POST_AUDIT_SNAPSHOT_DIR=""
}

prepare_post_audit_snapshot() {
    local work_dir_rel="$1"
    local snapshot_root="${TMPDIR:-/tmp}"

    if [ ! -f "$SNAPSHOT_HELPER" ]; then
        echo "ERROR: snapshot helper not found: $SNAPSHOT_HELPER" >&2
        return 1
    fi

    POST_AUDIT_SNAPSHOT_DIR="$(mktemp -d "$snapshot_root/$(basename "$WORK_DIR").post-audit.snapshot.XXXXXX")"
    rm -rf "$POST_AUDIT_SNAPSHOT_DIR"

    python3 "$SNAPSHOT_HELPER" "$REPO_ROOT" "$POST_AUDIT_SNAPSHOT_DIR" \
        --exclude-relpath "$work_dir_rel/post-audit" \
        --exclude-relpath "$work_dir_rel/DELTA.md" \
        --exclude-relpath "$work_dir_rel/compare-output.txt" \
        --exclude-relpath "$work_dir_rel/measurement-summary.json" \
        --exclude-relpath "$work_dir_rel/ser-summary.json" \
        --exclude-relpath "$work_dir_rel/ser-effectivity.json" \
        --exclude-relpath "$work_dir_rel/OPERATING_MODEL_SCORECARD.json" \
        --exclude-relpath "$work_dir_rel/score-session-bypass.json" \
        --exclude-relpath "$work_dir_rel/closeout-reconciliation.json" \
        --exclude-relpath "$work_dir_rel/closeout-telemetry.json" \
        > /dev/null
}

restore_post_audit_dir_on_abort() {
    if [ -z "$POST_AUDIT_DIR" ]; then
        cleanup_post_audit_snapshot
        return
    fi
    if [ -n "$POST_AUDIT_TMP_DIR" ] && [ -d "$POST_AUDIT_TMP_DIR" ]; then
        rm -rf "$POST_AUDIT_TMP_DIR"
    fi
    if [ -n "$POST_AUDIT_BACKUP_DIR" ] && [ -d "$POST_AUDIT_BACKUP_DIR" ]; then
        rm -rf "$POST_AUDIT_DIR"
        mv "$POST_AUDIT_BACKUP_DIR" "$POST_AUDIT_DIR"
    fi
    POST_AUDIT_DIR=""
    POST_AUDIT_TMP_DIR=""
    POST_AUDIT_BACKUP_DIR=""
    cleanup_post_audit_snapshot
}

abort_post_audit_closeout() {
    local exit_code="$1"
    restore_post_audit_dir_on_abort
    trap - EXIT INT TERM
    exit "$exit_code"
}

trap 'restore_post_audit_dir_on_abort' EXIT
trap 'abort_post_audit_closeout 130' INT
trap 'abort_post_audit_closeout 143' TERM

# ── Gate 3a: Pre-audit must exist ────────────────────────────────────
if [ ! -f "$WORK_DIR/pre-audit/SCORECARD.json" ]; then
    echo "ERROR: No pre-audit baseline found at $WORK_DIR/pre-audit/SCORECARD.json" >&2
    echo "  The work contract was not properly initialized." >&2
    exit 1
fi

# ── Gate 3b: Learning extraction required ────────────────────────────
LEARNINGS_ADDED=0
if [ -f LEARNINGS.md ] && [ -f "$WORK_DIR/.learnings_baseline_count" ]; then
    BASELINE_COUNT=$(cat "$WORK_DIR/.learnings_baseline_count")
    CURRENT_COUNT=$(grep -cE '^\| L[0-9]+' LEARNINGS.md 2>/dev/null || echo "0")
    LEARNINGS_ADDED=$((CURRENT_COUNT - BASELINE_COUNT))
fi

if [ "$LEARNINGS_ADDED" -le 0 ] && [ -z "$NO_NOVEL_FINDINGS" ]; then
    echo "" >&2
    echo "ERROR: Gate 3 — Learning extraction required before closing work contract." >&2
    echo "  LEARNINGS.md has $LEARNINGS_ADDED new L-number entries (need ≥1)." >&2
    echo "  Either:" >&2
    echo "    (a) Append at least one L-number to LEARNINGS.md, or" >&2
    echo "    (b) Re-run with: bash scripts/work-close.sh \"$WORK_DIR\" --no-novel-findings \"rationale\"" >&2
    echo "" >&2
    exit 1
fi

# ── Gate 3c: Post-audit ──────────────────────────────────────────────
echo "  Running post-audit..."
POST_AUDIT_DIR="$WORK_DIR/post-audit"
POST_AUDIT_TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/$(basename "$WORK_DIR").post-audit.run.XXXXXX")"
POST_AUDIT_BACKUP_DIR=""
if [ -d "$POST_AUDIT_DIR" ]; then
    POST_AUDIT_BACKUP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/$(basename "$WORK_DIR").post-audit.backup.XXXXXX")"
    rm -rf "$POST_AUDIT_BACKUP_DIR"
    mv "$POST_AUDIT_DIR" "$POST_AUDIT_BACKUP_DIR"
fi
WORK_DIR_REL=""
case "$WORK_DIR" in
    "$REPO_ROOT"/*)
        WORK_DIR_REL="${WORK_DIR#"$REPO_ROOT"/}"
        ;;
esac
if prepare_post_audit_snapshot "$WORK_DIR_REL" &&
    bash scripts/repo-auditor.sh "$POST_AUDIT_SNAPSHOT_DIR" "$POST_AUDIT_TMP_DIR" > /dev/null 2>&1; then
    rm -rf "$POST_AUDIT_DIR"
    mv "$POST_AUDIT_TMP_DIR" "$POST_AUDIT_DIR"
    [ -n "$POST_AUDIT_BACKUP_DIR" ] && rm -rf "$POST_AUDIT_BACKUP_DIR"
    POST_AUDIT_DIR=""
    POST_AUDIT_TMP_DIR=""
    POST_AUDIT_BACKUP_DIR=""
    cleanup_post_audit_snapshot
    echo "  Post-audit complete."
else
    POST_AUDIT_STATUS=$?
    cleanup_post_audit_snapshot
    if [ -f "$POST_AUDIT_TMP_DIR/SCORECARD.json" ]; then
        mv "$POST_AUDIT_TMP_DIR/SCORECARD.json" "$POST_AUDIT_TMP_DIR/SCORECARD.failure-fragment.json"
    fi
    cat > "$POST_AUDIT_TMP_DIR/AUDIT_FAILURE.json" <<EOF
{
  "status": "failure",
  "composite": null,
  "exit_code": $POST_AUDIT_STATUS,
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "note": "Post-audit exited nonzero before a trustworthy SCORECARD.json could be retained."
}
EOF
    if [ -n "$POST_AUDIT_BACKUP_DIR" ] && [ -d "$POST_AUDIT_BACKUP_DIR" ]; then
        rm -rf "$POST_AUDIT_TMP_DIR/previous-post-audit"
        mv "$POST_AUDIT_BACKUP_DIR" "$POST_AUDIT_TMP_DIR/previous-post-audit"
        if [ -f "$POST_AUDIT_TMP_DIR/previous-post-audit/SCORECARD.json" ]; then
            mv "$POST_AUDIT_TMP_DIR/previous-post-audit/SCORECARD.json" \
                "$POST_AUDIT_TMP_DIR/previous-post-audit/SCORECARD.previous.json"
        fi
    fi
    rm -rf "$POST_AUDIT_DIR"
    mv "$POST_AUDIT_TMP_DIR" "$POST_AUDIT_DIR"
    if [ -d "$POST_AUDIT_DIR/previous-post-audit" ]; then
        echo "  WARNING: Post-audit failed. Previous post-audit evidence preserved under previous-post-audit/."
    else
        echo "  WARNING: Post-audit failed. DELTA will be unavailable."
    fi
    POST_AUDIT_DIR=""
    POST_AUDIT_TMP_DIR=""
    POST_AUDIT_BACKUP_DIR=""
fi

# ── Compute delta ────────────────────────────────────────────────────
PRE_SCORE="?"
POST_SCORE="?"
DELTA="?"
if [ -f "$WORK_DIR/pre-audit/SCORECARD.json" ] && [ -f "$WORK_DIR/post-audit/SCORECARD.json" ]; then
    if [ -f scripts/compare-scorecards.sh ]; then
        bash scripts/compare-scorecards.sh "$WORK_DIR/pre-audit/SCORECARD.json" "$WORK_DIR/post-audit/SCORECARD.json" > "$WORK_DIR/compare-output.txt" 2>&1 || true
    fi
    PRE_SCORE=$(python3 -c "import json; print(json.load(open('$WORK_DIR/pre-audit/SCORECARD.json')).get('composite','?'))" 2>/dev/null || echo "?")
    POST_SCORE=$(python3 -c "import json; print(json.load(open('$WORK_DIR/post-audit/SCORECARD.json')).get('composite','?'))" 2>/dev/null || echo "?")
    if [ "$PRE_SCORE" != "?" ] && [ "$POST_SCORE" != "?" ]; then
        DELTA=$((POST_SCORE - PRE_SCORE))
    fi
fi

# ── Write DELTA.md ───────────────────────────────────────────────────
cat > "$WORK_DIR/DELTA.md" <<EOF
# Delta Report

| Metric | Pre | Post | Delta |
|--------|-----|------|-------|
| Composite | $PRE_SCORE | $POST_SCORE | $DELTA |

## Learnings Added: $LEARNINGS_ADDED

$(if [ -n "$NO_NOVEL_FINDINGS" ]; then echo "**No-novel-findings:** $NO_NOVEL_FINDINGS"; fi)

Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

echo "  DELTA.md written."

# ── Session grader (soft dependency) ─────────────────────────────────
SESSION_ID=$(basename "$WORK_DIR")
SCORE_SESSION_MODE="session_grader"
if [ -n "$GITHUB_NATIVE_CLOSEOUT" ]; then
    SCORE_SESSION_MODE="github_native_bypass"
    BYPASS_FILE="$WORK_DIR/score-session-bypass.json"
    python3 - "$BYPASS_FILE" "$WORK_DIR" "$SESSION_ID" "$GITHUB_NATIVE_CLOSEOUT" <<'PY'
import json
import os
import sys
from datetime import datetime, timezone

out, work_dir, session_id, rationale = sys.argv[1:]
repo_root = os.getcwd()
try:
    rel_work_dir = os.path.relpath(work_dir, repo_root)
except ValueError:
    rel_work_dir = work_dir

receipt = {
    "schema_version": "1.0.0",
    "mode": "github_native_issue_pr",
    "status": "score_session_not_authoritative",
    "work_dir": rel_work_dir,
    "session_id": session_id,
    "skipped_script": "scripts/score-session.sh",
    "rationale": rationale,
    "non_claims": [
        "Does not prove GitHub issue closure by itself.",
        "Does not apply to non-GitHub or session-local work.",
        "Does not change score-session thresholds."
    ],
    "generated_at": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
}

with open(out, "w", encoding="utf-8") as fh:
    json.dump(receipt, fh, indent=2, sort_keys=True)
    fh.write("\n")
PY
    echo "  Session grader skipped: GitHub-native issue/PR closure authority."
elif [ -f scripts/score-session.sh ]; then
    echo "  Running session grader..."
    if bash scripts/score-session.sh "$WORK_DIR" "$SESSION_ID" 2>&1; then
        echo "  Session grader complete."
    else
        echo "  WARNING: Session grader failed (non-blocking)."
    fi
else
    echo "  WARNING: scripts/score-session.sh not found (skipping session grader)."
fi

# ── Operations ledger (13.1.5: T1 mechanical) ─────────────────────────
# Append JSONL event to work/OPERATIONS_LEDGER.jsonl for fleet-level observability.
# Schema: compatible with BMA score-ledger-event.schema.json.
OPS_LEDGER="${WORK_CLOSE_OPS_LEDGER:-$REPO_ROOT/work/OPERATIONS_LEDGER.jsonl}"
_ops_ts=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
_ops_rid=$(echo "ops-$(basename "$WORK_DIR")-$PRE_SCORE-$POST_SCORE" | shasum -a 256 | head -c 16)
_ops_ver=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
# Quote scores as strings to handle "?" fallback values safely
_ops_event="{\"event_type\":\"work-close\",\"run_id\":\"$_ops_rid\",\"timestamp\":\"$_ops_ts\",\"target_id\":\"$(basename "$REPO_ROOT")\",\"source\":{\"script\":\"work-close.sh\",\"version\":\"$_ops_ver\"},\"data\":{\"composite_pre\":\"$PRE_SCORE\",\"composite_post\":\"$POST_SCORE\",\"delta\":\"$DELTA\",\"learnings_added\":$LEARNINGS_ADDED,\"work_dir\":\"$(basename "$WORK_DIR")\",\"score_session_mode\":\"$SCORE_SESSION_MODE\"}}"
if echo "$_ops_event" | python3 -c "import json,sys; json.loads(sys.stdin.read())" 2>/dev/null; then
    echo "$_ops_event" >> "$OPS_LEDGER"
    echo "  Ops ledger: recorded (delta=$DELTA, learnings=$LEARNINGS_ADDED)"
else
    echo "  WARNING: Ops ledger event failed JSON validation (skipped)."
fi

# ── Summary ──────────────────────────────────────────────────────────
echo ""
echo "=== Work Close Summary ==="
echo "  Work Dir:    $WORK_DIR"
echo "  Pre-Score:   $PRE_SCORE"
echo "  Post-Score:  $POST_SCORE"
echo "  Delta:       $DELTA"
echo "  Learnings:   $LEARNINGS_ADDED new"
if [ -n "$NO_NOVEL_FINDINGS" ]; then
    echo "  NNF:         $NO_NOVEL_FINDINGS"
fi
echo "  Artifacts:   DELTA.md$([ -f "$WORK_DIR/OPERATING_MODEL_SCORECARD.json" ] && echo ', OPERATING_MODEL_SCORECARD.json')$([ -f "$WORK_DIR/score-session-bypass.json" ] && echo ', score-session-bypass.json')"
echo "=== Done ==="
