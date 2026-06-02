#!/usr/bin/env bash
# Verify bounded AS-20..AS-33 replay keeps direct closure and clean recovery runtime clean.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

CLEAN_REPO="$TMPDIR/direct-campaign-closure"
REGROWTH_REPO="$TMPDIR/retained-closeout-regrowth"
STALE_REPO="$TMPDIR/stale-fractured-recovery-runtime"
ACTIVE_DOC_REPO="$TMPDIR/context-active-doc"
HISTORICAL_WORK_REPO="$TMPDIR/context-historical-work"
DEBUG_LOG_REPO="$TMPDIR/context-debug-log"
CACHE_REPO="$TMPDIR/context-cache"
GENERATED_EVIDENCE_REPO="$TMPDIR/context-generated-evidence"
OUTPUT_DIR="$TMPDIR/replay-output"

mkdir -p \
    "$CLEAN_REPO/docs" \
    "$REGROWTH_REPO/docs" \
    "$STALE_REPO/docs" \
    "$ACTIVE_DOC_REPO/docs" \
    "$HISTORICAL_WORK_REPO/docs/history" \
    "$DEBUG_LOG_REPO/docs/debug-logs" \
    "$CACHE_REPO/docs/cache" \
    "$GENERATED_EVIDENCE_REPO"

init_git_fixture() {
    local repo="$1"
    git -C "$repo" init -q
    git -C "$repo" config user.email "test@example.com"
    git -C "$repo" config user.name "Replay Test"
}

commit_git_fixture() {
    local repo="$1"
    local msg="$2"
    git -C "$repo" add .
    git -C "$repo" commit -q -m "$msg"
}

init_git_fixture "$CLEAN_REPO"
init_git_fixture "$REGROWTH_REPO"
init_git_fixture "$STALE_REPO"
init_git_fixture "$ACTIVE_DOC_REPO"
init_git_fixture "$HISTORICAL_WORK_REPO"
init_git_fixture "$DEBUG_LOG_REPO"
init_git_fixture "$CACHE_REPO"
init_git_fixture "$GENERATED_EVIDENCE_REPO"
git -C "$ACTIVE_DOC_REPO" remote add origin "https://user:secret@example.com:bad/org/context-active-doc.git"

cat > "$CLEAN_REPO/docs/issue164-direct-closure.md" <<'EOF'
# Issue 164 Direct Campaign Closure

Issue #401 is closed by PR #402 and the pull request is merged. The task is a
qualifying Issue #164 campaign issue, so GitHub-native closeout is used and
local closeout is explicitly bypassed with a github-native-closeout rationale.
There is no local completion authority and no completion manifest is retained
for this direct campaign task.

The owner_surface is repo-auditor and the first deliverable is a focused
detector precision PR. This Goal-mode episode is a multi-PR core-five batch, not
tiny one-file work.

Command help may still mention both paths as long as the bypass is explicit:
make work opens ordinary work contracts, but it is not for Issue #164 direct
closure. Qualifying Issue #164 campaign work closes through GitHub issue/PR
truth instead of work-close.

```
schemas/
  HERMES_FOREGROUND_RUN_RECEIPT.schema.json
templates/
  v3.1-markdown-handoff.md
```
EOF

cat > "$CLEAN_REPO/docs/clean-foreground-recovery-runtime-contract.md" <<'EOF'
# Clean Foreground Recovery Runtime Contract Example

This safe example should not fire. Hermes foreground launcher guidance uses
`hermes chat -q -Q` only through the governed run-hermes-foreground.py wrapper
and retains HERMES_FOREGROUND_RUN_RECEIPT.schema.json evidence.

Interrupted Goal recovery and batch reconstitution record:
- original objective: deliver the core-five recovery-runtime replay harness.
- blocker class: failed foreground run from a route-changing foreground failure.
- goal state: paused before downstream mutation.
- replacement objective: first owner PR proves the bounded detector replay.
- first owner PR: repo-auditor PR #402 with GitHub issue truth for issue #401.
- intentional serial/parallel plan: serial owner repair first, parallel target
  validation only after merge.
- learning trigger: failed foreground run changed the owner-surface route.
- fallback: preserve read-only target validation if foreground is unavailable.
- validation: replay log and raw runtime evidence are retained.

Learning / Recovery is anchored by GitHub surface owner action, raw runtime
evidence from a goal receipt and replay log, optional GBrain slug
bma/issue164/recovery-runtime, and bounded non-claims: this does not prove
closure and does not authorize target mutation.

The foreground recovery runtime contract consumes
HERMES_FOREGROUND_FAILURE_GUIDANCE via --from-hermes-guidance for route-changing
foreground failures. GitHub issue/owner truth names GitHub issue #401 as issue
truth and owner surface repo-auditor owner action. Failed HERMES_FOREGROUND_RUN_RECEIPT
evidence includes status_code non-zero, stderr_tail, and exit code from the
failed run receipt. No-regrowth boundaries: do not add a controller, scheduler,
queue, daemon, retry loop, background watcher, or target-repo mutation; this is
not a runtime dependency and does not authorize downstream mutation.
EOF

