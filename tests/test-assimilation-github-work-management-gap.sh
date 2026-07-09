#!/usr/bin/env bash
# Verify AS-59 detects ASSIMILATION_GITHUB_WORK_MANAGEMENT_V1 evidence gaps,
# forbidden closure/automation/mutation overclaims, and preserves
# permission_insufficient as an access/readback state when properly routed.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

GAP_REPO="$TMPDIR/assimilation-work-management-gap"
OVERCLAIM_REPO="$TMPDIR/assimilation-work-management-overclaim"
CLEAN_REPO="$TMPDIR/assimilation-work-management-clean"
PERMISSION_REPO="$TMPDIR/assimilation-work-management-permission"
NEUTRAL_REPO="$TMPDIR/assimilation-work-management-neutral"
CONTRACT_REPO="$TMPDIR/assimilation-work-management-contract"
HISTORICAL_REPO="$TMPDIR/assimilation-work-management-historical"
EXPLAINER_INDEX_REPO="$TMPDIR/assimilation-work-management-explainer-index"
mkdir -p "$GAP_REPO/docs" "$OVERCLAIM_REPO/docs" "$CLEAN_REPO/docs"
mkdir -p "$PERMISSION_REPO/docs" "$NEUTRAL_REPO/docs" "$CONTRACT_REPO/docs"
mkdir -p "$HISTORICAL_REPO/docs/completions"
mkdir -p "$EXPLAINER_INDEX_REPO"

cat > "$GAP_REPO/docs/assimilation.md" <<'EOF'
# Assimilation GitHub Work Management

ASSIMILATION_GITHUB_WORK_MANAGEMENT_V1
github_closure_reconciliation: TBD.
This assimilation readback is needed before the repo-star arc closes.
EOF

cat > "$OVERCLAIM_REPO/docs/assimilation.md" <<'EOF'
# Assimilation GitHub Work Management

ASSIMILATION_GITHUB_WORK_MANAGEMENT_V1
github_closure_reconciliation:
- github_pr_list_readback: gh pr list --state all captured for source issue.
- cross_pr_consistency_checked: true.
- closing_issue_references: checked through GitHub.
- issue_state_reconciliation: owner issue remains open until PR merge truth.
- closure_disposition: admit.
required_ci_and_reviewer_model:
- repo_native_gate: make check.
- required_checks: CI.
- required_reviewer_model: GitHub PR review threads.
- local_review_role: pre_check_only_not_cross_pr_authority.
- required_review_threshold: P2+.
- review_truth_source: GitHub PR review truth.
shared_fact_control:
- fact_name: CLI version pin.
- owning_source: config/tool-version.txt.
- consuming_artifacts: docs/a.md, docs/b.md.
- drift_check: tests/test-version-pin.sh.
- duplicate_copy_disposition: copy_sync_with_drift_gate.
autonomous_merge_eligibility_candidate:
- candidate_state: candidate.
- repo_native_gate_green: true.
- spec_id_or_spec_exempt_commit_discipline: followed.
- required_review_findings_resolved: true.
- merge_conflicts_resolved_and_verified: true.
- human_approval_role: product_directional_only_when_repo_policy_allows.
- autonomous_merge_authority: candidate_only.

Local review is GitHub closure truth for this owner issue.
autonomous_merge_authority: authorized
The controller scheduler queue registry dashboard retries in the background.
Automatic issue creation and automatic PR creation are enabled.
This authorizes downstream mutation in target repos.
permission_insufficient is a repo-quality gap and scored as deficient.
EOF

cat > "$CLEAN_REPO/docs/assimilation.md" <<'EOF'
# Assimilation GitHub Work Management Receipt

ASSIMILATION_GITHUB_WORK_MANAGEMENT_V1
permission_insufficient:
  status: false
  surface: none
  blocked_fields: []
  evidence: []
  owner_action: none
github_closure_reconciliation:
- github_pr_list_readback: gh pr list --state all captured for source issue.
- cross_pr_consistency_checked: true.
- superset_subset_disposition: no_overlap.
- open_review_threads: none.
- closing_issue_references: checked through GitHub.
- issue_state_reconciliation: owner issue remains open until PR merge truth.
- closure_disposition: admit.
required_ci_and_reviewer_model:
- repo_native_gate: make check.
- required_checks: CI.
- required_reviewer_model: GitHub PR review threads and review decision.
- local_review_role: pre_check_only_not_cross_pr_authority.
- required_review_threshold: P2+.
- review_truth_source: GitHub PR review truth.
shared_fact_control:
- fact_name: CLI version pin.
- owning_source: config/tool-version.txt.
- consuming_artifacts: docs/a.md, docs/b.md.
- drift_check: tests/test-version-pin.sh.
- duplicate_copy_disposition: copy_sync_with_drift_gate.
autonomous_merge_eligibility_candidate:
- candidate_state: candidate.
- repo_native_gate_green: true.
- spec_id_or_spec_exempt_commit_discipline: followed.
- required_review_findings_resolved: true.
- merge_conflicts_resolved_and_verified: true.
- human_approval_role: product_directional_only_when_repo_policy_allows.
- autonomous_merge_authority: candidate_only.
next_owner_action: repo-upgrade-advisor recommendation packaging.
bounded_non_claims:
- local review is a pre-check only and not closure truth.
- no controller, scheduler, queue, daemon, registry, dashboard, auto-merge,
  automatic issue creation, automatic PR creation, or downstream mutation.
EOF

cat > "$PERMISSION_REPO/docs/assimilation-permission.md" <<'EOF'
# Assimilation GitHub Work Management Permission Blocker

