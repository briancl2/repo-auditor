#!/usr/bin/env bash
# test-as32-owner-surfaces.sh — AS-32 owner-local self-learning anchors.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

bash "$REPO_ROOT/scripts/detect-as-unanchored-self-learning-claim.sh" "$REPO_ROOT" > "$TMPDIR/as32.json"

python3 - "$TMPDIR/as32.json" "$REPO_ROOT" <<'PY'
import json
import sys
from pathlib import Path

payload = json.load(open(sys.argv[1]))
repo_root = Path(sys.argv[2])
anchored_surfaces = [
    "LEARNINGS.md",
    "docs/live-capability-inventory.md",
    ".agents/improvement-auditor.agent.md",
    ".agents/repo-auditor.agent.md",
]
required_phrases = [
    "github_surface_or_owner_action",
    "raw_evidence",
    "gbrain_slug_or_no_capture_reason",
    "bounded_non_claims",
]

assert payload["ds_id"] == "AS-32", payload
assert payload["fired"] is False, payload
assert payload["signals"]["unanchored_self_learning_claim_count"] == 0, payload

for rel_path in anchored_surfaces:
    text = (repo_root / rel_path).read_text()
    for phrase in required_phrases:
        assert phrase in text, {"path": rel_path, "missing_phrase": phrase}
PY
