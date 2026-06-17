#!/usr/bin/env bash
# Verify AS-43 detects incomplete or overreaching capability placement previews.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

GAP_REPO="$TMPDIR/capability-placement-gap"
CLEAN_REPO="$TMPDIR/capability-placement-clean"
ACCEPTANCE_GAP_REPO="$TMPDIR/acceptance-placement-gap"
ACCEPTANCE_INVALID_REPO="$TMPDIR/acceptance-placement-invalid"
ACCEPTANCE_CLEAN_REPO="$TMPDIR/acceptance-placement-clean"
ACCEPTANCE_NA_REPO="$TMPDIR/acceptance-placement-not-applicable"
NEUTRAL_REPO="$TMPDIR/capability-placement-neutral"
CONTRACT_REPO="$TMPDIR/capability-placement-contract"
HISTORICAL_REPO="$TMPDIR/capability-placement-historical"
mkdir -p "$GAP_REPO/docs" "$CLEAN_REPO/docs" "$NEUTRAL_REPO/docs"
mkdir -p "$ACCEPTANCE_GAP_REPO/docs" "$ACCEPTANCE_INVALID_REPO/docs"
mkdir -p "$ACCEPTANCE_CLEAN_REPO/docs" "$ACCEPTANCE_NA_REPO/docs"
mkdir -p "$CONTRACT_REPO/docs" "$HISTORICAL_REPO/docs/completions"

cat > "$GAP_REPO/docs/placement.md" <<'EOF'
# Autonomy Preview

Best current owner: TBD
Allowed reach now: maybe branch mutation later
Promotion gate: unknown

This capability-placement note says a controller queue and background Hermes own
future routing. It omits several required placement fields.
EOF

cat > "$CLEAN_REPO/docs/placement.md" <<'EOF'
# Autonomy Preview

Best current owner: Codex/BMA foreground coordinator plus owner repo issue truth.
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

cat > "$ACCEPTANCE_GAP_REPO/docs/acceptance.md" <<'EOF'
# Coordinator Autonomy Acceptance

Acceptance verdict: accepted.
Promotion gate: maybe later

The report says acceptance is granted from doctrine. It has no GitHub
issue/PR/check/merge truth, no raw runtime evidence, no Goal state or Goal-null
fallback, no /tmp run root, no progress-ledger.jsonl, no heartbeat disposition,
no bounded non-claims, no demotion trigger, and no next owner action.
Background autonomy through a controller queue owns future GitHub mutation.
EOF

cat > "$ACCEPTANCE_INVALID_REPO/docs/acceptance.md" <<'EOF'
# Coordinator Autonomy Acceptance

Acceptance verdict: green.
This note uses a non-enum verdict value.
EOF

cat > "$ACCEPTANCE_CLEAN_REPO/docs/acceptance.md" <<'EOF'
# Coordinator Autonomy Acceptance

Acceptance verdict: partial.
GitHub issue/PR/check/merge truth: issue #855, PR #12, CI/check run 123, and merge commit abc123.
Raw runtime evidence: command transcript, runtime ledger, Goal metadata, and progress-ledger.jsonl.
Goal state: active; Goal-null fallback is recorded if unavailable.
Run root: /tmp/issue164-coordinator-acceptance-20260617T000000Z/progress-ledger.jsonl.
Heartbeat disposition: heartbeat created after the child issue and run root, then deleted at closure.
Bounded non-claims: this does not authorize background autonomy, automatic issue/PR creation, auto-merge, or remote execution.
Demotion/rejection trigger: missing raw evidence, vague promotion gates, or background authority claims reject acceptance.
Next owner action: repo-upgrade-advisor recommendation extension PR.
EOF

cat > "$ACCEPTANCE_NA_REPO/docs/acceptance.md" <<'EOF'
# Coordinator Autonomy Acceptance

Acceptance verdict: not_applicable.
No coordinator autonomy acceptance claim is made on this ordinary PR.
EOF

