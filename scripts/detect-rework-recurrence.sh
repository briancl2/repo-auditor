#!/usr/bin/env bash
# detect-rework-recurrence.sh — DS-49: Re-work recurrence / post-finalize churn
# Git-observable, read-only detector for work that was declared "done" and then
# had to be re-worked. Fires when a SUBSTANTIVE file (code / tests / schemas /
# specs / config) that a finalize/closeout/issue-close commit touched is
# re-modified shortly afterward by a CORRECTIVE (fix/revert/redo/regress) commit.
#
# Precision design (low false-positive):
#   1. Finalize is classified from the finalize ACT (subject-initial closeout
#      verb, "mark as done", "work complete", "closeout the {work,issue,task}",
#      or "(close|fix|resolve) #N") — NOT topic mentions of the words
#      "closeout"/"finalize", which appear as subject matter in closure-aware
#      repos.
#   2. Ceremony/doc/tracking files (docs/**, work/**, LEARNINGS.md, AGENTS.md,
#      README.md, .specify/**, research/**) are excluded from finalized areas;
#      they legitimately change on every closeout.
#   3. A recurrence is only counted when the re-touch commit itself carries
#      CORRECTIVE-rework vocabulary — so normal incremental additions
#      ("Add feature 2") that happen to touch a shared file are NOT rework.
#
# This is git-history observable and therefore LIVE-CHECKOUT ONLY: it no-ops
# (fires:false, signal:no-git/insufficient-data) on snapshot-mode inputs, which
# collapse to a single synthetic clean-HEAD commit.
#
# n=1 keep-candidate: graduation requires a confirmed fire on a 2nd distinct repo.
#
# Usage: bash scripts/detect-rework-recurrence.sh <repo_path> \
#          [--commits N] [--window-commits N] [--window-days N] \
#          [--area-threshold N] [--intensity-threshold N]
# Always emits a single JSON object and exits 0 (diagnostic-safe for the sweep).

set -euo pipefail

REPO="${1:?Usage: detect-rework-recurrence.sh <repo_path> [--commits N] [--window-commits N] [--window-days N] [--area-threshold N] [--intensity-threshold N]}"
shift
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

python3 - "$REPO" "$SCRIPT_DIR" "$@" <<'PY'
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

repo = Path(sys.argv[1]).resolve()
script_dir = sys.argv[2]
args = sys.argv[3:]

commits = 100
window_commits = 10
window_days = 30
area_threshold = 2
intensity_threshold = 2

_i = 0
while _i < len(args):
    key = args[_i]
    val = args[_i + 1] if _i + 1 < len(args) else None
    if key == "--commits" and val is not None:
        commits = int(val); _i += 2
    elif key == "--window-commits" and val is not None:
        window_commits = int(val); _i += 2
    elif key == "--window-days" and val is not None:
        window_days = int(val); _i += 2
    elif key == "--area-threshold" and val is not None:
        area_threshold = int(val); _i += 2
    elif key == "--intensity-threshold" and val is not None:
        intensity_threshold = int(val); _i += 2
    else:
        _i += 1

BASE = {
    "ds_id": "DS-49",
    "name": "Re-work recurrence",
    "severity": "MEDIUM",
    "prevention_tier": "T2",
}


def emit(payload: dict[str, object]) -> None:
    helper = Path(script_dir) / "ds_json_helper.py"
    call = [sys.executable, str(helper), json.dumps(BASE)]
    for key, value in payload.items():
        if isinstance(value, bool):
            rendered = "true" if value else "false"
        elif isinstance(value, list):
            rendered = ",".join(str(item) for item in value)
        else:
            rendered = str(value)
        call.append(f"{key}={rendered}")
    proc = subprocess.run(call, check=True, capture_output=True, text=True)
    sys.stdout.write(proc.stdout)


def git(*a: str) -> subprocess.CompletedProcess:
    return subprocess.run(
        ["git", "-C", str(repo), *a],
        capture_output=True,
        text=True,
    )


