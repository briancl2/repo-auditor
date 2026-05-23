#!/usr/bin/env bash
# test-auditor-schemas.sh — Validate all JSON schemas in the repo
set -euo pipefail

AUDITOR_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

echo "=== Auditor Schema Validation ==="

validate_fixture() {
  local schema="$1"
  local fixture="$2"
  local expected="$3"
  local label="$4"

  if python3 - "$schema" "$fixture" "$expected" <<'PY'
import json
import sys

import jsonschema

schema_path, fixture_path, expected = sys.argv[1:4]
with open(schema_path, "r", encoding="utf-8") as handle:
    schema = json.load(handle)
with open(fixture_path, "r", encoding="utf-8") as handle:
    instance = json.load(handle)

jsonschema.Draft7Validator.check_schema(schema)
validator = jsonschema.Draft7Validator(schema)
errors = sorted(validator.iter_errors(instance), key=lambda item: item.path)
valid = not errors

if expected == "pass" and valid:
    sys.exit(0)
if expected == "fail" and not valid:
    sys.exit(0)

if errors:
    print(errors[0].message)
else:
    print("fixture unexpectedly passed validation")
sys.exit(1)
PY
  then
    echo "  ✓ $label"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $label"
    FAIL=$((FAIL + 1))
  fi
}

for schema in "$AUDITOR_DIR/schemas"/*.schema.json; do
  NAME="$(basename "$schema")"
  if python3 -c "import json; json.load(open('$schema'))" 2>/dev/null; then
    echo "  ✓ $NAME"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $NAME — INVALID"
    FAIL=$((FAIL + 1))
  fi
done

echo ""
echo "=== FINDINGS fixture validation ==="

validate_fixture "$AUDITOR_DIR/schemas/FINDINGS.schema.json" \
  "$AUDITOR_DIR/tests/fixtures/findings-schema/legacy-valid.json" \
  pass "legacy findings fixture remains valid"
validate_fixture "$AUDITOR_DIR/schemas/FINDINGS.schema.json" \
  "$AUDITOR_DIR/tests/fixtures/findings-schema/action-tuple-valid.json" \
  pass "action tuple findings fixture is valid"
validate_fixture "$AUDITOR_DIR/schemas/FINDINGS.schema.json" \
  "$AUDITOR_DIR/tests/fixtures/findings-schema/action-tuple-invalid-type.json" \
  fail "invalid action tuple type is rejected"

echo ""
echo "  PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -gt 0 ]; then
  echo "  VERDICT: FAIL"
  exit 1
fi
echo "  VERDICT: PASS"