ASSIMILATION_GITHUB_WORK_MANAGEMENT_V1
permission_insufficient:
  status: true
  surface: prs checks reviews branch_ruleset parsed_closure
  blocked_fields:
    - github_closure_reconciliation
    - required_ci_and_reviewer_model
  evidence:
    - gh pr list returned permission denied
  owner_action: request/read access on the repo owner issue.
owner_routing:
  permission_insufficient_route: request/read access or record a GitHub-visible blocker.
next_owner_action: request GitHub PR/check/review readback access on the owner issue.
bounded_non_claims:
- permission_insufficient is an access/readback state, not a repo-quality gap.
- no repo deficiency is scored until GitHub evidence can be read.
EOF

cat > "$NEUTRAL_REPO/docs/notes.md" <<'EOF'
# Notes

Ordinary documentation without assimilation GitHub work-management material.
EOF

cat > "$CONTRACT_REPO/docs/assimilation-github-work-management-v1-contract.md" <<'EOF'
# Assimilation GitHub Work Management V1 Contract

This contract defines ASSIMILATION_GITHUB_WORK_MANAGEMENT_V1 and the fields
github_closure_reconciliation, required_ci_and_reviewer_model,
shared_fact_control, and autonomous_merge_eligibility_candidate.
EOF

cat > "$HISTORICAL_REPO/docs/completions/assimilation.md" <<'EOF'
# Historical assimilation note

ASSIMILATION_GITHUB_WORK_MANAGEMENT_V1 lacks shared_fact_control.
EOF

cat > "$EXPLAINER_INDEX_REPO/AGENTS.md" <<'EOF'
# AGENTS.md

## Key Conventions

- The Issue #164 assimilation GitHub work-management V1 contract lives in
  `docs/assimilation-github-work-management-v1-contract.md` and
  `templates/assimilation-github-work-management-v1.md`; consume it by
  copy-sync or citation only, not by runtime dependency, GitHub client, review
  bot, controller, scheduler, queue, daemon, registry, dashboard, automatic
  issue/PR loop, auto-merge path, retained closeout package, or downstream
  mutation. Repo-auditor AS-59 detector detects gaps and overclaims in
  receipt/material surfaces; this `AGENTS.md` convention is an index/explainer
  plus owner-boundary note, not a receipt. Generated AS-59 patch packs remain
  advisory until an owner PR applies or remediates them.
EOF

cat > "$EXPLAINER_INDEX_REPO/README.md" <<'EOF'
# Assimilation GitHub Work Management V1 Contract

The assimilation GitHub work-management V1 contract defines the shared
`ASSIMILATION_GITHUB_WORK_MANAGEMENT_V1` receipt for repo-star carriers.
Repo-auditor AS-59 detector detects gaps and overclaims in receipt/material
surfaces; this README section is an index/explainer surface, not a receipt.
GitHub issue/PR/check/review/merge truth remains authoritative.
EOF

python3 - "$REPO_ROOT" "$GAP_REPO" "$OVERCLAIM_REPO" "$CLEAN_REPO" "$PERMISSION_REPO" "$NEUTRAL_REPO" "$CONTRACT_REPO" "$HISTORICAL_REPO" "$EXPLAINER_INDEX_REPO" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

(
    repo_root,
    gap_repo,
    overclaim_repo,
    clean_repo,
    permission_repo,
    neutral_repo,
    contract_repo,
    historical_repo,
    explainer_index_repo,
) = map(Path, sys.argv[1:])


def run(repo: Path) -> dict:
    completed = subprocess.run(
        ["bash", str(repo_root / "scripts/detect-as-assimilation-github-work-management-gap.sh"), str(repo)],
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        raise SystemExit(completed.stderr or completed.stdout)
    return json.loads(completed.stdout)


gap = run(gap_repo)
assert gap["ds_id"] == "AS-59", gap
assert gap["fired"] is True, gap
assert gap["signals"]["assimilation_github_work_management_gap_count"] == 1, gap
assert gap["signals"]["missing_required_ci_and_reviewer_model_count"] == 1, gap
assert gap["signals"]["missing_shared_fact_control_count"] == 1, gap
assert gap["signals"]["missing_autonomous_merge_eligibility_candidate_count"] == 1, gap
assert gap["signals"]["vague_field_count"] >= 1, gap

overclaim = run(overclaim_repo)
assert overclaim["ds_id"] == "AS-59", overclaim
assert overclaim["fired"] is True, overclaim
assert overclaim["signals"]["local_review_closure_truth_overclaim_count"] == 1, overclaim
assert overclaim["signals"]["auto_merge_overclaim_count"] == 1, overclaim
assert overclaim["signals"]["control_plane_overclaim_count"] == 1, overclaim
assert overclaim["signals"]["automatic_github_overclaim_count"] == 1, overclaim
assert overclaim["signals"]["downstream_mutation_overclaim_count"] == 1, overclaim
assert overclaim["signals"]["permission_quality_failure_count"] == 1, overclaim

for repo in (clean_repo, neutral_repo, contract_repo, explainer_index_repo):
    payload = run(repo)
    assert payload["ds_id"] == "AS-59", payload
    assert payload["fired"] is False, payload
    assert payload["signals"]["assimilation_github_work_management_gap_count"] == 0, payload

explainer = run(explainer_index_repo)
assert explainer["signals"]["assimilation_github_work_management_grounded_count"] == 2, explainer

permission = run(permission_repo)
assert permission["ds_id"] == "AS-59", permission
assert permission["fired"] is False, permission
assert permission["signals"]["permission_insufficient_routed_count"] == 1, permission
assert permission["signals"]["assimilation_github_work_management_gap_count"] == 0, permission

historical = run(historical_repo)
assert historical["ds_id"] == "AS-59", historical
assert historical["fired"] is False, historical
assert historical["signals"]["historical_evidence_skipped_count"] == 1, historical
PY

echo "PASS: AS-59 assimilation GitHub work-management detector covered"
