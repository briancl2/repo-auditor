#!/usr/bin/env bash
# Verify AS-49 detects scheduled readback owner proof gaps.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

GAP_REPO="$TMPDIR/scheduled-owner-proof-gap"
CLEAN_REPO="$TMPDIR/scheduled-owner-proof-clean"
EXPLAINER_REPO="$TMPDIR/scheduled-owner-proof-explainer"
NEUTRAL_REPO="$TMPDIR/scheduled-owner-proof-neutral"
mkdir -p "$GAP_REPO/docs" "$CLEAN_REPO/docs" "$EXPLAINER_REPO/docs" "$NEUTRAL_REPO/docs"

cat > "$GAP_REPO/docs/proof.md" <<'EOF'
# Scheduled Readback Owner Proof

SCHEDULED_READBACK_OWNER_PROOF
candidate_id: runtime_shadow_schedule_readback
schedule_source: Issue #164 Runtime Learning Shadow

workflow_dispatch counts as scheduled proof and can be admitted.
Capture raw private local logs for retention.
A scheduler queue creates GitHub issues automatically and auto-merges repairs.
EOF

cat > "$CLEAN_REPO/docs/proof.md" <<'EOF'
# Scheduled Readback Owner Proof

SCHEDULED_READBACK_OWNER_PROOF
owner_issue_url: https://github.com/briancl2/build-meta-analysis/issues/943
candidate_id: runtime_shadow_schedule_readback
schedule_source: .github/workflows/issue164-runtime-learning-shadow.yml cron 17 21 * * *
allowed_event: schedule
event_filter:
  accepted_scheduled_events: [schedule]
  workflow_dispatch_counts_as_scheduled: false
cadence:
  expected: daily
  stale_after_hours: 30
blocker_rule: No new completed successful event=schedule run outside admitted IDs within the cadence window.
promotion_gate: Owner PR proves read-only event=schedule evidence, cadence, blocker rule, and bounded non-claims.
demotion_trigger: workflow_dispatch counted as scheduled proof, private/raw capture, hidden scheduler/queue/daemon/controller/registry, automatic GitHub mutation, or auto-merge.
kill_switch: Stop promotion and record a GitHub-visible blocker with one exact next owner action.
github_truth: GitHub issue/PR/check/merge truth remains closure truth.
bounded_non_claims:
  - workflow_dispatch is context only and never scheduled proof
  - no private/raw capture
  - no scheduler, queue, daemon, controller, registry, retry loop, background GBrain, background Hermes, automatic GitHub mutation, or auto-merge
EOF

cat > "$EXPLAINER_REPO/docs/as49.md" <<'EOF'
# AS-49 Scheduled Readback Owner Proof Gap

AS-49 detects scheduled readback owner proof gaps.
EOF

cat > "$NEUTRAL_REPO/docs/notes.md" <<'EOF'
# Notes

No scheduled readback owner proof appears here.
EOF

python3 - "$REPO_ROOT" "$GAP_REPO" "$CLEAN_REPO" "$EXPLAINER_REPO" "$NEUTRAL_REPO" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

repo_root, gap_repo, clean_repo, explainer_repo, neutral_repo = map(Path, sys.argv[1:])


def run(repo: Path) -> dict:
    completed = subprocess.run(
        ["bash", str(repo_root / "scripts/detect-as-scheduled-readback-owner-proof-gap.sh"), str(repo)],
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        raise SystemExit(completed.stderr or completed.stdout)
    return json.loads(completed.stdout)


gap = run(gap_repo)
assert gap["ds_id"] == "AS-49", gap
assert gap["fired"] is True, gap
signals = gap["signals"]
assert signals["scheduled_readback_owner_proof_gap_count"] == 1, signals
assert signals["missing_owner_issue_count"] == 1, signals
assert signals["missing_allowed_event_count"] == 1, signals
assert signals["missing_cadence_count"] == 1, signals
assert signals["missing_blocker_rule_count"] == 1, signals
assert signals["missing_promotion_gate_count"] == 1, signals
assert signals["missing_demotion_trigger_count"] == 1, signals
assert signals["missing_kill_switch_count"] == 1, signals
assert signals["missing_bounded_non_claims_count"] == 1, signals
assert signals["workflow_dispatch_as_scheduled_proof_count"] == 1, signals
assert signals["private_raw_capture_count"] == 1, signals
assert signals["hidden_control_plane_count"] == 1, signals
assert signals["automatic_github_mutation_or_auto_merge_count"] == 1, signals

clean = run(clean_repo)
assert clean["ds_id"] == "AS-49", clean
assert clean["fired"] is False, clean
assert clean["signals"]["scheduled_readback_owner_proof_grounded_count"] == 1, clean

explainer = run(explainer_repo)
assert explainer["fired"] is False, explainer
assert explainer["signals"]["scheduled_readback_owner_proof_grounded_count"] == 1, explainer

neutral = run(neutral_repo)
assert neutral["fired"] is False, neutral
assert neutral["signals"]["scheduled_readback_owner_proof_gap_count"] == 0, neutral
PY

echo "PASS: AS-49 scheduled readback owner proof detector covered"
