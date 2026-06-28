#!/usr/bin/env bash
# Verify AS-52 detects a repo-agent under assimilation that has no
# repo-anthropology surface (purpose + use-cases/deliverables + defined-vs-revealed
# principles). Read-only; targets are never modified.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

GAP_REPO="$TMPDIR/anthropology-gap"
PRESENT_REPO="$TMPDIR/anthropology-present"
NAMED_REPO="$TMPDIR/anthropology-named"
NON_AGENT_REPO="$TMPDIR/anthropology-non-agent"
mkdir -p "$GAP_REPO/.specify/memory" "$GAP_REPO/docs"
mkdir -p "$PRESENT_REPO/docs"
mkdir -p "$NAMED_REPO/docs"
mkdir -p "$NON_AGENT_REPO/src"

# --- GAP: repo-agent context (constitution + AGENTS) but NO anthropology surface ---
cat > "$GAP_REPO/AGENTS.md" <<'EOF'
# AGENTS.md

This repo-agent operates under an operating model. Startup reads this file.
EOF
cat > "$GAP_REPO/.specify/memory/constitution.md" <<'EOF'
# Constitution

P1 Engineering rigor for the domain.
EOF
cat > "$GAP_REPO/docs/notes.md" <<'EOF'
# Notes

Assorted implementation notes. No purpose/use-case/principle-duality record here.
EOF

# --- PRESENT: a real anthropology surface co-locating the three field groups ---
cat > "$PRESENT_REPO/AGENTS.md" <<'EOF'
# AGENTS.md

Repo-agent operating model startup surface.
EOF
cat > "$PRESENT_REPO/docs/assimilation-anthropology.md" <<'EOF'
# Assimilation anthropology

## Purpose
The purpose of this repo is to generate meeting notes from transcripts.

## Use cases and deliverables
Primary use-case: a reviewer pastes a transcript. Primary deliverable: a note.
Consumers: the meeting owner and attendees.

## Principles
Defined principles: rigor, determinism. Revealed principles (observed in
practice): reviewers value conciseness over completeness. This captures the
revealed-vs-defined principle duality before any repair was selected.
EOF

# --- NAMED: a surface explicitly named as repo-anthropology (short-circuit match) ---
cat > "$NAMED_REPO/AGENTS.md" <<'EOF'
# AGENTS.md

Operating model startup surface for this repo-agent.
EOF
cat > "$NAMED_REPO/docs/repo-anthropology.md" <<'EOF'
# Repo anthropology

A concise repo-anthropology record for this repo-agent.
EOF

# --- NON-AGENT: an ordinary library, no repo-agent context at all ---
cat > "$NON_AGENT_REPO/src/lib.py" <<'EOF'
def add(a, b):
    return a + b
EOF
cat > "$NON_AGENT_REPO/README.md" <<'EOF'
# tinylib

A tiny arithmetic library.
EOF

python3 - "$REPO_ROOT" "$GAP_REPO" "$PRESENT_REPO" "$NAMED_REPO" "$NON_AGENT_REPO" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

repo_root, gap_repo, present_repo, named_repo, non_agent_repo = map(Path, sys.argv[1:])


def run(repo: Path) -> dict:
    completed = subprocess.run(
        ["bash", str(repo_root / "scripts/detect-as-missing-repo-anthropology-surface.sh"), str(repo)],
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        raise SystemExit(completed.stderr or completed.stdout)
    return json.loads(completed.stdout)


gap = run(gap_repo)
assert gap["ds_id"] == "AS-52", gap
assert gap["family"] == "AS", gap
assert gap["severity"] == "MEDIUM", gap
assert gap["fired"] is True, gap
assert gap["signals"]["assimilation_context_present"] is True, gap
assert gap["signals"]["repo_anthropology_surface_present"] is False, gap
assert gap["signals"]["missing_repo_anthropology_surface_count"] == 1, gap

present = run(present_repo)
assert present["ds_id"] == "AS-52", present
assert present["fired"] is False, present
assert present["signals"]["repo_anthropology_surface_present"] is True, present

named = run(named_repo)
assert named["ds_id"] == "AS-52", named
assert named["fired"] is False, named
assert named["signals"]["repo_anthropology_surface_present"] is True, named

non_agent = run(non_agent_repo)
assert non_agent["ds_id"] == "AS-52", non_agent
assert non_agent["fired"] is False, non_agent
assert non_agent["signals"]["assimilation_context_present"] is False, non_agent
PY

echo "PASS: AS-52 missing repo-anthropology surface detector covered"