# ── Finalize ACT classifier (subject line) ───────────────────────────────
# Anchored to the ACT of finalizing, not topic mentions of "closeout"/"finalize".
FINALIZE_PATTERN = re.compile(
    r"^\s*(closeout|close[- ]out|finaliz(?:e|es|ed|ing)|wrap[- ]?up|sign[- ]?off)\b"
    r"|\bmark(?:ed|s|ing)?\s+(?:as\s+)?(?:done|complete|completed|resolved)\b"
    r"|\b(?:work|task|epic|milestone|feature|story|issue|pr)\s+(?:is\s+)?"
    r"(?:complete|completed|done|finaliz(?:ed|ing)|closed[- ]out)\b"
    r"|\bclose[- ]?out(?:s|ing)?\s+(?:the\s+)?"
    r"(?:work|task|epic|milestone|feature|story|issue|pr)\b"
    r"|\b(?:clos(?:e|es|ed)|fix(?:es|ed)?|resolv(?:e|es|ed))\s+#\d+\b",
    re.IGNORECASE,
)

# ── Corrective-rework classifier (subject line) ──────────────────────────
REWORK_PATTERN = re.compile(
    r"\b(fix(?:es|ed|up)?|hotfix|revert(?:s|ed)?|re-?work(?:s|ed|ing)?|"
    r"re-?do(?:es|ne)?|redo|reopen(?:s|ed|ing)?|regress(?:es|ed|ion)?|"
    r"broke(?:n)?|breakage|correct(?:s|ed|ion|ing)?|patch(?:es|ed|ing)?|"
    r"amend(?:s|ed|ing)?|un-?finish(?:ed)?)\b"
    r"|\bstill\s+(?:failing|broken|not\s+work)"
    r"|\bdidn'?t\s+work\b|\bnot\s+(?:actually\s+)?done\b",
    re.IGNORECASE,
)

_CODE_EXT = (
    ".py", ".js", ".ts", ".tsx", ".jsx", ".mjs", ".cjs", ".go", ".rs",
    ".rb", ".java", ".c", ".cc", ".cpp", ".h", ".hpp", ".sh", ".bash",
)


def is_substantive(path: str) -> bool:
    """Direct product/code/test/schema/spec/config surfaces. Ceremony, docs,
    tracking, and root prose are intentionally excluded (they legitimately churn
    on every closeout and would create false positives)."""
    p = path
    if p.startswith(("docs/", "work/", "research/", ".specify/")):
        return False
    if p.startswith("scripts/") and (p.endswith(".sh") or p.endswith(".py")):
        return True
    if p.startswith(("tests/", "schemas/", "config/", "templates/")):
        return True
    if p.startswith(".github/workflows/"):
        return True
    if p.startswith("specs/") and p.endswith(
        ("/spec.md", "/plan.md", "/tasks.md")
    ):
        return True
    if p.startswith(".agents/") and (
        p.endswith("/SKILL.md") or p.endswith(".agent.md") or "/scripts/" in p
    ):
        return True
    if p == "Makefile":
        return True
    return p.endswith(_CODE_EXT)


if not repo.is_dir():
    emit({
        "fired": False,
        "signal": "repo-not-found",
        "commits_analyzed": 0,
        "reason": "repo path is not a directory",
        "evidence": "repo not found",
    })
    raise SystemExit(0)

work_tree = git("rev-parse", "--is-inside-work-tree")
if work_tree.returncode != 0 or work_tree.stdout.strip() != "true":
    emit({
        "fired": False,
        "signal": "no-git",
        "commits_analyzed": 0,
        "reason": "target is not a git work tree; git-observable signal is live-checkout only",
        "evidence": "not a git work tree",
    })
    raise SystemExit(0)

