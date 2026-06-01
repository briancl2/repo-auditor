#!/usr/bin/env bash
# Verify bounded AS-20..AS-29 replay keeps direct GitHub closure clean.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

CLEAN_REPO="$TMPDIR/direct-campaign-closure"
REGROWTH_REPO="$TMPDIR/retained-closeout-regrowth"
OUTPUT_DIR="$TMPDIR/replay-output"

mkdir -p "$CLEAN_REPO/docs" "$REGROWTH_REPO/docs"

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

cat > "$REGROWTH_REPO/docs/retained-local-closeout.md" <<'EOF'
# Retained Local Closeout Regrowth

Issue #401 is closed by PR #402 and the pull request is merged, but the local
completion manifest remains the authoritative closeout and work-close is still
required as the closure authority.
EOF

python3 "$REPO_ROOT/scripts/replay-work-management-signatures.py" \
    --repo direct="$CLEAN_REPO" \
    --repo retained="$REGROWTH_REPO" \
    --output-dir "$OUTPUT_DIR" > "$TMPDIR/stdout.json"

python3 - "$OUTPUT_DIR/AS_WORK_MANAGEMENT_REPLAY.json" "$TMPDIR/stdout.json" <<'PY'
import json
import sys

from_file = json.load(open(sys.argv[1]))
from_stdout = json.load(open(sys.argv[2]))
assert from_file == from_stdout
assert from_file["signature_ids"] == [f"AS-{index}" for index in range(20, 30)]
assert from_file["target_count"] == 2

targets = {target["name"]: target for target in from_file["targets"]}
direct = targets["direct"]
retained = targets["retained"]

assert direct["closure_regrowth_fired"] is False, direct
assert "AS-22" not in direct["fired_ids"], direct
assert direct["github_native_closeout_bypassed_count"] >= 1, direct

assert retained["closure_regrowth_fired"] is True, retained
assert "AS-22" in retained["fired_ids"], retained
assert retained["closure_regrowth_count"] == 1, retained

assert from_file["closure_regrowth_target_count"] == 1
assert from_file["error_target_count"] == 0
assert any("read-only" in claim for claim in from_file["bounded_non_claims"])
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
