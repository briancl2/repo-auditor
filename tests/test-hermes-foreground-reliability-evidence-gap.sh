#!/usr/bin/env bash
# Verify AS-44 detects missing Hermes foreground reliability evidence fields.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

GAP_REPO="$TMPDIR/hermes-reliability-gap"
GENERIC_FAILURE_GUIDANCE_REPO="$TMPDIR/hermes-reliability-generic-failure-guidance"
MISSING_CHECKER_DISPOSITION_REPO="$TMPDIR/hermes-reliability-missing-checker-disposition"
OVERCLAIM_REPO="$TMPDIR/hermes-reliability-overclaim"
HEADER_NONCLAIMS_REPO="$TMPDIR/hermes-reliability-header-nonclaims"
SCOPED_PUBLICATION_REPO="$TMPDIR/hermes-reliability-scoped-publication"
CLEAN_REPO="$TMPDIR/hermes-reliability-clean"
NEUTRAL_REPO="$TMPDIR/hermes-reliability-neutral"
CONTRACT_REPO="$TMPDIR/hermes-reliability-contract"
HISTORICAL_REPO="$TMPDIR/hermes-reliability-historical"
mkdir -p "$GAP_REPO/docs" "$GENERIC_FAILURE_GUIDANCE_REPO/docs"
mkdir -p "$MISSING_CHECKER_DISPOSITION_REPO/docs" "$OVERCLAIM_REPO/docs"
mkdir -p "$HEADER_NONCLAIMS_REPO/docs" "$SCOPED_PUBLICATION_REPO/docs"
mkdir -p "$CLEAN_REPO/docs" "$NEUTRAL_REPO/docs"
mkdir -p "$CONTRACT_REPO/docs" "$HISTORICAL_REPO/docs/completions"

cat > "$GAP_REPO/docs/hermes-reliability.md" <<'EOF'
# Hermes Foreground Reliability

Hermes eligibility: TBD.
Attempt role: doer.
Launcher receipt: missing.

Hermes owns validation and merges the PR after retrying checks as a background
Hermes worker. Promotion gate: maybe later.
EOF

cat > "$GENERIC_FAILURE_GUIDANCE_REPO/docs/hermes-generic-failure-guidance.md" <<'EOF'
# Hermes Foreground Reliability

Hermes eligibility: scoped implementation leaf with issue owner, expected diff,
and excluded campaign authority.
Attempt role: doer.
Launcher receipt: HERMES_FOREGROUND_RUN_RECEIPT at /tmp/run/receipt.json.
Failure guidance: see notes.
Coordinator review: Codex/BMA reviews the diff before commit.
Validation owner: Codex/BMA coordinator owns local gates and CI polling.
Publication scope: none; Hermes does not publish branches or open PRs.
Promotion gate: two clean owner-surface proofs reduce operator burden.
Demotion/rejection trigger: timeout, missing receipt, noisy output, or authority
overclaim.
Checker shadow disposition: not_run because this proof used doer mode only.
Bounded non-claims: Hermes remains foreground-only and does not validate, merge,
retry, schedule, queue, run as a daemon, act as a controller, create issues or
PRs automatically, own Campaign Sync, own recovery, mutate downstream repos, or
adopt `hermes -z`.
EOF

cat > "$MISSING_CHECKER_DISPOSITION_REPO/docs/hermes-checker.md" <<'EOF'
# Hermes Checker Shadow Reliability

Hermes eligibility: checker-shadow only under owner issue authority.
Attempt role: checker_shadow.
Launcher receipt: HERMES_FOREGROUND_RUN_RECEIPT at /tmp/checker/launch.json.
Failure guidance: not-needed reason = clean success with no fallback.
Coordinator review: Codex/BMA reviews any advisory output before adoption.
Validation owner: Codex/BMA coordinator owns local gates and CI polling.
Promotion gate: two clean no-edit checker shadows.
Demotion/rejection trigger: missing receipts, edits, or approval claims.
Publication scope: none; Hermes does not publish branches or open PRs.
Bounded non-claims: Hermes checker shadow stays foreground-only, does not edit,
approve, validate, merge, retry, publish branches, open PRs, or own recovery.
EOF

cat > "$OVERCLAIM_REPO/docs/hermes-overclaim.md" <<'EOF'
# Hermes Foreground Reliability