commit_git_fixture "$CLEAN_REPO" "clean replay fixture"

cat > "$REGROWTH_REPO/docs/retained-local-closeout.md" <<'EOF'
# Retained Local Closeout Regrowth

Issue #401 is closed by PR #402 and the pull request is merged, but the local
completion manifest remains the authoritative closeout and work-close is still
required as the closure authority.
EOF

commit_git_fixture "$REGROWTH_REPO" "retained replay fixture"

cat > "$STALE_REPO/docs/stale-fractured-recovery-runtime.md" <<'EOF'
# Stale Fractured Recovery Runtime Examples

Hermes foreground launcher guidance tells operators to run `hermes chat -q -Q`
and validate-hermes-foreground-output.py directly. It does not cite the governed
foreground wrapper or run receipt contract.

Interrupted Goal recovery and batch reconstitution: Goal-mode work was blocked
by a tool runtime failure, but the record only says to keep going.

A blocker caused fractured serial continuation with ad hoc serial repair. The
team will continue one at a time as a single-PR continuation.

The system self-learned from the incident and claims self-healing improved the
workflow.

Hermes foreground recovery for a route-changing foreground failure is now
recommended, but the guidance omits the failure guidance environment contract,
owner issue truth, failed foreground run receipt evidence, and no-regrowth
boundaries.
EOF

commit_git_fixture "$STALE_REPO" "stale replay fixture"

cat > "$ACTIVE_DOC_REPO/docs/active-foreground-gap.md" <<'EOF'
# Active Foreground Gap

Operators should run `hermes chat -q -Q` directly for foreground work and then
use validate-hermes-foreground-output.py. This active documentation does not
name the governed foreground wrapper or run receipt contract.
EOF

commit_git_fixture "$ACTIVE_DOC_REPO" "active doc context fixture"

cat > "$HISTORICAL_WORK_REPO/docs/history/old-foreground-gap.md" <<'EOF'
# Historical Work Foreground Gap

An old work note said to run `hermes chat -q -Q` directly for foreground work
and then use validate-hermes-foreground-output.py. This historical record does
not name the governed foreground wrapper or run receipt contract.
EOF

commit_git_fixture "$HISTORICAL_WORK_REPO" "historical work context fixture"

cat > "$DEBUG_LOG_REPO/docs/debug-logs/foreground-gap-debug-log.txt" <<'EOF'
DEBUG transcript: operator ran `hermes chat -q -Q` directly for foreground work
and validate-hermes-foreground-output.py afterwards. The debug log does not name
the governed foreground wrapper or run receipt contract.
EOF

commit_git_fixture "$DEBUG_LOG_REPO" "debug log context fixture"

cat > "$CACHE_REPO/docs/cache/foreground-gap-cache.json" <<'EOF'
{
  "cached_note": "Operators should run `hermes chat -q -Q` directly for foreground work and then validate-hermes-foreground-output.py. This cache entry does not name the governed foreground wrapper or run receipt contract."
}
EOF

commit_git_fixture "$CACHE_REPO" "cache context fixture"

cat > "$GENERATED_EVIDENCE_REPO/SCORECARD.json" <<'EOF'
{
  "generated_evidence": "Operators should run `hermes chat -q -Q` directly for foreground work and then validate-hermes-foreground-output.py. This generated evidence does not name the governed foreground wrapper or run receipt contract."
}
EOF

commit_git_fixture "$GENERATED_EVIDENCE_REPO" "generated evidence context fixture"

python3 "$REPO_ROOT/scripts/replay-work-management-signatures.py" \
    --repo direct="$CLEAN_REPO" \
    --repo retained="$REGROWTH_REPO" \
    --repo stale="$STALE_REPO" \
    --repo active-doc="$ACTIVE_DOC_REPO" \
    --repo historical-work="$HISTORICAL_WORK_REPO" \
    --repo debug-log="$DEBUG_LOG_REPO" \
    --repo cache="$CACHE_REPO" \
    --repo generated-evidence="$GENERATED_EVIDENCE_REPO" \
    --output-dir "$OUTPUT_DIR" > "$TMPDIR/stdout.json"

python3 - "$OUTPUT_DIR/AS_WORK_MANAGEMENT_REPLAY.json" "$TMPDIR/stdout.json" <<'PY'
import json
import sys

from_file = json.load(open(sys.argv[1]))
from_stdout = json.load(open(sys.argv[2]))
assert from_file == from_stdout
assert from_file["signature_ids"] == [f"AS-{index}" for index in range(20, 34)]
assert from_file["target_count"] == 8
assert from_file["contract_reference"] == "repo-agent-core/docs/downstream-read-only-recovery-runtime-pilot-contract.md"
assert from_file["receipt_shape_reference"] == "DOWNSTREAM_READ_ONLY_RECOVERY_RUNTIME_PILOT_RECEIPT"
assert from_file["core_five_recovery_runtime_signature_ids"] == [f"AS-{index}" for index in range(29, 34)]