log = git("log", f"-{commits}", "--format=%H%x1f%ct%x1f%s")
parsed: list[tuple[str, int, str]] = []
for line in log.stdout.split("\n"):
    if not line.strip():
        continue
    fields = line.split("\x1f")
    if len(fields) < 3:
        continue
    sha = fields[0]
    try:
        ctime = int(fields[1])
    except ValueError:
        ctime = 0
    subject = "\x1f".join(fields[2:])
    parsed.append((sha, ctime, subject))

# git log is newest-first; reverse to chronological oldest -> newest so that
# "after finalize" is a forward scan.
parsed.reverse()
n = len(parsed)

MIN_COMMITS = 3
if n < MIN_COMMITS:
    emit({
        "fired": False,
        "signal": "insufficient-data",
        "commits_analyzed": n,
        "reason": f"fewer than {MIN_COMMITS} commits; git-observable signal is live-checkout only",
        "evidence": "insufficient history",
    })
    raise SystemExit(0)


def files_of(sha: str) -> set[str]:
    result = git("diff-tree", "--root", "--no-commit-id", "--name-only", "-r", sha)
    return {f for f in result.stdout.split("\n") if f.strip()}


all_files = [files_of(sha) for sha, _, _ in parsed]
subst_files = [{f for f in fl if is_substantive(f)} for fl in all_files]
finalize_idx = [i for i, (_, _, subj) in enumerate(parsed) if FINALIZE_PATTERN.search(subj)]

# Count post-finalize corrective re-touches per finalized substantive path.
recur_pairs: set[tuple[str, int]] = set()
finalize_example: dict[str, str] = {}
rework_example: dict[str, str] = {}
for fi in finalize_idx:
    fct = parsed[fi][1]
    jmax = min(n - 1, fi + window_commits)
    for path in subst_files[fi]:
        for j in range(fi + 1, jmax + 1):
            if path not in all_files[j]:
                continue
            if not REWORK_PATTERN.search(parsed[j][2]):
                continue
            if window_days > 0 and (parsed[j][1] - fct) > window_days * 86400:
                continue
            recur_pairs.add((path, j))
            finalize_example.setdefault(path, parsed[fi][0][:8])
            rework_example.setdefault(path, parsed[j][0][:8])

area_recurrence: dict[str, int] = {}
for path, _ in recur_pairs:
    area_recurrence[path] = area_recurrence.get(path, 0) + 1

recurring_area_count = sum(1 for c in area_recurrence.values() if c >= 1)
max_area = max(area_recurrence.values(), default=0)
total_hits = sum(area_recurrence.values())
fired = recurring_area_count >= area_threshold or max_area >= intensity_threshold

top = sorted(area_recurrence.items(), key=lambda kv: (-kv[1], kv[0]))[:5]
evidence_parts = [
    f"{path} x{count} (final@{finalize_example.get(path, '?')} rework@{rework_example.get(path, '?')})"
    for path, count in top
]
if not evidence_parts:
    if not finalize_idx:
        evidence_parts = ["no finalize/closeout/issue-close commits in analyzed window"]
    else:
        evidence_parts = [
            f"{len(finalize_idx)} finalize commit(s); no post-finalize corrective re-touch above thresholds"
        ]

if fired:
    signal = "rework-recurrence"
    reason = "finalized area(s) re-worked by corrective commits shortly after finalize/closeout — declared-done work recurred"
elif not finalize_idx:
    signal = "no-finalize-commits"
    reason = "no finalize/closeout/issue-close commits observed in the analyzed window"
else:
    signal = "within-tolerance"
    reason = "finalized areas did not exceed re-work recurrence thresholds"

emit({
    "fired": fired,
    "signal": signal,
    "commits_analyzed": n,
    "finalize_commit_count": len(finalize_idx),
    "recurring_area_count": recurring_area_count,
    "max_area_rework_recurrence": max_area,
    "rework_recurrence_hits": total_hits,
    "window_commits": window_commits,
    "window_days": window_days,
    "area_threshold": area_threshold,
    "intensity_threshold": intensity_threshold,
    "evidence": " | ".join(evidence_parts),
    "reason": reason,
})
PY
