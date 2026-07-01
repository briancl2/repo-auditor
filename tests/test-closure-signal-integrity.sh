#!/usr/bin/env bash
# Verify AS-54 detects successful work-close/closure evidence paired with
# degraded post-audit/scorer signals. Read-only; targets are never modified.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

GAP_REPO="$TMPDIR/closure-signal-gap"
CLEAN_REPO="$TMPDIR/closure-signal-clean"
NEGATED_REPO="$TMPDIR/closure-signal-negated"
TRACKED_WORK_REPO="$TMPDIR/closure-signal-tracked-work"
TABLE_ROW_REPO="$TMPDIR/closure-signal-table-row"
NESTED_SNAPSHOT_REPO="$TMPDIR/closure-signal-nested-snapshot"
mkdir -p "$GAP_REPO/docs" "$CLEAN_REPO/docs" "$NEGATED_REPO/docs" "$TABLE_ROW_REPO/docs" \
  "$TRACKED_WORK_REPO/work/20990101T000000Z" "$TRACKED_WORK_REPO/work/scratch-session" \
  "$NESTED_SNAPSHOT_REPO/work/20990102T000000Z/post-audit/pre-scan" \
  "$NESTED_SNAPSHOT_REPO/docs/post-audit-checklist"

# --- GAP: closeout exits successfully but retained signal is degraded ---
cat > "$GAP_REPO/docs/work-close-run.md" <<'EOF'
# Work-close D1/D2 evidence

work-close exits 0 for the owner lane.
post-audit unavailable: score-audit-dimensions.sh did not produce the post-audit leg.
The retained SCORECARD.json is PARTIAL scorecard evidence.
score-session emitted an integer-expression error while grading closure.
EOF

# --- CLEAN: normal small repo / no degraded post-audit artifacts ---
cat > "$CLEAN_REPO/README.md" <<'EOF'
# Small repo

This ordinary repository has a small README, a normal test command, and no
CURRENT_STATE.md, no work-close transcript, and no degraded score artifacts.
EOF
cat > "$CLEAN_REPO/docs/checks.md" <<'EOF'
# Checks

make test passes. No closeout scorer artifacts are retained for this fixture.
EOF

# --- NEGATED: mentions the hazard only as an explicitly clean non-claim ---
cat > "$NEGATED_REPO/docs/closure-health.md" <<'EOF'
# Closure health

work-close exits 0.
No post-audit unavailable state was observed.
No PARTIAL scorecard was emitted, and no integer-expression error occurred.
EOF

# --- TRACKED WORK: a git-tracked work/<timestamp>Z/ closure receipt records a
# real instance (checked completion item, no literal exit code logged) paired
# with degraded post-audit evidence; a sibling untracked/gitignored work/
# scratch directory must stay excluded so tracked-evidence visibility doesn't
# also pull in ad-hoc session scratch. ---
cat > "$TRACKED_WORK_REPO/work/20990101T000000Z/WORK.md" <<'EOF'
# Work-close receipt

## Status

- [x] work-close run

Post-audit unavailable: the external post-audit step did not run for this lane.
The retained SCORECARD.json is PARTIAL scorecard evidence.
EOF
cat > "$TRACKED_WORK_REPO/work/scratch-session/NOTES.md" <<'EOF'
# Scratch notes (untracked, must not be scanned)

work-close exits 0.
post-audit unavailable: this is decoy content that must not surface as evidence
because this directory is untracked scratch, not committed closure evidence.
EOF
cat > "$TRACKED_WORK_REPO/.gitignore" <<'EOF'
work/scratch-session/
EOF
git -C "$TRACKED_WORK_REPO" init -q
git -C "$TRACKED_WORK_REPO" config user.email "test@example.com"
git -C "$TRACKED_WORK_REPO" config user.name "Test"
git -C "$TRACKED_WORK_REPO" add -A
git -C "$TRACKED_WORK_REPO" commit -q -m "tracked work-close receipt fixture"

# --- TABLE ROW: closure success/degraded evidence logged as a markdown
# table cell rather than plain prose. General coverage: AS-54's success/
# degraded patterns must match regardless of whether the surrounding line
# happens to be table-formatted. (AS-55 has its own glossary/path-map
# false-catch fix, scoped to its own patterns only -- this fixture guards
# against a future regression that reintroduces any shared table-row
# filtering into AS-54.) ---
cat > "$TABLE_ROW_REPO/docs/work-close-status.md" <<'EOF'
# Work-close status table

| Item | Notes |
| --- | --- |
| Closure | work-close exits 0; post-audit unavailable; retained SCORECARD.json is PARTIAL scorecard evidence |
EOF

# --- NESTED SNAPSHOT: pre-audit/post-audit/pre-scan is excluded ONLY when
# nested under a work/<timestamp>Z/ receipt (a captured copy of this tool's
# own audit-tool output), not as a blanket path-segment match. A real
# work/ closure receipt one level up must still fire; a decoy file nested
# under work/.../post-audit/pre-scan/ must be excluded; and an owner-authored
# doc named docs/post-audit-checklist/ that is NOT nested under work/ must
# remain fully eligible/visible. ---
cat > "$NESTED_SNAPSHOT_REPO/work/20990102T000000Z/WORK.md" <<'EOF'
# Work-close receipt

work-close exits 0.
post-audit unavailable: score-audit-dimensions.sh did not produce the post-audit leg.
The retained SCORECARD.json is PARTIAL scorecard evidence.
EOF
cat > "$NESTED_SNAPSHOT_REPO/work/20990102T000000Z/post-audit/pre-scan/DECOY.md" <<'EOF'
# Nested audit-tool snapshot (must not surface as its own evidence line)

