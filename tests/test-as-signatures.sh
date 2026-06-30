#!/usr/bin/env bash
# test-as-signatures.sh — bounded smoke test for the AS-* signature family.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

TEST_REPO="$TMPDIR/as-fixture-repo"
mkdir -p "$TEST_REPO/.github/prompts" "$TEST_REPO/.github/workflows" "$TEST_REPO/docs" "$TEST_REPO/scripts" "$TEST_REPO/tests" "$TEST_REPO/.specify/memory"

cat > "$TEST_REPO/AGENTS.md" <<'EOF'
# AGENTS.md

AGENTS.md is the canonical instruction surface.

GBrain is canonical for repo-local instruction distribution and overrides repo
evidence. Use GBrain sync --watch to keep instruction surfaces fresh.

Issue #164 fresh coordinator launch should begin now, then ask the operator to
choose a category for the next owner action after CI. This omits the live-truth
check, Goal or Goal-null fallback, progress-ledger evidence, merge-or-blocker
discipline, and concrete owner-surface next action.

Codex Native Runtime Readiness: official Codex docs prove live cloud execution
and the remote pilot. This omits runtime-context preflight, lifecycle capture,
local/worktree dogfood, cloud/remote disposition, GitHub truth, bounded
non-claims, kill switch, and next owner action. Goal mode improved runtime
autonomy.
EOF

cat > "$TEST_REPO/README.md" <<'EOF'
# README

README.md is the canonical startup surface.
Current host: VS Code.
EOF

cat > "$TEST_REPO/LEARNINGS.md" <<'EOF'
# Learnings

This surface is query-only and not the live authority.
Archived source of truth for prior runs.
EOF

cat > "$TEST_REPO/.specify/memory/constitution.md" <<'EOF'
# Constitution

This principle set is non-negotiable.
EOF

cat > "$TEST_REPO/docs/invocation-contract.md" <<'EOF'
# Invocation Contract

Copilot CLI is supported here.
EOF

cat > "$TEST_REPO/.github/prompts/optimize.prompt.md" <<'EOF'
optimize token efficiency and reduce fan-out
EOF

cat > "$TEST_REPO/.github/workflows/ci.yml" <<'EOF'
name: ci
on: [push]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - run: echo test
EOF

cat > "$TEST_REPO/scripts/check.sh" <<'EOF'
#!/usr/bin/env bash
echo "check"
EOF
chmod +x "$TEST_REPO/scripts/check.sh"

cat > "$TEST_REPO/tests/test-something.sh" <<'EOF'
#!/usr/bin/env bash
echo "test"
EOF
chmod +x "$TEST_REPO/tests/test-something.sh"

cat > "$TEST_REPO/docs/critique.md" <<'EOF'
Responder truth mismatch: receipt-output mismatch and helper-only misclassification.
EOF

cat > "$TEST_REPO/scripts/helper.sh" <<'EOF'
#!/usr/bin/env bash
echo "helper only"
EOF
chmod +x "$TEST_REPO/scripts/helper.sh"

cat > "$TEST_REPO/docs/cost-evidence.md" <<'EOF'
# Cost Evidence

Estimated cost: $88.40 for the run.
request_count: 2400
tool_calls: 3600

API-equivalent pricing reference: $10 / 1M tokens.

review payload copied evidence:
> copied line 1
> copied line 2
> copied line 3
> copied line 4
> copied line 5
> copied line 6
> copied line 7
> copied line 8

Therefore this proves the run was cost efficient.
EOF

cat > "$TEST_REPO/docs/model-metrics.json" <<'EOF'
{
  "selected_model": "gpt-5.5",
  "current_model": "gpt-5.4",
  "modelMetrics": {
    "model": "gpt-5.4"
  }
}
EOF

cat > "$TEST_REPO/docs/enablement-boundary.md" <<'EOF'
# Enablement Boundary

production_default: true
enabled_by_default: true
approval_receipt: missing
authorized_by: none
"approval_receipt": null
EOF

cat > "$TEST_REPO/docs/rollback-gap.md" <<'EOF'
# Rollback Gap

Production rollout is enabled in production for the default route.
control proof: missing
rollback_receipt: missing
control_receipt: false
EOF

cat > "$TEST_REPO/docs/readiness.md" <<'EOF'
# Readiness

"production_readiness": "ready"
aggregate_pass_rate: 94%
aggregate_only: true
summary readiness is the only retained evidence.
per_case_receipts: missing
"per_case_receipts": null
EOF

cat > "$TEST_REPO/docs/direct-token-evidence.md" <<'EOF'
# Direct Token Evidence

generated_at: 2024-01-01
input_tokens: 100000
output_tokens: 20000
live_tokens: 120000
EOF

cat > "$TEST_REPO/docs/customer-newsletter-mutation.md" <<'EOF'
# CustomerNewsletter Mutation

Modified /Users/briancl/repos/CustomerNewsletter/content/index.md for production authoring.
Pushes /Users/briancl/repos/CustomerNewsletter/content/index.md to production.
EOF

cat > "$TEST_REPO/docs/source-intelligence-gap.md" <<'EOF'
# Source Intelligence Gap

This source bundle records source_id rows from operator supplied links and a
research-source-manifest, but it jumps directly to a recommendation without
recording equal first-pass treatment or any routed owner action.
EOF

cat > "$TEST_REPO/docs/bma-work-management-gaps.md" <<'EOF'
# BMA Work Management Gaps

The recommendation is category-only: hand back selection to the operator and
ask them to choose a category rather than naming an owner_surface,
github_issue_candidate, roadmap_disposition, or explicit_no_action reason.

The planning note recommends a Goal-mode episode for one tiny issue touching a
single file and expected to take 10 minutes; this is too small for Goal mode.

Issue #32 is closed and PR #99 is merged on GitHub, but the local completion
manifest remains the authoritative closeout and work-close is still required as
the closure authority. This regrows local closeout truth beside GitHub-native
issue/PR truth.

The repo-star fleet should handle the shared capability and pick an owner
later, so the destination and initial change are not specified.

Run repo-auditor against repo-optimizer as a validation target for the core
five, but do not state whether this proving-ground use is read-only or whether
mutation stays on the named owner repo.

Goal mode improved runtime health and reduced operator steering across the
episode, but no session log, Goal metadata, command transcript, CI run, or raw
runtime evidence is retained for that claim.

The Hermes provider failed, so the next repair should route to another
retrospective and selector update as the primary way to handle the blocker.

Hermes foreground wrapper:
timeout 900 hermes chat --provider copilot -m gpt-5.5 -q prompt -Q
status=$?
python3 scripts/validate-hermes-foreground-output.py --status-code "$status"

The recommendation says to adopt the upstream default capability as the new
default based on fork proof, PR-branch proof, and a remote-only branch check;
it has no upstream-main/local-proof reconciliation gate, source/local proof,
fallback path, or validation reconciliation record retained.

The Goal-mode arc was interrupted by an upstream blocker. Use the interruption
recovery and batch reconstitution contract, but only record the replacement
objective. Missing original objective, blocker class, Goal state, first owner PR,
intentional serial/parallel plan, learning trigger, fallback, and validation.

After that blocker, continue one at a time as unplanned serial repair work
without a planned replacement route or intentional plan.

The system self-learned and self-healed from this interruption, but no GitHub
owner action, raw evidence, GBrain slug, no-capture reason, or bounded
non-claims were recorded.

Hermes foreground recovery will self-heal route-changing failures and recover
after a failed foreground run, but this owner guidance does not require the
foreground failure guidance artifact, GitHub issue truth, failed run receipt
evidence, or no-regrowth boundaries.

An upstream capability intake record says component identity and local version
are known, source refs are stale, behindness is reduced to 0, capability
decisions adopt a native capability, update action is update now, validation is
missing, and owner routes, non-claims, and out-of-bounds surfaces are absent.

GBrain is canonical for repo-local instruction distribution and overrides repo
evidence. Use GBrain sync --watch to keep instruction surfaces fresh.

Issue #164 campaign sync cleared the active route with Next active track: None
selected. Codex found no current admissible owner-surface action remains after
gh issue list returned no open child issues or PRs.

Runtime Learning Shadow scheduled readback package: comments and artifacts are
closure truth for #798. This starts a scheduler that owns future readbacks.

SCHEDULED_READBACK_OWNER_PROOF candidate_id=runtime_shadow_schedule_readback
uses the Runtime Learning Shadow schedule file as its schedule source. The proof says
workflow_dispatch counts as scheduled proof and may be admitted. It captures raw
private local logs for retention, then a scheduler queue creates GitHub issues
automatically and auto-merges repairs.

Issue #164 Hermes/GitHub reliability note for a non-final child PR says it does
not close #798. HERMES_FOREGROUND_FAILURE_GUIDANCE records
provider_user_request_timeout with no fresh repro or failure residue
disposition. Hermes owns merge polling and retries the PR until green as a
background Hermes worker.

Final Campaign Sync admission checks next active track, micro-work rule, and
threshold clause, but the predicate omits completed-track readback coverage.
Campaign Sync:
- Completed track: #816 Hermes failure residue guidance
- Next active track: #798 Runtime Learning Shadow
- Micro-work rule: no standalone tiny output-cleanup issues.
- Threshold clause: adoption/delivery proof
Issue #164 readback:
Completed latest track: #811 stale completed track

ROUTE_CHANGING_LEARNING_FAILURE_RECEIPT route_changed=true. The route-changing
Learning / Recovery note says a broad GBrain search miss proves absence, omits
GitHub owner-surface evidence, raw evidence, fallback_without_memory, GBrain slug
or no_capture_reason, owner action, and literal-safe GitHub readback evidence,
then hands background GBrain to a controller queue.

Autonomy Preview for a high-priority capability-placement carrier:
Best current owner: TBD
Allowed reach now: maybe later
Promotion gate: unknown
A controller queue with background Hermes owns future routing.

Hermes foreground reliability record:
Hermes eligibility: TBD
Attempt role: doer
Launcher receipt: missing
Hermes owns validation and merges the PR after retrying checks as a background
Hermes worker. Promotion gate: maybe later.

HERMES_FOREGROUND_FAILURE_DISPOSITION:
classification: resolved_by_merged_repair
close_allowed: true
repair evidence: primary object PR #179 and /tmp/private-run-root
The scheduler queue will automatically close the failure issue and auto-merge the
next repair after a hidden retry loop.
EOF

cat > "$TEST_REPO/docs/integrated-native-acceptance-gap.md" <<'EOF'
# Integrated Native Capability Acceptance Gap

Integrated Native Capability Acceptance:
codex_cloud_proof_disposition: TBD.
Official docs prove the live remote acceptance. The sidecar pasteback is
accepted. GBrain is canonical and Hermes owns validation. A controller queue
auto-merges future repairs with retained closeout truth and downstream mutation.
EOF

cat > "$TEST_REPO/docs/standalone-sidecar-gap.md" <<'EOF'
# Standalone Sidecar Gap

BROAD_STANDALONE_SIDECAR_ACCEPTANCE
DEEP_RESEARCH_SOURCE_LEDGER_V2_ADOPTION
Prompt B for BMA should solve the architecture problem.
Definitions: TBD.
Read the GitHub issue and review this prompt.
Deep Research should research the sources without source rules.
The sidecar approves PRs and becomes closure truth.
A controller queue creates GitHub issues automatically and auto-merges repairs.
The local-aware critique is standalone sidecar proof.
Deep Research API ran live and authenticated-source capture is validated.
EOF

# Keep AS-33 covered after AS-47 uses a dedicated integrated-acceptance fixture.
cat > "$TEST_REPO/docs/foreground-failure-guidance-gap.md" <<'EOF'
# Foreground Failure Guidance Gap

Hermes foreground route-changing failure guidance cites the foreground recovery
runtime contract for a failed foreground run, but it omits GitHub issue owner
truth, failed run receipt evidence, and no-regrowth boundaries.
EOF

mkdir -p "$TEST_REPO/docs/deep-research-corpus"
cat > "$TEST_REPO/docs/deep-research-corpus/deep-research-native-corpus.md" <<'EOF'
# Deep Research/source-intelligence native corpus

DEEP_RESEARCH_SOURCE_INTELLIGENCE_NATIVE_CORPUS is planned for the approved
operator URLs. manual Deep Research sidecar: TBD. This omits
SOURCE_INSIGHT_PACKET, source count/corpus scope, public/no-auth then exact-url
authenticated access, claim/effect routing, evidence tier,
GitHub issue/PR/check/merge truth, and next owner action. Deep Research API ran
live and proved the corpus.
EOF

cat > "$TEST_REPO/docs/maturity-overclaim.md" <<'EOF'
# Capability status

This repo-agent is fully autonomous and production-ready. It is proven domain
capability and runs end-to-end autonomous from issue to PR merge.
EOF

cat > "$TEST_REPO/docs/closure-signal-integrity.md" <<'EOF'
# Closure signal integrity

work-close exits 0 for this owner-lane closeout.
post-audit unavailable: the post-audit/scorer leg is missing.
The retained SCORECARD.json is a PARTIAL scorecard, and score-session printed an
integer-expression error while grading the closeout.
EOF

cat > "$TEST_REPO/docs/review-ergonomics-working-memory.md" <<'EOF'
# Review ergonomics

CURRENT_STATE.md is oversized and creates working-memory overload during review.
The owner lane needed a review timeout override before the PR could be reviewed.
EOF

OUTPUT_DIR="$TMPDIR/output"
mkdir -p "$OUTPUT_DIR"

bash "$REPO_ROOT/scripts/detect-new-signatures.sh" "$TEST_REPO" "$OUTPUT_DIR" > "$TMPDIR/run.json"

