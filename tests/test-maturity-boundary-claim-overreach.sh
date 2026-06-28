#!/usr/bin/env bash
# Verify AS-53 detects a domain-capability/autonomy claim that has no co-located
# maturity-class qualifier or bounded non-claim. Read-only; targets are never
# modified.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

OVERCLAIM_REPO="$TMPDIR/maturity-overclaim"
QUALIFIED_REPO="$TMPDIR/maturity-qualified"
NO_CLAIM_REPO="$TMPDIR/maturity-no-claim"
mkdir -p "$OVERCLAIM_REPO/docs" "$QUALIFIED_REPO/docs" "$NO_CLAIM_REPO/docs"

# --- OVERCLAIM: claims domain autonomy with no maturity qualifier ---
cat > "$OVERCLAIM_REPO/README.md" <<'EOF'
# Repo-agent

This repo-agent is fully autonomous and production-ready. It is proven domain
capability: it runs end-to-end autonomous from issue to PR merge with no
operator involvement.
EOF

# --- QUALIFIED: same claim but with a co-located bounded non-claim / maturity class ---
cat > "$QUALIFIED_REPO/README.md" <<'EOF'
# Repo-agent

This repo-agent reached production-ready operating-model maturity.

Bounded non-claim: this is operating-model progress, not domain capability. It
does not prove the note-quality benchmark improved (n=1 only). Readiness is not
the same as capability.
EOF

# --- NO CLAIM: ordinary descriptive docs, no maturity claim at all ---
cat > "$NO_CLAIM_REPO/README.md" <<'EOF'
# Repo-agent

A transcript-to-notes repo-agent. The pipeline reads a transcript and emits a
structured note. See docs for configuration.
EOF

python3 - "$REPO_ROOT" "$OVERCLAIM_REPO" "$QUALIFIED_REPO" "$NO_CLAIM_REPO" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

repo_root, overclaim_repo, qualified_repo, no_claim_repo = map(Path, sys.argv[1:])


def run(repo: Path) -> dict:
    completed = subprocess.run(
        ["bash", str(repo_root / "scripts/detect-as-maturity-boundary-claim-overreach.sh"), str(repo)],
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        raise SystemExit(completed.stderr or completed.stdout)
    return json.loads(completed.stdout)


overclaim = run(overclaim_repo)
assert overclaim["ds_id"] == "AS-53", overclaim
assert overclaim["family"] == "AS", overclaim
assert overclaim["severity"] == "HIGH", overclaim
assert overclaim["fired"] is True, overclaim
assert overclaim["signals"]["maturity_boundary_claim_overreach_count"] >= 1, overclaim

qualified = run(qualified_repo)
assert qualified["ds_id"] == "AS-53", qualified
assert qualified["fired"] is False, qualified
assert qualified["signals"]["maturity_boundary_claim_overreach_count"] == 0, qualified
assert qualified["signals"]["maturity_class_grounded_count"] >= 1, qualified

no_claim = run(no_claim_repo)
assert no_claim["ds_id"] == "AS-53", no_claim
assert no_claim["fired"] is False, no_claim
assert no_claim["signals"]["maturity_boundary_claim_overreach_count"] == 0, no_claim
PY

echo "PASS: AS-53 maturity-boundary claim overreach detector covered"
