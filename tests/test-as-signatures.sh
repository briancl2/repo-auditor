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
assert stdout_report["capability_metadata"]["family_totals"]["AS"]["total"] == 28
assert output_report["capability_metadata"]["family_totals"]["AS"]["total"] == 28

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
}

# This fixture is intentionally engineered to trip every AS detector once so the
# smoke test proves the full owner-surface family is wired and addressable.
fired = {item["ds_id"] for item in output_report["results"] if item.get("family") == "AS" and item.get("fired")}
assert fired == as_ids
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
EOF

LIVE_WORK_MANAGEMENT_REPO="$TMPDIR/as-work-management-live-repo"
mkdir -p "$LIVE_WORK_MANAGEMENT_REPO/docs"
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
status-variable launch snippets, and stale/default capability guidance.
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