python3 - "$TMPDIR/run.json" "$OUTPUT_DIR/DS-34-plus-results.json" <<'PY'
import json
import sys

stdout_report = json.load(open(sys.argv[1]))
output_report = json.load(open(sys.argv[2]))

assert stdout_report["repo"] == "as-fixture-repo"
assert stdout_report["capability_metadata"]["family_totals"]["AS"]["total"] == 55
assert output_report["capability_metadata"]["family_totals"]["AS"]["total"] == 55

as_ids = {item["ds_id"] for item in output_report["results"] if item.get("family") == "AS"}
assert as_ids == {
    "AS-01",
    "AS-02",
    "AS-03",
    "AS-04",
    "AS-05",
    "AS-06",
    "AS-07",
    "AS-08",
    "AS-09",
    "AS-10",
    "AS-11",
    "AS-12",
    "AS-13",
    "AS-14",
    "AS-15",
    "AS-16",
    "AS-17",
    "AS-18",
    "AS-19",
    "AS-20",
    "AS-21",
    "AS-22",
    "AS-23",
    "AS-24",
    "AS-25",
    "AS-26",
    "AS-27",
    "AS-28",
    "AS-29",
    "AS-30",
    "AS-31",
    "AS-32",
    "AS-33",
    "AS-34",
    "AS-35",
    "AS-36",
    "AS-37",
    "AS-38",
    "AS-39",
    "AS-40",
    "AS-41",
    "AS-42",
    "AS-43",
    "AS-44",
    "AS-45",
    "AS-46",
    "AS-47",
    "AS-48",
    "AS-49",
    "AS-50",
    "AS-51",
    "AS-52",
    "AS-53",
    "AS-54",
    "AS-55",
}

# This fixture is intentionally engineered to trip every AS detector once so the
# smoke test proves the full owner-surface family is wired and addressable.
fired = {item["ds_id"] for item in output_report["results"] if item.get("family") == "AS" and item.get("fired")}
assert fired == as_ids, {"missing": sorted(as_ids - fired), "unexpected": sorted(fired - as_ids)}
PY

GENERICITY_REPO="$TMPDIR/non-bma-genericity-fixture"
mkdir -p "$GENERICITY_REPO/.github/workflows" "$GENERICITY_REPO/scripts" "$GENERICITY_REPO/docs"
git -C "$GENERICITY_REPO" init -q
git -C "$GENERICITY_REPO" config user.name "Codex Test"
git -C "$GENERICITY_REPO" config user.email "codex@example.com"
cat > "$GENERICITY_REPO/README.md" <<'EOF'
# Generic Fixture

This is a controlled non-BMA target for repo-star genericity proof.
EOF
cat > "$GENERICITY_REPO/.github/workflows/ci.yml" <<'EOF'
name: ci
on:
  pull_request:
  push:
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - run: make check
        env:
          GITHUB_RUN_ID: ${{ github.run_id }}
          GITHUB_RUN_ATTEMPT: ${{ github.run_attempt }}
EOF
cat > "$GENERICITY_REPO/Makefile" <<'EOF'
check:
	@bash scripts/check.sh
EOF
cat > "$GENERICITY_REPO/scripts/check.sh" <<'EOF'
#!/usr/bin/env bash
closure_run_id="${CLOSURE_RUN_ID:-local-$(date +%s)}"
closure_phase="${CLOSURE_PHASE:-check}"
closure_trigger="${CLOSURE_TRIGGER:-manual}"
evidence_reuse_key="${EVIDENCE_REUSE_KEY:-check:generic-fixture}"
github_run_id="${GITHUB_RUN_ID:-local}"
github_run_attempt="${GITHUB_RUN_ATTEMPT:-0}"
parent_command="${PARENT_COMMAND:-make check}"
printf '%s\n' "$closure_run_id $closure_phase $closure_trigger $evidence_reuse_key $github_run_id $github_run_attempt $parent_command"
EOF
chmod +x "$GENERICITY_REPO/scripts/check.sh"
cat > "$GENERICITY_REPO/docs/notes.md" <<'EOF'
# Notes

This fixture intentionally avoids project-specific governance prose. It exists
only to prove that repo-auditor can classify generic detector metadata without
mutating the target repository.
EOF
git -C "$GENERICITY_REPO" add .
git -C "$GENERICITY_REPO" commit -qm "seed genericity fixture"
GENERICITY_HEAD_BEFORE="$(git -C "$GENERICITY_REPO" rev-parse HEAD)"
GENERICITY_STATUS_BEFORE="$(git -C "$GENERICITY_REPO" status --short)"
GENERICITY_OUTPUT="$TMPDIR/genericity-output"
mkdir -p "$GENERICITY_OUTPUT"
bash "$REPO_ROOT/scripts/detect-new-signatures.sh" "$GENERICITY_REPO" "$GENERICITY_OUTPUT" > "$TMPDIR/genericity-run.json"
GENERICITY_HEAD_AFTER="$(git -C "$GENERICITY_REPO" rev-parse HEAD)"
GENERICITY_STATUS_AFTER="$(git -C "$GENERICITY_REPO" status --short)"
python3 - "$GENERICITY_OUTPUT/DS-34-plus-results.json" "$GENERICITY_HEAD_BEFORE" "$GENERICITY_HEAD_AFTER" "$GENERICITY_STATUS_BEFORE" "$GENERICITY_STATUS_AFTER" <<'PY'
import json
import sys

report = json.load(open(sys.argv[1]))
head_before, head_after, status_before, status_after = sys.argv[2:6]
assert head_before == head_after, (head_before, head_after)
assert status_before == status_after == "", (status_before, status_after)

genericity = report["capability_metadata"]["repo_star_genericity"]
assert genericity["detector_scope"] == "classified", genericity
assert genericity["closure_signature_target_finding_count"] == 0, genericity
entries = {entry["ds_id"]: entry for entry in genericity["closure_signature_metadata"]}
for signature_id in ("AS-22", "AS-34"):
    entry = entries[signature_id]
    assert entry["scope"] == "generic_repo_health_detector", entry
    assert entry["target_finding_count"] == 0, entry
    assert entry["status"] == "closure_detector_metadata_allowed_when_zero_count", entry
    result = next(item for item in report["results"] if item.get("ds_id") == signature_id)
    assert result["repo_star_genericity_scope"] == entry, result
    assert result["fired"] is False, result
PY

GENERICITY_INCOMPLETE_TMP="$TMPDIR/genericity-incomplete-ds"
mkdir -p "$GENERICITY_INCOMPLETE_TMP"
cat > "$GENERICITY_INCOMPLETE_TMP/ds_0.json" <<'EOF'
{
  "ds_id": "AS-22",
  "name": "GitHub-native closure regrowth",
  "family": "AS",
  "fired": false,
  "signals": {
    "github_native_closure_regrowth_count": 0
  }
}
EOF
python3 "$REPO_ROOT/scripts/assemble_ds_results.py" "$GENERICITY_INCOMPLETE_TMP" "missing-as34" "$GENERICITY_REPO" > "$TMPDIR/genericity-incomplete.json"
python3 - "$TMPDIR/genericity-incomplete.json" <<'PY'
import json
import sys

report = json.load(open(sys.argv[1]))
genericity = report["capability_metadata"]["repo_star_genericity"]
assert genericity["detector_scope"] == "incomplete", genericity
assert genericity["closure_signature_scope_complete"] is False, genericity
assert genericity["missing_closure_signature_ids"] == ["AS-34"], genericity
assert genericity["incomplete_closure_signature_ids"] == [], genericity
assert genericity["closure_signature_target_finding_count"] is None, genericity
PY

GENERICITY_ERROR_TMP="$TMPDIR/genericity-error-ds"
mkdir -p "$GENERICITY_ERROR_TMP"
cat > "$GENERICITY_ERROR_TMP/ds_0.json" <<'EOF'
{
  "ds_id": "AS-22",
  "name": "GitHub-native closure regrowth",
  "family": "AS",
  "fired": false,
  "error": "script failed"
}
EOF
cat > "$GENERICITY_ERROR_TMP/ds_1.json" <<'EOF'
{
  "ds_id": "AS-34",
  "name": "Closure-run identity gap",
  "family": "AS",
  "fired": false,
  "signals": {
    "closure_run_identity_gap_count": 0
  }
}
EOF
python3 "$REPO_ROOT/scripts/assemble_ds_results.py" "$GENERICITY_ERROR_TMP" "errored-as22" "$GENERICITY_REPO" > "$TMPDIR/genericity-error.json"
python3 - "$TMPDIR/genericity-error.json" <<'PY'
import json
import sys

report = json.load(open(sys.argv[1]))
genericity = report["capability_metadata"]["repo_star_genericity"]
assert genericity["detector_scope"] == "incomplete", genericity
assert genericity["closure_signature_scope_complete"] is False, genericity
assert genericity["missing_closure_signature_ids"] == [], genericity
assert genericity["errored_closure_signature_ids"] == ["AS-22"], genericity
assert genericity["incomplete_closure_signature_ids"] == ["AS-22"], genericity
assert genericity["closure_signature_target_finding_count"] is None, genericity
entries = {entry["ds_id"]: entry for entry in genericity["closure_signature_metadata"]}
assert entries["AS-22"]["status"] == "detector_error", entries
PY

GENERICITY_SIGNAL_TMP="$TMPDIR/genericity-signal-ds"
mkdir -p "$GENERICITY_SIGNAL_TMP"
cat > "$GENERICITY_SIGNAL_TMP/ds_0.json" <<'EOF'
{
  "ds_id": "AS-22",
  "name": "GitHub-native closure regrowth",
  "family": "AS",
  "fired": false,
  "signals": {
    "github_native_closure_regrowth_count": 0
  }
}
EOF
cat > "$GENERICITY_SIGNAL_TMP/ds_1.json" <<'EOF'
{
  "ds_id": "AS-34",
  "name": "Closure-run identity gap",
  "family": "AS",
  "fired": false,
  "signals": {}
}
EOF
python3 "$REPO_ROOT/scripts/assemble_ds_results.py" "$GENERICITY_SIGNAL_TMP" "missing-as34-signal" "$GENERICITY_REPO" > "$TMPDIR/genericity-signal.json"
python3 - "$TMPDIR/genericity-signal.json" <<'PY'
import json
import sys

report = json.load(open(sys.argv[1]))
genericity = report["capability_metadata"]["repo_star_genericity"]
assert genericity["detector_scope"] == "incomplete", genericity
assert genericity["closure_signature_scope_complete"] is False, genericity
assert genericity["missing_closure_signature_ids"] == [], genericity
assert genericity["incomplete_closure_signature_ids"] == ["AS-34"], genericity
assert genericity["closure_signature_target_finding_count"] is None, genericity
entries = {entry["ds_id"]: entry for entry in genericity["closure_signature_metadata"]}
assert entries["AS-34"]["status"] == "detector_signal_missing", entries
PY

GENERICITY_FIRED_TMP="$TMPDIR/genericity-fired-ds"
mkdir -p "$GENERICITY_FIRED_TMP"
cat > "$GENERICITY_FIRED_TMP/ds_0.json" <<'EOF'
{
  "ds_id": "AS-22",
  "name": "GitHub-native closure regrowth",
  "family": "AS",
  "fired": true,
  "signals": {
    "github_native_closure_regrowth_count": 0
  }
}
EOF
cat > "$GENERICITY_FIRED_TMP/ds_1.json" <<'EOF'
{
  "ds_id": "AS-34",
  "name": "Closure-run identity gap",
  "family": "AS",
  "fired": false,
  "signals": {
    "closure_run_identity_gap_count": 0
  }
}
EOF
python3 "$REPO_ROOT/scripts/assemble_ds_results.py" "$GENERICITY_FIRED_TMP" "fired-as22" "$GENERICITY_REPO" > "$TMPDIR/genericity-fired.json"
python3 - "$TMPDIR/genericity-fired.json" <<'PY'
import json
import sys

report = json.load(open(sys.argv[1]))
genericity = report["capability_metadata"]["repo_star_genericity"]
assert genericity["detector_scope"] == "classified", genericity
assert genericity["closure_signature_scope_complete"] is True, genericity
assert genericity["closure_signature_target_finding_count"] == 1, genericity
entries = {entry["ds_id"]: entry for entry in genericity["closure_signature_metadata"]}
assert entries["AS-22"]["status"] == "target_finding", entries
PY

GENERICITY_RUNNER_COPY="$TMPDIR/genericity-runner-copy"
cp -R "$REPO_ROOT/scripts" "$GENERICITY_RUNNER_COPY"
cat > "$GENERICITY_RUNNER_COPY/detect-as-github-native-closure-regrowth.sh" <<'EOF'
#!/usr/bin/env bash
exit 9
EOF
chmod +x "$GENERICITY_RUNNER_COPY/detect-as-github-native-closure-regrowth.sh"
GENERICITY_RUNNER_FAIL_OUT="$TMPDIR/genericity-runner-fail-output"
mkdir -p "$GENERICITY_RUNNER_FAIL_OUT"
bash "$GENERICITY_RUNNER_COPY/detect-new-signatures.sh" "$GENERICITY_REPO" "$GENERICITY_RUNNER_FAIL_OUT" > "$TMPDIR/genericity-runner-fail.json"
python3 - "$GENERICITY_RUNNER_FAIL_OUT/DS-34-plus-results.json" <<'PY'
import json
import sys

