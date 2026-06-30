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
mkdir -p "$GAP_REPO/docs" "$CLEAN_REPO/docs" "$NEGATED_REPO/docs"

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

python3 - "$REPO_ROOT" "$GAP_REPO" "$CLEAN_REPO" "$NEGATED_REPO" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

repo_root, gap_repo, clean_repo, negated_repo = map(Path, sys.argv[1:])


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
PY

echo "PASS: AS-54 closure-signal integrity detector covered"