Hermes eligibility: scoped implementation leaf with issue owner, expected diff,
and excluded campaign authority.
Attempt role: checker_shadow.
Launcher receipt: HERMES_FOREGROUND_RUN_RECEIPT at /tmp/checker/launch.json.
Failure guidance: not-needed reason = clean success with no fallback.
Coordinator review: Codex/BMA reviewed any advisory output before adoption.
Validation owner: Codex/BMA coordinator owns local gates and CI polling.
Promotion gate: two clean no-edit checker shadows.
Demotion/rejection trigger: missing receipts, edits, or approval claims.
Checker shadow disposition: advisory receipt retained and rejected no findings.
Publication scope: none; Hermes does not publish branches or open PRs.
Bounded non-claims: Hermes remains foreground-only.
Hermes checker-shadow self-approval accepted the implementation and pushed the
branch, opened its PR. Hermes will run broad validation until CI is green.
Hermes publishes branches and opens PRs for the checker-shadow route.
Hermes retry loop fixes the PR until CI is green as a background Hermes
controller.
EOF

cat > "$HEADER_NONCLAIMS_REPO/docs/hermes-header-nonclaims.md" <<'EOF'
# Hermes Foreground Reliability

Hermes eligibility: scoped implementation leaf with issue owner, expected diff,
and excluded campaign authority.
Attempt role: doer.
Launcher receipt: HERMES_FOREGROUND_RUN_RECEIPT at /tmp/run/receipt.json.
Failure guidance: HERMES_FOREGROUND_FAILURE_GUIDANCE before Codex fallback or
clean-success reason.
Coordinator review: Codex/BMA reviews the diff before commit.
Validation owner: Codex/BMA coordinator owns local gates and CI polling.
Publication scope: none.
Promotion gate: two clean owner-surface proofs reduce operator burden.
Demotion/rejection trigger: timeout, missing receipt, noisy output, or authority
overclaim.
Checker shadow disposition: not_run because this proof used doer mode only.

## Bounded non-claims

Hermes does not validate, merge, retry, schedule, queue, run as a daemon, act as
a controller, create issues or PRs automatically, own Campaign Sync, own
recovery, mutate downstream repos, or adopt `hermes -z`.
EOF

cat > "$SCOPED_PUBLICATION_REPO/docs/hermes-scoped-publication.md" <<'EOF'
# Hermes Foreground Reliability

Hermes eligibility: scoped implementation leaf with issue owner, expected diff,
and excluded campaign authority.
Attempt role: doer.
Launcher receipt: HERMES_FOREGROUND_RUN_RECEIPT at /tmp/run/receipt.json.
Failure guidance: HERMES_FOREGROUND_FAILURE_GUIDANCE before Codex fallback or
clean-success reason.
Coordinator review: Codex/BMA reviews the diff before commit.
Validation owner: Codex/BMA coordinator owns local gates and CI polling.
Publication scope: branch-and-pr only when explicitly scoped as foreground work;
Hermes may open a PR only when explicitly scoped as foreground work.
Promotion gate: two clean owner-surface proofs reduce operator burden.
Demotion/rejection trigger: timeout, missing receipt, noisy output, or authority
overclaim.
Checker shadow disposition: not_run because this proof used doer mode only.
Bounded non-claims: publication scope does not authorize merge, Campaign Sync,
recovery, broad validation, autonomous retry, or background operation.
EOF

cat > "$CLEAN_REPO/docs/hermes-reliability.md" <<'EOF'
# Hermes Foreground Reliability

Hermes eligibility: scoped implementation leaf with issue owner, expected diff,
and excluded campaign authority.
Attempt role: doer.
Launcher receipt: HERMES_FOREGROUND_RUN_RECEIPT at /tmp/run/receipt.json.
Failure guidance: not-needed reason = clean success with validated final output.
Coordinator review: Codex/BMA reviewed and edited the diff before commit.
Validation owner: Codex/BMA coordinator ran local gates, CI polling, and recovery.
Promotion gate: two clean owner-surface proofs reduce operator burden.
Demotion/rejection trigger: timeout, missing receipt, noisy output, or authority
overclaim.
Checker shadow disposition: not_run because this proof used doer mode only.
Publication scope: none; Hermes does not publish branches or open PRs.
Bounded non-claims: Hermes remains foreground-only and does not validate, merge,
retry, schedule, queue, run as a daemon, act as a controller, create issues or
PRs automatically, own Campaign Sync, own recovery, mutate downstream repos, or
adopt `hermes -z`.
EOF

cat > "$NEUTRAL_REPO/docs/notes.md" <<'EOF'
# Notes

Ordinary repo notes without Hermes doer/checker reliability material.
EOF

cat > "$CONTRACT_REPO/docs/hermes-foreground-reliability-contract.md" <<'EOF'
# Hermes Foreground Reliability Contract

This detector should suppress the shared contract definition. It defines
Hermes eligibility, launcher receipt, failure guidance, validation owner, and
bounded non-claims as copy-sync/citation fields.
EOF

cat > "$HISTORICAL_REPO/docs/completions/stale-hermes.md" <<'EOF'
# Historical Hermes Foreground Reliability

Hermes foreground reliability record from an old completion package with
missing fields.
EOF

