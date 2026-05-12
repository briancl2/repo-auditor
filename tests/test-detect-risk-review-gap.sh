#!/usr/bin/env bash
# test-detect-risk-review-gap.sh - Validate DS-48 advisory risk-review gap fixtures.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/detect-risk-review-gap.sh"
TMP_ROOT=$(mktemp -d)
trap 'rm -rf "$TMP_ROOT"' EXIT

write_file() {
  local repo="$1"
  local path="$2"
  mkdir -p "$(dirname "$repo/$path")"
  cat > "$repo/$path"
}

assert_json() {
  local json="$1"
  local python_check="$2"
  printf '%s' "$json" | python3 -c "$python_check"
}

echo "=== DS-48 Risk Review Gap Fixtures ==="

POSITIVE="$TMP_ROOT/broad-review-positive"
mkdir -p "$POSITIVE"
write_file "$POSITIVE" "AGENTS.md" <<'EOF'
# Broad Review Repo

- `make check` runs deterministic validation.
- `make review` is mandatory before every commit.
- All changes must run full LLM review before landing.
EOF
positive_json=$(bash "$SCRIPT" "$POSITIVE")
assert_json "$positive_json" '
import json, sys
data = json.load(sys.stdin)
assert data["ds_id"] == "DS-48"
assert data["fired"] is True
assert data["classification"] == "broad_review_without_risk_route"
assert data["review_required"] is True
assert data["advisory_only"] is True
assert "Advisory only" in data["limitations"]
'
echo "  ✓ broad mandatory review without risk route fires"

HEALTHY="$TMP_ROOT/risk-router-negative"
mkdir -p "$HEALTHY"
write_file "$HEALTHY" "AGENTS.md" <<'EOF'
# Risk-Routed Repo

Review is risk-tiered. Low-risk governed and semi-governed delivery can skip
make review when make quality-gate passes and the maintainer performs a scoped
manual spot-check. Medium-risk and High-risk changes require make review. For
severity, CRITICAL and HIGH findings block, while MEDIUM is advisory unless the
change is High-risk and needs maintainer disposition.
EOF
healthy_json=$(bash "$SCRIPT" "$HEALTHY")
assert_json "$healthy_json" '
import json, sys
data = json.load(sys.stdin)
assert data["fired"] is False
assert data["classification"] == "risk_router_with_severity_policy"
assert data["risk_router_present"] is True
assert data["low_risk_route_present"] is True
assert data["severity_policy_present"] is True
'
echo "  ✓ healthy risk-router negative stays quiet"

EDGE="$TMP_ROOT/behavioral-risk-edge"
mkdir -p "$EDGE"
write_file "$EDGE" "AGENTS.md" <<'EOF'
# Behavioral Risk Repo

Tiny prompt, model, output, schema, and shared contract changes are high-risk.
Behavioral risk changes require a spec, make review, and benchmark evidence
before commit. Documentation-only changes use make check unless they alter
behavior or shared contracts.
EOF
edge_json=$(bash "$SCRIPT" "$EDGE")
assert_json "$edge_json" '
import json, sys
data = json.load(sys.stdin)
assert data["fired"] is False
assert data["classification"] == "risk_router_present"
assert data["risk_router_present"] is True
assert data["high_risk_route_present"] is True
'
echo "  ✓ behavioral-risk edge route stays advisory and quiet"

NO_POLICY="$TMP_ROOT/no-policy"
mkdir -p "$NO_POLICY"
write_file "$NO_POLICY" "README.md" <<'EOF'
# No review policy here
EOF
no_policy_json=$(bash "$SCRIPT" "$NO_POLICY")
assert_json "$no_policy_json" '
import json, sys
data = json.load(sys.stdin)
assert data["fired"] is False
assert data["classification"] == "insufficient_review_policy_to_judge"
assert data["review_required"] is False
'
echo "  ✓ no policy surface does not overclaim"

echo "  VERDICT: PASS"