report = json.load(open(sys.argv[1]))
genericity = report["capability_metadata"]["repo_star_genericity"]
assert genericity["detector_scope"] == "incomplete", genericity
assert genericity["closure_signature_scope_complete"] is False, genericity
assert genericity["missing_closure_signature_ids"] == [], genericity
assert genericity["errored_closure_signature_ids"] == ["AS-22"], genericity
assert genericity["incomplete_closure_signature_ids"] == ["AS-22"], genericity
entries = {entry["ds_id"]: entry for entry in genericity["closure_signature_metadata"]}
assert entries["AS-22"]["status"] == "detector_error", entries
assert entries["AS-22"]["target_finding_count"] is None, entries
PY

EXPLAINER_REPO="$TMPDIR/as-work-management-explainer-repo"
mkdir -p "$EXPLAINER_REPO/detection-signatures"
cat > "$EXPLAINER_REPO/detection-signatures/DS-43-plus.md" <<'EOF'
# Detection Signatures DS-43+

### AS-20: Selection Handback Recommendation
- **Detects:** Recommendation or planning surfaces that hand next-work selection back to the operator with category-only language.
- **Signal:** A recommendation says to choose a category, pick an adoption proof, work on repo-star, or do real delivery.
- **Fire condition:** `selection_handback_count > 0`
- **Script:** `scripts/detect-as-selection-handback-recommendation.sh`

### AS-21: Too-Small Goal-Mode Episode
- **Detects:** Codex Goal-mode recommendations for tiny, single-file, micro-work, or short cleanup tasks.
- **Signal:** A surface recommends Goal mode while also describing the work as one tiny issue.
- **Fire condition:** `too_small_goal_episode_count > 0`
- **Script:** `scripts/detect-as-too-small-goal-mode-episode.sh`

### AS-22: GitHub-Native Closure Regrowth
- **Detects:** GitHub issue/PR closure truth coexisting with local closeout authority.
- **Signal:** A surface says PR #99 is merged while also requiring a completion manifest, work-close, SER, or handoff.
- **Fire condition:** `github_native_closure_regrowth_count > 0`
- **Script:** `scripts/detect-as-github-native-closure-regrowth.sh`

### AS-30: Interrupted Goal Recovery Gap
- **Detects:** Goal-mode blocker recovery that omits batch-reconstitution fields.
- **Signal:** A surface names an interrupted Goal episode and blocker without original objective, blocker class, Goal state, replacement objective, first owner PR, intentional plan, learning trigger, fallback, or validation.
- **Fire condition:** `interrupted_goal_recovery_gap_count > 0`
- **Script:** `scripts/detect-as-interrupted-goal-recovery-gap.sh`

### AS-31: Fractured Serial Continuation
- **Detects:** Blocker recovery that collapses into unplanned serial continuation.
- **Signal:** A surface describes ad hoc serial work after a blocker with no replacement objective or intentional serial/parallel plan.
- **Fire condition:** `fractured_serial_continuation_count > 0`
- **Script:** `scripts/detect-as-fractured-serial-continuation.sh`

### AS-32: Unanchored Self-Learning Claim
- **Detects:** Self-learning or self-healing claims without GitHub owner action, raw evidence, GBrain slug, or explicit no-capture reason.
- **Signal:** A surface says the system self-learned but has no Learning / Recovery block.
- **Fire condition:** `unanchored_self_learning_claim_count > 0`
- **Script:** `scripts/detect-as-unanchored-self-learning-claim.sh`

### AS-33: Foreground Failure Guidance Gap
- **Detects:** Hermes foreground recovery or self-healing guidance that omits the failure-guidance consumption, GitHub issue truth, failed foreground run receipt evidence, or no-regrowth boundaries.
- **Signal:** A surface claims foreground recovery for route-changing failures without the full foreground recovery runtime contract.
- **Fire condition:** `foreground_failure_guidance_gap_count > 0`
- **Script:** `scripts/detect-as-foreground-failure-guidance-gap.sh`

### AS-34: Closure-Run Identity Gap
- **Detects:** Make, script, or GitHub Actions closure surfaces without comparable closure-run identity fields.
- **Signal:** Closure commands and workflows exist without `closure_run_id`, `evidence_reuse_key`, `github_run_id`, or `github_run_attempt`.
- **Fire condition:** `closure_run_identity_gap_count > 0`
- **Script:** `scripts/detect-as-closure-run-identity-gap.sh`

### AS-35: Upstream Capability Intake Gap
- **Detects:** Upstream capability intake records missing required fields, validation, source refs, owner routes, or non-claims.
- **Signal:** Incomplete intake evidence or update claims without validation.
- **Fire condition:** `upstream_intake_gap_count > 0`
- **Script:** `scripts/detect-as-upstream-capability-intake-gap.sh`

### AS-36: GBrain Instruction Distribution Overclaim
- **Detects:** GBrain instruction or exact-handle replay surfaces that overclaim canonical authority, enable background behavior, or omit advisory/source/exact-replay boundaries.
- **Signal:** Instruction guidance references GBrain distribution or exact-handle replay with canonical claims, background commands, missing advisory limits, missing source/citation expectations, missing fallback/no-capture evidence, missing no-canonical boundary, or missing no-background boundary.
- **Fire condition:** `gbrain_instruction_gap_count > 0`
- **Script:** `scripts/detect-as-gbrain-instruction-distribution-overclaim.sh`

### AS-37: Issue 164 Runtime Drift
- **Detects:** Issue #164 coordinator runtime launch surfaces that omit transfer mode, live truth, Goal or Goal-null fallback, run-root/progress-ledger evidence, heartbeat ordering, CI polling, merge-or-blocker discipline, concrete next action, or evidence-bearing coordinator autonomy acceptance fields.
- **Signal:** Issue #164 runtime guidance mentions coordinator launch or heartbeat but lacks required runtime fields; coordinator autonomy acceptance verdicts of accepted, partial, or rejected lack GitHub issue/PR/check/merge truth, raw runtime evidence, Goal state, run-root/progress-ledger evidence, heartbeat disposition, bounded non-claims, or concrete next owner action.
- **Fire condition:** `issue164_runtime_drift_count > 0`
- **Script:** `scripts/detect-as-issue164-runtime-drift.sh`

### AS-38: Self-Authored Campaign Pause Authority
- **Detects:** Campaign sync surfaces that set `Next active track: None selected` using no open issues, stale downstream references, or self-authored no-action proof.
- **Signal:** A campaign pause or stop disposition lacks operator-approved pause evidence or true campaign closure with no unresolved campaign families.
- **Fire condition:** `campaign_pause_authority_count > 0`
- **Script:** `scripts/detect-as-self-authored-campaign-pause-authority.sh`

### AS-39: Scheduled Workflow Evidence Boundary Gap
- **Detects:** Scheduled workflow evidence surfaces that miss schedule/run identity, review disposition, closure non-claims, or no-background boundaries.
- **Signal:** Runtime Learning Shadow scheduled readback material treats comments/artifacts as closure truth, lacks event/run fields, lacks review disposition, or regrows scheduler/controller wording.
- **Fire condition:** `scheduled_evidence_boundary_gap_count > 0`
- **Script:** `scripts/detect-as-scheduled-evidence-boundary-gap.sh`

### AS-45: Codex Native Runtime Readiness Evidence Gap
- **Detects:** Codex native runtime readiness surfaces that omit runtime
evidence fields or overclaim Codex Cloud, remote execution, or control-plane
authority.
- **Signal:** Missing transfer mode, Goal-null state, runtime-context preflight,
heartbeat lifecycle, local/worktree dogfood, cloud/remote disposition, GitHub
truth, bounded non-claims, or next owner action.
- **Fire condition:** `codex_native_runtime_readiness_gap_count > 0`
- **Script:** `scripts/detect-as-codex-native-runtime-readiness-evidence-gap.sh`

### AS-46: Deep Research Source-Intelligence Native Corpus Evidence Gap
- **Detects:** Deep Research/source-intelligence native corpus material that
omits portable corpus fields or overclaims live Deep Research API, Codex
Cloud/remote execution, crawler/registry authority, raw authenticated capture
retention, automatic GitHub mutation, retained closeout truth, or downstream
mutation.
- **Signal:** Missing `DEEP_RESEARCH_SOURCE_INTELLIGENCE_NATIVE_CORPUS`,
`SOURCE_INSIGHT_PACKET`, source count/corpus scope, source IDs, public/no-auth
then exact-url authenticated access, manual sidecar/API disposition,
equal-insight disposition, claim/effect routing, evidence tier, owner/no-action
routing, bounded non-claims, GitHub issue/PR/check/merge truth, or next owner
action.
- **Fire condition:** `deep_research_source_intelligence_native_corpus_gap_count > 0`
- **Script:** `scripts/detect-as-deep-research-source-intelligence-native-corpus-gap.sh`

### AS-48: Standalone External Intelligence Sidecar Gap
- **Detects:** Sidecar prompt material that is not standalone for external
intelligence, depends on local/private/GitHub context, omits embedded context
or definitions, confuses prompt layers, omits Prompt A/B or Deep Research mode
requirements, omits source-ledger v2 fields, claims broad sidecar acceptance
without proxy/red-team/critique/manual transport proof, or overclaims sidecar
authority.
- **Signal:** Missing `STANDALONE_EXTERNAL_INTELLIGENCE_SIDECAR`, local/private
or GitHub dependency, missing embedded context, Prompt B without actual Prompt A
output, Deep Research without source rules/source-ledger output, prompt-review
confusion, missing `consulted_on_date`/`exclusion_rationale`/
`recommendation_effect`, missing broad acceptance proof, or sidecar authority,
Deep Research API, authenticated capture, source-registry/crawler,
local-aware-as-standalone-proof, or control-plane claims.
- **Fire condition:** `standalone_external_intelligence_sidecar_gap_count > 0`
- **Script:** `scripts/detect-as-standalone-external-intelligence-sidecar-gap.sh`

### AS-49: Scheduled Readback Owner Proof Gap
- **Detects:** Scheduled-readback owner proof material that counts
`workflow_dispatch` as scheduled proof, omits owner/cadence/event/blocker
fields, retains private/raw capture, or regrows hidden scheduler/queue/daemon/
controller/registry, automatic GitHub mutation, or auto-merge authority.
- **Signal:** Missing `SCHEDULED_READBACK_OWNER_PROOF` owner issue, candidate
id, schedule source, allowed event, cadence, blocker rule, promotion gate,
demotion trigger, kill switch, bounded non-claims, or overclaimed scheduler and
GitHub mutation authority.
- **Fire condition:** `scheduled_readback_owner_proof_gap_count > 0`
- **Script:** `scripts/detect-as-scheduled-readback-owner-proof-gap.sh`

### AS-50: Hermes Foreground Failure Disposition Gap
- **Detects:** Hermes foreground failure disposition material that omits failure
identity fields, closes from ambiguous or private-only evidence, mismatches
provider-policy supersession, or regrows retry/control-plane behavior.
- **Signal:** Missing `HERMES_FOREGROUND_FAILURE_DISPOSITION` fields, missing
merged related repair PR evidence, primary-object-only repair evidence,
ambiguous repair candidates, provider-policy mismatch, raw/private evidence,
hidden scheduler/controller behavior, auto-close, or auto-merge.
- **Fire condition:** `hermes_failure_disposition_gap_count > 0`
- **Script:** `scripts/detect-as-hermes-foreground-failure-disposition-gap.sh`
EOF
cat > "$EXPLAINER_REPO/detection-signatures/recommendation-templates-F14-F28.md" <<'EOF'
# Recommendation Templates

**Triggers:** AS-20 fires (selection handback / category-only recommendation).
The template must tell the agent not to hand selection back to the operator.

**Triggers:** AS-21 fires when Goal mode is proposed for a tiny cleanup.
The template recommends a larger batch, not micro-work.

**Triggers:** AS-22 fires when GitHub-native closure coexists with local closeout.
The template says issue/PR truth should replace work-close authority.

**Triggers:** AS-23 fires when owner-surface ambiguity leaves repo-star work
without a named owner repo or first deliverable.

**Triggers:** AS-24 fires when reciprocal proving-ground validation lacks the
read-only owner-mutation boundary.

**Triggers:** AS-25 fires when a Goal-mode runtime improvement claim lacks raw
runtime evidence such as session logs, Goal metadata, command transcripts, or
CI runs.

**Triggers:** AS-26 fires when a known failure routes to retrospective or
selector work instead of direct owner-surface repair or GitHub issue truth.

**Triggers:** AS-27 fires when a Hermes/zsh launch snippet uses status=$?.
The template says to use hermes_status=$? instead.

**Triggers:** AS-28 fires when stale/default capability guidance adopts an
upstream default using fork proof, PR-branch proof, or remote-only proof without
upstream-main/local-proof reconciliation gates.

**Triggers:** AS-29 fires when Hermes foreground launcher guidance mentions
`hermes chat -q -Q` or validate-hermes-foreground-output.py but omits the
foreground run receipt contract and wrapper.

**Triggers:** AS-30 fires when interrupted Goal recovery docs omit the batch
reconstitution fields.

**Triggers:** AS-31 fires when blocker recovery collapses into fractured serial
continuation.

**Triggers:** AS-32 fires when self-learning claims are unanchored from GitHub
owner action, raw evidence, GBrain slug, or no-capture reason.

**Triggers:** AS-33 fires when Hermes foreground recovery/self-healing guidance
omits HERMES_FOREGROUND_FAILURE_GUIDANCE consumption, GitHub issue/owner truth,
failed HERMES_FOREGROUND_RUN_RECEIPT evidence, or no-regrowth boundaries.

**Triggers:** AS-34 fires when closure commands or GitHub Actions checks exist
without closure_run_id, evidence_reuse_key, github_run_id, or github_run_attempt
fields that let local and remote validation runs be correlated.

