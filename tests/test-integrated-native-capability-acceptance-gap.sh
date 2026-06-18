#!/usr/bin/env bash
# Verify AS-47 detects missing integrated native capability acceptance fields.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

GAP_REPO="$TMPDIR/integrated-acceptance-gap"
OVERCLAIM_REPO="$TMPDIR/integrated-acceptance-overclaim"
CLEAN_REPO="$TMPDIR/integrated-acceptance-clean"
NEUTRAL_REPO="$TMPDIR/integrated-acceptance-neutral"
CONTRACT_REPO="$TMPDIR/integrated-acceptance-contract"
HISTORICAL_REPO="$TMPDIR/integrated-acceptance-historical"
mkdir -p "$GAP_REPO/docs" "$OVERCLAIM_REPO/docs" "$CLEAN_REPO/docs"
mkdir -p "$NEUTRAL_REPO/docs" "$CONTRACT_REPO/docs" "$HISTORICAL_REPO/docs/completions"

cat > "$GAP_REPO/docs/integrated-acceptance.md" <<'EOF'
# Integrated Native Capability Acceptance

Integrated Native Capability Acceptance is planned for the campaign.
codex_cloud_proof_disposition: TBD.
promotion_gate: TBD.
EOF

cat > "$OVERCLAIM_REPO/docs/integrated-acceptance.md" <<'EOF'
# Integrated Native Capability Acceptance

INTEGRATED_NATIVE_CAPABILITY_ACCEPTANCE
codex_cloud_proof_disposition=accepted_ready_no_diff
task_id: task_e_6a34120847c4832b94a1a08423530556
hosted_repo: briancl2/build-meta-analysis
commit: 5d5bc96609e8b059b327c2309da7d07171c99f0c
git status before and after: clean
files_changed=0
codex_remote_proof_disposition=deferred_not_validated
external_intelligence_sidecar_disposition=failed_prompt_generation_deferred_outside_arc5
GitHub issue/PR/check/merge truth is recorded.
arc_gate_matrix: Arc 1, Arc 2, Arc 3, Arc 4, Arc 5.
promotion_gate: repeat only with raw task evidence.
demotion_rejection_trigger: reject stale proof.
kill_switch: stop and record a blocker.
acceptance limits omitted.
next_owner_action: repo-upgrade-advisor recommendation propagation.

Official docs prove live Codex Cloud acceptance and remote acceptance.
Codex remote proof is accepted and validated.
The sidecar pasteback is accepted and validated.
GBrain is canonical source of truth.
Hermes owns validation and merge.
The controller scheduler queue daemon registry retries in the background.
Automatic issue creation and auto-merge are enabled.
The retained closeout package is closure truth.
This authorizes downstream mutation.
EOF

cat > "$CLEAN_REPO/docs/integrated-acceptance.md" <<'EOF'
# Integrated Native Capability Acceptance

INTEGRATED_NATIVE_CAPABILITY_ACCEPTANCE
codex_cloud_proof_disposition=accepted_ready_no_diff
cloud_proof:
- task_id: task_e_6a34120847c4832b94a1a08423530556
- hosted_repo: briancl2/build-meta-analysis
- commit: 5d5bc96609e8b059b327c2309da7d07171c99f0c
- git status before and after: clean
- files_changed=0
- no diff
codex_remote_proof_disposition=deferred_not_validated
external_intelligence_sidecar_disposition=failed_prompt_generation_deferred_outside_arc5
GitHub issue/PR/check/merge truth is recorded.
arc_gate_matrix: Arc 1 advisory GBrain, Arc 2 bounded Hermes, Arc 3 Cloud
accepted and remote deferred, Arc 4 sidecar failed outside Arc 5, Arc 5
Cloud-backed propagation.
promotion_gate: repeat only with GitHub truth and raw task/session evidence.
demotion_rejection_trigger: docs-as-proof, false remote acceptance, sidecar
acceptance, controller drift, retained closeout truth, or downstream mutation.
kill_switch: stop propagation and record a GitHub-visible blocker.
bounded non-claims: no Codex remote acceptance, no sidecar acceptance, no live
Deep Research API, no official docs as proof, no GBrain canonicality, no Hermes
primary ownership, no controller, no scheduler, no queue, no daemon, no
registry, no automatic GitHub mutation, no auto-merge, no retained closeout
truth, and no downstream mutation.
next_owner_action: repo-upgrade-advisor recommendation propagation.
EOF

