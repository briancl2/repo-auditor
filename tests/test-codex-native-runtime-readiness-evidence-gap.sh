#!/usr/bin/env bash
# Verify AS-45 detects missing Codex native runtime readiness evidence fields.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

GAP_REPO="$TMPDIR/codex-runtime-gap"
OVERCLAIM_REPO="$TMPDIR/codex-runtime-overclaim"
GOAL_OVERCLAIM_REPO="$TMPDIR/codex-runtime-goal-overclaim"
CLEAN_REPO="$TMPDIR/codex-runtime-clean"
NEUTRAL_REPO="$TMPDIR/codex-runtime-neutral"
CONTRACT_REPO="$TMPDIR/codex-runtime-contract"
HISTORICAL_REPO="$TMPDIR/codex-runtime-historical"
mkdir -p "$GAP_REPO/docs" "$OVERCLAIM_REPO/docs" "$GOAL_OVERCLAIM_REPO/docs"
mkdir -p "$CLEAN_REPO/docs" "$NEUTRAL_REPO/docs" "$CONTRACT_REPO/docs"
mkdir -p "$HISTORICAL_REPO/docs/completions"

cat > "$GAP_REPO/docs/codex-runtime.md" <<'EOF'
# Codex Native Runtime Readiness

transfer_mode: same-thread continuation.
Goal state: TBD.
runtime-context preflight: missing.
Promotion gate: maybe later.
EOF

cat > "$OVERCLAIM_REPO/docs/codex-runtime.md" <<'EOF'
# Codex Native Runtime Readiness

transfer_mode: fresh-thread.
Goal state: Goal-null fallback recorded.
Run root: /tmp/issue164-codex-native-runtime-arc3-carrier3 with
progress-ledger.jsonl.
runtime-context preflight: runtime-context payload validated by
issue164-native-preflight.py summary.
heartbeat lifecycle: created, active, captured, and deleted after closure.
local/worktree dogfood: local worktree branch, validation, PR, and merge.
cloud/remote disposition: capability context noted.
official Codex context: official Codex manual sections refreshed.
GitHub issue/PR/check/merge truth: issue, PR, CI / check, and merge commit.
CI polling terminal condition: foreground CI polling reached green-clean merge.
promotion gate: two clean owner-surface proofs.
demotion/rejection trigger: missing raw evidence or overclaiming cloud/remote.
kill switch: stop readiness claims and record a GitHub-visible blocker.
bounded non-claims: none.
next_owner_action: repo-upgrade-advisor recommendation propagation.

Official Codex docs prove live cloud execution and validate the remote pilot.
Codex Cloud remote execution ran as a live pilot.
A background subagent controller schedules a queue for future runtime placement.
automatic issue creation and auto-merge are enabled after the detector passes.
The retained closeout package is closure truth for this carrier.
This authorizes downstream mutation in repo-upgrade-advisor.
EOF

cat > "$GOAL_OVERCLAIM_REPO/docs/codex-runtime.md" <<'EOF'
# Codex Native Runtime Readiness

Goal mode improved runtime autonomy and operator steering for Codex native
runtime readiness.
EOF

cat > "$CLEAN_REPO/docs/codex-runtime.md" <<'EOF'
# Codex Native Runtime Readiness

transfer_mode: same-thread continuation.
Goal state: Goal-null fallback recorded from foreground command evidence.
Run root: /tmp/issue164-codex-native-runtime-arc3-carrier3 with
progress-ledger.jsonl.
runtime-context preflight: runtime-context payload validated by
issue164-native-preflight.py summary.
heartbeat lifecycle: created after the child issue and run root, inspected
during the run, and deleted after closure.
local/worktree dogfood: local worktree branch, validation, PR, and merge.
cloud/remote disposition: no live cloud or remote execution; official docs are
capability context only.
official Codex context: official Codex manual sections refreshed.
GitHub issue/PR/check/merge truth: issue, PR, CI / check, and merge commit.
CI polling terminal condition: foreground CI polling reached green-clean merge.
proof_gate: official docs context, local/worktree dogfood evidence, runtime
context preflight, heartbeat lifecycle, GitHub truth, and Campaign Sync.
demotion/rejection trigger: missing raw evidence, stale worktree, overclaiming
cloud/remote execution, or control-plane drift.
kill switch: stop readiness claims and record a GitHub-visible blocker.
bounded non-claims: no live cloud or remote execution, no runtime-improvement
claim without raw evidence, no controller, no scheduler, no queue, no daemon,
no registry, no automatic issue or PR creation, no auto-merge, no retained
closeout truth, and no downstream mutation.
next_owner_action: repo-upgrade-advisor recommendation propagation.
EOF