**Triggers:** AS-36 fires when GBrain instruction distribution or exact-handle
replay guidance overclaims canonical authority, enables background GBrain
behavior, omits the advisory boundary, omits source/citation expectations,
omits fallback/no-capture evidence, omits a no-canonical boundary, or omits a
no-background boundary.

**Triggers:** AS-37 fires when Issue #164 runtime launch guidance omits transfer
mode, live truth, Goal or Goal-null fallback, run-root/progress-ledger evidence,
heartbeat-after-child/run-root ordering, CI polling, merge-or-blocker discipline,
or concrete owner-surface next action, or when an accepted/partial/rejected
coordinator autonomy acceptance verdict lacks GitHub issue/PR/check/merge truth,
raw runtime evidence, Goal state, run-root/progress-ledger evidence, heartbeat
disposition, bounded non-claims, or concrete next owner action.

**Triggers:** AS-38 fires when a campaign sync says Next active track: None
selected or pauses the campaign based only on no open issues or PRs, stale
downstream references, or an agent-authored no-action assertion instead of an
operator-approved pause or true campaign closure.

**Triggers:** AS-39 fires when scheduled Runtime Learning Shadow readback
material treats comments/artifacts as closure truth, lacks schedule/run identity
or review disposition, or claims background scheduler/controller ownership.

**Triggers:** AS-41 fires when final Campaign Sync or validator surfaces have
completed-track drift, miss completed-track readback, or keep next-track,
micro-work, and threshold predicate coverage without completed-track coverage.

**Triggers:** AS-42 fires when route-changing learning/failure material misses
GitHub/raw evidence, GBrain slug or no-capture reason, exact readback or
no-capture discipline, fallback without memory, owner action, literal-safe
GitHub readback, treats broad GBrain search miss as absence without exact-handle
replay, overclaims stale/contradictory/failed GBrain evidence, or claims
background GBrain/Hermes/controller behavior.

**Triggers:** AS-43 fires when capability-placement / Autonomy Preview material
omits owner, reach, native signal, promotion, demotion, kill-switch, forbidden
mode, or GBrain no-capture fields, keeps fields vague, or claims forbidden
automation authority; or when coordinator autonomy acceptance material omits a
valid accepted/partial/rejected/not_applicable verdict, lacks evidence-bearing
fields for a non-not_applicable verdict, keeps gates vague, or claims background
autonomy, Hermes-primary ownership, canonical GBrain memory, remote execution,
automatic GitHub mutation, or other forbidden control-plane ownership.

**Triggers:** AS-44 fires when Hermes foreground reliability material omits
eligibility, attempt role, launcher/run receipt, pre-fallback failure guidance,
coordinator review, validation owner, publication scope, promotion/demotion,
checker disposition, or bounded non-claims; or when it makes Hermes validation
owner, grants checker-shadow approval/edit ownership, publishes branches/PRs
without scoped authority, claims autonomous retry/fix-cycle behavior, or grants
Hermes forbidden foreground/control-plane authority.

**Triggers:** AS-45 fires when Codex native runtime readiness material omits
transfer mode, Goal/Goal-null state, run root/progress-ledger, runtime-context
preflight, heartbeat lifecycle, local/worktree dogfood, cloud/remote
disposition, official Codex context, GitHub truth, CI polling terminal
condition, promotion/demotion/kill-switch fields, bounded non-claims, or next
owner action; or when it overclaims official docs as live cloud/remote proof,
claims live cloud/remote execution, claims Goal-mode runtime improvement without
raw evidence, or grants control-plane, automatic GitHub mutation, retained
closeout, or downstream mutation authority.

**Triggers:** AS-46 fires when Deep Research/source-intelligence native corpus
material omits the native corpus token, SOURCE_INSIGHT_PACKET, source
count/corpus scope, source IDs, public/no-auth then exact-url authenticated
access order, manual sidecar/API disposition, equal-insight disposition,
claim/effect routing, evidence tier, owner/no-action routing, bounded
non-claims, GitHub issue/PR/check/merge truth, or next owner action; or when it
overclaims live Deep Research API use, live Codex Cloud/remote proof,
crawler/registry/watcher/control-plane authority, raw authenticated capture
retention, automatic GitHub mutation, retained closeout truth, or downstream
mutation.

**Triggers:** AS-48 fires when sidecar prompt material is not standalone for an
external model, depends on local/private/GitHub context, omits embedded context
or definitions, confuses prompt layers, creates Prompt B without actual Prompt A
output and answered context, uses Deep Research without research targets/source
rules/source-ledger output, omits source-ledger v2 fields, claims broad
sidecar acceptance without proxy/red-team/critique/manual transport proof, or
treats sidecar output, local-aware critique, Deep Research API use,
authenticated-source capture, source registries, crawlers, or automatic GitHub
mutation as accepted authority.

**Triggers:** AS-49 fires when scheduled-readback owner proof material counts
workflow_dispatch as scheduled proof, omits owner/cadence/event/blocker fields,
retains private/raw capture, or regrows hidden scheduler/queue/daemon/controller/
registry, automatic GitHub mutation, or auto-merge authority.

**Triggers:** AS-50 fires when Hermes foreground failure disposition material
allows closure without merged repair PR evidence, relies on ambiguous
primary-object or private-only evidence, mismatches provider-policy evidence, or
regrows hidden retry/scheduler/controller, auto-close, or auto-merge behavior.
EOF

LIVE_WORK_MANAGEMENT_REPO="$TMPDIR/as-work-management-live-repo"
mkdir -p "$LIVE_WORK_MANAGEMENT_REPO/docs" "$LIVE_WORK_MANAGEMENT_REPO/.github/workflows" "$LIVE_WORK_MANAGEMENT_REPO/scripts"
cat > "$LIVE_WORK_MANAGEMENT_REPO/AGENTS.md" <<'EOF'
# AGENTS

GBrain is canonical for repo-local instruction distribution and overrides repo
evidence. Use GBrain sync --watch to keep instruction surfaces fresh.

Issue #164 fresh coordinator runtime: pick an adoption proof after CI finishes.
This omits transfer-mode/live-truth evidence, Goal-null fallback,
progress-ledger evidence, green-clean merge-or-blocker discipline, and concrete
owner-surface action.
EOF
cat > "$LIVE_WORK_MANAGEMENT_REPO/Makefile" <<'EOF'
check:
	@bash scripts/check.sh

test-fast:
	@bash scripts/check.sh
EOF
cat > "$LIVE_WORK_MANAGEMENT_REPO/.github/workflows/ci.yml" <<'EOF'
name: ci
on:
  pull_request:
  push:
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - run: make check
EOF
cat > "$LIVE_WORK_MANAGEMENT_REPO/scripts/check.sh" <<'EOF'
#!/usr/bin/env bash
echo "closure validation"
EOF
chmod +x "$LIVE_WORK_MANAGEMENT_REPO/scripts/check.sh"
cat > "$LIVE_WORK_MANAGEMENT_REPO/docs/recommendation.md" <<'EOF'
# Live Work Recommendation

The recommendation is category-only and says the operator should choose a
category, pick an adoption proof, or work on repo-star before the agent names
an exact owner-surface action.

This Goal-mode episode is for one tiny issue touching a single file; it is
micro-work and too small for Goal mode.

Issue #32 is closed and PR #99 is merged on GitHub, but the local completion
manifest remains the authoritative closeout and work-close is still required as
the closure authority.

The repo-star fleet should handle the shared capability and pick an owner later.

Run repo-auditor against repo-optimizer as a validation target, but omit the
safety boundary for that target use.

Goal mode improved runtime health and reduced operator steering, but the
episode has no raw runtime evidence, session log, Goal metadata, command
transcript, or CI run reference.

The provider failure should be handled by another retrospective and selector
update before any concrete fix is named.

Hermes foreground wrapper:
hermes chat --provider copilot -m gpt-5.5 -q prompt -Q
status=$?
python3 scripts/validate-hermes-foreground-output.py --status-code "$status"

Default capability guidance: adopt the upstream default capability from the
fork proof and PR branch proof. The remote-only proof is enough; do not block on
local proof or upstream-main reconciliation before recommending the default.

The Goal-mode arc was interrupted by an upstream blocker. Use the interruption
recovery and batch reconstitution contract, but only record the replacement
objective. Missing original objective, blocker class, Goal state, first owner PR,
intentional serial/parallel plan, learning trigger, fallback, and validation.

After that blocker, continue one at a time as unplanned serial repair work
without a planned replacement route or intentional plan.

The system self-learned and self-healed from this interruption, but no GitHub
owner action, raw evidence, GBrain slug, no-capture reason, or bounded
non-claims were recorded.

Hermes foreground recovery will self-heal route-changing failures and recover
after a failed foreground run, but this owner guidance does not require the
foreground failure guidance artifact, GitHub issue truth, failed run receipt
evidence, or no-regrowth boundaries.

An upstream capability intake record says component identity and local version
are known, source refs are stale, behindness is reduced to 0, capability
decisions adopt a native capability, update action is update now, validation is
missing, and owner routes, non-claims, and out-of-bounds surfaces are absent.

GBrain is canonical for repo-local instruction distribution and overrides repo
evidence. Use GBrain sync --watch to keep instruction surfaces fresh.

Issue #164 campaign sync: Next active track: None selected. Search returned no
open child issues or PRs, and the agent-authored note says no current
admissible owner-surface action remains.

Runtime Learning Shadow scheduled readback package: comments and artifacts are
closure truth for #798. This starts a scheduler that owns future readbacks.

SCHEDULED_READBACK_OWNER_PROOF candidate_id=runtime_shadow_schedule_readback
uses the Runtime Learning Shadow schedule file as its schedule source. The proof says
workflow_dispatch counts as scheduled proof and may be admitted. It captures raw
private local logs for retention, then a scheduler queue creates GitHub issues
automatically and auto-merges repairs.

Final Campaign Sync admission checks next active track, micro-work rule, and
threshold clause but omits completed-track predicate coverage. Campaign Sync:
Completed track: #816 Hermes failure residue guidance.
Completed latest track: #811 stale completed track.

ROUTE_CHANGING_LEARNING_FAILURE_RECEIPT route_changed=true. A broad GBrain search
miss proves absence. Optional GBrain slug: bma/issue164/learning/stale-card.
Stale GBrain evidence is accepted as route truth. No raw evidence, no
no_capture_reason, no fallback_without_memory, no owner action, no literal-safe
GitHub readback, and a background Hermes controller owns routing.

Autonomy Preview for a capability-placement carrier:
Best current owner: TBD
Allowed reach now: maybe later
Promotion gate: unknown
A controller queue with background Hermes owns future routing.

Hermes foreground reliability record:
Hermes eligibility: TBD
Attempt role: doer
Launcher receipt: missing
Hermes owns validation and merges the PR after retrying checks as a background
Hermes worker. Promotion gate: maybe later.

Deep Research/source-intelligence native corpus:
DEEP_RESEARCH_SOURCE_INTELLIGENCE_NATIVE_CORPUS is planned for the approved
operator URLs. manual Deep Research sidecar: TBD. This omits
SOURCE_INSIGHT_PACKET, source count/corpus scope, public/no-auth then exact-url
authenticated access, claim/effect routing, evidence tier,
GitHub issue/PR/check/merge truth, and next owner action. Deep Research API ran
live and proved the corpus.

Standalone sidecar prompt:
Prompt B for BMA should solve the architecture problem.
Definitions: TBD.
Read the GitHub issue and review this prompt.
Deep Research should research the sources without source rules.
The sidecar approves PRs and becomes closure truth.

HERMES_FOREGROUND_FAILURE_DISPOSITION:
classification: resolved_by_merged_repair
close_allowed: true
repair evidence: primary object PR #179 and /tmp/private-run-root
The scheduler queue will automatically close the failure issue and auto-merge the
next repair after a hidden retry loop.
EOF

python3 - "$REPO_ROOT" "$EXPLAINER_REPO" "$LIVE_WORK_MANAGEMENT_REPO" <<'PY'
import json
import subprocess
import sys

repo_root, explainer_repo, live_repo = sys.argv[1:4]
scripts = {
    "AS-20": "detect-as-selection-handback-recommendation.sh",
    "AS-21": "detect-as-too-small-goal-mode-episode.sh",
    "AS-22": "detect-as-github-native-closure-regrowth.sh",
    "AS-23": "detect-as-owner-surface-ambiguity.sh",
    "AS-24": "detect-as-reciprocal-proving-ground-gap.sh",
    "AS-25": "detect-as-goal-runtime-evidence-gap.sh",
    "AS-26": "detect-as-reactive-self-healing-loop.sh",
    "AS-27": "detect-as-shell-reserved-status-variable.sh",
    "AS-28": "detect-as-stale-default-capability-guidance.sh",
    "AS-29": "detect-as-hermes-foreground-receipt-adoption-gap.sh",
    "AS-30": "detect-as-interrupted-goal-recovery-gap.sh",
    "AS-31": "detect-as-fractured-serial-continuation.sh",
    "AS-32": "detect-as-unanchored-self-learning-claim.sh",
    "AS-33": "detect-as-foreground-failure-guidance-gap.sh",
    "AS-34": "detect-as-closure-run-identity-gap.sh",
    "AS-35": "detect-as-upstream-capability-intake-gap.sh",
    "AS-36": "detect-as-gbrain-instruction-distribution-overclaim.sh",
    "AS-37": "detect-as-issue164-runtime-drift.sh",
    "AS-38": "detect-as-self-authored-campaign-pause-authority.sh",
    "AS-39": "detect-as-scheduled-evidence-boundary-gap.sh",
    "AS-41": "detect-as-campaign-sync-completed-track-gap.sh",
    "AS-42": "detect-as-route-changing-learning-propagation-gap.sh",
    "AS-43": "detect-as-capability-placement-gap.sh",
    "AS-44": "detect-as-hermes-foreground-reliability-evidence-gap.sh",
    "AS-46": "detect-as-deep-research-source-intelligence-native-corpus-gap.sh",
    "AS-48": "detect-as-standalone-external-intelligence-sidecar-gap.sh",
    "AS-49": "detect-as-scheduled-readback-owner-proof-gap.sh",
    "AS-50": "detect-as-hermes-foreground-failure-disposition-gap.sh",
}

