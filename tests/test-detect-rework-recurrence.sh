#!/usr/bin/env bash
# test-detect-rework-recurrence.sh — Validate DS-49 re-work recurrence signals.
#
# DS-49 is git-history observable (live-checkout only). These fixtures build
# throwaway git repos with controlled per-commit subjects + file touches to
# exercise the finalize-ACT classifier, the corrective-rework classifier, the
# substantive-file filter, and the double-threshold fire logic.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/detect-rework-recurrence.sh"
TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/ds49.XXXXXX")
trap 'rm -rf "$TMP_ROOT"' EXIT

echo "=== DS-49 Re-work Recurrence Fixtures ==="

init_repo() {
  local repo="$1"
  mkdir -p "$repo"
  git -C "$repo" init -q
  git -C "$repo" config user.email "test@example.com"
  git -C "$repo" config user.name "DS49 Test"
}

# commit_file <repo> <path> <token> <subject>
# Writes <token> into <path> (appending so re-touches produce a real diff),
# stages only that path, and commits with the exact subject line.
commit_file() {
  local repo="$1" path="$2" token="$3" subject="$4"
  mkdir -p "$(dirname "$repo/$path")"
  printf 'line %s\n' "$token" >> "$repo/$path"
  git -C "$repo" add "$path"
  git -C "$repo" commit -q -m "$subject"
}

assert_json() {
  local json="$1" python_check="$2"
  printf '%s' "$json" | python3 -c "$python_check"
}

# ── POSITIVE: finalized code re-worked twice → fires via intensity ≥ 2 ────
POS="$TMP_ROOT/positive"
init_repo "$POS"
commit_file "$POS" scripts/scanner.py 1 "Add scanner module"
commit_file "$POS" scripts/scanner.py 2 "Closeout scanner work: mark scanner complete"
commit_file "$POS" scripts/scanner.py 3 "Fix scanner regression after closeout"
commit_file "$POS" scripts/scanner.py 4 "Redo scanner logic; still broken"

pos_json=$(bash "$SCRIPT" "$POS")
assert_json "$pos_json" '
import json, sys
d = json.load(sys.stdin)
assert d["ds_id"] == "DS-49", d
assert d["fired"] is True, d
assert d["signal"] == "rework-recurrence", d
assert d["finalize_commit_count"] == 1, d
assert d["recurring_area_count"] == 1, d
assert d["max_area_rework_recurrence"] == 2, d
assert "scripts/scanner.py" in d["evidence"], d
'
echo "  ✓ finalized code re-worked twice fires (intensity)"

# ── NEG: finalize followed by ADDITIVE iteration (no rework vocab) ────────
ITER="$TMP_ROOT/normal-iteration"
init_repo "$ITER"
commit_file "$ITER" scripts/mod.py 1 "Add mod module"
commit_file "$ITER" scripts/mod.py 2 "Closeout mod work: mark mod complete"
commit_file "$ITER" scripts/mod.py 3 "Add mod feature two"
commit_file "$ITER" scripts/mod.py 4 "Extend mod capability"

iter_json=$(bash "$SCRIPT" "$ITER")
assert_json "$iter_json" '
import json, sys
d = json.load(sys.stdin)
assert d["fired"] is False, d
assert d["finalize_commit_count"] == 1, d
assert d["recurring_area_count"] == 0, d
assert d["signal"] == "within-tolerance", d
'
echo "  ✓ additive iteration after finalize stays quiet (no corrective vocab)"

# ── NEG: corrective churn with NO prior finalize ─────────────────────────
NOFIN="$TMP_ROOT/no-finalize"
init_repo "$NOFIN"
commit_file "$NOFIN" scripts/x.py 1 "Add x module"
commit_file "$NOFIN" scripts/x.py 2 "Fix x bug"
commit_file "$NOFIN" scripts/x.py 3 "Fix x again"

nofin_json=$(bash "$SCRIPT" "$NOFIN")
assert_json "$nofin_json" '
import json, sys
d = json.load(sys.stdin)
assert d["fired"] is False, d
assert d["finalize_commit_count"] == 0, d
assert d["signal"] == "no-finalize-commits", d
'
echo "  ✓ rework without a prior finalize stays quiet"

# ── NEG: ceremony/doc-only recurrence (non-substantive, excluded) ────────
CEREMONY="$TMP_ROOT/ceremony-only"
init_repo "$CEREMONY"
commit_file "$CEREMONY" docs/notes.md 1 "Add notes"
commit_file "$CEREMONY" docs/notes.md 2 "Closeout docs work: mark docs complete"
commit_file "$CEREMONY" docs/notes.md 3 "Fix docs typo after closeout"
commit_file "$CEREMONY" LEARNINGS.md 1 "Redo learnings entry"

ceremony_json=$(bash "$SCRIPT" "$CEREMONY")
assert_json "$ceremony_json" '
import json, sys
d = json.load(sys.stdin)
assert d["fired"] is False, d
assert d["finalize_commit_count"] == 1, d
assert d["recurring_area_count"] == 0, d
assert d["signal"] == "within-tolerance", d
'
echo "  ✓ ceremony/doc-only recurrence excluded (non-substantive filter)"

# ── NEG: single finalize→one fix (below both thresholds) ─────────────────
ONEOFF="$TMP_ROOT/one-off"
init_repo "$ONEOFF"
commit_file "$ONEOFF" scripts/o.py 1 "Add o module"
commit_file "$ONEOFF" scripts/o.py 2 "Closeout o work: mark o complete"
commit_file "$ONEOFF" scripts/o.py 3 "Fix o small bug"
commit_file "$ONEOFF" scripts/p.py 1 "Add p module"

oneoff_json=$(bash "$SCRIPT" "$ONEOFF")
assert_json "$oneoff_json" '
import json, sys
d = json.load(sys.stdin)
assert d["fired"] is False, d
assert d["finalize_commit_count"] == 1, d
assert d["recurring_area_count"] == 1, d
assert d["max_area_rework_recurrence"] == 1, d
assert d["signal"] == "within-tolerance", d
'
echo "  ✓ single finalize→one fix stays under thresholds (discipline)"

# ── Registration in the DS-34+ runner ────────────────────────────────────
outdir="$TMP_ROOT/run-out"
bash "$REPO_ROOT/scripts/detect-new-signatures.sh" "$POS" "$outdir" > "$TMP_ROOT/run.json"
python3 - "$TMP_ROOT/run.json" "$outdir/DS-34-plus-results.json" <<'PY'
import json
import sys
stdout_report = json.load(open(sys.argv[1]))
output_report = json.load(open(sys.argv[2]))
for report in (stdout_report, output_report):
    assert "DS-49" in report["capability_metadata"]["signature_order"], report
    ds49 = [item for item in report["results"] if item.get("ds_id") == "DS-49"][0]
    assert ds49["fired"] is True, ds49
    assert ds49["signal"] == "rework-recurrence", ds49
PY
echo "  ✓ DS-49 registered in DS-34+ runner"

echo "  VERDICT: PASS"