cat > "$NEUTRAL_REPO/docs/notes.md" <<'EOF'
# Notes

Ordinary repo notes without Codex runtime readiness material.
EOF

cat > "$CONTRACT_REPO/docs/codex-native-runtime-readiness-contract.md" <<'EOF'
# Codex Native Runtime Readiness Contract

This detector should suppress the shared contract definition. It defines
transfer mode, Goal-null state, runtime context preflight, heartbeat lifecycle,
local/worktree dogfood, and cloud/remote disposition fields.
EOF

cat > "$HISTORICAL_REPO/docs/completions/codex-runtime.md" <<'EOF'
# Historical Codex Native Runtime Readiness

This old closeout note is missing runtime context preflight and heartbeat
lifecycle fields.
EOF

python3 - "$REPO_ROOT" "$GAP_REPO" "$OVERCLAIM_REPO" "$GOAL_OVERCLAIM_REPO" "$CLEAN_REPO" "$NEUTRAL_REPO" "$CONTRACT_REPO" "$HISTORICAL_REPO" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

(
    repo_root,
    gap_repo,
    overclaim_repo,
    goal_overclaim_repo,
    clean_repo,
    neutral_repo,
    contract_repo,
    historical_repo,
) = map(Path, sys.argv[1:])


def run(repo: Path) -> dict:
    completed = subprocess.run(
        ["bash", str(repo_root / "scripts/detect-as-codex-native-runtime-readiness-evidence-gap.sh"), str(repo)],
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        raise SystemExit(completed.stderr or completed.stdout)
    return json.loads(completed.stdout)


gap = run(gap_repo)
assert gap["ds_id"] == "AS-45", gap
assert gap["fired"] is True, gap
assert gap["signals"]["codex_native_runtime_readiness_gap_count"] == 1, gap
assert gap["signals"]["missing_transfer_mode_count"] == 0, gap
assert gap["signals"]["missing_run_root_progress_ledger_count"] == 1, gap
assert gap["signals"]["missing_runtime_context_preflight_count"] == 0, gap
assert gap["signals"]["missing_heartbeat_lifecycle_count"] == 1, gap
assert gap["signals"]["missing_local_worktree_dogfood_count"] == 1, gap
assert gap["signals"]["missing_cloud_remote_disposition_count"] == 1, gap
assert gap["signals"]["missing_github_truth_count"] == 1, gap
assert gap["signals"]["missing_bounded_non_claims_count"] == 1, gap
assert gap["signals"]["vague_field_count"] >= 2, gap

overclaim = run(overclaim_repo)
assert overclaim["ds_id"] == "AS-45", overclaim
assert overclaim["fired"] is True, overclaim
assert overclaim["signals"]["codex_native_runtime_readiness_gap_count"] == 1, overclaim
assert overclaim["signals"]["official_docs_as_live_proof_count"] == 1, overclaim
assert overclaim["signals"]["live_cloud_remote_overclaim_count"] == 1, overclaim
assert overclaim["signals"]["control_plane_overclaim_count"] == 1, overclaim
assert overclaim["signals"]["automatic_github_overclaim_count"] == 1, overclaim
assert overclaim["signals"]["retained_closeout_overclaim_count"] == 1, overclaim
assert overclaim["signals"]["downstream_mutation_overclaim_count"] == 1, overclaim

goal_overclaim = run(goal_overclaim_repo)
assert goal_overclaim["ds_id"] == "AS-45", goal_overclaim
assert goal_overclaim["fired"] is True, goal_overclaim
assert goal_overclaim["signals"]["goal_improvement_without_raw_evidence_count"] == 1, goal_overclaim

for repo in (clean_repo, neutral_repo, contract_repo):
    payload = run(repo)
    assert payload["ds_id"] == "AS-45", payload
    assert payload["fired"] is False, payload
    assert payload["signals"]["codex_native_runtime_readiness_gap_count"] == 0, payload

historical = run(historical_repo)
assert historical["ds_id"] == "AS-45", historical
assert historical["fired"] is False, historical
assert historical["signals"]["historical_evidence_skipped_count"] == 1, historical
PY

echo "PASS: AS-45 Codex native runtime readiness evidence detector covered"