python3 - "$REPO_ROOT" "$GAP_REPO" "$GENERIC_FAILURE_GUIDANCE_REPO" "$MISSING_CHECKER_DISPOSITION_REPO" "$OVERCLAIM_REPO" "$HEADER_NONCLAIMS_REPO" "$SCOPED_PUBLICATION_REPO" "$CLEAN_REPO" "$NEUTRAL_REPO" "$CONTRACT_REPO" "$HISTORICAL_REPO" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

(
    repo_root,
    gap_repo,
    generic_failure_guidance_repo,
    missing_checker_disposition_repo,
    overclaim_repo,
    header_nonclaims_repo,
    scoped_publication_repo,
    clean_repo,
    neutral_repo,
    contract_repo,
    historical_repo,
) = map(Path, sys.argv[1:])


def run(repo: Path) -> dict:
    completed = subprocess.run(
        ["bash", str(repo_root / "scripts/detect-as-hermes-foreground-reliability-evidence-gap.sh"), str(repo)],
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        raise SystemExit(completed.stderr or completed.stdout)
    return json.loads(completed.stdout)


gap = run(gap_repo)
assert gap["ds_id"] == "AS-44", gap
assert gap["fired"] is True, gap
assert gap["signals"]["hermes_foreground_reliability_gap_count"] == 1, gap
assert gap["signals"]["missing_failure_guidance_count"] == 1, gap
assert gap["signals"]["missing_coordinator_review_count"] == 1, gap
assert gap["signals"]["missing_validation_owner_count"] == 1, gap
assert gap["signals"]["missing_publication_scope_count"] == 1, gap
assert gap["signals"]["missing_demotion_rejection_trigger_count"] == 1, gap
assert gap["signals"]["missing_checker_shadow_disposition_count"] == 1, gap
assert gap["signals"]["missing_bounded_non_claims_count"] == 1, gap
assert gap["signals"]["vague_field_count"] >= 1, gap
assert gap["signals"]["forbidden_hermes_authority_count"] == 1, gap

generic_failure_guidance = run(generic_failure_guidance_repo)
assert generic_failure_guidance["ds_id"] == "AS-44", generic_failure_guidance
assert generic_failure_guidance["fired"] is True, generic_failure_guidance
assert generic_failure_guidance["signals"]["hermes_foreground_reliability_gap_count"] == 1, generic_failure_guidance
assert generic_failure_guidance["signals"]["missing_failure_guidance_count"] == 1, generic_failure_guidance

missing_checker_disposition = run(missing_checker_disposition_repo)
assert missing_checker_disposition["ds_id"] == "AS-44", missing_checker_disposition
assert missing_checker_disposition["fired"] is True, missing_checker_disposition
assert missing_checker_disposition["signals"]["hermes_foreground_reliability_gap_count"] == 1, missing_checker_disposition
assert missing_checker_disposition["signals"]["missing_checker_shadow_disposition_count"] == 1, missing_checker_disposition
assert missing_checker_disposition["signals"]["missing_publication_scope_count"] == 0, missing_checker_disposition
assert missing_checker_disposition["signals"]["validation_owner_overclaim_count"] == 0, missing_checker_disposition
assert missing_checker_disposition["signals"]["publication_scope_overclaim_count"] == 0, missing_checker_disposition

explicit_overclaim = run(overclaim_repo)
assert explicit_overclaim["ds_id"] == "AS-44", explicit_overclaim
assert explicit_overclaim["fired"] is True, explicit_overclaim
assert explicit_overclaim["signals"]["hermes_foreground_reliability_gap_count"] == 1, explicit_overclaim
assert explicit_overclaim["signals"]["checker_shadow_authority_overclaim_count"] == 1, explicit_overclaim
assert explicit_overclaim["signals"]["publication_scope_overclaim_count"] == 1, explicit_overclaim
assert explicit_overclaim["signals"]["validation_owner_overclaim_count"] == 1, explicit_overclaim
assert explicit_overclaim["signals"]["autonomous_retry_overclaim_count"] == 1, explicit_overclaim
assert explicit_overclaim["signals"]["control_plane_overclaim_count"] == 1, explicit_overclaim

for repo in (header_nonclaims_repo, scoped_publication_repo, clean_repo, neutral_repo, contract_repo):
    payload = run(repo)
    assert payload["ds_id"] == "AS-44", payload
    assert payload["fired"] is False, payload
    assert payload["signals"]["hermes_foreground_reliability_gap_count"] == 0, payload

historical_payload = run(historical_repo)
assert historical_payload["ds_id"] == "AS-44", historical_payload
assert historical_payload["fired"] is False, historical_payload
assert historical_payload["signals"]["hermes_foreground_reliability_gap_count"] == 0, historical_payload
assert historical_payload["signals"]["historical_evidence_skipped_count"] == 1, historical_payload
PY

echo "PASS: AS-44 Hermes foreground reliability evidence detector covered"
