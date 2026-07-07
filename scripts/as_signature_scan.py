#!/usr/bin/env python3
"""Shared AS-* signature evaluator for repo-auditor."""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path
from typing import Any, Iterator


SIGNATURES: dict[str, dict[str, str]] = {
    "AS-01": {
        "name": "Instruction root drift",
        "severity": "HIGH",
        "prevention_tier": "T1",
        "script": "detect-as-instruction-root-drift.sh",
    },
    "AS-02": {
        "name": "Docs-vs-observed host drift",
        "severity": "MEDIUM",
        "prevention_tier": "T2",
        "script": "detect-as-docs-vs-observed-host-drift.sh",
    },
    "AS-03": {
        "name": "Missing runtime heartbeat",
        "severity": "HIGH",
        "prevention_tier": "T1",
        "script": "detect-as-missing-runtime-heartbeat.sh",
    },
    "AS-04": {
        "name": "Validator live path gap",
        "severity": "HIGH",
        "prevention_tier": "T1",
        "script": "detect-as-validator-live-path-gap.sh",
    },
    "AS-05": {
        "name": "Memory authority confusion",
        "severity": "HIGH",
        "prevention_tier": "T1",
        "script": "detect-as-memory-authority-confusion.sh",
    },
    "AS-06": {
        "name": "Prompt-only optimization surface",
        "severity": "MEDIUM",
        "prevention_tier": "T2",
        "script": "detect-as-prompt-only-optimization-surface.sh",
    },
    "AS-07": {
        "name": "Unused platform surface",
        "severity": "MEDIUM",
        "prevention_tier": "T2",
        "script": "detect-as-unused-platform-surface.sh",
    },
    "AS-08": {
        "name": "External critique health",
        "severity": "HIGH",
        "prevention_tier": "T1",
        "script": "detect-external-critique-health.sh",
    },
    "AS-09": {
        "name": "Cost estimate without token fields",
        "severity": "HIGH",
        "prevention_tier": "T1",
        "script": "detect-as-cost-without-token-fields.sh",
    },
    "AS-10": {
        "name": "Cost model mismatch",
        "severity": "HIGH",
        "prevention_tier": "T1",
        "script": "detect-as-cost-model-mismatch.sh",
    },
    "AS-11": {
        "name": "Uncalled request/tool amplification",
        "severity": "MEDIUM",
        "prevention_tier": "T2",
        "script": "detect-as-request-tool-amplification-gap.sh",
    },
    "AS-12": {
        "name": "Pricing provenance gap",
        "severity": "HIGH",
        "prevention_tier": "T1",
        "script": "detect-as-pricing-provenance-gap.sh",
    },
    "AS-13": {
        "name": "Copied evidence boundary gap",
        "severity": "MEDIUM",
        "prevention_tier": "T2",
        "script": "detect-as-copied-evidence-boundary-gap.sh",
    },
    "AS-14": {
        "name": "Unauthorized production default enablement",
        "severity": "HIGH",
        "prevention_tier": "T1",
        "script": "detect-as-unauthorized-production-default-enablement.sh",
    },
    "AS-15": {
        "name": "Missing rollback/control proof",
        "severity": "HIGH",
        "prevention_tier": "T1",
        "script": "detect-as-missing-rollback-control-proof.sh",
    },
    "AS-16": {
        "name": "Aggregate-only readiness",
        "severity": "HIGH",
        "prevention_tier": "T1",
        "script": "detect-as-aggregate-only-readiness.sh",
    },
    "AS-17": {
        "name": "Stale direct-token evidence",
        "severity": "MEDIUM",
        "prevention_tier": "T2",
        "script": "detect-as-stale-direct-token-evidence.sh",
    },
    "AS-18": {
        "name": "Forbidden public CustomerNewsletter mutation",
        "severity": "HIGH",
        "prevention_tier": "T1",
        "script": "detect-as-forbidden-public-customernewsletter-mutation.sh",
    },
    "AS-19": {
        "name": "Source intelligence intake gap",
        "severity": "HIGH",
        "prevention_tier": "T1",
        "script": "detect-as-source-intelligence-intake-gap.sh",
    },
    "AS-20": {
        "name": "Selection handback recommendation",
        "severity": "HIGH",
        "prevention_tier": "T1",
        "script": "detect-as-selection-handback-recommendation.sh",
    },
    "AS-21": {
        "name": "Too-small Goal-mode episode",
        "severity": "MEDIUM",
        "prevention_tier": "T2",
        "script": "detect-as-too-small-goal-mode-episode.sh",
    },
    "AS-22": {
        "name": "GitHub-native closure regrowth",
        "severity": "HIGH",
        "prevention_tier": "T1",
        "script": "detect-as-github-native-closure-regrowth.sh",
    },
    "AS-23": {
        "name": "Owner-surface ambiguity",
        "severity": "HIGH",
        "prevention_tier": "T1",
        "script": "detect-as-owner-surface-ambiguity.sh",
    },
    "AS-24": {
        "name": "Reciprocal proving-ground gap",
        "severity": "MEDIUM",
        "prevention_tier": "T2",
        "script": "detect-as-reciprocal-proving-ground-gap.sh",
    },
    "AS-25": {
        "name": "Goal-mode runtime evidence gap",
        "severity": "HIGH",
        "prevention_tier": "T1",
        "script": "detect-as-goal-runtime-evidence-gap.sh",
    },
    "AS-26": {
        "name": "Reactive self-healing loop",
        "severity": "HIGH",
        "prevention_tier": "T1",
        "script": "detect-as-reactive-self-healing-loop.sh",
    },
    "AS-27": {
        "name": "Shell reserved status-variable launch snippet",
        "severity": "HIGH",
        "prevention_tier": "T1",
        "script": "detect-as-shell-reserved-status-variable.sh",
    },
    "AS-28": {
        "name": "Stale/default capability guidance",
        "severity": "HIGH",
        "prevention_tier": "T1",
        "script": "detect-as-stale-default-capability-guidance.sh",
    },
    "AS-29": {
        "name": "Hermes foreground receipt adoption gap",
        "severity": "HIGH",
        "prevention_tier": "T1",
        "script": "detect-as-hermes-foreground-receipt-adoption-gap.sh",
    },
    "AS-30": {
        "name": "Interrupted Goal recovery gap",
        "severity": "HIGH",
        "prevention_tier": "T1",
        "script": "detect-as-interrupted-goal-recovery-gap.sh",
    },
    "AS-31": {
        "name": "Fractured serial continuation",
        "severity": "HIGH",
        "prevention_tier": "T1",
        "script": "detect-as-fractured-serial-continuation.sh",
    },
    "AS-32": {
        "name": "Unanchored self-learning claim",
        "severity": "HIGH",
        "prevention_tier": "T1",
        "script": "detect-as-unanchored-self-learning-claim.sh",
    },
    "AS-33": {
        "name": "Foreground failure guidance gap",
        "severity": "HIGH",
        "prevention_tier": "T1",
        "script": "detect-as-foreground-failure-guidance-gap.sh",
    },
    "AS-34": {
        "name": "Closure-run identity gap",
        "severity": "MEDIUM",
        "prevention_tier": "T2",
        "script": "detect-as-closure-run-identity-gap.sh",
    },
    "AS-35": {
        "name": "Upstream capability intake gap",
        "severity": "HIGH",
        "prevention_tier": "T1",
        "script": "detect-as-upstream-capability-intake-gap.sh",
    },
    "AS-36": {
        "name": "GBrain instruction distribution overclaim",
        "severity": "HIGH",
        "prevention_tier": "T1",
        "script": "detect-as-gbrain-instruction-distribution-overclaim.sh",
    },
    "AS-37": {
        "name": "Issue 164 runtime drift",
        "severity": "HIGH",
        "prevention_tier": "T1",
        "script": "detect-as-issue164-runtime-drift.sh",
    },
    "AS-38": {
        "name": "Self-authored campaign pause authority",
        "severity": "HIGH",
        "prevention_tier": "T1",
        "script": "detect-as-self-authored-campaign-pause-authority.sh",
    },
    "AS-39": {
        "name": "Scheduled workflow evidence boundary gap",
        "severity": "HIGH",
        "prevention_tier": "T1",
        "script": "detect-as-scheduled-evidence-boundary-gap.sh",
    },
    "AS-40": {
        "name": "Hermes/GitHub reliability boundary gap",
        "severity": "HIGH",
        "prevention_tier": "T1",
        "script": "detect-as-hermes-github-reliability-boundary-gap.sh",
    },
    "AS-41": {
        "name": "Campaign Sync completed-track readback gap",
        "severity": "HIGH",
        "prevention_tier": "T1",
        "script": "detect-as-campaign-sync-completed-track-gap.sh",
    },
    "AS-42": {
        "name": "Route-changing learning propagation gap",
        "severity": "HIGH",
        "prevention_tier": "T1",
        "script": "detect-as-route-changing-learning-propagation-gap.sh",
    },
    "AS-43": {
        "name": "Capability placement preview gap",
        "severity": "MEDIUM",
        "prevention_tier": "T2",
        "script": "detect-as-capability-placement-gap.sh",
    },
    "AS-44": {
        "name": "Hermes foreground reliability evidence gap",
        "severity": "HIGH",
        "prevention_tier": "T1",
        "script": "detect-as-hermes-foreground-reliability-evidence-gap.sh",
    },
    "AS-45": {
        "name": "Codex native runtime readiness evidence gap",
        "severity": "HIGH",
        "prevention_tier": "T1",
        "script": "detect-as-codex-native-runtime-readiness-evidence-gap.sh",
    },
    "AS-46": {
        "name": "Deep Research source-intelligence native corpus evidence gap",
        "severity": "HIGH",
        "prevention_tier": "T1",
        "script": "detect-as-deep-research-source-intelligence-native-corpus-gap.sh",
    },
    "AS-47": {
        "name": "Integrated native capability acceptance evidence gap",
        "severity": "HIGH",
        "prevention_tier": "T1",
        "script": "detect-as-integrated-native-capability-acceptance-gap.sh",
    },
    "AS-48": {
        "name": "Standalone external intelligence sidecar gap",
        "severity": "HIGH",
        "prevention_tier": "T1",
        "script": "detect-as-standalone-external-intelligence-sidecar-gap.sh",
    },
    "AS-49": {
        "name": "Scheduled readback owner proof gap",
        "severity": "HIGH",
        "prevention_tier": "T1",
        "script": "detect-as-scheduled-readback-owner-proof-gap.sh",
    },
    "AS-50": {
        "name": "Hermes foreground failure disposition gap",
        "severity": "HIGH",
        "prevention_tier": "T1",
        "script": "detect-as-hermes-foreground-failure-disposition-gap.sh",
    },
    "AS-51": {
        "name": "Missing operating-model alignment anchor",
        "severity": "HIGH",
        "prevention_tier": "T1",
        "script": "detect-as-missing-operating-model-alignment-anchor.sh",
    },
    "AS-52": {
        "name": "Missing repo-anthropology surface",
        "severity": "MEDIUM",
        "prevention_tier": "T2",
        "script": "detect-as-missing-repo-anthropology-surface.sh",
    },
    "AS-53": {
        "name": "Maturity-boundary claim overreach",
        "severity": "HIGH",
        "prevention_tier": "T1",
        "script": "detect-as-maturity-boundary-claim-overreach.sh",
    },
    "AS-54": {
        "name": "closure-signal-integrity",
        "severity": "HIGH",
        "prevention_tier": "T1",
        "script": "detect-as-closure-signal-integrity.sh",
    },
    "AS-55": {
        "name": "review-ergonomics-working-memory-lightness",
        "severity": "MEDIUM",
        "prevention_tier": "T2",
        "script": "detect-as-review-ergonomics-working-memory-lightness.sh",
    },
    "AS-56": {
        "name": "external-closure-coupling",
        "severity": "HIGH",
        "prevention_tier": "T1",
        "script": "detect-as-external-closure-coupling.sh",
    },
    "AS-57": {
        "name": "native-evidence-before-verdict",
        "severity": "HIGH",
        "prevention_tier": "T1",
        "script": "detect-as-native-evidence-before-verdict.sh",
    },
}


INSTRUCTION_FILES = {
    "AGENTS.md",
    "AGENT.md",
    "CLAUDE.md",
    "CODEX.md",
    "GEMINI.md",
    "README.md",
    "LEARNINGS.md",
    "docs/invocation-contract.md",
    ".specify/memory/constitution.md",
}
SCAN_LIMIT = 200
SCAN_ORDER_NOTE = (
    "AS text scan budgets up to 200 owner-evidence files and up to 200 "
    "instrumentation/test-noise files separately, after prioritizing owner "
    "guidance, instruction, and closure operation surfaces (root instruction "
    "files, AGENTS.md, README.md, Makefile, GitHub workflows, closure/timing "
    "scripts, docs, .github, .agents, scripts, schemas, tests, tracked work/ "
    "closure receipts) before the general sorted file walk. Declared "
    "working-memory/state docs (e.g. CURRENT_STATE.md) are always scanned "
    "regardless of either budget."
)
PRIORITY_ROOT_FILES = {
    "AGENTS.md",
    "AGENT.md",
    "CLAUDE.md",
    "CODEX.md",
    "GEMINI.md",
    "README.md",
    "README.txt",
    "LEARNINGS.md",
    "Makefile",
    "makefile",
}
PRIORITY_DIR_RANKS = {
    "docs": 10,
    ".github": 20,
    ".agents": 30,
    "scripts": 40,
    "schemas": 50,
    "tests": 60,
    "test": 60,
    # Tracked work/<timestamp>Z/ closeout receipts are the fleet-wide
    # repo-star closure-evidence convention (WORK.md, SCORECARD.json, etc.).
    # Rank them so they compete for scan budget on equal footing with other
    # recognized evidence directories instead of falling into the unranked,
    # alphabetically-sorted catch-all tier where a leading lowercase "work"
    # loses out to upper-case-prefixed paths.
    "work": 65,
}
PRIORITY_OPERATION_PATHS = {
    "scripts/analyze-closure-dedupe.py",
    "scripts/record-check-step-timing.py",
    "scripts/record-make-target.sh",
    "scripts/run-test-manifest.sh",
    "scripts/work-close.sh",
}

TEXT_EXTENSIONS = {
    ".md",
    ".txt",
    ".json",
    ".jsonl",
    ".csv",
    ".yml",
    ".yaml",
    ".sh",
    ".py",
    ".prompt",
}
SKIP_PARTS = {
    ".git",
    ".venv",
    "venv",
    "node_modules",
    ".tox",
    ".mypy_cache",
    "__pycache__",
    "vendor",
    ".eggs",
    "audit_output",
    ".tmp",
}
# Fleet-wide repo-star closure receipts (work/<timestamp>Z/) sometimes nest a
# full copy of this tool's own before/after audit output (e.g.
# SCORECARD.json, AUDIT_REPORT.md, drift/maturity/stall-risk text, and a
# pre-scan/ file-inventory dump) under pre-audit/ or post-audit/. That is
# generated tool output captured as a receipt, not owner-authored prose.
# Unlike "audit_output" (an unambiguous generated-artifact name), "pre-audit"
# / "post-audit" / "pre-scan" are generic enough that a repo could plausibly
# use them for real owner documentation outside a work/ receipt (e.g.
# docs/pre-audit-checklist.md, or even a coincidentally-named docs/work/
# subdirectory) -- so these are NOT in the blanket SKIP_PARTS set above. They
# are only excluded when nested under the root-level work/<timestamp>Z/
# closure-receipt directory specifically (parts[0] == "work", mirroring the
# same root-only convention PRIORITY_DIR_RANKS/scan_priority_key already use
# for "work"), not any "work" segment appearing deeper in the tree. The
# WORK.md/DELTA.md/SCORECARD.json receipt files one level up (directly under
# work/<ts>Z/) are unaffected either way.
NESTED_WORK_RECEIPT_SNAPSHOT_PARTS = {"pre-audit", "post-audit", "pre-scan"}


def is_nested_work_receipt_snapshot_path(parts_lower: list[str]) -> bool:
    if not parts_lower or parts_lower[0] != "work":
        return False
    return any(part in NESTED_WORK_RECEIPT_SNAPSHOT_PARTS for part in parts_lower[1:])


# "work" is excluded only when the path is NOT git-tracked: every repo-star
# fleet repo (including this one) uses a gitignored work/<timestamp>Z/ scratch
# convention for ephemeral session output, but some repos (e.g. tp) also
# force-add committed closure-evidence files under the same directory name.
# A blanket SKIP_PARTS match would blind every AS-NN scan to that legitimately
# tracked evidence; a tracked-vs-untracked check keeps scratch out without
# hiding real, committed evidence. See is_eligible_text_path / is_git_tracked.
UNTRACKED_ONLY_SKIP_PARTS = {"work"}
SYNTHETIC_EVIDENCE_PARTS = {"fixture", "fixtures", "__fixtures__", "testdata", "test-data"}
SYNTHETIC_EVIDENCE_ROOTS = {"test", "tests"}
SELF_INSTRUMENTATION_PATHS = {"scripts/as_signature_scan.py"}
# Declared working-memory/state docs (e.g. CURRENT_STATE.md) are guaranteed a
# scan slot regardless of SCAN_LIMIT so a test-heavy repo can't starve the one
# file size-based friction detectors (AS-55) are specifically named to read.
WORKING_MEMORY_DOC_SUFFIX = "CURRENT_STATE.md"


def parse_args() -> tuple[str, Path]:
    if len(sys.argv) != 3:
        raise SystemExit("Usage: as_signature_scan.py <AS-id> <repo_path>")
    return sys.argv[1], Path(sys.argv[2]).resolve()


@dataclass(frozen=True)
class TextScan:
    texts: dict[str, str]
    eligible_files: int
    scan_limit: int = SCAN_LIMIT
    scan_order_note: str = SCAN_ORDER_NOTE
    # Whether either the owner-evidence or instrumentation-noise budget
    # actually dropped a file. With the dual-budget split, total
    # eligible_files can exceed scan_limit while every file still gets read
    # (e.g. 150 owner-evidence + 100 noise files, each bucket under its own
    # 200 cap) -- so scan_limited must reflect real omission, not just the
    # combined eligible-file count vs a single limit.
    budget_exhausted: bool = False

    @property
    def scan_limited(self) -> bool:
        return self.budget_exhausted


@lru_cache(maxsize=None)
def _git_tracked_relpaths(repo: Path) -> frozenset[str] | None:
    """Git-tracked relative paths for repo, or None if repo isn't a usable
    git checkout (no git binary, not a repo, etc). Callers must treat None as
    "tracked status unknown" and fall back to the conservative/excluded path
    so untracked scratch is never accidentally pulled into a scan."""
    try:
        result = subprocess.run(
            ["git", "-C", str(repo), "ls-files", "-z"],
            capture_output=True,
            timeout=30,
            check=True,
        )
    except (OSError, subprocess.CalledProcessError, subprocess.TimeoutExpired):
        return None
    raw = result.stdout.decode("utf-8", errors="replace")
    return frozenset(entry for entry in raw.split("\0") if entry)


def is_git_tracked(repo: Path, rel_str: str) -> bool:
    tracked = _git_tracked_relpaths(repo)
    if tracked is None:
        return False
    return rel_str in tracked


def is_eligible_text_path(repo: Path, path: Path) -> bool:
    if not path.is_file():
        return False
    rel = path.relative_to(repo)
    parts_lower = [part.lower() for part in rel.parts]
    if any(part in SKIP_PARTS for part in parts_lower):
        return False
    if is_nested_work_receipt_snapshot_path(parts_lower):
        return False
    rel_str = rel.as_posix()
    if any(part in UNTRACKED_ONLY_SKIP_PARTS for part in parts_lower):
        if not is_git_tracked(repo, rel_str):
            return False
    return (
        path.suffix.lower() in TEXT_EXTENSIONS
        or path.name in INSTRUCTION_FILES
        or path.name in PRIORITY_ROOT_FILES
        or rel_str in INSTRUCTION_FILES
    )


def scan_priority_key(repo: Path, path: Path) -> tuple[int, str]:
    rel = path.relative_to(repo)
    rel_str = rel.as_posix()
    parts = rel.parts
    name = path.name
    if rel_str in INSTRUCTION_FILES or (len(parts) == 1 and name in PRIORITY_ROOT_FILES):
        return (0, rel_str)
    if rel_str in PRIORITY_OPERATION_PATHS or rel_str.startswith(".github/workflows/"):
        return (5, rel_str)
    if parts:
        first = parts[0].lower()
        if first in PRIORITY_DIR_RANKS:
            return (PRIORITY_DIR_RANKS[first], rel_str)
    return (100, rel_str)


def is_declared_working_memory_doc(rel_str: str) -> bool:
    return rel_str.endswith(WORKING_MEMORY_DOC_SUFFIX)


def iter_eligible_text_paths(repo: Path) -> Iterator[Path]:
    """Yield eligible text paths under repo, pruning generated/VCS trees during
    the walk instead of after it.

    ``Path.rglob("*")`` stats every entry in the tree -- including huge
    ``.git``/``node_modules``/``.venv`` subtrees that ``is_eligible_text_path``
    only rejects one file at a time -- and can follow symlink cycles. On a
    large repo that traversal, repeated once per signature process, is what
    lets the DS-34+ sweep stall. Pruning any directory whose name is an
    unconditional skip part (``SKIP_PARTS``) mid-walk yields the identical
    eligible-file set far faster, and ``followlinks=False`` avoids symlink-loop
    hangs. Conditional skips (untracked ``work/`` scratch, nested work-receipt
    snapshots) stay in ``is_eligible_text_path`` so semantics are unchanged."""
    for dirpath, dirnames, filenames in os.walk(repo, topdown=True, followlinks=False):
        dirnames[:] = [name for name in dirnames if name.lower() not in SKIP_PARTS]
        base = Path(dirpath)
        for name in filenames:
            path = base / name
            if is_eligible_text_path(repo, path):
                yield path


def load_text_scan(repo: Path) -> TextScan:
    eligible_paths = sorted(
        iter_eligible_text_paths(repo),
        key=lambda path: scan_priority_key(repo, path),
    )
    texts: dict[str, str] = {}

    def read_into_texts(path: Path, rel_str: str) -> None:
        try:
            texts[rel_str] = path.read_text(encoding="utf-8", errors="replace")
        except OSError:
            return

    # Pass 1: declared working-memory/state docs are guaranteed a scan slot
    # regardless of either budget below (see WORKING_MEMORY_DOC_SUFFIX).
    for path in eligible_paths:
        rel_str = path.relative_to(repo).as_posix()
        if is_declared_working_memory_doc(rel_str):
            read_into_texts(path, rel_str)

    # Pass 2: the remaining SCAN_LIMIT budget is tracked separately for
    # instrumentation/test-noise files vs owner-evidence files. Without this
    # split, a test-heavy repo's tests/ tier (counted at full priority but
    # discarded by owner_evidence_texts for most detectors anyway) can
    # exhaust the entire cap before any owner-evidence file in a lower-ranked
    # or unranked directory is ever read.
    owner_evidence_read = 0
    noise_read = 0
    owner_evidence_seen = 0
    noise_seen = 0
    for path in eligible_paths:
        rel_str = path.relative_to(repo).as_posix()
        if rel_str in texts:
            continue
        if is_instrumentation_noise_path(rel_str):
            noise_seen += 1
            if noise_read >= SCAN_LIMIT:
                continue
            read_into_texts(path, rel_str)
            if rel_str in texts:
                noise_read += 1
        else:
            owner_evidence_seen += 1
            if owner_evidence_read >= SCAN_LIMIT:
                continue
            read_into_texts(path, rel_str)
            if rel_str in texts:
                owner_evidence_read += 1

    budget_exhausted = owner_evidence_read < owner_evidence_seen or noise_read < noise_seen
    return TextScan(
        texts=texts,
        eligible_files=len(eligible_paths),
        budget_exhausted=budget_exhausted,
    )


def load_texts(repo: Path) -> dict[str, str]:
    return load_text_scan(repo).texts


def is_instrumentation_noise_path(path: str) -> bool:
    parts = tuple(part.lower() for part in path.split("/"))
    if path in SELF_INSTRUMENTATION_PATHS:
        return True
    if any(part in SYNTHETIC_EVIDENCE_PARTS for part in parts):
        return True
    return bool(parts) and parts[0] in SYNTHETIC_EVIDENCE_ROOTS


def owner_evidence_texts(texts: dict[str, str]) -> dict[str, str]:
    return {path: text for path, text in texts.items() if not is_instrumentation_noise_path(path)}


def rels_matching(texts: dict[str, str], predicate) -> list[str]:
    matched = []
    for path, text in texts.items():
        if predicate(path, text.lower()):
            matched.append(path)
    return matched


def evidence_join(items: list[str], limit: int = 6) -> str:
    if not items:
        return "n/a"
    trimmed = items[:limit]
    suffix = " ..." if len(items) > limit else ""
    return " | ".join(trimmed) + suffix


def instruction_root_drift(texts: dict[str, str]) -> dict[str, Any]:
    root_pattern = re.compile(
        r"(AGENTS\.md|README\.md|LEARNINGS\.md|docs/invocation-contract\.md|\.specify/memory/constitution\.md|"
        r"\.agents/[^ ]+\.agent\.md|\.github/prompts/[^ ]+\.prompt\.md|\.agents/skills/[^ ]+/SKILL\.md)"
    )
    claim_files: list[str] = []
    claimed_roots: set[str] = set()
    details: list[str] = []

    for path, text in texts.items():
        lowered = text.lower()
        if path not in INSTRUCTION_FILES and not path.startswith(".agents/") and not path.startswith(".github/"):
            continue
        if not re.search(r"\b(canonical|primary|startup surface|instruction surface|authoritative|source of truth)\b", lowered):
            continue
        roots = sorted(set(root_pattern.findall(text)))
        if roots:
            claim_files.append(path)
            claimed_roots.update(roots)
            details.append(f"{path}=>{','.join(roots)}")

    fired = len(claim_files) >= 2 and len(claimed_roots) >= 2
    return {
        "fired": fired,
        "signals": {
            "claim_file_count": len(claim_files),
            "distinct_root_count": len(claimed_roots),
            "claimed_roots": sorted(claimed_roots),
        },
        "evidence": evidence_join(details or ["no instruction-root drift"]),
        "reason": "instruction-root claims disagree across surfaces" if fired else "no conflicting instruction root claims found",
    }


def docs_vs_observed_host_drift(texts: dict[str, str]) -> dict[str, Any]:
    host_patterns = {
        "codex desktop": re.compile(r"\bcodex desktop\b"),
        "copilot cli": re.compile(r"\bcopilot cli\b|\bcopilot -p\b|\bcopilot --model\b"),
        "vs code": re.compile(r"\bvs code\b|\bvscode\b|\bvisual studio code\b"),
    }
    host_hits: dict[str, list[str]] = defaultdict(list)
    for path, text in texts.items():
        lowered = text.lower()
        if not (
            path in INSTRUCTION_FILES
            or path.startswith(".agents/")
            or path.startswith(".github/")
            or path.startswith("docs/")
            or path == "README.md"
        ):
            continue
        for host, pattern in host_patterns.items():
            if pattern.search(lowered):
                host_hits[host].append(path)

    details = [f"{host}=>{','.join(paths[:3])}" for host, paths in sorted(host_hits.items())]
    fired = len(host_hits) >= 2
    return {
        "fired": fired,
        "signals": {
            "distinct_host_count": len(host_hits),
            "hosts": sorted(host_hits),
        },
        "evidence": evidence_join(details or ["no host drift detected"]),
        "reason": "docs disagree about the active host" if fired else "host mentions are consistent or absent",
    }


def missing_runtime_heartbeat(texts: dict[str, str]) -> dict[str, Any]:
    runtime_files = rels_matching(
        texts,
        lambda path, text: (
            path.endswith("Makefile")
            or path.startswith("scripts/")
            or path.startswith(".github/workflows/")
            or re.search(r"\b(run|test|audit|validate|score)\b", text) is not None
        ),
    )
    heartbeat_files = rels_matching(
        texts,
        lambda path, text: re.search(r"\b(heartbeat|health check|liveness|smoke test|liveness probe)\b", text) is not None,
    )
    fired = bool(runtime_files) and not heartbeat_files
    details = [f"runtime=>{','.join(runtime_files[:4]) or 'none'}", f"heartbeat=>{','.join(heartbeat_files[:4]) or 'none'}"]
    return {
        "fired": fired,
        "signals": {
            "runtime_file_count": len(runtime_files),
            "heartbeat_file_count": len(heartbeat_files),
        },
        "evidence": evidence_join(details),
        "reason": "runtime surfaces have no heartbeat/liveness check" if fired else "runtime heartbeat is present or runtime surfaces are absent",
    }


def validator_live_path_gap(texts: dict[str, str]) -> dict[str, Any]:
    validation_files = rels_matching(
        texts,
        lambda path, text: re.search(r"\b(validate|validation|test|check|score)\b", text) is not None,
    )
    live_path_files = rels_matching(
        texts,
        lambda path, text: re.search(r"\b(execute|invoke|orchestrated|workflow|entrypoint|agent entry|live path)\b", text) is not None,
    )
    fired = len(validation_files) >= 1 and not live_path_files
    details = [f"validation=>{','.join(validation_files[:4]) or 'none'}", f"live_path=>{','.join(live_path_files[:4]) or 'none'}"]
    return {
        "fired": fired,
        "signals": {
            "validation_file_count": len(validation_files),
            "live_path_file_count": len(live_path_files),
        },
        "evidence": evidence_join(details),
        "reason": "validators are present but no live path is documented or exercised" if fired else "live path coverage exists or validation surfaces are absent",
    }


def memory_authority_confusion(texts: dict[str, str]) -> dict[str, Any]:
    def is_memory_surface(path: str) -> bool:
        return (
            path.endswith("LEARNINGS.md")
            or path.endswith("constitution.md")
            or path.startswith(".specify/")
        )

    canonical_files = rels_matching(
        texts,
        lambda path, text: (
            path in INSTRUCTION_FILES
            or path.startswith(".agents/")
            or path.startswith(".github/")
        )
        and re.search(r"\b(canonical|primary startup surface|canonical instruction surface)\b", text) is not None,
    )
    memory_files = rels_matching(
        texts,
        lambda path, text: is_memory_surface(path)
        and re.search(r"\b(query-only|non-negotiable|deferred-only|historical|archived)\b", text) is not None,
    )
    conflicting_memory_claims = rels_matching(
        texts,
        lambda path, text: is_memory_surface(path)
        and re.search(r"\b(canonical|primary|startup surface|instruction surface|authoritative|source of truth)\b", text) is not None,
    )
    authority_terms = Counter()
    authority_terms["canonical"] = len(canonical_files)
    authority_terms["memory"] = len(memory_files)
    authority_terms["conflicting_memory_claims"] = len(conflicting_memory_claims)
    fired = bool(canonical_files) and bool(conflicting_memory_claims)
    details = [
        f"canonical=>{','.join(canonical_files[:4]) or 'none'}",
        f"memory=>{','.join(memory_files[:4]) or 'none'}",
        f"memory_authority=>{','.join(conflicting_memory_claims[:4]) or 'none'}",
    ]
    return {
        "fired": fired,
        "signals": dict(authority_terms),
        "evidence": evidence_join(details),
        "reason": "memory-only surfaces also claim authority" if fired else "memory surfaces stay separated from live authority claims",
    }


def prompt_only_optimization_surface(texts: dict[str, str]) -> dict[str, Any]:
    prompt_files = rels_matching(
        texts,
        lambda path, text: (
            path.endswith(".prompt.md")
            or path.startswith(".github/prompts/")
            or path.startswith(".agents/")
        )
        and re.search(r"\b(optimize|optimization|reduce fan-out|efficiency|token efficiency|improve)\b", text) is not None,
    )
    executable_files = rels_matching(
        texts,
        lambda path, text: (
            path.endswith(".sh")
            or path.endswith(".py")
            or path.endswith("Makefile")
            or path.startswith("scripts/")
            or path.startswith("tests/")
        )
        and re.search(r"\b(optimize|optimization|reduce fan-out|efficiency|token efficiency|measure|validate)\b", text) is not None,
    )
    fired = bool(prompt_files) and not executable_files
    details = [f"prompt=>{','.join(prompt_files[:4]) or 'none'}", f"exec=>{','.join(executable_files[:4]) or 'none'}"]
    return {
        "fired": fired,
        "signals": {
            "prompt_surface_count": len(prompt_files),
            "executed_surface_count": len(executable_files),
        },
        "evidence": evidence_join(details),
        "reason": "optimization language lives only on prompt surfaces" if fired else "optimization language also appears on executable surfaces",
    }


def unused_platform_surface(texts: dict[str, str]) -> dict[str, Any]:
    platform_roots = [".agents", ".github/prompts", ".github/workflows"]
    registry_text = "\n".join(
        texts.get(path, "")
        for path in ("AGENTS.md", "README.md", "docs/invocation-contract.md")
        if path in texts
    ).lower()

    unreferenced: list[str] = []
    details: list[str] = []
    for root in platform_roots:
        has_surface = any(path == root or path.startswith(root + "/") for path in texts)
        if not has_surface:
            continue
        if root.replace(".", "") in registry_text or root in registry_text:
            continue
        unreferenced.append(root)
        details.append(f"{root}=>unreferenced")

    fired = bool(unreferenced)
    return {
        "fired": fired,
        "signals": {
            "unreferenced_platform_surface_count": len(unreferenced),
            "unreferenced_platform_surfaces": unreferenced,
        },
        "evidence": evidence_join(details or ["all platform surfaces are referenced"]),
        "reason": "platform surface exists without registry or invocation documentation" if fired else "platform surfaces are documented or absent",
    }


EXTERNAL_CRITIQUE_CONTRACT_SOURCE = (
    "repo-agent-core/docs/external-critique-capability-contract.md"
    "@d31c7017a8c01a7aa798ac2102f91eb1199e36d1"
)
EXTERNAL_CRITIQUE_CONTRACT_VERSION = "1.1"
EXTERNAL_CRITIQUE_TOKEN_PATTERN = re.compile(
    r"\b(EXTERNAL_CRITIQUE_CAPABILITY|CRITIQUE_RESULT)\b",
    re.IGNORECASE,
)
EXTERNAL_CRITIQUE_CONCEPT_PATTERN = re.compile(
    r"\b(external[-_ ]critique|external critic|critic mode|critic request|"
    r"critique result|bounded risk sensor|latest[-_ ]panel|high[-_ ]stakes context|"
    r"blocker findings?|advisory findings?|finding quota|no[-_ ]findings?)\b",
    re.IGNORECASE,
)
EXTERNAL_CRITIQUE_SEMANTIC_PATTERNS = {
    "authority": re.compile(
        r"\b(authority refs?|local authority|repo[- ]local instructions?|"
        r"owner evidence|owner decision|github issue/pr/check/merge truth|"
        r"target repo principles|local principles)\b",
        re.IGNORECASE,
    ),
    "invocation": re.compile(
        r"\b(invoke|invocation|critic mode|one critic|panel|latest[- ]panel|"
        r"trigger examples?|when[- ]not[- ]to[- ]invoke)\b",
        re.IGNORECASE,
    ),
    "admission": re.compile(
        r"\b(admissible|admission|owner disposition|blocker findings?|"
        r"advisory findings?|no[- ]finding result|independent owner evidence)\b",
        re.IGNORECASE,
    ),
    "privacy": re.compile(
        r"\b(privacy|redaction|credentials?|private data|customer details?|"
        r"private urls?|internal text)\b",
        re.IGNORECASE,
    ),
    "budget": re.compile(
        r"\b(pass budget|one follow[- ]up|one initial pass|loop caps?|"
        r"stopping condition|max(?:imum)? passes?)\b",
        re.IGNORECASE,
    ),
}
EXTERNAL_CRITIQUE_VERSION_PATTERN = re.compile(
    r"\b(?:external critique capability )?(?:contract )?version\s*[:=]\s*`?([0-9]+(?:\.[0-9]+)*)`?",
    re.IGNORECASE,
)
PANEL_PATTERN = re.compile(r"\b(panel|latest[- ]panel)\b", re.IGNORECASE)
NAMED_HIGH_STAKES_CONTEXT_PATTERN = re.compile(
    r"\b(named|specific|concrete|explicit)\b.{0,50}\bhigh[- ]stakes context\b|"
    r"\bhigh[- ]stakes context\b.{0,70}\b(required|before invocation|before use|must be named)\b",
    re.IGNORECASE | re.DOTALL,
)
CONTEXT_SUPPORT_PATTERN = re.compile(
    r"\b(context support|scope reviewed|subject and scope|embedded context|"
    r"repository context|local context|named high[- ]stakes context|"
    r"answered context|context gaps?)\b",
    re.IGNORECASE,
)
FORCED_FINDING_QUOTA_PATTERN = re.compile(
    r"\b(forced finding quota|must return (?:at least )?(?:one|two|three|[1-9][0-9]*) findings?|"
    r"at least (?:one|two|three|[1-9][0-9]*) findings?|minimum (?:one|two|three|[1-9][0-9]*) findings?|"
    r"always (?:find|return) (?:a finding|findings)|find (?:three|two|[2-9][0-9]*) issues?)\b",
    re.IGNORECASE,
)
NO_FORCED_FINDING_QUOTA_PATTERN = re.compile(
    r"\b(no forced finding quota|finding quota:\s*none|no[- ]finding results? (?:are|is) valid|"
    r"valid critique may return no findings|no findings? result is valid|"
    r"do not ask for a forced finding count)\b",
    re.IGNORECASE,
)
BLOCKER_ADVISORY_PATTERN = re.compile(
    r"\b(blocker findings?|blockers?)\b.{0,80}\b(advisory findings?|advisory)\b|"
    r"\b(advisory findings?|advisory)\b.{0,80}\b(blocker findings?|blockers?)\b|"
    r"\bblocker/advisory\b",
    re.IGNORECASE | re.DOTALL,
)
LOOP_CAP_PATTERN = re.compile(
    r"\b(pass budget|one initial pass plus one follow[- ]up|one follow[- ]up pass|"
    r"loop caps?|max(?:imum)? passes?|stopping condition|budget expansion)\b",
    re.IGNORECASE,
)
LOCAL_AUTHORITY_REF_PATTERN = re.compile(
    r"\b(authority refs?|local authority|repo[- ]local instructions?|repo[- ]local policy|"
    r"owner evidence|owner decision|independent owner evidence|"
    r"github issue/pr/check/merge truth|github issue|pull request|checks?|"
    r"AGENTS\.md|CODEX\.md|CLAUDE\.md|target repo principles|local principles)\b",
    re.IGNORECASE,
)
PRIVACY_BOUNDARY_PATTERN = re.compile(
    r"\b(privacy|redaction|redact|credentials?|secrets?|private data|private urls?|"
    r"account details?|customer details?|internal text|omit|summarize)\b",
    re.IGNORECASE,
)
BMA_ONLY_TERM_PATTERN = re.compile(
    r"\b(BMA|Build Meta Analysis|build-meta-analysis|Issue #164|repo-star|"
    r"coordinator|child issue|run root|progress-ledger)\b",
    re.IGNORECASE,
)
BMA_TRANSLATION_PATTERN = re.compile(
    r"\b(seed evidence|provenance only|non[- ]canonical|not canonical|"
    r"target[- ]local translation|locali[sz]e|locali[sz]ed|"
    r"target repo principles outrank|local principles outrank|"
    r"rewrites? it through local principles)\b",
    re.IGNORECASE,
)
AUTHORITY_OVERCLAIM_PATTERN = re.compile(
    r"\b(critique is authority|critic output is authority|external output into authority|"
    r"closure truth|approves? (?:prs?|pull requests?|closure|merges?)|"
    r"decides? (?:owner )?action|blocks? work by itself|blockers? stop by themselves|"
    r"replacement authority|replaces? local tests|replaces? github)\b",
    re.IGNORECASE,
)
AUTHORITY_NEGATION_PATTERN = re.compile(
    r"\b(not|no|never|without|cannot|does not|do not|is not|are not|not a|not authority|"
    r"not closure truth|doesn't)\b",
    re.IGNORECASE,
)
BMA_CANONICAL_PATTERN = re.compile(
    r"\b(BMA|Build Meta Analysis|build-meta-analysis)\b.{0,100}"
    r"\b(canonical|authority|authoritative|source of truth|outranks?|must follow)\b|"
    r"\b(canonical|authority|authoritative|source of truth|outranks?|must follow)\b.{0,100}"
    r"\b(BMA|Build Meta Analysis|build-meta-analysis)\b",
    re.IGNORECASE | re.DOTALL,
)
FLEET_FINDING_PATTERN = re.compile(
    r"\b(fleet findings?|repo[- ]star findings?|cross[- ]repo findings?|"
    r"downstream findings?|repo-agent fleet|core[- ]five findings?)\b",
    re.IGNORECASE,
)
FLEET_ADVISORY_PATTERN = re.compile(
    r"\b(advisory until owner evidence|not owner[- ]binding|owner evidence exists|"
    r"until tied to (?:target|owner) evidence|owner routing|target evidence)\b",
    re.IGNORECASE,
)
SKILL_OR_CAPABILITY_CONVENTION_PATH_PATTERN = re.compile(
    r"(^|/)(?:\.agents/skills|\.github/skills|skills)/[^/]+/(?:SKILL\.md|[^/]+\.(?:md|txt|yml|yaml|json))$|"
    r"(^|/)(?:\.github/agents|\.agents)/[^/]+\.agent\.md$",
    re.IGNORECASE,
)
SKILL_OR_CAPABILITY_CONVENTION_TEXT_PATTERN = re.compile(
    r"\b(skill system|repo-agent capability|repo[- ]agent capability|capability convention|"
    r"capability surface|capability registry|agent skill|skills/)\b",
    re.IGNORECASE,
)
EXTERNAL_CRITIQUE_MODEL_RUNTIME_PATTERNS = {
    "requested_path": re.compile(r"\b(requested[_ -]?path|requested[_ -]?provider|requested[_ -]?route)\b", re.IGNORECASE),
    "requested_model": re.compile(r"\b(requested[_ -]?model|model[_ -]?requested)\b", re.IGNORECASE),
    "actual_responding_path": re.compile(
        r"\b(actual[_ -]?responding[_ -]?path|actual[_ -]?path|responding[_ -]?path|"
        r"actual[_ -]?responding[_ -]?provider|responding[_ -]?provider)\b",
        re.IGNORECASE,
    ),
    "actual_responding_model": re.compile(
        r"\b(actual[_ -]?responding[_ -]?model|actual[_ -]?model|responding[_ -]?model)\b",
        re.IGNORECASE,
    ),
    "unavailable_disposition": re.compile(
        r"\b(unavailable[_ -]?disposition|model[_ -]?unavailable|model[_ -]?not[_ -]?available|"
        r"provider[_ -]?unavailable|provider[_ -]?not[_ -]?available|fallback disposition)\b",
        re.IGNORECASE,
    ),
}
EXTERNAL_CRITIQUE_MODEL_RUNTIME_REQUIRED_FIELDS = frozenset(EXTERNAL_CRITIQUE_MODEL_RUNTIME_PATTERNS)


def external_critique_role(path: str) -> str:
    lowered = path.lower()
    name = Path(path).name.lower()
    if lowered.startswith(".github/workflows/"):
        return "workflow"
    if path == "Makefile" or name == "makefile":
        return "make_target"
    if ".agents/skills/" in lowered or ".github/skills/" in lowered or "/skills/" in lowered:
        return "skill"
    if lowered.startswith(".github/prompts/") or lowered.endswith((".prompt", ".prompt.md")) or "prompt" in name:
        return "prompt"
    if (
        path in INSTRUCTION_FILES
        or lowered.startswith(".github/agents/")
        or lowered.endswith(".agent.md")
        or name in {"agents.md", "agent.md", "codex.md", "claude.md", "gemini.md"}
    ):
        return "agent_instruction"
    if lowered.startswith("scripts/") or "/scripts/" in lowered or lowered.startswith("tools/") or "/tools/" in lowered:
        return "runner"
    if lowered.startswith("docs/") or name in {"readme.md", "learnings.md"}:
        return "docs"
    return "docs" if lowered.endswith((".md", ".txt")) else "other"


def external_critique_semantic_hit_count(text: str) -> int:
    return sum(pattern.search(text) is not None for pattern in EXTERNAL_CRITIQUE_SEMANTIC_PATTERNS.values())


def is_external_critique_capability_surface(path: str, text: str) -> bool:
    if is_instrumentation_noise_path(path):
        return False
    if EXTERNAL_CRITIQUE_TOKEN_PATTERN.search(text):
        return True
    if not EXTERNAL_CRITIQUE_CONCEPT_PATTERN.search(text):
        return False
    return external_critique_semantic_hit_count(text) >= 2


def is_skill_or_capability_convention_surface(path: str, text: str) -> bool:
    if is_instrumentation_noise_path(path):
        return False
    if SKILL_OR_CAPABILITY_CONVENTION_PATH_PATTERN.search(path):
        return True
    return SKILL_OR_CAPABILITY_CONVENTION_TEXT_PATTERN.search(text) is not None


def external_critique_model_runtime_hits(text: str) -> set[str]:
    if not (
        EXTERNAL_CRITIQUE_TOKEN_PATTERN.search(text)
        or EXTERNAL_CRITIQUE_CONCEPT_PATTERN.search(text)
    ):
        return set()
    if not re.search(r"\b(receipt[-_ ]?output|receipt|output truth|runtime truth)\b", text, re.IGNORECASE):
        return set()
    return {
        name
        for name, pattern in EXTERNAL_CRITIQUE_MODEL_RUNTIME_PATTERNS.items()
        if pattern.search(text)
    }


def external_critique_has_authority_overclaim(text: str) -> bool:
    for line in text.splitlines():
        if not AUTHORITY_OVERCLAIM_PATTERN.search(line):
            continue
        if AUTHORITY_NEGATION_PATTERN.search(line):
            continue
        return True
    return False


def external_critique_has_bma_canonical_drift(text: str) -> bool:
    if not BMA_CANONICAL_PATTERN.search(text):
        return False
    return BMA_TRANSLATION_PATTERN.search(text) is None


def external_critique_health(texts: dict[str, str]) -> dict[str, Any]:
    evidence_texts = owner_evidence_texts(texts)
    responder_truth_files = rels_matching(
        evidence_texts,
        lambda path, text: re.search(r"\b(responder truth|responder-truth|truth.*output|output.*truth)\b", text) is not None,
    )
    receipt_output_files = rels_matching(
        evidence_texts,
        lambda path, text: re.search(r"\b(receipt-output|receipt.*output|output.*receipt|receipt.*mismatch)\b", text) is not None,
    )
    helper_only_files = rels_matching(
        evidence_texts,
        lambda path, text: re.search(r"\b(helper-only|helper only|helper-only misclassification)\b", text) is not None,
    )
    bounded_calibration_files = rels_matching(
        evidence_texts,
        lambda path, text: re.search(
            r"\b(external_critique_health|bounded_current_anchor|bounded_calibrated|downstream_admission\b.{0,24}\bbounded)\b",
            text,
        )
        is not None,
    )
    validation_files = rels_matching(
        texts,
        lambda path, text: path not in SELF_INSTRUMENTATION_PATHS
        and (
            path.endswith(".sh")
            or path.endswith(".py")
            or path.endswith(".md")
        )
        and re.search(r"\b(test|validate|assert|receipt)\b", text) is not None,
    )

    capability_surfaces = {
        path: text
        for path, text in evidence_texts.items()
        if is_external_critique_capability_surface(path, text)
    }
    skill_or_capability_convention_paths = sorted(
        path
        for path, text in evidence_texts.items()
        if is_skill_or_capability_convention_surface(path, text)
        and not is_external_critique_capability_surface(path, text)
    )
    model_runtime_truth_hits: dict[str, set[str]] = {
        path: hits
        for path, text in evidence_texts.items()
        if (hits := external_critique_model_runtime_hits(text))
    }
    model_runtime_truth_paths = sorted(model_runtime_truth_hits)
    model_runtime_truth_complete_paths = sorted(
        path
        for path, hits in model_runtime_truth_hits.items()
        if EXTERNAL_CRITIQUE_MODEL_RUNTIME_REQUIRED_FIELDS.issubset(hits)
    )
    model_runtime_truth_path_set = set(model_runtime_truth_paths)
    model_runtime_field_counts = Counter(
        field for hits in model_runtime_truth_hits.values() for field in hits
    )
    legacy_observed_classes = sum(
        bool([path for path in bucket if path not in model_runtime_truth_path_set])
        for bucket in (
            responder_truth_files,
            receipt_output_files,
            helper_only_files,
            bounded_calibration_files,
        )
    )
    legacy_validation_files = [
        path for path in validation_files if path not in model_runtime_truth_path_set
    ]
    legacy_health_fired = legacy_observed_classes >= 2 and len(legacy_validation_files) >= 1
    paths_by_role: dict[str, list[str]] = {role: [] for role in (
        "runner",
        "prompt",
        "skill",
        "make_target",
        "docs",
        "workflow",
        "agent_instruction",
        "other",
    )}
    for path in sorted(capability_surfaces):
        paths_by_role[external_critique_role(path)].append(path)
    prompt_only_external_critique = (
        bool(paths_by_role["prompt"])
        and not any(paths for role, paths in paths_by_role.items() if role != "prompt")
    )

    evidence_class_counts: dict[str, int] = {
        "missing_capability": 0,
        "stale_bma_copy": 0,
        "local_principle_drift": 0,
        "panel_without_context": 0,
        "forced_finding_quota": 0,
        "no_loop_cap": 0,
        "no_local_authority_refs": 0,
        "privacy_boundary_missing": 0,
    }
    extra_drift_counts: dict[str, int] = {
        "blocker_advisory_missing": 0,
        "fleet_advisory_missing": 0,
        "contract_version_drift": 0,
        "prompt_only_external_critique": 0,
        "model_runtime_truth_missing": 0,
    }
    semantic_support_counts = Counter()
    class_evidence: list[str] = []
    local_version_records: list[str] = []

    if not capability_surfaces:
        evidence_class_counts["missing_capability"] = 1
        class_evidence.append("missing_capability=>no target-local external-critique capability surface")
    else:
        if prompt_only_external_critique and skill_or_capability_convention_paths:
            extra_drift_counts["prompt_only_external_critique"] = 1
            class_evidence.append(
                "prompt_only_external_critique=>"
                f"prompt:{','.join(paths_by_role['prompt'][:3])};"
                f"convention:{','.join(skill_or_capability_convention_paths[:3])}"
            )
        if not model_runtime_truth_complete_paths:
            extra_drift_counts["model_runtime_truth_missing"] = 1
            class_evidence.append(
                "model_runtime_truth_missing=>no external-critique receipt/output model-runtime truth fields"
            )
        for path, text in sorted(capability_surfaces.items()):
            role = external_critique_role(path)
            version_match = EXTERNAL_CRITIQUE_VERSION_PATTERN.search(text)
            if version_match:
                version = version_match.group(1)
                local_version_records.append(f"{path}=>{version}")
                if version != EXTERNAL_CRITIQUE_CONTRACT_VERSION:
                    extra_drift_counts["contract_version_drift"] += 1
                    class_evidence.append(f"contract_version_drift=>{path}:{version}")

            if CONTEXT_SUPPORT_PATTERN.search(text):
                semantic_support_counts["context_support"] += 1
            if PANEL_PATTERN.search(text):
                semantic_support_counts["panel_surface"] += 1
                if NAMED_HIGH_STAKES_CONTEXT_PATTERN.search(text):
                    semantic_support_counts["named_high_stakes_context"] += 1
                else:
                    evidence_class_counts["panel_without_context"] += 1
                    class_evidence.append(f"panel_without_context=>{path}")
            if FORCED_FINDING_QUOTA_PATTERN.search(text) and not NO_FORCED_FINDING_QUOTA_PATTERN.search(text):
                evidence_class_counts["forced_finding_quota"] += 1
                class_evidence.append(f"forced_finding_quota=>{path}")
            if NO_FORCED_FINDING_QUOTA_PATTERN.search(text):
                semantic_support_counts["no_forced_finding_quota"] += 1
            if BLOCKER_ADVISORY_PATTERN.search(text):
                semantic_support_counts["blocker_advisory_support"] += 1
            else:
                extra_drift_counts["blocker_advisory_missing"] += 1
                class_evidence.append(f"blocker_advisory_missing=>{path}")
            if LOOP_CAP_PATTERN.search(text):
                semantic_support_counts["loop_cap_support"] += 1
            else:
                evidence_class_counts["no_loop_cap"] += 1
                class_evidence.append(f"no_loop_cap=>{path}")
            if LOCAL_AUTHORITY_REF_PATTERN.search(text):
                semantic_support_counts["local_authority_refs"] += 1
            else:
                evidence_class_counts["no_local_authority_refs"] += 1
                class_evidence.append(f"no_local_authority_refs=>{path}")
            if PRIVACY_BOUNDARY_PATTERN.search(text):
                semantic_support_counts["privacy_boundary"] += 1
            else:
                evidence_class_counts["privacy_boundary_missing"] += 1
                class_evidence.append(f"privacy_boundary_missing=>{path}")
            if BMA_ONLY_TERM_PATTERN.search(text):
                semantic_support_counts["bma_term_surface"] += 1
                if BMA_TRANSLATION_PATTERN.search(text):
                    semantic_support_counts["bma_translation"] += 1
                else:
                    evidence_class_counts["stale_bma_copy"] += 1
                    class_evidence.append(f"stale_bma_copy=>{path}")
            if external_critique_has_authority_overclaim(text) or external_critique_has_bma_canonical_drift(text):
                evidence_class_counts["local_principle_drift"] += 1
                class_evidence.append(f"local_principle_drift=>{path}")
            if FLEET_FINDING_PATTERN.search(text):
                semantic_support_counts["fleet_finding_surface"] += 1
                if FLEET_ADVISORY_PATTERN.search(text):
                    semantic_support_counts["fleet_advisory_until_owner_evidence"] += 1
                else:
                    extra_drift_counts["fleet_advisory_missing"] += 1
                    class_evidence.append(f"fleet_advisory_missing=>{path}")
            semantic_support_counts[f"role_{role}"] += 1

    active_evidence_classes = [
        name for name, count in {**evidence_class_counts, **extra_drift_counts}.items() if count
    ]
    fired = legacy_health_fired or bool(active_evidence_classes)
    role_details = [
        f"{role}=>{','.join(paths[:4])}"
        for role, paths in paths_by_role.items()
        if paths
    ]
    prompt_only_external_critique_count = 1 if prompt_only_external_critique else 0
    details = [
        f"responder_truth=>{','.join(responder_truth_files[:4]) or 'none'}",
        f"receipt_output=>{','.join(receipt_output_files[:4]) or 'none'}",
        f"helper_only=>{','.join(helper_only_files[:4]) or 'none'}",
        f"bounded_calibration=>{','.join(bounded_calibration_files[:4]) or 'none'}",
        f"validation=>{','.join(validation_files[:4]) or 'none'}",
        f"capability_roles=>{';'.join(role_details) or 'missing'}",
        f"evidence_classes=>{';'.join(class_evidence[:8]) or 'none'}",
    ]
    if evidence_class_counts["missing_capability"]:
        reason = "external critique capability surface is missing"
    elif active_evidence_classes:
        reason = "external critique capability surfaces have localization, admission, or authority drift"
    elif legacy_health_fired:
        reason = "repo exposes two or more critique-health evidence classes with validation support"
    else:
        reason = "external critique capability is absent from drift classes or is locally bounded"

    return {
        "fired": fired,
        "signals": {
            "responder_truth_file_count": len(responder_truth_files),
            "receipt_output_file_count": len(receipt_output_files),
            "helper_only_file_count": len(helper_only_files),
            "bounded_calibration_file_count": len(bounded_calibration_files),
            "validation_file_count": len(validation_files),
            "contract_semantics_source": EXTERNAL_CRITIQUE_CONTRACT_SOURCE,
            "contract_source_version": EXTERNAL_CRITIQUE_CONTRACT_VERSION,
            "external_critique_capability_present": bool(capability_surfaces),
            "external_critique_mechanism_count": len(capability_surfaces),
            "mechanism_roles": [role for role, paths in paths_by_role.items() if paths],
            "mechanism_paths_by_role": {role: paths for role, paths in paths_by_role.items() if paths},
            "skill_or_capability_convention_present": bool(skill_or_capability_convention_paths),
            "skill_or_capability_convention_paths": skill_or_capability_convention_paths,
            "prompt_only_external_critique_count": prompt_only_external_critique_count,
            "prompt_only_external_critique_drift_count": extra_drift_counts["prompt_only_external_critique"],
            "model_runtime_truth_file_count": len(model_runtime_truth_paths),
            "model_runtime_truth_paths": model_runtime_truth_paths,
            "model_runtime_truth_complete_file_count": len(model_runtime_truth_complete_paths),
            "model_runtime_truth_complete_paths": model_runtime_truth_complete_paths,
            "model_runtime_truth_missing_count": extra_drift_counts["model_runtime_truth_missing"],
            "requested_path_evidence_count": model_runtime_field_counts["requested_path"],
            "requested_model_evidence_count": model_runtime_field_counts["requested_model"],
            "actual_responding_path_evidence_count": model_runtime_field_counts["actual_responding_path"],
            "actual_responding_model_evidence_count": model_runtime_field_counts["actual_responding_model"],
            "unavailable_disposition_evidence_count": model_runtime_field_counts["unavailable_disposition"],
            "local_version_records": local_version_records,
            "local_version_unknown_count": max(len(capability_surfaces) - len(local_version_records), 0),
            "context_support_count": semantic_support_counts["context_support"],
            "panel_surface_count": semantic_support_counts["panel_surface"],
            "named_high_stakes_context_count": semantic_support_counts["named_high_stakes_context"],
            "no_forced_finding_quota_count": semantic_support_counts["no_forced_finding_quota"],
            "blocker_advisory_support_count": semantic_support_counts["blocker_advisory_support"],
            "loop_cap_support_count": semantic_support_counts["loop_cap_support"],
            "local_authority_ref_count": semantic_support_counts["local_authority_refs"],
            "privacy_boundary_count": semantic_support_counts["privacy_boundary"],
            "bma_term_surface_count": semantic_support_counts["bma_term_surface"],
            "bma_translation_count": semantic_support_counts["bma_translation"],
            "fleet_finding_surface_count": semantic_support_counts["fleet_finding_surface"],
            "fleet_advisory_until_owner_evidence_count": semantic_support_counts[
                "fleet_advisory_until_owner_evidence"
            ],
            "evidence_class_counts": evidence_class_counts,
            "extra_drift_counts": extra_drift_counts,
            "active_evidence_classes": active_evidence_classes,
        },
        "evidence": evidence_join(details),
        "reason": reason,
    }


TOKEN_FIELD_PATTERN = re.compile(
    r"\b(input_tokens|output_tokens|total_tokens|prompt_tokens|completion_tokens|"
    r"cached_tokens|cache_read_tokens|cache_write_tokens|reasoning_tokens|live_tokens|"
    r"context_load_tokens|token_count|tokens_by_model)\b"
)
COST_ESTIMATE_PATTERN = re.compile(
    r"(\$[0-9][0-9,]*(?:\.[0-9]+)?|usd\s*[0-9][0-9,]*(?:\.[0-9]+)?|"
    r"\b(cost|dollar|spend|price|pricing|estimate|estimated)\b)"
)
# A bare ``$<digit>`` is ambiguous: shell positionals ($1, $2), awk fields
# ($$1), and template placeholders match it just as readily as money. Only treat
# a dollar amount as a cost claim when it is unambiguously money-shaped (decimal,
# thousands grouping, magnitude/currency suffix, or ``usd N``) OR co-occurs with
# a money-context word. Applied to lowercased text (see cost_without_token_fields).
UNAMBIGUOUS_MONEY_DOLLAR = (
    r"\$[0-9][0-9,]*\.[0-9]+"                                  # $5.00, $1,234.56
    r"|\$[0-9]{1,3}(?:,[0-9]{3})+"                             # $1,000, $12,500
    r"|\$[0-9][0-9,]*(?:\.[0-9]+)?\s*(?:k|m|bn|b)\b"           # $5k, $1.5m
    r"|\$[0-9][0-9,]*(?:\.[0-9]+)?\s*(?:/|per\b|usd|dollar)"   # $5/mo, $5 usd
    r"|usd\s*[0-9][0-9,]*(?:\.[0-9]+)?"                        # usd 5000
)
MONEY_CONTEXT_WORD = (
    r"(?:cost|costs|spend|spent|price|pricing|priced|budget|"
    r"estimate|estimated|usd|dollars?)"
)
DIRECT_COST_CLAIM_PATTERN = re.compile(
    r"(" + UNAMBIGUOUS_MONEY_DOLLAR
    + r"|\b" + MONEY_CONTEXT_WORD + r"\b.{0,80}\$[0-9]"
    + r"|\$[0-9].{0,80}\b" + MONEY_CONTEXT_WORD + r"\b)"
)


def cost_without_token_fields(texts: dict[str, str]) -> dict[str, Any]:
    offenders: list[str] = []
    grounded: list[str] = []
    for path, text in owner_evidence_texts(texts).items():
        lowered = text.lower()
        if not DIRECT_COST_CLAIM_PATTERN.search(lowered):
            continue
        if TOKEN_FIELD_PATTERN.search(lowered):
            grounded.append(path)
        else:
            offenders.append(path)

    details = [
        f"cost_without_tokens=>{','.join(offenders[:4]) or 'none'}",
        f"grounded_cost=>{','.join(grounded[:4]) or 'none'}",
    ]
    return {
        "fired": bool(offenders),
        "signals": {
            "cost_claim_file_count": len(offenders) + len(grounded),
            "cost_without_token_field_count": len(offenders),
            "grounded_cost_file_count": len(grounded),
        },
        "evidence": evidence_join(details),
        "reason": "dollar/cost claims lack direct token fields" if offenders else "cost claims carry direct token fields or are absent",
    }


MODEL_FIELD_PATTERNS = {
    "selected": re.compile(r'"(?:selected|selected_model|selectedModel)"\s*:\s*"([^"]+)"'),
    "current": re.compile(r'"(?:current|current_model|currentModel)"\s*:\s*"([^"]+)"'),
    "model_metrics": re.compile(r'"modelMetrics"\s*:\s*\{[^{}]{0,500}?"model"\s*:\s*"([^"]+)"', re.DOTALL),
}


def normalize_model_name(value: str) -> str:
    return re.sub(r"\s+", " ", value.strip().lower())


def cost_model_mismatch(texts: dict[str, str]) -> dict[str, Any]:
    mismatches: list[str] = []
    matched: list[str] = []
    for path, text in owner_evidence_texts(texts).items():
        extracted: dict[str, str] = {}
        for field, pattern in MODEL_FIELD_PATTERNS.items():
            match = pattern.search(text)
            if match:
                extracted[field] = normalize_model_name(match.group(1))
        if len(extracted) < 2:
            continue
        distinct = sorted(set(extracted.values()))
        detail = f"{path}=>{','.join(f'{key}:{value}' for key, value in sorted(extracted.items()))}"
        if len(distinct) > 1:
            mismatches.append(detail)
        else:
            matched.append(detail)

    details = [
        f"mismatch=>{';'.join(mismatches[:3]) or 'none'}",
        f"matched=>{';'.join(matched[:3]) or 'none'}",
    ]
    return {
        "fired": bool(mismatches),
        "signals": {
            "model_comparison_file_count": len(mismatches) + len(matched),
            "model_mismatch_count": len(mismatches),
            "model_match_count": len(matched),
        },
        "evidence": evidence_join(details, limit=2),
        "reason": "selected/current/modelMetrics model fields disagree" if mismatches else "model comparison fields match or are absent",
    }


AMPLIFICATION_SIGNAL_PATTERN = re.compile(
    r"\b(request_count|requests|tool_calls|tool call|tool_calls_total|tool invocations?|"
    r"api_calls|api requests|turns|fan[- ]?out)\b"
)
AMPLIFICATION_CALLOUT_PATTERN = re.compile(
    r"\b(amplification|fan[- ]?out|multiplier|multiplied|amplified|called out|callout|"
    r"request/tool boundary|tool/request boundary|request-to-tool)\b"
)


def request_tool_amplification_gap(texts: dict[str, str]) -> dict[str, Any]:
    offenders: list[str] = []
    called_out: list[str] = []
    for path, text in owner_evidence_texts(texts).items():
        lowered = text.lower()
        if not AMPLIFICATION_SIGNAL_PATTERN.search(lowered):
            continue
        if not (COST_ESTIMATE_PATTERN.search(lowered) or TOKEN_FIELD_PATTERN.search(lowered)):
            continue
        if AMPLIFICATION_CALLOUT_PATTERN.search(lowered):
            called_out.append(path)
        else:
            offenders.append(path)

    details = [
        f"uncalled=>{','.join(offenders[:4]) or 'none'}",
        f"called_out=>{','.join(called_out[:4]) or 'none'}",
    ]
    return {
        "fired": bool(offenders),
        "signals": {
            "request_tool_cost_file_count": len(offenders) + len(called_out),
            "uncalled_amplification_count": len(offenders),
            "called_out_amplification_count": len(called_out),
        },
        "evidence": evidence_join(details),
        "reason": "request/tool volume appears in cost evidence without an amplification callout" if offenders else "request/tool amplification is called out or absent",
    }


API_PRICING_PATTERN = re.compile(
    r"\b(api[- ]?equivalent|api pricing|pricing reference|price reference|per 1m tokens|"
    r"per million tokens|/1m tokens|\$[0-9.]+\s*/\s*1m)\b"
)
PRICING_SOURCE_PATTERN = re.compile(r"\b(source_url|source url|source:|pricing_source|pricing source)\b")
PRICING_TIMESTAMP_PATTERN = re.compile(r"\b(fetched_at|fetched-at|as_of|as-of|retrieved_at|retrieved-at|timestamp)\b")
DATE_PATTERN = re.compile(r"\b(20[0-9]{2})-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])\b")


def pricing_provenance_gap(texts: dict[str, str]) -> dict[str, Any]:
    from datetime import date

    today = date.today()
    stale: list[str] = []
    missing: list[str] = []
    current: list[str] = []
    for path, text in owner_evidence_texts(texts).items():
        lowered = text.lower()
        if not API_PRICING_PATTERN.search(lowered):
            continue
        dates = []
        for match in DATE_PATTERN.finditer(lowered):
            try:
                dates.append(date(int(match.group(1)), int(match.group(2)), int(match.group(3))))
            except ValueError:
                continue
        has_source = PRICING_SOURCE_PATTERN.search(lowered) is not None
        has_timestamp = PRICING_TIMESTAMP_PATTERN.search(lowered) is not None and bool(dates)
        newest_age_days = (today - max(dates)).days if dates else None
        if not (has_source and has_timestamp):
            missing.append(path)
        elif newest_age_days is not None and newest_age_days > 180:
            stale.append(f"{path}=>{newest_age_days}d")
        else:
            current.append(path)

    fired = bool(missing or stale)
    details = [
        f"missing_provenance=>{','.join(missing[:4]) or 'none'}",
        f"stale_pricing=>{','.join(stale[:4]) or 'none'}",
        f"current_pricing=>{','.join(current[:4]) or 'none'}",
    ]
    return {
        "fired": fired,
        "signals": {
            "api_pricing_file_count": len(missing) + len(stale) + len(current),
            "missing_pricing_provenance_count": len(missing),
            "stale_pricing_reference_count": len(stale),
            "current_pricing_reference_count": len(current),
        },
        "evidence": evidence_join(details),
        "reason": "API-equivalent pricing references are stale or missing fetched/source timestamps" if fired else "API-equivalent pricing references carry current provenance or are absent",
    }


PRODUCTION_DEFAULT_PATTERN = re.compile(
    r"\b(production_default|production default|default_enablement|default enablement|"
    r"enabled_by_default|enabled by default|default enabled|auto_enable|auto-enabled|"
    r"enable_by_default|enable by default)\b"
)
ENABLEMENT_TRUE_PATTERN = re.compile(r"\b(true|yes|enabled|on|active|shipping|rollout|production)\b")
ENABLEMENT_AUTH_PATTERN = re.compile(
    r"\b(operator approved|human sign[- ]?off|explicit approval|owner approval|approval:\s*approved)\b"
)
MISSING_ENABLEMENT_AUTH_PATTERN = re.compile(
    r"\b(no (operator |owner |human )?approval|missing (operator |owner |human )?approval|"
    r"without (operator |owner |human )?approval|"
    r"[\"']?(approval_receipt|approved_by|authorized_by|owner approval|explicit approval|human sign[- ]?off)[\"']?"
    r"\s*[:=]\s*[\"']?(missing|none|false|no|null|n/a|na|0)[\"']?)\b"
)
AUTH_FIELD_VALUE_PATTERN = re.compile(
    r"[\"']?(approved_by|approval_receipt|enablement_authority|authorized_by)[\"']?"
    r"\s*[:=]\s*[\"']?([^\"'\n,}]+)[\"']?",
    re.IGNORECASE,
)


def has_affirmative_enablement_auth(text: str) -> bool:
    lowered = text.lower()
    if ENABLEMENT_AUTH_PATTERN.search(lowered):
        return True
    for match in AUTH_FIELD_VALUE_PATTERN.finditer(text):
        value = match.group(2).strip().strip("\"'").lower()
        if value and value not in {"missing", "none", "false", "no", "null", "n/a", "na", "0"}:
            return True
    return False


def unauthorized_production_default_enablement(texts: dict[str, str]) -> dict[str, Any]:
    offenders: list[str] = []
    authorized: list[str] = []
    for path, text in owner_evidence_texts(texts).items():
        lowered_text = text.lower()
        candidate_lines = []
        for line in text.splitlines():
            lowered = line.lower()
            if (
                PRODUCTION_DEFAULT_PATTERN.search(lowered)
                and ENABLEMENT_TRUE_PATTERN.search(lowered)
            ):
                candidate_lines.append(line.strip()[:120])
        if not candidate_lines:
            continue
        if MISSING_ENABLEMENT_AUTH_PATTERN.search(lowered_text):
            offenders.append(f"{path}=>{candidate_lines[0]}")
        elif has_affirmative_enablement_auth(text):
            authorized.append(path)
        else:
            offenders.append(f"{path}=>{candidate_lines[0]}")

    details = [
        f"unauthorized_default=>{';'.join(offenders[:3]) or 'none'}",
        f"authorized_default=>{','.join(authorized[:4]) or 'none'}",
    ]
    return {
        "fired": bool(offenders),
        "signals": {
            "production_default_enablement_count": len(offenders) + len(authorized),
            "unauthorized_default_enablement_count": len(offenders),
            "authorized_default_enablement_count": len(authorized),
        },
        "evidence": evidence_join(details, limit=2),
        "reason": "production/default enablement lacks explicit operator or owner approval" if offenders else "production/default enablement is authorized or absent",
    }


ENABLEMENT_CLAIM_PATTERN = re.compile(
    r"\b(production_default|production default|default_enablement|default enablement|"
    r"enabled_by_default|enabled by default|default enabled|production rollout|"
    r"enabled in production|public launch|shipping default|live default)\b"
)
CONTROL_PROOF_PATTERN = re.compile(
    r"\b(rollback_receipt|rollback receipt|rollback tested|rollback plan|rollback proof|"
    r"control_receipt|control receipt|control proof|kill switch|disable path|"
    r"feature flag|revert plan|recovery proof)\b"
)
AFFIRMATIVE_CONTROL_PROOF_PATTERN = re.compile(
    r"\b(rollback_receipt|rollback receipt|rollback proof|control_receipt|control receipt|"
    r"control proof|kill switch|disable path|feature flag|revert plan|recovery proof)\b"
    r".{0,80}\b(retained|tested|verified|present|true|yes|available|approved|exists|documented)\b|"
    r"\b(rollback tested|kill switch tested|disable path verified)\b"
)
MISSING_CONTROL_PATTERN = re.compile(
    r"\b(no rollback|missing rollback|rollback: none|rollback none|without rollback|"
    r"no control proof|control proof: missing|missing control proof|no disable path|"
    r"rollback/control proof missing|rollback_receipt:\s*(missing|none|false|no|null)|"
    r"control_receipt:\s*(missing|none|false|no|null)|rollback proof:\s*(missing|none|false|no|null)|"
    r"control proof:\s*(missing|none|false|no|null)|"
    r"final[_ -]?(feature[_ -]?)?config(?:ured)?[_ -]?mode\s*:\s*(default|enabled|true)|"
    r"final (feature )?config (remained|stayed|is) (default|enabled)|"
    r"after canary.{0,120}configured[_ -]?mode\s*:\s*default)\b"
)


def missing_rollback_control_proof(texts: dict[str, str]) -> dict[str, Any]:
    offenders: list[str] = []
    controlled: list[str] = []
    for path, text in owner_evidence_texts(texts).items():
        lowered = text.lower()
        if not ENABLEMENT_CLAIM_PATTERN.search(lowered):
            continue
        has_control = AFFIRMATIVE_CONTROL_PROOF_PATTERN.search(lowered) is not None
        missing_control = MISSING_CONTROL_PATTERN.search(lowered) is not None
        if missing_control or not has_control:
            offenders.append(path)
        else:
            controlled.append(path)

    details = [
        f"missing_control=>{','.join(offenders[:4]) or 'none'}",
        f"controlled=>{','.join(controlled[:4]) or 'none'}",
    ]
    return {
        "fired": bool(offenders),
        "signals": {
            "enablement_claim_file_count": len(offenders) + len(controlled),
            "missing_rollback_control_count": len(offenders),
            "rollback_control_proven_count": len(controlled),
        },
        "evidence": evidence_join(details),
        "reason": "production/default enablement lacks rollback or control proof" if offenders else "enablement claims carry rollback/control proof or are absent",
    }


READINESS_CLAIM_PATTERN = re.compile(
    r"\b(production ready|ready for production|readiness:\s*ready|release ready|"
    r"publication ready|rollout ready|admitted for production|"
    r"[\"']?readiness_status[\"']?\s*:\s*[\"']?(ready|pass|passed)[\"']?|"
    r"[\"']?production_readiness[\"']?\s*:\s*[\"']?(ready|pass|passed)[\"']?)\b"
)
AGGREGATE_READINESS_PATTERN = re.compile(
    r"\b(aggregate[_ -]?only|summary[_ -]?only|overall|aggregate pass rate|"
    r"aggregate_pass_rate|fleet average|composite score|mean score|rollup|summary readiness)\b"
)
PER_CASE_EVIDENCE_PATTERN = re.compile(
    r"\b(per[-_ ]?case|case receipts?|fixture receipts?|row[-_ ]?level|per[-_ ]?repo|"
    r"drilldown|evidence packets?|individual runs?|sample ids?|case_ids?|case_ids|"
    r"per_case_receipts)\b"
)
MISSING_PER_CASE_EVIDENCE_PATTERN = re.compile(
    r"\b(no per[-_ ]?case|missing per[-_ ]?case|without per[-_ ]?case|"
    r"no case receipts?|missing case receipts?|"
    r"[\"']?(case receipts?|per_case_receipts|fixture_receipts|evidence_packets|"
    r"individual_runs|case_ids?|sample_ids?|row[-_ ]?level)[\"']?"
    r"\s*[:=]\s*[\"']?(missing|none|false|no|null|n/a|na|0|\[\])[\"']?|"
    r"no row[-_ ]?level)\b"
)
PER_CASE_FIELD_VALUE_PATTERN = re.compile(
    r"[\"']?(per_case_receipts|case_ids?|sample_ids?|fixture_receipts|evidence_packets|individual_runs)[\"']?"
    r"\s*[:=]\s*(\[[^\]\n]*\]|[\"']?[^\"'\n,}]+[\"']?)",
    re.IGNORECASE,
)
POSITIVE_PER_CASE_TEXT_PATTERN = re.compile(
    r"\b(per[-_ ]?case receipts? retained|case[-_ ]?level receipts? retained|"
    r"row[-_ ]?level receipts? retained|evidence packets? retained|individual runs? retained)\b"
)


def has_affirmative_per_case_evidence(text: str) -> bool:
    lowered = text.lower()
    if POSITIVE_PER_CASE_TEXT_PATTERN.search(lowered):
        return True
    for match in PER_CASE_FIELD_VALUE_PATTERN.finditer(text):
        value = match.group(2).strip().strip("\"'").lower()
        if value.startswith("[") and value.endswith("]"):
            inner = value[1:-1].strip()
            if inner and inner not in {"missing", "none", "false", "no", "null"}:
                return True
        elif value and value not in {"missing", "none", "false", "no", "null", "n/a", "na", "0", "[]"}:
            return True
    return False


def aggregate_only_readiness(texts: dict[str, str]) -> dict[str, Any]:
    offenders: list[str] = []
    grounded: list[str] = []
    for path, text in owner_evidence_texts(texts).items():
        lowered = text.lower()
        if not READINESS_CLAIM_PATTERN.search(lowered):
            continue
        if not AGGREGATE_READINESS_PATTERN.search(lowered):
            continue
        if MISSING_PER_CASE_EVIDENCE_PATTERN.search(lowered):
            offenders.append(path)
        elif has_affirmative_per_case_evidence(text):
            grounded.append(path)
        else:
            offenders.append(path)

    details = [
        f"aggregate_only=>{','.join(offenders[:4]) or 'none'}",
        f"case_grounded=>{','.join(grounded[:4]) or 'none'}",
    ]
    return {
        "fired": bool(offenders),
        "signals": {
            "aggregate_readiness_file_count": len(offenders) + len(grounded),
            "aggregate_only_readiness_count": len(offenders),
            "case_grounded_readiness_count": len(grounded),
        },
        "evidence": evidence_join(details),
        "reason": "readiness is claimed from aggregate-only evidence" if offenders else "readiness claims include case-level evidence or are absent",
    }


TOKEN_EVIDENCE_CONTEXT_PATTERN = re.compile(
    r"\b(direct token|token evidence|token telemetry|input_tokens|output_tokens|"
    r"total_tokens|live_tokens|cached_tokens|cache_read_tokens|cache_write_tokens|token_count)\b"
)


def stale_direct_token_evidence(texts: dict[str, str]) -> dict[str, Any]:
    from datetime import date

    today = date.today()
    stale_threshold_days = 30
    stale: list[str] = []
    current: list[str] = []
    undated: list[str] = []
    for path, text in owner_evidence_texts(texts).items():
        lowered = text.lower()
        if not TOKEN_FIELD_PATTERN.search(lowered) or not TOKEN_EVIDENCE_CONTEXT_PATTERN.search(lowered):
            continue
        dates = []
        for match in DATE_PATTERN.finditer(lowered):
            try:
                dates.append(date(int(match.group(1)), int(match.group(2)), int(match.group(3))))
            except ValueError:
                continue
        if not dates:
            undated.append(path)
            continue
        newest_age_days = (today - max(dates)).days
        if newest_age_days > stale_threshold_days:
            stale.append(f"{path}=>{newest_age_days}d")
        else:
            current.append(path)

    details = [
        f"stale_token_evidence=>{','.join(stale[:4]) or 'none'}",
        f"current_token_evidence=>{','.join(current[:4]) or 'none'}",
        f"undated_token_evidence=>{','.join(undated[:4]) or 'none'}",
    ]
    return {
        "fired": bool(stale),
        "signals": {
            "direct_token_evidence_file_count": len(stale) + len(current) + len(undated),
            "stale_direct_token_evidence_count": len(stale),
            "current_direct_token_evidence_count": len(current),
            "undated_direct_token_evidence_count": len(undated),
            "stale_threshold_days": stale_threshold_days,
        },
        "evidence": evidence_join(details),
        "reason": "direct token evidence is older than the freshness threshold" if stale else "direct token evidence is current, undated, or absent",
    }


CUSTOMER_NEWSLETTER_PATTERN = re.compile(r"\bcustomernewsletter\b")
PUBLIC_CUSTOMER_NEWSLETTER_PATTERN = re.compile(
    r"(/users/\S+/repos/customernewsletter|github\.com/\S+/customernewsletter|"
    r"\bpublic\s+customernewsletter\b|\bcustomernewsletter\s+public\b|"
    r"\bpublic\s+repo:\s*customernewsletter\b)"
)
MUTATION_ACTION_PATTERN = re.compile(
    r"\b(modify|modifies|modified|editing|edits|edited|write|writes|wrote|written|"
    r"commit|commits|committed|push|pushes|pushed|land|lands|landed|"
    r"applied|apply changes|changed|opened pr|open pr|prs?|pull request|production authoring)\b"
)
CUSTOMER_NEWSLETTER_GUARDRAIL_PATTERN = re.compile(
    r"\b(forbidden|do not mutate|read-only|read only|downstream-only|downstream only|"
    r"blocked|not allowed|no mutation|would violate|should not|landing zone)\b"
)


def forbidden_public_customernewsletter_mutation(texts: dict[str, str]) -> dict[str, Any]:
    offenders: list[str] = []
    guarded: list[str] = []
    for path, text in owner_evidence_texts(texts).items():
        for line in text.splitlines():
            lowered = line.lower()
            if not CUSTOMER_NEWSLETTER_PATTERN.search(lowered):
                continue
            if not PUBLIC_CUSTOMER_NEWSLETTER_PATTERN.search(lowered):
                continue
            if not MUTATION_ACTION_PATTERN.search(lowered):
                continue
            if CUSTOMER_NEWSLETTER_GUARDRAIL_PATTERN.search(lowered):
                guarded.append(path)
            else:
                offenders.append(f"{path}=>{line.strip()[:120]}")

    details = [
        f"forbidden_mutation=>{';'.join(offenders[:3]) or 'none'}",
        f"guarded_mentions=>{','.join(sorted(set(guarded))[:4]) or 'none'}",
    ]
    return {
        "fired": bool(offenders),
        "signals": {
            "public_customernewsletter_mutation_count": len(offenders),
            "guarded_customernewsletter_mention_count": len(set(guarded)),
        },
        "evidence": evidence_join(details, limit=2),
        "reason": "public CustomerNewsletter mutation is claimed without a guardrail boundary" if offenders else "public CustomerNewsletter mutation is absent or explicitly blocked",
    }


COPIED_EVIDENCE_PATTERN = re.compile(r"\b(copied evidence|copied-evidence|evidence payload|review payload|verbatim evidence)\b")
AUTHOR_BOUNDARY_PATTERN = re.compile(
    r"\b(authored claims?|author claims?|claims boundary|copied evidence boundary|"
    r"copied_evidence|authored_claims|boundary between copied evidence and authored claims)\b"
)
CLAIM_PATTERN = re.compile(r"\b(conclude|therefore|proves|shows|recommend|should|claim|finding)\b")


def copied_evidence_boundary_gap(texts: dict[str, str]) -> dict[str, Any]:
    offenders: list[str] = []
    bounded: list[str] = []
    for path, text in owner_evidence_texts(texts).items():
        lowered = text.lower()
        if not COPIED_EVIDENCE_PATTERN.search(lowered):
            continue
        quoted_lines = sum(1 for line in text.splitlines() if line.lstrip().startswith((">", "|")))
        long_payload = len(text) > 2500 or quoted_lines >= 8
        claim_present = CLAIM_PATTERN.search(lowered) is not None
        has_boundary = AUTHOR_BOUNDARY_PATTERN.search(lowered) is not None
        if (long_payload or claim_present) and not has_boundary:
            offenders.append(f"{path}=>quoted_lines:{quoted_lines}")
        else:
            bounded.append(path)

    details = [
        f"unclear_boundary=>{','.join(offenders[:4]) or 'none'}",
        f"bounded_payload=>{','.join(bounded[:4]) or 'none'}",
    ]
    return {
        "fired": bool(offenders),
        "signals": {
            "copied_evidence_payload_count": len(offenders) + len(bounded),
            "unclear_boundary_count": len(offenders),
            "bounded_payload_count": len(bounded),
        },
        "evidence": evidence_join(details),
        "reason": "copied evidence payloads blur copied text and authored claims" if offenders else "copied evidence boundaries are explicit or absent",
    }


SOURCE_INTELLIGENCE_SURFACE_PATTERN = re.compile(
    r"\b(source[-_ ]?intelligence|source[-_ ]?insight|source bundle|source manifest|"
    r"research-source-manifest|operator-source-inventory|source_id|SOURCE_INSIGHT_PACKET)\b",
    re.IGNORECASE,
)
SOURCE_INSIGHT_DISPOSITION_PATTERN = re.compile(
    r"\b(insight_disposition|equal[-_ ]?insight|equal first-pass|first-pass insight|"
    r"no_insight|contradiction|inaccessible|insight/no-insight)\b",
    re.IGNORECASE,
)
SOURCE_OWNER_ROUTING_PATTERN = re.compile(
    r"\b(owner_surface|owner[-_ ]?surface|github_issue_candidate|roadmap_disposition|"
    r"explicit_no_action|no_action_reason|owner/no-action|owner routing|owner-directed)\b",
    re.IGNORECASE,
)

SELECTION_HANDBACK_PATTERN = re.compile(
    r"\b(category[- ]?only|hand back selection|selection handback|operator (?:should )?"
    r"(?:choose|pick|select)|choose a category|pick an adoption proof|do real delivery|"
    r"work on repo-star|pick adoption/delivery proof)\b",
    re.IGNORECASE,
)
SELECTION_HANDBACK_NEGATION_PATTERN = re.compile(
    r"\b(no|not|never|without|rejects?|invalid|forbid(?:s|den)?|prevents?)\b.{0,40}"
    r"\b(category[- ]?only|selection handback|hand back selection|operator (?:choose|pick|select)|"
    r"choose a category|pick an adoption proof|do real delivery|adoption/delivery proof|"
    r"work on repo-star)\b",
    re.IGNORECASE,
)
GOAL_MODE_PATTERN = re.compile(r"\b(goal[- ]?mode|codex goal|goal episode)\b", re.IGNORECASE)
TOO_SMALL_GOAL_PATTERN = re.compile(
    r"\b(tiny|too small|small cleanup|one tiny issue|single[- ]file|one[- ]file|"
    r"10 minutes?|standalone cleanup|micro[- ]work)\b",
    re.IGNORECASE,
)
TOO_SMALL_GOAL_NEGATION_PATTERN = re.compile(
    r"\b(not for tiny|not tiny|reserved for (?:a )?batch|larger batch|multi[- ]pr|"
    r"multiple repos|medium-or-larger|larger episode)\b",
    re.IGNORECASE,
)
GITHUB_CLOSURE_TRUTH_PATTERN = re.compile(
    r"\b(github[- ]native (?:closure|closeout|task truth|issue/pr truth|issue and pr closure authority)|"
    r"github issue|issue #\d+|pr #\d+|pull request|merged (?:pr|pull request)|"
    r"closed (?:issue|pr|pull request)|(?:issue|pr|pull request) (?:is |was )?closed)\b",
    re.IGNORECASE,
)
LOCAL_CLOSEOUT_AUTHORITY_PATTERN = re.compile(
    r"\b(local closeout|completion[- ]manifest|work-close|score-session|handoff|"
    r"ser\b|session[- ]end[- ]review|closeout authority|authoritative closeout|"
    r"closure authority|local work packages?|work packages? as (?:closure|task) truth|"
    r"retained report packages?|handoff[- ]sync facts?|local duplicate closure receipts?|"
    r"duplicate closure receipts?|pointer[- ]file compatibility|pointer files?|"
    r"direct[- ]closure self[- ]heal artifacts?|self[- ]heal receipts?|"
    r"local receipt writers?|local receipts? as (?:closure|task) truth)\b",
    re.IGNORECASE,
)
LOCAL_CLOSEOUT_BYPASS_PATTERN = re.compile(
    r"\b(github-native-closeout|github[- ]native closeout|bypass(?:ed)?|"
    r"explicitly bypass(?:ed)?|not re-graded|no local completion authority|"
    r"no local closeout authority|no new local closeout|issue/pr truth is closure authority|"
    r"except for qualifying|do not run|do not add|"
    r"no new.{0,80}local closeout|not for.{0,80}direct closure|"
    r"instead of [`'\"]?(?:make )?work-close|"
    r"score[_-]session[_-]not[_-]authoritative|session grader skipped)\b",
    re.IGNORECASE,
)


def local_authority_match_is_negated(text: str, match: re.Match[str]) -> bool:
    """Return true when the matched local-closeout authority is locally negated."""

    start, end = match.span()
    sentence_start = max(text.rfind(".", 0, start), text.rfind("\n", 0, start), text.rfind(";", 0, start)) + 1
    next_bounds = [idx for idx in (text.find(".", end), text.find("\n", end), text.find(";", end)) if idx != -1]
    sentence_end = min(next_bounds) if next_bounds else len(text)
    prefix = text[sentence_start:start].lower()
    suffix = text[end:sentence_end].lower()
    if re.search(r"\b(no|without)\s+(?:[\w`'\"/-]+\s+){0,4}$", prefix):
        return True
    if re.search(
        r"\b(?:do|does|must|should|may|is|are)\s+not\s+"
        r"(?:(?:require|use|treat|add|make|keep|run)\s+)?(?:[\w`'\"/-]+\s+){0,4}$",
        prefix,
    ):
        return True
    if re.match(
        r"\s+(?:is|are|remains?|remain)?\s*not\s+"
        r"(?:required|authoritative|used|closure authority|task truth)\b",
        suffix,
    ):
        return True
    return False


def has_unnegated_local_closeout_authority(text: str) -> bool:
    return any(
        not local_authority_match_is_negated(text, match)
        for match in LOCAL_CLOSEOUT_AUTHORITY_PATTERN.finditer(text)
    )
CORE_FIVE_SURFACE_PATTERN = re.compile(
    r"\b(core[- ]five|repo[- ]star|fleet repos?|repo[- ]family|"
    r"repo-auditor|repo-upgrade-advisor|repo-optimizer|repo-agent-core)\b",
    re.IGNORECASE,
)
OWNER_SURFACE_EXACT_PATTERN = re.compile(
    r"\b(owner_surface|owner[- ]surface|owner repo|owner repository|"
    r"first deliverable|first PR|repo-auditor owns|repo-upgrade-advisor owns|"
    r"repo-optimizer owns|repo-agent-core owns|BMA owns|"
    r"own issue, branch, PR, checks, and merge)\b",
    re.IGNORECASE,
)
OWNER_SURFACE_AMBIGUITY_PATTERN = re.compile(
    r"\b(owner tbd|pick an owner|choose (?:an )?owner|choose repo|"
    r"some repo|shared capability|move (?:it|this) to (?:the )?fleet|"
    r"work on repo-star|fleet should handle|repo-star should handle|"
    r"distribute later|decide later)\b",
    re.IGNORECASE,
)
CORE_FIVE_VALIDATION_PATTERN = re.compile(
    r"\b(validate|validation|target|scan|audit|test|proving[- ]ground|"
    r"run repo-auditor|run auditor|self-hosted|against each other)\b",
    re.IGNORECASE,
)
RECIPROCAL_PROVING_GROUND_PATTERN = re.compile(
    r"\b(reciprocal proving grounds?|read-only targets?|validate against each other|"
    r"against each other read-only|ordinary validation, not downstream adoption|"
    r"owner issue, branch, PR, checks, and merge|owner-repo mutation boundary)\b",
    re.IGNORECASE,
)
WORK_MANAGEMENT_SIGNATURE_REFERENCE_PATTERN = re.compile(
    r"\b(AS-2[0-9]|AS-3[0-9]|AS-4[0-4]|AS-50|selection handback|too-small goal|too small goal|"
    r"github-native closure regrowth|github native closure regrowth|"
    r"owner-surface ambiguity|owner surface ambiguity|"
    r"reciprocal proving-ground gap|reciprocal proving ground gap|"
    r"goal-mode runtime evidence gap|goal mode runtime evidence gap|"
    r"reactive self-healing loop|shell reserved status-variable|"
    r"reserved status variable|status-variable launch|"
    r"stale/default capability guidance|stale default capability guidance|"
    r"default capability guidance|hermes foreground receipt adoption gap|"
    r"foreground receipt adoption gap|interrupted goal recovery gap|"
    r"fractured serial continuation|unanchored self-learning claim|"
    r"unanchored self learning claim|foreground failure guidance gap|"
    r"closure-run identity gap|closure run identity gap|closure_run_identity_gap|"
    r"closure-run identity|closure run identity|"
    r"upstream capability intake gap|upstream capability intake|"
    r"issue 164 runtime drift|issue #164 runtime drift|"
    r"self-authored campaign pause authority|self authored campaign pause authority|"
    r"campaign pause authority|campaign pause-authority|"
    r"scheduled workflow evidence boundary gap|hermes/github reliability boundary gap|"
    r"campaign sync completed-track readback gap|route-changing learning propagation gap|"
    r"hermes foreground reliability evidence gap|"
    r"hermes foreground failure disposition gap|"
    r"foreground recovery runtime contract)\b",
    re.IGNORECASE,
)
SIGNATURE_DEFINITION_MARKER_PATTERN = re.compile(
    r"\b(detects:|signal:|fire condition:|prevention tier:|severity:|script:|"
    r"triggers?:|recommendation template|detection signature)\b",
    re.IGNORECASE,
)


def is_work_management_signature_explainer(path: str, text: str) -> bool:
    """Suppress detector docs/templates that define work-management AS checks."""

    lowered_path = path.lower()
    # detection-signatures/ is a reference catalog directory by construction
    # (DS-* and AS-* signature definitions); any file there documents what a
    # signature looks for, it does not make an owner claim, regardless of
    # which signature family (DS or AS) its prose happens to describe.
    if lowered_path.startswith("detection-signatures/"):
        return True
    if not WORK_MANAGEMENT_SIGNATURE_REFERENCE_PATTERN.search(text):
        return False
    if "template" in lowered_path and SIGNATURE_DEFINITION_MARKER_PATTERN.search(text):
        return True
    return "signature" in lowered_path and SIGNATURE_DEFINITION_MARKER_PATTERN.search(text)


def is_closure_runtime_distribution_explainer(path: str, text: str) -> bool:
    """Suppress only the shared closure/runtime distribution contract itself."""

    lowered_path = path.lower()
    if not (
        lowered_path.endswith("repo-star-closure-runtime-distribution-contract.md")
        or lowered_path.endswith("repo-star-closure-runtime-distribution.md")
    ):
        return False
    return bool(
        re.search(r"\brepo-star closure runtime distribution\b", text, re.I)
        and re.search(r"\bclosure[- ]ceremony regrowth classes\b", text, re.I)
    )


def source_intelligence_intake_gap(texts: dict[str, str]) -> dict[str, Any]:
    offenders: list[str] = []
    grounded: list[str] = []
    missing_insight = 0
    missing_owner = 0
    package_signals: dict[str, dict[str, Any]] = defaultdict(
        lambda: {"files": [], "has_insight": False, "has_owner": False}
    )

    for path, text in owner_evidence_texts(texts).items():
        if not SOURCE_INTELLIGENCE_SURFACE_PATTERN.search(text):
            continue
        package = str(Path(path).parent)
        if package == ".":
            package = "<root>"
        package_signals[package]["files"].append(path)
        package_signals[package]["has_insight"] = (
            package_signals[package]["has_insight"]
            or SOURCE_INSIGHT_DISPOSITION_PATTERN.search(text) is not None
        )
        package_signals[package]["has_owner"] = (
            package_signals[package]["has_owner"]
            or SOURCE_OWNER_ROUTING_PATTERN.search(text) is not None
        )

    for package, signals in package_signals.items():
        has_insight = signals["has_insight"]
        has_owner = signals["has_owner"]
        if has_insight and has_owner:
            grounded.append(f"{package}=>files:{len(signals['files'])}")
            continue
        if not has_insight:
            missing_insight += 1
        if not has_owner:
            missing_owner += 1
        offenders.append(
            f"{package}=>insight:{has_insight};owner:{has_owner};files:{len(signals['files'])}"
        )

    details = [
        f"intake_gap=>{';'.join(offenders[:4]) or 'none'}",
        f"grounded_intake=>{','.join(grounded[:4]) or 'none'}",
    ]
    return {
        "fired": bool(offenders),
        "signals": {
            "source_intelligence_surface_count": len(offenders) + len(grounded),
            "source_intelligence_gap_count": len(offenders),
            "missing_insight_disposition_count": missing_insight,
            "missing_owner_routing_count": missing_owner,
            "grounded_source_intelligence_count": len(grounded),
        },
        "evidence": evidence_join(details),
        "reason": "source-intelligence surfaces lack equal-insight disposition or owner/no-action routing" if offenders else "source-intelligence surfaces are routed or absent",
    }


UPSTREAM_INTAKE_SURFACE_PATTERN = re.compile(
    r"\b(upstream capability intake|upstream[-_ ]capability[-_ ]intake|"
    r"capability intake|behindness signal|delta clusters|capability decisions)\b",
    re.IGNORECASE,
)
UPSTREAM_INTAKE_REQUIRED_PATTERNS = {
    "component_identity": re.compile(r"\b(component identity|component_identity)\b", re.IGNORECASE),
    "local_version": re.compile(r"\b(local version|local_version)\b", re.IGNORECASE),
    "upstream_reference": re.compile(r"\b(upstream reference|upstream_reference)\b", re.IGNORECASE),
    "behindness_signal": re.compile(r"\b(behindness signal|behindness_signal)\b", re.IGNORECASE),
    "source_refs": re.compile(r"\b(source refs|source_refs|source references)\b", re.IGNORECASE),
    "delta_clusters": re.compile(r"\b(delta clusters|delta_clusters)\b", re.IGNORECASE),
    "capability_decisions": re.compile(r"\b(capability decisions|capability_decisions)\b", re.IGNORECASE),
    "update_action": re.compile(r"\b(update action|update_action)\b", re.IGNORECASE),
    "validation": re.compile(r"\b(validation|validation receipt|validation_receipt)\b", re.IGNORECASE),
    "adoption_plan_refs": re.compile(r"\b(adoption-plan refs|adoption plan refs|adoption_plan_refs)\b", re.IGNORECASE),
    "owner_routes": re.compile(r"\b(owner routes|owner_routes|owner surface|owner_surface)\b", re.IGNORECASE),
    "non_claims": re.compile(r"\b(non-claims|non_claims|bounded non-claims|bounded_non_claims)\b", re.IGNORECASE),
    "out_of_bounds_surfaces": re.compile(
        r"\b(out-of-bounds surfaces|out_of_bounds_surfaces|out of bounds surfaces)\b",
        re.IGNORECASE,
    ),
}
UPSTREAM_INTAKE_UPDATE_CLAIM_PATTERN = re.compile(
    r"\b(adopt|adoption|update now|updated|upgrade|delete/sunset|delete|sunset|native capability|"
    r"behindness reduced|behindness reduction|up to date|behindness:?\s*0)\b",
    re.IGNORECASE,
)
UPSTREAM_INTAKE_MISSING_VALIDATION_PATTERN = re.compile(
    r"\b(validation|validation receipt|validation_receipt)\b.{0,80}\b(missing|none|null|todo|tbd|absent|not retained|unavailable)\b",
    re.IGNORECASE | re.DOTALL,
)
UPSTREAM_INTAKE_STALE_SOURCE_PATTERN = re.compile(
    r"\b(source refs?|source_refs|upstream reference|upstream_reference)\b.{0,100}\b(stale|missing|none|null|todo|tbd|unknown|unverified)\b",
    re.IGNORECASE | re.DOTALL,
)


def upstream_capability_intake_gap(texts: dict[str, str]) -> dict[str, Any]:
    offenders: list[str] = []
    grounded: list[str] = []
    missing_field_records = 0
    update_without_validation = 0
    adoption_without_owner_or_nonclaims = 0
    stale_source_ref_records = 0

    for path, text in owner_evidence_texts(texts).items():
        if is_work_management_signature_explainer(path, text):
            grounded.append(path)
            continue
        if not path.endswith((".md", ".txt", ".json", ".jsonl", ".csv", ".yml", ".yaml")):
            continue
        if not UPSTREAM_INTAKE_SURFACE_PATTERN.search(text):
            continue

        required_hits = {
            name: pattern.search(text) is not None
            for name, pattern in UPSTREAM_INTAKE_REQUIRED_PATTERNS.items()
        }
        missing_keys = [name for name, present in required_hits.items() if not present]
        has_update_claim = UPSTREAM_INTAKE_UPDATE_CLAIM_PATTERN.search(text) is not None
        validation_missing = (
            not required_hits["validation"]
            or UPSTREAM_INTAKE_MISSING_VALIDATION_PATTERN.search(text) is not None
        )
        source_stale = UPSTREAM_INTAKE_STALE_SOURCE_PATTERN.search(text) is not None
        owner_or_nonclaims_missing = not required_hits["owner_routes"] or not required_hits["non_claims"]

        reasons: list[str] = []
        if missing_keys:
            missing_field_records += 1
            reasons.append("missing:" + ",".join(missing_keys[:6]))
        if has_update_claim and validation_missing:
            update_without_validation += 1
            reasons.append("update_without_validation")
        if has_update_claim and owner_or_nonclaims_missing:
            adoption_without_owner_or_nonclaims += 1
            reasons.append("owner_or_nonclaims_missing")
        if source_stale:
            stale_source_ref_records += 1
            reasons.append("stale_or_missing_source_refs")

        if reasons:
            offenders.append(f"{path}=>{';'.join(reasons)}")
        else:
            grounded.append(path)

    details = [
        f"intake_gap=>{';'.join(offenders[:4]) or 'none'}",
        f"grounded_intake=>{','.join(grounded[:4]) or 'none'}",
    ]
    return {
        "fired": bool(offenders),
        "signals": {
            "upstream_intake_record_count": len(offenders) + len(grounded),
            "upstream_intake_gap_count": len(offenders),
            "missing_field_record_count": missing_field_records,
            "update_claim_without_validation_count": update_without_validation,
            "adoption_without_owner_or_nonclaims_count": adoption_without_owner_or_nonclaims,
            "stale_source_ref_record_count": stale_source_ref_records,
        },
        "evidence": evidence_join(details),
        "reason": (
            "upstream capability intake records are incomplete, stale, or claim updates without validation"
            if offenders
            else "upstream capability intake records are field-complete and bounded, or absent"
        ),
    }


GBRAIN_DISTRIBUTION_SURFACE_PATTERN = re.compile(
    r"\b(gbrain[-_ ]repo[-_ ]local[-_ ]instruction[-_ ]distribution|"
    r"gbrain-repo-local-instruction-distribution|"
    r"gbrain\b.{0,120}\b(distribution|repo-local instructions?|instruction surfaces?)|"
    r"(distribution|repo-local instructions?|instruction surfaces?)\b.{0,120}\bgbrain)\b",
    re.IGNORECASE,
)
GBRAIN_EXACT_REPLAY_SURFACE_PATTERN = re.compile(
    r"\b(gbrain\b.{0,160}\b(exact[- ]handle|exact[- ]get|exact replay|operator[- ]intent exact|"
    r"advisor memory|advisory memory)|"
    r"(exact[- ]handle|exact[- ]get|exact replay|operator[- ]intent exact|advisor memory|"
    r"advisory memory)\b.{0,160}\bgbrain)\b",
    re.IGNORECASE,
)
GBRAIN_DISTRIBUTION_RECORD_PATTERN = re.compile(
    r"\b(distribution|repo-local instructions?|instruction surfaces?|"
    r"gbrain-repo-local-instruction-distribution)\b",
    re.IGNORECASE,
)
GBRAIN_SOURCE_EXPECTATION_PATTERN = re.compile(
    r"\b(source/citation/provenance|source refs?|source_refs|citation|citations?|"
    r"provenance|github surface|github issue|github pr|evidence refs?)\b",
    re.IGNORECASE,
)
GBRAIN_ADVISORY_PATTERN = re.compile(
    r"\b(gbrain remains advisory|advisory gbrain|gbrain is advisory)\b",
    re.IGNORECASE,
)
GBRAIN_NEGATED_BOUNDARY_PATTERN = re.compile(
    r"(\b(without|no|not|never|missing|omit|omits|lacks?|absent)\b.{0,40}"
    r"\b(advisory|source refs?|source_refs|source/citation/provenance|citation|citations?|"
    r"provenance|github surface|github issue|github pr|evidence refs?)\b|"
    r"\b(advisory|source refs?|source_refs|source/citation/provenance|citation|citations?|"
    r"provenance|github surface|github issue|github pr|evidence refs?)\b.{0,40}"
    r"\b(not required|not needed|not expected|optional|unnecessary|not mandatory)\b)",
    re.IGNORECASE,
)
GBRAIN_POSITIVE_CANONICAL_PATTERN = re.compile(
    r"\b(gbrain (is|as|becomes|remains)?\s*(the\s*)?(canonical|source of truth|authority)|"
    r"gbrain (overrides?|supersedes|replaces) (operator|github|repo|local instruction)|"
    r"canonical gbrain|gbrain canonicality)\b",
    re.IGNORECASE,
)
GBRAIN_CANONICAL_NEGATION_PATTERN = re.compile(
    r"\b(no|not|never|cannot|can't|does not|do not|must not|forbid|forbidden|without)\b",
    re.IGNORECASE,
)
GBRAIN_BACKGROUND_COMMAND_PATTERN = re.compile(
    r"\b(sync --watch|sync/watch|sync --install-cron|cron|autopilot|dream|jobs work(?:er)?|mcp serving|"
    r"minions?|daemons?|schedulers?|queues?|hidden registr(?:y|ies)|background memory behavior|"
    r"background gbrain behavior|bulk import)\b",
    re.IGNORECASE,
)
GBRAIN_BACKGROUND_PROHIBITION_PATTERN = re.compile(
    r"(\b(do not|must not|never|cannot|can't|does not|forbid|forbidden|without)\b\s*"
    r"(use|run|enable|start|invoke|call)?\s*`?gbrain`?\b.{0,80}"
    r"\b(sync --watch|sync/watch|sync --install-cron|cron|autopilot|dream|jobs work(?:er)?|mcp serving|"
    r"minions?|daemons?|schedulers?|queues?|hidden registr(?:y|ies)|background memory behavior|"
    r"background gbrain behavior|bulk import)\b|"
    r"\b(forbid|forbids|forbidden)\b.{0,40}"
    r"\b(background gbrain behavior|background memory behavior|bulk import|sync/watch|sync --watch)\b|"
    r"\bgbrain\b.{0,80}\b(sync --watch|sync/watch|sync --install-cron|cron|autopilot|dream|jobs work(?:er)?|"
    r"mcp serving|minions?|daemons?|schedulers?|queues?|hidden registr(?:y|ies)|"
    r"background memory behavior|background gbrain behavior|bulk import)\b.{0,40}"
    r"\b(forbidden|not allowed|must not|do not|never)\b)",
    re.IGNORECASE,
)
GBRAIN_FALLBACK_EXPECTATION_PATTERN = re.compile(
    r"\b(fallback without memory|no[- ]memory fallback|fallback disposition|fallback path|"
    r"no[-_ ]capture reason|no_capture_reason|slug or no[- ]capture|without memory)\b",
    re.IGNORECASE,
)
GBRAIN_NO_CANONICAL_BOUNDARY_PATTERN = re.compile(
    r"\b(canonical_records_written\s*[:=]\s*0|no canonical|not canonical|never canonical|"
    r"does not make gbrain canonical|gbrain remains advisory|never as canonical truth|"
    r"not as canonical truth|not a canonical|no canonical promotion)\b",
    re.IGNORECASE,
)


def is_instruction_like_surface(path: str) -> bool:
    return (
        path in INSTRUCTION_FILES
        or path in {"AGENTS.md", "README.md", ".github/copilot-instructions.md", ".github/pull_request_template.md"}
        or path.startswith(".github/ISSUE_TEMPLATE/")
        or path.startswith(".github/instructions/")
        or path.startswith(".github/prompts/")
        or path.startswith(".agents/")
        or path.endswith((".agent.md", ".instructions.md", ".prompt.md"))
    )


def canonical_claim_is_negated(line: str) -> bool:
    return re.search(
        r"(\bgbrain\b.{0,30}\b(no|not|never|cannot|can't|does not|must not)\b.{0,30}"
        r"\b(canonical(?:ity)?|source of truth|authority)\b|"
        r"\bdoes not make\b.{0,30}\bgbrain\b.{0,30}\bcanonical(?:ity)?\b|"
        r"\b(no|not|never|without|must not|forbid(?:s|den)?|does not(?: authorize)?)\b[^.]{0,240}"
        r"\b(gbrain canonicality|canonical[- ]gbrain|canonical gbrain)\b)",
        line,
        re.IGNORECASE,
    ) is not None


def canonical_claim_negation_context(lines: list[str], index: int) -> str:
    context = [lines[index]]
    current_is_bullet = re.match(r"\s*[-*]\s+", lines[index]) is not None
    current_starts_lower = lines[index].lstrip()[:1].islower()
    for prior_index in range(index - 1, max(-1, index - 4), -1):
        prior_line = lines[prior_index]
        if not prior_line.strip():
            break
        prior_is_bullet = re.match(r"\s*[-*]\s+", prior_line) is not None
        if current_is_bullet and prior_is_bullet:
            break
        prior_continues_clause = re.search(r"(,|\bor\b|\band\b)\s*$", prior_line.strip(), re.IGNORECASE) is not None
        if not prior_continues_clause and not current_starts_lower:
            break
        context.insert(0, prior_line)
        if "." in prior_line:
            break
    return " ".join(context)


def text_has_positive_pattern(text: str, pattern: re.Pattern[str]) -> bool:
    for line in text.splitlines():
        if pattern.search(line) and not GBRAIN_NEGATED_BOUNDARY_PATTERN.search(line):
            return True
    return False


def gbrain_background_command_is_prohibited(line: str) -> bool:
    return GBRAIN_BACKGROUND_PROHIBITION_PATTERN.search(line) is not None


def is_gbrain_background_command_context(text: str) -> bool:
    return re.search(
        r"(\bgbrain\b.{0,100}\b(sync --watch|sync/watch|sync --install-cron|autopilot|dream|"
        r"jobs work(?:er)?|mcp serving|cron|minions?|daemons?|schedulers?|queues?|"
        r"hidden registr(?:y|ies)|bulk import|background (?:gbrain )?(?:memory )?behavior)\b|"
        r"\b(use|run|enable|start|invoke|call)\s+`?gbrain`?\b.{0,100}"
        r"\b(sync --watch|sync/watch|sync --install-cron|cron|autopilot|dream|jobs work(?:er)?|"
        r"mcp serving|minions?|daemons?|schedulers?|queues?|hidden registr(?:y|ies)|"
        r"background memory behavior|background gbrain behavior|bulk import)\b|"
        r"\b(use|run|enable|start|invoke|call)\s+"
        r"(sync --watch|sync/watch|sync --install-cron|cron|autopilot|dream|jobs work(?:er)?|"
        r"mcp serving|minions?|daemons?|schedulers?|queues?|hidden registr(?:y|ies)|"
        r"background memory behavior|background gbrain behavior|bulk import)\b.{0,100}\bgbrain\b)",
        text,
        re.IGNORECASE,
    ) is not None


def line_has_gbrain_background_context(lines: list[str], index: int) -> bool:
    line = lines[index]
    if "gbrain" in line.lower():
        return True
    previous = lines[index - 1] if index > 0 else ""
    return re.search(
        r"\b(use|run|enable|start|invoke|call)\s+gbrain"
        r"(\s+(sync|jobs?|jobs work(?:er)?|autopilot|dream|mcp|bulk|cron|queue|scheduler|daemon|minion|background))?\s*$",
        previous,
        re.IGNORECASE,
    ) is not None


def gbrain_instruction_distribution_overclaim(texts: dict[str, str]) -> dict[str, Any]:
    offenders: list[str] = []
    grounded: list[str] = []
    canonical_claims = 0
    background_commands = 0
    missing_advisory = 0
    missing_source_expectation = 0
    exact_replay_gaps = 0
    missing_exact_replay_fallback = 0
    missing_exact_replay_no_canonical = 0
    missing_exact_replay_no_background = 0

    for path, text in owner_evidence_texts(texts).items():
        normalized_text = re.sub(r"\s+", " ", text)
        if is_work_management_signature_explainer(path, text):
            if GBRAIN_DISTRIBUTION_SURFACE_PATTERN.search(normalized_text) or GBRAIN_EXACT_REPLAY_SURFACE_PATTERN.search(
                normalized_text
            ):
                grounded.append(path)
            continue
        if not is_instruction_like_surface(path):
            continue
        distribution_context = GBRAIN_DISTRIBUTION_SURFACE_PATTERN.search(normalized_text) is not None
        exact_replay_context = GBRAIN_EXACT_REPLAY_SURFACE_PATTERN.search(normalized_text) is not None
        if not distribution_context and not exact_replay_context:
            continue

        reasons: list[str] = []
        lines = text.splitlines()
        for index, line in enumerate(lines):
            lowered_line = line.lower()
            canonical_context = canonical_claim_negation_context(lines, index)
            if (
                "gbrain" in lowered_line
                and GBRAIN_POSITIVE_CANONICAL_PATTERN.search(line)
                and not canonical_claim_is_negated(canonical_context)
            ):
                canonical_claims += 1
                reasons.append("canonical_claim")
                break
        for index, line in enumerate(lines):
            background_context = " ".join(lines[max(0, index - 1) : index + 1])
            if (
                line_has_gbrain_background_context(lines, index)
                and GBRAIN_BACKGROUND_COMMAND_PATTERN.search(background_context)
                and is_gbrain_background_command_context(background_context)
                and not gbrain_background_command_is_prohibited(background_context)
            ):
                background_commands += 1
                reasons.append("background_gbrain_command")
                break
        if not text_has_positive_pattern(text, GBRAIN_ADVISORY_PATTERN):
            missing_advisory += 1
            reasons.append("missing_advisory_boundary")
        if (GBRAIN_DISTRIBUTION_RECORD_PATTERN.search(normalized_text) or exact_replay_context) and not text_has_positive_pattern(
            text, GBRAIN_SOURCE_EXPECTATION_PATTERN
        ):
            missing_source_expectation += 1
            reasons.append("missing_source_or_citation_expectation")
        if exact_replay_context:
            exact_replay_reasons = 0
            if not text_has_positive_pattern(text, GBRAIN_FALLBACK_EXPECTATION_PATTERN):
                missing_exact_replay_fallback += 1
                exact_replay_reasons += 1
                reasons.append("missing_exact_replay_fallback")
            if not text_has_positive_pattern(text, GBRAIN_NO_CANONICAL_BOUNDARY_PATTERN):
                missing_exact_replay_no_canonical += 1
                exact_replay_reasons += 1
                reasons.append("missing_exact_replay_no_canonical_boundary")
            if not any(gbrain_background_command_is_prohibited(" ".join(lines[max(0, i - 1) : i + 1])) for i in range(len(lines))):
                missing_exact_replay_no_background += 1
                exact_replay_reasons += 1
                reasons.append("missing_exact_replay_no_background_boundary")
            if exact_replay_reasons:
                exact_replay_gaps += 1

        if reasons:
            offenders.append(f"{path}=>{','.join(sorted(set(reasons)))}")
        else:
            grounded.append(path)

    details = [
        f"gbrain_instruction_gap=>{';'.join(offenders[:4]) or 'none'}",
        f"grounded_gbrain_instruction=>{','.join(sorted(set(grounded))[:4]) or 'none'}",
    ]
    return {
        "fired": bool(offenders),
        "signals": {
            "gbrain_instruction_surface_count": len(offenders) + len(set(grounded)),
            "gbrain_instruction_gap_count": len(offenders),
            "canonical_claim_count": canonical_claims,
            "background_gbrain_command_count": background_commands,
            "missing_advisory_boundary_count": missing_advisory,
            "missing_source_or_citation_expectation_count": missing_source_expectation,
            "exact_replay_gap_count": exact_replay_gaps,
            "missing_exact_replay_fallback_count": missing_exact_replay_fallback,
            "missing_exact_replay_no_canonical_count": missing_exact_replay_no_canonical,
            "missing_exact_replay_no_background_count": missing_exact_replay_no_background,
        },
        "evidence": evidence_join(details),
        "reason": (
            "GBrain instruction surfaces overclaim authority, enable background behavior, or omit advisory/source/exact-replay boundaries"
            if offenders
            else "GBrain instruction surfaces preserve advisory, source/citation, exact-replay, no-background, and owner-route boundaries, or are absent"
        ),
    }


def selection_handback_recommendation(texts: dict[str, str]) -> dict[str, Any]:
    offenders: list[str] = []
    clean: list[str] = []

    for path, text in owner_evidence_texts(texts).items():
        if is_work_management_signature_explainer(path, text):
            clean.append(path)
            continue
        if not (
            path.endswith(".md")
            or path.endswith(".txt")
            or path.endswith(".json")
            or path.endswith(".jsonl")
            or path.endswith(".csv")
        ):
            continue
        for line in text.splitlines():
            lowered = line.lower()
            if not SELECTION_HANDBACK_PATTERN.search(lowered):
                continue
            if SELECTION_HANDBACK_NEGATION_PATTERN.search(lowered):
                clean.append(path)
                continue
            offenders.append(f"{path}=>{line.strip()[:100]}")
            break

    details = [
        f"selection_handback=>{';'.join(offenders[:4]) or 'none'}",
        f"negated_or_clean=>{','.join(sorted(set(clean))[:4]) or 'none'}",
    ]
    return {
        "fired": bool(offenders),
        "signals": {
            "selection_handback_count": len(offenders),
            "negated_selection_handback_count": len(set(clean)),
        },
        "evidence": evidence_join(details, limit=2),
        "reason": "recommendation hands next-work selection back to the operator" if offenders else "selection recommendations name concrete action or are absent",
    }


def too_small_goal_mode_episode(texts: dict[str, str]) -> dict[str, Any]:
    offenders: list[str] = []
    bounded: list[str] = []

    for path, text in owner_evidence_texts(texts).items():
        if is_work_management_signature_explainer(path, text):
            bounded.append(path)
            continue
        lowered_text = text.lower()
        if not GOAL_MODE_PATTERN.search(lowered_text):
            continue
        if TOO_SMALL_GOAL_NEGATION_PATTERN.search(lowered_text):
            bounded.append(path)
            continue
        if TOO_SMALL_GOAL_PATTERN.search(lowered_text):
            offenders.append(path)

    details = [
        f"too_small_goal=>{','.join(offenders[:4]) or 'none'}",
        f"bounded_goal=>{','.join(bounded[:4]) or 'none'}",
    ]
    return {
        "fired": bool(offenders),
        "signals": {
            "too_small_goal_episode_count": len(offenders),
            "bounded_goal_episode_count": len(bounded),
        },
        "evidence": evidence_join(details),
        "reason": "Goal mode is recommended for tiny or single-file work" if offenders else "Goal-mode recommendations are sized or absent",
    }


def github_native_closure_regrowth(texts: dict[str, str]) -> dict[str, Any]:
    offenders: list[str] = []
    bypassed: list[str] = []

    for path, text in owner_evidence_texts(texts).items():
        if is_work_management_signature_explainer(path, text):
            bypassed.append(path)
            continue
        if is_closure_runtime_distribution_explainer(path, text):
            bypassed.append(path)
            continue
        if "AS_WORK_MANAGEMENT_SIGNATURES" in text:
            bypassed.append(path)
            continue
        if path.startswith(("docs/archive/", "docs/handoffs/", "docs/completions/")):
            bypassed.append(path)
            continue
        chunks = [chunk.strip() for chunk in re.split(r"\n\s*\n", text) if chunk.strip()]
        path_bypassed = False
        for chunk in chunks:
            if chunk.startswith("```"):
                path_bypassed = True
                continue
            lowered = chunk.lower()
            if not GITHUB_CLOSURE_TRUTH_PATTERN.search(lowered):
                continue
            if not has_unnegated_local_closeout_authority(lowered):
                continue
            if LOCAL_CLOSEOUT_BYPASS_PATTERN.search(lowered):
                path_bypassed = True
                continue
            offenders.append(f"{path}=>{chunk[:100].replace(chr(10), ' ')}")
            break
        if path_bypassed:
            bypassed.append(path)

    details = [
        f"closure_regrowth=>{','.join(offenders[:4]) or 'none'}",
        f"bypassed=>{','.join(bypassed[:4]) or 'none'}",
    ]
    return {
        "fired": bool(offenders),
        "signals": {
            "github_native_closure_regrowth_count": len(offenders),
            "github_native_closeout_bypassed_count": len(bypassed),
        },
        "evidence": evidence_join(details),
        "reason": "GitHub issue/PR truth coexists with local closeout authority" if offenders else "GitHub-native closure is not duplicated by local closeout authority",
    }


ISSUE164_RUNTIME_SURFACE_PATTERN = re.compile(
    r"\b(issue\s*#?164|issue164)\b.{0,240}"
    r"\b(fresh coordinator|transfer mode|goal[- ]?null|goal state|run root|"
    r"progress[- ]ledger|heartbeat|ci polling|green[- ]clean|merge-or-blocker|"
    r"next owner action|next action)\b",
    re.IGNORECASE | re.DOTALL,
)
ISSUE164_RUNTIME_LAUNCH_CONTEXT_PATTERN = re.compile(
    r"\b(issue\s*#?164 runtime launch|fresh coordinator|transfer mode|ci polling|"
    r"green[- ]clean|merge-or-blocker)\b",
    re.IGNORECASE,
)
ISSUE164_TRANSFER_MODE_PATTERN = re.compile(
    r"\b(transfer mode:\s*(?:fresh coordinator thread|fresh thread)|fresh coordinator thread|fresh thread)\b",
    re.IGNORECASE,
)
ISSUE164_LIVE_TRUTH_PATTERN = re.compile(
    r"\b(live truth|re-?check(?:ed)?|gh issue view|gh pr list|git status|"
    r"open pr|active child|updatedAt|rev-parse)\b",
    re.IGNORECASE,
)
ISSUE164_GOAL_PATTERN = re.compile(
    r"\b(goal[- ]?null fallback|goal state|goal object|codex goal|goal mode|"
    r"goal active|goal unavailable)\b",
    re.IGNORECASE,
)
ISSUE164_RUN_ROOT_PATTERN = re.compile(
    r"/tmp/issue164-[\w./-]+",
    re.IGNORECASE,
)
ISSUE164_PROGRESS_LEDGER_PATTERN = re.compile(r"\bprogress[-_ ]ledger(?:\.jsonl)?\b", re.IGNORECASE)
ISSUE164_HEARTBEAT_AFTER_PATTERN = re.compile(
    r"\bheartbeat\b.{0,120}\b(after|only after|once)\b.{0,120}\b(child issue|child)\b.{0,120}\b(run root|progress[-_ ]ledger)\b|"
    r"\b(after|only after|once)\b.{0,120}\b(child issue|child)\b.{0,120}\b(run root|progress[-_ ]ledger)\b.{0,120}\bheartbeat\b",
    re.IGNORECASE | re.DOTALL,
)
ISSUE164_HEARTBEAT_BEFORE_PATTERN = re.compile(
    r"\bheartbeat\b.{0,80}\bbefore\b.{0,120}\b(child issue|child|run root|progress[-_ ]ledger)\b",
    re.IGNORECASE | re.DOTALL,
)
ISSUE164_CI_MERGE_PATTERN = re.compile(
    r"\b(ci polling|poll(?:ing)? (?:pr )?checks?|github checks?|green[- ]clean|"
    r"merge-or-blocker|merge if green|checks and merge|pr/check/merge truth|"
    r"check failure requiring human decision)\b",
    re.IGNORECASE,
)
ISSUE164_CONCRETE_NEXT_PATTERN = re.compile(
    r"\b(next_owner_action|next owner action|exact next owner[- ]surface action|"
    r"first deliverable|first owner pr|owner pr|"
    r"github issue routing|owner action)\b",
    re.IGNORECASE,
)
COORDINATOR_ACCEPTANCE_SURFACE_PATTERN = re.compile(
    r"\b(coordinator autonomy acceptance|autonomy acceptance|"
    r"acceptance[_ -]verdict|acceptance verdict|acceptance rubric)\b",
    re.IGNORECASE,
)
COORDINATOR_ACCEPTANCE_EVIDENCE_VERDICT_PATTERN = re.compile(
    r"\b(?:coordinator autonomy acceptance|autonomy acceptance|acceptance[_ -]verdict|"
    r"acceptance verdict|verdict)\b.{0,120}\b(accepted|partial|rejected)\b",
    re.IGNORECASE | re.DOTALL,
)
COORDINATOR_ACCEPTANCE_NOT_APPLICABLE_PATTERN = re.compile(
    r"\b(?:coordinator autonomy acceptance|autonomy acceptance|acceptance[_ -]verdict|"
    r"acceptance verdict|verdict)\b.{0,120}\bnot[_ -]applicable\b",
    re.IGNORECASE | re.DOTALL,
)
COORDINATOR_ACCEPTANCE_GITHUB_TRUTH_PATTERN = re.compile(
    r"\b(github issue/pr/check/merge truth|github issue/pr truth|"
    r"issue/pr/check/merge truth|pr/check/merge truth|github issue|github pr|"
    r"pull request|check run|ci/check|ci / check|merge commit|merged pr|"
    r"closed issue|https://github\.com/[^/\s]+/[^/\s]+/(?:issues|pull)/[0-9]+)\b",
    re.IGNORECASE,
)
COORDINATOR_ACCEPTANCE_RAW_RUNTIME_PATTERN = re.compile(
    r"\b(raw runtime evidence|raw_evidence|session logs?|command transcripts?|"
    r"ci/check runs?|check runs?|runtime ledgers?|goal metadata|goal receipts?|"
    r"progress[-_ ]ledger(?:\.jsonl)?|run-root ledger|run root ledger)\b",
    re.IGNORECASE,
)
COORDINATOR_ACCEPTANCE_HEARTBEAT_DISPOSITION_PATTERN = re.compile(
    r"\bheartbeat\b.{0,120}\b(capture|captured|status|active|deleted|archive|"
    r"archived|disposition|lifecycle|created|receipt)\b|"
    r"\b(capture|captured|status|active|deleted|archive|archived|disposition|"
    r"lifecycle|created|receipt)\b.{0,120}\bheartbeat\b",
    re.IGNORECASE | re.DOTALL,
)
COORDINATOR_ACCEPTANCE_MISSING_HEARTBEAT_PATTERN = re.compile(
    r"\b(no|missing|lacks?|without|omit(?:s|ted)?)\b.{0,80}\bheartbeat\b.{0,80}"
    r"\b(capture|captured|status|active|deleted|archive|archived|disposition|"
    r"lifecycle|created|receipt)\b|"
    r"\b(no|missing|lacks?|without|omit(?:s|ted)?)\b.{0,80}\b(capture|captured|"
    r"status|active|deleted|archive|archived|disposition|lifecycle|created|"
    r"receipt)\b.{0,80}\bheartbeat\b",
    re.IGNORECASE | re.DOTALL,
)
COORDINATOR_ACCEPTANCE_BOUNDED_NONCLAIM_PATTERN = re.compile(
    r"\b(bounded non[- ]claims?|bounded_non_claims|does not authorize|"
    r"does not prove|no background autonomy|foreground[- ]only|non[- ]claim)\b",
    re.IGNORECASE,
)
COORDINATOR_ACCEPTANCE_MISSING_BOUNDED_NONCLAIM_PATTERN = re.compile(
    r"\b(no|missing|lacks?|without|omit(?:s|ted)?)\b.{0,60}\bbounded non[- ]claims?\b|"
    r"\bbounded non[- ]claims?\b.{0,60}\b(missing|none|n/a|null|absent)\b",
    re.IGNORECASE | re.DOTALL,
)
ISSUE164_FIELD_NEGATION_PATTERN = re.compile(
    r"\b(omit(?:s|ted)?|missing|lacks?|without|absent|not include|"
    r"does not include|do not include|not recorded|not required|no)\b",
    re.IGNORECASE,
)


def issue164_has_positive_field(text: str, pattern: re.Pattern[str]) -> bool:
    for match in pattern.finditer(text):
        start, end = match.span()
        sentence_start = max(text.rfind(".", 0, start), text.rfind(";", 0, start)) + 1
        next_bounds = [idx for idx in (text.find(".", end), text.find(";", end)) if idx != -1]
        sentence_end = min(next_bounds) if next_bounds else len(text)
        context = text[sentence_start:sentence_end]
        if ISSUE164_FIELD_NEGATION_PATTERN.search(context):
            continue
        return True
    return False


def issue164_runtime_missing_fields(text: str) -> list[str]:
    missing: list[str] = []
    if not issue164_has_positive_field(text, ISSUE164_TRANSFER_MODE_PATTERN):
        missing.append("transfer_mode")
    if not issue164_has_positive_field(text, ISSUE164_LIVE_TRUTH_PATTERN):
        missing.append("live_truth")
    if not issue164_has_positive_field(text, ISSUE164_GOAL_PATTERN):
        missing.append("goal_or_goal_null")
    if not (
        issue164_has_positive_field(text, ISSUE164_RUN_ROOT_PATTERN)
        and issue164_has_positive_field(text, ISSUE164_PROGRESS_LEDGER_PATTERN)
    ):
        missing.append("run_root_progress_ledger")
    if ISSUE164_HEARTBEAT_BEFORE_PATTERN.search(text) or not ISSUE164_HEARTBEAT_AFTER_PATTERN.search(text):
        missing.append("heartbeat_after_child_run_root")
    if not issue164_has_positive_field(text, ISSUE164_CI_MERGE_PATTERN):
        missing.append("ci_polling_merge_or_blocker")
    has_selection_handback = (
        SELECTION_HANDBACK_PATTERN.search(text) is not None
        and SELECTION_HANDBACK_NEGATION_PATTERN.search(text) is None
    )
    if has_selection_handback or not issue164_has_positive_field(text, ISSUE164_CONCRETE_NEXT_PATTERN):
        missing.append("concrete_next_action")
    return missing


def coordinator_acceptance_runtime_missing_fields(text: str) -> list[str]:
    if not COORDINATOR_ACCEPTANCE_EVIDENCE_VERDICT_PATTERN.search(text):
        return []
    if COORDINATOR_ACCEPTANCE_NOT_APPLICABLE_PATTERN.search(text):
        return []

    missing: list[str] = []
    if not issue164_has_positive_field(text, COORDINATOR_ACCEPTANCE_GITHUB_TRUTH_PATTERN):
        missing.append("github_issue_pr_check_merge_truth")
    if not issue164_has_positive_field(text, COORDINATOR_ACCEPTANCE_RAW_RUNTIME_PATTERN):
        missing.append("raw_runtime_evidence")
    if not issue164_has_positive_field(text, ISSUE164_GOAL_PATTERN):
        missing.append("goal_or_goal_null")
    if not (
        issue164_has_positive_field(text, ISSUE164_RUN_ROOT_PATTERN)
        and issue164_has_positive_field(text, ISSUE164_PROGRESS_LEDGER_PATTERN)
    ):
        missing.append("run_root_progress_ledger")
    has_heartbeat_disposition = (
        COORDINATOR_ACCEPTANCE_HEARTBEAT_DISPOSITION_PATTERN.search(text) is not None
        and COORDINATOR_ACCEPTANCE_MISSING_HEARTBEAT_PATTERN.search(text) is None
    )
    if not has_heartbeat_disposition:
        missing.append("heartbeat_capture_disposition")
    has_bounded_nonclaim = (
        COORDINATOR_ACCEPTANCE_BOUNDED_NONCLAIM_PATTERN.search(text) is not None
        and COORDINATOR_ACCEPTANCE_MISSING_BOUNDED_NONCLAIM_PATTERN.search(text) is None
    )
    if not has_bounded_nonclaim:
        missing.append("bounded_non_claims")
    if not issue164_has_positive_field(text, ISSUE164_CONCRETE_NEXT_PATTERN):
        missing.append("concrete_next_action")
    return missing


def issue164_runtime_drift(texts: dict[str, str]) -> dict[str, Any]:
    offenders: list[str] = []
    grounded: list[str] = []
    reason_counts: Counter[str] = Counter()

    for path, text in owner_evidence_texts(texts).items():
        if is_work_management_signature_explainer(path, text):
            grounded.append(path)
            continue
        if is_closure_runtime_distribution_explainer(path, text):
            grounded.append(path)
            continue
        if not path.endswith((".md", ".txt", ".json", ".jsonl", ".csv", ".yml", ".yaml")):
            continue
        is_runtime_surface = ISSUE164_RUNTIME_SURFACE_PATTERN.search(text) is not None
        is_acceptance_surface = COORDINATOR_ACCEPTANCE_SURFACE_PATTERN.search(text) is not None
        if not is_runtime_surface and not is_acceptance_surface:
            continue
        missing = []
        if is_runtime_surface and (
            not is_acceptance_surface or ISSUE164_RUNTIME_LAUNCH_CONTEXT_PATTERN.search(text)
        ):
            missing.extend(issue164_runtime_missing_fields(text))
        if is_acceptance_surface:
            missing.extend(coordinator_acceptance_runtime_missing_fields(text))
        missing = list(dict.fromkeys(missing))
        if missing:
            reason_counts.update(missing)
            offenders.append(f"{path}=>missing:{','.join(missing)}")
        else:
            grounded.append(path)

    details = [
        f"issue164_runtime_drift=>{';'.join(offenders[:4]) or 'none'}",
        f"issue164_runtime_grounded=>{','.join(sorted(set(grounded))[:4]) or 'none'}",
    ]
    return {
        "fired": bool(offenders),
        "signals": {
            "issue164_runtime_drift_count": len(offenders),
            "issue164_runtime_grounded_count": len(set(grounded)),
            "missing_acceptance_github_truth_count": reason_counts["github_issue_pr_check_merge_truth"],
            "missing_acceptance_raw_runtime_evidence_count": reason_counts["raw_runtime_evidence"],
            "missing_acceptance_heartbeat_disposition_count": reason_counts["heartbeat_capture_disposition"],
            "missing_acceptance_bounded_non_claims_count": reason_counts["bounded_non_claims"],
        },
        "evidence": evidence_join(details),
        "reason": "Issue #164 runtime launch or merge discipline is missing required coordinator fields" if offenders else "Issue #164 runtime surfaces are complete or absent",
    }


CAMPAIGN_PAUSE_SURFACE_PATTERN = re.compile(
    r"\b(issue\s*#?164|issue164|campaign|github[- ]native|active tracks?|"
    r"active child|next active track|owner[-_ ]surface|repo[- ]star)\b",
    re.IGNORECASE,
)
CAMPAIGN_NONE_SELECTED_PATTERN = re.compile(
    r"\b(next active track|next_active_track)\s*[:=]\s*[`\"']?"
    r"(none selected|none|null|n/a|na)[`\"']?\b",
    re.IGNORECASE,
)
CAMPAIGN_STOP_DISPOSITION_PATTERN = re.compile(
    r"\b(no next active track|no active track remains|no further (?:campaign )?work|"
    r"campaign (?:is |was )?(?:paused|stopped|complete|completed|closed|done)|"
    r"(?:pause|paused|stop|stopped|park|parked|defer|deferred) (?:the )?campaign|"
    r"no current admissible owner[-_ ]surface action remains|"
    r"no admissible owner[-_ ]surface action remains|"
    r"no owner[-_ ]surface action remains|nothing actionable remains)\b",
    re.IGNORECASE,
)
CAMPAIGN_NEGATIVE_SEARCH_PATTERN = re.compile(
    r"(\b(?:no|zero)\s+(?:matching\s+)?(?:open\s+)?"
    r"(?:issues?|prs?|pull requests?|children|child issues?|results|hits)\b|"
    r"\bno open (?:child\s+)?(?:issues?|prs?|pull requests?)\b|"
    r"\b(?:gh|github)\s+(?:issue|pr)\s+(?:list|search|view)\b.{0,120}"
    r"\b(?:returned|found|showed)\s+(?:no|zero|0|\[\])\b|"
    r"\bsearch(?:es)?\s+(?:returned|found|showed)\s+(?:no|zero|0)\b)",
    re.IGNORECASE | re.DOTALL,
)
CAMPAIGN_STALE_DOWNSTREAM_PATTERN = re.compile(
    r"(\b(?:stale|old|prior|previous|archived)\b.{0,100}"
    r"\b(?:downstream|final opportunity|retained artifact|reference|references|"
    r"package|handoff|retrospective|replay)\b|"
    r"\bdownstream references?\b.{0,100}"
    r"\b(?:stale|old|prior|previous|archived|closed|missing)\b)",
    re.IGNORECASE | re.DOTALL,
)
CAMPAIGN_SELF_AUTHORED_NO_ACTION_PATTERN = re.compile(
    r"\b(no current admissible owner[-_ ]surface action remains|"
    r"no admissible owner[-_ ]surface action remains|"
    r"no current owner[-_ ]surface action|"
    r"no owner[-_ ]surface action remains|"
    r"agent[- ]authored|self[- ]authored|codex found no|i found no|"
    r"there is nothing actionable|nothing actionable remains)\b",
    re.IGNORECASE,
)
CAMPAIGN_OPERATOR_APPROVED_PAUSE_PATTERN = re.compile(
    r"\b(operator[- ]approved pause|operator approved pause|"
    r"explicit operator approval (?:to|for) (?:pause|stop|defer|park)|"
    r"operator[- ]directed (?:pause|stop|defer|park)|"
    r"operator requested (?:a )?(?:pause|stop|defer|park)|"
    r"owner approved pause|human approved pause|"
    r"approved_by\s*[:=]\s*(?:operator|human|owner)|"
    r"authorized_by\s*[:=]\s*(?:operator|human|owner))\b",
    re.IGNORECASE,
)
CAMPAIGN_TRUE_CLOSURE_PATTERN = re.compile(
    r"\b(true campaign closure|campaign closure evidence|campaign is closed|"
    r"campaign closed|parent campaign closed|"
    r"all campaign work (?:is |was )?(?:closed|complete|completed|resolved))\b",
    re.IGNORECASE,
)
CAMPAIGN_NO_UNRESOLVED_FAMILIES_PATTERN = re.compile(
    r"\b(no unresolved campaign families|"
    r"unresolved campaign families\s*[:=]\s*(?:none|0|\[\])|"
    r"all campaign families (?:are |were )?(?:resolved|closed|complete|completed)|"
    r"zero unresolved campaign families)\b",
    re.IGNORECASE,
)


def campaign_pause_authorized(chunk: str) -> str | None:
    if CAMPAIGN_OPERATOR_APPROVED_PAUSE_PATTERN.search(chunk):
        return "operator_approved_pause"
    if CAMPAIGN_TRUE_CLOSURE_PATTERN.search(chunk) and CAMPAIGN_NO_UNRESOLVED_FAMILIES_PATTERN.search(chunk):
        return "true_campaign_closure"
    return None


def campaign_pause_weak_reasons(chunk: str) -> list[str]:
    reasons: list[str] = []
    if CAMPAIGN_NONE_SELECTED_PATTERN.search(chunk):
        reasons.append("none_selected_disposition")
    if CAMPAIGN_NEGATIVE_SEARCH_PATTERN.search(chunk):
        reasons.append("negative_search_or_no_open_owner_surface")
    if CAMPAIGN_STALE_DOWNSTREAM_PATTERN.search(chunk):
        reasons.append("stale_downstream_reference")
    if CAMPAIGN_SELF_AUTHORED_NO_ACTION_PATTERN.search(chunk):
        reasons.append("self_authored_no_action_assertion")
    return reasons


def self_authored_campaign_pause_authority(texts: dict[str, str]) -> dict[str, Any]:
    offenders: list[str] = []
    grounded: list[str] = []
    reason_counts: Counter[str] = Counter()
    authorized_counts: Counter[str] = Counter()

    for path, text in owner_evidence_texts(texts).items():
        if is_work_management_signature_explainer(path, text):
            grounded.append(path)
            continue
        if not path.endswith((".md", ".txt", ".json", ".jsonl", ".csv", ".yml", ".yaml")):
            continue

        chunks = [chunk.strip() for chunk in re.split(r"\n\s*\n", text) if chunk.strip()]
        for chunk in chunks:
            if not CAMPAIGN_PAUSE_SURFACE_PATTERN.search(chunk):
                continue
            if not (
                CAMPAIGN_NONE_SELECTED_PATTERN.search(chunk)
                or CAMPAIGN_STOP_DISPOSITION_PATTERN.search(chunk)
            ):
                continue

            authorized_reason = campaign_pause_authorized(chunk)
            if authorized_reason:
                authorized_counts[authorized_reason] += 1
                grounded.append(f"{path}=>{authorized_reason}")
                continue

            weak_reasons = campaign_pause_weak_reasons(chunk)
            if not weak_reasons:
                continue
            for reason in weak_reasons:
                reason_counts[reason] += 1
            offenders.append(f"{path}=>{','.join(weak_reasons[:4])}")
            break

    details = [
        f"self_authored_pause=>{';'.join(offenders[:4]) or 'none'}",
        f"authorized_pause_or_closure=>{';'.join(grounded[:4]) or 'none'}",
    ]
    return {
        "fired": bool(offenders),
        "signals": {
            "campaign_pause_authority_count": len(offenders),
            "none_selected_disposition_count": reason_counts["none_selected_disposition"],
            "negative_search_pause_authority_count": reason_counts["negative_search_or_no_open_owner_surface"],
            "stale_downstream_pause_authority_count": reason_counts["stale_downstream_reference"],
            "self_authored_no_action_count": reason_counts["self_authored_no_action_assertion"],
            "operator_approved_pause_count": authorized_counts["operator_approved_pause"],
            "true_campaign_closure_count": authorized_counts["true_campaign_closure"],
            "authorized_pause_or_closure_count": sum(authorized_counts.values()),
        },
        "evidence": evidence_join(details, limit=2),
        "reason": (
            "campaign pause/stop disposition relies on self-authored negative proof instead of operator-approved pause or true closure"
            if offenders
            else "campaign pause/stop dispositions are operator-approved, true-closure grounded, absent, or not supported only by weak negative proof"
        ),
    }


SCHEDULED_SHADOW_SURFACE_PATTERN = re.compile(
    r"\b(runtime learning shadow|scheduled shadow|scheduled readback|"
    r"schedule(?:d)? workflow evidence|schedule(?:d)? evidence|four[- ]run disposition)\b",
    re.IGNORECASE,
)
SCHEDULED_SHADOW_EVIDENCE_PATTERN = re.compile(
    r"\b(readback|admission|artifact|comment|summary|workflow run|"
    r"evidence|classifier|disposition)\b",
    re.IGNORECASE,
)
SCHEDULED_EVENT_IDENTITY_PATTERN = re.compile(
    r"(\bevent(?:_name)?\b\s*[:=]\s*[`\"']?schedule[`\"']?|\bevent=schedule\b|"
    r"\bactual scheduled event\b)",
    re.IGNORECASE,
)
SCHEDULED_RUN_IDENTITY_PATTERNS = {
    "run_id": re.compile(r"\brun[-_ ]?id\b|\bgithub\.run_id\b", re.IGNORECASE),
    "run_number": re.compile(r"\brun[-_ ]?number\b|\bgithub\.run_number\b", re.IGNORECASE),
    "run_attempt": re.compile(r"\brun[-_ ]?attempt\b|\bgithub\.run_attempt\b", re.IGNORECASE),
}
SCHEDULED_REVIEW_DISPOSITION_PATTERN = re.compile(
    r"\b(review disposition|promotion disposition|four[- ]run disposition|"
    r"four[- ]run review|actionability[_ -]classification|"
    r"keep_with_named_value|reduce_frequency|demote_to_manual_only|"
    r"repair_specific_failure)\b",
    re.IGNORECASE,
)
SCHEDULED_FIELD_NEGATION_PATTERN = re.compile(
    r"\b(omit(?:s|ted)?|missing|lacks?|without|absent|not include|"
    r"does not include|does not retain|do not include|not recorded|not retained|"
    r"not required|no)\b",
    re.IGNORECASE,
)
SCHEDULED_CLOSURE_OVERCLAIM_PATTERN = re.compile(
    r"\b(comments?|artifacts?)\b.{0,80}\b(?:are|is|as|become|treated as|count as)\b.{0,80}"
    r"\bclosure truth\b|"
    r"\b(comments?|artifacts?)\b.{0,80}\b(?:close|closes|closed|resolve|resolves)\b.{0,80}"
    r"\b(?:issue|#798|task|child)\b|"
    r"\bclosure truth\b.{0,80}\b(?:from|by|via)\b.{0,80}\b(comments?|artifacts?)\b",
    re.IGNORECASE | re.DOTALL,
)
SCHEDULED_CLOSURE_NON_CLAIM_PATTERN = re.compile(
    r"\b(evidence only|not closure truth|not task closure truth|"
    r"does not close #?798|does not close issues?|"
    r"github issue/pr/check/merge truth)\b",
    re.IGNORECASE,
)
SCHEDULED_BACKGROUND_CONTROL_PATTERN = re.compile(
    r"\b(start|starts|install|installs|run|runs|launch|launches|own|owns|operate|operates|"
    r"control|controls|create|creates)\b.{0,80}"
    r"\b(scheduler|queue|daemon|controller|registry|retry loop|background worker|"
    r"background gbrain|background hermes)\b|"
    r"\b(scheduler|queue|daemon|controller|registry|retry loop|background worker)\b.{0,80}"
    r"\b(owns|controls|runs|operates|dispatches)\b",
    re.IGNORECASE | re.DOTALL,
)
SCHEDULED_BACKGROUND_NEGATION_PATTERN = re.compile(
    r"\b(no|not|never|does not|do not|without|forbid(?:s|den)?|prohibit(?:s|ed)?|"
    r"non[- ]claim|boundary)\b.{0,120}"
    r"\b(scheduler|queue|daemon|controller|registry|retry loop|background worker|"
    r"background gbrain|background hermes)\b",
    re.IGNORECASE | re.DOTALL,
)
SCHEDULED_EVIDENCE_BOUNDARY_EXPLAINER_PATTERN = re.compile(
    r"\b(AS-39|Scheduled Workflow Evidence Boundary Gap)\b.{0,160}\b(detects|detector|signature)\b",
    re.IGNORECASE | re.DOTALL,
)


def scheduled_identity_missing(text: str) -> list[str]:
    missing: list[str] = []
    if not scheduled_has_positive_field(text, SCHEDULED_EVENT_IDENTITY_PATTERN):
        missing.append("event_schedule")
    for field, pattern in SCHEDULED_RUN_IDENTITY_PATTERNS.items():
        if not scheduled_has_positive_field(text, pattern):
            missing.append(field)
    return missing


def scheduled_has_positive_field(text: str, pattern: re.Pattern[str]) -> bool:
    for match in pattern.finditer(text):
        start, end = match.span()
        line_start = text.rfind("\n", 0, start) + 1
        line_end = text.find("\n", end)
        if line_end == -1:
            line_end = len(text)
        line = text[line_start:line_end]
        previous_start = text.rfind("\n", 0, max(0, line_start - 1)) + 1
        previous = text[previous_start:max(0, line_start - 1)]
        continuation = bool(line.strip()) and not line.lstrip().startswith(("-", "*", "#"))
        if SCHEDULED_FIELD_NEGATION_PATTERN.search(line):
            continue
        if continuation and SCHEDULED_FIELD_NEGATION_PATTERN.search(previous):
            continue
        return True
    return False


def scheduled_background_control_overclaim(text: str) -> bool:
    for match in SCHEDULED_BACKGROUND_CONTROL_PATTERN.finditer(text):
        start, end = match.span()
        context = text[max(0, start - 140): min(len(text), end + 140)]
        if SCHEDULED_BACKGROUND_NEGATION_PATTERN.search(context):
            continue
        return True
    return False


def is_scheduled_evidence_boundary_explainer(text: str) -> bool:
    return SCHEDULED_EVIDENCE_BOUNDARY_EXPLAINER_PATTERN.search(text) is not None


def scheduled_closure_overclaim(text: str) -> bool:
    for match in SCHEDULED_CLOSURE_OVERCLAIM_PATTERN.finditer(text):
        start, end = match.span()
        context = text[max(0, start - 140): min(len(text), end + 140)]
        if SCHEDULED_CLOSURE_NON_CLAIM_PATTERN.search(context):
            continue
        return True
    return False


def scheduled_evidence_boundary_gap(texts: dict[str, str]) -> dict[str, Any]:
    offenders: list[str] = []
    grounded: list[str] = []
    reason_counts: Counter[str] = Counter()

    for path, text in owner_evidence_texts(texts).items():
        if is_work_management_signature_explainer(path, text):
            grounded.append(path)
            continue
        if is_scheduled_evidence_boundary_explainer(text):
            grounded.append(path)
            continue
        if not path.endswith((".md", ".txt", ".json", ".jsonl", ".csv", ".yml", ".yaml")):
            continue
        if not SCHEDULED_SHADOW_SURFACE_PATTERN.search(text):
            continue
        if not SCHEDULED_SHADOW_EVIDENCE_PATTERN.search(text):
            continue

        reasons: list[str] = []
        identity_missing = scheduled_identity_missing(text)
        if identity_missing:
            reasons.append("missing_schedule_run_identity:" + ",".join(identity_missing))
            reason_counts["missing_schedule_run_identity"] += 1
        if not scheduled_has_positive_field(text, SCHEDULED_REVIEW_DISPOSITION_PATTERN):
            reasons.append("missing_review_disposition")
            reason_counts["missing_review_disposition"] += 1
        if scheduled_closure_overclaim(text):
            reasons.append("comments_or_artifacts_as_closure_truth")
            reason_counts["comments_or_artifacts_as_closure_truth"] += 1
        if scheduled_background_control_overclaim(text):
            reasons.append("background_control_wording")
            reason_counts["background_control_wording"] += 1

        if reasons:
            offenders.append(f"{path}=>{';'.join(reasons[:4])}")
        else:
            grounded.append(path)

    details = [
        f"scheduled_evidence_boundary_gap=>{';'.join(offenders[:4]) or 'none'}",
        f"scheduled_evidence_boundary_grounded=>{','.join(sorted(set(grounded))[:4]) or 'none'}",
    ]
    return {
        "fired": bool(offenders),
        "signals": {
            "scheduled_evidence_boundary_gap_count": len(offenders),
            "scheduled_evidence_boundary_grounded_count": len(set(grounded)),
            "missing_schedule_run_identity_count": reason_counts["missing_schedule_run_identity"],
            "missing_review_disposition_count": reason_counts["missing_review_disposition"],
            "comments_or_artifacts_as_closure_truth_count": reason_counts["comments_or_artifacts_as_closure_truth"],
            "background_control_wording_count": reason_counts["background_control_wording"],
        },
        "evidence": evidence_join(details, limit=2),
        "reason": (
            "scheduled workflow evidence treats comments/artifacts as closure truth, lacks schedule/run identity or review disposition, or regrows background control wording"
            if offenders
            else "scheduled workflow evidence boundaries are complete or absent"
        ),
    }


SCHEDULED_OWNER_PROOF_EXPLAINER_PATTERN = re.compile(
    r"\b(AS-49|Scheduled Readback Owner Proof Gap)\b.{0,180}\b(detects|detector|signature|triggers?|fires)\b",
    re.IGNORECASE | re.DOTALL,
)
SCHEDULED_OWNER_PROOF_SURFACE_PATTERN = re.compile(
    r"\b(SCHEDULED_READBACK_OWNER_PROOF|scheduled[- ]readback owner proof|scheduled readback owner proof)\b",
    re.IGNORECASE,
)
SCHEDULED_OWNER_PROOF_CONTRACT_PATH_HINTS = (
    "scheduled-readback-owner-proof-contract.md",
    "scheduled-readback-owner-proof.md",
    "detect-as-scheduled-readback-owner-proof-gap.sh",
    "test-scheduled-readback-owner-proof-gap.sh",
)
SCHEDULED_OWNER_PROOF_NEGATION_PATTERN = re.compile(
    r"\b(no|not|never|does not|do not|without|forbid(?:s|den)?|forbidden|non[- ]claim|boundary|bounded|context only)\b",
    re.IGNORECASE,
)
SCHEDULED_OWNER_PROOF_REQUIRED_FIELDS: tuple[tuple[str, re.Pattern[str]], ...] = (
    ("missing_owner_issue", re.compile(r"\b(owner_issue_url|owner issue|owner issue URL)\b", re.IGNORECASE)),
    ("missing_candidate_id", re.compile(r"\b(candidate_id|candidate id)\b", re.IGNORECASE)),
    ("missing_schedule_source", re.compile(r"\b(schedule_source|schedule source|workflow file|cron)\b", re.IGNORECASE)),
    ("missing_allowed_event", re.compile(r"\b(allowed_event|allowed event|event_filter|event filter|event=schedule|event_name.*schedule)\b", re.IGNORECASE)),
    ("missing_cadence", re.compile(r"\b(cadence|expected cadence|stale_after_hours|max_age_hours)\b", re.IGNORECASE)),
    ("missing_blocker_rule", re.compile(r"\b(blocker_rule|blocker rule|blocker trigger)\b", re.IGNORECASE)),
    ("missing_promotion_gate", re.compile(r"\b(promotion_gate|promotion gate)\b", re.IGNORECASE)),
    ("missing_demotion_trigger", re.compile(r"\b(demotion_trigger|demotion trigger|rejection trigger)\b", re.IGNORECASE)),
    ("missing_kill_switch", re.compile(r"\b(kill_switch|kill switch)\b", re.IGNORECASE)),
    ("missing_bounded_non_claims", re.compile(r"\b(bounded_non_claims|bounded non-claims|non-claims)\b", re.IGNORECASE)),
)
SCHEDULED_OWNER_WORKFLOW_DISPATCH_PROOF_PATTERN = re.compile(
    r"\bworkflow_dispatch\b.{0,120}\b(counts? as|accepted|admit(?:s|ted)?|proof|scheduled proof)\b|"
    r"\b(counts? as|accepted|admit(?:s|ted)?|proof|scheduled proof)\b.{0,120}\bworkflow_dispatch\b",
    re.IGNORECASE | re.DOTALL,
)
SCHEDULED_OWNER_PRIVATE_RAW_CAPTURE_PATTERN = re.compile(
    r"\b(private|raw|authenticated|local)\b.{0,80}\b(capture|archive|retention|logs?|DOM|HTML|screenshots?)\b|"
    r"\b(capture|archive|retention)\b.{0,80}\b(private|raw|authenticated|local)\b",
    re.IGNORECASE | re.DOTALL,
)
SCHEDULED_OWNER_CONTROL_PLANE_PATTERN = re.compile(
    r"\b(start|starts|install|installs|run|runs|launch|launches|create|creates|own|owns|control|controls)\b.{0,100}"
    r"\b(scheduler|queue|daemon|controller|registry|retry loop|background gbrain|background hermes)\b|"
    r"\b(scheduler|queue|daemon|controller|registry|retry loop)\b.{0,100}\b(owns|controls|runs|dispatches|creates)\b",
    re.IGNORECASE | re.DOTALL,
)
SCHEDULED_OWNER_AUTO_GITHUB_PATTERN = re.compile(
    r"\b(automatic GitHub mutation|automatic issue creation|automatic PR creation|automatic pull request creation|"
    r"creates? GitHub issues? automatically|auto[- ]?merges?|automatic merge)\b",
    re.IGNORECASE,
)


def is_scheduled_owner_proof_explainer(path: str, text: str) -> bool:
    lowered = path.lower()
    if any(hint in lowered for hint in SCHEDULED_OWNER_PROOF_CONTRACT_PATH_HINTS):
        return True
    return SCHEDULED_OWNER_PROOF_EXPLAINER_PATTERN.search(text) is not None


def scheduled_owner_proof_positive_surface(text: str) -> bool:
    for match in SCHEDULED_OWNER_PROOF_SURFACE_PATTERN.finditer(text):
        start, end = match.span()
        line_start = text.rfind("\n", 0, start) + 1
        line_end = text.find("\n", end)
        if line_end == -1:
            line_end = len(text)
        line = text[line_start:line_end]
        if SCHEDULED_OWNER_PROOF_NEGATION_PATTERN.search(line):
            continue
        return True
    return False


def scheduled_owner_proof_positive_field(text: str, pattern: re.Pattern[str]) -> bool:
    for match in pattern.finditer(text):
        start, end = match.span()
        line_start = text.rfind("\n", 0, start) + 1
        line_end = text.find("\n", end)
        if line_end == -1:
            line_end = len(text)
        line = text[line_start:line_end]
        previous_start = text.rfind("\n", 0, max(0, line_start - 1)) + 1
        previous = text[previous_start:max(0, line_start - 1)]
        is_named_field = re.match(r"\s*[\w -]+(?:_[\w -]+)?\s*[:=]", line) is not None
        if SCHEDULED_FIELD_NEGATION_PATTERN.search(line) and not is_named_field:
            continue
        continuation = bool(line.strip()) and not line.lstrip().startswith(("-", "*", "#")) and not is_named_field
        if continuation and SCHEDULED_FIELD_NEGATION_PATTERN.search(previous):
            continue
        return True
    return False


def scheduled_owner_proof_line_overclaim(text: str, pattern: re.Pattern[str]) -> bool:
    prohibition_context = 0
    for line in text.splitlines():
        if re.search(
            r"\b(boundary|bounded[_ -]non-claims|non-claims|forbidden mode|"
            r"blocker[_ -]rule|demotion[_ -]trigger|rejection trigger|kill[_ -]switch)\b",
            line,
            re.IGNORECASE,
        ):
            has_negation = SCHEDULED_OWNER_PROOF_NEGATION_PATTERN.search(line) is not None
            is_boundary_header = re.search(
                r"^\s*(?:#{1,6}\s*)?(?:boundary|bounded[_ -]non-claims|non-claims|"
                r"blocker[_ -]rule|demotion[_ -]trigger|rejection trigger|kill[_ -]switch)\s*:?\s*$",
                line,
                re.IGNORECASE,
            )
            is_guardrail_field = re.search(
                r"\b(blocker[_ -]rule|demotion[_ -]trigger|rejection trigger|kill[_ -]switch)\b",
                line,
                re.IGNORECASE,
            )
            prohibition_context = 12 if (has_negation or is_boundary_header or is_guardrail_field) else 0
        if not pattern.search(line):
            if prohibition_context and line.strip():
                prohibition_context -= 1
            continue
        if prohibition_context or SCHEDULED_OWNER_PROOF_NEGATION_PATTERN.search(line):
            if prohibition_context and line.strip():
                prohibition_context -= 1
            continue
        return True
    return False


def scheduled_readback_owner_proof_gap(texts: dict[str, str]) -> dict[str, Any]:
    offenders: list[str] = []
    grounded: list[str] = []
    reason_counts: Counter[str] = Counter()

    for path, text in owner_evidence_texts(texts).items():
        if is_work_management_signature_explainer(path, text):
            grounded.append(path)
            continue
        if is_scheduled_owner_proof_explainer(path, text):
            grounded.append(path)
            continue
        if not path.endswith((".md", ".txt", ".json", ".jsonl", ".yml", ".yaml")):
            continue
        if not scheduled_owner_proof_positive_surface(text):
            continue

        reasons: list[str] = []
        for reason, pattern in SCHEDULED_OWNER_PROOF_REQUIRED_FIELDS:
            if not scheduled_owner_proof_positive_field(text, pattern):
                reasons.append(reason)
                reason_counts[reason] += 1

        if scheduled_owner_proof_line_overclaim(text, SCHEDULED_OWNER_WORKFLOW_DISPATCH_PROOF_PATTERN):
            reasons.append("workflow_dispatch_as_scheduled_proof")
            reason_counts["workflow_dispatch_as_scheduled_proof"] += 1
        if scheduled_owner_proof_line_overclaim(text, SCHEDULED_OWNER_PRIVATE_RAW_CAPTURE_PATTERN):
            reasons.append("private_raw_capture")
            reason_counts["private_raw_capture"] += 1
        if scheduled_owner_proof_line_overclaim(text, SCHEDULED_OWNER_CONTROL_PLANE_PATTERN):
            reasons.append("hidden_control_plane")
            reason_counts["hidden_control_plane"] += 1
        if scheduled_owner_proof_line_overclaim(text, SCHEDULED_OWNER_AUTO_GITHUB_PATTERN):
            reasons.append("automatic_github_mutation_or_auto_merge")
            reason_counts["automatic_github_mutation_or_auto_merge"] += 1

        if reasons:
            offenders.append(f"{path}=>{';'.join(reasons[:7])}")
        else:
            grounded.append(path)

    details = [
        f"scheduled_readback_owner_proof_gap=>{';'.join(offenders[:4]) or 'none'}",
        f"scheduled_readback_owner_proof_grounded=>{','.join(sorted(set(grounded))[:4]) or 'none'}",
    ]
    return {
        "fired": bool(offenders),
        "signals": {
            "scheduled_readback_owner_proof_gap_count": len(offenders),
            "scheduled_readback_owner_proof_grounded_count": len(set(grounded)),
            "missing_owner_issue_count": reason_counts["missing_owner_issue"],
            "missing_candidate_id_count": reason_counts["missing_candidate_id"],
            "missing_schedule_source_count": reason_counts["missing_schedule_source"],
            "missing_allowed_event_count": reason_counts["missing_allowed_event"],
            "missing_cadence_count": reason_counts["missing_cadence"],
            "missing_blocker_rule_count": reason_counts["missing_blocker_rule"],
            "missing_promotion_gate_count": reason_counts["missing_promotion_gate"],
            "missing_demotion_trigger_count": reason_counts["missing_demotion_trigger"],
            "missing_kill_switch_count": reason_counts["missing_kill_switch"],
            "missing_bounded_non_claims_count": reason_counts["missing_bounded_non_claims"],
            "workflow_dispatch_as_scheduled_proof_count": reason_counts["workflow_dispatch_as_scheduled_proof"],
            "private_raw_capture_count": reason_counts["private_raw_capture"],
            "hidden_control_plane_count": reason_counts["hidden_control_plane"],
            "automatic_github_mutation_or_auto_merge_count": reason_counts["automatic_github_mutation_or_auto_merge"],
        },
        "evidence": evidence_join(details, limit=2),
        "reason": (
            "scheduled readback owner proof is missing owner/cadence/event/blocker fields or overclaims automation authority"
            if offenders
            else "scheduled readback owner proof evidence is complete or absent"
        ),
    }


HERMES_GITHUB_RELIABILITY_SURFACE_PATTERN = re.compile(
    r"\b(hermes|HERMES_FOREGROUND|failure[- ]?guidance|provider_user_request_timeout|"
    r"closingIssuesReferences|parsed[- ]closure|campaign sync|issue #164)\b",
    re.IGNORECASE,
)
HERMES_GITHUB_RELIABILITY_EXPLAINER_PATTERN = re.compile(
    r"\b(AS-40|Hermes/GitHub Reliability Boundary Gap)\b.{0,160}\b(detects|detector|signature)\b",
    re.IGNORECASE | re.DOTALL,
)
NEGATED_CLOSURE_KEYWORD_HAZARD_PATTERN = re.compile(
    r"\b(?:does\s+not|do\s+not|not|never|without)\b.{0,60}"
    r"\b(?:close[sd]?|fix(?:e[sd])?|resolve[sd]?)\b.{0,80}"
    r"(?:#[0-9]+|https://github\.com/[^/\s]+/[^/\s]+/issues/[0-9]+)",
    re.IGNORECASE | re.DOTALL,
)
NONFINAL_ISSUE164_CONTEXT_PATTERN = re.compile(
    r"\b(non[- ]?final|intermediate|not\s+final)\b.{0,120}\b(issue\s*#?164|campaign sync|child)\b|"
    r"\b(issue\s*#?164|campaign sync|child)\b.{0,120}\b(non[- ]?final|intermediate|not\s+final)\b",
    re.IGNORECASE | re.DOTALL,
)
HERMES_FAILURE_RESIDUE_PATTERN = re.compile(
    # Generic failure-to-issue guidance is not Hermes-specific residue. Require
    # the Hermes foreground receipt name, provider timeout, or explicit residue term.
    r"\b(HERMES_FOREGROUND_FAILURE_GUIDANCE|provider_user_request_timeout|"
    r"provider_request_body_timeout|Hermes failure residue)\b",
    re.IGNORECASE,
)
HERMES_FAILURE_DISPOSITION_PATTERN = re.compile(
    r"\b(fresh repro|fresh bounded repro|current repro|recovered_close_residue|"
    r"provider_still_failing|upstream_issue_needed|bma_prompt_shape_repair|"
    r"failure residue classification|failure residue disposition)\b",
    re.IGNORECASE,
)
HERMES_DISPOSITION_NEGATION_PATTERN = re.compile(
    r"\b(no|not|never|without|missing|lacks?|unrecorded|absent)\b",
    re.IGNORECASE,
)
HERMES_COORDINATOR_OVERCLAIM_PATTERN = re.compile(
    r"\bHermes\b.{0,80}\b(owns|coordinates|merges|auto[- ]?merges|polls|retries|"
    r"schedules|queues|runs\s+background|operates\s+as\s+coordinator)\b|"
    r"\b(background Hermes|Hermes retry loop|Hermes scheduler|Hermes queue|Hermes daemon|Hermes controller)\b",
    re.IGNORECASE | re.DOTALL,
)
HERMES_BOUNDARY_NEGATION_PATTERN = re.compile(
    r"\b(no|not|never|does not|do not|without|forbid(?:s|den)?|boundary|non[- ]claim)\b.{0,120}"
    r"\b(Hermes|auto[- ]?merge|retry loop|scheduler|queue|daemon|controller|background)\b",
    re.IGNORECASE | re.DOTALL,
)
HISTORICAL_CLOSURE_ARTIFACT_PREFIXES = ("docs/archive/", "docs/handoffs/", "docs/completions/")


def is_hermes_github_reliability_explainer(text: str) -> bool:
    return HERMES_GITHUB_RELIABILITY_EXPLAINER_PATTERN.search(text) is not None


def hermes_coordinator_overclaim(text: str) -> bool:
    for match in HERMES_COORDINATOR_OVERCLAIM_PATTERN.finditer(text):
        start, end = match.span()
        line_start = text.rfind("\n", 0, start) + 1
        line_end = text.find("\n", end)
        if line_end == -1:
            line_end = len(text)
        line = text[line_start:line_end]
        if HERMES_BOUNDARY_NEGATION_PATTERN.search(line):
            continue
        return True
    return False


def has_positive_hermes_failure_disposition(text: str) -> bool:
    for match in HERMES_FAILURE_DISPOSITION_PATTERN.finditer(text):
        start, end = match.span()
        line_start = text.rfind("\n", 0, start) + 1
        line_end = text.find("\n", end)
        if line_end == -1:
            line_end = len(text)
        line = text[line_start:line_end]
        if HERMES_DISPOSITION_NEGATION_PATTERN.search(line):
            continue
        return True
    return False


def hermes_github_reliability_boundary_gap(texts: dict[str, str]) -> dict[str, Any]:
    offenders: list[str] = []
    grounded: list[str] = []
    reason_counts: Counter[str] = Counter()
    historical_evidence_skipped = 0

    for path, text in owner_evidence_texts(texts).items():
        if path.startswith(HISTORICAL_CLOSURE_ARTIFACT_PREFIXES):
            historical_evidence_skipped += 1
            continue
        if is_work_management_signature_explainer(path, text):
            grounded.append(path)
            continue
        if is_hermes_github_reliability_explainer(text):
            grounded.append(path)
            continue
        if not path.endswith((".md", ".txt", ".json", ".jsonl", ".csv", ".yml", ".yaml")):
            continue
        if not HERMES_GITHUB_RELIABILITY_SURFACE_PATTERN.search(text):
            continue

        reasons: list[str] = []
        if NEGATED_CLOSURE_KEYWORD_HAZARD_PATTERN.search(text) and NONFINAL_ISSUE164_CONTEXT_PATTERN.search(text):
            reasons.append("negated_closure_keyword_parse_hazard")
            reason_counts["negated_closure_keyword_parse_hazard"] += 1
        if HERMES_FAILURE_RESIDUE_PATTERN.search(text) and not has_positive_hermes_failure_disposition(text):
            reasons.append("missing_fresh_hermes_failure_disposition")
            reason_counts["missing_fresh_hermes_failure_disposition"] += 1
        if hermes_coordinator_overclaim(text):
            reasons.append("hermes_coordinator_or_background_overclaim")
            reason_counts["hermes_coordinator_or_background_overclaim"] += 1

        if reasons:
            offenders.append(f"{path}=>{';'.join(reasons[:4])}")
        else:
            grounded.append(path)

    details = [
        f"hermes_github_reliability_gap=>{';'.join(offenders[:4]) or 'none'}",
        f"hermes_github_reliability_grounded=>{','.join(sorted(set(grounded))[:4]) or 'none'}",
    ]
    return {
        "fired": bool(offenders),
        "signals": {
            "hermes_github_reliability_gap_count": len(offenders),
            "hermes_github_reliability_grounded_count": len(set(grounded)),
            "negated_closure_keyword_parse_hazard_count": reason_counts["negated_closure_keyword_parse_hazard"],
            "missing_fresh_hermes_failure_disposition_count": reason_counts["missing_fresh_hermes_failure_disposition"],
            "hermes_coordinator_or_background_overclaim_count": reason_counts["hermes_coordinator_or_background_overclaim"],
            "historical_evidence_skipped_count": historical_evidence_skipped,
        },
        "evidence": evidence_join(details, limit=2),
        "reason": (
            "Hermes/GitHub reliability material has parsed-closure hazards, stale failure residue, or Hermes coordinator/background overclaim wording"
            if offenders
            else "Hermes/GitHub reliability boundaries are complete or absent"
        ),
    }


CAMPAIGN_SYNC_COMPLETED_TRACK_EXPLAINER_PATTERN = re.compile(
    r"\b(AS-41|Campaign Sync Completed-Track Readback Gap)\b.{0,180}\b(detects|detector|signature|triggers?)\b",
    re.IGNORECASE | re.DOTALL,
)
CAMPAIGN_SYNC_COMPLETED_TRACK_SURFACE_PATTERN = re.compile(
    r"\b(campaign sync|campaign_sync|Completed track:|Completed latest track:|"
    r"require-campaign-sync|validate-github-campaign-pointer|native closure|"
    r"campaign_sync_errors(?:_for_data)?|campaign_sync_completed_track_readback)\b",
    re.IGNORECASE,
)
COMPLETED_TRACK_MARKER_PATTERN = re.compile(
    r"^\s*(?:[-*]\s*)?Completed track:\s*(.+?)\s*$",
    re.IGNORECASE | re.MULTILINE,
)
COMPLETED_LATEST_TRACK_MARKER_PATTERN = re.compile(
    r"^\s*(?:[-*]\s*)?Completed latest track:\s*(.+?)\s*$",
    re.IGNORECASE | re.MULTILINE,
)
FINAL_CAMPAIGN_SYNC_CONTEXT_PATTERN = re.compile(
    r"\b(final(?:[- ]campaign sync)?|final_for_own_child|before admit|admit|admitted|"
    r"closes\s+#[0-9]+|own target child|own child issue)\b",
    re.IGNORECASE,
)
CAMPAIGN_SYNC_PREDICATE_CONTEXT_PATTERN = re.compile(
    r"\b(campaign sync predicate|campaign sync validation|campaign sync readback|"
    r"campaign_sync_errors(?:_for_data)?|require-campaign-sync|validate-github-campaign-pointer|"
    r"native closure validator|native campaign sync|final campaign sync)\b",
    re.IGNORECASE,
)
NEXT_TRACK_COVERAGE_PATTERN = re.compile(r"\b(next active track|next-track)\b", re.IGNORECASE)
MICRO_OR_THRESHOLD_COVERAGE_PATTERN = re.compile(
    r"\b(micro[- ]work rule|threshold clause|threshold)\b",
    re.IGNORECASE,
)
COMPLETED_TRACK_COVERAGE_PATTERN = re.compile(
    r"\b(completed track|completed latest track|campaign_sync_completed_track_readback|completed-track readback)\b",
    re.IGNORECASE,
)


def is_campaign_sync_completed_track_explainer(text: str) -> bool:
    return CAMPAIGN_SYNC_COMPLETED_TRACK_EXPLAINER_PATTERN.search(text) is not None


def campaign_track_marker_values(pattern: re.Pattern[str], text: str) -> list[str]:
    values: list[str] = []
    for match in pattern.finditer(text):
        value = match.group(1).strip()
        if value:
            values.append(value)
    return values


def normalize_campaign_track_value(value: str) -> str:
    return re.sub(r"[^a-z0-9#]+", " ", value.lower()).strip()


def campaign_sync_completed_track_readback_gap(texts: dict[str, str]) -> dict[str, Any]:
    offenders: list[str] = []
    grounded: list[str] = []
    reason_counts: Counter[str] = Counter()
    historical_evidence_skipped = 0

    for path, text in owner_evidence_texts(texts).items():
        if path.startswith(HISTORICAL_CLOSURE_ARTIFACT_PREFIXES):
            historical_evidence_skipped += 1
            continue
        if is_work_management_signature_explainer(path, text):
            grounded.append(path)
            continue
        if is_campaign_sync_completed_track_explainer(text):
            grounded.append(path)
            continue
        if not path.endswith((".md", ".txt", ".json", ".jsonl", ".csv", ".yml", ".yaml", ".sh", ".py")):
            continue
        if not CAMPAIGN_SYNC_COMPLETED_TRACK_SURFACE_PATTERN.search(text):
            continue

        completed_tracks = campaign_track_marker_values(COMPLETED_TRACK_MARKER_PATTERN, text)
        completed_latest_tracks = campaign_track_marker_values(COMPLETED_LATEST_TRACK_MARKER_PATTERN, text)
        normalized_completed = {normalize_campaign_track_value(value) for value in completed_tracks}
        normalized_latest = {normalize_campaign_track_value(value) for value in completed_latest_tracks}

        reasons: list[str] = []
        if completed_tracks and completed_latest_tracks and normalized_completed.isdisjoint(normalized_latest):
            reasons.append("completed_track_drift")
            reason_counts["completed_track_drift"] += 1
        if (
            completed_tracks
            and not completed_latest_tracks
            and FINAL_CAMPAIGN_SYNC_CONTEXT_PATTERN.search(text)
            and "campaign_sync_completed_track_readback" not in text.lower()
        ):
            reasons.append("missing_final_completed_track_readback")
            reason_counts["missing_final_completed_track_readback"] += 1
        if (
            CAMPAIGN_SYNC_PREDICATE_CONTEXT_PATTERN.search(text)
            and NEXT_TRACK_COVERAGE_PATTERN.search(text)
            and MICRO_OR_THRESHOLD_COVERAGE_PATTERN.search(text)
            and not COMPLETED_TRACK_COVERAGE_PATTERN.search(text)
        ):
            reasons.append("missing_completed_track_predicate_coverage")
            reason_counts["missing_completed_track_predicate_coverage"] += 1

        if reasons:
            offenders.append(f"{path}=>{';'.join(reasons[:4])}")
        else:
            grounded.append(path)

    details = [
        f"campaign_sync_completed_track_gap=>{';'.join(offenders[:4]) or 'none'}",
        f"campaign_sync_completed_track_grounded=>{','.join(sorted(set(grounded))[:4]) or 'none'}",
    ]
    return {
        "fired": bool(offenders),
        "signals": {
            "campaign_sync_completed_track_gap_count": len(offenders),
            "campaign_sync_completed_track_grounded_count": len(set(grounded)),
            "completed_track_drift_count": reason_counts["completed_track_drift"],
            "missing_final_completed_track_readback_count": reason_counts["missing_final_completed_track_readback"],
            "missing_completed_track_predicate_coverage_count": reason_counts["missing_completed_track_predicate_coverage"],
            "historical_evidence_skipped_count": historical_evidence_skipped,
        },
        "evidence": evidence_join(details, limit=2),
        "reason": (
            "Campaign Sync material has completed-track drift or missing completed-track readback predicate coverage"
            if offenders
            else "No Campaign Sync completed-track readback gaps detected"
        ),
    }


ROUTE_CHANGING_LEARNING_EXPLAINER_PATTERN = re.compile(
    r"\b(AS-42|Route[- ]Changing Learning Propagation Gap)\b.{0,180}\b(detects|detector|signature|triggers?)\b",
    re.IGNORECASE | re.DOTALL,
)
ROUTE_CHANGING_LEARNING_SURFACE_PATTERN = re.compile(
    r"\b(route_changed|route_change_reason|ROUTE_CHANGING_LEARNING_FAILURE_RECEIPT|"
    r"learning_recovery_block|Learning / Recovery|fallback_without_memory|fallback without memory|"
    r"gbrain_exact_handle_replay|gbrain_slug_or_no_capture_reason|exact[- ]handle replay|"
    r"literal_safe_github_readback|literal[- ]safe GitHub|broad GBrain search miss|"
    r"HERMES_FOREGROUND_FAILURE_GUIDANCE|HERMES_FOREGROUND_RUN_RECEIPT)\b",
    re.IGNORECASE,
)
ROUTE_GITHUB_SURFACE_PATTERN = re.compile(
    r"\bgithub_surface\b|https://github\.com/[^/\s]+/[^/\s]+/(?:issues|pull)/[0-9]+|"
    r"https://github\.com/[^/\s]+/[^/\s]+/issues/[0-9]+#issuecomment-[0-9]+|"
    r"\b(?:GitHub surface|GitHub issue|GitHub PR|owner issue|owner PR)\b.{0,80}(?<![A-Za-z0-9_-])#[0-9]+(?![0-9])",
    re.IGNORECASE,
)
ROUTE_RAW_EVIDENCE_PATTERN = re.compile(
    r"\b(raw_evidence|raw evidence|command transcript|transcript|receipt|stdout|stderr|"
    r"CI/check run|check run|replay log|failure_guidance|foreground_receipt)\b",
    re.IGNORECASE,
)
ROUTE_MEMORY_DISPOSITION_PATTERN = re.compile(
    r"\b(gbrain_slug_or_no_capture_reason|optional_gbrain_slug|no_capture_reason|"
    r"optional\s+GBrain\s+slug|GBrain\s+slug|"
    r"gbrain://|gbrain get|exact[- ]handle replay|gbrain_exact_handle_replay|"
    r"github_evidence_sufficient|not_reusable|local_only|duplicate|routine)\b",
    re.IGNORECASE,
)
ROUTE_GBRAIN_SLUG_PATTERN = re.compile(
    r"\b(gbrain_slug|optional_gbrain_slug|GBrain slug|gbrain://|"
    r"gbrain_slug_or_no_capture_reason)\b",
    re.IGNORECASE,
)
ROUTE_NO_CAPTURE_PATTERN = re.compile(
    r"\b(no_capture_reason|no[- ]capture reason|github_evidence_sufficient|"
    r"not_reusable|local_only|duplicate|routine)\b",
    re.IGNORECASE,
)
ROUTE_EXACT_READBACK_PATTERN = re.compile(
    r"\b(gbrain_exact_handle_replay|exact[- ]handle replay|exact[- ]get|gbrain get|get_status|"
    r"exact[- ]handle|exact[- ]read(?:back)?\b.{0,80}\bgbrain\b|"
    r"\bgbrain\b.{0,80}\bexact[- ]read(?:back)?)\b",
    re.IGNORECASE,
)
ROUTE_FALLBACK_WITHOUT_MEMORY_PATTERN = re.compile(
    r"\b(fallback_without_memory|fallback without memory|without GBrain|GBrain unavailable|"
    r"without advisory GBrain|without memory)\b",
    re.IGNORECASE,
)
ROUTE_OWNER_ACTION_PATTERN = re.compile(
    r"\b(owner_action|owner action|owner surface|owner issue|owner PR|owner pull request|"
    r"owner route|first deliverable|open .*PR|open .*issue)\b",
    re.IGNORECASE,
)
ROUTE_LITERAL_READBACK_REQUIRED_PATTERN = re.compile(
    r"\b(literal_safe_github_readback|literal[- ]safe GitHub|expected_literals|"
    r"readback_status|shell backtick|backtick substitution|code fence|JSON literal)\b",
    re.IGNORECASE,
)
ROUTE_LITERAL_READBACK_COMPLETE_PATTERN = re.compile(
    r"\b(readback_status\s*[:=]\s*[\"']?(?:matched|passed)|literal[- ]safe GitHub comment readback preserved|"
    r"expected_literals\b.{0,160}\b(?:matched|preserved|passed)|comment_url\b.{0,160}\bissuecomment-)\b",
    re.IGNORECASE | re.DOTALL,
)
ROUTE_BROAD_SEARCH_MISS_ABSENCE_PATTERN = re.compile(
    r"\bbroad\s+GBrain\s+search\s+miss\b.{0,160}\b(absen(?:t|ce)|no memory|none found)\b|"
    r"\bGBrain\s+search\b.{0,120}\bmiss(?:ed)?\b.{0,120}\b(absen(?:t|ce)|no memory|none found)\b",
    re.IGNORECASE | re.DOTALL,
)
ROUTE_EXACT_HANDLE_PATTERN = re.compile(
    r"\b(exact[- ]handle|gbrain_exact_handle_replay|gbrain get|gbrain://)\b",
    re.IGNORECASE,
)
ROUTE_BACKGROUND_CONTROL_PATTERN = re.compile(
    r"\b(background\s+GBrain|background\s+Hermes|controller|scheduler|queue|daemon|retry\s*-?\s*loop|"
    r"automatic\s+(?:issue|PR|pull request)\s+creation)\b",
    re.IGNORECASE,
)
# Superset negation/non-claim context used by the sentence-aware overclaim check.
# Supersedes the former line-based ROUTE_BACKGROUND_NEGATION_PATTERN: adds
# underscore JSON-key variants ("non_claims", "bounded_non_claims",
# "out_of_scope", "not_allowed") and more negation/prohibition forms so a
# bounded-non-claims list (prose, bullet, or JSON array) is recognized even when
# the negation lead-in wraps onto another physical line from its control words.
ROUTE_NONCLAIM_CONTEXT_PATTERN = re.compile(
    r"\b(no|not|never|cannot|can't|does not|do not|must not|will not|without|"
    r"forbid(?:s|den)?|forbidden[-_ ]?modes?|prohibit(?:s|ed)?|disallow(?:s|ed)?|"
    r"exclud(?:e|es|ed)|non[-_ ]?claims?|bounded[-_ ]?non[-_ ]?claims?|"
    r"out[-_ ]?of[-_ ]?scope|not[-_ ]?allowed|boundary|bounded)\b",
    re.IGNORECASE,
)
ROUTE_GBRAIN_STALE_FAILED_PATTERN = re.compile(
    r"\b(stale|contradictory|contradiction|failed|missing|uncited)\b.{0,120}\bGBrain\b|"
    r"\bGBrain\b.{0,120}\b(stale|contradictory|contradiction|failed|missing|uncited)\b",
    re.IGNORECASE | re.DOTALL,
)
ROUTE_GBRAIN_OVERCLAIM_PATTERN = re.compile(
    r"\b(admit|admitted|accepted|relied|relies|confirmed|proves|proof|route truth|"
    r"source of truth|authoritative|canonical|changed the route|route changed)\b",
    re.IGNORECASE,
)
ROUTE_GBRAIN_OVERCLAIM_NEGATION_PATTERN = re.compile(
    r"\b(do not|does not|must not|never|cannot|can't|reject|rejected|block|blocked|"
    r"route to owner|owner surface|no[-_ ]capture|fallback|not rely|do not rely|"
    r"not authoritative|not canonical|advisory only)\b",
    re.IGNORECASE,
)


def is_route_changing_learning_explainer(text: str) -> bool:
    return ROUTE_CHANGING_LEARNING_EXPLAINER_PATTERN.search(text) is not None


def _route_overclaim_sentences(text: str) -> list[str]:
    """Segment text into sentence-ish units for negation-aware overclaim checks.

    Single newlines (line wraps) are collapsed to spaces so a negated
    enumeration that wraps across physical lines (``... not a controller,
    scheduler, / daemon, queue ...``) or a ``"bounded_non_claims": [ ... ]``
    array stays one unit with its negation lead-in. Blank lines and sentence
    terminators (``.?!``) end a unit, so an affirmative overclaim in its own
    sentence is still detected even when an unrelated negation sits earlier in
    the same paragraph.
    """
    sentences: list[str] = []
    for paragraph in re.split(r"\n[ \t]*\n", text):
        collapsed = re.sub(r"\s*\n\s*", " ", paragraph.strip())
        for sentence in re.split(r"(?<=[.!?])\s+", collapsed):
            sentence = sentence.strip()
            if sentence:
                sentences.append(sentence)
    return sentences


def route_learning_background_overclaim(text: str) -> bool:
    for sentence in _route_overclaim_sentences(text):
        if not ROUTE_BACKGROUND_CONTROL_PATTERN.search(sentence):
            continue
        if ROUTE_NONCLAIM_CONTEXT_PATTERN.search(sentence):
            continue
        return True
    return False


def route_learning_missing_exact_readback_or_no_capture(text: str) -> bool:
    if not ROUTE_GBRAIN_SLUG_PATTERN.search(text):
        return False
    if route_learning_has_exact_readback_proof(text):
        return False
    if ROUTE_NO_CAPTURE_PATTERN.search(text):
        return False
    return True


def route_learning_has_exact_readback_proof(text: str) -> bool:
    for line in text.splitlines():
        if re.search(r"\b(raw_evidence|raw evidence)\b", line, re.IGNORECASE):
            continue
        if ROUTE_EXACT_READBACK_PATTERN.search(line):
            return True
    return False


def route_learning_stale_failed_gbrain_overclaim(text: str) -> bool:
    for line in text.splitlines():
        if not ROUTE_GBRAIN_STALE_FAILED_PATTERN.search(line):
            continue
        if not ROUTE_GBRAIN_OVERCLAIM_PATTERN.search(line):
            continue
        if ROUTE_GBRAIN_OVERCLAIM_NEGATION_PATTERN.search(line):
            continue
        return True
    return False


def route_changing_learning_propagation_gap(texts: dict[str, str]) -> dict[str, Any]:
    offenders: list[str] = []
    grounded: list[str] = []
    reason_counts: Counter[str] = Counter()
    historical_evidence_skipped = 0

    for path, text in owner_evidence_texts(texts).items():
        if path.startswith(HISTORICAL_CLOSURE_ARTIFACT_PREFIXES):
            historical_evidence_skipped += 1
            continue
        if is_work_management_signature_explainer(path, text):
            grounded.append(path)
            continue
        if is_route_changing_learning_explainer(text):
            grounded.append(path)
            continue
        if not path.endswith((".md", ".txt", ".json", ".jsonl", ".csv", ".yml", ".yaml", ".sh", ".py")):
            continue
        if not ROUTE_CHANGING_LEARNING_SURFACE_PATTERN.search(text):
            continue

        reasons: list[str] = []
        if not ROUTE_GITHUB_SURFACE_PATTERN.search(text):
            reasons.append("missing_github_surface")
            reason_counts["missing_github_surface"] += 1
        if not ROUTE_RAW_EVIDENCE_PATTERN.search(text):
            reasons.append("missing_raw_evidence")
            reason_counts["missing_raw_evidence"] += 1
        if not ROUTE_MEMORY_DISPOSITION_PATTERN.search(text):
            reasons.append("missing_gbrain_slug_or_no_capture_reason")
            reason_counts["missing_gbrain_slug_or_no_capture_reason"] += 1
        if route_learning_missing_exact_readback_or_no_capture(text):
            reasons.append("missing_exact_readback_or_no_capture")
            reason_counts["missing_exact_readback_or_no_capture"] += 1
        if (
            not ROUTE_FALLBACK_WITHOUT_MEMORY_PATTERN.search(text)
            and not ROUTE_NO_CAPTURE_PATTERN.search(text)
        ):
            reasons.append("missing_fallback_without_memory")
            reason_counts["missing_fallback_without_memory"] += 1
        if not ROUTE_OWNER_ACTION_PATTERN.search(text):
            reasons.append("missing_owner_action")
            reason_counts["missing_owner_action"] += 1
        if (
            ROUTE_LITERAL_READBACK_REQUIRED_PATTERN.search(text)
            and not ROUTE_LITERAL_READBACK_COMPLETE_PATTERN.search(text)
        ):
            reasons.append("unsafe_literal_readback")
            reason_counts["unsafe_literal_readback"] += 1
        if (
            ROUTE_BROAD_SEARCH_MISS_ABSENCE_PATTERN.search(text)
            and not ROUTE_EXACT_HANDLE_PATTERN.search(text)
        ):
            reasons.append("broad_search_miss_as_absence")
            reason_counts["broad_search_miss_as_absence"] += 1
        if route_learning_stale_failed_gbrain_overclaim(text):
            reasons.append("stale_or_failed_gbrain_overclaim")
            reason_counts["stale_or_failed_gbrain_overclaim"] += 1
        if route_learning_background_overclaim(text):
            reasons.append("background_or_controller_overclaim")
            reason_counts["background_or_controller_overclaim"] += 1

        if reasons:
            offenders.append(f"{path}=>{';'.join(reasons[:5])}")
        else:
            grounded.append(path)

    details = [
        f"route_changing_learning_gap=>{';'.join(offenders[:4]) or 'none'}",
        f"route_changing_learning_grounded=>{','.join(sorted(set(grounded))[:4]) or 'none'}",
    ]
    return {
        "fired": bool(offenders),
        "signals": {
            "route_changing_learning_gap_count": len(offenders),
            "route_changing_learning_grounded_count": len(set(grounded)),
            "missing_github_surface_count": reason_counts["missing_github_surface"],
            "missing_raw_evidence_count": reason_counts["missing_raw_evidence"],
            "missing_gbrain_slug_or_no_capture_reason_count": reason_counts["missing_gbrain_slug_or_no_capture_reason"],
            "missing_exact_readback_or_no_capture_count": reason_counts["missing_exact_readback_or_no_capture"],
            "missing_fallback_without_memory_count": reason_counts["missing_fallback_without_memory"],
            "missing_owner_action_count": reason_counts["missing_owner_action"],
            "unsafe_literal_readback_count": reason_counts["unsafe_literal_readback"],
            "broad_search_miss_as_absence_count": reason_counts["broad_search_miss_as_absence"],
            "stale_or_failed_gbrain_overclaim_count": reason_counts["stale_or_failed_gbrain_overclaim"],
            "background_or_controller_overclaim_count": reason_counts["background_or_controller_overclaim"],
            "historical_evidence_skipped_count": historical_evidence_skipped,
        },
        "evidence": evidence_join(details, limit=2),
        "reason": (
            "Route-changing learning material lacks GitHub/raw evidence, memory disposition, fallback, owner action, literal readback, or bounded foreground-only language"
            if offenders
            else "Route-changing learning propagation evidence is complete or absent"
        ),
    }


CAPABILITY_PLACEMENT_EXPLAINER_PATTERN = re.compile(
    r"\b(AS-43|Capability Placement Preview Gap)\b.{0,180}\b(detects|detector|signature|triggers?)\b",
    re.IGNORECASE | re.DOTALL,
)
CAPABILITY_PLACEMENT_SURFACE_PATTERN = re.compile(
    r"\b(Autonomy Preview|capability[- ]placement|CAPABILITY_PLACEMENT_PREVIEW|"
    r"best_current_owner|best current owner|Allowed reach now|Promotion gate|"
    r"Demotion/rejection trigger|Forbidden mode)\b",
    re.IGNORECASE,
)
CAPABILITY_PLACEMENT_CORE_SURFACE_PATTERN = re.compile(
    r"\b(Autonomy Preview|capability[- ]placement|CAPABILITY_PLACEMENT_PREVIEW|"
    r"best_current_owner|best current owner|best_future_owner|best future owner|"
    r"allowed_reach_now|Allowed reach now|native_signal|native signal|"
    r"kill_switch|kill switch|forbidden_mode|Forbidden mode|"
    r"gbrain_slug_or_no_capture_reason|GBrain slug/no-capture reason)\b",
    re.IGNORECASE,
)
CAPABILITY_PLACEMENT_REQUIRED_FIELDS: tuple[tuple[str, re.Pattern[str]], ...] = (
    ("missing_best_current_owner", re.compile(r"\b(best_current_owner|best current owner)\b", re.IGNORECASE)),
    ("missing_best_future_owner", re.compile(r"\b(best_future_owner|best future owner)\b", re.IGNORECASE)),
    ("missing_allowed_reach_now", re.compile(r"\b(allowed_reach_now|allowed reach now)\b", re.IGNORECASE)),
    ("missing_native_signal", re.compile(r"\b(native_signal|native signal)\b", re.IGNORECASE)),
    ("missing_promotion_gate", re.compile(r"\b(promotion_gate|promotion gate)\b", re.IGNORECASE)),
    (
        "missing_demotion_rejection_trigger",
        re.compile(r"\b(demotion_rejection_trigger|demotion/rejection trigger|demotion trigger|rejection trigger)\b", re.IGNORECASE),
    ),
    ("missing_kill_switch", re.compile(r"\b(kill_switch|kill switch)\b", re.IGNORECASE)),
    ("missing_forbidden_mode", re.compile(r"\b(forbidden_mode|forbidden mode)\b", re.IGNORECASE)),
    (
        "missing_gbrain_slug_or_no_capture_reason",
        re.compile(r"\b(gbrain_slug_or_no_capture_reason|GBrain slug/no-capture reason|no_capture_reason)\b", re.IGNORECASE),
    ),
)
CAPABILITY_PLACEMENT_VAGUE_VALUE_PATTERN = re.compile(
    r"[:=]\s*(?:\"?\s*)?(?:tbd|todo|unknown|unclear|maybe|later|none|n/a|null|to be decided)\b",
    re.IGNORECASE,
)
CAPABILITY_PLACEMENT_AUTHORITY_PATTERN = re.compile(
    r"\b(controller|scheduler|queue|daemon|registry|dashboard|central autonomy ledger|hidden state store|"
    r"background\s+(?:Hermes|GBrain|Hermes/GBrain)|automatic\s+(?:issue|PR|pull request)\s+creation|"
    r"automatic GitHub mutation|auto-merge|background autonomy|"
    r"Codex cloud(?:/background)? write authority|Codex Cloud execution|remote execution|"
    r"Hermes primary (?:owner|ownership|operator)|Hermes-primary|GBrain canonical memory|"
    r"canonical GBrain memory|downstream mutation|replacement closure truth)\b",
    re.IGNORECASE,
)
CAPABILITY_PLACEMENT_NEGATION_PATTERN = re.compile(
    r"\b(no|not|never|does not|do not|without|forbid(?:s|den)?|forbidden|non[- ]claim|boundary|bounded|advisory[- ]first|advisory only)\b",
    re.IGNORECASE,
)
CAPABILITY_PLACEMENT_CONTRACT_PATH_HINTS = (
    "capability-placement-contract.md",
    "templates/capability-placement.md",
    "test-capability-placement-contract.sh",
    "detect-as-capability-placement-gap.sh",
)


def is_capability_placement_explainer(path: str, text: str) -> bool:
    lowered = path.lower()
    if any(hint in lowered for hint in CAPABILITY_PLACEMENT_CONTRACT_PATH_HINTS):
        return True
    return CAPABILITY_PLACEMENT_EXPLAINER_PATTERN.search(text) is not None


def capability_field_missing_or_vague(text: str, pattern: re.Pattern[str]) -> tuple[bool, bool]:
    lines = [line for line in text.splitlines() if pattern.search(line)]
    if not lines:
        return True, False
    if all(CAPABILITY_PLACEMENT_VAGUE_VALUE_PATTERN.search(line) for line in lines):
        return False, True
    return False, False


def capability_placement_authority_overclaim(text: str) -> bool:
    prohibition_context = 0
    for line in text.splitlines():
        has_prohibition_marker = re.search(
            r"\b(forbidden_mode|forbidden mode|bounded_non_claims|bounded non-claims|non-claims)\b",
            line,
            re.IGNORECASE,
        )
        missing_prohibition_marker = re.search(
            r"\b(no|missing|lacks?|without|omit(?:s|ted)?)\b.{0,60}"
            r"\b(forbidden mode|bounded_non_claims|bounded non-claims|non-claims)\b",
            line,
            re.IGNORECASE,
        )
        if has_prohibition_marker and not missing_prohibition_marker:
            prohibition_context = 4
        if not CAPABILITY_PLACEMENT_AUTHORITY_PATTERN.search(line):
            if prohibition_context:
                prohibition_context -= 1
            continue
        if prohibition_context or CAPABILITY_PLACEMENT_NEGATION_PATTERN.search(line):
            if prohibition_context:
                prohibition_context -= 1
            continue
        return True
    return False


COORDINATOR_ACCEPTANCE_VERDICT_FIELD_PATTERN = re.compile(
    r"\b(acceptance[_ -]verdict|acceptance verdict|verdict)\b",
    re.IGNORECASE,
)
COORDINATOR_ACCEPTANCE_VALID_VERDICT_PATTERN = re.compile(
    r"\b(acceptance[_ -]verdict|acceptance verdict|verdict)\b\s*[:=]?\s*"
    r"[`\"']?(accepted|partial|rejected|not[_ -]applicable)[`\"']?\b|"
    r"\bcoordinator autonomy acceptance\b.{0,80}\b(accepted|partial|rejected|not[_ -]applicable)\b",
    re.IGNORECASE | re.DOTALL,
)
COORDINATOR_ACCEPTANCE_EVIDENCE_VERDICT_VALUE_PATTERN = re.compile(
    r"\b(acceptance[_ -]verdict|acceptance verdict|verdict)\b\s*[:=]?\s*"
    r"[`\"']?(accepted|partial|rejected)[`\"']?\b|"
    r"\bcoordinator autonomy acceptance\b.{0,80}\b(accepted|partial|rejected)\b",
    re.IGNORECASE | re.DOTALL,
)
COORDINATOR_ACCEPTANCE_DEMOTION_TRIGGER_PATTERN = re.compile(
    r"\b(demotion/rejection trigger|demotion_rejection_trigger|demotion trigger|"
    r"rejection trigger|demote|demotion|reject(?:ion)? trigger)\b",
    re.IGNORECASE,
)
COORDINATOR_ACCEPTANCE_MISSING_DEMOTION_TRIGGER_PATTERN = re.compile(
    r"\b(no|missing|lacks?|without|omit(?:s|ted)?)\b.{0,60}"
    r"\b(demotion/rejection trigger|demotion_rejection_trigger|demotion trigger|"
    r"rejection trigger)\b",
    re.IGNORECASE | re.DOTALL,
)
COORDINATOR_ACCEPTANCE_MISSING_NEXT_OWNER_ACTION_PATTERN = re.compile(
    r"\b(no|missing|lacks?|without|omit(?:s|ted)?)\b.{0,60}"
    r"\b(next_owner_action|next owner action|owner action|owner[- ]surface action)\b",
    re.IGNORECASE | re.DOTALL,
)
COORDINATOR_ACCEPTANCE_GATE_VAGUE_PATTERN = re.compile(
    r"\b(promotion gate|promotion_gate|demotion/rejection trigger|"
    r"demotion_rejection_trigger|demotion trigger|rejection trigger)\b\s*[:=]\s*"
    r"[`\"']?(tbd|todo|unknown|unclear|maybe|later|none|n/a|null|to be decided)\b",
    re.IGNORECASE,
)


def coordinator_acceptance_reasons(text: str) -> tuple[list[str], Counter[str]]:
    reasons: list[str] = []
    counts: Counter[str] = Counter()

    if not COORDINATOR_ACCEPTANCE_VALID_VERDICT_PATTERN.search(text):
        if COORDINATOR_ACCEPTANCE_VERDICT_FIELD_PATTERN.search(text):
            reasons.append("invalid_acceptance_verdict")
            counts["invalid_acceptance_verdict"] += 1
        else:
            reasons.append("missing_acceptance_verdict")
            counts["missing_acceptance_verdict"] += 1
        return reasons, counts

    if not COORDINATOR_ACCEPTANCE_EVIDENCE_VERDICT_VALUE_PATTERN.search(text):
        return reasons, counts

    positive_checks: tuple[tuple[str, re.Pattern[str]], ...] = (
        ("missing_acceptance_github_truth", COORDINATOR_ACCEPTANCE_GITHUB_TRUTH_PATTERN),
        ("missing_acceptance_raw_runtime_evidence", COORDINATOR_ACCEPTANCE_RAW_RUNTIME_PATTERN),
        ("missing_acceptance_goal_or_goal_null", ISSUE164_GOAL_PATTERN),
        ("missing_acceptance_run_root_progress_ledger", ISSUE164_PROGRESS_LEDGER_PATTERN),
    )
    for reason, pattern in positive_checks:
        if not issue164_has_positive_field(text, pattern):
            reasons.append(reason)
            counts[reason] += 1
    direct_checks: tuple[tuple[str, re.Pattern[str], re.Pattern[str]], ...] = (
        (
            "missing_acceptance_demotion_trigger",
            COORDINATOR_ACCEPTANCE_DEMOTION_TRIGGER_PATTERN,
            COORDINATOR_ACCEPTANCE_MISSING_DEMOTION_TRIGGER_PATTERN,
        ),
        (
            "missing_acceptance_next_owner_action",
            ISSUE164_CONCRETE_NEXT_PATTERN,
            COORDINATOR_ACCEPTANCE_MISSING_NEXT_OWNER_ACTION_PATTERN,
        ),
    )
    for reason, present_pattern, missing_pattern in direct_checks:
        if missing_pattern.search(text) or not present_pattern.search(text):
            reasons.append(reason)
            counts[reason] += 1
    if not issue164_has_positive_field(text, ISSUE164_RUN_ROOT_PATTERN):
        reason = "missing_acceptance_run_root_progress_ledger"
        if reason not in reasons:
            reasons.append(reason)
            counts[reason] += 1
    has_heartbeat_disposition = (
        COORDINATOR_ACCEPTANCE_HEARTBEAT_DISPOSITION_PATTERN.search(text) is not None
        and COORDINATOR_ACCEPTANCE_MISSING_HEARTBEAT_PATTERN.search(text) is None
    )
    if not has_heartbeat_disposition:
        reasons.append("missing_acceptance_heartbeat_disposition")
        counts["missing_acceptance_heartbeat_disposition"] += 1
    has_bounded_nonclaim = (
        COORDINATOR_ACCEPTANCE_BOUNDED_NONCLAIM_PATTERN.search(text) is not None
        and COORDINATOR_ACCEPTANCE_MISSING_BOUNDED_NONCLAIM_PATTERN.search(text) is None
    )
    if not has_bounded_nonclaim:
        reasons.append("missing_acceptance_bounded_non_claims")
        counts["missing_acceptance_bounded_non_claims"] += 1
    if COORDINATOR_ACCEPTANCE_GATE_VAGUE_PATTERN.search(text):
        reasons.append("vague_acceptance_gate")
        counts["vague_field"] += 1
    return reasons, counts


def capability_placement_gap(texts: dict[str, str]) -> dict[str, Any]:
    offenders: list[str] = []
    grounded: list[str] = []
    reason_counts: Counter[str] = Counter()
    historical_evidence_skipped = 0

    for path, text in owner_evidence_texts(texts).items():
        if path.startswith(HISTORICAL_CLOSURE_ARTIFACT_PREFIXES):
            historical_evidence_skipped += 1
            continue
        if is_work_management_signature_explainer(path, text):
            grounded.append(path)
            continue
        if is_capability_placement_explainer(path, text):
            grounded.append(path)
            continue
        if not path.endswith((".md", ".txt", ".json", ".jsonl", ".yml", ".yaml")):
            continue
        is_acceptance_surface = COORDINATOR_ACCEPTANCE_SURFACE_PATTERN.search(text) is not None
        is_placement_surface = CAPABILITY_PLACEMENT_SURFACE_PATTERN.search(text) is not None
        if is_acceptance_surface:
            is_placement_surface = CAPABILITY_PLACEMENT_CORE_SURFACE_PATTERN.search(text) is not None
        if not is_placement_surface and not is_acceptance_surface:
            continue

        reasons: list[str] = []
        if is_placement_surface:
            for reason, pattern in CAPABILITY_PLACEMENT_REQUIRED_FIELDS:
                missing, vague = capability_field_missing_or_vague(text, pattern)
                if missing:
                    reasons.append(reason)
                    reason_counts[reason] += 1
                elif vague:
                    reasons.append(f"vague_{reason.removeprefix('missing_')}")
                    reason_counts["vague_field"] += 1

        if is_acceptance_surface:
            acceptance_reasons, acceptance_counts = coordinator_acceptance_reasons(text)
            reasons.extend(acceptance_reasons)
            reason_counts.update(acceptance_counts)

        if capability_placement_authority_overclaim(text):
            reasons.append("forbidden_authority_overclaim")
            reason_counts["forbidden_authority_overclaim"] += 1

        if reasons:
            offenders.append(f"{path}=>{';'.join(reasons[:6])}")
        else:
            grounded.append(path)

    details = [
        f"capability_placement_gap=>{';'.join(offenders[:4]) or 'none'}",
        f"capability_placement_grounded=>{','.join(sorted(set(grounded))[:4]) or 'none'}",
    ]
    return {
        "fired": bool(offenders),
        "signals": {
            "capability_placement_gap_count": len(offenders),
            "capability_placement_grounded_count": len(set(grounded)),
            "missing_best_current_owner_count": reason_counts["missing_best_current_owner"],
            "missing_best_future_owner_count": reason_counts["missing_best_future_owner"],
            "missing_allowed_reach_now_count": reason_counts["missing_allowed_reach_now"],
            "missing_native_signal_count": reason_counts["missing_native_signal"],
            "missing_promotion_gate_count": reason_counts["missing_promotion_gate"],
            "missing_demotion_rejection_trigger_count": reason_counts["missing_demotion_rejection_trigger"],
            "missing_kill_switch_count": reason_counts["missing_kill_switch"],
            "missing_forbidden_mode_count": reason_counts["missing_forbidden_mode"],
            "missing_gbrain_slug_or_no_capture_reason_count": reason_counts["missing_gbrain_slug_or_no_capture_reason"],
            "missing_acceptance_verdict_count": reason_counts["missing_acceptance_verdict"],
            "invalid_acceptance_verdict_count": reason_counts["invalid_acceptance_verdict"],
            "missing_acceptance_github_truth_count": reason_counts["missing_acceptance_github_truth"],
            "missing_acceptance_raw_runtime_evidence_count": reason_counts["missing_acceptance_raw_runtime_evidence"],
            "missing_acceptance_goal_or_goal_null_count": reason_counts["missing_acceptance_goal_or_goal_null"],
            "missing_acceptance_run_root_progress_ledger_count": reason_counts["missing_acceptance_run_root_progress_ledger"],
            "missing_acceptance_heartbeat_disposition_count": reason_counts["missing_acceptance_heartbeat_disposition"],
            "missing_acceptance_bounded_non_claims_count": reason_counts["missing_acceptance_bounded_non_claims"],
            "missing_acceptance_demotion_trigger_count": reason_counts["missing_acceptance_demotion_trigger"],
            "missing_acceptance_next_owner_action_count": reason_counts["missing_acceptance_next_owner_action"],
            "vague_field_count": reason_counts["vague_field"],
            "forbidden_authority_overclaim_count": reason_counts["forbidden_authority_overclaim"],
            "historical_evidence_skipped_count": historical_evidence_skipped,
        },
        "evidence": evidence_join(details, limit=2),
        "reason": (
            "Capability placement material lacks required Autonomy Preview fields or overclaims forbidden authority"
            if offenders
            else "Capability placement preview evidence is complete or absent"
        ),
    }


HERMES_FOREGROUND_RELIABILITY_EXPLAINER_PATTERN = re.compile(
    r"\b(AS-44|Hermes Foreground Reliability Evidence Gap)\b.{0,180}\b(detects|detector|signature|triggers?)\b",
    re.IGNORECASE | re.DOTALL,
)
HERMES_FOREGROUND_RELIABILITY_SURFACE_PATTERN = re.compile(
    r"\b(Hermes foreground reliability|foreground Hermes reliability|Hermes doer|Hermes checker|"
    r"checker[-_ ]shadow|checker[-_ ]advisory|attempt_role|attempt role|hermes_eligibility|"
    r"Hermes eligibility|launcher_receipt|coordinator_review|validation_owner|publication_scope|"
    r"publication scope)\b",
    re.IGNORECASE,
)
HERMES_RELIABILITY_SURFACE_NEGATION_PATTERN = re.compile(
    r"\b(no|not|without|absent|lacks?|missing)\b.{0,80}"
    r"\b(Hermes foreground reliability|foreground Hermes reliability|Hermes doer|Hermes checker|"
    r"checker[-_ ]shadow|checker[-_ ]advisory|attempt_role|attempt role|hermes_eligibility|"
    r"Hermes eligibility|launcher_receipt|coordinator_review|validation_owner|publication_scope|"
    r"publication scope)\b",
    re.IGNORECASE,
)
HERMES_FOREGROUND_RELIABILITY_REQUIRED_FIELDS: tuple[tuple[str, re.Pattern[str]], ...] = (
    ("missing_hermes_eligibility", re.compile(r"\b(hermes_eligibility|Hermes eligibility|eligibility)\b", re.IGNORECASE)),
    ("missing_attempt_role", re.compile(r"\b(attempt_role|attempt role|doer|checker_shadow|checker[- ]shadow|checker_advisory|checker[- ]advisory|not_eligible|not[- ]eligible)\b", re.IGNORECASE)),
    ("missing_launcher_receipt", re.compile(r"\b(launcher_receipt|launcher receipt|run receipt|HERMES_FOREGROUND_RUN_RECEIPT)\b", re.IGNORECASE)),
    ("missing_failure_guidance", re.compile(r"\b(pre[- ]fallback guidance|before Codex fallback|HERMES_FOREGROUND_FAILURE_GUIDANCE|not_needed_reason|not[- ]needed reason|clean[- ]success reason)\b", re.IGNORECASE)),
    ("missing_coordinator_review", re.compile(r"\b(coordinator_review|coordinator review|Codex review|BMA review|reviewer)\b", re.IGNORECASE)),
    ("missing_validation_owner", re.compile(r"\b(validation_owner|validation owner)\b", re.IGNORECASE)),
    ("missing_publication_scope", re.compile(r"\b(publication_scope|publication scope)\b", re.IGNORECASE)),
    ("missing_promotion_gate", re.compile(r"\b(promotion_gate|promotion gate)\b", re.IGNORECASE)),
    (
        "missing_demotion_rejection_trigger",
        re.compile(r"\b(demotion_rejection_trigger|demotion/rejection trigger|demotion trigger|rejection trigger)\b", re.IGNORECASE),
    ),
    (
        "missing_checker_shadow_disposition",
        re.compile(r"\b(checker_shadow_disposition|checker shadow disposition|checker disposition|shadow disposition)\b", re.IGNORECASE),
    ),
    ("missing_bounded_non_claims", re.compile(r"\b(bounded_non_claims|bounded non-claims|forbidden mode|forbidden authority|non-claims)\b", re.IGNORECASE)),
)
HERMES_RELIABILITY_CONTRACT_PATH_HINTS = (
    "hermes-foreground-reliability-contract.md",
    "hermes-foreground-reliability.md",
    "test-hermes-foreground-reliability-contract.sh",
    "detect-as-hermes-foreground-reliability-evidence-gap.sh",
    "test-hermes-foreground-reliability-evidence-gap.sh",
)
HERMES_RELIABILITY_VAGUE_VALUE_PATTERN = re.compile(
    r"[:=]\s*(?:\"?\s*)?(?:tbd|todo|unknown|unclear|maybe|later|none|n/a|null|to be decided)\b",
    re.IGNORECASE,
)
# `publication_scope: none` is a bounded valid value, not an unknown placeholder.
HERMES_RELIABILITY_VAGUE_VALUE_ALLOW_NONE_PATTERN = re.compile(
    r"[:=]\s*(?:\"?\s*)?(?:tbd|todo|unknown|unclear|maybe|later|n/a|null|to be decided)\b",
    re.IGNORECASE,
)
HERMES_VALIDATION_OWNER_OVERCLAIM_PATTERN = re.compile(
    r"\b(?:validation_owner|validation owner)\s*[:=]\s*(?:Hermes|foreground Hermes)\b|"
    r"\bHermes\b.{0,120}\b(?:owns|runs|performs|controls|will\s+run)\b.{0,120}\b(?:validation|broad validation|local gates|CI|checks)\b",
    re.IGNORECASE,
)
HERMES_CHECKER_SHADOW_AUTHORITY_OVERCLAIM_PATTERN = re.compile(
    r"\bHermes\b.{0,80}\bchecker[-_ ]?shadow\b.{0,120}\b(?:approve(?:d|s)?|self[- ]?approve(?:d|s)?|"
    r"self[- ]?approval|edit(?:ed|s)?|own(?:s|ed)?\s+(?:the\s+)?(?:diff|edits?|implementation)|claims?\s+approval)\b|"
    r"\bchecker[-_ ]?shadow\b.{0,120}\b(?:approve(?:d|s)?|self[- ]?approve(?:d|s)?|self[- ]?approval|edit(?:ed|s)?|claims?\s+approval)\b",
    re.IGNORECASE,
)
HERMES_PUBLICATION_SCOPE_OVERCLAIM_PATTERN = re.compile(
    r"\bHermes\b.{0,120}\b(?:publish(?:es|ed)?|push(?:es|ed)?|open(?:s|ed)?|create(?:s|d)?)\b.{0,80}"
    r"\b(?:branch(?:es)?|PRs?|pull requests?)\b|"
    r"\b(?:branch publish|publish branch|open PR|opened PR|create PR|created PR)\b",
    re.IGNORECASE,
)
HERMES_AUTONOMOUS_RETRY_OVERCLAIM_PATTERN = re.compile(
    r"\bHermes\b.{0,120}\b(?:autonomous(?:ly)?|automatic(?:ally)?|retry loop|fix[- ]cycle|"
    r"retry(?:ing|ies|ied)?|fix(?:es|ed|ing)?)\b.{0,120}\b(?:without review|until CI|until checks|CI is green|checks are green|"
    r"broad validation)\b|"
    r"\b(?:autonomous retry|automatic fix[- ]cycle|Hermes retry loop)\b",
    re.IGNORECASE,
)
HERMES_CONTROL_PLANE_OVERCLAIM_PATTERN = re.compile(
    r"\b(?:Hermes|GBrain)\b.{0,100}\b(?:controller|queue|scheduler|daemon|registry|background job|"
    r"automatic issue|automatic PR|auto[- ]?merge|downstream mutation)\b|"
    r"\b(?:background Hermes|background GBrain|Hermes controller|Hermes queue|Hermes scheduler|Hermes daemon|"
    r"GBrain controller|GBrain queue|GBrain scheduler|GBrain daemon|hidden registr(?:y|ies)|auto[- ]?merge|"
    r"automatic issue creation|automatic PR creation|mutate downstream)\b",
    re.IGNORECASE,
)
HERMES_RELIABILITY_FORBIDDEN_AUTHORITY_PATTERN = re.compile(
    r"\bHermes\b.{0,80}\b(owns|coordinates|merges|auto[- ]?merges|polls|retries|schedules|queues|"
    r"creates?\s+(?:issues?|PRs?|pull requests?)|runs\s+background|operates\s+as\s+coordinator|"
    r"owns\s+campaign|owns\s+Campaign Sync|owns\s+recovery|owns\s+CI|runs\s+CI|owns\s+merge|"
    r"primary\s+operator)\b|"
    r"\b(background Hermes|Hermes retry loop|Hermes scheduler|Hermes queue|Hermes daemon|Hermes controller|"
    r"Hermes auto[- ]?merge|Hermes-primary campaign|Hermes-primary operator|Hermes owns Campaign Sync|"
    r"Hermes owns recovery|Hermes owns CI|hermes -z adoption)\b",
    re.IGNORECASE | re.DOTALL,
)
HERMES_RELIABILITY_OVERCLAIM_PATTERNS: tuple[tuple[str, re.Pattern[str]], ...] = (
    ("checker_shadow_authority_overclaim", HERMES_CHECKER_SHADOW_AUTHORITY_OVERCLAIM_PATTERN),
    ("publication_scope_overclaim", HERMES_PUBLICATION_SCOPE_OVERCLAIM_PATTERN),
    ("autonomous_retry_overclaim", HERMES_AUTONOMOUS_RETRY_OVERCLAIM_PATTERN),
    ("control_plane_overclaim", HERMES_CONTROL_PLANE_OVERCLAIM_PATTERN),
)
HERMES_RELIABILITY_NEGATION_PATTERN = re.compile(
    r"\b(no|not|never|does not|do not|without|forbid(?:s|den)?|forbidden|non[- ]claim|boundary|bounded|"
    r"foreground[- ]only|advisory[- ]only|excluded authority|does not transfer|only when explicitly scoped|"
    r"explicitly scoped foreground|explicitly scoped)\b",
    re.IGNORECASE,
)


def is_hermes_foreground_reliability_explainer(path: str, text: str) -> bool:
    lowered = path.lower()
    if any(hint in lowered for hint in HERMES_RELIABILITY_CONTRACT_PATH_HINTS):
        return True
    return HERMES_FOREGROUND_RELIABILITY_EXPLAINER_PATTERN.search(text) is not None


def has_hermes_foreground_reliability_surface(text: str) -> bool:
    for line in text.splitlines():
        if not HERMES_FOREGROUND_RELIABILITY_SURFACE_PATTERN.search(line):
            continue
        if HERMES_RELIABILITY_SURFACE_NEGATION_PATTERN.search(line):
            continue
        return True
    return False


def hermes_reliability_field_missing_or_vague(
    text: str, pattern: re.Pattern[str], *, allow_none_value: bool = False
) -> tuple[bool, bool]:
    lines = [line for line in text.splitlines() if pattern.search(line)]
    if not lines:
        return True, False
    vague_pattern = HERMES_RELIABILITY_VAGUE_VALUE_ALLOW_NONE_PATTERN if allow_none_value else HERMES_RELIABILITY_VAGUE_VALUE_PATTERN
    if all(vague_pattern.search(line) for line in lines):
        return False, True
    return False, False


def hermes_reliability_line_overclaim(text: str, pattern: re.Pattern[str]) -> bool:
    prohibition_context = 0
    for line in text.splitlines():
        if re.search(r"\b(bounded_non_claims|bounded non-claims|forbidden mode|forbidden authority|excluded authority|non-claims)\b", line, re.IGNORECASE):
            is_non_claims_header = re.search(
                r"^\s*(?:#{1,6}\s*)?(?:bounded[_ -]non-claims|non-claims)\s*:?\s*$",
                line,
                re.IGNORECASE,
            )
            has_negation = re.search(
                r"\b(does not|do not|never|forbid(?:s|den)?|excluded|non[- ]claim)\b",
                line,
                re.IGNORECASE,
            )
            prohibition_context = 4 if (has_negation or is_non_claims_header) else 0
        if not pattern.search(line):
            if prohibition_context and line.strip():
                prohibition_context -= 1
            continue
        if prohibition_context or HERMES_RELIABILITY_NEGATION_PATTERN.search(line):
            if prohibition_context and line.strip():
                prohibition_context -= 1
            continue
        return True
    return False


def hermes_foreground_reliability_evidence_gap(texts: dict[str, str]) -> dict[str, Any]:
    offenders: list[str] = []
    grounded: list[str] = []
    reason_counts: Counter[str] = Counter()
    historical_evidence_skipped = 0

    for path, text in owner_evidence_texts(texts).items():
        if path.startswith(HISTORICAL_CLOSURE_ARTIFACT_PREFIXES):
            historical_evidence_skipped += 1
            continue
        if is_work_management_signature_explainer(path, text):
            grounded.append(path)
            continue
        if is_hermes_foreground_reliability_explainer(path, text):
            grounded.append(path)
            continue
        if not path.endswith((".md", ".txt", ".json", ".jsonl", ".yml", ".yaml")):
            continue
        if not has_hermes_foreground_reliability_surface(text):
            continue

        reasons: list[str] = []
        for reason, pattern in HERMES_FOREGROUND_RELIABILITY_REQUIRED_FIELDS:
            missing, vague = hermes_reliability_field_missing_or_vague(
                text,
                pattern,
                allow_none_value=reason == "missing_publication_scope",
            )
            if missing:
                reasons.append(reason)
                reason_counts[reason] += 1
            elif vague:
                reasons.append(f"vague_{reason.removeprefix('missing_')}")
                reason_counts["vague_field"] += 1

        if hermes_reliability_line_overclaim(text, HERMES_VALIDATION_OWNER_OVERCLAIM_PATTERN):
            reasons.append("validation_owner_overclaim")
            reason_counts["validation_owner_overclaim"] += 1
        for reason, pattern in HERMES_RELIABILITY_OVERCLAIM_PATTERNS:
            if hermes_reliability_line_overclaim(text, pattern):
                reasons.append(reason)
                reason_counts[reason] += 1
        if hermes_reliability_line_overclaim(text, HERMES_RELIABILITY_FORBIDDEN_AUTHORITY_PATTERN):
            reasons.append("forbidden_hermes_authority")
            reason_counts["forbidden_hermes_authority"] += 1

        if reasons:
            offenders.append(f"{path}=>{';'.join(reasons[:6])}")
        else:
            grounded.append(path)

    details = [
        f"hermes_foreground_reliability_gap=>{';'.join(offenders[:4]) or 'none'}",
        f"hermes_foreground_reliability_grounded=>{','.join(sorted(set(grounded))[:4]) or 'none'}",
    ]
    return {
        "fired": bool(offenders),
        "signals": {
            "hermes_foreground_reliability_gap_count": len(offenders),
            "hermes_foreground_reliability_grounded_count": len(set(grounded)),
            "missing_hermes_eligibility_count": reason_counts["missing_hermes_eligibility"],
            "missing_attempt_role_count": reason_counts["missing_attempt_role"],
            "missing_launcher_receipt_count": reason_counts["missing_launcher_receipt"],
            "missing_failure_guidance_count": reason_counts["missing_failure_guidance"],
            "missing_coordinator_review_count": reason_counts["missing_coordinator_review"],
            "missing_validation_owner_count": reason_counts["missing_validation_owner"],
            "missing_publication_scope_count": reason_counts["missing_publication_scope"],
            "missing_promotion_gate_count": reason_counts["missing_promotion_gate"],
            "missing_demotion_rejection_trigger_count": reason_counts["missing_demotion_rejection_trigger"],
            "missing_checker_shadow_disposition_count": reason_counts["missing_checker_shadow_disposition"],
            "missing_bounded_non_claims_count": reason_counts["missing_bounded_non_claims"],
            "vague_field_count": reason_counts["vague_field"],
            "validation_owner_overclaim_count": reason_counts["validation_owner_overclaim"],
            "checker_shadow_authority_overclaim_count": reason_counts["checker_shadow_authority_overclaim"],
            "publication_scope_overclaim_count": reason_counts["publication_scope_overclaim"],
            "autonomous_retry_overclaim_count": reason_counts["autonomous_retry_overclaim"],
            "control_plane_overclaim_count": reason_counts["control_plane_overclaim"],
            "forbidden_hermes_authority_count": reason_counts["forbidden_hermes_authority"],
            "historical_evidence_skipped_count": historical_evidence_skipped,
        },
        "evidence": evidence_join(details, limit=2),
        "reason": (
            "Hermes foreground reliability material lacks doer/checker evidence fields or overclaims Hermes authority"
            if offenders
            else "Hermes foreground reliability evidence is complete or absent"
        ),
    }


CODEX_NATIVE_RUNTIME_EXPLAINER_PATTERN = re.compile(
    r"\b(AS-45|Codex Native Runtime Readiness Evidence Gap)\b.{0,180}\b(detects|detector|signature|triggers?)\b",
    re.IGNORECASE | re.DOTALL,
)
CODEX_NATIVE_RUNTIME_SURFACE_PATTERN = re.compile(
    r"\b(Codex native runtime readiness|Codex Native Runtime / Cloud / Remote Readiness|"
    r"native runtime readiness|runtime[-_ ]context payload|runtime[-_ ]context preflight|"
    r"remote/cloud readiness disposition|cloud/remote readiness disposition|"
    r"Codex Cloud/remote readiness|local/worktree dogfood|worktree dogfood)\b",
    re.IGNORECASE,
)
CODEX_NATIVE_RUNTIME_SURFACE_NEGATION_PATTERN = re.compile(
    r"\b(no|not|without|absent|lacks?|missing|omit(?:s|ted)?)\b.{0,90}"
    r"\b(Codex native runtime readiness|native runtime readiness|runtime[-_ ]context payload|"
    r"runtime[-_ ]context preflight|cloud/remote readiness|local/worktree dogfood|worktree dogfood)\b",
    re.IGNORECASE,
)
CODEX_RUNTIME_VAGUE_VALUE_PATTERN = re.compile(
    r"[:=]\s*(?:\"?\s*)?(?:(?:tbd|todo|unknown|unclear|maybe|later|none|n/a|null|to be decided)\b|"
    r"(?:missing|absent|omitted)\s*\.?\s*$)",
    re.IGNORECASE,
)
CODEX_RUNTIME_NEGATIVE_FIELD_PATTERN = re.compile(
    r"\b(no|not|without|absent|lacks?|missing|omit(?:s|ted)?)\b",
    re.IGNORECASE,
)
CODEX_NATIVE_RUNTIME_FIELD_PATTERNS: tuple[tuple[str, re.Pattern[str]], ...] = (
    ("missing_transfer_mode", re.compile(r"\b(transfer_mode|transfer mode|fresh[- ]thread|same[- ]thread|fork)\b", re.IGNORECASE)),
    ("missing_goal_or_goal_null", re.compile(r"\b(goal_state|Goal state|Goal-null|Goal null|goal[- ]null)\b", re.IGNORECASE)),
    ("missing_runtime_context_preflight", re.compile(r"\b(runtime[-_ ]context|issue164-native-preflight\.py|native preflight|preflight summary|runtime-context payload)\b", re.IGNORECASE)),
    ("missing_heartbeat_lifecycle", re.compile(r"\b(heartbeat_lifecycle|heartbeat lifecycle|heartbeat status|heartbeat disposition|heartbeat capture)\b", re.IGNORECASE)),
    ("missing_local_worktree_dogfood", re.compile(r"\b(local/worktree|local worktree|worktree dogfood|local dogfood|worktree runtime|local runtime)\b", re.IGNORECASE)),
    ("missing_cloud_remote_disposition", re.compile(r"\b(cloud/remote disposition|remote/cloud readiness disposition|cloud readiness disposition|remote readiness disposition|no live cloud|no live remote|cloud/remote as context)\b", re.IGNORECASE)),
    ("missing_official_codex_context", re.compile(r"\b(official Codex|Codex manual|OpenAI Codex docs|Codex docs|official OpenAI docs)\b", re.IGNORECASE)),
    ("missing_github_truth", re.compile(r"\b(GitHub issue/PR/check/merge|issue/PR/check/merge|PR/check/merge|GitHub truth|merge truth|CI / check|CI/check)\b", re.IGNORECASE)),
    ("missing_ci_polling_terminal_condition", re.compile(r"\b(CI polling|foreground CI polling|polling terminal condition|terminal condition|check run|green-clean|merge-or-blocker|GitHub-visible blocker)\b", re.IGNORECASE)),
    ("missing_promotion_gate", re.compile(r"\b(proof_gate|proof gate|promotion_gate|promotion gate)\b", re.IGNORECASE)),
    ("missing_demotion_rejection_trigger", re.compile(r"\b(demotion_rejection_trigger|demotion/rejection trigger|demotion trigger|rejection trigger)\b", re.IGNORECASE)),
    ("missing_kill_switch", re.compile(r"\b(kill_switch|kill switch)\b", re.IGNORECASE)),
    ("missing_bounded_non_claims", re.compile(r"\b(bounded_non_claims|bounded non-claims|bounded nonclaims|non-claims|forbidden mode|non-claim)\b", re.IGNORECASE)),
    ("missing_next_owner_action", re.compile(r"\b(next_owner_action|next owner action|next active track|owner-surface action|owner surface action)\b", re.IGNORECASE)),
)
CODEX_NATIVE_RUNTIME_CONTRACT_PATH_HINTS = (
    "codex-native-runtime-readiness-contract.md",
    "codex-native-runtime-readiness.md",
    "detect-as-codex-native-runtime-readiness-evidence-gap.sh",
    "test-codex-native-runtime-readiness-evidence-gap.sh",
)
CODEX_RUNTIME_OFFICIAL_DOCS_AS_LIVE_PROOF_PATTERN = re.compile(
    r"\b(official Codex|Codex manual|OpenAI Codex docs|Codex docs|official OpenAI docs)\b"
    r".{0,140}\b(proves?|proof|validated?|verified?)\b"
    r".{0,140}\b(live cloud|live remote|cloud execution|remote execution|Codex Cloud|remote pilot|cloud pilot|live run)\b|"
    r"\b(live cloud|live remote|cloud execution|remote execution|Codex Cloud|remote pilot|cloud pilot|live run)\b"
    r".{0,140}\b(proves?|proof|validated?|verified?)\b"
    r".{0,140}\b(official Codex|Codex manual|OpenAI Codex docs|Codex docs|official OpenAI docs)\b",
    re.IGNORECASE,
)
CODEX_RUNTIME_LIVE_CLOUD_REMOTE_OVERCLAIM_PATTERN = re.compile(
    r"\b(Codex Cloud|cloud runtime|remote execution|remote runtime|cloud pilot|remote pilot)\b"
    r".{0,120}\b(execut(?:ed|ion)|ran|run|pilot|dogfood|proof|validated?|verified?)\b|"
    r"\b(live cloud|live remote)\b.{0,120}\b(execut(?:ed|ion)|ran|run|pilot|proof)\b",
    re.IGNORECASE,
)
CODEX_RUNTIME_GOAL_IMPROVEMENT_PATTERN = re.compile(
    r"\bGoal mode\b.{0,140}\b(improved|reduced|increased|better|self[- ]?healed|strengthened)\b"
    r".{0,140}\b(runtime|autonomy|continuity|self[- ]?healing|throughput|operator steering|recovery)\b|"
    r"\b(runtime|autonomy|continuity|self[- ]?healing|throughput|operator steering|recovery)\b"
    r".{0,140}\b(improved|reduced|increased|better|self[- ]?healed|strengthened)\b"
    r".{0,140}\bGoal mode\b",
    re.IGNORECASE | re.DOTALL,
)
CODEX_RUNTIME_RAW_EVIDENCE_PATTERN = re.compile(
    r"\b(session logs?|Goal metadata|command transcripts?|CI/check runs?|CI runs?|check runs?|"
    r"runtime ledgers?|progress-ledger\.jsonl|replay logs?|raw runtime evidence|raw evidence)\b",
    re.IGNORECASE,
)
CODEX_RUNTIME_CONTROL_PLANE_OVERCLAIM_PATTERN = re.compile(
    r"\b(background automation|background subagent|subagent controller|subagent scheduler|subagent queue|"
    r"automation controller|automation scheduler|automation queue|automation daemon|automation registry|"
    r"controller|scheduler|queue|daemon|registry|background job)\b",
    re.IGNORECASE,
)
CODEX_RUNTIME_AUTOMATIC_GITHUB_OVERCLAIM_PATTERN = re.compile(
    r"\b(automatic issue creation|automatic PR creation|automatic pull request creation|"
    r"automatic GitHub mutation|auto[- ]?merge|automatic merge)\b",
    re.IGNORECASE,
)
CODEX_RUNTIME_RETAINED_CLOSEOUT_OVERCLAIM_PATTERN = re.compile(
    r"\b(retained closeout package|retained closeout truth|local closeout truth|completion manifest|handoff closeout)\b",
    re.IGNORECASE,
)
CODEX_RUNTIME_DOWNSTREAM_MUTATION_OVERCLAIM_PATTERN = re.compile(
    r"\b(downstream mutation|mutate downstream|core-five mutation|mutate core-five|repo-upgrade-advisor mutation|repo-optimizer mutation)\b",
    re.IGNORECASE,
)
CODEX_RUNTIME_NEGATION_PATTERN = re.compile(
    r"\b(no|not|never|does not|do not|without|forbid(?:s|den)?|forbidden|non[- ]claim|boundary|bounded|"
    r"context only|capability context|no live|no runtime-improvement claim|raw evidence required|read-only|untouched)\b",
    re.IGNORECASE,
)


def is_codex_native_runtime_explainer(path: str, text: str) -> bool:
    lowered = path.lower()
    if any(hint in lowered for hint in CODEX_NATIVE_RUNTIME_CONTRACT_PATH_HINTS):
        return True
    return CODEX_NATIVE_RUNTIME_EXPLAINER_PATTERN.search(text) is not None


def has_codex_native_runtime_surface(text: str) -> bool:
    for line in text.splitlines():
        if not CODEX_NATIVE_RUNTIME_SURFACE_PATTERN.search(line):
            continue
        if CODEX_NATIVE_RUNTIME_SURFACE_NEGATION_PATTERN.search(line):
            continue
        return True
    return False


def codex_runtime_field_missing_or_vague(text: str, pattern: re.Pattern[str]) -> tuple[bool, bool]:
    positive_lines = []
    for line in text.splitlines():
        match = pattern.search(line)
        if not match:
            continue
        prefix = line[max(0, match.start() - 90):match.start()]
        if CODEX_RUNTIME_NEGATIVE_FIELD_PATTERN.search(prefix):
            continue
        positive_lines.append(line)
    if not positive_lines:
        return True, False
    if all(CODEX_RUNTIME_VAGUE_VALUE_PATTERN.search(line) for line in positive_lines):
        return False, True
    return False, False


def codex_runtime_line_overclaim(text: str, pattern: re.Pattern[str]) -> bool:
    prohibition_context = 0
    for line in text.splitlines():
        if re.search(r"\b(bounded_non_claims|bounded non-claims|forbidden mode|non-claims|bounded nonclaims)\b", line, re.IGNORECASE):
            is_non_claims_header = re.search(
                r"^\s*(?:#{1,6}\s*)?(?:bounded[_ -]non-claims|non-claims|bounded nonclaims)\s*:?\s*$",
                line,
                re.IGNORECASE,
            )
            has_negation = CODEX_RUNTIME_NEGATION_PATTERN.search(line) is not None
            is_vague_nonclaim = CODEX_RUNTIME_VAGUE_VALUE_PATTERN.search(line) is not None
            prohibition_context = 4 if (not is_vague_nonclaim and (has_negation or is_non_claims_header)) else 0
        if not pattern.search(line):
            if prohibition_context and line.strip():
                prohibition_context -= 1
            continue
        if prohibition_context or CODEX_RUNTIME_NEGATION_PATTERN.search(line):
            if prohibition_context and line.strip():
                prohibition_context -= 1
            continue
        return True
    return False


def codex_runtime_goal_improvement_without_raw_evidence(text: str) -> bool:
    return CODEX_RUNTIME_GOAL_IMPROVEMENT_PATTERN.search(text) is not None and CODEX_RUNTIME_RAW_EVIDENCE_PATTERN.search(text) is None


def codex_native_runtime_readiness_evidence_gap(texts: dict[str, str]) -> dict[str, Any]:
    offenders: list[str] = []
    grounded: list[str] = []
    reason_counts: Counter[str] = Counter()
    historical_evidence_skipped = 0

    for path, text in owner_evidence_texts(texts).items():
        if path.startswith(HISTORICAL_CLOSURE_ARTIFACT_PREFIXES):
            historical_evidence_skipped += 1
            continue
        if is_work_management_signature_explainer(path, text):
            grounded.append(path)
            continue
        if is_codex_native_runtime_explainer(path, text):
            grounded.append(path)
            continue
        if not path.endswith((".md", ".txt", ".json", ".jsonl", ".yml", ".yaml")):
            continue
        if not has_codex_native_runtime_surface(text):
            continue

        reasons: list[str] = []
        for reason, pattern in CODEX_NATIVE_RUNTIME_FIELD_PATTERNS:
            missing, vague = codex_runtime_field_missing_or_vague(text, pattern)
            if missing:
                reasons.append(reason)
                reason_counts[reason] += 1
            elif vague:
                reasons.append(f"vague_{reason.removeprefix('missing_')}")
                reason_counts["vague_field"] += 1
        if not (issue164_has_positive_field(text, ISSUE164_RUN_ROOT_PATTERN) and issue164_has_positive_field(text, ISSUE164_PROGRESS_LEDGER_PATTERN)):
            reasons.append("missing_run_root_progress_ledger")
            reason_counts["missing_run_root_progress_ledger"] += 1

        overclaim_patterns: tuple[tuple[str, re.Pattern[str]], ...] = (
            ("official_docs_as_live_proof_count", CODEX_RUNTIME_OFFICIAL_DOCS_AS_LIVE_PROOF_PATTERN),
            ("live_cloud_remote_overclaim_count", CODEX_RUNTIME_LIVE_CLOUD_REMOTE_OVERCLAIM_PATTERN),
            ("control_plane_overclaim_count", CODEX_RUNTIME_CONTROL_PLANE_OVERCLAIM_PATTERN),
            ("automatic_github_overclaim_count", CODEX_RUNTIME_AUTOMATIC_GITHUB_OVERCLAIM_PATTERN),
            ("retained_closeout_overclaim_count", CODEX_RUNTIME_RETAINED_CLOSEOUT_OVERCLAIM_PATTERN),
            ("downstream_mutation_overclaim_count", CODEX_RUNTIME_DOWNSTREAM_MUTATION_OVERCLAIM_PATTERN),
        )
        for reason, pattern in overclaim_patterns:
            if codex_runtime_line_overclaim(text, pattern):
                reasons.append(reason.removesuffix("_count"))
                reason_counts[reason] += 1
        if codex_runtime_goal_improvement_without_raw_evidence(text):
            reasons.append("goal_improvement_without_raw_evidence")
            reason_counts["goal_improvement_without_raw_evidence_count"] += 1

        if reasons:
            offenders.append(f"{path}=>{';'.join(reasons[:6])}")
        else:
            grounded.append(path)

    details = [
        f"codex_native_runtime_readiness_gap=>{';'.join(offenders[:4]) or 'none'}",
        f"codex_native_runtime_readiness_grounded=>{','.join(sorted(set(grounded))[:4]) or 'none'}",
    ]
    return {
        "fired": bool(offenders),
        "signals": {
            "codex_native_runtime_readiness_gap_count": len(offenders),
            "codex_native_runtime_readiness_grounded_count": len(set(grounded)),
            "missing_transfer_mode_count": reason_counts["missing_transfer_mode"],
            "missing_goal_or_goal_null_count": reason_counts["missing_goal_or_goal_null"],
            "missing_run_root_progress_ledger_count": reason_counts["missing_run_root_progress_ledger"],
            "missing_runtime_context_preflight_count": reason_counts["missing_runtime_context_preflight"],
            "missing_heartbeat_lifecycle_count": reason_counts["missing_heartbeat_lifecycle"],
            "missing_local_worktree_dogfood_count": reason_counts["missing_local_worktree_dogfood"],
            "missing_cloud_remote_disposition_count": reason_counts["missing_cloud_remote_disposition"],
            "missing_official_codex_context_count": reason_counts["missing_official_codex_context"],
            "missing_github_truth_count": reason_counts["missing_github_truth"],
            "missing_ci_polling_terminal_condition_count": reason_counts["missing_ci_polling_terminal_condition"],
            "missing_promotion_gate_count": reason_counts["missing_promotion_gate"],
            "missing_demotion_rejection_trigger_count": reason_counts["missing_demotion_rejection_trigger"],
            "missing_kill_switch_count": reason_counts["missing_kill_switch"],
            "missing_bounded_non_claims_count": reason_counts["missing_bounded_non_claims"],
            "missing_next_owner_action_count": reason_counts["missing_next_owner_action"],
            "vague_field_count": reason_counts["vague_field"],
            "official_docs_as_live_proof_count": reason_counts["official_docs_as_live_proof_count"],
            "live_cloud_remote_overclaim_count": reason_counts["live_cloud_remote_overclaim_count"],
            "goal_improvement_without_raw_evidence_count": reason_counts["goal_improvement_without_raw_evidence_count"],
            "control_plane_overclaim_count": reason_counts["control_plane_overclaim_count"],
            "automatic_github_overclaim_count": reason_counts["automatic_github_overclaim_count"],
            "retained_closeout_overclaim_count": reason_counts["retained_closeout_overclaim_count"],
            "downstream_mutation_overclaim_count": reason_counts["downstream_mutation_overclaim_count"],
            "historical_evidence_skipped_count": historical_evidence_skipped,
        },
        "evidence": evidence_join(details, limit=2),
        "reason": (
            "Codex native runtime readiness material lacks runtime evidence fields or overclaims cloud/remote/control-plane authority"
            if offenders
            else "Codex native runtime readiness evidence is complete or absent"
        ),
    }


DEEP_RESEARCH_CORPUS_EXPLAINER_PATTERN = re.compile(
    r"\b(AS-46|Deep Research Source-Intelligence Native Corpus Evidence Gap)\b"
    r".{0,180}\b(detects|detector|signature|triggers?)\b",
    re.IGNORECASE | re.DOTALL,
)
DEEP_RESEARCH_CORPUS_SURFACE_PATTERN = re.compile(
    r"\b(DEEP_RESEARCH_SOURCE_INTELLIGENCE_NATIVE_CORPUS|Deep Research/source[- ]intelligence native corpus|"
    r"Deep Research external intelligence native corpus|Deep Research source[- ]intelligence|"
    r"manual Deep Research sidecar|deep_research_api_disposition|source[- ]intelligence native corpus)\b",
    re.IGNORECASE,
)
DEEP_RESEARCH_CORPUS_SURFACE_NEGATION_PATTERN = re.compile(
    r"\b(no|not|without|absent|lacks?|missing|omit(?:s|ted)?)\b.{0,90}"
    r"\b(DEEP_RESEARCH_SOURCE_INTELLIGENCE_NATIVE_CORPUS|Deep Research/source[- ]intelligence native corpus|"
    r"Deep Research external intelligence native corpus|Deep Research source[- ]intelligence|"
    r"manual Deep Research sidecar|deep_research_api_disposition|source[- ]intelligence native corpus)\b",
    re.IGNORECASE,
)
DEEP_RESEARCH_CORPUS_FIELD_PATTERNS: tuple[tuple[str, re.Pattern[str]], ...] = (
    ("missing_native_contract_token", re.compile(r"\bDEEP_RESEARCH_SOURCE_INTELLIGENCE_NATIVE_CORPUS\b", re.IGNORECASE)),
    ("missing_source_insight_packet", re.compile(r"\bSOURCE_INSIGHT_PACKET\b", re.IGNORECASE)),
    ("missing_source_count_or_corpus_scope", re.compile(r"\b(19[- ]source|19 exact|19 operator|source_count|source count|corpus source count|sources=19|19-link|19 link)\b", re.IGNORECASE)),
    ("missing_source_ids", re.compile(r"\b(source_id|source IDs?|normalized source)\b", re.IGNORECASE)),
    ("missing_access_order", re.compile(r"\b(public/no-auth|public no-auth|no-auth first|exact[- ]url authenticated|authenticated exact[- ]url|approved X URL|approved URL)\b", re.IGNORECASE)),
    ("missing_manual_sidecar_disposition", re.compile(r"\b(manual Deep Research sidecar|manual sidecar|deep_research_api_disposition|rescoped_failed_not_authorized)\b", re.IGNORECASE)),
    ("missing_equal_insight_disposition", re.compile(r"\b(equal[-_ ]insight|insight/no-insight|insight_disposition|no_insight|contradiction|inaccessible)\b", re.IGNORECASE)),
    ("missing_claim_effect", re.compile(r"\b(claim_effect|claim effect|claim/effect|claim routing)\b", re.IGNORECASE)),
    ("missing_evidence_tier", re.compile(r"\b(evidence_tier|evidence tier|proof tier|source tier)\b", re.IGNORECASE)),
    ("missing_owner_no_action", re.compile(r"\b(owner/no-action|owner no-action|owner_surface|owner[-_ ]surface|explicit_no_action|no_action_reason|owner routing|owner/no action)\b", re.IGNORECASE)),
    ("missing_bounded_non_claims", re.compile(r"\b(bounded_non_claims|bounded non-claims|non-claims|forbidden mode|non-claim)\b", re.IGNORECASE)),
    ("missing_github_truth", re.compile(r"\b(GitHub issue/PR/check/merge|issue/PR/check/merge|PR/check/merge|GitHub truth|CI / check|CI/check|merge truth)\b", re.IGNORECASE)),
    ("missing_next_owner_action", re.compile(r"\b(next_owner_action|next owner action|next active track|owner-surface action|owner surface action)\b", re.IGNORECASE)),
)
DEEP_RESEARCH_CORPUS_CONTRACT_PATH_HINTS = (
    "deep-research-source-intelligence-native-corpus-contract.md",
    "deep-research-source-intelligence-native-corpus.md",
    "detect-as-deep-research-source-intelligence-native-corpus-gap.sh",
    "test-deep-research-source-intelligence-native-corpus-gap.sh",
)
DEEP_RESEARCH_LIVE_API_OVERCLAIM_PATTERN = re.compile(
    r"\b(Deep Research API|deep research api|Deep Research)\b.{0,120}\b(live run|ran|run|execut(?:ed|ion)|called|proof|validated?|verified?)\b|"
    r"\b(live Deep Research|live API)\b.{0,120}\b(run|proof|validated?|verified?)\b",
    re.IGNORECASE,
)
DEEP_RESEARCH_CLOUD_REMOTE_OVERCLAIM_PATTERN = re.compile(
    r"\b(Codex Cloud|cloud runtime|remote execution|remote runtime|cloud pilot|remote pilot|live cloud|live remote)\b"
    r".{0,120}\b(execut(?:ed|ion)|ran|run|pilot|proof|validated?|verified?)\b",
    re.IGNORECASE,
)
DEEP_RESEARCH_CRAWLER_REGISTRY_OVERCLAIM_PATTERN = re.compile(
    r"\b(crawler|watcher|source registry|source[- ]registry|background ingestion|background research automation|"
    r"controller|scheduler|queue|daemon|registry)\b",
    re.IGNORECASE,
)
DEEP_RESEARCH_RAW_AUTH_RETENTION_PATTERN = re.compile(
    r"\b(raw authenticated DOM|authenticated DOM|raw DOM|HTML screenshots?|screenshots?|account context|cookies|local storage|browser profile)\b"
    r".{0,120}\b(retain(?:ed|s|ing)?|commit(?:ted|s|ting)?|store(?:d|s|ing)?|preserve(?:d|s|ing)?)\b|"
    r"\b(retain(?:ed|s|ing)?|commit(?:ted|s|ting)?|store(?:d|s|ing)?|preserve(?:d|s|ing)?)\b"
    r".{0,120}\b(raw authenticated DOM|authenticated DOM|raw DOM|HTML screenshots?|screenshots?|account context|cookies|local storage|browser profile)\b",
    re.IGNORECASE,
)
DEEP_RESEARCH_AUTOMATIC_GITHUB_OVERCLAIM_PATTERN = re.compile(
    r"\b(automatic issue creation|automatic PR creation|automatic pull request creation|automatic GitHub mutation|auto[- ]?merge|automatic merge)\b",
    re.IGNORECASE,
)
DEEP_RESEARCH_RETAINED_CLOSEOUT_OVERCLAIM_PATTERN = re.compile(
    r"\b(retained closeout package|retained closeout truth|local closeout truth|completion manifest|handoff closeout)\b",
    re.IGNORECASE,
)
DEEP_RESEARCH_DOWNSTREAM_MUTATION_OVERCLAIM_PATTERN = re.compile(
    r"\b(downstream mutation|mutate downstream|repo-upgrade-advisor mutation|repo-optimizer mutation|repo-auditor mutation|core-five mutation)\b",
    re.IGNORECASE,
)
DEEP_RESEARCH_NEGATION_PATTERN = re.compile(
    r"\b(no|not|never|does not|do not|without|forbid(?:s|den)?|forbidden|non[- ]claim|boundary|bounded|"
    r"context only|capability context|no live|manual only|manual sidecar|raw evidence required|read-only|untouched)\b",
    re.IGNORECASE,
)


def is_deep_research_corpus_explainer(path: str, text: str) -> bool:
    lowered = path.lower()
    if any(hint in lowered for hint in DEEP_RESEARCH_CORPUS_CONTRACT_PATH_HINTS):
        return True
    return DEEP_RESEARCH_CORPUS_EXPLAINER_PATTERN.search(text) is not None


def has_deep_research_corpus_surface(text: str) -> bool:
    for line in text.splitlines():
        if not DEEP_RESEARCH_CORPUS_SURFACE_PATTERN.search(line):
            continue
        if DEEP_RESEARCH_CORPUS_SURFACE_NEGATION_PATTERN.search(line):
            continue
        return True
    return False


def deep_research_field_missing_or_vague(text: str, pattern: re.Pattern[str]) -> tuple[bool, bool]:
    positive_lines = []
    for line in text.splitlines():
        match = pattern.search(line)
        if not match:
            continue
        prefix = line[max(0, match.start() - 90):match.start()]
        if CODEX_RUNTIME_NEGATIVE_FIELD_PATTERN.search(prefix):
            continue
        positive_lines.append(line)
    if not positive_lines:
        return True, False
    if all(CODEX_RUNTIME_VAGUE_VALUE_PATTERN.search(line) for line in positive_lines):
        return False, True
    return False, False


def deep_research_line_overclaim(text: str, pattern: re.Pattern[str]) -> bool:
    prohibition_context = 0
    for line in text.splitlines():
        if re.search(r"\b(bounded_non_claims|bounded non-claims|forbidden mode|non-claims|bounded nonclaims)\b", line, re.IGNORECASE):
            is_non_claims_header = re.search(
                r"^\s*(?:#{1,6}\s*)?(?:bounded[_ -]non-claims|non-claims|bounded nonclaims)\s*:?\s*$",
                line,
                re.IGNORECASE,
            )
            has_negation = DEEP_RESEARCH_NEGATION_PATTERN.search(line) is not None
            is_vague_nonclaim = CODEX_RUNTIME_VAGUE_VALUE_PATTERN.search(line) is not None
            prohibition_context = 4 if (not is_vague_nonclaim and (has_negation or is_non_claims_header)) else 0
        if not pattern.search(line):
            if prohibition_context and line.strip():
                prohibition_context -= 1
            continue
        if prohibition_context or DEEP_RESEARCH_NEGATION_PATTERN.search(line):
            if prohibition_context and line.strip():
                prohibition_context -= 1
            continue
        return True
    return False


def deep_research_source_intelligence_native_corpus_gap(texts: dict[str, str]) -> dict[str, Any]:
    offenders: list[str] = []
    grounded: list[str] = []
    reason_counts: Counter[str] = Counter()
    historical_evidence_skipped = 0

    for path, text in owner_evidence_texts(texts).items():
        if path.startswith(HISTORICAL_CLOSURE_ARTIFACT_PREFIXES):
            historical_evidence_skipped += 1
            continue
        if is_work_management_signature_explainer(path, text):
            grounded.append(path)
            continue
        if is_deep_research_corpus_explainer(path, text):
            grounded.append(path)
            continue
        if not path.endswith((".md", ".txt", ".json", ".jsonl", ".yml", ".yaml")):
            continue
        if not has_deep_research_corpus_surface(text):
            continue

        reasons: list[str] = []
        for reason, pattern in DEEP_RESEARCH_CORPUS_FIELD_PATTERNS:
            missing, vague = deep_research_field_missing_or_vague(text, pattern)
            if missing:
                reasons.append(reason)
                reason_counts[reason] += 1
            elif vague:
                reasons.append(f"vague_{reason.removeprefix('missing_')}")
                reason_counts["vague_field"] += 1

        overclaim_patterns: tuple[tuple[str, re.Pattern[str]], ...] = (
            ("live_deep_research_api_overclaim_count", DEEP_RESEARCH_LIVE_API_OVERCLAIM_PATTERN),
            ("live_cloud_remote_overclaim_count", DEEP_RESEARCH_CLOUD_REMOTE_OVERCLAIM_PATTERN),
            ("crawler_registry_overclaim_count", DEEP_RESEARCH_CRAWLER_REGISTRY_OVERCLAIM_PATTERN),
            ("raw_authenticated_retention_count", DEEP_RESEARCH_RAW_AUTH_RETENTION_PATTERN),
            ("automatic_github_overclaim_count", DEEP_RESEARCH_AUTOMATIC_GITHUB_OVERCLAIM_PATTERN),
            ("retained_closeout_overclaim_count", DEEP_RESEARCH_RETAINED_CLOSEOUT_OVERCLAIM_PATTERN),
            ("downstream_mutation_overclaim_count", DEEP_RESEARCH_DOWNSTREAM_MUTATION_OVERCLAIM_PATTERN),
        )
        for reason, pattern in overclaim_patterns:
            if deep_research_line_overclaim(text, pattern):
                reasons.append(reason.removesuffix("_count"))
                reason_counts[reason] += 1

        if reasons:
            offenders.append(f"{path}=>{';'.join(reasons[:6])}")
        else:
            grounded.append(path)

    details = [
        f"deep_research_source_intelligence_native_corpus_gap=>{';'.join(offenders[:4]) or 'none'}",
        f"deep_research_source_intelligence_native_corpus_grounded=>{','.join(sorted(set(grounded))[:4]) or 'none'}",
    ]
    return {
        "fired": bool(offenders),
        "signals": {
            "deep_research_source_intelligence_native_corpus_gap_count": len(offenders),
            "deep_research_source_intelligence_native_corpus_grounded_count": len(set(grounded)),
            "missing_native_contract_token_count": reason_counts["missing_native_contract_token"],
            "missing_source_insight_packet_count": reason_counts["missing_source_insight_packet"],
            "missing_source_count_or_corpus_scope_count": reason_counts["missing_source_count_or_corpus_scope"],
            "missing_source_ids_count": reason_counts["missing_source_ids"],
            "missing_access_order_count": reason_counts["missing_access_order"],
            "missing_manual_sidecar_disposition_count": reason_counts["missing_manual_sidecar_disposition"],
            "missing_equal_insight_disposition_count": reason_counts["missing_equal_insight_disposition"],
            "missing_claim_effect_count": reason_counts["missing_claim_effect"],
            "missing_evidence_tier_count": reason_counts["missing_evidence_tier"],
            "missing_owner_no_action_count": reason_counts["missing_owner_no_action"],
            "missing_bounded_non_claims_count": reason_counts["missing_bounded_non_claims"],
            "missing_github_truth_count": reason_counts["missing_github_truth"],
            "missing_next_owner_action_count": reason_counts["missing_next_owner_action"],
            "vague_field_count": reason_counts["vague_field"],
            "live_deep_research_api_overclaim_count": reason_counts["live_deep_research_api_overclaim_count"],
            "live_cloud_remote_overclaim_count": reason_counts["live_cloud_remote_overclaim_count"],
            "crawler_registry_overclaim_count": reason_counts["crawler_registry_overclaim_count"],
            "raw_authenticated_retention_count": reason_counts["raw_authenticated_retention_count"],
            "automatic_github_overclaim_count": reason_counts["automatic_github_overclaim_count"],
            "retained_closeout_overclaim_count": reason_counts["retained_closeout_overclaim_count"],
            "downstream_mutation_overclaim_count": reason_counts["downstream_mutation_overclaim_count"],
            "historical_evidence_skipped_count": historical_evidence_skipped,
        },
        "evidence": evidence_join(details, limit=2),
        "reason": (
            "Deep Research source-intelligence native corpus material lacks corpus evidence fields or overclaims API/cloud/control-plane authority"
            if offenders
            else "Deep Research source-intelligence native corpus evidence is complete or absent"
        ),
    }


INTEGRATED_NATIVE_ACCEPTANCE_EXPLAINER_PATTERN = re.compile(
    r"\b(AS-47|Integrated Native Capability Acceptance Evidence Gap)\b"
    r".{0,180}\b(detects|detector|signature|triggers?)\b",
    re.IGNORECASE | re.DOTALL,
)
INTEGRATED_NATIVE_ACCEPTANCE_SURFACE_PATTERN = re.compile(
    r"\b(INTEGRATED_NATIVE_CAPABILITY_ACCEPTANCE|Integrated Native Capability Acceptance|"
    r"codex_cloud_proof_disposition|codex_remote_proof_disposition|"
    r"external_intelligence_sidecar_disposition|accepted_ready_no_diff|"
    r"deferred_not_validated|failed_prompt_generation_deferred_outside_arc5)\b",
    re.IGNORECASE,
)
INTEGRATED_NATIVE_ACCEPTANCE_SURFACE_NEGATION_PATTERN = re.compile(
    r"\b(no|not|without|absent|lacks?|missing|omit(?:s|ted)?)\b.{0,90}"
    r"\b(INTEGRATED_NATIVE_CAPABILITY_ACCEPTANCE|Integrated Native Capability Acceptance|integrated acceptance)\b",
    re.IGNORECASE,
)
INTEGRATED_NATIVE_VAGUE_VALUE_PATTERN = re.compile(
    r"[:=]\s*(?:\"?\s*)?(?:(?:tbd|todo|unknown|unclear|maybe|later|none|n/a|null|to be decided)\b|"
    r"(?:missing|absent|omitted)\s*\.?\s*$)",
    re.IGNORECASE,
)
INTEGRATED_NATIVE_NEGATIVE_FIELD_PATTERN = re.compile(
    r"\b(no|not|without|absent|lacks?|missing|omit(?:s|ted)?)\b",
    re.IGNORECASE,
)
INTEGRATED_NATIVE_NEGATION_PATTERN = re.compile(
    r"\b(no|not|never|does not|do not|without|forbid(?:s|den)?|forbidden|non[- ]claim|boundary|bounded|"
    r"context only|capability context|no live|raw evidence required|read-only|untouched|deferred|outside Arc 5)\b",
    re.IGNORECASE,
)
INTEGRATED_NATIVE_ACCEPTANCE_FIELD_PATTERNS: tuple[tuple[str, re.Pattern[str]], ...] = (
    ("missing_integrated_acceptance_token", re.compile(r"\bINTEGRATED_NATIVE_CAPABILITY_ACCEPTANCE\b", re.IGNORECASE)),
    ("missing_cloud_proof_disposition", re.compile(r"\bcodex_cloud_proof_disposition=accepted_ready_no_diff\b|\baccepted_ready_no_diff\b", re.IGNORECASE)),
    ("missing_cloud_task_evidence", re.compile(r"\b(task_id|Cloud task|Codex Cloud task|hosted_repo|hosted repo)\b", re.IGNORECASE)),
    ("missing_cloud_no_diff_evidence", re.compile(r"\b(no diff|files_changed=0|files changed[:= ]+0|zero changed files|clean git status|clean status before and after)\b", re.IGNORECASE)),
    ("missing_remote_deferred_disposition", re.compile(r"\bcodex_remote_proof_disposition=deferred_not_validated\b|\bdeferred_not_validated\b", re.IGNORECASE)),
    ("missing_sidecar_failed_disposition", re.compile(r"\bexternal_intelligence_sidecar_disposition=failed_prompt_generation_deferred_outside_arc5\b|\bfailed_prompt_generation_deferred_outside_arc5\b", re.IGNORECASE)),
    ("missing_github_truth", re.compile(r"\b(GitHub issue/PR/check/merge|issue/PR/check/merge|PR/check/merge|GitHub truth|merge truth|CI / check|CI/check|required check)\b", re.IGNORECASE)),
    ("missing_arc_gate_matrix", re.compile(r"\b(arc_gate_matrix|Arc gate matrix)\b", re.IGNORECASE)),
    ("missing_promotion_gate", re.compile(r"\b(promotion_gate|promotion gate|proof_gate|proof gate)\b", re.IGNORECASE)),
    ("missing_demotion_rejection_trigger", re.compile(r"\b(demotion_rejection_trigger|demotion/rejection trigger|demotion trigger|rejection trigger)\b", re.IGNORECASE)),
    ("missing_kill_switch", re.compile(r"\b(kill_switch|kill switch)\b", re.IGNORECASE)),
    ("missing_bounded_non_claims", re.compile(r"\b(bounded_non_claims|bounded non-claims|bounded nonclaims|non-claims|forbidden mode|non-claim)\b", re.IGNORECASE)),
    ("missing_next_owner_action", re.compile(r"\b(next_owner_action|next owner action|next active track|owner-surface action|owner surface action)\b", re.IGNORECASE)),
)
INTEGRATED_NATIVE_ACCEPTANCE_CONTRACT_PATH_HINTS = (
    "integrated-native-capability-acceptance-contract.md",
    "integrated-native-capability-acceptance.md",
    "detect-as-integrated-native-capability-acceptance-gap.sh",
    "test-integrated-native-capability-acceptance-gap.sh",
)
INTEGRATED_NATIVE_DOCS_AS_PROOF_PATTERN = re.compile(
    r"\b(official docs|official Codex|Codex docs|OpenAI docs|manual)\b"
    r".{0,140}\b(proves?|proof|accepted|validated?|verified?)\b"
    r".{0,140}\b(INTEGRATED_NATIVE_CAPABILITY_ACCEPTANCE|Codex Cloud|remote|sidecar)\b|"
    r"\b(INTEGRATED_NATIVE_CAPABILITY_ACCEPTANCE|Codex Cloud|remote|sidecar)\b"
    r".{0,140}\b(proves?|proof|accepted|validated?|verified?)\b"
    r".{0,140}\b(official docs|official Codex|Codex docs|OpenAI docs|manual)\b",
    re.IGNORECASE,
)
INTEGRATED_NATIVE_REMOTE_ACCEPTANCE_OVERCLAIM_PATTERN = re.compile(
    r"\b(Codex remote|remote proof|remote execution|remote session|remote pilot|live remote)\b"
    r".{0,120}\b(accepted|proven|proof|validated?|verified?|ran|execut(?:ed|ion))\b|"
    r"\b(codex_remote_proof_disposition)\s*[:=]\s*(accepted|raw_evidence_proven|validated|proven)\b",
    re.IGNORECASE,
)
INTEGRATED_NATIVE_SIDECAR_ACCEPTANCE_OVERCLAIM_PATTERN = re.compile(
    r"\b(sidecar|Deep Research pasteback|external intelligence)\b"
    r".{0,120}\b(accepted|validated?|verified?|hard[- ]accepted|proof)\b|"
    r"\bexternal_intelligence_sidecar_disposition\s*[:=]\s*(accepted|validated|pasteback_validated|raw_evidence_proven)\b",
    re.IGNORECASE,
)
INTEGRATED_NATIVE_GBRAIN_CANONICALITY_PATTERN = re.compile(
    r"\b(GBrain)\b.{0,120}\b(canonical|source of truth|authoritative memory|primary memory)\b",
    re.IGNORECASE,
)
INTEGRATED_NATIVE_HERMES_PRIMARY_PATTERN = re.compile(
    r"\b(Hermes)\b.{0,120}\b(primary owner|primary operator|owns validation|owns merge|owns campaign sync|autonomous retry)\b",
    re.IGNORECASE,
)
INTEGRATED_NATIVE_CONTROL_PLANE_PATTERN = re.compile(
    r"\b(controller|scheduler|queue|daemon|registry|retry loop|sidecar runner|background job|background worker)\b",
    re.IGNORECASE,
)
INTEGRATED_NATIVE_AUTOMATIC_GITHUB_PATTERN = re.compile(
    r"\b(automatic issue creation|automatic PR creation|automatic pull request creation|automatic GitHub mutation|auto[- ]?merge|automatic merge)\b",
    re.IGNORECASE,
)
INTEGRATED_NATIVE_RETAINED_CLOSEOUT_PATTERN = re.compile(
    r"\b(retained closeout package|retained closeout truth|local closeout truth|completion manifest|handoff closeout)\b",
    re.IGNORECASE,
)
INTEGRATED_NATIVE_DOWNSTREAM_MUTATION_PATTERN = re.compile(
    r"\b(downstream mutation|mutate downstream|repo-optimizer mutation|target mutation|core-five mutation)\b",
    re.IGNORECASE,
)


def is_integrated_native_acceptance_explainer(path: str, text: str) -> bool:
    lowered = path.lower()
    if any(hint in lowered for hint in INTEGRATED_NATIVE_ACCEPTANCE_CONTRACT_PATH_HINTS):
        return True
    return INTEGRATED_NATIVE_ACCEPTANCE_EXPLAINER_PATTERN.search(text) is not None


def has_integrated_native_acceptance_surface(text: str) -> bool:
    for line in text.splitlines():
        if not INTEGRATED_NATIVE_ACCEPTANCE_SURFACE_PATTERN.search(line):
            continue
        if INTEGRATED_NATIVE_ACCEPTANCE_SURFACE_NEGATION_PATTERN.search(line):
            continue
        return True
    return False


def integrated_native_field_missing_or_vague(text: str, pattern: re.Pattern[str]) -> tuple[bool, bool]:
    positive_lines = []
    for line in text.splitlines():
        match = pattern.search(line)
        if not match:
            continue
        prefix = line[max(0, match.start() - 90):match.start()]
        if INTEGRATED_NATIVE_NEGATIVE_FIELD_PATTERN.search(prefix):
            continue
        positive_lines.append(line)
    if not positive_lines:
        return True, False
    if all(INTEGRATED_NATIVE_VAGUE_VALUE_PATTERN.search(line) for line in positive_lines):
        return False, True
    return False, False


def integrated_native_line_overclaim(text: str, pattern: re.Pattern[str]) -> bool:
    prohibition_context = 0
    demotion_context = 0
    for line in text.splitlines():
        if re.search(r"\b(demotion_rejection_trigger|demotion/rejection trigger|demotion trigger|rejection trigger)\b", line, re.IGNORECASE):
            demotion_context = 3
        if re.search(r"\b(bounded_non_claims|bounded non-claims|forbidden mode|non-claims|bounded nonclaims)\b", line, re.IGNORECASE):
            is_non_claims_header = re.search(
                r"^\s*(?:#{1,6}\s*)?(?:bounded[_ -]non-claims|non-claims|bounded nonclaims)\s*:?\s*$",
                line,
                re.IGNORECASE,
            )
            has_negation = INTEGRATED_NATIVE_NEGATION_PATTERN.search(line) is not None
            is_vague_nonclaim = INTEGRATED_NATIVE_VAGUE_VALUE_PATTERN.search(line) is not None
            prohibition_context = 12 if (not is_vague_nonclaim and (has_negation or is_non_claims_header)) else 0
        if not pattern.search(line):
            if prohibition_context and line.strip():
                prohibition_context -= 1
            if demotion_context and line.strip():
                demotion_context -= 1
            continue
        if demotion_context or prohibition_context or INTEGRATED_NATIVE_NEGATION_PATTERN.search(line):
            if prohibition_context and line.strip():
                prohibition_context -= 1
            if demotion_context and line.strip():
                demotion_context -= 1
            continue
        return True
    return False


def integrated_native_acceptance_gap(texts: dict[str, str]) -> dict[str, Any]:
    offenders: list[str] = []
    grounded: list[str] = []
    reason_counts: Counter[str] = Counter()
    historical_evidence_skipped = 0

    for path, text in owner_evidence_texts(texts).items():
        if path.startswith(HISTORICAL_CLOSURE_ARTIFACT_PREFIXES):
            historical_evidence_skipped += 1
            continue
        if is_integrated_native_acceptance_explainer(path, text):
            grounded.append(path)
            continue
        if not path.endswith((".md", ".txt", ".json", ".jsonl", ".yml", ".yaml")):
            continue
        if not has_integrated_native_acceptance_surface(text):
            continue

        reasons: list[str] = []
        for reason, pattern in INTEGRATED_NATIVE_ACCEPTANCE_FIELD_PATTERNS:
            missing, vague = integrated_native_field_missing_or_vague(text, pattern)
            if missing:
                reasons.append(reason)
                reason_counts[reason] += 1
            elif vague:
                reasons.append(f"vague_{reason.removeprefix('missing_')}")
                reason_counts["vague_field"] += 1

        overclaim_patterns: tuple[tuple[str, re.Pattern[str]], ...] = (
            ("docs_as_proof_overclaim_count", INTEGRATED_NATIVE_DOCS_AS_PROOF_PATTERN),
            ("remote_acceptance_overclaim_count", INTEGRATED_NATIVE_REMOTE_ACCEPTANCE_OVERCLAIM_PATTERN),
            ("sidecar_acceptance_overclaim_count", INTEGRATED_NATIVE_SIDECAR_ACCEPTANCE_OVERCLAIM_PATTERN),
            ("gbrain_canonicality_overclaim_count", INTEGRATED_NATIVE_GBRAIN_CANONICALITY_PATTERN),
            ("hermes_primary_ownership_overclaim_count", INTEGRATED_NATIVE_HERMES_PRIMARY_PATTERN),
            ("control_plane_overclaim_count", INTEGRATED_NATIVE_CONTROL_PLANE_PATTERN),
            ("automatic_github_overclaim_count", INTEGRATED_NATIVE_AUTOMATIC_GITHUB_PATTERN),
            ("retained_closeout_overclaim_count", INTEGRATED_NATIVE_RETAINED_CLOSEOUT_PATTERN),
            ("downstream_mutation_overclaim_count", INTEGRATED_NATIVE_DOWNSTREAM_MUTATION_PATTERN),
        )
        for reason, pattern in overclaim_patterns:
            if integrated_native_line_overclaim(text, pattern):
                reasons.append(reason.removesuffix("_count"))
                reason_counts[reason] += 1

        if reasons:
            offenders.append(f"{path}=>{';'.join(reasons[:6])}")
        else:
            grounded.append(path)

    details = [
        f"integrated_native_capability_acceptance_gap=>{';'.join(offenders[:4]) or 'none'}",
        f"integrated_native_capability_acceptance_grounded=>{','.join(sorted(set(grounded))[:4]) or 'none'}",
    ]
    return {
        "fired": bool(offenders),
        "signals": {
            "integrated_native_capability_acceptance_gap_count": len(offenders),
            "integrated_native_capability_acceptance_grounded_count": len(set(grounded)),
            "missing_integrated_acceptance_token_count": reason_counts["missing_integrated_acceptance_token"],
            "missing_cloud_proof_disposition_count": reason_counts["missing_cloud_proof_disposition"],
            "missing_cloud_task_evidence_count": reason_counts["missing_cloud_task_evidence"],
            "missing_cloud_no_diff_evidence_count": reason_counts["missing_cloud_no_diff_evidence"],
            "missing_remote_deferred_disposition_count": reason_counts["missing_remote_deferred_disposition"],
            "missing_sidecar_failed_disposition_count": reason_counts["missing_sidecar_failed_disposition"],
            "missing_github_truth_count": reason_counts["missing_github_truth"],
            "missing_arc_gate_matrix_count": reason_counts["missing_arc_gate_matrix"],
            "missing_promotion_gate_count": reason_counts["missing_promotion_gate"],
            "missing_demotion_rejection_trigger_count": reason_counts["missing_demotion_rejection_trigger"],
            "missing_kill_switch_count": reason_counts["missing_kill_switch"],
            "missing_bounded_non_claims_count": reason_counts["missing_bounded_non_claims"],
            "missing_next_owner_action_count": reason_counts["missing_next_owner_action"],
            "vague_field_count": reason_counts["vague_field"],
            "docs_as_proof_overclaim_count": reason_counts["docs_as_proof_overclaim_count"],
            "remote_acceptance_overclaim_count": reason_counts["remote_acceptance_overclaim_count"],
            "sidecar_acceptance_overclaim_count": reason_counts["sidecar_acceptance_overclaim_count"],
            "gbrain_canonicality_overclaim_count": reason_counts["gbrain_canonicality_overclaim_count"],
            "hermes_primary_ownership_overclaim_count": reason_counts["hermes_primary_ownership_overclaim_count"],
            "control_plane_overclaim_count": reason_counts["control_plane_overclaim_count"],
            "automatic_github_overclaim_count": reason_counts["automatic_github_overclaim_count"],
            "retained_closeout_overclaim_count": reason_counts["retained_closeout_overclaim_count"],
            "downstream_mutation_overclaim_count": reason_counts["downstream_mutation_overclaim_count"],
            "historical_evidence_skipped_count": historical_evidence_skipped,
        },
        "evidence": evidence_join(details, limit=2),
        "reason": (
            "Integrated native capability acceptance material lacks required fields or overclaims unproven authority"
            if offenders
            else "Integrated native capability acceptance evidence is complete or absent"
        ),
    }


STANDALONE_SIDECAR_EXPLAINER_PATTERN = re.compile(
    r"\b(AS-48|Standalone External Intelligence Sidecar Gap)\b"
    r".{0,180}\b(detects|detector|signature|triggers?|fires)\b",
    re.IGNORECASE | re.DOTALL,
)
STANDALONE_SIDECAR_SURFACE_PATTERN = re.compile(
    r"\b(STANDALONE_EXTERNAL_INTELLIGENCE_SIDECAR|standalone external[- ]intelligence sidecar|"
    r"standalone sidecar|sidecar prompt|ChatGPT Pro sidecar|Deep Research sidecar|"
    r"Prompt A/B|Prompt A|Prompt B|BROAD_STANDALONE_SIDECAR_ACCEPTANCE|"
    r"broad standalone sidecar acceptance|broad sidecar acceptance)\b",
    re.IGNORECASE,
)
STANDALONE_SIDECAR_SURFACE_NEGATION_PATTERN = re.compile(
    r"\b(no|not|without|absent|lacks?|missing|omit(?:s|ted)?)\b.{0,90}"
    r"\b(standalone sidecar|sidecar prompt|Prompt A|Prompt B)\b",
    re.IGNORECASE,
)
STANDALONE_SIDECAR_VAGUE_VALUE_PATTERN = re.compile(
    r"[:=]\s*(?:\"?\s*)?(?:(?:tbd|todo|unknown|unclear|maybe|later|none|n/a|null|to be decided)\b|"
    r"(?:missing|absent|omitted)\s*\.?\s*$)",
    re.IGNORECASE,
)
STANDALONE_SIDECAR_NEGATION_PATTERN = re.compile(
    r"\b(no|not|never|does not|do not|without|forbid(?:s|den)?|forbidden|non[- ]claim|boundary|bounded|"
    r"optional|non-load-bearing|advisory|no live|doesn't|cannot|can't|no access)\b",
    re.IGNORECASE,
)
STANDALONE_SIDECAR_FIELD_PATTERNS: tuple[tuple[str, re.Pattern[str]], ...] = (
    ("missing_standalone_sidecar_token", re.compile(r"\bSTANDALONE_EXTERNAL_INTELLIGENCE_SIDECAR\b", re.IGNORECASE)),
    ("missing_access_boundary", re.compile(r"\b(no local filesystem access|do not have local filesystem access|do not have local files?|no local files?|no private repository access|private repository access|GitHub issue access|prior chat access|workspace context)\b", re.IGNORECASE)),
    ("missing_embedded_context", re.compile(r"\b(embedded context|all required context|full context|standalone context|context embedded)\b", re.IGNORECASE)),
    ("missing_url_boundary", re.compile(r"\b(optional and non-load-bearing|optional non-load-bearing|public URLs?.{0,80}non-load-bearing)\b", re.IGNORECASE)),
    ("missing_definitions", re.compile(r"\b(Definitions And Glossary|definitions|glossary|define(?:d)? jargon|acronyms defined)\b", re.IGNORECASE)),
    ("missing_response_shape", re.compile(r"\b(response shape|output shape|return these sections|source-ledger response shape)\b", re.IGNORECASE)),
    ("missing_advisory_boundary", re.compile(r"\b(sidecar output is advisory|advisory only|not closure truth|does not close GitHub issues|does not approve pull requests)\b", re.IGNORECASE)),
)
STANDALONE_SIDECAR_CONTRACT_PATH_HINTS = (
    "sidecar-prompt-ab-response-shaped-contract.md",
    "sidecar-prompt-ab-response-shaped.md",
    "detect-as-standalone-external-intelligence-sidecar-gap.sh",
    "test-standalone-external-intelligence-sidecar-gap.sh",
)
STANDALONE_SIDECAR_LOCAL_PRIVATE_GITHUB_PATTERN = re.compile(
    r"\b(read|open|inspect|clone|view|check)\s+(?:the\s+)?(?:local\s+)?"
    r"(repo|repository|GitHub issue|GitHub PR|pull request|file|path|workspace)\b|"
    r"(?<!\w)/(?:Users|tmp|workspace|var|private|home)/[^\s)]+",
    re.IGNORECASE,
)
STANDALONE_SIDECAR_UNDEFINED_TERMS_PATTERN = re.compile(
    r"\b(BMA|GBrain|Hermes|AS-48|Prompt A|Prompt B|Deep Research|repo-star)\b",
    re.IGNORECASE,
)
STANDALONE_SIDECAR_PROMPT_LAYER_PATTERN = re.compile(
    r"\b(review this prompt|critique this prompt|assess this prompt|improve this prompt|"
    r"copy and paste|paste this|paste the following|here is the prompt|below is the prompt|operator note)\b",
    re.IGNORECASE,
)
STANDALONE_SIDECAR_AUTHORITY_PATTERN = re.compile(
    r"\b(sidecar|ChatGPT Pro|Deep Research|external intelligence)\b.{0,120}"
    r"\b(closes? GitHub issues?|approves? PRs?|approves? pull requests?|closure truth|task authority|campaign authority|merge authority)\b|"
    r"\b(closure truth|task authority|campaign authority|merge authority)\b.{0,120}"
    r"\b(sidecar|ChatGPT Pro|Deep Research|external intelligence)\b",
    re.IGNORECASE,
)
STANDALONE_SIDECAR_CONTROL_PLANE_PATTERN = re.compile(
    r"\b(controller|scheduler|queue|daemon|registry|retry loop|sidecar runner|background job|background worker)\b",
    re.IGNORECASE,
)
STANDALONE_SIDECAR_AUTOMATIC_GITHUB_PATTERN = re.compile(
    r"\b(automatic issue creation|automatic PR creation|automatic pull request creation|automatic GitHub mutation|"
    r"creates? GitHub issues? automatically|auto[- ]?merges?|automatic merge)\b",
    re.IGNORECASE,
)
STANDALONE_SIDECAR_BROAD_ACCEPTANCE_PATTERN = re.compile(
    r"\b(BROAD_STANDALONE_SIDECAR_ACCEPTANCE|broad standalone sidecar acceptance|broad sidecar acceptance)\b",
    re.IGNORECASE,
)
STANDALONE_SIDECAR_BROAD_REQUIRED_PATTERNS: tuple[tuple[str, re.Pattern[str]], ...] = (
    (
        "missing_broad_proxy_battery",
        re.compile(
            r"\b(8/8|eight of eight|accepted_proxy_trials|all\s+\d+\s+(?:accepted\s+)?trials)\b"
            r".{0,120}\b(Opus|proxy|battery|bundle[- ]only)\b|"
            r"\b(Opus|proxy|battery|bundle[- ]only)\b.{0,120}"
            r"\b(8/8|eight of eight|accepted_proxy_trials|all\s+\d+\s+(?:accepted\s+)?trials)\b",
            re.IGNORECASE | re.DOTALL,
        ),
    ),
    (
        "missing_redteam_regression",
        re.compile(r"\b(red[- ]team|redteam|boundary regression)\b.{0,120}\b(fail(?:ed|s)? as expected|validation|regression)\b", re.IGNORECASE | re.DOTALL),
    ),
    (
        "missing_local_aware_critique",
        re.compile(r"\b(local[- ]aware critique|critique pass)\b.{0,160}\b(no unresolved (?:CRITICAL|HIGH)|no unresolved CRITICAL or HIGH)\b", re.IGNORECASE | re.DOTALL),
    ),
    (
        "missing_final_manual_deep_research_transport",
        re.compile(r"\b(final manual Deep Research|manual Deep Research transport trial|manual Deep Research pasteback)\b", re.IGNORECASE),
    ),
    (
        "missing_deep_research_api_nonclaim",
        re.compile(r"\b(no|not|without|non[- ]claim|does not claim)\b.{0,100}\bDeep Research API\b|\bDeep Research API\b.{0,100}\b(no|not|without|non[- ]claim|not validated|not authorized)\b", re.IGNORECASE),
    ),
    (
        "missing_authenticated_capture_nonclaim",
        re.compile(r"\b(no|not|without|non[- ]claim|does not claim)\b.{0,120}\b(authenticated[- ]source capture|authenticated capture)\b|\b(authenticated[- ]source capture|authenticated capture)\b.{0,120}\b(no|not|without|non[- ]claim|not validated|not authorized)\b", re.IGNORECASE),
    ),
    (
        "missing_sidecar_closure_truth_nonclaim",
        re.compile(r"\b(no|not|without|non[- ]claim|does not claim)\b.{0,120}\b(sidecar closure truth|sidecar output.*closure truth)\b|\b(sidecar closure truth|sidecar output.*closure truth)\b.{0,120}\b(no|not|without|non[- ]claim|not validated|not authorized|never)\b", re.IGNORECASE),
    ),
)
STANDALONE_SIDECAR_SOURCE_LEDGER_V2_PATTERN = re.compile(
    r"\b(DEEP_RESEARCH_SOURCE_LEDGER_V2_ADOPTION|source[- ]ledger v2|source[- ]ledger-v2)\b",
    re.IGNORECASE,
)
STANDALONE_SIDECAR_SOURCE_LEDGER_V2_FIELD_PATTERNS: tuple[tuple[str, re.Pattern[str]], ...] = (
    ("missing_consulted_on_date", re.compile(r"\b(consulted[-_ ]on date|consulted_on_date)\b", re.IGNORECASE)),
    ("missing_exclusion_rationale", re.compile(r"\b(exclusion rationale|exclusion_rationale)\b", re.IGNORECASE)),
    ("missing_recommendation_effect", re.compile(r"\b(recommendation effect|recommendation_effect)\b", re.IGNORECASE)),
)
STANDALONE_SIDECAR_DEEP_RESEARCH_API_OVERCLAIM_PATTERN = re.compile(
    r"\bDeep Research API\b.{0,120}\b(accepted|validated|proved|proven|proof|live|ran|executed)\b|"
    r"\b(accepted|validated|proved|proven|proof|live|ran|executed)\b.{0,120}\bDeep Research API\b",
    re.IGNORECASE,
)
STANDALONE_SIDECAR_AUTH_CAPTURE_OVERCLAIM_PATTERN = re.compile(
    r"\b(authenticated[- ]source capture|authenticated capture)\b.{0,120}\b(accepted|validated|proved|proven|proof|live)\b|"
    r"\b(accepted|validated|proved|proven|proof|live)\b.{0,120}\b(authenticated[- ]source capture|authenticated capture)\b",
    re.IGNORECASE,
)
STANDALONE_SIDECAR_LOCAL_AWARE_AS_PROOF_PATTERN = re.compile(
    r"\blocal[- ]aware critique\b.{0,160}\b(standalone proof|standalone sidecar proof|proves? standalone|acceptance proof)\b|"
    r"\b(standalone proof|standalone sidecar proof|proves? standalone|acceptance proof)\b.{0,160}\blocal[- ]aware critique\b",
    re.IGNORECASE,
)
STANDALONE_SIDECAR_SOURCE_CONTROL_PLANE_PATTERN = re.compile(
    r"\b(source registry|source crawler|crawler|watcher|automatic ingestion)\b",
    re.IGNORECASE,
)


def is_standalone_sidecar_explainer(path: str, text: str) -> bool:
    lowered = path.lower()
    if any(hint in lowered for hint in STANDALONE_SIDECAR_CONTRACT_PATH_HINTS):
        return True
    return STANDALONE_SIDECAR_EXPLAINER_PATTERN.search(text) is not None


def is_source_intelligence_corpus_evidence(path: str, text: str) -> bool:
    lowered = path.lower()
    if "prompt" in lowered or "sidecar" in lowered:
        return False
    if not ("corpus" in lowered or "source-intelligence" in lowered):
        return False
    return (
        re.search(r"\bDEEP_RESEARCH_SOURCE_INTELLIGENCE_NATIVE_CORPUS\b", text, re.IGNORECASE)
        and re.search(r"\bSOURCE_INSIGHT_PACKET\b", text, re.IGNORECASE)
    )


def has_standalone_sidecar_surface(text: str) -> bool:
    for line in text.splitlines():
        if not STANDALONE_SIDECAR_SURFACE_PATTERN.search(line):
            continue
        if STANDALONE_SIDECAR_SURFACE_NEGATION_PATTERN.search(line):
            continue
        return True
    return False


def standalone_sidecar_field_missing_or_vague(text: str, pattern: re.Pattern[str]) -> tuple[bool, bool]:
    positive_lines = []
    for line in text.splitlines():
        match = pattern.search(line)
        if not match:
            continue
        prefix = line[max(0, match.start() - 90):match.start()]
        if re.search(r"\b(no|not|without|absent|lacks?|missing|omit(?:s|ted)?)\b", prefix, re.IGNORECASE):
            continue
        positive_lines.append(line)
    if not positive_lines:
        return True, False
    if all(STANDALONE_SIDECAR_VAGUE_VALUE_PATTERN.search(line) for line in positive_lines):
        return False, True
    return False, False


def standalone_sidecar_line_overclaim(text: str, pattern: re.Pattern[str]) -> bool:
    prohibition_context = 0
    for line in text.splitlines():
        if re.search(r"\b(bounded_non_claims|bounded non-claims|forbidden mode|non-claims|boundary)\b", line, re.IGNORECASE):
            is_boundary_header = re.search(r"^\s*(?:#{1,6}\s*)?(?:boundary|bounded[_ -]non-claims|non-claims)\s*:?\s*$", line, re.IGNORECASE)
            has_negation = STANDALONE_SIDECAR_NEGATION_PATTERN.search(line) is not None
            is_vague = STANDALONE_SIDECAR_VAGUE_VALUE_PATTERN.search(line) is not None
            prohibition_context = 12 if (not is_vague and (has_negation or is_boundary_header)) else 0
        if not pattern.search(line):
            if prohibition_context and line.strip():
                prohibition_context -= 1
            continue
        if prohibition_context or STANDALONE_SIDECAR_NEGATION_PATTERN.search(line):
            if prohibition_context and line.strip():
                prohibition_context -= 1
            continue
        return True
    return False


def standalone_external_intelligence_sidecar_gap(texts: dict[str, str]) -> dict[str, Any]:
    offenders: list[str] = []
    grounded: list[str] = []
    reason_counts: Counter[str] = Counter()
    historical_evidence_skipped = 0

    for path, text in owner_evidence_texts(texts).items():
        if path.startswith(HISTORICAL_CLOSURE_ARTIFACT_PREFIXES):
            historical_evidence_skipped += 1
            continue
        if is_standalone_sidecar_explainer(path, text):
            grounded.append(path)
            continue
        if is_source_intelligence_corpus_evidence(path, text):
            grounded.append(path)
            continue
        if not path.endswith((".md", ".txt", ".json", ".jsonl", ".yml", ".yaml")):
            continue
        if not has_standalone_sidecar_surface(text):
            continue

        reasons: list[str] = []
        for reason, pattern in STANDALONE_SIDECAR_FIELD_PATTERNS:
            missing, vague = standalone_sidecar_field_missing_or_vague(text, pattern)
            if missing:
                reasons.append(reason)
                reason_counts[reason] += 1
            elif vague:
                reasons.append(f"vague_{reason.removeprefix('missing_')}")
                reason_counts["vague_field"] += 1

        if STANDALONE_SIDECAR_UNDEFINED_TERMS_PATTERN.search(text) and not re.search(r"\b(Definitions And Glossary|definitions|glossary)\b", text, re.IGNORECASE):
            reasons.append("undefined_terms")
            reason_counts["undefined_terms_count"] += 1
        if re.search(r"\bPrompt B\b", text, re.IGNORECASE) and not (
            re.search(r"\bactual Prompt A output\b", text, re.IGNORECASE)
            and re.search(r"\b(answered context|answers? to Prompt A)\b", text, re.IGNORECASE)
        ):
            reasons.append("prompt_b_without_actual_prompt_a")
            reason_counts["prompt_b_without_actual_prompt_a_count"] += 1
        if re.search(r"\bDeep Research\b", text, re.IGNORECASE) and not (
            re.search(r"\bresearch targets?\b", text, re.IGNORECASE)
            and re.search(r"\bsource rules?\b", text, re.IGNORECASE)
            and re.search(r"\bsource[- ]ledger\b", text, re.IGNORECASE)
        ):
            reasons.append("deep_research_missing_research_shape")
            reason_counts["deep_research_missing_research_shape_count"] += 1
        if STANDALONE_SIDECAR_SOURCE_LEDGER_V2_PATTERN.search(text):
            for reason, pattern in STANDALONE_SIDECAR_SOURCE_LEDGER_V2_FIELD_PATTERNS:
                missing, vague = standalone_sidecar_field_missing_or_vague(text, pattern)
                if missing:
                    reasons.append(reason)
                    reason_counts[reason] += 1
                elif vague:
                    reasons.append(f"vague_{reason.removeprefix('missing_')}")
                    reason_counts["vague_source_ledger_v2_field"] += 1
        if STANDALONE_SIDECAR_BROAD_ACCEPTANCE_PATTERN.search(text):
            for reason, pattern in STANDALONE_SIDECAR_BROAD_REQUIRED_PATTERNS:
                missing, vague = standalone_sidecar_field_missing_or_vague(text, pattern)
                if missing:
                    reasons.append(reason)
                    reason_counts[reason] += 1
                elif vague:
                    reasons.append(f"vague_{reason.removeprefix('missing_')}")
                    reason_counts["vague_broad_acceptance_field"] += 1

        overclaim_patterns: tuple[tuple[str, re.Pattern[str]], ...] = (
            ("local_private_github_dependency_count", STANDALONE_SIDECAR_LOCAL_PRIVATE_GITHUB_PATTERN),
            ("prompt_layer_confusion_count", STANDALONE_SIDECAR_PROMPT_LAYER_PATTERN),
            ("sidecar_authority_overclaim_count", STANDALONE_SIDECAR_AUTHORITY_PATTERN),
            ("control_plane_overclaim_count", STANDALONE_SIDECAR_CONTROL_PLANE_PATTERN),
            ("source_control_plane_overclaim_count", STANDALONE_SIDECAR_SOURCE_CONTROL_PLANE_PATTERN),
            ("automatic_github_overclaim_count", STANDALONE_SIDECAR_AUTOMATIC_GITHUB_PATTERN),
            ("deep_research_api_overclaim_count", STANDALONE_SIDECAR_DEEP_RESEARCH_API_OVERCLAIM_PATTERN),
            ("authenticated_capture_overclaim_count", STANDALONE_SIDECAR_AUTH_CAPTURE_OVERCLAIM_PATTERN),
            ("local_aware_as_standalone_proof_count", STANDALONE_SIDECAR_LOCAL_AWARE_AS_PROOF_PATTERN),
        )
        for reason, pattern in overclaim_patterns:
            if standalone_sidecar_line_overclaim(text, pattern):
                reasons.append(reason.removesuffix("_count"))
                reason_counts[reason] += 1

        if reasons:
            offenders.append(f"{path}=>{';'.join(reasons[:7])}")
        else:
            grounded.append(path)

    details = [
        f"standalone_external_intelligence_sidecar_gap=>{';'.join(offenders[:4]) or 'none'}",
        f"standalone_external_intelligence_sidecar_grounded=>{','.join(sorted(set(grounded))[:4]) or 'none'}",
    ]
    return {
        "fired": bool(offenders),
        "signals": {
            "standalone_external_intelligence_sidecar_gap_count": len(offenders),
            "standalone_external_intelligence_sidecar_grounded_count": len(set(grounded)),
            "missing_standalone_sidecar_token_count": reason_counts["missing_standalone_sidecar_token"],
            "missing_access_boundary_count": reason_counts["missing_access_boundary"],
            "missing_embedded_context_count": reason_counts["missing_embedded_context"],
            "missing_url_boundary_count": reason_counts["missing_url_boundary"],
            "missing_definitions_count": reason_counts["missing_definitions"],
            "missing_response_shape_count": reason_counts["missing_response_shape"],
            "missing_advisory_boundary_count": reason_counts["missing_advisory_boundary"],
            "undefined_terms_count": reason_counts["undefined_terms_count"],
            "prompt_b_without_actual_prompt_a_count": reason_counts["prompt_b_without_actual_prompt_a_count"],
            "deep_research_missing_research_shape_count": reason_counts["deep_research_missing_research_shape_count"],
            "missing_consulted_on_date_count": reason_counts["missing_consulted_on_date"],
            "missing_exclusion_rationale_count": reason_counts["missing_exclusion_rationale"],
            "missing_recommendation_effect_count": reason_counts["missing_recommendation_effect"],
            "missing_broad_proxy_battery_count": reason_counts["missing_broad_proxy_battery"],
            "missing_redteam_regression_count": reason_counts["missing_redteam_regression"],
            "missing_local_aware_critique_count": reason_counts["missing_local_aware_critique"],
            "missing_final_manual_deep_research_transport_count": reason_counts["missing_final_manual_deep_research_transport"],
            "missing_deep_research_api_nonclaim_count": reason_counts["missing_deep_research_api_nonclaim"],
            "missing_authenticated_capture_nonclaim_count": reason_counts["missing_authenticated_capture_nonclaim"],
            "missing_sidecar_closure_truth_nonclaim_count": reason_counts["missing_sidecar_closure_truth_nonclaim"],
            "local_private_github_dependency_count": reason_counts["local_private_github_dependency_count"],
            "prompt_layer_confusion_count": reason_counts["prompt_layer_confusion_count"],
            "sidecar_authority_overclaim_count": reason_counts["sidecar_authority_overclaim_count"],
            "control_plane_overclaim_count": reason_counts["control_plane_overclaim_count"],
            "source_control_plane_overclaim_count": reason_counts["source_control_plane_overclaim_count"],
            "automatic_github_overclaim_count": reason_counts["automatic_github_overclaim_count"],
            "deep_research_api_overclaim_count": reason_counts["deep_research_api_overclaim_count"],
            "authenticated_capture_overclaim_count": reason_counts["authenticated_capture_overclaim_count"],
            "local_aware_as_standalone_proof_count": reason_counts["local_aware_as_standalone_proof_count"],
            "vague_field_count": reason_counts["vague_field"],
            "vague_source_ledger_v2_field_count": reason_counts["vague_source_ledger_v2_field"],
            "vague_broad_acceptance_field_count": reason_counts["vague_broad_acceptance_field"],
            "historical_evidence_skipped_count": historical_evidence_skipped,
        },
        "evidence": evidence_join(details, limit=2),
        "reason": (
            "Standalone external-intelligence sidecar material lacks standalone prompt fields or overclaims authority"
            if offenders
            else "Standalone external-intelligence sidecar evidence is complete or absent"
        ),
    }


def owner_surface_ambiguity(texts: dict[str, str]) -> dict[str, Any]:
    offenders: list[str] = []
    grounded: list[str] = []

    for path, text in owner_evidence_texts(texts).items():
        if is_work_management_signature_explainer(path, text):
            grounded.append(path)
            continue
        for line in text.splitlines():
            if not CORE_FIVE_SURFACE_PATTERN.search(line):
                continue
            if OWNER_SURFACE_EXACT_PATTERN.search(line):
                grounded.append(path)
                break
            if OWNER_SURFACE_AMBIGUITY_PATTERN.search(line):
                offenders.append(path)
                break

    details = [
        f"owner_surface_ambiguity=>{','.join(offenders[:4]) or 'none'}",
        f"grounded_owner_surface=>{','.join(grounded[:4]) or 'none'}",
    ]
    return {
        "fired": bool(offenders),
        "signals": {
            "owner_surface_ambiguity_count": len(offenders),
            "grounded_owner_surface_count": len(grounded),
        },
        "evidence": evidence_join(details),
        "reason": "repo-star/core-five recommendation lacks exact owner surface" if offenders else "core-five owner surfaces are exact or absent",
    }


def reciprocal_proving_ground_gap(texts: dict[str, str]) -> dict[str, Any]:
    offenders: list[str] = []
    grounded: list[str] = []
    root_grounded: list[str] = []

    for path, text in owner_evidence_texts(texts).items():
        if is_work_management_signature_explainer(path, text):
            grounded.append(path)
            continue
        lowered = text.lower()
        if not CORE_FIVE_SURFACE_PATTERN.search(lowered):
            continue
        if not CORE_FIVE_VALIDATION_PATTERN.search(lowered):
            continue
        if RECIPROCAL_PROVING_GROUND_PATTERN.search(text):
            grounded.append(path)
            if path in {"AGENTS.md", "README.md", "CLAUDE.md"}:
                root_grounded.append(path)
        else:
            offenders.append(path)

    if root_grounded:
        offenders = []

    details = [
        f"reciprocal_proving_ground_gap=>{','.join(offenders[:4]) or 'none'}",
        f"reciprocal_grounded=>{','.join(grounded[:4]) or 'none'}",
        f"reciprocal_root_grounded=>{','.join(root_grounded[:4]) or 'none'}",
    ]
    return {
        "fired": bool(offenders),
        "signals": {
            "reciprocal_proving_ground_gap_count": len(offenders),
            "reciprocal_proving_grounded_count": len(grounded),
        },
        "evidence": evidence_join(details),
        "reason": "core-five validation guidance lacks read-only reciprocal proving-ground boundary" if offenders else "core-five validation guidance is bounded or absent",
    }


GOAL_RUNTIME_IMPROVEMENT_PATTERN = re.compile(
    r"\b(goal[- ]?mode|codex goal|goal episode)\b.{0,160}"
    r"(?:(?<!self-)\bimprov(?:e|ed|ement|ing|es)?\b|\breduc(?:e|ed|tion)\b|"
    r"\bincreas(?:e|ed)\b|\bself[- ]?healing\b|\boperator steering\b|"
    r"\bruntime health\b|\bautonomy\b|\bcontinuity\b)",
    re.IGNORECASE | re.DOTALL,
)
RAW_RUNTIME_EVIDENCE_PATTERN = re.compile(
    r"\b(raw runtime evidence|session logs?|rollout[-_][A-Za-z0-9_.-]+\\.jsonl|goal receipt|"
    r"goal metadata|runtime ledger|runtime-behavior ledger|command transcript|ci run|"
    r"github actions run|check run|replay log)\b",
    re.IGNORECASE,
)
MISSING_RAW_RUNTIME_EVIDENCE_PATTERN = re.compile(
    r"\b(no|missing|without|lacks?|absent|not retained|unavailable)\b.{0,60}"
    r"\b(raw runtime evidence|session logs?|goal receipt|goal metadata|runtime ledger|"
    r"command transcript|ci run|replay log)\b",
    re.IGNORECASE | re.DOTALL,
)
FAILURE_SIGNAL_PATTERN = re.compile(
    r"\b(fail(?:ed|ure)?|blocker|blocked|broken|hang|hung|timeout|unconfigured|gate failure|"
    r"provider failure|ci failure)\b",
    re.IGNORECASE,
)
REACTIVE_META_REPAIR_PATTERN = re.compile(
    r"\b(retrospective|retro|selector|doctrine|principle|planning)\b.{0,120}"
    r"\b(repair|fix|next step|route|handle|address|primary)\b",
    re.IGNORECASE | re.DOTALL,
)
OWNER_SURFACE_REPAIR_PATTERN = re.compile(
    r"\b(owner[-_ ]?surface|owner repo|owner repository|first deliverable|github issue truth|"
    r"failure issue|converted? to (?:github )?issue truth|direct repair|exact owner[-_ ]?surface action|"
    r"issue, branch, PR, checks, and merge)\b",
    re.IGNORECASE,
)
SELF_HEALING_NEGATION_PATTERN = re.compile(
    r"\b(do not|not|never|instead of|rather than|invalid|forbid(?:s|den)?|rejects?)\b.{0,80}"
    r"\b(retrospective|retro|selector|doctrine|planning)\b",
    re.IGNORECASE | re.DOTALL,
)
INTERRUPTION_BLOCKER_PATTERN = re.compile(
    r"\b(interrupt(?:ed|ion)?|blocked?|blocker|upstream blocker|upstream fix|"
    r"tool runtime failure|hermes executable not found|ci failure|permission boundary|"
    r"owner[- ]surface blocker|validation blocker|timeout|hang|hung)\b",
    re.IGNORECASE,
)
INTERRUPTION_CONTRACT_PATTERN = re.compile(
    r"\b(interruption recovery and batch reconstitution|interrupted goal recovery|"
    r"batch reconstitution|replacement objective|original objective|blocker class|"
    r"intentional serial/parallel plan)\b",
    re.IGNORECASE,
)
RECOVERY_FIELDS = {
    "original_objective": re.compile(r"\boriginal objective\b", re.IGNORECASE),
    "blocker_class": re.compile(r"\bblocker class\b", re.IGNORECASE),
    "goal_state": re.compile(r"\bgoal state\b", re.IGNORECASE),
    "replacement_objective": re.compile(r"\breplacement objective\b", re.IGNORECASE),
    "first_owner_pr": re.compile(r"\bfirst owner (?:pr|pull request|issue)\b", re.IGNORECASE),
    "intentional_plan": re.compile(r"\bintentional serial/parallel plan\b", re.IGNORECASE),
    "learning_trigger": re.compile(r"\blearning trigger\b", re.IGNORECASE),
    "fallback": re.compile(r"\bfallback\b", re.IGNORECASE),
    "validation": re.compile(r"\bvalidation\b", re.IGNORECASE),
}
FRACTURED_SERIAL_PATTERN = re.compile(
    r"\b(fractured serial continuation|ad hoc serial|serial repair(?:s)? without (?:a )?plan|"
    r"continue one[- ]off|continue one at a time|single[- ]PR continuation|"
    r"silent serial continuation|unplanned serial)\b",
    re.IGNORECASE,
)
RECOVERY_RECONSTITUTED_PATTERN = re.compile(
    r"\b(replacement objective|first owner (?:pr|pull request|issue)|"
    r"intentional serial/parallel plan|goal-ready (?:episode|github episode)|"
    r"batch reconstitution)\b",
    re.IGNORECASE,
)
SELF_LEARNING_CLAIM_PATTERN = re.compile(
    r"\b(self[- ]?(?:learning|learned)|self[- ]?(?:healing|healed)|self[- ]?improv(?:ement|ing)|"
    r"learning / recovery|learning/recovery|reusable learning|"
    r"decision[- ]changing learning|learned from|learning loop)\b",
    re.IGNORECASE,
)
LEARNING_GITHUB_SURFACE_PATTERN = re.compile(
    r"\b(github surface|github issue truth|github issue|owner action|owner[-_ ]surface|"
    r"first owner (?:pr|pull request|issue)|issue #\d+|pr #\d+|pull request #\d+|"
    r"check run|github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+/(?:issues|pull)/\d+)\b",
    re.IGNORECASE,
)
LEARNING_MEMORY_DISPOSITION_PATTERN = re.compile(
    r"\b(gbrain slug|gbrain capture|optional gbrain slug|bma/issue164/[A-Za-z0-9_.-]+|"
    r"no[-_ ]capture reason|no capture reason|no_capture_reason)\b",
    re.IGNORECASE,
)
LEARNING_BOUNDED_NON_CLAIM_PATTERN = re.compile(
    r"\b(bounded non[- ]claims?|does not prove|does not authorize|non[- ]claim)\b",
    re.IGNORECASE,
)

FOREGROUND_FAILURE_GUIDANCE_CLAIM_PATTERN = re.compile(
    r"(?:\bhermes\b.{0,80}\bforeground\b.{0,120}"
    r"\b(recover(?:y|ed|ing)?|fail(?:ed|ure)?|route[- ]changing)\b|"
    r"\bforeground\b.{0,80}\b(failure guidance|route[- ]changing failure|failed foreground run)\b|"
    r"\bforeground recovery runtime contract\b|"
    r"\bHERMES_FOREGROUND_FAILURE_GUIDANCE\b|"
    r"\b--from-hermes-guidance\b)",
    re.IGNORECASE | re.DOTALL,
)
FOREGROUND_FAILURE_GUIDANCE_CONSUMPTION_PATTERN = re.compile(
    r"\b(HERMES_FOREGROUND_FAILURE_GUIDANCE|--from-hermes-guidance|"
    r"foreground recovery runtime contract)\b|"
    r"\b(consumes?|uses?|requires?|records?|includes?)\b.{0,80}\bfailure_guidance\b|"
    r"\bfailure_guidance\b.{0,80}\b(receipt field|path|url|not-applicable reason)\b",
    re.IGNORECASE,
)
FOREGROUND_FAILURE_GUIDANCE_NEGATED_CONSUMPTION_PATTERN = re.compile(
    r"\b(does not|without|missing|omit(?:s|ted)?|lacks?)\b.{0,80}$",
    re.IGNORECASE,
)
ROUTE_CHANGING_GITHUB_OWNER_TRUTH_PATTERN = re.compile(
    r"(?=.*\b(route[- ]changing failures?|foreground failures?|failed foreground run|fail(?:ed|ure)\b))"
    r"(?=.*\b(github issue truth|github issue/owner truth|github issue|issue truth)\b)"
    r"(?=.*\b(owner truth|owner[-_ ]surface|owner action|owner repo|owner repository)\b)",
    re.IGNORECASE | re.DOTALL,
)
FAILED_FOREGROUND_RECEIPT_EVIDENCE_PATTERN = re.compile(
    r"(?=.*\b(failed|failure|non[- ]zero|status_code|stderr_tail|exit code)\b)"
    r"(?=.*\b(HERMES_FOREGROUND_RUN_RECEIPT|foreground run receipt|run receipt evidence|failed run receipt)\b)",
    re.IGNORECASE | re.DOTALL,
)
NO_REGROWTH_BOUNDARY_PATTERN = re.compile(
    r"\b(no[- ]regrowth|forbid(?:s|den)?|must not|do not|never|"
    r"does not authorize|not by|not a runtime dependency|must not turn)\b",
    re.IGNORECASE,
)
NO_REGROWTH_CONTROL_TERMS = {
    "controller": re.compile(r"\bcontroller\b", re.IGNORECASE),
    "scheduler": re.compile(r"\bscheduler|cron\b", re.IGNORECASE),
    "queue": re.compile(r"\bqueues?\b", re.IGNORECASE),
    "daemon": re.compile(r"\bdaemon|service\b", re.IGNORECASE),
    "retry": re.compile(r"\bretr(?:y|ies)|retry[- ]loop\b", re.IGNORECASE),
    "background": re.compile(r"\bbackground (?:behavior|sync|memory)|watcher|autopilot|MCP server\b", re.IGNORECASE),
}
NO_REGROWTH_MUTATION_BOUNDARY_PATTERN = re.compile(
    r"\b(downstream mutation|downstream repos?|target[- ]repo mutation|mutating downstream|"
    r"mutate target repos?|target repos?|Hermes internals|automatic GitHub issue creation|"
    r"automatic background issue creation|Hermes/GBrain internals mutation)\b",
    re.IGNORECASE,
)
FAILURE_TO_ISSUE_CONVERSION_PATTERN = re.compile(
    r"\b(foreground failure[- ]to[- ]issue conversion|failure[- ]to[- ]issue conversion|"
    r"GitHub failure issue)\b",
    re.IGNORECASE,
)
FOREGROUND_FAILURE_SOURCE_GUIDANCE_PATTERN = re.compile(
    r"\b(HERMES_FOREGROUND_FAILURE_GUIDANCE|source receipt evidence|source receipt path|"
    r"foreground run receipt|failed run receipt evidence)\b",
    re.IGNORECASE,
)
GITHUB_ISSUE_COMMENT_TRUTH_PATTERN = re.compile(
    r"(?=.*(?:\b(GitHub issue or GitHub issue comment truth|GitHub issue comment truth|"
    r"issue comment truth|owner GitHub issue|GitHub issue truth)\b))"
    r"(?=.*\b(owner[-_ ]surface|owner action|owner repo|owner repository|owner issue)\b)",
    re.IGNORECASE | re.DOTALL,
)
EXACT_MARKER_DEDUPE_PATTERN = re.compile(
    r"(?=.*\b(exact marker search|exact marker|exact[- ]marker|stable dedupe marker)\b)"
    r"(?=.*\b(dedupe key|dedupe marker|dedupe-key|issue164-foreground-failure-to-issue)\b)",
    re.IGNORECASE | re.DOTALL,
)
BOUNDED_FALLBACK_INDEX_LAG_PATTERN = re.compile(
    r"(?=.*\bbounded fallback body scan\b)"
    r"(?=.*\bindex[- ]lag guard\b)",
    re.IGNORECASE | re.DOTALL,
)
EVIDENCE_SOURCE_RECEIPT_PATH_PATTERN = re.compile(
    r"(?=.*\b(evidence path|evidence file|evidence URL|evidence url)\b)"
    r"(?=.*\b(source receipt path|source receipt evidence|HERMES_FOREGROUND_FAILURE_GUIDANCE source)\b)",
    re.IGNORECASE | re.DOTALL,
)
CONVERSION_BOUNDED_NON_CLAIMS_PATTERN = re.compile(
    # The conversion contract must mention non-claims, no-retry/no-repair
    # language, and the control-plane terms it is disclaiming.
    r"(?=.*\b(bounded non[- ]claims?|not closure|not a repair|not CI proof|not runtime proof)\b)"
    r"(?=.*\b(no automatic retry/repair|automatic retry|retry the command|automatic repair|repair code)\b)"
    r"(?=.*\b(controller|background behavior|background GBrain behavior|daemon|scheduler|queue)\b)",
    re.IGNORECASE | re.DOTALL,
)


def is_foreground_failure_guidance_surface(path: str) -> bool:
    lowered = path.lower()
    if lowered.startswith(("schemas/", "templates/", "scripts/")):
        return False
    return (
        path in {"AGENTS.md", "README.md"}
        or lowered.startswith("docs/")
        or lowered.startswith(".github/")
        or lowered.startswith(".agents/")
    )


def has_foreground_failure_guidance_consumption(text: str) -> bool:
    for match in FOREGROUND_FAILURE_GUIDANCE_CONSUMPTION_PATTERN.finditer(text):
        prefix = text[max(0, match.start() - 100) : match.start()]
        if FOREGROUND_FAILURE_GUIDANCE_NEGATED_CONSUMPTION_PATTERN.search(prefix):
            continue
        return True
    return False
RESERVED_STATUS_ASSIGNMENT_PATTERN = re.compile(r"(^|[;&|({\s\"'])status=")
AS27_REPLAY_EVIDENCE_PATH_PATTERN = re.compile(
    r"(^|/)acceptance/replays/[^/]+/(AS_WORK_MANAGEMENT_FINDINGS\.json|advisor-stdout\.txt)$|"
    r"(^|/)(AS_WORK_MANAGEMENT_FINDINGS\.json|advisor-stdout\.txt)$",
    re.IGNORECASE,
)
AS27_REPLAY_EVIDENCE_TEXT_PATTERN = re.compile(
    r"(?:\b(?:AS_WORK_MANAGEMENT_FINDINGS|fired_findings|advisor stdout|advisor-stdout|"
    r"anti_pattern_family|shell_reserved_status_variable|reserved_status_assignment=>|"
    r"review diff|evidence_refs)\b|reported reason:|snapshot corroboration:|receipt:)",
    re.IGNORECASE,
)
HERMES_OR_ZSH_CONTEXT_PATTERN = re.compile(
    r"\b(hermes|foreground|launch snippet|launch contract|zsh|zsh-compatible|"
    r"read-only variable|reserved variable|validate-hermes-foreground-output)\b",
    re.IGNORECASE,
)
DEFAULT_CAPABILITY_GUIDANCE_PATTERN = re.compile(
    r"\b(default capability|capability default|default/upstream capability|"
    r"upstream default|adopt(?:s|ed|ing)? (?:the )?(?:upstream )?default|"
    r"make (?:this|the) capability default|"
    r"recommend(?:s|ed|ation)? .{0,80}\bdefault capability\b)\b",
    re.IGNORECASE | re.DOTALL,
)
WEAK_DEFAULT_PROOF_PATTERN = re.compile(
    r"\b(fork proof|fork-only proof|pr[- ]branch proof|pull request branch proof|"
    r"branch proof|remote-only proof|remote only proof|remote branch check|"
    r"remote[- ]only branch check|upstream branch proof|open pr|open pull request|"
    r"unmerged pr|unmerged pull request)\b",
    re.IGNORECASE,
)
DEFAULT_RECONCILIATION_GATE_PATTERN = re.compile(
    r"\b(upstream[-_ ]main(?:[-_ ]sha)?|local[-_ ]main(?:[-_ ]sha)?|"
    r"upstream[-_ ]main/local[-_ ]proof|local[-_ ]proof|source[-_ ]local[-_ ]reconciliation|"
    r"source/local proof|source proof|local proof|same[-_ ]version(?:[-_ ]proof)?|"
    r"same version proof|reconciliation gate|"
    r"validation reconciliation|validation_receipt|validation record|"
    r"fallback path|fallback_path|rollback path|disable path|owner[-_ ]surface|"
    r"owner repo|owner repository)\b",
    re.IGNORECASE,
)
DEFAULT_RECONCILIATION_MISSING_PATTERN = re.compile(
    r"\b(no|missing|without|lacks?|absent|not retained|unavailable|do not block on|"
    r"skip(?:s|ped)?|omit(?:s|ted)?|remote-only proof is enough)\b.{0,100}"
    r"\b(upstream[-_ ]main|local[-_ ]proof|local proof|same[-_ ]version|source[-_ ]local|source/local|"
    r"owner[-_ ]surface|owner surface|fallback|validation reconciliation|validation record|reconciliation gate)\b",
    re.IGNORECASE | re.DOTALL,
)
DEFAULT_OWNER_SURFACE_MISSING_PATTERN = re.compile(
    r"\b(no|missing|without|lacks?|absent|not retained|unavailable)\b.{0,80}"
    r"\b(owner[-_ ]surface|owner surface|owner repo|owner repository)\b",
    re.IGNORECASE | re.DOTALL,
)
DEFAULT_WEAK_PROOF_NEGATION_PATTERN = re.compile(
    r"\b(do not|don't|must not|never|forbid(?:s|den)?|reject(?:s|ed)?|not enough|"
    r"insufficient|invalid)\b.{0,120}\b(fork proof|fork-only proof|pr[- ]branch proof|"
    r"pull request branch proof|remote-only proof|remote only proof|remote branch check|"
    r"open pr|open pull request|unmerged pr|unmerged pull request)\b",
    re.IGNORECASE | re.DOTALL,
)
DEFAULT_REQUIRED_RECONCILIATION_PATTERNS = {
    "upstream_main": re.compile(r"\b(upstream[-_ ]main(?:[-_ ]sha)?|main branch upstream)\b", re.IGNORECASE),
    "local_proof": re.compile(r"\b(local[-_ ]proof|local proof|local[-_ ]main(?:[-_ ]sha)?)\b", re.IGNORECASE),
    "same_version_proof": re.compile(r"\b(same[-_ ]version(?:[-_ ]proof)?|same version proof|same version)\b", re.IGNORECASE),
    "owner_surface": re.compile(r"\b(owner[-_ ]surface|owner surface|owner repo|owner repository)\b", re.IGNORECASE),
    "fallback": re.compile(r"\b(fallback path|fallback_path|rollback path|disable path|kill switch)\b", re.IGNORECASE),
    "validation": re.compile(r"\b(validation reconciliation|validation_receipt|validation record|validation receipt)\b", re.IGNORECASE),
}
HERMES_FOREGROUND_GUIDANCE_PATTERN = re.compile(
    r"(?:\bhermes foreground launchers?\b|\bforeground launchers?\b|"
    r"\bforeground wrapper\b|\bforeground hermes\b|"
    r"\bhermes\s+chat\b(?=[\s\S]{0,160}(?:^|\s)-q(?:\s|=|$))"
    r"(?=[\s\S]{0,160}(?:^|\s)-Q(?:\s|$))|"
    r"\bvalidate-hermes-foreground-output\.py\b|"
    r"\btimeout\s+\d+\s+hermes\s+chat\b|"
    r"\bhermes\s+chat\b(?=[\s\S]{0,160}(?:^|\s)"
    r"(?:--provider|-m|--model|--model-id)(?:\s|=|$)))",
    re.IGNORECASE | re.DOTALL,
)
HERMES_FOREGROUND_RECEIPT_CONTRACT_PATTERN = re.compile(
    r"\b(HERMES_FOREGROUND_RUN_RECEIPT|run-hermes-foreground\.py|"
    r"hermes-foreground-launcher-contract\.md|"
    r"HERMES_FOREGROUND_RUN_RECEIPT\.schema\.json)\b",
    re.IGNORECASE,
)
HERMES_FOREGROUND_CLEAN_EXAMPLE_PATTERN = re.compile(
    r"\b(clean example|safe example|compliant example|negative fixture|"
    r"should not fire|does not fire|no finding)\b",
    re.IGNORECASE,
)


def strip_operations_signature_inventory_for_as28(path: str, text: str) -> str:
    """Ignore AS-28 reference-only inventory lines in repo-auditor operations docs."""

    if path != "docs/agent-operations.md":
        return text
    kept: list[str] = []
    in_detection_signatures = False
    for line in text.splitlines():
        if line.startswith("## "):
            in_detection_signatures = line.strip() == "## Detection Signatures"
        if in_detection_signatures and WORK_MANAGEMENT_SIGNATURE_REFERENCE_PATTERN.search(line):
            continue
        kept.append(line)
    return "\n".join(kept)


def is_as27_retained_replay_evidence(path: str, text: str) -> bool:
    """Suppress retained AS-27 replay/advisor receipts that quote historical findings."""

    if not AS27_REPLAY_EVIDENCE_PATH_PATTERN.search(path):
        return False
    if not RESERVED_STATUS_ASSIGNMENT_PATTERN.search(text):
        return False
    return AS27_REPLAY_EVIDENCE_TEXT_PATTERN.search(text) is not None


def shell_reserved_status_variable(texts: dict[str, str]) -> dict[str, Any]:
    offenders: list[str] = []
    safe_examples: list[str] = []
    replay_evidence: list[str] = []

    for path, text in owner_evidence_texts(texts).items():
        if is_work_management_signature_explainer(path, text):
            safe_examples.append(path)
            continue
        if is_as27_retained_replay_evidence(path, text):
            replay_evidence.append(path)
            continue
        path_lower = path.lower()
        context = bool(
            HERMES_OR_ZSH_CONTEXT_PATTERN.search(text)
            or path_lower.endswith((".zsh", ".zshrc", ".zprofile", ".zlogin"))
        )
        if not context:
            continue
        path_offenders: list[str] = []
        in_python_multiline_string = False
        for line in text.splitlines():
            triple_quote_count = line.count('"""') + line.count("'''")
            in_generated_python_string = in_python_multiline_string
            if triple_quote_count % 2 == 1:
                in_python_multiline_string = not in_python_multiline_string
            if (
                path.endswith(".py")
                and not in_generated_python_string
                and re.match(r"^\s*status\s*=", line)
            ):
                rhs = line.split("=", 1)[1]
                if not RESERVED_STATUS_ASSIGNMENT_PATTERN.search(rhs):
                    continue
            if RESERVED_STATUS_ASSIGNMENT_PATTERN.search(line):
                path_offenders.append(line.strip()[:100])
            elif re.search(r"\b(?:hermes_status|cmd_status|STATUS)\s*=\s*\$\?", line):
                safe_examples.append(path)
        if path_offenders:
            offenders.append(f"{path}=>{path_offenders[0]}")

    details = [
        f"reserved_status_assignment=>{';'.join(offenders[:4]) or 'none'}",
        f"safe_status_assignment=>{','.join(sorted(set(safe_examples))[:4]) or 'none'}",
        f"retained_replay_evidence=>{','.join(sorted(set(replay_evidence))[:4]) or 'none'}",
    ]
    return {
        "fired": bool(offenders),
        "signals": {
            "shell_reserved_status_variable_count": len(offenders),
            "safe_status_assignment_count": len(set(safe_examples)),
            "retained_replay_evidence_count": len(set(replay_evidence)),
        },
        "evidence": evidence_join(details),
        "reason": "Hermes/zsh launch snippet assigns to reserved shell variable `status`" if offenders else "Hermes/zsh launch snippets use non-reserved status variables, are retained replay evidence, or are absent",
    }


def stale_default_capability_guidance(texts: dict[str, str]) -> dict[str, Any]:
    offenders: list[str] = []
    reconciled: list[str] = []
    weak_proof_count = 0
    stale_record_count = 0
    missing_owner_surface_count = 0
    missing_same_version_count = 0

    for path, text in owner_evidence_texts(texts).items():
        if is_work_management_signature_explainer(path, text):
            reconciled.append(path)
            continue
        if not path.endswith((".md", ".txt", ".json", ".jsonl", ".csv", ".yml", ".yaml")):
            continue
        text = strip_operations_signature_inventory_for_as28(path, text)
        if not DEFAULT_CAPABILITY_GUIDANCE_PATTERN.search(text):
            continue

        has_weak_proof = WEAK_DEFAULT_PROOF_PATTERN.search(text) is not None
        weak_proof_is_negated = DEFAULT_WEAK_PROOF_NEGATION_PATTERN.search(text) is not None
        missing_reconciliation = DEFAULT_RECONCILIATION_MISSING_PATTERN.search(text) is not None
        owner_surface_is_missing = DEFAULT_OWNER_SURFACE_MISSING_PATTERN.search(text) is not None
        required_hits = {
            name: pattern.search(text) is not None
            for name, pattern in DEFAULT_REQUIRED_RECONCILIATION_PATTERNS.items()
        }
        if owner_surface_is_missing:
            required_hits["owner_surface"] = False
        has_reconciliation_record = all(required_hits.values())

        if has_weak_proof and not weak_proof_is_negated:
            weak_proof_count += 1
        if not required_hits["owner_surface"]:
            missing_owner_surface_count += 1
        if not required_hits["same_version_proof"]:
            missing_same_version_count += 1

        if weak_proof_is_negated and has_reconciliation_record:
            reconciled.append(path)
        elif missing_reconciliation or (has_weak_proof and not weak_proof_is_negated) or not has_reconciliation_record:
            missing_keys = [name for name, present in required_hits.items() if not present]
            offenders.append(f"{path}=>missing:{','.join(missing_keys) or 'none'}")
            if not has_weak_proof and not missing_reconciliation:
                stale_record_count += 1
        else:
            reconciled.append(path)

    details = [
        f"stale_default_capability_guidance=>{';'.join(offenders[:4]) or 'none'}",
        f"reconciled_default_capability=>{','.join(sorted(set(reconciled))[:4]) or 'none'}",
    ]
    return {
        "fired": bool(offenders),
        "signals": {
            "stale_default_capability_guidance_count": len(offenders),
            "weak_default_proof_count": weak_proof_count,
            "missing_reconciliation_record_count": len(offenders),
            "stale_default_record_count": stale_record_count,
            "missing_owner_surface_count": missing_owner_surface_count,
            "missing_same_version_proof_count": missing_same_version_count,
            "reconciled_default_capability_count": len(set(reconciled)),
        },
        "evidence": evidence_join(details),
        "reason": "default capability guidance relies on fork/PR/remote-only/open-PR proof or lacks upstream-main/local/same-version owner/fallback validation reconciliation" if offenders else "default capability guidance is reconciled or absent",
    }


def hermes_foreground_receipt_adoption_gap(texts: dict[str, str]) -> dict[str, Any]:
    offenders: list[str] = []
    grounded: list[str] = []
    clean_examples: list[str] = []

    for path, text in owner_evidence_texts(texts).items():
        if is_work_management_signature_explainer(path, text):
            grounded.append(path)
            continue
        if not path.endswith((".md", ".txt", ".json", ".jsonl", ".csv", ".yml", ".yaml", ".sh", ".py")):
            continue
        if not HERMES_FOREGROUND_GUIDANCE_PATTERN.search(text):
            continue
        has_contract = HERMES_FOREGROUND_RECEIPT_CONTRACT_PATTERN.search(text) is not None
        is_clean_example = HERMES_FOREGROUND_CLEAN_EXAMPLE_PATTERN.search(text) is not None
        if has_contract:
            grounded.append(path)
        elif is_clean_example:
            clean_examples.append(path)
        else:
            offenders.append(path)

    details = [
        f"foreground_receipt_gap=>{','.join(offenders[:4]) or 'none'}",
        f"foreground_receipt_grounded=>{','.join(sorted(set(grounded))[:4]) or 'none'}",
        f"foreground_clean_example=>{','.join(sorted(set(clean_examples))[:4]) or 'none'}",
    ]
    return {
        "fired": bool(offenders),
        "signals": {
            "hermes_foreground_guidance_count": len(offenders) + len(set(grounded)) + len(set(clean_examples)),
            "foreground_receipt_gap_count": len(offenders),
            "foreground_receipt_grounded_count": len(set(grounded)),
            "foreground_clean_example_count": len(set(clean_examples)),
        },
        "evidence": evidence_join(details),
        "reason": "Hermes foreground launcher guidance lacks the governed run receipt contract" if offenders else "Hermes foreground launcher guidance carries receipt contract references, is a clean example, or is absent",
    }


def goal_runtime_evidence_gap(texts: dict[str, str]) -> dict[str, Any]:
    offenders: list[str] = []
    grounded: list[str] = []

    for path, text in owner_evidence_texts(texts).items():
        if is_work_management_signature_explainer(path, text):
            grounded.append(path)
            continue
        if not GOAL_RUNTIME_IMPROVEMENT_PATTERN.search(text):
            continue
        has_evidence = RAW_RUNTIME_EVIDENCE_PATTERN.search(text) is not None
        missing_evidence = MISSING_RAW_RUNTIME_EVIDENCE_PATTERN.search(text) is not None
        if has_evidence and not missing_evidence:
            grounded.append(path)
        else:
            offenders.append(path)

    details = [
        f"goal_runtime_evidence_gap=>{','.join(offenders[:4]) or 'none'}",
        f"goal_runtime_evidence_grounded=>{','.join(grounded[:4]) or 'none'}",
    ]
    return {
        "fired": bool(offenders),
        "signals": {
            "goal_runtime_claim_count": len(offenders) + len(grounded),
            "goal_runtime_evidence_gap_count": len(offenders),
            "goal_runtime_evidence_grounded_count": len(grounded),
        },
        "evidence": evidence_join(details),
        "reason": "Goal-mode runtime improvement claim lacks raw runtime evidence" if offenders else "Goal-mode runtime claims cite raw runtime evidence or are absent",
    }


def reactive_self_healing_loop(texts: dict[str, str]) -> dict[str, Any]:
    offenders: list[str] = []
    repaired: list[str] = []

    for path, text in owner_evidence_texts(texts).items():
        if is_work_management_signature_explainer(path, text):
            repaired.append(path)
            continue
        path_repaired = False
        path_offender = False
        chunks = [chunk.strip() for chunk in re.split(r"\n\s*\n", text) if chunk.strip()]
        for chunk in chunks:
            if not FAILURE_SIGNAL_PATTERN.search(chunk):
                continue
            if OWNER_SURFACE_REPAIR_PATTERN.search(chunk):
                path_repaired = True
                continue
            if SELF_HEALING_NEGATION_PATTERN.search(chunk):
                path_repaired = True
                continue
            if REACTIVE_META_REPAIR_PATTERN.search(chunk):
                path_offender = True
        if path_offender:
            offenders.append(path)
        elif path_repaired:
            repaired.append(path)

    details = [
        f"reactive_self_healing_loop=>{','.join(offenders[:4]) or 'none'}",
        f"direct_owner_repair=>{','.join(repaired[:4]) or 'none'}",
    ]
    return {
        "fired": bool(offenders),
        "signals": {
            "reactive_self_healing_loop_count": len(offenders),
            "direct_owner_repair_count": len(repaired),
        },
        "evidence": evidence_join(details),
        "reason": "known failure routes to retrospective/selector/doctrine work instead of owner-surface repair" if offenders else "known failures route to owner-surface repair or are absent",
    }


def interruption_recovery_missing_fields(text: str) -> list[str]:
    return [field for field, pattern in RECOVERY_FIELDS.items() if not pattern.search(text)]


def interrupted_goal_recovery_gap(texts: dict[str, str]) -> dict[str, Any]:
    offenders: list[str] = []
    grounded: list[str] = []

    for path, text in owner_evidence_texts(texts).items():
        if is_work_management_signature_explainer(path, text):
            grounded.append(path)
            continue
        if not (GOAL_MODE_PATTERN.search(text) and INTERRUPTION_BLOCKER_PATTERN.search(text)):
            continue
        if not INTERRUPTION_CONTRACT_PATTERN.search(text):
            continue
        missing = interruption_recovery_missing_fields(text)
        if missing:
            offenders.append(f"{path}=>missing:{','.join(missing[:4])}")
        else:
            grounded.append(path)

    details = [
        f"interrupted_goal_recovery_gap=>{';'.join(offenders[:4]) or 'none'}",
        f"interrupted_goal_recovery_grounded=>{','.join(grounded[:4]) or 'none'}",
    ]
    return {
        "fired": bool(offenders),
        "signals": {
            "interrupted_goal_recovery_gap_count": len(offenders),
            "interrupted_goal_recovery_grounded_count": len(grounded),
        },
        "evidence": evidence_join(details),
        "reason": "Goal-mode blocker recovery lacks the batch reconstitution contract fields" if offenders else "interrupted Goal recovery records are complete or absent",
    }


def fractured_serial_continuation(texts: dict[str, str]) -> dict[str, Any]:
    offenders: list[str] = []
    reconstituted: list[str] = []

    for path, text in owner_evidence_texts(texts).items():
        if is_work_management_signature_explainer(path, text):
            reconstituted.append(path)
            continue
        path_offender = False
        path_reconstituted = False
        chunks = [chunk.strip() for chunk in re.split(r"\n\s*\n", text) if chunk.strip()]
        for chunk in chunks:
            if not (INTERRUPTION_BLOCKER_PATTERN.search(chunk) and FRACTURED_SERIAL_PATTERN.search(chunk)):
                continue
            if RECOVERY_RECONSTITUTED_PATTERN.search(chunk):
                path_reconstituted = True
                continue
            path_offender = True
        if path_offender:
            offenders.append(path)
        elif path_reconstituted:
            reconstituted.append(path)

    details = [
        f"fractured_serial_continuation=>{','.join(offenders[:4]) or 'none'}",
        f"batch_reconstituted=>{','.join(reconstituted[:4]) or 'none'}",
    ]
    return {
        "fired": bool(offenders),
        "signals": {
            "fractured_serial_continuation_count": len(offenders),
            "batch_reconstituted_count": len(reconstituted),
        },
        "evidence": evidence_join(details),
        "reason": "blocker recovery collapsed into unplanned serial continuation" if offenders else "blocker recovery is batch-reconstituted or absent",
    }


def unanchored_self_learning_claim(texts: dict[str, str]) -> dict[str, Any]:
    offenders: list[str] = []
    grounded: list[str] = []

    for path, text in owner_evidence_texts(texts).items():
        # AS-32 audits owner guidance claims, not detector wrapper names.
        if path.startswith("scripts/"):
            continue
        if is_work_management_signature_explainer(path, text):
            grounded.append(path)
            continue
        if path == "docs/agent-operations.md" and WORK_MANAGEMENT_SIGNATURE_REFERENCE_PATTERN.search(text):
            grounded.append(path)
            continue
        if not SELF_LEARNING_CLAIM_PATTERN.search(text):
            continue
        has_github_surface = LEARNING_GITHUB_SURFACE_PATTERN.search(text) is not None
        has_raw_evidence = RAW_RUNTIME_EVIDENCE_PATTERN.search(text) is not None
        has_memory_disposition = LEARNING_MEMORY_DISPOSITION_PATTERN.search(text) is not None
        has_bounded_non_claim = LEARNING_BOUNDED_NON_CLAIM_PATTERN.search(text) is not None
        if has_github_surface and has_raw_evidence and has_memory_disposition and has_bounded_non_claim:
            grounded.append(path)
            continue
        missing = []
        if not has_github_surface:
            missing.append("github_surface_or_owner_action")
        if not has_raw_evidence:
            missing.append("raw_evidence")
        if not has_memory_disposition:
            missing.append("gbrain_slug_or_no_capture_reason")
        if not has_bounded_non_claim:
            missing.append("bounded_non_claims")
        offenders.append(f"{path}=>missing:{','.join(missing[:4])}")

    details = [
        f"unanchored_self_learning_claim=>{';'.join(offenders[:4]) or 'none'}",
        f"learning_recovery_grounded=>{','.join(grounded[:4]) or 'none'}",
    ]
    return {
        "fired": bool(offenders),
        "signals": {
            "unanchored_self_learning_claim_count": len(offenders),
            "learning_recovery_grounded_count": len(grounded),
        },
        "evidence": evidence_join(details),
        "reason": "self-learning/self-healing claim lacks GitHub owner action, raw evidence, memory disposition, or bounded non-claims" if offenders else "self-learning claims are anchored or absent",
    }


def foreground_failure_guidance_gap(texts: dict[str, str]) -> dict[str, Any]:
    offenders: list[str] = []
    grounded: list[str] = []

    for path, text in owner_evidence_texts(texts).items():
        if not is_foreground_failure_guidance_surface(path):
            continue
        if is_work_management_signature_explainer(path, text):
            grounded.append(path)
            continue
        if path == "docs/agent-operations.md" and WORK_MANAGEMENT_SIGNATURE_REFERENCE_PATTERN.search(text):
            grounded.append(path)
            continue
        if not path.endswith((".md", ".txt", ".json", ".jsonl", ".csv", ".yml", ".yaml", ".sh", ".py")):
            continue
        if not FOREGROUND_FAILURE_GUIDANCE_CLAIM_PATTERN.search(text):
            continue

        is_failure_to_issue_conversion = FAILURE_TO_ISSUE_CONVERSION_PATTERN.search(text) is not None
        has_evidence_source_receipt_path = False
        has_guidance_consumption = has_foreground_failure_guidance_consumption(text)
        has_github_owner_truth = ROUTE_CHANGING_GITHUB_OWNER_TRUTH_PATTERN.search(text) is not None
        has_failed_receipt_evidence = FAILED_FOREGROUND_RECEIPT_EVIDENCE_PATTERN.search(text) is not None
        control_term_count = sum(1 for pattern in NO_REGROWTH_CONTROL_TERMS.values() if pattern.search(text))
        has_no_regrowth_boundaries = (
            NO_REGROWTH_BOUNDARY_PATTERN.search(text) is not None
            and control_term_count >= 3
            and NO_REGROWTH_MUTATION_BOUNDARY_PATTERN.search(text) is not None
        )

        if is_failure_to_issue_conversion:
            has_evidence_source_receipt_path = EVIDENCE_SOURCE_RECEIPT_PATH_PATTERN.search(text) is not None
            has_guidance_consumption = (
                has_guidance_consumption
                or FOREGROUND_FAILURE_SOURCE_GUIDANCE_PATTERN.search(text) is not None
            )
            has_github_owner_truth = (
                has_github_owner_truth
                or GITHUB_ISSUE_COMMENT_TRUTH_PATTERN.search(text) is not None
            )
            has_failed_receipt_evidence = (
                has_failed_receipt_evidence
                or has_evidence_source_receipt_path
            )
            has_no_regrowth_boundaries = (
                has_no_regrowth_boundaries
                or CONVERSION_BOUNDED_NON_CLAIMS_PATTERN.search(text) is not None
            )

        missing: list[str] = []
        if not has_guidance_consumption:
            missing.append("guidance_consumption")
        if not has_github_owner_truth:
            missing.append("github_issue_owner_truth")
        if not has_failed_receipt_evidence:
            missing.append("failed_foreground_run_receipt")
        if not has_no_regrowth_boundaries:
            missing.append("no_regrowth_boundaries")
        if is_failure_to_issue_conversion:
            if EXACT_MARKER_DEDUPE_PATTERN.search(text) is None:
                missing.append("exact_marker_dedupe")
            if BOUNDED_FALLBACK_INDEX_LAG_PATTERN.search(text) is None:
                missing.append("bounded_fallback_index_lag_guard")
            if not has_evidence_source_receipt_path:
                missing.append("evidence_and_source_receipt_path")

        if missing:
            offenders.append(f"{path}=>missing:{','.join(missing)}")
        else:
            grounded.append(path)

    details = [
        f"foreground_failure_guidance_gap=>{';'.join(offenders[:4]) or 'none'}",
        f"foreground_failure_guidance_grounded=>{','.join(sorted(set(grounded))[:4]) or 'none'}",
    ]
    return {
        "fired": bool(offenders),
        "signals": {
            "foreground_failure_guidance_claim_count": len(offenders) + len(set(grounded)),
            "foreground_failure_guidance_gap_count": len(offenders),
            "foreground_failure_guidance_grounded_count": len(set(grounded)),
        },
        "evidence": evidence_join(details),
        "reason": "Hermes foreground recovery/self-healing guidance lacks failure-guidance consumption, GitHub issue/owner truth, failed run receipt evidence, or no-regrowth boundaries" if offenders else "foreground failure recovery guidance carries the full runtime contract or is absent",
    }


CLOSURE_LOCAL_COMMAND_PATTERN = re.compile(
    r"\b(make\s+(?:check|test|test-fast|validate|work-close)|"
    r"work-close|check-step|test[-_ ]manifest|record[-_ ]make[-_ ]target|"
    r"local validation|closure timing|timing ledger)\b",
    re.IGNORECASE,
)
CLOSURE_REMOTE_COMMAND_PATTERN = re.compile(
    r"\b(github actions|pull_request|workflow_dispatch|push|schedule|"
    r"jobs:|runs-on:|check run|workflow run|github\.run_id|GITHUB_RUN_ID)\b",
    re.IGNORECASE,
)
CLOSURE_LOCAL_IDENTITY_PATTERN = re.compile(
    r"\b(closure_run_id|closure_phase|closure_trigger|"
    r"evidence_reuse_key|parent_command)\b",
    re.IGNORECASE,
)
CLOSURE_REMOTE_IDENTITY_PATTERN = re.compile(
    r"\b(github_run_id|github_run_attempt|GITHUB_RUN_ID|GITHUB_RUN_ATTEMPT|"
    r"github\.run_id|github\.run_attempt)\b",
    re.IGNORECASE,
)
CLOSURE_IDENTITY_NEGATION_PATTERN = re.compile(
    r"\b(no|missing|without|lacks?|lack|absent|omit(?:s|ted)?|"
    r"cannot|can't|not)\b.{0,80}"
    r"\b(closure[-_ ]run[-_ ]identity|closure_run_id|closure_phase|"
    r"closure_trigger|evidence_reuse_key|github_run_id|github_run_attempt|"
    r"GITHUB_RUN_ID|GITHUB_RUN_ATTEMPT|parent_command)\b",
    re.IGNORECASE | re.DOTALL,
)


def is_closure_owner_surface(path: str) -> bool:
    return (
        path == "Makefile"
        or path == "makefile"
        or path.startswith("scripts/")
        or path.startswith(".github/workflows/")
    )


def has_positive_closure_identity(text: str, pattern: re.Pattern[str]) -> bool:
    if pattern.search(text) is None:
        return False
    return CLOSURE_IDENTITY_NEGATION_PATTERN.search(text) is None


def closure_run_identity_gap(texts: dict[str, str]) -> dict[str, Any]:
    local_closure: list[str] = []
    remote_closure: list[str] = []
    local_identity: list[str] = []
    remote_identity: list[str] = []
    explainer: list[str] = []

    for path, text in owner_evidence_texts(texts).items():
        if is_work_management_signature_explainer(path, text):
            explainer.append(path)
            continue
        if not is_closure_owner_surface(path):
            continue

        if (
            path in {"Makefile", "makefile"}
            or path.startswith("scripts/")
        ) and CLOSURE_LOCAL_COMMAND_PATTERN.search(text):
            local_closure.append(path)
        if path.startswith(".github/workflows/") and CLOSURE_REMOTE_COMMAND_PATTERN.search(text):
            remote_closure.append(path)
        if has_positive_closure_identity(text, CLOSURE_LOCAL_IDENTITY_PATTERN):
            local_identity.append(path)
        if has_positive_closure_identity(text, CLOSURE_REMOTE_IDENTITY_PATTERN):
            remote_identity.append(path)

    missing: list[str] = []
    if local_closure and not local_identity:
        missing.append("local_command_identity")
    if remote_closure and not remote_identity:
        missing.append("github_workflow_identity")

    fired = bool(missing)
    details = [
        f"local_closure=>{','.join(sorted(set(local_closure))[:4]) or 'none'}",
        f"remote_closure=>{','.join(sorted(set(remote_closure))[:4]) or 'none'}",
        f"local_identity=>{','.join(sorted(set(local_identity))[:4]) or 'none'}",
        f"remote_identity=>{','.join(sorted(set(remote_identity))[:4]) or 'none'}",
        f"missing_identity=>{','.join(missing) or 'none'}",
        f"explainer_suppressed=>{','.join(sorted(set(explainer))[:4]) or 'none'}",
    ]
    return {
        "fired": fired,
        "signals": {
            "closure_run_identity_gap_count": 1 if fired else 0,
            "local_closure_surface_count": len(set(local_closure)),
            "remote_closure_surface_count": len(set(remote_closure)),
            "local_identity_surface_count": len(set(local_identity)),
            "remote_identity_surface_count": len(set(remote_identity)),
            "missing_identity_surface_count": len(missing),
            "missing_identity_surfaces": missing,
        },
        "evidence": evidence_join(details),
        "reason": (
            "closure validation surfaces lack comparable closure-run identity across local commands and workflow runs"
            if fired
            else "closure-run identity is present where closure surfaces exist, or closure surfaces are absent"
        ),
    }


HERMES_FAILURE_DISPOSITION_SURFACE_PATTERN = re.compile(
    r"\b(HERMES_FOREGROUND_FAILURE_DISPOSITION|Hermes foreground failure disposition|"
    r"foreground Hermes failure disposition)\b",
    re.IGNORECASE,
)
HERMES_FAILURE_DISPOSITION_EXPLAINER_PATTERN = re.compile(
    r"\b(detect-as-hermes-foreground-failure-disposition-gap\.sh|"
    r"Hermes foreground failure disposition detector coverage|Triggers:\s*AS-50|"
    r"AS-50:\s*Hermes Foreground Failure Disposition Gap)\b",
    re.IGNORECASE,
)
HERMES_FAILURE_DISPOSITION_EXPLAINER_PATHS = {
    "readme.md",
    "scripts/detect-as-hermes-foreground-failure-disposition-gap.sh",
    "scripts/detect-new-signatures.sh",
}
HERMES_FAILURE_DISPOSITION_REQUIRED_FIELDS: tuple[tuple[str, re.Pattern[str]], ...] = (
    ("missing_failure_issue", re.compile(r"^\s*failure[ _-]?issue\s*[:=]", re.IGNORECASE | re.MULTILINE)),
    ("missing_primary_object", re.compile(r"^\s*primary[ _-]?object\s*[:=]", re.IGNORECASE | re.MULTILINE)),
    ("missing_command_family", re.compile(r"^\s*command[ _-]?family\s*[:=]", re.IGNORECASE | re.MULTILINE)),
    ("missing_failure_code", re.compile(r"^\s*failure[ _-]?code\s*[:=]", re.IGNORECASE | re.MULTILINE)),
)
HERMES_FAILURE_DISPOSITION_CLOSE_PATTERN = re.compile(
    r"\b(close[_ -]?allowed\s*[:=]\s*true|close allowance\s*[:=]\s*true|"
    r"resolved_by_merged_repair|close(?:s|d)?\s+(?:the\s+)?failure issue|"
    r"close_failure_issue_with_merged_repair_reference)\b",
    re.IGNORECASE,
)
HERMES_FAILURE_DISPOSITION_MERGED_REPAIR_PATTERN = re.compile(
    r"\b(merged related repair PR|merged repair PR|repair PR)\b",
    re.IGNORECASE,
)
HERMES_FAILURE_DISPOSITION_REFERENCES_FAILURE_PATTERN = re.compile(
    r"\b(references?|refs?|links? to)\s+(?:the\s+)?failure issue\b|"
    r"\bfailure issue itself\b",
    re.IGNORECASE,
)
HERMES_FAILURE_DISPOSITION_AMBIGUOUS_REPAIR_PATTERN = re.compile(
    r"\b(ambiguous|multiple|candidate(?:s)?|primary-object URL equality|"
    r"primary object URL equality|primary object)\b",
    re.IGNORECASE,
)
HERMES_FAILURE_DISPOSITION_PROVIDER_POLICY_PATTERN = re.compile(
    r"\bsuperseded_by_provider_policy\b|\bprovider[- ]policy supersession\b",
    re.IGNORECASE,
)
HERMES_FAILURE_DISPOSITION_SUPERSEDED_SIGNAL_PATTERN = re.compile(
    r"\bexplicit superseded[- ]provider signal\b|\bsuperseded provider\b",
    re.IGNORECASE,
)
HERMES_FAILURE_DISPOSITION_CURRENT_PROVIDER_PATTERN = re.compile(
    r"\bcurrent provider/model policy evidence\b|\bcurrent provider\b.{0,40}\bmodel\b",
    re.IGNORECASE | re.DOTALL,
)
HERMES_FAILURE_DISPOSITION_GITHUB_TRUTH_PATTERN = re.compile(
    r"\b(GitHub truth|github\.com/[^)\s]+/(?:issues|pull)/\d+|issue/PR/check/merge truth|"
    r"issue comment|check run|merge commit)\b",
    re.IGNORECASE,
)
HERMES_FAILURE_DISPOSITION_REPAIR_GITHUB_TRUTH_PATTERN = re.compile(
    r"\b(merged related repair PR|related repair PR|merged repair PR|repair PR|merge commit)\b|"
    r"github\.com/[^)\s]+/pull/\d+",
    re.IGNORECASE,
)
HERMES_FAILURE_DISPOSITION_PRIVATE_ONLY_PATTERN = re.compile(
    r"\b(raw/private-only|private-only|private only|local-only|workspace-only|raw log|"
    r"private log|run root|local receipt)\b|/tmp/",
    re.IGNORECASE,
)
HERMES_FAILURE_DISPOSITION_NEGATION_PATTERN = re.compile(
    r"\b(no|not|never|does not|do not|without|forbid(?:s|den)?|forbidden|"
    r"bounded non-claims?|non-claims?|excluded authority|not a|demotion trigger|"
    r"kill switch|disables?)\b",
    re.IGNORECASE,
)
HERMES_FAILURE_DISPOSITION_HIDDEN_CONTROL_PATTERN = re.compile(
    r"\b(hidden retry|retry loop|scheduler|queue|daemon|controller|registry|"
    r"background Hermes|background GBrain)\b",
    re.IGNORECASE,
)
HERMES_FAILURE_DISPOSITION_AUTOCLOSE_PATTERN = re.compile(
    r"\b(auto[- ]?close|automatically close|automatic closure)\b",
    re.IGNORECASE,
)
HERMES_FAILURE_DISPOSITION_AUTOMERGE_PATTERN = re.compile(
    r"\b(auto[- ]?merge|automatically merge|automatic merge)\b",
    re.IGNORECASE,
)


def hermes_disposition_line_overclaim(text: str, pattern: re.Pattern[str]) -> bool:
    prohibition_context = 0
    for line in text.splitlines():
        if re.search(
            r"\b(bounded[_ -]non-claims?|forbidden authority|excluded authority|non-claims?|"
            r"demotion trigger|kill switch)\b",
            line,
            re.IGNORECASE,
        ):
            prohibition_context = 4
        if not pattern.search(line):
            if prohibition_context and line.strip():
                prohibition_context -= 1
            continue
        if prohibition_context or HERMES_FAILURE_DISPOSITION_NEGATION_PATTERN.search(line):
            if prohibition_context and line.strip():
                prohibition_context -= 1
            continue
        return True
    return False


def hermes_disposition_positive_field(text: str, pattern: re.Pattern[str]) -> bool:
    for line in text.splitlines():
        if pattern.search(line) and not HERMES_FAILURE_DISPOSITION_NEGATION_PATTERN.search(line):
            return True
    return False


def is_hermes_failure_disposition_explainer(path: str, text: str) -> bool:
    """Treat AS-50 catalog and detector docs as explanatory, not dispositions."""
    lowered_path = path.lower()
    if (
        lowered_path not in HERMES_FAILURE_DISPOSITION_EXPLAINER_PATHS
        and not lowered_path.startswith("detection-signatures/")
    ):
        return False
    return HERMES_FAILURE_DISPOSITION_EXPLAINER_PATTERN.search(text) is not None


def hermes_foreground_failure_disposition_gap(texts: dict[str, str]) -> dict[str, Any]:
    offenders: list[str] = []
    grounded: list[str] = []
    reason_counts: Counter[str] = Counter()
    historical_evidence_skipped = 0

    for path, text in owner_evidence_texts(texts).items():
        if path.startswith(HISTORICAL_CLOSURE_ARTIFACT_PREFIXES):
            historical_evidence_skipped += 1
            continue
        if is_work_management_signature_explainer(path, text):
            grounded.append(path)
            continue
        if is_hermes_failure_disposition_explainer(path, text):
            grounded.append(path)
            continue
        if not path.endswith((".md", ".txt", ".json", ".jsonl", ".yml", ".yaml")):
            continue
        if not HERMES_FAILURE_DISPOSITION_SURFACE_PATTERN.search(text):
            continue

        reasons: list[str] = []
        for reason, pattern in HERMES_FAILURE_DISPOSITION_REQUIRED_FIELDS:
            if not pattern.search(text):
                reasons.append(reason)
                reason_counts[reason] += 1

        close_claim = HERMES_FAILURE_DISPOSITION_CLOSE_PATTERN.search(text) is not None
        merged_repair_grounded = hermes_disposition_positive_field(
            text, HERMES_FAILURE_DISPOSITION_MERGED_REPAIR_PATTERN
        ) and hermes_disposition_positive_field(text, HERMES_FAILURE_DISPOSITION_REFERENCES_FAILURE_PATTERN)
        provider_claim = HERMES_FAILURE_DISPOSITION_PROVIDER_POLICY_PATTERN.search(text) is not None
        provider_grounded = hermes_disposition_positive_field(
            text, HERMES_FAILURE_DISPOSITION_SUPERSEDED_SIGNAL_PATTERN
        ) and hermes_disposition_positive_field(text, HERMES_FAILURE_DISPOSITION_CURRENT_PROVIDER_PATTERN)

        if close_claim and not (merged_repair_grounded or provider_grounded):
            reasons.append("missing_merged_repair_evidence")
            reason_counts["missing_merged_repair_evidence"] += 1
        if (
            close_claim
            and HERMES_FAILURE_DISPOSITION_AMBIGUOUS_REPAIR_PATTERN.search(text)
            and not merged_repair_grounded
            and not provider_grounded
        ):
            reasons.append("ambiguous_repair_evidence")
            reason_counts["ambiguous_repair_evidence"] += 1
        if provider_claim and not provider_grounded:
            reasons.append("provider_policy_mismatch")
            reason_counts["provider_policy_mismatch"] += 1
        if (
            HERMES_FAILURE_DISPOSITION_PRIVATE_ONLY_PATTERN.search(text)
            and not HERMES_FAILURE_DISPOSITION_REPAIR_GITHUB_TRUTH_PATTERN.search(text)
        ):
            reasons.append("raw_private_only_evidence")
            reason_counts["raw_private_only_evidence"] += 1
        if hermes_disposition_line_overclaim(text, HERMES_FAILURE_DISPOSITION_HIDDEN_CONTROL_PATTERN):
            reasons.append("hidden_retry_scheduler_controller")
            reason_counts["hidden_retry_scheduler_controller"] += 1
        if hermes_disposition_line_overclaim(text, HERMES_FAILURE_DISPOSITION_AUTOCLOSE_PATTERN):
            reasons.append("auto_close")
            reason_counts["auto_close"] += 1
        if hermes_disposition_line_overclaim(text, HERMES_FAILURE_DISPOSITION_AUTOMERGE_PATTERN):
            reasons.append("auto_merge")
            reason_counts["auto_merge"] += 1

        if reasons:
            offenders.append(f"{path}=>{';'.join(reasons[:8])}")
        else:
            grounded.append(path)

    details = [
        f"hermes_failure_disposition_gap=>{';'.join(offenders[:4]) or 'none'}",
        f"hermes_failure_disposition_grounded=>{','.join(sorted(set(grounded))[:4]) or 'none'}",
    ]
    return {
        "fired": bool(offenders),
        "signals": {
            "hermes_failure_disposition_gap_count": len(offenders),
            "hermes_failure_disposition_grounded_count": len(set(grounded)),
            "missing_failure_issue_count": reason_counts["missing_failure_issue"],
            "missing_primary_object_count": reason_counts["missing_primary_object"],
            "missing_command_family_count": reason_counts["missing_command_family"],
            "missing_failure_code_count": reason_counts["missing_failure_code"],
            "missing_merged_repair_evidence_count": reason_counts["missing_merged_repair_evidence"],
            "ambiguous_repair_evidence_count": reason_counts["ambiguous_repair_evidence"],
            "provider_policy_mismatch_count": reason_counts["provider_policy_mismatch"],
            "raw_private_only_evidence_count": reason_counts["raw_private_only_evidence"],
            "hidden_retry_scheduler_controller_count": reason_counts["hidden_retry_scheduler_controller"],
            "auto_close_count": reason_counts["auto_close"],
            "auto_merge_count": reason_counts["auto_merge"],
            "historical_evidence_skipped": historical_evidence_skipped,
        },
        "evidence": evidence_join(details),
        "reason": (
            "Hermes foreground failure disposition surfaces allow unsafe closure or lack required GitHub repair evidence"
            if offenders
            else "Hermes foreground failure disposition surfaces are absent, explanatory, or grounded"
        ),
    }


ANCHOR_CONSTITUTION_PATTERN = re.compile(
    r"(?im)^#{1,3}\s+.*\bconstitution\b|\boperating[- ]model constitution\b"
)
ANCHOR_OPERATING_MODEL_REF_PATTERN = re.compile(
    r"(?i)\b("
    r"work[- ]clos(?:e|ure)|"
    r"automation[- ](?:health|authority)|automation earns authority|"
    r"grounded route[- ]change|route[- ]grounding|grounded route|"
    r"github[- ](?:truth|deterministic|native closure)|"
    r"fail[- ]closed|"
    r"responder[- ]truth|"
    r"operating[- ]model principle"
    r")\b"
)
ANCHOR_CANON_IMPORT_PATTERN = re.compile(
    r"(?i)("
    r"operating[- ]model (?:principle )?(?:canon|criteria)|"
    r"imported (?:operating[- ]model )?principle canon|"
    r"principle[- ]alignment anchor|"
    r"alignment anchor|"
    r"revealed[- ]vs[- ]defined principle"
    r")"
)
ANCHOR_RECONCILIATION_PATTERN = re.compile(
    r"(?i)("
    r"reconciliation table|"
    r"principle gap matrix|"
    r"gap matrix|"
    r"principle reconciliation|"
    r"revealed[- ]vs[- ]defined"
    r")"
)


def missing_operating_model_alignment_anchor(texts: dict[str, str]) -> dict[str, Any]:
    """AS-51: a repo-agent with a constitution and scattered operating-model
    point-repairs (work-closure, automation-health, route-grounding, GitHub-truth)
    that never imported an operating-model canon, reconciled it, and produced a
    principle gap matrix -- i.e. it has no alignment anchor."""
    owner = owner_evidence_texts(texts)

    constitution_files = [
        path
        for path, text in owner.items()
        if path.endswith("constitution.md")
        or "/memory/constitution" in path
        or ANCHOR_CONSTITUTION_PATTERN.search(text)
    ]
    operating_model_ref_files = [
        path
        for path, text in owner.items()
        if ANCHOR_OPERATING_MODEL_REF_PATTERN.search(text)
    ]
    anchor_artifact_files = [
        path
        for path, text in owner.items()
        if ANCHOR_CANON_IMPORT_PATTERN.search(text)
        and ANCHOR_RECONCILIATION_PATTERN.search(text)
    ]

    constitution_present = bool(constitution_files)
    scattered_count = len(operating_model_ref_files)
    anchor_present = bool(anchor_artifact_files)
    fired = constitution_present and scattered_count > 1 and not anchor_present

    details = [
        f"constitution=>{','.join(constitution_files[:3]) or 'none'}",
        f"operating_model_refs=>{','.join(operating_model_ref_files[:4]) or 'none'}",
        f"alignment_anchor=>{','.join(anchor_artifact_files[:3]) or 'none'}",
    ]
    return {
        "fired": fired,
        "signals": {
            "constitution_present": constitution_present,
            "scattered_operating_model_ref_count": scattered_count,
            "alignment_anchor_artifact_present": anchor_present,
            "missing_operating_model_alignment_anchor_count": 1 if fired else 0,
        },
        "evidence": evidence_join(details),
        "reason": (
            "constitution and scattered operating-model point-repairs exist but no imported-canon + reconciliation/gap-matrix alignment anchor was found"
            if fired
            else "alignment anchor is present, or constitution/operating-model references are absent"
        ),
    }


ANTHROPOLOGY_CONTEXT_PATTERN = re.compile(
    r"(?im)^#{1,3}\s+.*\bconstitution\b|\boperating[- ]model\b|\bAGENTS\.md\b|\brepo[- ]agent\b"
)
ANTHROPOLOGY_PURPOSE_PATTERN = re.compile(
    r"(?i)\b(purpose|what this repo is|what this repo does|mission|charter|reason this repo exists)\b"
)
ANTHROPOLOGY_DELIVERABLE_PATTERN = re.compile(
    r"(?i)\b(use[- ]case|use cases|deliverable|primary output|primary deliverable|consumers?|who uses)\b"
)
ANTHROPOLOGY_PRINCIPLE_DUALITY_PATTERN = re.compile(
    r"(?i)("
    r"revealed[- ]vs[- ]defined principle|"
    r"revealed principle.{0,80}defined principle|"
    r"defined principle.{0,80}revealed principle|"
    r"revealed[- ]principle"
    r")"
)
ANTHROPOLOGY_NAMED_SURFACE_PATTERN = re.compile(
    r"(?i)(repo[- ]anthropology|repository anthropology|anthropology (?:surface|record|note))"
)


def missing_repo_anthropology_surface(texts: dict[str, str]) -> dict[str, Any]:
    """AS-52: a repo-agent under assimilation that never produced a repo-anthropology
    surface -- a single record of purpose, use-cases/deliverables, and the
    defined-vs-revealed principle duality -- before repairs were selected."""
    owner = owner_evidence_texts(texts)

    context_files = [
        path
        for path, text in owner.items()
        if path.endswith("constitution.md")
        or path.endswith("AGENTS.md")
        or "/memory/constitution" in path
        or ANTHROPOLOGY_CONTEXT_PATTERN.search(text)
    ]
    anthropology_files = [
        path
        for path, text in owner.items()
        if ANTHROPOLOGY_NAMED_SURFACE_PATTERN.search(text)
        or (
            ANTHROPOLOGY_PURPOSE_PATTERN.search(text)
            and ANTHROPOLOGY_DELIVERABLE_PATTERN.search(text)
            and ANTHROPOLOGY_PRINCIPLE_DUALITY_PATTERN.search(text)
        )
    ]

    assimilation_context = bool(context_files)
    anthropology_present = bool(anthropology_files)
    fired = assimilation_context and not anthropology_present

    details = [
        f"assimilation_context=>{','.join(context_files[:3]) or 'none'}",
        f"anthropology_surface=>{','.join(anthropology_files[:3]) or 'none'}",
    ]
    return {
        "fired": fired,
        "signals": {
            "assimilation_context_present": assimilation_context,
            "repo_anthropology_surface_present": anthropology_present,
            "missing_repo_anthropology_surface_count": 1 if fired else 0,
        },
        "evidence": evidence_join(details),
        "reason": (
            "repo-agent context exists but no repo-anthropology surface (purpose + use-cases/deliverables + defined-vs-revealed principles) was found"
            if fired
            else "a repo-anthropology surface is present, or this is not a repo-agent assimilation context"
        ),
    }


MATURITY_OVERCLAIM_PATTERN = re.compile(
    r"(?i)("
    r"fully autonomous|"
    r"production[- ]ready|"
    r"proven (?:domain )?capability|"
    r"proves (?:domain |live cloud )|"
    r"domain autonomy|"
    r"improved runtime autonomy|"
    r"end[- ]to[- ]end autonomous|"
    r"autonomous[^.\n]{0,40}from issue[^.\n]{0,40}(?:to )?(?:pr |pull request |)merge|"
    r"complete autonomy"
    r")"
)
MATURITY_QUALIFIER_PATTERN = re.compile(
    r"(?i)("
    r"bounded non[- ]claim|"
    r"does not (?:prove|claim)|"
    r"not (?:yet )?(?:domain|production)|"
    r"operating[- ]model (?:progress|maturity|capability)|"
    r"readiness[^.\n]{0,30}(?:not|vs)[^.\n]{0,30}capability|"
    r"maturity[- ](?:boundary|class)|"
    r"\bn=\d"
    r")"
)


def maturity_boundary_claim_overreach(texts: dict[str, str]) -> dict[str, Any]:
    """AS-53: an owner surface that claims domain capability or autonomy while only
    operating-model progress, readiness, or validation legibility has been proven,
    with no co-located maturity-class qualifier or bounded non-claim."""
    offenders: list[str] = []
    grounded: list[str] = []

    for path, text in owner_evidence_texts(texts).items():
        if path.startswith("scripts/") or path.startswith("detection-signatures/"):
            continue
        if is_work_management_signature_explainer(path, text):
            grounded.append(path)
            continue
        if not MATURITY_OVERCLAIM_PATTERN.search(text):
            continue
        if MATURITY_QUALIFIER_PATTERN.search(text):
            grounded.append(path)
            continue
        offenders.append(f"{path}=>maturity_overclaim_without_qualifier")

    details = [
        f"maturity_boundary_overclaim=>{';'.join(offenders[:4]) or 'none'}",
        f"maturity_class_grounded=>{','.join(grounded[:4]) or 'none'}",
    ]
    return {
        "fired": bool(offenders),
        "signals": {
            "maturity_boundary_claim_overreach_count": len(offenders),
            "maturity_class_grounded_count": len(grounded),
        },
        "evidence": evidence_join(details),
        "reason": (
            "a domain-capability/autonomy claim lacks a co-located maturity-class qualifier or bounded non-claim"
            if offenders
            else "maturity claims are class-qualified or absent"
        ),
    }


AS_FRICTION_SURFACE_SUFFIXES = (".md", ".txt", ".json", ".jsonl", ".csv", ".yml", ".yaml")

CLOSURE_SIGNAL_CONTEXT_PATTERN = re.compile(
    r"(?i)\b(work[- ]?close(?:\.sh)?|closeout|closure (?:gate|run|contract)|"
    r"score[- ]session|post[- ]audit|audit[- ]post|scorecard|scorer)\b"
)
CLOSURE_SIGNAL_SUCCESS_PATTERN = re.compile(
    r"(?i)("
    r"\bwork[- ]?close(?:\.sh)?\b[^.\n]{0,120}\b(?:exit(?:ed|s)?|return(?:ed|s)?|status|rc)\s*[:=]?\s*0\b|"
    r"\b(?:exit(?:ed|s)?|return(?:ed|s)?|status|rc)\s*[:=]?\s*0\b[^.\n]{0,120}\bwork[- ]?close(?:\.sh)?\b|"
    r"\bclosure\b[^.\n]{0,80}\b(?:exit(?:ed|s)?|return(?:ed|s)?|status)\s*[:=]?\s*0\b|"
    # Structural fallback when no literal exit code is logged: a checked
    # markdown task-list item is a measured (checkbox), not prose, success
    # marker; a generic completion verb anchored to the established
    # work-close command name is a small, fixed verb set, not a tp-specific
    # phrase.
    r"\[x\][^.\n]{0,40}\bwork[- ]?close(?:\.sh)?\b|"
    r"\bwork[- ]?close(?:\.sh)?\b[^.\n]{0,40}\[x\]|"
    r"\bwork[- ]?close(?:\.sh)?\b[^.\n]{0,80}\b(?:completed?|succeeded|finished)\b|"
    r"\b(?:completed?|succeeded|finished)\b[^.\n]{0,80}\bwork[- ]?close(?:\.sh)?\b"
    r")"
)
CLOSURE_SIGNAL_DEGRADED_PATTERN = re.compile(
    r"(?i)("
    r"integer[- ]expression (?:expected|error)|"
    r"post[- ]audit[^.\n]{0,80}\b(?:unavailable|missing|partial|degraded)\b|"
    r"audit[- ]post[^.\n]{0,80}\b(?:unavailable|missing|partial|degraded)\b|"
    r"\bPARTIAL\b[^.\n]{0,80}\bscorecard\b|"
    r"\bscorecard\b[^.\n]{0,80}\bPARTIAL\b|"
    r"\bscorer\b[^.\n]{0,80}\b(?:unavailable|missing|partial|degraded)\b|"
    r"degraded[^.\n]{0,80}\b(?:post[- ]audit|scorecard|scorer)\b"
    r")"
)
CLOSURE_SIGNAL_NEGATION_PATTERN = re.compile(
    r"(?i)\b(no|not|never|without|absent|clean|healthy|green|avoids?|prevent(?:s|ed)?)\b"
)

CURRENT_STATE_OVERSIZED_CHAR_THRESHOLD = 16000
# Note: "timeout override" is an explicit alternative (not just "review
# timeout") because REVIEW_TIMEOUT_OVERRIDE_PATTERN below tolerates review and
# timeout being up to 80 chars apart in either order -- without this anchor a
# file discussing e.g. "the review needed a timeout override" (the words not
# immediately adjacent) would match the corroboration pattern but fail this
# admission gate first, a false negative. The bare "review" token stays
# excluded (removed deliberately -- see below) since it was the original
# cause of the glossary/path-map false catch.
REVIEW_ERGONOMICS_CONTEXT_PATTERN = re.compile(
    r"(?i)\b(CURRENT_STATE\.md|current state|working[- ]memory|make review|local review|"
    r"review timeout|review ergonomics|timeout override)\b"
)
REVIEW_TIMEOUT_OVERRIDE_PATTERN = re.compile(
    r"(?i)\b(review timeout override|review[^.\n]{0,80}\btimeout\b|timeout[^.\n]{0,80}\breview)\b"
)
# Branches 1/2 require an actual size/bloat complaint word co-located with
# CURRENT_STATE.md. "working[- ]memory" is deliberately NOT in that keyword
# set: it is the neutral name of the file's role (see e.g. a glossary/path-map
# table row like "| Working memory | `CURRENT_STATE.md` |"), not an assertion
# that the file is oversized. Branch 3 still requires "working memory" to be
# paired with a genuine overload/pressure word. Branches 4/5 require the full
# "timeout override" phrase next to "review", not a bare co-mention. Together
# these keyword-tightenings are enough on their own to keep a glossary/
# path-map row (which never contains any of these complaint words) from
# matching, without needing a separate table-row structural negation.
REVIEW_WORKING_MEMORY_OVERLOAD_PATTERN = re.compile(
    r"(?i)("
    r"\bCURRENT_STATE\.md\b[^.\n]{0,120}\b(?:oversized|too large|bloated|bloat|timeout)\b|"
    r"\b(?:oversized|too large|bloated|bloat|timeout)\b[^.\n]{0,120}\bCURRENT_STATE\.md\b|"
    r"\bworking[- ]memory\b[^.\n]{0,80}\b(?:overload|pressure|drag|friction|bloat|too large|oversized)\b|"
    r"\breview\b[^.\n]{0,80}\btimeout override\b|"
    r"\btimeout override\b[^.\n]{0,80}\breview\b"
    r")"
)
REVIEW_ERGONOMICS_NEGATION_PATTERN = re.compile(
    r"(?i)\b(no|not|never|without|absent|small|bounded|clean|normal|avoids?|prevent(?:s|ed)?)\b"
)

CLOSURE_EXTERNAL_COUPLING_CONTEXT_PATTERN = re.compile(
    r"(?i)\b(work[- ]?close(?:\.sh)?|closeout|closure (?:gate|run|contract|script)|"
    r"post[- ]audit|audit[- ]post|score[- ]session|scorecard|scorer)\b"
)
CLOSURE_EXTERNAL_OPERATION_PATH_PATTERN = re.compile(
    r"(?i)(^|/)(?:work[-_]close|closeout|closure|score[-_]session|post[-_]audit|audit[-_]post)[^/]*\.(?:sh|py)$"
)
CLOSURE_EXTERNAL_REPO_PATH_PATTERN = re.compile(
    r"(?i)(?:"
    r"(?:\$HOME|\$\{HOME\}|~)/(?:repos?|src|code|workspaces?)/[A-Za-z0-9_.-]+(?:/[A-Za-z0-9_.-]+)*|"
    r"/(?:Users|home)/[^\s\"'`$()]+/(?:repos?|src|code|workspaces?)/[A-Za-z0-9_.-]+(?:/[A-Za-z0-9_.-]+)*"
    r")"
)
CLOSURE_EXTERNAL_COUPLING_NEGATION_PATTERN = re.compile(
    r"(?i)\b(no|not|never|without|avoid(?:s|ed)?|forbid(?:s|den)?|must not|should not|"
    r"advisory|opt[- ]in|not required|never required)\b"
)


def _unnegated_line_match_count(
    text: str, pattern: re.Pattern[str], negation_pattern: re.Pattern[str]
) -> int:
    return sum(
        1
        for line in text.splitlines()
        if pattern.search(line) and not negation_pattern.search(line)
    )


def _skip_friction_detector_surface(path: str, text: str) -> bool:
    if path.startswith("scripts/") or path.startswith("detection-signatures/"):
        return True
    if not path.endswith(AS_FRICTION_SURFACE_SUFFIXES):
        return True
    return is_work_management_signature_explainer(path, text)


def _is_closure_external_coupling_surface(path: str, text: str) -> bool:
    if path.startswith("detection-signatures/"):
        return False
    if is_work_management_signature_explainer(path, text):
        return False
    if path.startswith("scripts/"):
        return bool(CLOSURE_EXTERNAL_OPERATION_PATH_PATTERN.search(path))
    return bool(
        CLOSURE_EXTERNAL_OPERATION_PATH_PATTERN.search(path)
        or CLOSURE_EXTERNAL_COUPLING_CONTEXT_PATTERN.search(text)
    )


def _external_closure_path_reason(line: str) -> str | None:
    if CLOSURE_EXTERNAL_COUPLING_NEGATION_PATTERN.search(line):
        return None
    if CLOSURE_EXTERNAL_REPO_PATH_PATTERN.search(line):
        return "external_repo_path"
    return None


def closure_signal_integrity(texts: dict[str, str]) -> dict[str, Any]:
    """AS-54: work-close reports a successful closeout while retained post-audit
    or scorecard evidence is unavailable, partial, or degraded."""
    offenders: list[str] = []
    grounded: list[str] = []
    closure_success_surfaces = 0
    degraded_signal_surfaces = 0

    for path, text in owner_evidence_texts(texts).items():
        if _skip_friction_detector_surface(path, text):
            continue
        if not CLOSURE_SIGNAL_CONTEXT_PATTERN.search(text):
            continue

        success_count = _unnegated_line_match_count(
            text, CLOSURE_SIGNAL_SUCCESS_PATTERN, CLOSURE_SIGNAL_NEGATION_PATTERN
        )
        degraded_count = _unnegated_line_match_count(
            text, CLOSURE_SIGNAL_DEGRADED_PATTERN, CLOSURE_SIGNAL_NEGATION_PATTERN
        )

        if success_count:
            closure_success_surfaces += 1
        if degraded_count:
            degraded_signal_surfaces += 1

        if success_count and degraded_count:
            offenders.append(
                f"{path}=>successful_closeout_with_degraded_post_audit_signal"
            )
        else:
            grounded.append(path)

    details = [
        f"closure_signal_integrity_gap=>{';'.join(offenders[:4]) or 'none'}",
        f"closure_signal_grounded=>{','.join(sorted(set(grounded))[:4]) or 'none'}",
    ]
    return {
        "fired": bool(offenders),
        "signals": {
            "closure_signal_integrity_gap_count": len(offenders),
            "closure_success_surface_count": closure_success_surfaces,
            "degraded_closure_signal_surface_count": degraded_signal_surfaces,
            "closure_signal_grounded_count": len(set(grounded)),
        },
        "evidence": evidence_join(details),
        "reason": (
            "successful work-close/closure evidence coexists with degraded post-audit, scorer, or PARTIAL scorecard evidence"
            if offenders
            else "closure success evidence is absent, or post-audit/scorer signals are clean or negated"
        ),
    }


def review_ergonomics_working_memory_lightness(texts: dict[str, str]) -> dict[str, Any]:
    """AS-55: review ergonomics are degraded by oversized CURRENT_STATE.md or
    review-timeout override pressure on working memory.

    The measured file-size signal (oversized_current_state_file) is the
    primary, structural basis for firing. Keyword-proximity matches
    (review_timeout_override, working_memory_overload) are corroboration:
    they require an actual complaint word (oversized/too large/bloated/
    overload/pressure/etc.) co-located with CURRENT_STATE.md or "working
    memory", so a glossary/path-map row that merely names the file next to
    its label never matches (see REVIEW_WORKING_MEMORY_OVERLOAD_PATTERN)."""
    offenders: list[str] = []
    grounded: list[str] = []
    current_state_files = 0
    oversized_current_state_files = 0
    timeout_override_surfaces = 0
    working_memory_overload_surfaces = 0

    for path, text in owner_evidence_texts(texts).items():
        if _skip_friction_detector_surface(path, text):
            continue

        is_current_state_file = is_declared_working_memory_doc(path)
        if is_current_state_file:
            current_state_files += 1

        has_context = is_current_state_file or REVIEW_ERGONOMICS_CONTEXT_PATTERN.search(text)
        if not has_context:
            continue

        oversized_file = is_current_state_file and len(text) >= CURRENT_STATE_OVERSIZED_CHAR_THRESHOLD
        timeout_count = _unnegated_line_match_count(
            text, REVIEW_TIMEOUT_OVERRIDE_PATTERN, REVIEW_ERGONOMICS_NEGATION_PATTERN
        )
        overload_count = _unnegated_line_match_count(
            text, REVIEW_WORKING_MEMORY_OVERLOAD_PATTERN, REVIEW_ERGONOMICS_NEGATION_PATTERN
        )

        if oversized_file:
            oversized_current_state_files += 1
        if timeout_count:
            timeout_override_surfaces += 1
        if overload_count:
            working_memory_overload_surfaces += 1

        # Primary signal first: the measured oversize check is the detector's
        # structural basis for firing. Keyword matches are appended as
        # corroboration only.
        reasons: list[str] = []
        if oversized_file:
            reasons.append("oversized_current_state_file")
        if timeout_count:
            reasons.append("review_timeout_override")
        if overload_count:
            reasons.append("working_memory_overload")

        if reasons:
            offenders.append(f"{path}=>{';'.join(reasons[:4])}")
        else:
            grounded.append(path)

    details = [
        f"review_ergonomics_working_memory_gap=>{';'.join(offenders[:4]) or 'none'}",
        f"review_ergonomics_grounded=>{','.join(sorted(set(grounded))[:4]) or 'none'}",
    ]
    fire_disposition = (
        "measured_oversize"
        if oversized_current_state_files
        else ("corroboration_only" if offenders else "not_fired")
    )
    return {
        "fired": bool(offenders),
        "signals": {
            "review_ergonomics_working_memory_lightness_count": len(offenders),
            "current_state_file_count": current_state_files,
            "oversized_current_state_file_count": oversized_current_state_files,
            "review_timeout_override_surface_count": timeout_override_surfaces,
            "working_memory_overload_surface_count": working_memory_overload_surfaces,
            "current_state_oversize_threshold_chars": CURRENT_STATE_OVERSIZED_CHAR_THRESHOLD,
            "fire_disposition": fire_disposition,
        },
        "evidence": evidence_join(details),
        "reason": (
            "review ergonomics show oversized CURRENT_STATE.md (primary, measured signal)"
            if oversized_current_state_files
            else (
                "review ergonomics show working-memory overload or review-timeout override pressure "
                "(corroborating prose signal; no oversized CURRENT_STATE.md was measured)"
                if offenders
                else "CURRENT_STATE.md/review working-memory pressure is absent, bounded, or negated"
            )
        ),
    }


def external_closure_coupling(texts: dict[str, str]) -> dict[str, Any]:
    """AS-56: default closure gate reaches into a sibling/local repo path."""
    offenders: list[str] = []
    grounded: list[str] = []
    closure_surfaces = 0
    external_path_surfaces = 0

    for path, text in owner_evidence_texts(texts).items():
        if not _is_closure_external_coupling_surface(path, text):
            continue

        closure_surfaces += 1
        reasons = sorted(
            {
                reason
                for line in text.splitlines()
                if (reason := _external_closure_path_reason(line)) is not None
            }
        )
        if reasons:
            external_path_surfaces += 1
            offenders.append(f"{path}=>{';'.join(reasons)}")
        else:
            grounded.append(path)

    details = [
        f"external_closure_coupling=>{';'.join(offenders[:4]) or 'none'}",
        f"external_closure_grounded=>{','.join(sorted(set(grounded))[:4]) or 'none'}",
    ]
    return {
        "fired": bool(offenders),
        "signals": {
            "external_closure_coupling_count": len(offenders),
            "external_repo_path_surface_count": external_path_surfaces,
            "closure_surface_count": closure_surfaces,
        },
        "evidence": evidence_join(details),
        "reason": (
            "closure gate hard-depends on an external repo path (should be opt-in / advisory, not in the default closure gate)"
            if offenders
            else "default closure surfaces are self-contained, advisory-only, absent, or negated"
        ),
    }


# AS-57 native-evidence-before-verdict patterns. The detector fires when a
# verdict-bearing surface decides adoption/readiness/fallback/production/GA/
# cutover/architecture from docs-readback or substitute proof, without a native
# attempt or a concrete owner-surface blocker. See repo-agent-core
# docs/native-evidence-before-verdict-contract.md.
NATIVE_EVIDENCE_CONTRACT_REF = (
    "repo-agent-core/docs/native-evidence-before-verdict-contract.md"
)
NATIVE_EVIDENCE_CONTEXT_PATTERN = re.compile(
    r"(?i)\b(upstream|native[- ]evidence[- ]before[- ]verdict|native (?:setup|use|"
    r"model|command|run|attempt|capability|tool)|adopt\w*|GBrain|Hermes|"
    r"external (?:system|tool|library|product|dependency|capability)|third[- ]party|"
    r"install_for_agents|production[- ]readi\w*|readiness (?:verdict|decision)|"
    r"go[- ]live|cutover)\b"
)
NATIVE_EVIDENCE_POSITIVE_VERDICT_PATTERN = re.compile(
    r"(?i)\b(production[- ]ready|ready for production|production readiness|"
    r"adopt(?:ed|ion|able|s)?|adoption[- ]ready|safe to adopt|"
    r"generally available|\bGA\b|cutover|go[- ]live|greenlight|green[- ]light|"
    r"ready to (?:adopt|ship|roll ?out|productionize))\b"
)
NATIVE_EVIDENCE_NEGATIVE_VERDICT_PATTERN = re.compile(
    r"(?i)\b(not production[- ]ready|not ready for production|not[- ]GA|not GA\b|"
    r"not generally available|fallback (?:required|is required|needed|route|only)|"
    r"hybrid fallback|adoption (?:blocked|is blocked)|blocked adoption|"
    r"not safe to adopt|not adoptable|adoption[- ]blocked)\b"
)
# A "no verdict / no decision" disclaimer means the surface explicitly declines
# to decide; it is orientation, not a verdict. This is intentionally narrow so
# that a negative verdict such as "not production-ready" is still a verdict.
NATIVE_EVIDENCE_VERDICT_DISCLAIMER_PATTERN = re.compile(
    r"(?i)("
    r"\b(?:no|not|without|never)\s+(?:\w+[\s,]+){0,4}?(?:verdict|decision|"
    r"judg?ment|call|conclusion)\b|"
    r"\bmakes?\s+no\b|\bdo(?:es)?\s+not\s+(?:make|decide|conclude|judge|claim)\b|"
    r"\bdefer(?:s|red|ring)?\b|\bsupport but do(?:es)? not decide\b|"
    r"\bonly to support\b|\bnecessary but not sufficient\b)"
)
NATIVE_EVIDENCE_SUBSTITUTE_PROOF_PATTERN = re.compile(
    r"(?i)\b(read(?:ing)? (?:the )?(?:docs|documentation|readme|agents|manual)|"
    r"docs? readback|based on (?:the )?(?:docs|documentation|readme)|"
    r"per the (?:docs|readme|documentation)|the docs are clear|README|AGENTS\.md|"
    r"install_for_agents|local doctor|doctor output|local tests?|"
    r"retained (?:report|validation|receipt|evidence)|model summary|"
    r"prompt contract|validation receipt|documentation (?:says|shows|confirms)|"
    r"rests on the docs)\b"
)
# Affirmative native execution / real result evidence. Counted per-line and
# suppressed by negation so "did not run"/"no native command was executed" does
# not count as an attempt.
NATIVE_EVIDENCE_NATIVE_ATTEMPT_PATTERN = re.compile(
    r"(?i)\b(ran|executed|invoked|installed and ran|successfully ran|actually ran|"
    r"native run (?:succeeded|passed|completed|shows)|"
    r"working native (?:run|attempt)|real command output|command output:|"
    r"output (?:was|shows|showed|confirms)|reproduced (?:it )?(?:with|via|by running)|"
    r"smoke (?:passed|ran)|native attempt (?:succeeded|passed|completed)|"
    r"verified by running)\b"
)
# Affirmative owner-surface blocker that stops before unsafe/unauthorized native
# execution and routes the next step to the owner. Counted per-line and
# suppressed by negation so "no owner-surface blocker" does not count.
NATIVE_EVIDENCE_OWNER_BLOCKER_PATTERN = re.compile(
    r"(?i)\b(owner[- ]surface blocker|blocker (?:routed|filed|raised|was filed)|"
    r"routed to (?:the )?owner|filed (?:an? )?(?:issue|blocker) to|owner (?:issue|repo|surface)|"
    r"blocked by|cannot (?:run|execute)|could not (?:safely )?run|"
    r"unsafe to (?:run|execute)|unauthorized (?:production|native)|"
    r"requires? (?:approval|credentials|permission)|permission denied|"
    r"stopped before (?:the )?native|before unsafe (?:native )?execution|"
    r"upstream (?:bug|issue)|awaiting owner|needs owner)\b"
)
NATIVE_EVIDENCE_NEGATION_PATTERN = re.compile(
    r"(?i)\b(no|not|never|without|did not|didn't|does not|doesn't|do not|don't|"
    r"have not|haven't|has not|hasn't|unable to|could not|couldn't|"
    r"cannot|can't|won't|skipped|nor)\b"
)


def _native_evidence_verdict_line_count(text: str) -> int:
    """Affirmative verdict lines: positive/negative verdict claims that are not
    part of an explicit no-verdict/no-decision disclaimer."""
    count = 0
    for line in text.splitlines():
        if NATIVE_EVIDENCE_VERDICT_DISCLAIMER_PATTERN.search(line):
            continue
        if NATIVE_EVIDENCE_POSITIVE_VERDICT_PATTERN.search(
            line
        ) or NATIVE_EVIDENCE_NEGATIVE_VERDICT_PATTERN.search(line):
            count += 1
    return count


def native_evidence_before_verdict(texts: dict[str, str]) -> dict[str, Any]:
    """AS-57: a verdict-bearing surface decides adoption/readiness/fallback/
    production/GA/cutover/architecture from docs-readback or substitute proof,
    without a native attempt or a concrete owner-surface blocker."""
    offenders: list[str] = []
    grounded: list[str] = []
    verdict_surfaces = 0
    substitute_proof_surfaces = 0
    native_or_blocker_surfaces = 0

    for path, text in owner_evidence_texts(texts).items():
        if _skip_friction_detector_surface(path, text):
            continue
        if not NATIVE_EVIDENCE_CONTEXT_PATTERN.search(text):
            continue

        verdict_count = _native_evidence_verdict_line_count(text)
        if not verdict_count:
            continue
        verdict_surfaces += 1

        has_substitute_proof = bool(
            NATIVE_EVIDENCE_SUBSTITUTE_PROOF_PATTERN.search(text)
        )
        if has_substitute_proof:
            substitute_proof_surfaces += 1

        native_attempt_count = _unnegated_line_match_count(
            text, NATIVE_EVIDENCE_NATIVE_ATTEMPT_PATTERN, NATIVE_EVIDENCE_NEGATION_PATTERN
        )
        owner_blocker_count = _unnegated_line_match_count(
            text, NATIVE_EVIDENCE_OWNER_BLOCKER_PATTERN, NATIVE_EVIDENCE_NEGATION_PATTERN
        )
        has_native_or_blocker = bool(native_attempt_count or owner_blocker_count)
        if has_native_or_blocker:
            native_or_blocker_surfaces += 1

        if has_substitute_proof and not has_native_or_blocker:
            offenders.append(f"{path}=>docs_readback_only_verdict")
        else:
            grounded.append(path)

    details = [
        f"native_evidence_before_verdict=>{';'.join(offenders[:4]) or 'none'}",
        f"native_evidence_grounded=>{','.join(sorted(set(grounded))[:4]) or 'none'}",
        f"contract_ref=>{NATIVE_EVIDENCE_CONTRACT_REF}",
    ]
    return {
        "fired": bool(offenders),
        "signals": {
            "native_evidence_before_verdict_count": len(offenders),
            "verdict_surface_count": verdict_surfaces,
            "substitute_proof_surface_count": substitute_proof_surfaces,
            "native_attempt_or_blocker_surface_count": native_or_blocker_surfaces,
            "contract_ref": NATIVE_EVIDENCE_CONTRACT_REF,
        },
        "evidence": evidence_join(details),
        "reason": (
            "verdict-bearing surface decides adoption/readiness/fallback from "
            "docs-readback or substitute proof without a native attempt or a "
            "concrete owner-surface blocker; require a native attempt or route "
            "the blocker to the owner surface per "
            f"{NATIVE_EVIDENCE_CONTRACT_REF}"
            if offenders
            else "verdict surfaces carry a native attempt or owner-surface "
            "blocker, make no adoption/readiness/fallback verdict, or are absent"
        ),
    }


EVALUATORS = {
    "AS-01": instruction_root_drift,
    "AS-02": docs_vs_observed_host_drift,
    "AS-03": missing_runtime_heartbeat,
    "AS-04": validator_live_path_gap,
    "AS-05": memory_authority_confusion,
    "AS-06": prompt_only_optimization_surface,
    "AS-07": unused_platform_surface,
    "AS-08": external_critique_health,
    "AS-09": cost_without_token_fields,
    "AS-10": cost_model_mismatch,
    "AS-11": request_tool_amplification_gap,
    "AS-12": pricing_provenance_gap,
    "AS-13": copied_evidence_boundary_gap,
    "AS-14": unauthorized_production_default_enablement,
    "AS-15": missing_rollback_control_proof,
    "AS-16": aggregate_only_readiness,
    "AS-17": stale_direct_token_evidence,
    "AS-18": forbidden_public_customernewsletter_mutation,
    "AS-19": source_intelligence_intake_gap,
    "AS-20": selection_handback_recommendation,
    "AS-21": too_small_goal_mode_episode,
    "AS-22": github_native_closure_regrowth,
    "AS-23": owner_surface_ambiguity,
    "AS-24": reciprocal_proving_ground_gap,
    "AS-25": goal_runtime_evidence_gap,
    "AS-26": reactive_self_healing_loop,
    "AS-27": shell_reserved_status_variable,
    "AS-28": stale_default_capability_guidance,
    "AS-29": hermes_foreground_receipt_adoption_gap,
    "AS-30": interrupted_goal_recovery_gap,
    "AS-31": fractured_serial_continuation,
    "AS-32": unanchored_self_learning_claim,
    "AS-33": foreground_failure_guidance_gap,
    "AS-34": closure_run_identity_gap,
    "AS-35": upstream_capability_intake_gap,
    "AS-36": gbrain_instruction_distribution_overclaim,
    "AS-37": issue164_runtime_drift,
    "AS-38": self_authored_campaign_pause_authority,
    "AS-39": scheduled_evidence_boundary_gap,
    "AS-40": hermes_github_reliability_boundary_gap,
    "AS-41": campaign_sync_completed_track_readback_gap,
    "AS-42": route_changing_learning_propagation_gap,
    "AS-43": capability_placement_gap,
    "AS-44": hermes_foreground_reliability_evidence_gap,
    "AS-45": codex_native_runtime_readiness_evidence_gap,
    "AS-46": deep_research_source_intelligence_native_corpus_gap,
    "AS-47": integrated_native_acceptance_gap,
    "AS-48": standalone_external_intelligence_sidecar_gap,
    "AS-49": scheduled_readback_owner_proof_gap,
    "AS-50": hermes_foreground_failure_disposition_gap,
    "AS-51": missing_operating_model_alignment_anchor,
    "AS-52": missing_repo_anthropology_surface,
    "AS-53": maturity_boundary_claim_overreach,
    "AS-54": closure_signal_integrity,
    "AS-55": review_ergonomics_working_memory_lightness,
    "AS-56": external_closure_coupling,
    "AS-57": native_evidence_before_verdict,
}


def main() -> int:
    signature_id, repo = parse_args()
    signature = SIGNATURES.get(signature_id)
    evaluator = EVALUATORS.get(signature_id)
    if signature is None or evaluator is None:
        print(json.dumps({"error": "unknown_signature", "signature_id": signature_id}))
        return 1
    if not repo.is_dir():
        print(json.dumps({"error": "repo_not_found", "signature_id": signature_id}))
        return 1

    text_scan = load_text_scan(repo)
    texts = text_scan.texts
    result = evaluator(texts)
    payload = {
        "ds_id": signature_id,
        "family": "AS",
        "name": signature["name"],
        "severity": signature["severity"],
        "prevention_tier": signature["prevention_tier"],
        "script": signature["script"],
        "fired": bool(result.get("fired")),
        "signals": result.get("signals", {}),
        "evidence": result.get("evidence", ""),
        "reason": result.get("reason", ""),
        "scanned_files": len(texts),
        "eligible_files": text_scan.eligible_files,
        "scan_limit": text_scan.scan_limit,
        "scan_limited": text_scan.scan_limited,
        "scan_order_note": text_scan.scan_order_note,
    }
    print(json.dumps(payload, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
