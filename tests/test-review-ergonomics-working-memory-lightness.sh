#!/usr/bin/env bash
# Verify AS-55 detects oversized CURRENT_STATE.md / review-timeout override
# working-memory friction. Read-only; targets are never modified.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

INLINE_GAP_REPO="$TMPDIR/review-ergonomics-inline-gap"
LARGE_STATE_REPO="$TMPDIR/review-ergonomics-large-state"
CLEAN_REPO="$TMPDIR/review-ergonomics-clean"
SMALL_STATE_REPO="$TMPDIR/review-ergonomics-small-state"
NEGATED_REPO="$TMPDIR/review-ergonomics-negated"
mkdir -p "$INLINE_GAP_REPO/docs" "$LARGE_STATE_REPO" "$CLEAN_REPO/docs" "$SMALL_STATE_REPO" "$NEGATED_REPO/docs"

# --- INLINE GAP: documented working-memory pressure and timeout override ---
cat > "$INLINE_GAP_REPO/docs/review-friction.md" <<'EOF'
# Review friction

CURRENT_STATE.md is oversized and creates working-memory overload for review.
The owner lane required a review timeout override before the change could land.
EOF

# --- LARGE CURRENT_STATE: file-size pressure even without explanatory prose ---
python3 - "$LARGE_STATE_REPO/CURRENT_STATE.md" <<'PY'
import sys
from pathlib import Path

Path(sys.argv[1]).write_text("# Current state\n\n" + ("status line\n" * 1700))
PY

# --- CLEAN: normal small repo with no CURRENT_STATE.md or review timeout ---
cat > "$CLEAN_REPO/README.md" <<'EOF'
# Small repo

This ordinary repository has no CURRENT_STATE.md, no review timeout override,
and no retained working-memory pressure artifacts.
EOF

# --- SMALL STATE: CURRENT_STATE.md exists but stays bounded and reviewable ---
cat > "$SMALL_STATE_REPO/CURRENT_STATE.md" <<'EOF'
# Current state

Small bounded handoff. Review completes normally.
EOF

# --- NEGATED: mentions the hazard only as a clean non-claim ---
cat > "$NEGATED_REPO/docs/review-health.md" <<'EOF'
# Review health

CURRENT_STATE.md remains small and bounded.
No review timeout override was needed.
No working-memory overload was observed.
EOF

python3 - "$REPO_ROOT" "$INLINE_GAP_REPO" "$LARGE_STATE_REPO" "$CLEAN_REPO" "$SMALL_STATE_REPO" "$NEGATED_REPO" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

repo_root, inline_gap_repo, large_state_repo, clean_repo, small_state_repo, negated_repo = map(Path, sys.argv[1:])


def run(repo: Path) -> dict:
    completed = subprocess.run(
        ["bash", str(repo_root / "scripts/detect-as-review-ergonomics-working-memory-lightness.sh"), str(repo)],
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        raise SystemExit(completed.stderr or completed.stdout)
    return json.loads(completed.stdout)


inline_gap = run(inline_gap_repo)
assert inline_gap["ds_id"] == "AS-55", inline_gap
assert inline_gap["family"] == "AS", inline_gap
assert inline_gap["name"] == "review-ergonomics-working-memory-lightness", inline_gap
assert inline_gap["severity"] == "MEDIUM", inline_gap
assert inline_gap["fired"] is True, inline_gap
assert inline_gap["signals"]["review_ergonomics_working_memory_lightness_count"] == 1, inline_gap
assert inline_gap["signals"]["review_timeout_override_surface_count"] == 1, inline_gap
assert inline_gap["signals"]["working_memory_overload_surface_count"] == 1, inline_gap

large_state = run(large_state_repo)
assert large_state["ds_id"] == "AS-55", large_state
assert large_state["fired"] is True, large_state
assert large_state["signals"]["current_state_file_count"] == 1, large_state
assert large_state["signals"]["oversized_current_state_file_count"] == 1, large_state

clean = run(clean_repo)
assert clean["ds_id"] == "AS-55", clean
assert clean["fired"] is False, clean
assert clean["signals"]["review_ergonomics_working_memory_lightness_count"] == 0, clean
assert clean["signals"]["current_state_file_count"] == 0, clean

small_state = run(small_state_repo)
assert small_state["ds_id"] == "AS-55", small_state
assert small_state["fired"] is False, small_state
assert small_state["signals"]["current_state_file_count"] == 1, small_state
assert small_state["signals"]["oversized_current_state_file_count"] == 0, small_state

negated = run(negated_repo)
assert negated["ds_id"] == "AS-55", negated
assert negated["fired"] is False, negated
assert negated["signals"]["review_ergonomics_working_memory_lightness_count"] == 0, negated
PY

echo "PASS: AS-55 review-ergonomics working-memory lightness detector covered"