for signature_id, script in scripts.items():
    explainer = subprocess.run(
        ["bash", f"{repo_root}/scripts/{script}", explainer_repo],
        check=True,
        text=True,
        stdout=subprocess.PIPE,
    )
    explainer_payload = json.loads(explainer.stdout)
    assert explainer_payload["ds_id"] == signature_id
    assert explainer_payload["fired"] is False, explainer_payload

    live = subprocess.run(
        ["bash", f"{repo_root}/scripts/{script}", live_repo],
        check=True,
        text=True,
        stdout=subprocess.PIPE,
    )
    live_payload = json.loads(live.stdout)
    assert live_payload["ds_id"] == signature_id
    assert live_payload["fired"] is True, live_payload
PY

AS50_GAP_REPO="$TMPDIR/as50-gap-repo"
AS50_PROVIDER_GAP_REPO="$TMPDIR/as50-provider-gap-repo"
AS50_PROVIDER_CLEAN_REPO="$TMPDIR/as50-provider-clean-repo"
AS50_CLEAN_REPO="$TMPDIR/as50-clean-repo"
mkdir -p "$AS50_GAP_REPO/docs" "$AS50_PROVIDER_GAP_REPO/docs" "$AS50_PROVIDER_CLEAN_REPO/docs" "$AS50_CLEAN_REPO/docs"
cat > "$AS50_GAP_REPO/docs/hermes-disposition.md" <<'EOF'
# Hermes Failure Disposition

HERMES_FOREGROUND_FAILURE_DISPOSITION
failure issue: https://github.com/example/repo/issues/885
classification: resolved_by_merged_repair
close_allowed: true
recommended action: close the failure issue from primary object PR #179
repair evidence: primary object PR #179 plus /tmp/private-run-root/raw-log.txt
The hidden retry scheduler queue will automatically close and auto-merge the next
repair.
EOF

cat > "$AS50_PROVIDER_GAP_REPO/docs/hermes-provider-disposition.md" <<'EOF'
# Hermes Provider Disposition

HERMES_FOREGROUND_FAILURE_DISPOSITION
failure issue: https://github.com/example/repo/issues/885
primary object: https://github.com/example/repo/pull/12
command family: hermes-foreground
failure code: provider_user_request_timeout
classification: superseded_by_provider_policy
close_allowed: true
provider-policy evidence: stale provider note without an explicit
superseded-provider signal or current provider/model policy evidence.
GitHub truth: https://github.com/example/repo/issues/885#issuecomment-1
EOF

cat > "$AS50_PROVIDER_CLEAN_REPO/docs/hermes-provider-disposition.md" <<'EOF'
# Hermes Provider Disposition

HERMES_FOREGROUND_FAILURE_DISPOSITION
failure issue: https://github.com/example/repo/issues/885
primary object: https://github.com/example/repo/pull/12
command family: hermes-foreground
failure code: provider_user_request_timeout
classification: superseded_by_provider_policy
close_allowed: true
provider-policy evidence: explicit superseded-provider signal recorded on the
failure issue.
current provider/model policy evidence: provider copilot model gpt-5.5 uses the
current supported provider path.
GitHub truth: https://github.com/example/repo/issues/885#issuecomment-1
bounded non-claims: no retries, no scheduler, no queue, no daemon, no controller,
no registry, no auto-close, no auto-merge, no upstream Hermes mutation, no
downstream mutation, and no background Hermes/GBrain.
EOF

cat > "$AS50_CLEAN_REPO/docs/hermes-disposition.md" <<'EOF'
# Hermes Failure Disposition

HERMES_FOREGROUND_FAILURE_DISPOSITION
failure issue: https://github.com/example/repo/issues/885 state=CLOSED
primary object: https://github.com/example/repo/pull/12
related repair PRs: exactly one merged related repair PR
https://github.com/example/repair/pull/179 at merge commit abc123 references the
failure issue itself.
command family: hermes-foreground
failure code: missing_final_response
classification: resolved_by_merged_repair
close allowance: true
recommended action: close with merged repair evidence
blocker evidence: none
provider-policy evidence: none
GitHub truth: https://github.com/example/repo/issues/885#issuecomment-1 and
https://github.com/example/repair/pull/179
promotion trigger: clean live proof, merged repair, focused tests, and no
unresolved high-severity critique.
demotion trigger: false close, ambiguous repair evidence, stale policy evidence,
hidden retry behavior, or missing GitHub truth.
kill switch: false close or background retry behavior disables the disposition.
bounded non-claims: no retries, no scheduler, no queue, no daemon, no controller,
no registry, no auto-close, no auto-merge, no upstream Hermes mutation, no
downstream mutation, no target mutation, and no background Hermes/GBrain.
EOF

python3 - "$REPO_ROOT" "$AS50_GAP_REPO" "$AS50_PROVIDER_GAP_REPO" "$AS50_PROVIDER_CLEAN_REPO" "$AS50_CLEAN_REPO" <<'PY'
import json
import subprocess
import sys

repo_root, gap_repo, provider_gap_repo, provider_clean_repo, clean_repo = sys.argv[1:6]
script = f"{repo_root}/scripts/detect-as-hermes-foreground-failure-disposition-gap.sh"

gap = subprocess.run(["bash", script, gap_repo], check=True, text=True, stdout=subprocess.PIPE)
gap_payload = json.loads(gap.stdout)
assert gap_payload["ds_id"] == "AS-50", gap_payload
assert gap_payload["fired"] is True, gap_payload
assert gap_payload["signals"]["missing_primary_object_count"] == 1, gap_payload
assert gap_payload["signals"]["missing_command_family_count"] == 1, gap_payload
assert gap_payload["signals"]["missing_failure_code_count"] == 1, gap_payload
assert gap_payload["signals"]["missing_merged_repair_evidence_count"] == 1, gap_payload
assert gap_payload["signals"]["ambiguous_repair_evidence_count"] == 1, gap_payload
assert gap_payload["signals"]["raw_private_only_evidence_count"] == 1, gap_payload
assert gap_payload["signals"]["hidden_retry_scheduler_controller_count"] == 1, gap_payload
assert gap_payload["signals"]["auto_close_count"] == 1, gap_payload
assert gap_payload["signals"]["auto_merge_count"] == 1, gap_payload

provider_gap = subprocess.run(
    ["bash", script, provider_gap_repo],
    check=True,
    text=True,
    stdout=subprocess.PIPE,
)
provider_payload = json.loads(provider_gap.stdout)
assert provider_payload["ds_id"] == "AS-50", provider_payload
assert provider_payload["fired"] is True, provider_payload
assert provider_payload["signals"]["provider_policy_mismatch_count"] == 1, provider_payload

provider_clean = subprocess.run(
    ["bash", script, provider_clean_repo],
    check=True,
    text=True,
    stdout=subprocess.PIPE,
)
provider_clean_payload = json.loads(provider_clean.stdout)
assert provider_clean_payload["ds_id"] == "AS-50", provider_clean_payload
assert provider_clean_payload["fired"] is False, provider_clean_payload
assert provider_clean_payload["signals"]["hermes_failure_disposition_grounded_count"] == 1, provider_clean_payload

clean = subprocess.run(["bash", script, clean_repo], check=True, text=True, stdout=subprocess.PIPE)
clean_payload = json.loads(clean.stdout)
assert clean_payload["ds_id"] == "AS-50", clean_payload
assert clean_payload["fired"] is False, clean_payload
assert clean_payload["signals"]["hermes_failure_disposition_grounded_count"] == 1, clean_payload

self_scan = subprocess.run(["bash", script, repo_root], check=True, text=True, stdout=subprocess.PIPE)
self_payload = json.loads(self_scan.stdout)
assert self_payload["ds_id"] == "AS-50", self_payload
assert self_payload["fired"] is False, self_payload
assert self_payload["signals"]["hermes_failure_disposition_gap_count"] == 0, self_payload
assert self_payload["signals"]["hermes_failure_disposition_grounded_count"] >= 1, self_payload
PY

AS34_GAP_REPO="$TMPDIR/as34-gap-repo"
AS34_HEALTHY_REPO="$TMPDIR/as34-healthy-repo"
mkdir -p "$AS34_GAP_REPO/.github/workflows" "$AS34_GAP_REPO/scripts"
mkdir -p "$AS34_HEALTHY_REPO/.github/workflows" "$AS34_HEALTHY_REPO/scripts"
cat > "$AS34_GAP_REPO/Makefile" <<'EOF'
check:
	@bash scripts/check.sh

test-fast:
	@bash scripts/check.sh
EOF
cat > "$AS34_GAP_REPO/.github/workflows/ci.yml" <<'EOF'
name: ci
on:
  pull_request:
  push:
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - run: make test-fast
EOF
cat > "$AS34_GAP_REPO/scripts/check.sh" <<'EOF'
#!/usr/bin/env bash
echo "make check"
EOF
chmod +x "$AS34_GAP_REPO/scripts/check.sh"

cat > "$AS34_HEALTHY_REPO/Makefile" <<'EOF'
check:
	@CLOSURE_PHASE=local-validation bash scripts/record-make-target.sh check

test-fast:
	@CLOSURE_PHASE=local-validation bash scripts/record-make-target.sh test-fast
EOF
cat > "$AS34_HEALTHY_REPO/.github/workflows/ci.yml" <<'EOF'
name: ci
on:
  pull_request:
  push:
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - run: make test-fast
        env:
          GITHUB_RUN_ID: ${{ github.run_id }}
          GITHUB_RUN_ATTEMPT: ${{ github.run_attempt }}
EOF
cat > "$AS34_HEALTHY_REPO/scripts/record-make-target.sh" <<'EOF'
#!/usr/bin/env bash
closure_run_id="${CLOSURE_RUN_ID:-local-$(date +%s)}"
closure_phase="${CLOSURE_PHASE:-local-validation}"
closure_trigger="${CLOSURE_TRIGGER:-manual}"
evidence_reuse_key="${EVIDENCE_REUSE_KEY:-${closure_phase}:$1}"
github_run_id="${GITHUB_RUN_ID:-local}"
github_run_attempt="${GITHUB_RUN_ATTEMPT:-0}"
parent_command="${PARENT_COMMAND:-make $1}"
printf '%s\n' "$closure_run_id $closure_phase $closure_trigger $evidence_reuse_key $github_run_id $github_run_attempt $parent_command"
EOF
chmod +x "$AS34_HEALTHY_REPO/scripts/record-make-target.sh"

python3 - "$REPO_ROOT" "$AS34_GAP_REPO" "$AS34_HEALTHY_REPO" <<'PY'
import json
import subprocess
import sys

repo_root, gap_repo, healthy_repo = sys.argv[1:4]
script = f"{repo_root}/scripts/detect-as-closure-run-identity-gap.sh"

gap = subprocess.run(["bash", script, gap_repo], check=True, text=True, stdout=subprocess.PIPE)
gap_payload = json.loads(gap.stdout)
assert gap_payload["ds_id"] == "AS-34", gap_payload
assert gap_payload["fired"] is True, gap_payload
assert gap_payload["signals"]["closure_run_identity_gap_count"] == 1, gap_payload
assert "local_command_identity" in gap_payload["signals"]["missing_identity_surfaces"], gap_payload
assert "github_workflow_identity" in gap_payload["signals"]["missing_identity_surfaces"], gap_payload

healthy = subprocess.run(["bash", script, healthy_repo], check=True, text=True, stdout=subprocess.PIPE)
healthy_payload = json.loads(healthy.stdout)
assert healthy_payload["ds_id"] == "AS-34", healthy_payload
assert healthy_payload["fired"] is False, healthy_payload
assert healthy_payload["signals"]["local_identity_surface_count"] >= 1, healthy_payload
assert healthy_payload["signals"]["remote_identity_surface_count"] >= 1, healthy_payload
PY

AS29_BARE_COMMAND_REPO="$TMPDIR/as29-bare-command-repo"
mkdir -p "$AS29_BARE_COMMAND_REPO/docs"
cat > "$AS29_BARE_COMMAND_REPO/docs/hermes.md" <<'EOF'
# Hermes Launch

hermes chat -q "implement the detector" -Q
EOF

AS29_LARGE_UNGROUNDED_REPO="$TMPDIR/as29-large-ungrounded-repo"
mkdir -p "$AS29_LARGE_UNGROUNDED_REPO/aaa-filler" "$AS29_LARGE_UNGROUNDED_REPO/docs"
python3 - "$AS29_LARGE_UNGROUNDED_REPO" <<'PY'
from pathlib import Path
import sys

repo = Path(sys.argv[1])
for index in range(225):
    (repo / "aaa-filler" / f"filler-{index:03d}.md").write_text(
        f"# Filler {index}\n\nThis sorted filler file previously hid owner guidance behind the AS scan cap.\n",
        encoding="utf-8",
    )
(repo / "docs" / "issue164-ecosystem-architecture.md").write_text(
    "# Issue 164 Ecosystem Architecture\n\n"
    "Hermes foreground wrapper:\n"
    "timeout 900 hermes chat --provider copilot -m gpt-5.5 -q prompt -Q\n"
    "python3 scripts/validate-hermes-foreground-output.py --status-code \"$status\"\n",
    encoding="utf-8",
)
PY