cat > "$NEUTRAL_REPO/docs/notes.md" <<'EOF'
# Notes

Ordinary release notes.
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

python3 - "$REPO_ROOT" "$GAP_REPO" "$CLEAN_REPO" "$ACCEPTANCE_GAP_REPO" "$ACCEPTANCE_INVALID_REPO" "$ACCEPTANCE_CLEAN_REPO" "$ACCEPTANCE_NA_REPO" "$NEUTRAL_REPO" "$CONTRACT_REPO" "$HISTORICAL_REPO" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

(
    repo_root,
    gap_repo,
    clean_repo,
    acceptance_gap_repo,
    acceptance_invalid_repo,
    acceptance_clean_repo,
    acceptance_na_repo,
    neutral_repo,
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
assert gap["signals"]["capability_placement_gap_count"] == 1, gap
assert gap["signals"]["missing_best_future_owner_count"] == 1, gap
assert gap["signals"]["missing_native_signal_count"] == 1, gap
assert gap["signals"]["missing_demotion_rejection_trigger_count"] == 1, gap
assert gap["signals"]["missing_kill_switch_count"] == 1, gap
assert gap["signals"]["missing_forbidden_mode_count"] == 1, gap
assert gap["signals"]["missing_gbrain_slug_or_no_capture_reason_count"] == 1, gap
assert gap["signals"]["vague_field_count"] >= 1, gap
assert gap["signals"]["forbidden_authority_overclaim_count"] == 1, gap

acceptance_gap = run(acceptance_gap_repo)
assert acceptance_gap["ds_id"] == "AS-43", acceptance_gap
assert acceptance_gap["fired"] is True, acceptance_gap
assert acceptance_gap["signals"]["capability_placement_gap_count"] == 1, acceptance_gap
assert acceptance_gap["signals"]["missing_acceptance_github_truth_count"] == 1, acceptance_gap
assert acceptance_gap["signals"]["missing_acceptance_raw_runtime_evidence_count"] == 1, acceptance_gap
assert acceptance_gap["signals"]["missing_acceptance_goal_or_goal_null_count"] == 1, acceptance_gap
assert acceptance_gap["signals"]["missing_acceptance_run_root_progress_ledger_count"] == 1, acceptance_gap
assert acceptance_gap["signals"]["missing_acceptance_heartbeat_disposition_count"] == 1, acceptance_gap
assert acceptance_gap["signals"]["missing_acceptance_bounded_non_claims_count"] == 1, acceptance_gap
assert acceptance_gap["signals"]["missing_acceptance_demotion_trigger_count"] == 1, acceptance_gap
assert acceptance_gap["signals"]["missing_acceptance_next_owner_action_count"] == 1, acceptance_gap
assert acceptance_gap["signals"]["vague_field_count"] >= 1, acceptance_gap
assert acceptance_gap["signals"]["forbidden_authority_overclaim_count"] == 1, acceptance_gap

acceptance_invalid = run(acceptance_invalid_repo)
assert acceptance_invalid["ds_id"] == "AS-43", acceptance_invalid
assert acceptance_invalid["fired"] is True, acceptance_invalid
assert acceptance_invalid["signals"]["invalid_acceptance_verdict_count"] == 1, acceptance_invalid

for repo in (clean_repo, acceptance_clean_repo, acceptance_na_repo, neutral_repo, contract_repo):
    payload = run(repo)
    assert payload["ds_id"] == "AS-43", payload
    assert payload["fired"] is False, payload
    assert payload["signals"]["capability_placement_gap_count"] == 0, payload

historical_payload = run(historical_repo)
assert historical_payload["ds_id"] == "AS-43", historical_payload
assert historical_payload["fired"] is False, historical_payload
assert historical_payload["signals"]["capability_placement_gap_count"] == 0, historical_payload
assert historical_payload["signals"]["historical_evidence_skipped_count"] == 1, historical_payload
PY

echo "PASS: AS-43 capability placement detector covered"
