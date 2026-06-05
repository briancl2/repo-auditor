#!/usr/bin/env bash
# test-closure-identity.sh — Validate local and CI closure-run identity fields.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

LOCAL_STDOUT="$TMPDIR/local.json"
env -u CLOSURE_RUN_ID \
    -u CLOSURE_PHASE \
    -u CLOSURE_TRIGGER \
    -u EVIDENCE_REUSE_KEY \
    -u PARENT_COMMAND \
    -u GITHUB_RUN_ID \
    -u GITHUB_RUN_ATTEMPT \
    -u CLOSURE_IDENTITY_RECEIPT_PATH \
    python3 "$REPO_ROOT/scripts/closure_identity.py" \
    --phase check \
    --parent-command "make check" > "$LOCAL_STDOUT"

python3 - "$LOCAL_STDOUT" "$TMPDIR" <<'PY'
import json
import re
import sys
from pathlib import Path

payload = json.load(open(sys.argv[1]))
tmpdir = Path(sys.argv[2])

assert re.match(r"^local-\d{8}T\d{6}Z-\d+$", payload["closure_run_id"]), payload
assert payload["closure_phase"] == "check", payload
assert payload["closure_trigger"] == "manual", payload
assert payload["evidence_reuse_key"] == "check:make check", payload
assert payload["parent_command"] == "make check", payload
assert payload["github_run_id"] is None, payload
assert payload["github_run_attempt"] is None, payload
assert list(tmpdir.iterdir()) == [Path(sys.argv[1])], sorted(tmpdir.iterdir())
PY

CI_STDOUT="$TMPDIR/ci.json"
CI_RECEIPT="$TMPDIR/receipt/closure-identity.json"
CLOSURE_RUN_ID="12345-2" \
CLOSURE_PHASE="test" \
CLOSURE_TRIGGER="pull_request" \
EVIDENCE_REUSE_KEY="test:12345-2" \
PARENT_COMMAND="make test" \
GITHUB_RUN_ID="12345" \
GITHUB_RUN_ATTEMPT="2" \
CLOSURE_IDENTITY_RECEIPT_PATH="$CI_RECEIPT" \
    python3 "$REPO_ROOT/scripts/closure_identity.py" --phase ignored --parent-command ignored > "$CI_STDOUT"

python3 - "$CI_STDOUT" "$CI_RECEIPT" <<'PY'
import json
import sys

stdout_payload = json.load(open(sys.argv[1]))
receipt_payload = json.load(open(sys.argv[2]))
assert stdout_payload == receipt_payload, (stdout_payload, receipt_payload)
assert receipt_payload == {
    "closure_run_id": "12345-2",
    "closure_phase": "test",
    "closure_trigger": "pull_request",
    "evidence_reuse_key": "test:12345-2",
    "parent_command": "make test",
    "github_run_id": "12345",
    "github_run_attempt": "2",
}, receipt_payload
PY

AS34_OUTPUT="$TMPDIR/as34.json"
bash "$REPO_ROOT/scripts/detect-as-closure-run-identity-gap.sh" "$REPO_ROOT" > "$AS34_OUTPUT"
python3 - "$AS34_OUTPUT" <<'PY'
import json
import sys

payload = json.load(open(sys.argv[1]))
assert payload["ds_id"] == "AS-34", payload
assert payload["fired"] is False, payload
assert payload["signals"]["local_identity_surface_count"] >= 1, payload
assert payload["signals"]["remote_identity_surface_count"] >= 1, payload
PY
