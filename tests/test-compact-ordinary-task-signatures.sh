#!/usr/bin/env bash
# Compact ordinary-task behavior must stay outside retained AS-25/26/43 scope.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

ORDINARY_REPO="$TMPDIR/ordinary"
RUNTIME_CLAIM_REPO="$TMPDIR/runtime-claim"
REACTIVE_REPO="$TMPDIR/reactive"
PLACEMENT_OVERCLAIM_REPO="$TMPDIR/placement-overclaim"
mkdir -p "$ORDINARY_REPO/docs" "$RUNTIME_CLAIM_REPO/docs"
mkdir -p "$REACTIVE_REPO/docs" "$PLACEMENT_OVERCLAIM_REPO/docs"

cat > "$ORDINARY_REPO/docs/task.md" <<'EOF'
# Ordinary Task

Material update:
- Delta: focused behavior is implemented and the direct fixture passes.
- Next: run the repository gate.

Terminal report:
- Outcome: the named owner behavior is delivered.
- Residual: repeated use remains unproved.
- Next: choose the largest unclosed owner outcome.

Coordinator return:
- Zoom-out: this advances one governing-parent clause without closing the parent.

For a sparse `continue` turn or pasted recommendations, reload the governing
parent and current owner issue, then resume the largest unclosed outcome.
EOF

cat > "$RUNTIME_CLAIM_REPO/docs/claim.md" <<'EOF'
# Runtime Claim

Goal mode improved runtime health and autonomy. No raw runtime evidence was
retained.
EOF

cat > "$REACTIVE_REPO/docs/failure.md" <<'EOF'
# Failure Route

The provider failure blocked delivery. Retrospective repair and a selector
update are the primary way to handle it.
EOF

cat > "$PLACEMENT_OVERCLAIM_REPO/docs/placement.md" <<'EOF'
# Autonomy Preview

A controller queue automatically creates pull requests and owns downstream
mutation.

Best current owner: the repository owner issue.
Best future owner: the same repository after repeated evidence.
Allowed reach now: advisory findings only.
Native signal: current issue and check truth.
Promotion gate: two owner-approved episodes.
Demotion/rejection trigger: any authority overclaim.
Kill switch: remove the integration through an owner PR.
Forbidden mode: no background agents or automatic merge.
GBrain slug/no-capture reason: no_capture_reason=no durable learning.
EOF

python3 - "$REPO_ROOT" "$ORDINARY_REPO" "$RUNTIME_CLAIM_REPO" "$REACTIVE_REPO" "$PLACEMENT_OVERCLAIM_REPO" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

repo_root, ordinary, runtime_claim, reactive, placement = map(Path, sys.argv[1:])
scripts = {
    "AS-25": "detect-as-goal-runtime-evidence-gap.sh",
    "AS-26": "detect-as-reactive-self-healing-loop.sh",
    "AS-43": "detect-as-capability-placement-gap.sh",
}


def run(signature_id: str, repo: Path) -> dict:
    completed = subprocess.run(
        ["bash", str(repo_root / "scripts" / scripts[signature_id]), str(repo)],
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        raise SystemExit(completed.stderr or completed.stdout)
    return json.loads(completed.stdout)


for signature_id in scripts:
    payload = run(signature_id, ordinary)
    assert payload["ds_id"] == signature_id, payload
    assert payload["fired"] is False, payload

runtime_payload = run("AS-25", runtime_claim)
assert runtime_payload["fired"] is True, runtime_payload
assert runtime_payload["signals"]["goal_runtime_evidence_gap_count"] == 1, runtime_payload

reactive_payload = run("AS-26", reactive)
assert reactive_payload["fired"] is True, reactive_payload
assert reactive_payload["signals"]["reactive_self_healing_loop_count"] == 1, reactive_payload

placement_payload = run("AS-43", placement)
assert placement_payload["fired"] is True, placement_payload
assert placement_payload["signals"]["forbidden_authority_overclaim_count"] == 1, placement_payload
PY

echo "PASS: compact ordinary-task detector scope covered"