AS29_LARGE_GROUNDED_REPO="$TMPDIR/as29-large-grounded-repo"
mkdir -p "$AS29_LARGE_GROUNDED_REPO/aaa-filler" "$AS29_LARGE_GROUNDED_REPO/scripts"
python3 - "$AS29_LARGE_GROUNDED_REPO" <<'PY'
from pathlib import Path
import sys

repo = Path(sys.argv[1])
for index in range(225):
    (repo / "aaa-filler" / f"filler-{index:03d}.md").write_text(
        f"# Filler {index}\n\nThis sorted filler file previously hid grounded launcher guidance.\n",
        encoding="utf-8",
    )
(repo / "scripts" / "run-hermes-foreground.py").write_text(
    "#!/usr/bin/env python3\n"
    "\"\"\"Grounded Hermes foreground launcher.\"\"\"\n"
    "# Writes HERMES_FOREGROUND_RUN_RECEIPT for timeout 900 hermes chat -q prompt -Q runs.\n"
    "print('HERMES_FOREGROUND_RUN_RECEIPT')\n",
    encoding="utf-8",
)
PY

AS29_LARGE_ROOT_GROUNDED_REPO="$TMPDIR/as29-large-root-grounded-repo"
mkdir -p "$AS29_LARGE_ROOT_GROUNDED_REPO/.agents/skills"
python3 - "$AS29_LARGE_ROOT_GROUNDED_REPO" <<'PY'
from pathlib import Path
import sys

repo = Path(sys.argv[1])
for index in range(225):
    skill_dir = repo / ".agents" / "skills" / f"filler-{index:03d}"
    skill_dir.mkdir(parents=True, exist_ok=True)
    (skill_dir / "AGENTS.md").write_text(
        f"# Nested Agent {index}\n\nNested AGENTS.md fixture without Hermes guidance.\n",
        encoding="utf-8",
    )
(repo / "AGENTS.md").write_text(
    "# AGENTS.md\n\n"
    "Use foreground Hermes through hermes chat -q prompt -Q and retain HERMES_FOREGROUND_RUN_RECEIPT.\n",
    encoding="utf-8",
)
PY

python3 - "$REPO_ROOT" "$AS29_BARE_COMMAND_REPO" "$AS29_LARGE_UNGROUNDED_REPO" "$AS29_LARGE_GROUNDED_REPO" "$AS29_LARGE_ROOT_GROUNDED_REPO" <<'PY'
import json
import subprocess
import sys

repo_root, target_repo, large_ungrounded_repo, large_grounded_repo, large_root_grounded_repo = sys.argv[1:6]
script = f"{repo_root}/scripts/detect-as-hermes-foreground-receipt-adoption-gap.sh"

completed = subprocess.run(
    ["bash", script, target_repo],
    check=True,
    text=True,
    stdout=subprocess.PIPE,
)
payload = json.loads(completed.stdout)
assert payload["ds_id"] == "AS-29"
assert payload["fired"] is True, payload
assert "docs/hermes.md" in payload["evidence"], payload
assert payload["eligible_files"] == 1, payload
assert payload["scan_limit"] == 200, payload
assert payload["scan_limited"] is False, payload
assert "owner guidance" in payload["scan_order_note"], payload

large_ungrounded = subprocess.run(
    ["bash", script, large_ungrounded_repo],
    check=True,
    text=True,
    stdout=subprocess.PIPE,
)
payload = json.loads(large_ungrounded.stdout)
assert payload["ds_id"] == "AS-29", payload
assert payload["fired"] is True, payload
assert payload["signals"]["hermes_foreground_guidance_count"] == 1, payload
assert payload["signals"]["foreground_receipt_gap_count"] == 1, payload
assert "docs/issue164-ecosystem-architecture.md" in payload["evidence"], payload
assert payload["eligible_files"] == 226, payload
assert payload["scanned_files"] == 200, payload
assert payload["scan_limit"] == 200, payload
assert payload["scan_limited"] is True, payload
assert "bounded to 200" in payload["scan_order_note"], payload

large_grounded = subprocess.run(
    ["bash", script, large_grounded_repo],
    check=True,
    text=True,
    stdout=subprocess.PIPE,
)
payload = json.loads(large_grounded.stdout)
assert payload["ds_id"] == "AS-29", payload
assert payload["fired"] is False, payload
assert payload["signals"]["hermes_foreground_guidance_count"] == 1, payload
assert payload["signals"]["foreground_receipt_grounded_count"] == 1, payload
assert "scripts/run-hermes-foreground.py" in payload["evidence"], payload
assert payload["eligible_files"] == 226, payload
assert payload["scanned_files"] == 200, payload
assert payload["scan_limit"] == 200, payload
assert payload["scan_limited"] is True, payload

large_root_grounded = subprocess.run(
    ["bash", script, large_root_grounded_repo],
    check=True,
    text=True,
    stdout=subprocess.PIPE,
)
payload = json.loads(large_root_grounded.stdout)
assert payload["ds_id"] == "AS-29", payload
assert payload["fired"] is False, payload
assert payload["signals"]["hermes_foreground_guidance_count"] == 1, payload
assert payload["signals"]["foreground_receipt_grounded_count"] == 1, payload
assert "AGENTS.md" in payload["evidence"], payload
assert payload["eligible_files"] == 226, payload
assert payload["scanned_files"] == 200, payload
assert payload["scan_limited"] is True, payload
PY

AS33_FAILURE_TO_ISSUE_GAP_REPO="$TMPDIR/as33-failure-to-issue-gap-repo"
AS33_FAILURE_TO_ISSUE_HEALTHY_REPO="$TMPDIR/as33-failure-to-issue-healthy-repo"
mkdir -p "$AS33_FAILURE_TO_ISSUE_GAP_REPO/docs" "$AS33_FAILURE_TO_ISSUE_HEALTHY_REPO/docs"
cat > "$AS33_FAILURE_TO_ISSUE_GAP_REPO/docs/foreground-failure.md" <<'EOF'
# Foreground Failure Conversion

When a Hermes foreground failure hits a route-changing failure, convert the
foreground failure to a GitHub failure issue. The guidance mentions
HERMES_FOREGROUND_FAILURE_GUIDANCE and an owner action, but only says to create a
failure issue and let the agent handle duplicates later.
EOF
cat > "$AS33_FAILURE_TO_ISSUE_HEALTHY_REPO/docs/foreground-failure.md" <<'EOF'
# Foreground Failure-To-Issue Conversion

For route-changing Hermes foreground failures, convert
HERMES_FOREGROUND_FAILURE_GUIDANCE into explicit GitHub issue or GitHub issue
comment truth on the owner surface. The accepted guidance input may be the
source receipt evidence; record source receipt path, evidence path, dedupe key,
and owner action.

Exact marker search is authoritative. Include
`<!-- issue164-foreground-failure-to-issue: hermes-foreground:timeout:pr-53 -->`
and search for that exact marker before creating a new issue. If the exact
marker already exists, add a GitHub issue comment truth instead of creating a
duplicate. A bounded fallback body scan is only an index-lag guard across a
small explicit set of likely issue bodies or comments; broad fallback saturation
is not permanent authority after clean exact marker search.

Conversion output fields: GitHub issue or GitHub issue comment truth, dedupe key,
evidence path `/tmp/hermes/failure-guidance.json`, source receipt path
`/tmp/hermes/HERMES_FOREGROUND_FAILURE_GUIDANCE.json`, owner action `create issue
or comment on the existing owner issue`, and bounded non-claims. This conversion
is not closure, not a repair, not CI proof, and not runtime proof beyond the
cited evidence. It does not authorize automatic retry, automatic repair,
controller, scheduler, queue, daemon, retry loop, registry, hidden registry,
background GBrain behavior, automatic background issue creation, background
behavior, auto-merge, downstream mutation, target-repo mutation, or
Hermes/GBrain internals mutation.
EOF

python3 - "$REPO_ROOT" "$AS33_FAILURE_TO_ISSUE_GAP_REPO" "$AS33_FAILURE_TO_ISSUE_HEALTHY_REPO" <<'PY'
import json
import subprocess
import sys

repo_root, gap_repo, healthy_repo = sys.argv[1:4]
script = f"{repo_root}/scripts/detect-as-foreground-failure-guidance-gap.sh"

gap = subprocess.run(["bash", script, gap_repo], check=True, text=True, stdout=subprocess.PIPE)
gap_payload = json.loads(gap.stdout)
assert gap_payload["ds_id"] == "AS-33", gap_payload
assert gap_payload["fired"] is True, gap_payload
assert isinstance(gap_payload.get("evidence"), str), gap_payload
assert "failed_foreground_run_receipt" in gap_payload["evidence"], gap_payload
assert "no_regrowth_boundaries" in gap_payload["evidence"], gap_payload
assert "exact_marker_dedupe" in gap_payload["evidence"], gap_payload
assert "bounded_fallback_index_lag_guard" in gap_payload["evidence"], gap_payload
assert "evidence_and_source_receipt_path" in gap_payload["evidence"], gap_payload

healthy = subprocess.run(["bash", script, healthy_repo], check=True, text=True, stdout=subprocess.PIPE)
healthy_payload = json.loads(healthy.stdout)
assert healthy_payload["ds_id"] == "AS-33", healthy_payload
assert healthy_payload["fired"] is False, healthy_payload
assert healthy_payload["signals"]["foreground_failure_guidance_grounded_count"] == 1, healthy_payload
assert isinstance(healthy_payload.get("evidence"), str), healthy_payload
assert "exact_marker_dedupe" not in healthy_payload.get("evidence", ""), healthy_payload
assert "bounded_fallback_index_lag_guard" not in healthy_payload.get("evidence", ""), healthy_payload
assert "evidence_and_source_receipt_path" not in healthy_payload.get("evidence", ""), healthy_payload
PY

AS27_REPLAY_ONLY_REPO="$TMPDIR/as27-replay-only-repo"
mkdir -p "$AS27_REPLAY_ONLY_REPO/acceptance/replays/20260601T005144Z-real-hermes-chat-as-scorecard"
cat > "$AS27_REPLAY_ONLY_REPO/acceptance/replays/20260601T005144Z-real-hermes-chat-as-scorecard/AS_WORK_MANAGEMENT_FINDINGS.json" <<'EOF'
{
  "fired_findings": [
    {
      "anti_pattern_family": "shell_reserved_status_variable",
      "ds_id": "AS-27",
      "evidence": "reserved_status_assignment=>scripts/generate-patches.sh=>guard_indent + \"    status=$?\", | safe_status_assignment=>none",
      "fired": true,
      "reason": "Hermes/zsh launch snippet captures exit code in reserved shell variable `status`"
    }
  ]
}
EOF
cat > "$AS27_REPLAY_ONLY_REPO/acceptance/replays/20260601T005144Z-real-hermes-chat-as-scorecard/advisor-stdout.txt" <<'EOF'
+        "command": "target content search for reserved status capture",
+        "outcome": "matched scripts/generate-patches.sh generated launch snippet lines using status=$? and $status",
+        "artifact": "/tmp/replay/advisor-stdout.txt"
+- AS-27, `shell_reserved_status_variable`, severity HIGH, prevention tier T1.
+- Reported reason: Hermes/zsh launch snippet captures exit code in reserved shell variable `status`.
+- Snapshot corroboration: `scripts/generate-patches.sh` includes generated guard lines that emit `status=$?` and then reference `$status`.
EOF

AS27_LIVE_STATUS_ZERO_REPO="$TMPDIR/as27-live-status-zero-repo"
mkdir -p "$AS27_LIVE_STATUS_ZERO_REPO/scripts"
cat > "$AS27_LIVE_STATUS_ZERO_REPO/scripts/hermes-foreground-wrapper.sh" <<'EOF'
#!/usr/bin/env zsh
# Real Hermes foreground launch snippet.
status=0
timeout 900 hermes chat --provider copilot -m gpt-5.5 -q prompt -Q
python3 scripts/validate-hermes-foreground-output.py --status-code "$status"
EOF
chmod +x "$AS27_LIVE_STATUS_ZERO_REPO/scripts/hermes-foreground-wrapper.sh"

AS27_PYTHON_STATUS_REPO="$TMPDIR/as27-python-status-repo"
mkdir -p "$AS27_PYTHON_STATUS_REPO/scripts"
cat > "$AS27_PYTHON_STATUS_REPO/scripts/audit_terminal.py" <<'EOF'
#!/usr/bin/env python3
"""Mentions zsh and Hermes in prose but uses ordinary Python assignment."""

status = "WARNING: INCONCLUSIVE"
status="WARNING: STILL PYTHON"
print(status)
EOF

AS27_PYTHON_GENERATOR_REPO="$TMPDIR/as27-python-generator-repo"
mkdir -p "$AS27_PYTHON_GENERATOR_REPO/scripts"
cat > "$AS27_PYTHON_GENERATOR_REPO/scripts/generate_hermes_wrapper.py" <<'EOF'
#!/usr/bin/env python3
"""Generates a zsh-compatible Hermes foreground wrapper."""

guard = "status=$?"
print(f"timeout 900 hermes chat -q prompt -Q; {guard}")
EOF

AS27_PYTHON_MULTILINE_GENERATOR_REPO="$TMPDIR/as27-python-multiline-generator-repo"
mkdir -p "$AS27_PYTHON_MULTILINE_GENERATOR_REPO/scripts"
cat > "$AS27_PYTHON_MULTILINE_GENERATOR_REPO/scripts/generate_hermes_wrapper.py" <<'EOF'
#!/usr/bin/env python3
"""Generates a zsh-compatible Hermes foreground wrapper."""