targets = {target["name"]: target for target in from_file["targets"]}
direct = targets["direct"]
retained = targets["retained"]
stale = targets["stale"]
active_doc = targets["active-doc"]
historical_work = targets["historical-work"]
debug_log = targets["debug-log"]
cache = targets["cache"]
generated_evidence = targets["generated-evidence"]

def result(target, ds_id):
    return next(item for item in target["results"] if item["ds_id"] == ds_id)

def assert_downstream_receipt(target):
    receipt = target["downstream_pilot_receipt"]
    assert receipt["artifact"] == "DOWNSTREAM_READ_ONLY_RECOVERY_RUNTIME_PILOT_RECEIPT", receipt
    assert receipt["schema_version"] == 1, receipt
    assert receipt["target_repo_identity"], receipt
    assert receipt["target_path_or_name"] == target["path"], receipt
    assert receipt["target_git_head_before"] == receipt["target_git_head_after"], receipt
    assert len(receipt["target_git_head_before"]) == 40, receipt
    assert receipt["target_dirty_count_before"] == receipt["target_dirty_count_after"] == 0, receipt
    assert receipt["auditor_as_replay_artifact_path"].endswith("AS_WORK_MANAGEMENT_REPLAY.json"), receipt
    assert receipt["advisor_artifact_path"] is None, receipt
    assert receipt["optimizer_replay_receipt_path"] is None, receipt
    assert receipt["generated_patch_pack_path"] is None, receipt
    assert receipt["patch_metadata_path"] is None, receipt
    assert receipt["blocker_path"] is None, receipt
    assert receipt["apply_check_result_path"] is None, receipt
    assert any("does not mutate the target repo" in claim for claim in receipt["bounded_non_claims"]), receipt
    assert any("does not apply patches" in claim for claim in receipt["bounded_non_claims"]), receipt
    assert target["target_repo_identity"] == receipt["target_repo_identity"], target
    assert target["target_path_or_name"] == receipt["target_path_or_name"], target
    assert target["target_git_head_before"] == receipt["target_git_head_before"], target
    assert target["target_git_head_after"] == receipt["target_git_head_after"], target
    assert target["target_dirty_count_before"] == receipt["target_dirty_count_before"], target
    assert target["target_dirty_count_after"] == receipt["target_dirty_count_after"], target
    assert target["auditor_as_replay_artifact_path"] == receipt["auditor_as_replay_artifact_path"], target
    assert target["bounded_non_claims"] == receipt["bounded_non_claims"], target

for target in targets.values():
    assert_downstream_receipt(target)
    for row in target["results"]:
        context = row.get("evidence_context")
        assert context, row
        assert context["primary_class"] in {
            "active_doc",
            "historical_work",
            "debug_log",
            "cache",
            "generated_evidence",
            "unknown",
        }, row
        assert context["is_suppressor"] is False, row

assert "user:secret" not in active_doc["target_repo_identity"], active_doc
assert "https://example.com:bad/org/context-active-doc.git" in active_doc["target_repo_identity"], active_doc

assert direct["closure_regrowth_fired"] is False, direct
assert "AS-22" not in direct["fired_ids"], direct
assert direct["github_native_closeout_bypassed_count"] >= 1, direct
for ds_id in [f"AS-{index}" for index in range(29, 34)]:
    assert ds_id not in direct["fired_ids"], (ds_id, result(direct, ds_id))

assert retained["closure_regrowth_fired"] is True, retained
assert "AS-22" in retained["fired_ids"], retained
assert retained["closure_regrowth_count"] == 1, retained

for ds_id in [f"AS-{index}" for index in range(29, 34)]:
    assert ds_id in stale["fired_ids"], (ds_id, result(stale, ds_id))
assert stale["core_five_recovery_runtime_fired_ids"] == [f"AS-{index}" for index in range(29, 34)], stale

context_cases = [
    (active_doc, "active_doc"),
    (historical_work, "historical_work"),
    (debug_log, "debug_log"),
    (cache, "cache"),
    (generated_evidence, "generated_evidence"),
]
for target, expected_class in context_cases:
    assert "AS-29" in target["fired_ids"], target
    row = result(target, "AS-29")
    context = row["evidence_context"]
    assert expected_class in context["classes"], (expected_class, row)
    assert context["primary_class"] == expected_class, (expected_class, row)
    assert context["is_suppressor"] is False, row
    assert context["summary"], row
    assert context["paths"], row

assert from_file["closure_regrowth_target_count"] == 1
assert from_file["error_target_count"] == 0
assert any("read-only" in claim for claim in from_file["bounded_non_claims"])
assert any("AS-20 through AS-33" in claim for claim in from_file["bounded_non_claims"])
PY

if python3 "$REPO_ROOT/scripts/replay-work-management-signatures.py" \
    --repo one="$CLEAN_REPO" \
    --repo two="$REGROWTH_REPO" \
    --max-targets 1 \
    --output-dir "$TMPDIR/over-limit" >/dev/null 2>&1; then
    echo "Expected over-limit replay to fail" >&2
    exit 1
fi

echo "=== test-work-management-replay.sh: PASS ==="
