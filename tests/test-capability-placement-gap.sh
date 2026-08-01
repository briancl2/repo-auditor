#!/usr/bin/env bash
# Verify AS-43 stays scoped to capability placement and authority overclaims.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

GAP_REPO="$TMPDIR/capability-placement-gap"
CLEAN_REPO="$TMPDIR/capability-placement-clean"
OVERCLAIM_REPO="$TMPDIR/capability-placement-overclaim"
ORDINARY_REPO="$TMPDIR/ordinary-coordinator-return"
CONTRACT_REPO="$TMPDIR/capability-placement-contract"
HISTORICAL_REPO="$TMPDIR/capability-placement-historical"
mkdir -p "$GAP_REPO/docs" "$CLEAN_REPO/docs" "$OVERCLAIM_REPO/docs"
mkdir -p "$ORDINARY_REPO/docs" "$CONTRACT_REPO/docs"
mkdir -p "$HISTORICAL_REPO/docs/completions"

cat > "$GAP_REPO/docs/placement.md" <<'EOF'
# Autonomy Preview

Best current owner: TBD
Allowed reach now: maybe branch mutation later
Promotion gate: unknown

This capability-placement note omits several required placement fields.
EOF

cat > "$CLEAN_REPO/docs/placement.md" <<'EOF'
# Autonomy Preview

Best current owner: Codex foreground coordinator plus owner repo issue truth.
Best future owner: repo-auditor advisory detector after proof.
Allowed reach now: owner repo branch and PR mutation only.
Native signal: owner issue, PR check, merge, and detector fixture results.
Promotion gate: two follow-on PRs use the fields to change route.
Demotion/rejection trigger: fields become boilerplate or do not affect routing.
Kill switch: remove or shrink the detector through the owner PR.
Forbidden mode: No controller, scheduler, queue, daemon, registry, dashboard,
background Hermes/GBrain, automatic issue/PR creation, auto-merge, Codex
cloud/background write authority, downstream mutation, or replacement closure
truth.
GBrain slug/no-capture reason: no_capture_reason=memory did not change route.
EOF

cat > "$OVERCLAIM_REPO/docs/placement.md" <<'EOF'
# Capability Placement

A controller queue automatically creates pull requests and owns downstream
mutation.

Best current owner: the repository owner issue.
Best future owner: the same repository after repeated evidence.
Allowed reach now: advisory findings only.
Native signal: current owner issue and check truth.
Promotion gate: two owner-approved episodes.
Demotion/rejection trigger: any authority overclaim.
Kill switch: remove the integration through an owner PR.
Forbidden mode: no background agents or automatic merge.
GBrain slug/no-capture reason: no_capture_reason=no durable learning.
EOF

cat > "$ORDINARY_REPO/docs/return.md" <<'EOF'
# Coordinator Return

Outcome: the owner change passed focused tests.
Residual: the parent program remains open.
Next: resume the largest unclosed owner outcome.
Zoom-out: this advances one parent item and does not close the parent.
EOF

cat > "$CONTRACT_REPO/docs/capability-placement-contract.md" <<'EOF'
# Capability Placement Contract

This contract defines the CAPABILITY_PLACEMENT_PREVIEW fields for copy-sync or
citation. It is explanatory material, not a filled carrier preview.
EOF

cat > "$HISTORICAL_REPO/docs/completions/stale-placement.md" <<'EOF'
# Historical Autonomy Preview

Autonomy Preview without current placement fields.
EOF

python3 - "$REPO_ROOT" "$GAP_REPO" "$CLEAN_REPO" "$OVERCLAIM_REPO" "$ORDINARY_REPO" "$CONTRACT_REPO" "$HISTORICAL_REPO" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

(
    repo_root,
    gap_repo,
    clean_repo,
    overclaim_repo,
    ordinary_repo,
    contract_repo,
    historical_repo,
) = map(Path, sys.argv[1:])


def run(repo: Path) -> dict:
    completed = subprocess.run(
        ["bash", str(repo_root / "scripts/detect-as-capability-placement-gap.sh"), str(repo)],
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        raise SystemExit(completed.stderr or completed.stdout)
    return json.loads(completed.stdout)


gap = run(gap_repo)
assert gap["ds_id"] == "AS-43", gap
assert gap["fired"] is True, gap
assert gap["signals"]["missing_best_future_owner_count"] == 1, gap
assert gap["signals"]["missing_native_signal_count"] == 1, gap
assert gap["signals"]["missing_kill_switch_count"] == 1, gap
assert gap["signals"]["vague_field_count"] >= 1, gap

overclaim = run(overclaim_repo)
assert overclaim["fired"] is True, overclaim
assert overclaim["signals"]["forbidden_authority_overclaim_count"] == 1, overclaim

for repo in (clean_repo, ordinary_repo, contract_repo):
    payload = run(repo)
    assert payload["ds_id"] == "AS-43", payload
    assert payload["fired"] is False, payload
    assert payload["signals"]["capability_placement_gap_count"] == 0, payload

historical = run(historical_repo)
assert historical["fired"] is False, historical
assert historical["signals"]["historical_evidence_skipped_count"] == 1, historical
PY

echo "PASS: AS-43 capability placement scope covered"