work-close exits 0.
post-audit unavailable: this decoy line lives inside a nested pre-audit/
post-audit/pre-scan snapshot and must not be double-counted as a separate
evidence surface.
EOF
cat > "$NESTED_SNAPSHOT_REPO/docs/post-audit-checklist/NOTES.md" <<'EOF'
# Post-audit checklist (owner-authored, NOT a work/ receipt snapshot)

work-close exits 0.
post-audit unavailable: this owner-authored checklist doc lives outside any
work/ directory and must remain eligible for scanning -- the nested
pre-audit/post-audit/pre-scan exclusion only applies when nested under a
work/ receipt.
The retained SCORECARD.json is PARTIAL scorecard evidence.
EOF
git -C "$NESTED_SNAPSHOT_REPO" init -q
git -C "$NESTED_SNAPSHOT_REPO" config user.email "test@example.com"
git -C "$NESTED_SNAPSHOT_REPO" config user.name "Test"
git -C "$NESTED_SNAPSHOT_REPO" add -A
git -C "$NESTED_SNAPSHOT_REPO" commit -q -m "nested snapshot vs owner-authored post-audit doc fixture"

python3 - "$REPO_ROOT" "$GAP_REPO" "$CLEAN_REPO" "$NEGATED_REPO" "$TRACKED_WORK_REPO" "$TABLE_ROW_REPO" "$NESTED_SNAPSHOT_REPO" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

repo_root, gap_repo, clean_repo, negated_repo, tracked_work_repo, table_row_repo, nested_snapshot_repo = map(Path, sys.argv[1:])


def run(repo: Path) -> dict:
    completed = subprocess.run(
        ["bash", str(repo_root / "scripts/detect-as-closure-signal-integrity.sh"), str(repo)],
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        raise SystemExit(completed.stderr or completed.stdout)
    return json.loads(completed.stdout)


gap = run(gap_repo)
assert gap["ds_id"] == "AS-54", gap
assert gap["family"] == "AS", gap
assert gap["name"] == "closure-signal-integrity", gap
assert gap["severity"] == "HIGH", gap
assert gap["fired"] is True, gap
assert gap["signals"]["closure_signal_integrity_gap_count"] == 1, gap
assert gap["signals"]["closure_success_surface_count"] == 1, gap
assert gap["signals"]["degraded_closure_signal_surface_count"] == 1, gap

clean = run(clean_repo)
assert clean["ds_id"] == "AS-54", clean
assert clean["fired"] is False, clean
assert clean["signals"]["closure_signal_integrity_gap_count"] == 0, clean

negated = run(negated_repo)
assert negated["ds_id"] == "AS-54", negated
assert negated["fired"] is False, negated
assert negated["signals"]["closure_signal_integrity_gap_count"] == 0, negated

tracked_work = run(tracked_work_repo)
assert tracked_work["ds_id"] == "AS-54", tracked_work
# Right-reason: a git-tracked work/<timestamp>Z/ closure receipt (checked
# completion item, no literal exit code) paired with degraded post-audit
# evidence must now be visible and fire; the SKIP_PARTS narrowing exists
# specifically so committed work/ evidence is not blanket-excluded.
assert tracked_work["fired"] is True, tracked_work
assert tracked_work["signals"]["closure_signal_integrity_gap_count"] == 1, tracked_work
assert tracked_work["signals"]["closure_success_surface_count"] == 1, tracked_work
assert tracked_work["signals"]["degraded_closure_signal_surface_count"] == 1, tracked_work
assert "work/20990101T000000Z/WORK.md" in tracked_work["evidence"], tracked_work
# The sibling untracked/gitignored work/scratch-session/ directory must stay
# excluded: tracked-evidence visibility must not pull in ad-hoc scratch.
assert "scratch-session" not in tracked_work["evidence"], tracked_work

table_row = run(table_row_repo)
assert table_row["ds_id"] == "AS-54", table_row
# General coverage: table-formatted closure success/degraded evidence must
# still fire. AS-54's success/degraded matching must not depend on line
# formatting (prose vs. table cell).
assert table_row["fired"] is True, table_row
assert table_row["signals"]["closure_signal_integrity_gap_count"] == 1, table_row
assert table_row["signals"]["closure_success_surface_count"] == 1, table_row
assert table_row["signals"]["degraded_closure_signal_surface_count"] == 1, table_row

nested_snapshot = run(nested_snapshot_repo)
assert nested_snapshot["ds_id"] == "AS-54", nested_snapshot
assert nested_snapshot["fired"] is True, nested_snapshot
# Exactly two offenders: the work/ receipt itself and the non-nested
# owner-authored docs/post-audit-checklist/ doc. The decoy nested under
# work/.../post-audit/pre-scan/ must be excluded from scanning entirely, so
# it must not inflate the count to 3 or appear in the evidence string.
assert nested_snapshot["signals"]["closure_signal_integrity_gap_count"] == 2, nested_snapshot
assert "work/20990102T000000Z/WORK.md" in nested_snapshot["evidence"], nested_snapshot
assert "docs/post-audit-checklist/NOTES.md" in nested_snapshot["evidence"], nested_snapshot
assert "post-audit/pre-scan/DECOY.md" not in nested_snapshot["evidence"], nested_snapshot
PY

echo "PASS: AS-54 closure-signal integrity detector covered"
