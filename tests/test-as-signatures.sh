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

OUTPUT_DIR="$TMPDIR/output"
mkdir -p "$OUTPUT_DIR"

bash "$REPO_ROOT/scripts/detect-new-signatures.sh" "$TEST_REPO" "$OUTPUT_DIR" > "$TMPDIR/run.json"

python3 - "$TMPDIR/run.json" "$OUTPUT_DIR/DS-34-plus-results.json" <<'PY'
import json
import sys

stdout_report = json.load(open(sys.argv[1]))
output_report = json.load(open(sys.argv[2]))

assert stdout_report["repo"] == "as-fixture-repo"
assert stdout_report["capability_metadata"]["family_totals"]["AS"]["total"] == 13
assert output_report["capability_metadata"]["family_totals"]["AS"]["total"] == 13

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