cat > "$NEUTRAL_REPO/docs/notes.md" <<'EOF'
# Notes

Ordinary notes without integrated native capability acceptance material.
EOF

cat > "$CONTRACT_REPO/docs/integrated-native-capability-acceptance-contract.md" <<'EOF'
# Integrated Native Capability Acceptance Contract

This shared contract defines INTEGRATED_NATIVE_CAPABILITY_ACCEPTANCE,
codex_cloud_proof_disposition=accepted_ready_no_diff,
codex_remote_proof_disposition=deferred_not_validated, and
external_intelligence_sidecar_disposition=failed_prompt_generation_deferred_outside_arc5.
EOF

cat > "$HISTORICAL_REPO/docs/completions/integrated-acceptance.md" <<'EOF'
# Historical integrated acceptance note

INTEGRATED_NATIVE_CAPABILITY_ACCEPTANCE lacks cloud proof.
EOF

python3 - "$REPO_ROOT" "$GAP_REPO" "$OVERCLAIM_REPO" "$CLEAN_REPO" "$NEUTRAL_REPO" "$CONTRACT_REPO" "$HISTORICAL_REPO" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

repo_root, gap_repo, overclaim_repo, clean_repo, neutral_repo, contract_repo, historical_repo = map(Path, sys.argv[1:])


def run(repo: Path) -> dict:
    completed = subprocess.run(
        ["bash", str(repo_root / "scripts/detect-as-integrated-native-capability-acceptance-gap.sh"), str(repo)],
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        raise SystemExit(completed.stderr or completed.stdout)
    return json.loads(completed.stdout)


gap = run(gap_repo)
assert gap["ds_id"] == "AS-47", gap
assert gap["fired"] is True, gap
assert gap["signals"]["integrated_native_capability_acceptance_gap_count"] == 1, gap
assert gap["signals"]["missing_integrated_acceptance_token_count"] == 1, gap
assert gap["signals"]["missing_cloud_proof_disposition_count"] == 1, gap
assert gap["signals"]["missing_cloud_task_evidence_count"] == 1, gap
assert gap["signals"]["missing_cloud_no_diff_evidence_count"] == 1, gap
assert gap["signals"]["missing_remote_deferred_disposition_count"] == 1, gap
assert gap["signals"]["missing_sidecar_failed_disposition_count"] == 1, gap
assert gap["signals"]["missing_github_truth_count"] == 1, gap
assert gap["signals"]["missing_arc_gate_matrix_count"] == 1, gap
assert gap["signals"]["missing_bounded_non_claims_count"] == 1, gap
assert gap["signals"]["vague_field_count"] >= 1, gap

overclaim = run(overclaim_repo)
assert overclaim["ds_id"] == "AS-47", overclaim
assert overclaim["fired"] is True, overclaim
assert overclaim["signals"]["docs_as_proof_overclaim_count"] == 1, overclaim
assert overclaim["signals"]["remote_acceptance_overclaim_count"] == 1, overclaim
assert overclaim["signals"]["sidecar_acceptance_overclaim_count"] == 1, overclaim
assert overclaim["signals"]["gbrain_canonicality_overclaim_count"] == 1, overclaim
assert overclaim["signals"]["hermes_primary_ownership_overclaim_count"] == 1, overclaim
assert overclaim["signals"]["control_plane_overclaim_count"] == 1, overclaim
assert overclaim["signals"]["automatic_github_overclaim_count"] == 1, overclaim
assert overclaim["signals"]["retained_closeout_overclaim_count"] == 1, overclaim
assert overclaim["signals"]["downstream_mutation_overclaim_count"] == 1, overclaim

for repo in (clean_repo, neutral_repo, contract_repo):
    payload = run(repo)
    assert payload["ds_id"] == "AS-47", payload
    assert payload["fired"] is False, payload
    assert payload["signals"]["integrated_native_capability_acceptance_gap_count"] == 0, payload

historical = run(historical_repo)
assert historical["ds_id"] == "AS-47", historical
assert historical["fired"] is False, historical
assert historical["signals"]["historical_evidence_skipped_count"] == 1, historical
PY

echo "PASS: AS-47 integrated native capability acceptance detector covered"
