#!/usr/bin/env bash
# Verify AS-51 detects a repo-agent that has a constitution and scattered
# operating-model point-repairs but no imported-canon + reconciliation/gap-matrix
# alignment anchor. Read-only; targets are never modified.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

GAP_REPO="$TMPDIR/anchor-gap"
ANCHORED_REPO="$TMPDIR/anchor-present"
NO_CONSTITUTION_REPO="$TMPDIR/anchor-no-constitution"
SINGLE_REF_REPO="$TMPDIR/anchor-single-ref"
mkdir -p "$GAP_REPO/.specify/memory" "$GAP_REPO/docs"
mkdir -p "$ANCHORED_REPO/.specify/memory" "$ANCHORED_REPO/docs"
mkdir -p "$NO_CONSTITUTION_REPO/docs"
mkdir -p "$SINGLE_REF_REPO/.specify/memory" "$SINGLE_REF_REPO/docs"

# --- GAP: constitution + scattered operating-model point-repairs, NO anchor ---
cat > "$GAP_REPO/.specify/memory/constitution.md" <<'EOF'
# Constitution

P1 Engineering rigor. P2 Deterministic builds. The domain principles for note
generation and transcript analysis are codified here.
EOF
cat > "$GAP_REPO/docs/work-close-gate.md" <<'EOF'
# Work-close gate

A fail-closed work-closure gate proves review, critique, and hypothesis before
a code-change contract may close.
EOF
cat > "$GAP_REPO/docs/ci-and-automation.md" <<'EOF'
# Automation health

CI concurrency control and automation authority earn their place gradually. The
grounded route-change convention requires a fallback and a runtime ref.
GitHub truth (issue/PR/check/merge state) is canonical for closure.
EOF

# --- ANCHORED: same point-repairs PLUS an imported-canon + reconciliation anchor ---
cat > "$ANCHORED_REPO/.specify/memory/constitution.md" <<'EOF'
# Constitution

P1 Engineering rigor. Work-closure proof and fail-closed gates are codified.
GitHub truth is canonical. Automation authority is earned gradually.
EOF
cat > "$ANCHORED_REPO/docs/operating-model-alignment-anchor.md" <<'EOF'
# Operating-model alignment anchor

This repo imported an operating-model principle canon and reconciled the
revealed-vs-defined principles against it.

## Principle gap matrix (reconciliation table)

| Principle | Revealed (observed) | Defined (canon) | Status |
| --- | --- | --- | --- |
| Work-closure proof | scattered point-repair | imported canon | reconciled |
| Automation authority | scattered point-repair | imported canon | reconciled |
| Grounded route-change | scattered point-repair | imported canon | reconciled |
EOF
cat > "$ANCHORED_REPO/docs/automation.md" <<'EOF'
# Automation health

Automation authority is earned gradually; grounded route-change requires a
fallback and runtime ref.
EOF

# --- NO CONSTITUTION: operating-model refs but no constitution surface ---
cat > "$NO_CONSTITUTION_REPO/docs/automation.md" <<'EOF'
# Automation health

Work-closure and automation authority and grounded route-change and GitHub truth
are all discussed, but there is no constitution surface in this repo.
EOF

# --- SINGLE REF: constitution but only one scattered operating-model reference ---
cat > "$SINGLE_REF_REPO/.specify/memory/constitution.md" <<'EOF'
# Constitution

P1 Engineering rigor for the domain.
EOF
cat > "$SINGLE_REF_REPO/docs/notes.md" <<'EOF'
# Notes

A single mention of fail-closed work-closure appears here and nowhere else.
EOF

python3 - "$REPO_ROOT" "$GAP_REPO" "$ANCHORED_REPO" "$NO_CONSTITUTION_REPO" "$SINGLE_REF_REPO" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

repo_root, gap_repo, anchored_repo, no_constitution_repo, single_ref_repo = map(Path, sys.argv[1:])


def run(repo: Path) -> dict:
    completed = subprocess.run(
        ["bash", str(repo_root / "scripts/detect-as-missing-operating-model-alignment-anchor.sh"), str(repo)],
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        raise SystemExit(completed.stderr or completed.stdout)
    return json.loads(completed.stdout)


gap = run(gap_repo)
assert gap["ds_id"] == "AS-51", gap
assert gap["family"] == "AS", gap
assert gap["severity"] == "HIGH", gap
assert gap["fired"] is True, gap
assert gap["signals"]["constitution_present"] is True, gap
assert gap["signals"]["scattered_operating_model_ref_count"] > 1, gap
assert gap["signals"]["alignment_anchor_artifact_present"] is False, gap
assert gap["signals"]["missing_operating_model_alignment_anchor_count"] == 1, gap

anchored = run(anchored_repo)
assert anchored["ds_id"] == "AS-51", anchored
assert anchored["fired"] is False, anchored
assert anchored["signals"]["alignment_anchor_artifact_present"] is True, anchored
assert anchored["signals"]["missing_operating_model_alignment_anchor_count"] == 0, anchored

no_constitution = run(no_constitution_repo)
assert no_constitution["ds_id"] == "AS-51", no_constitution
assert no_constitution["fired"] is False, no_constitution
assert no_constitution["signals"]["constitution_present"] is False, no_constitution

single_ref = run(single_ref_repo)
assert single_ref["ds_id"] == "AS-51", single_ref
assert single_ref["fired"] is False, single_ref
assert single_ref["signals"]["constitution_present"] is True, single_ref
assert single_ref["signals"]["scattered_operating_model_ref_count"] <= 1, single_ref
PY

echo "PASS: AS-51 missing operating-model alignment anchor detector covered"
