#!/usr/bin/env bash
# validate-floor-receipt.sh — Canonical static conformance validator for a
# repo-agent fleet consistency-floor receipt.
#
# Usage: bash validate-floor-receipt.sh <receipt-path>
#   Default receipt path when omitted:
#     docs/repo-agent-fleet-consistency-floor-receipt.md
#
# Read-only, no network. Asserts (exits non-zero on the first failure):
#   1. File exists.
#   2. Prose declares floor v0.2 (contains "v0.2").
#   3. Contains exactly one fenced ```json block that parses as valid JSON.
#   4. JSON schema_version == 1.
#   5. ci_check_contract.branch_protection_required_checks is a non-empty array.
#   6. domain_outcome_delta is present and has a result_class.
#
# On success prints: OK: <path> conforms to floor v0.2
#
# CANONICAL COPY: this file lives in briancl2/repo-agent-core. The four consumer
# repos (repo-upgrade-advisor, repo-optimizer, repo-auditor, build-meta-analysis)
# vendor a byte-identical copy via copy-sync (BMA #1214 Phase 4 item b). Keep the
# copies byte-identical; scripts/fleet-floor-conformance-audit.sh flags drift.

set -euo pipefail

RECEIPT_PATH="${1:-docs/repo-agent-fleet-consistency-floor-receipt.md}"

python3 - "$RECEIPT_PATH" <<'PY'
import json
import re
import sys

path = sys.argv[1]


def fail(msg):
    print(f"FAIL: {path}: {msg}", file=sys.stderr)
    sys.exit(1)


# 1. File exists.
try:
    with open(path, encoding="utf-8") as fh:
        text = fh.read()
except FileNotFoundError:
    fail("receipt file does not exist")
except OSError as exc:
    fail(f"cannot read receipt file: {exc}")

# 2. Prose declares floor v0.2.
if "v0.2" not in text:
    fail("prose does not declare floor v0.2 (no 'v0.2' found)")

# 3. Exactly one fenced json block that parses.
blocks = re.findall(r"```json\s*(.*?)```", text, re.DOTALL)
if len(blocks) != 1:
    fail(f"expected exactly one fenced ```json block, found {len(blocks)}")
try:
    data = json.loads(blocks[0])
except json.JSONDecodeError as exc:
    fail(f"fenced json block does not parse: {exc}")
if not isinstance(data, dict):
    fail("fenced json block is not a JSON object")

# 4. schema_version == 1.
if data.get("schema_version") != 1:
    fail(f"schema_version must be 1, got {data.get('schema_version')!r}")

# 5. ci_check_contract.branch_protection_required_checks non-empty array.
cic = data.get("ci_check_contract")
if not isinstance(cic, dict):
    fail("ci_check_contract is missing or not an object")
checks = cic.get("branch_protection_required_checks")
if not isinstance(checks, list) or len(checks) == 0:
    fail("ci_check_contract.branch_protection_required_checks must be a non-empty array")

# 6. domain_outcome_delta present with a result_class.
dod = data.get("domain_outcome_delta")
if not isinstance(dod, dict):
    fail("domain_outcome_delta (dimension 7) is missing or not an object")
if not dod.get("result_class"):
    fail("domain_outcome_delta.result_class is missing or empty")

print(f"OK: {path} conforms to floor v0.2")
PY
