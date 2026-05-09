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

cat > "$TEST_REPO/docs/model-effort-binding-gap.md" <<'EOF'
# Model/Effort Binding Gap

The gpt-5.5 high reasoning effort cell proves lower token cost and better quality.
model_effort_binding: missing
session_binding: missing
EOF

cat > "$TEST_REPO/docs/stale-copilot-reporting-reuse.md" <<'EOF'
# Stale Copilot Reporting Reuse

The same Copilot report was reused across model/version/effort cells in the matrix.
model cells: gpt-5.5, gpt-5.4
copilot_version cells: 1.0.44, 1.0.45
reasoning_effort cells: low, high
current_copilot_version: missing
per_cell_receipts: missing
EOF

cat > "$TEST_REPO/docs/promotion-noise-floor-gap.md" <<'EOF'
# Promotion Noise Floor Gap

Promoted the model route to production readiness from control noise floor evidence.
control_noise_floor_n: 1
current_noise_floor: missing
EOF

cat > "$TEST_REPO/docs/model-recommendation-leakage.md" <<'EOF'
# Model Recommendation Leakage

Recommended model: claude-sonnet-4.6 for the next production route.
production_confirmation_receipt: missing
EOF

cat > "$TEST_REPO/docs/phase-attribution-alias-gap.md" <<'EOF'
# Phase Attribution Alias Gap

The phase1b_xcode phase attribution proves pre-phase token growth and cost growth.
largest_positive_phase_delta: phase1b_xcode
phase_label_semantics: []
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
assert stdout_report["capability_metadata"]["family_totals"]["AS"]["total"] == 23
assert output_report["capability_metadata"]["family_totals"]["AS"]["total"] == 23

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
}

# This fixture is intentionally engineered to trip every AS detector once so the
# smoke test proves the full owner-surface family is wired and addressable.
fired = {item["ds_id"] for item in output_report["results"] if item.get("family") == "AS" and item.get("fired")}
assert fired == as_ids
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

cat > "$CLEAN_REPO/docs/model-reasoning-guardrails.md" <<EOF
# Model Reasoning Guardrails

The gpt-5.5 high reasoning effort cell has an exact model_effort_binding: exact.
prompt/session binding: exact
bound_candidate_count: 1
prompt_sha256: abc123
session_log_sha256: def456

Copilot reporting is regenerated per cell with current_copilot_version: GitHub Copilot CLI 1.0.44.
per_cell_receipts: cell-a, cell-b, cell-c
No reuse across model/version/effort cells.

Promotion is allowed only with a current control noise floor.
current control_noise_floor_n: 3
as_of: $(date +%F)

No model recommendation is made from this evidence.
production_confirmation_receipt: retained pass

Recommendation: update the docs after the evidence packet is retained.

Phase attribution is grounded with phase_label_semantics: multi_artifact_phase1b_retrieval_alias.
The phase1b_xcode label is the Phase 1B retrieval command boundary, not an isolated Xcode-only request.
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
    "AS-19": "detect-as-model-effort-binding-gap.sh",
    "AS-20": "detect-as-stale-copilot-reporting-reuse.sh",
    "AS-21": "detect-as-promotion-without-control-noise-floor.sh",
    "AS-22": "detect-as-model-recommendation-before-production-confirmation.sh",
    "AS-23": "detect-as-phase-attribution-alias-gap.sh",
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

echo "=== test-as-signatures.sh: PASS ==="
