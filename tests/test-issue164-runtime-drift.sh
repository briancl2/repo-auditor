#!/usr/bin/env bash
# Verify AS-37 detects Issue #164 runtime launch drift without flagging clean or neutral surfaces.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

STALE_REPO="$TMPDIR/stale-issue164-runtime"
CLEAN_REPO="$TMPDIR/clean-issue164-runtime"
ACCEPTANCE_GAP_REPO="$TMPDIR/acceptance-runtime-gap"
ACCEPTANCE_CLEAN_REPO="$TMPDIR/acceptance-runtime-clean"
ACCEPTANCE_NA_REPO="$TMPDIR/acceptance-runtime-not-applicable"
NEUTRAL_REPO="$TMPDIR/neutral-contract"
ORDINARY_REPO="$TMPDIR/ordinary-runtime"
mkdir -p "$STALE_REPO/docs" "$CLEAN_REPO/docs" "$ACCEPTANCE_GAP_REPO/docs"
mkdir -p "$ACCEPTANCE_CLEAN_REPO/docs" "$ACCEPTANCE_NA_REPO/docs"
mkdir -p "$NEUTRAL_REPO/docs" "$ORDINARY_REPO/docs"

cat > "$STALE_REPO/docs/launch.md" <<'EOF'
# Issue #164 Runtime Launch

Issue #164 fresh coordinator launch: start the heartbeat before the child issue
and run root exist. After CI finishes, ask the operator to choose a category for
the next owner action. This note does not include the live truth check, Goal
state or Goal-null fallback, progress-ledger evidence, green-clean
merge-or-blocker discipline, or a concrete owner-surface action.
EOF

cat > "$CLEAN_REPO/docs/launch.md" <<'EOF'
# Issue #164 Runtime Launch

- Transfer mode: fresh coordinator thread.
- Live truth: re-checked with gh issue view, gh pr list, git status, and rev-parse before mutation.
- Goal state: active; Goal-null fallback is recorded if Codex Goal is unavailable.
- Run root: /tmp/issue164-clean-runtime-20260609T000000Z with progress-ledger.jsonl.
- Heartbeat: created only after the child issue and run root exist.
- CI polling: poll GitHub checks, then merge-or-blocker with green-clean PR/check/merge truth.
- Next_owner_action: first owner PR on repo-auditor with validation scope, fallback, and GitHub issue routing.
EOF

cat > "$ACCEPTANCE_GAP_REPO/docs/acceptance.md" <<'EOF'
# Coordinator Autonomy Acceptance

Acceptance verdict: accepted.

This report says the coordinator is accepted based on doctrine alone. It has no
GitHub issue/PR/check/merge truth, no raw runtime evidence, no Goal state or
Goal-null fallback, no /tmp run root, no progress-ledger.jsonl, no heartbeat
disposition, no bounded non-claims, and no concrete next owner action.
EOF

cat > "$ACCEPTANCE_CLEAN_REPO/docs/acceptance.md" <<'EOF'
# Coordinator Autonomy Acceptance

Acceptance verdict: partial.
GitHub issue/PR/check/merge truth: issue #855, PR #12, CI/check run 123, and merge commit abc123.
Raw runtime evidence: command transcript, runtime ledger, Goal metadata, and progress-ledger.jsonl.
Goal state: active; Goal-null fallback is recorded if unavailable.
Run root: /tmp/issue164-coordinator-acceptance-20260617T000000Z/progress-ledger.jsonl.
Heartbeat capture: created after the child issue and run root, then deleted at closure.
Bounded non-claims: this does not authorize background autonomy, automatic issue/PR creation, auto-merge, or remote execution.
Next_owner_action: repo-upgrade-advisor recommendation extension PR.
EOF

cat > "$ACCEPTANCE_NA_REPO/docs/acceptance.md" <<'EOF'
# Coordinator Autonomy Acceptance

Acceptance verdict: not_applicable.
This ordinary note records that no autonomy acceptance claim is being made.
EOF

cat > "$NEUTRAL_REPO/docs/repo-star-closure-runtime-distribution-contract.md" <<'EOF'
# Repo-Star Closure Runtime Distribution

This contract names closure-ceremony regrowth classes and runtime drift classes
for detector/advisor distribution. It is a shared explanatory contract, not a
runtime launch record.
EOF

cat > "$ORDINARY_REPO/docs/runtime.md" <<'EOF'
# Runtime Notes

The service has a heartbeat and a progress ledger. This ordinary runtime note
does not reference Issue #164 coordinator launch.
EOF

python3 - "$REPO_ROOT" "$STALE_REPO" "$CLEAN_REPO" "$ACCEPTANCE_GAP_REPO" "$ACCEPTANCE_CLEAN_REPO" "$ACCEPTANCE_NA_REPO" "$NEUTRAL_REPO" "$ORDINARY_REPO" <<'PY'
import json
import subprocess
import sys

repo_root, stale_repo, clean_repo, acceptance_gap_repo, acceptance_clean_repo, acceptance_na_repo, neutral_repo, ordinary_repo = sys.argv[1:9]

def run(repo):
    completed = subprocess.run(
        ["bash", f"{repo_root}/scripts/detect-as-issue164-runtime-drift.sh", repo],
        check=True,
        text=True,
        stdout=subprocess.PIPE,
    )
    return json.loads(completed.stdout)

stale = run(stale_repo)
assert stale["ds_id"] == "AS-37", stale
assert stale["fired"] is True, stale
assert stale["signals"]["issue164_runtime_drift_count"] == 1, stale
assert "live_truth" in stale["evidence"], stale
assert "goal_or_goal_null" in stale["evidence"], stale
assert "run_root_progress_ledger" in stale["evidence"], stale
assert "heartbeat_after_child_run_root" in stale["evidence"], stale
assert "concrete_next_action" in stale["evidence"], stale

acceptance_gap = run(acceptance_gap_repo)
assert acceptance_gap["ds_id"] == "AS-37", acceptance_gap
assert acceptance_gap["fired"] is True, acceptance_gap
assert acceptance_gap["signals"]["issue164_runtime_drift_count"] == 1, acceptance_gap
assert acceptance_gap["signals"]["missing_acceptance_github_truth_count"] == 1, acceptance_gap
assert acceptance_gap["signals"]["missing_acceptance_raw_runtime_evidence_count"] == 1, acceptance_gap
assert acceptance_gap["signals"]["missing_acceptance_heartbeat_disposition_count"] == 1, acceptance_gap
assert acceptance_gap["signals"]["missing_acceptance_bounded_non_claims_count"] == 1, acceptance_gap

for repo in (clean_repo, acceptance_clean_repo, acceptance_na_repo, neutral_repo, ordinary_repo):
    payload = run(repo)
    assert payload["ds_id"] == "AS-37", payload
    assert payload["fired"] is False, payload
    assert payload["signals"]["issue164_runtime_drift_count"] == 0, payload
PY

echo "Issue #164 runtime drift detector test passed."