script = """
timeout 900 hermes chat -q prompt -Q
status=$?
"""
print(script)
EOF

AS27_PYTHON_RHS_GENERATOR_REPO="$TMPDIR/as27-python-rhs-generator-repo"
mkdir -p "$AS27_PYTHON_RHS_GENERATOR_REPO/scripts"
cat > "$AS27_PYTHON_RHS_GENERATOR_REPO/scripts/generate_hermes_wrapper.py" <<'EOF'
#!/usr/bin/env python3
"""Generates a zsh-compatible Hermes foreground wrapper."""

status = "status=$?"
print(f"timeout 900 hermes chat -q prompt -Q; {status}")
EOF

python3 - "$REPO_ROOT" "$AS27_REPLAY_ONLY_REPO" "$AS27_LIVE_STATUS_ZERO_REPO" "$AS27_PYTHON_STATUS_REPO" "$AS27_PYTHON_GENERATOR_REPO" "$AS27_PYTHON_MULTILINE_GENERATOR_REPO" "$AS27_PYTHON_RHS_GENERATOR_REPO" <<'PY'
import json
import subprocess
import sys

repo_root, replay_repo, live_status_zero_repo, python_status_repo, python_generator_repo, python_multiline_generator_repo, python_rhs_generator_repo = sys.argv[1:8]
script = f"{repo_root}/scripts/detect-as-shell-reserved-status-variable.sh"

replay = subprocess.run(["bash", script, replay_repo], check=True, text=True, stdout=subprocess.PIPE)
payload = json.loads(replay.stdout)
assert payload["ds_id"] == "AS-27", payload
assert payload["fired"] is False, payload
assert payload["signals"]["shell_reserved_status_variable_count"] == 0, payload
assert payload["signals"]["retained_replay_evidence_count"] == 2, payload

live = subprocess.run(["bash", script, live_status_zero_repo], check=True, text=True, stdout=subprocess.PIPE)
payload = json.loads(live.stdout)
assert payload["ds_id"] == "AS-27", payload
assert payload["fired"] is True, payload
assert payload["signals"]["shell_reserved_status_variable_count"] == 1, payload
assert "status=0" in payload["evidence"], payload

python_status = subprocess.run(["bash", script, python_status_repo], check=True, text=True, stdout=subprocess.PIPE)
payload = json.loads(python_status.stdout)
assert payload["ds_id"] == "AS-27", payload
assert payload["fired"] is False, payload
assert payload["signals"]["shell_reserved_status_variable_count"] == 0, payload

python_generator = subprocess.run(["bash", script, python_generator_repo], check=True, text=True, stdout=subprocess.PIPE)
payload = json.loads(python_generator.stdout)
assert payload["ds_id"] == "AS-27", payload
assert payload["fired"] is True, payload
assert payload["signals"]["shell_reserved_status_variable_count"] == 1, payload
assert "status=$?" in payload["evidence"], payload

python_multiline_generator = subprocess.run(["bash", script, python_multiline_generator_repo], check=True, text=True, stdout=subprocess.PIPE)
payload = json.loads(python_multiline_generator.stdout)
assert payload["ds_id"] == "AS-27", payload
assert payload["fired"] is True, payload
assert payload["signals"]["shell_reserved_status_variable_count"] == 1, payload
assert "status=$?" in payload["evidence"], payload

python_rhs_generator = subprocess.run(["bash", script, python_rhs_generator_repo], check=True, text=True, stdout=subprocess.PIPE)
payload = json.loads(python_rhs_generator.stdout)
assert payload["ds_id"] == "AS-27", payload
assert payload["fired"] is True, payload
assert payload["signals"]["shell_reserved_status_variable_count"] == 1, payload
assert "status=$?" in payload["evidence"], payload
PY

CLEAN_REPO="$TMPDIR/as-cost-clean-repo"
mkdir -p "$CLEAN_REPO/docs"

cat > "$CLEAN_REPO/AGENTS.md" <<'EOF'
# AGENTS.md

Core-five and repo-star validation may use this repository as a reciprocal
proving-ground read-only target. That evidence is ordinary validation, not
downstream adoption authority. Any mutation must route through the named owner
repo's own issue, branch, PR, checks, and merge path.
EOF

cat > "$CLEAN_REPO/docs/cost-evidence.md" <<EOF
# Bounded Cost Evidence

The estimated cost is \$4.12 and is derived from direct token fields:
input_tokens: 100000
output_tokens: 20000
cache_read_tokens: 50000
cache_write_tokens: 1000

API-equivalent pricing reference: \$1.25 / 1M input tokens.
source_url: https://example.invalid/pricing
fetched_at: $(date +%F)

request_count: 20
tool_calls: 25
request/tool amplification: called out as a 1.25x tool fan-out multiplier.

copied evidence boundary:
copied_evidence:
> raw copied receipt line
authored_claims:
The authored claim is limited to the direct token fields above.
EOF

cat > "$CLEAN_REPO/docs/model-metrics.json" <<'EOF'
{
  "selected_model": "gpt-5.5",
  "current_model": "gpt-5.5",
  "modelMetrics": {
    "model": "gpt-5.5"
  }
}
EOF

cat > "$CLEAN_REPO/docs/enablement-control.md" <<EOF
# Enablement Control

production_default: true
authorized_by: operator approved
rollback_receipt: retained
control_receipt: retained
kill switch tested
disable path verified

production_readiness: ready
aggregate_pass_rate: 94%
per_case_receipts: case-a, case-b, case-c

token_evidence_date: $(date +%F)
input_tokens: 100000
output_tokens: 20000

The public CustomerNewsletter repo is downstream-only and read-only; do not mutate it.
Edited private CustomerNewsletter source notes for internal authoring.
EOF

cat > "$CLEAN_REPO/docs/source-intelligence.md" <<'EOF'
# Source Intelligence

SOURCE_INSIGHT_PACKET records source_id entries with insight_disposition for
each readable source. High-signal findings include owner_surface routing,
github_issue_candidate or roadmap_disposition status, and explicit_no_action
with no_action_reason when no owner change is warranted.
EOF

cat > "$CLEAN_REPO/docs/bma-work-management-clean.md" <<'EOF'
# BMA Work Management Clean

Recommendations name owner_surface and github_issue_candidate disposition
directly; there is no category-only recommendation or selection handback.
For Issue 164 recommendations, do not answer with a category such as "do real
delivery" or "adoption/delivery proof"; name one exact next owner-surface
action instead.

Goal-mode episode recommendation is reserved for a batch of eight issues across
multiple repos with a retained acceptance contract, not for tiny one-file work.

GitHub-native closeout is used when issue truth and PR truth are already closed
or merged; local closeout is explicitly bypassed with a github-native-closeout
rationale and no local completion authority is retained.

The core five are reciprocal proving grounds: BMA, repo-auditor,
repo-upgrade-advisor, repo-optimizer, and repo-agent-core may validate against
each other read-only. Each core-five repo changes only through its own owner
issue, branch, PR, checks, and merge. The owner_surface is repo-auditor and the
first deliverable is a focused detector PR.

Goal mode improved runtime health and operator steering reduction. Raw runtime
evidence is retained in rollout-2026-05-29T10-42-49.jsonl, the Goal metadata
receipt, CI run 26699097560, and the replay log.

The alignment skill catalog mentions Goal-mode leaps and recursive
self-improvement as risk categories, without claiming that runtime improved.

The provider failure was converted to GitHub issue truth and routed to the
repo-agent-core owner surface with first deliverable, validation scope, and
issue, branch, PR, checks, and merge.

Hermes foreground wrapper:
hermes chat --provider copilot -m gpt-5.5 -q prompt -Q
hermes_status=$?
cmd_status=$?
STATUS=$?
python3 scripts/validate-hermes-foreground-output.py --status-code "$hermes_status"
HERMES_FOREGROUND_RUN_RECEIPT is exported by scripts/run-hermes-foreground.py
and validated against docs/hermes-foreground-launcher-contract.md plus
schemas/HERMES_FOREGROUND_RUN_RECEIPT.schema.json.

Default capability guidance keeps the capability behind a fallback until
source proof, local proof, and same-version proof all validate on upstream main.
The validation reconciliation record names upstream_main_sha, local_main_sha,
same_version_proof, source_local_reconciliation, fallback_path, and
validation_receipt.

Recommendation category ordering is fix-broken > add-new > optimize; that
schema vocabulary is not a reactive self-healing repair route.

Do not adopt a default capability from fork proof, PR-branch proof, remote-only
proof, open PR proof, or unmerged PR proof. Production adoption requires
upstream main, local proof, same-version proof, owner_surface, fallback_path,
and validation_receipt before recommending any default.

| Capability family | Owner surface | First deliverable shape |
|---|---|---|
| Audit and signature detection | repo-auditor | Detector signature, fixture, registration, and repo-native test |
| Recommendation packaging | repo-upgrade-advisor | Recommendation template, scorer rule, prompt/schema update, and packaging fixture |
| Patch-pack materialization | repo-optimizer | Deterministic patch materializer plus git apply check fixture |

Interruption recovery and batch reconstitution record:
- Original objective: Complete the Goal-mode arc.
- Blocker class: tool_runtime_failure.
- Goal state: active.
- Replacement objective: Continue with the preauthorized owner-surface repair.
- First owner PR: repo-auditor detector precision PR.
- Intentional serial/parallel plan: intentionally serial inside the approved batch.
- Learning trigger: foreground tool failure changed the route.
- Fallback: convert a fresh permission boundary to GitHub issue truth and stop.
- Validation: repo-native checks and campaign sync.

Learning / Recovery:
- Decision changed: continue through a preauthorized owner-surface repair.
- GitHub surface: issue #403 and PR #404.
- Raw evidence: raw runtime evidence, command transcript, CI run, and check run.
- Optional GBrain slug: none.
- No-capture reason: duplicate route-change already recorded on GitHub issue truth.
- Fallback without memory: continue from GitHub issue/PR/check truth and the same owner action.
- Reusable learning text: foreground tool blockers should convert to owner issue truth before fallback.
- Owner action: repo-agent-core issue #24 and first owner PR.
- Bounded non-claims: does not prove background memory, daemon behavior, scheduler behavior, or target mutation.

Foreground recovery runtime contract:
- HERMES_FOREGROUND_FAILURE_GUIDANCE is consumed with --from-hermes-guidance.
- Route-changing failures convert to GitHub issue truth and owner truth before route changes.
- Failed HERMES_FOREGROUND_RUN_RECEIPT evidence is retained with status_code and stderr_tail.
- No-regrowth boundaries forbid controller, scheduler, queue, daemon, retry-loop, background behavior, and downstream mutation.

Issue #164 runtime launch:
- Transfer mode: fresh coordinator thread.
- Live truth: re-checked with gh issue view, gh pr list, git status, and rev-parse before mutation.
- Goal state: active; Goal-null fallback is recorded if Codex Goal is unavailable.
- Run root: /tmp/issue164-clean-runtime-20260609T000000Z with progress-ledger.jsonl.
- Heartbeat: created only after the child issue and run root exist.
- CI polling: poll GitHub checks, then merge-or-blocker with green-clean PR/check/merge truth.
- Next_owner_action: first owner PR on repo-auditor with validation scope, fallback, and GitHub issue routing.
EOF

cat > "$CLEAN_REPO/docs/deep-research-native-corpus.md" <<'EOF'
# Deep Research/source-intelligence native corpus

DEEP_RESEARCH_SOURCE_INTELLIGENCE_NATIVE_CORPUS composes SOURCE_INSIGHT_PACKET.
source_count: 19 exact operator-provided X URLs.
source_id values: arc4-x-01 through arc4-x-19.
access order: public/no-auth first, then exact-url authenticated capture only
for approved URLs.
manual Deep Research sidecar prompt only.
deep_research_api_disposition=rescoped_failed_not_authorized.
equal-insight disposition records insight/no-insight and contradiction.
claim_effect routes each claim to evidence.
evidence_tier records official_current_fact, local_proof, or operator_corpus.
owner/no-action disposition records owner_surface or explicit_no_action.
bounded non-claims: no live Deep Research API run, no live Codex Cloud
execution, no live Codex remote execution, no crawler, no source registry, no
watcher, no controller, no scheduler, no queue, no daemon, no automatic GitHub
mutation, no retained closeout truth, and no downstream mutation.
GitHub issue/PR/check/merge truth is recorded.
next_owner_action: repo-upgrade-advisor recommendation propagation.
EOF

cat > "$CLEAN_REPO/docs/standalone-sidecar-clean.md" <<'EOF'
# Standalone External-Intelligence Sidecar Prompt

STANDALONE_EXTERNAL_INTELLIGENCE_SIDECAR
BROAD_STANDALONE_SIDECAR_ACCEPTANCE
DEEP_RESEARCH_SOURCE_LEDGER_V2_ADOPTION
You are an external intelligence receiving a standalone prompt.
You do not have local filesystem access, private repository access, GitHub
issue access, prior chat access, or workspace context beyond what is embedded.
All required context is embedded below.
Public URLs are optional and non-load-bearing.

## Definitions And Glossary

- BMA: Build Meta Analysis, the campaign workspace.
- Prompt A: first pass for clarifying questions and context gaps.
- Prompt B: second pass after actual Prompt A output plus answered context.
- Deep Research: research mode with research targets, source rules, and
  source-ledger response shape.
- Local-aware critique: diagnostics lane that may inspect local files and is not
  standalone sidecar proof.

## Embedded Context

The prompt contains enough context for an external model to answer without
private files, prior chats, or GitHub access. It explains goals, boundaries,
failure modes, integration points, source-ledger v2 fields, and success
criteria.

