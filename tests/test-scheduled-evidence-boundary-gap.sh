#!/usr/bin/env bash
# Verify AS-39 detects scheduled workflow evidence boundary gaps without flagging clean scheduled readback material.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

GAP_REPO="$TMPDIR/scheduled-shadow-gap"
CLEAN_REPO="$TMPDIR/scheduled-shadow-clean"
NEUTRAL_REPO="$TMPDIR/scheduled-shadow-neutral"
mkdir -p "$GAP_REPO/docs" "$CLEAN_REPO/docs" "$NEUTRAL_REPO/docs"

cat > "$GAP_REPO/docs/readback.md" <<'EOF'
# Runtime Learning Shadow scheduled readback

The scheduled workflow evidence is complete because comments are closure truth
and artifacts close #798. A background controller owns the scheduler and queue.
The note does not retain event=schedule, run_id, run_number, run_attempt, or
any review disposition.
EOF

cat > "$CLEAN_REPO/docs/readback.md" <<'EOF'
# Runtime Learning Shadow scheduled readback

- event_name: schedule
- run_id: 987654321
- run_number: 42
- run_attempt: 1
- actionability_classification: clean no-op
- four-run disposition: reduce_frequency unless named value is proved
- Closure boundary: generated comments and artifacts are evidence only, not closure truth.
- GitHub issue/PR/check/merge truth remains closure truth; this does not close #798.
- Boundary: no scheduler, queue, daemon, controller, registry, retry loop, background GBrain, or background Hermes behavior.
EOF

cat > "$NEUTRAL_REPO/docs/detector-note.md" <<'EOF'
# AS-39 detector note

AS-39: Scheduled Workflow Evidence Boundary Gap detects comments/artifacts
treated as closure truth. This detector note is explanatory material, not a
Runtime Learning Shadow readback.
EOF

python3 - "$REPO_ROOT" "$GAP_REPO" "$CLEAN_REPO" "$NEUTRAL_REPO" <<'PY'
import json
import subprocess
import sys

repo_root, gap_repo, clean_repo, neutral_repo = sys.argv[1:5]

def run(repo):
    completed = subprocess.run(
        ["bash", f"{repo_root}/scripts/detect-as-scheduled-evidence-boundary-gap.sh", repo],
        check=True,
        text=True,
        stdout=subprocess.PIPE,
    )
    return json.loads(completed.stdout)

gap = run(gap_repo)
assert gap["ds_id"] == "AS-39", gap
assert gap["fired"] is True, gap
assert gap["signals"]["scheduled_evidence_boundary_gap_count"] == 1, gap
assert gap["signals"]["missing_schedule_run_identity_count"] == 1, gap
assert gap["signals"]["missing_review_disposition_count"] == 1, gap
assert gap["signals"]["comments_or_artifacts_as_closure_truth_count"] == 1, gap
assert gap["signals"]["background_control_wording_count"] == 1, gap

for repo in (clean_repo, neutral_repo):
    payload = run(repo)
    assert payload["ds_id"] == "AS-39", payload
    assert payload["fired"] is False, payload
    assert payload["signals"]["scheduled_evidence_boundary_gap_count"] == 0, payload
PY

echo "Scheduled evidence boundary gap detector test passed."