## Actual Prompt A Output

The model asked for definitions and missing context.

## Answered Context

The operator answered the missing context and embedded it here.

## Research Targets

Research prompt quality and standalone external review patterns.

## Source Rules

Use public sources only and return a source-ledger v2 response shape with
consulted_on_date, exclusion_rationale, and recommendation_effect.

## Response Shape

Return Executive Verdict, Prompt A Reconciliation, Findings, Risks, Source
Ledger, and Next Step.

## Proof

The bundle-only Opus proxy battery accepted 8/8 trials.
Red-team boundary regression validation failed as expected.
The local-aware critique pass had no unresolved CRITICAL or HIGH findings.
A final manual Deep Research transport trial passed.

## Boundary

Sidecar output is advisory and does not close GitHub issues, approve pull
requests, mutate repositories, replace operator judgment, or become closure
truth. No Deep Research API validation is claimed.
No authenticated-source capture validation is claimed.
No sidecar closure truth is claimed. No source registry, crawler, watcher,
controller, scheduler, queue, daemon, automatic ingestion, automatic GitHub
mutation, or auto-merge is authorized.
EOF

cat > "$CLEAN_REPO/docs/subordinate-core-five-validation.md" <<'EOF'
# Subordinate Core-Five Validation

Run repo-auditor against repo-optimizer as a validation target for the core
five. This file intentionally relies on the repo-wide AGENTS.md proving-ground
boundary instead of repeating it locally.
EOF

mkdir -p "$CLEAN_REPO/research/evidence/source-package"
cat > "$CLEAN_REPO/research/evidence/source-package/research-source-manifest.json" <<'EOF'
{
  "sources": [
    {
      "source_id": "operator-source",
      "url_or_ref": "https://example.invalid/source",
      "access_status": "captured"
    }
  ]
}
EOF
cat > "$CLEAN_REPO/research/evidence/source-package/equal-insight-ledger.jsonl" <<'EOF'
{"source_id":"operator-source","insight_disposition":"insight","insight":"Useful source insight."}
EOF
cat > "$CLEAN_REPO/research/evidence/source-package/roadmap-owner-candidate-ledger.csv" <<'EOF'
source_id,disposition,owner_surface
operator-source,owner_surface_candidate,build-meta-analysis
EOF

python3 - "$REPO_ROOT" "$CLEAN_REPO" <<'PY'
import json
import subprocess
import sys

repo_root, clean_repo = sys.argv[1:3]
scripts = {
    "AS-09": "detect-as-cost-without-token-fields.sh",
    "AS-10": "detect-as-cost-model-mismatch.sh",
    "AS-11": "detect-as-request-tool-amplification-gap.sh",
    "AS-12": "detect-as-pricing-provenance-gap.sh",
    "AS-13": "detect-as-copied-evidence-boundary-gap.sh",
    "AS-14": "detect-as-unauthorized-production-default-enablement.sh",
    "AS-15": "detect-as-missing-rollback-control-proof.sh",
    "AS-16": "detect-as-aggregate-only-readiness.sh",
    "AS-17": "detect-as-stale-direct-token-evidence.sh",
    "AS-18": "detect-as-forbidden-public-customernewsletter-mutation.sh",
    "AS-19": "detect-as-source-intelligence-intake-gap.sh",
    "AS-20": "detect-as-selection-handback-recommendation.sh",
    "AS-21": "detect-as-too-small-goal-mode-episode.sh",
    "AS-22": "detect-as-github-native-closure-regrowth.sh",
    "AS-23": "detect-as-owner-surface-ambiguity.sh",
    "AS-24": "detect-as-reciprocal-proving-ground-gap.sh",
    "AS-25": "detect-as-goal-runtime-evidence-gap.sh",
    "AS-26": "detect-as-reactive-self-healing-loop.sh",
    "AS-27": "detect-as-shell-reserved-status-variable.sh",
    "AS-28": "detect-as-stale-default-capability-guidance.sh",
    "AS-29": "detect-as-hermes-foreground-receipt-adoption-gap.sh",
    "AS-30": "detect-as-interrupted-goal-recovery-gap.sh",
    "AS-31": "detect-as-fractured-serial-continuation.sh",
    "AS-32": "detect-as-unanchored-self-learning-claim.sh",
    "AS-33": "detect-as-foreground-failure-guidance-gap.sh",
    "AS-34": "detect-as-closure-run-identity-gap.sh",
    "AS-35": "detect-as-upstream-capability-intake-gap.sh",
    "AS-36": "detect-as-gbrain-instruction-distribution-overclaim.sh",
    "AS-37": "detect-as-issue164-runtime-drift.sh",
    "AS-38": "detect-as-self-authored-campaign-pause-authority.sh",
    "AS-39": "detect-as-scheduled-evidence-boundary-gap.sh",
    "AS-41": "detect-as-campaign-sync-completed-track-gap.sh",
    "AS-42": "detect-as-route-changing-learning-propagation-gap.sh",
    "AS-43": "detect-as-capability-placement-gap.sh",
    "AS-44": "detect-as-hermes-foreground-reliability-evidence-gap.sh",
    "AS-46": "detect-as-deep-research-source-intelligence-native-corpus-gap.sh",
    "AS-48": "detect-as-standalone-external-intelligence-sidecar-gap.sh",
    "AS-49": "detect-as-scheduled-readback-owner-proof-gap.sh",
    "AS-50": "detect-as-hermes-foreground-failure-disposition-gap.sh",
}

for signature_id, script in scripts.items():
    completed = subprocess.run(
        ["bash", f"{repo_root}/scripts/{script}", clean_repo],
        check=True,
        text=True,
        stdout=subprocess.PIPE,
    )
    payload = json.loads(completed.stdout)
    assert payload["ds_id"] == signature_id
    assert payload["fired"] is False, payload
PY

FINAL_ON_REPO="$TMPDIR/as-final-default-on-repo"
mkdir -p "$FINAL_ON_REPO/docs"
cat > "$FINAL_ON_REPO/docs/final-default-left-on.md" <<'EOF'
# Final Default Left On

production_default: true
rollback_receipt: retained
control_receipt: retained
The canary completed, but final_feature_config_mode: default.
EOF

FINAL_OFF_REPO="$TMPDIR/as-final-default-off-repo"
mkdir -p "$FINAL_OFF_REPO/docs"
cat > "$FINAL_OFF_REPO/docs/final-default-off.md" <<'EOF'
# Final Default Rolled Back

production_default: true
rollback_receipt: retained
control_receipt: retained
kill switch tested
disable path verified
final_feature_config_mode: off
EOF

python3 - "$REPO_ROOT" "$FINAL_ON_REPO" "$FINAL_OFF_REPO" <<'PY'
import json
import subprocess
import sys

repo_root, final_on_repo, final_off_repo = sys.argv[1:4]
script = f"{repo_root}/scripts/detect-as-missing-rollback-control-proof.sh"

final_on = subprocess.run(["bash", script, final_on_repo], check=True, text=True, stdout=subprocess.PIPE)
payload = json.loads(final_on.stdout)
assert payload["ds_id"] == "AS-15", payload
assert payload["fired"] is True, payload
assert payload["signals"]["missing_rollback_control_count"] == 1, payload

final_off = subprocess.run(["bash", script, final_off_repo], check=True, text=True, stdout=subprocess.PIPE)
payload = json.loads(final_off.stdout)
assert payload["ds_id"] == "AS-15", payload
assert payload["fired"] is False, payload
assert payload["signals"]["rollback_control_proven_count"] == 1, payload
PY

DEFAULT_CAPABILITY_OWNER_GAP_REPO="$TMPDIR/as-default-capability-owner-gap-repo"
mkdir -p "$DEFAULT_CAPABILITY_OWNER_GAP_REPO/docs"
cat > "$DEFAULT_CAPABILITY_OWNER_GAP_REPO/docs/default-capability.md" <<'EOF'
# Default Capability Owner Gap

Default capability guidance keeps the capability behind a fallback until source
proof, local proof, same-version proof, and upstream main all reconcile. The
validation reconciliation record names upstream_main_sha, local_main_sha,
same_version_proof, source_local_reconciliation, fallback_path, and
validation_receipt, but no owner surface is named for production adoption.
EOF

OPEN_PR_ADOPTION_REPO="$TMPDIR/as-open-pr-adoption-repo"
mkdir -p "$OPEN_PR_ADOPTION_REPO/docs"
cat > "$OPEN_PR_ADOPTION_REPO/docs/open-pr-adoption.md" <<'EOF'
# Open PR Adoption

Default capability guidance: make this capability default in production because
an open PR and unmerged pull request show it works. Treat the PR as enough for
production adoption without upstream main, local proof, same-version proof,
owner surface, fallback path, or validation reconciliation.
EOF

CAPABILITY_GATING_CLEAN_REPO="$TMPDIR/as-capability-gating-clean-repo"
mkdir -p "$CAPABILITY_GATING_CLEAN_REPO/docs"
cat > "$CAPABILITY_GATING_CLEAN_REPO/docs/capability-gating.md" <<'EOF'
# Capability Gating

Do not recommend platform features unless availability is confirmed via target
config or version evidence. If capability is unknown, default to suppress or
allow-with-warning, never confidently allow.
EOF

OPERATIONS_INVENTORY_REPO="$TMPDIR/as-operations-inventory-repo"
mkdir -p "$OPERATIONS_INVENTORY_REPO/docs"
cat > "$OPERATIONS_INVENTORY_REPO/docs/agent-operations.md" <<'EOF'
# Agent Operations

## Detection Signatures

The deterministic signature family includes agent-surface AS-* checks for
Goal-mode runtime evidence gaps, reactive self-healing loops, shell reserved
status-variable launch snippets, stale/default capability guidance,
interruption recovery gaps, fractured serial continuation, and unanchored
self-learning claims.
EOF

python3 - "$REPO_ROOT" "$DEFAULT_CAPABILITY_OWNER_GAP_REPO" "$OPEN_PR_ADOPTION_REPO" "$CAPABILITY_GATING_CLEAN_REPO" "$OPERATIONS_INVENTORY_REPO" <<'PY'
import json
import subprocess
import sys

repo_root, owner_gap_repo, open_pr_repo, capability_gating_repo, operations_inventory_repo = sys.argv[1:6]
script = f"{repo_root}/scripts/detect-as-stale-default-capability-guidance.sh"

owner_gap = subprocess.run(["bash", script, owner_gap_repo], check=True, text=True, stdout=subprocess.PIPE)
payload = json.loads(owner_gap.stdout)
assert payload["ds_id"] == "AS-28", payload
assert payload["fired"] is True, payload
assert payload["signals"]["missing_owner_surface_count"] == 1, payload

open_pr = subprocess.run(["bash", script, open_pr_repo], check=True, text=True, stdout=subprocess.PIPE)
payload = json.loads(open_pr.stdout)
assert payload["ds_id"] == "AS-28", payload
assert payload["fired"] is True, payload
assert payload["signals"]["weak_default_proof_count"] == 1, payload

capability_gating = subprocess.run(["bash", script, capability_gating_repo], check=True, text=True, stdout=subprocess.PIPE)
payload = json.loads(capability_gating.stdout)
assert payload["ds_id"] == "AS-28", payload
assert payload["fired"] is False, payload

operations_inventory = subprocess.run(["bash", script, operations_inventory_repo], check=True, text=True, stdout=subprocess.PIPE)
payload = json.loads(operations_inventory.stdout)
assert payload["ds_id"] == "AS-28", payload
assert payload["fired"] is False, payload
PY

NOISE_REPO="$TMPDIR/as-noise-only-repo"
mkdir -p \
    "$NOISE_REPO/.venv/docs" \
    "$NOISE_REPO/vendor/docs" \
    "$NOISE_REPO/tests/fixtures/as" \
    "$NOISE_REPO/tests"

cat > "$NOISE_REPO/README.md" <<'EOF'
# Noise-only fixture
EOF

cat > "$NOISE_REPO/.venv/docs/cost.md" <<'EOF'
# Virtualenv Cost Evidence

Estimated cost: $88.40 for a synthetic fixture run.
EOF

cat > "$NOISE_REPO/vendor/docs/cost.md" <<'EOF'
# Vendor Cost Evidence

Estimated cost: $88.40 for a synthetic fixture run.
EOF

cat > "$NOISE_REPO/tests/fixtures/as/cost.md" <<'EOF'
# Fixture Cost Evidence

Estimated cost: $88.40 for a synthetic fixture run.
EOF

cat > "$NOISE_REPO/tests/test-as-signatures.sh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' 'Estimated cost: $88.40 for a synthetic fixture run.'
EOF
chmod +x "$NOISE_REPO/tests/test-as-signatures.sh"

python3 - "$REPO_ROOT" "$NOISE_REPO" <<'PY'
import json
import subprocess
import sys

repo_root, noise_repo = sys.argv[1:3]
completed = subprocess.run(
    ["bash", f"{repo_root}/scripts/detect-as-cost-without-token-fields.sh", noise_repo],
    check=True,
    text=True,
    stdout=subprocess.PIPE,
)
payload = json.loads(completed.stdout)
assert payload["ds_id"] == "AS-09", payload
assert payload["fired"] is False, payload
assert payload["signals"]["cost_claim_file_count"] == 0, payload
assert payload["signals"]["cost_without_token_field_count"] == 0, payload
evidence = payload["evidence"]
for filtered_path in [".venv", "vendor", "tests/fixtures", "tests/test-as-signatures.sh"]:
    assert filtered_path not in evidence, payload
PY

echo "=== test-as-signatures.sh: PASS ==="
