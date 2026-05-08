#!/usr/bin/env python3
"""Add primary-surface and full-facts inventory receipts to audit outputs."""

from __future__ import annotations

import argparse
import fnmatch
import json
import os
from pathlib import Path
from typing import Any


RECEIPT_VERSION = "1.0.0"
PATH_LIMIT = 50
DEFAULT_MAX_FILES_SCANNED = 200
DEFAULT_PRUNED_DIRS = {
    ".git",
    ".venv",
    "venv",
    "node_modules",
    ".tox",
    ".mypy_cache",
    "__pycache__",
    "vendor",
    ".eggs",
}
DEFAULT_EXCLUDED_FILES = {".DS_Store"}

PRIMARY_PATTERNS: dict[str, tuple[str, ...]] = {
    "instruction_roots": (
        "AGENTS.md",
        "CLAUDE.md",
        "CODEX.md",
        "GEMINI.md",
        ".copilot-instructions.md",
        ".github/copilot-instructions.md",
        ".github/instructions/*.instructions.md",
        ".cursor/rules/*",
        ".cursorrules",
        ".windsurfrules",
    ),
    "agent_definitions": (
        ".agents/*.agent.md",
        ".agents/**/*.agent.md",
        ".github/agents/*.md",
    ),
    "skill_definitions": (
        ".agents/skills/*/SKILL.md",
        ".agents/skills/**/SKILL.md",
    ),
    "governance_and_specs": (
        ".specify/memory/constitution.md",
        "specs/*/spec.md",
        "specs/*/plan.md",
        "specs/*/tasks.md",
        "FLYWHEEL.md",
        "HYPOTHESES.md",
        "LEARNINGS.md",
    ),
    "validation_surfaces": (
        "Makefile",
        "scripts/check.sh",
        "scripts/validate*.sh",
        "tests/test-*.sh",
    ),
    "workflow_surfaces": (
        ".github/workflows/*.yml",
        ".github/workflows/*.yaml",
        ".github/actions/**",
    ),
}


def load_json(path: Path) -> dict[str, Any]:
    with path.open() as fh:
        data = json.load(fh)
    if not isinstance(data, dict):
        raise ValueError(f"{path} must contain a JSON object")
    return data


def write_json(path: Path, data: dict[str, Any]) -> None:
    path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n")


def relpath(path: Path, root: Path) -> str:
    return path.relative_to(root).as_posix()


def load_auditorignore(root: Path) -> list[str]:
    path = root / ".auditorignore"
    if not path.is_file():
        return []
    entries: list[str] = []
    for raw in path.read_text(errors="replace").splitlines():
        stripped = raw.strip()
        if stripped and not stripped.startswith("#"):
            entries.append(stripped)
    return entries


def ignored_by_auditorignore(rel: str, entries: list[str]) -> bool:
    for entry in entries:
        normalized = entry.strip("/")
        if not normalized:
            continue
        if entry.endswith("/") and (rel == normalized or rel.startswith(f"{normalized}/")):
            return True
        if rel == normalized or fnmatch.fnmatch(rel, normalized):
            return True
        if "/" not in normalized and normalized in rel.split("/"):
            return True
    return False


def should_skip_dir(rel: str, entries: list[str]) -> bool:
    name = rel.rsplit("/", 1)[-1]
    if name in DEFAULT_PRUNED_DIRS:
        return True
    return ignored_by_auditorignore(rel, entries)


def should_skip_file(rel: str, entries: list[str]) -> bool:
    name = rel.rsplit("/", 1)[-1]
    if name in DEFAULT_EXCLUDED_FILES:
        return True
    return ignored_by_auditorignore(rel, entries)


def match_any(rel: str, patterns: tuple[str, ...]) -> bool:
    return any(fnmatch.fnmatch(rel, pattern) for pattern in patterns)


def bounded_paths(paths: list[str]) -> dict[str, Any]:
    ordered = sorted(set(paths))
    return {
        "count": len(ordered),
        "paths_emitted": True,
        "path_limit": PATH_LIMIT,
        "paths": ordered[:PATH_LIMIT],
        "omitted_path_count": max(0, len(ordered) - PATH_LIMIT),
    }


def classify_fact(rel: str) -> str:
    suffix = Path(rel).suffix.lower()
    parts = rel.split("/")
    first = parts[0] if parts else rel

    if match_any(rel, tuple(pattern for patterns in PRIMARY_PATTERNS.values() for pattern in patterns)):
        return "primary_surface"
    if first in {"docs", "documentation"} or suffix in {".md", ".rst", ".txt"}:
        return "documentation"
    if first == "research":
        return "research"
    if first == "specs":
        return "specs"
    if first == "tests" or rel.startswith("test/") or "test" in Path(rel).stem.lower():
        return "tests"
    if first in {"work", "runs", "workspace"}:
        return "retained_runtime_evidence"
    if first in {"data", "schemas", "fixtures"} or suffix in {".json", ".jsonl", ".yaml", ".yml", ".csv"}:
        return "structured_data"
    if suffix in {".py", ".sh", ".js", ".ts", ".tsx", ".go", ".rs", ".rb", ".java"}:
        return "source_code"
    if suffix in {".toml", ".ini", ".cfg", ".conf", ".env", ".lock"} or first in {".github", ".config"}:
        return "configuration"
    return "other"


def scan_target(root: Path, output_dir: Path, max_files_scanned: int) -> tuple[dict[str, Any], dict[str, Any]]:
    auditorignore_entries = load_auditorignore(root)
    output_dir_resolved = output_dir.resolve()
    primary: dict[str, list[str]] = {name: [] for name in PRIMARY_PATTERNS}
    fact_counts: dict[str, int] = {}
    scanned_files = 0
    skipped_files = 0
    limit_reached = False

    for current, dirs, files in os.walk(root):
        if limit_reached:
            break
        current_path = Path(current)
        if current_path.resolve() == output_dir_resolved:
            dirs[:] = []
            continue
        rel_current = "" if current_path == root else relpath(current_path, root)
        dirs.sort()
        files.sort()
        kept_dirs = []
        for dirname in dirs:
            if (current_path / dirname).resolve() == output_dir_resolved:
                continue
            dir_rel = f"{rel_current}/{dirname}".strip("/")
            if should_skip_dir(dir_rel, auditorignore_entries):
                continue
            kept_dirs.append(dirname)
        dirs[:] = kept_dirs

        for filename in files:
            if scanned_files >= max_files_scanned:
                limit_reached = True
                dirs[:] = []
                break
            path = current_path / filename
            rel = relpath(path, root)
            if should_skip_file(rel, auditorignore_entries):
                skipped_files += 1
                continue
            scanned_files += 1
            for category, patterns in PRIMARY_PATTERNS.items():
                if match_any(rel, patterns):
                    primary[category].append(rel)
            fact_class = classify_fact(rel)
            fact_counts[fact_class] = fact_counts.get(fact_class, 0) + 1

    categories = {name: bounded_paths(paths) for name, paths in primary.items()}
    unique_primary = sorted({path for paths in primary.values() for path in paths})
    if limit_reached:
        primary_status = "available_limited"
    else:
        primary_status = "available" if unique_primary else "available_empty"
    full_status = "available_limited" if limit_reached else "available"
    primary_inventory = {
        "version": RECEIPT_VERSION,
        "status": primary_status,
        "source": "deterministic target filesystem scan bounded to primary AI/authority patterns",
        "scan_limit": max_files_scanned,
        "scan_limit_reached": limit_reached,
        "total_unique_paths": len(unique_primary),
        "categories": categories,
        "unavailable_reason": None,
        "empty_state_meaning": "no primary AI/authority surfaces matched known patterns" if not unique_primary and not limit_reached else None,
        "non_authorization_statement": "Missing, empty, limited, or unavailable primary inventory is insufficient evidence and never cleanup authorization.",
    }

    full_inventory = {
        "version": RECEIPT_VERSION,
        "status": full_status,
        "source": "deterministic auditor-pruned target filesystem scan",
        "scan_limit": max_files_scanned,
        "scan_limit_reached": limit_reached,
        "total_files_scanned": scanned_files,
        "paths_emitted": False,
        "class_counts": dict(sorted(fact_counts.items())),
        "auditorignore": {
            "active": bool(auditorignore_entries),
            "entry_count": len(auditorignore_entries),
            "entries_emitted": False,
        },
        "skipped_files_count": skipped_files,
        "non_authorization_statement": "Full-facts inventory is evidence context only; it does not authorize deleting, archiving, compressing, or rewriting target files.",
    }
    return primary_inventory, full_inventory


def unavailable_inventory(reason: str) -> tuple[dict[str, Any], dict[str, Any]]:
    primary = {
        "version": RECEIPT_VERSION,
        "status": "unavailable",
        "source": None,
        "scan_limit": DEFAULT_MAX_FILES_SCANNED,
        "scan_limit_reached": False,
        "total_unique_paths": 0,
        "categories": {name: bounded_paths([]) for name in PRIMARY_PATTERNS},
        "unavailable_reason": reason,
        "empty_state_meaning": None,
        "non_authorization_statement": "Missing, empty, limited, or unavailable primary inventory is insufficient evidence and never cleanup authorization.",
    }
    full = {
        "version": RECEIPT_VERSION,
        "status": "unavailable",
        "source": None,
        "scan_limit": DEFAULT_MAX_FILES_SCANNED,
        "scan_limit_reached": False,
        "total_files_scanned": 0,
        "paths_emitted": False,
        "class_counts": {},
        "auditorignore": {
            "active": False,
            "entry_count": 0,
            "entries_emitted": False,
        },
        "skipped_files_count": 0,
        "unavailable_reason": reason,
        "non_authorization_statement": "Full-facts inventory is evidence context only; it does not authorize deleting, archiving, compressing, or rewriting target files.",
    }
    return primary, full


def parse_scan_limit() -> int:
    raw = os.environ.get("REPO_AUDITOR_DUAL_INVENTORY_MAX_FILES", str(DEFAULT_MAX_FILES_SCANNED))
    try:
        value = int(raw)
    except ValueError as exc:
        raise ValueError("REPO_AUDITOR_DUAL_INVENTORY_MAX_FILES must be an integer") from exc
    if value < 1:
        raise ValueError("REPO_AUDITOR_DUAL_INVENTORY_MAX_FILES must be >= 1")
    return value


def update_outputs(target: Path, output_dir: Path) -> None:
    scorecard_path = output_dir / "SCORECARD.json"
    receipts_path = output_dir / "SCORECARD_RECEIPTS.json"
    scorecard = load_json(scorecard_path)
    receipts = load_json(receipts_path)
    max_files_scanned = parse_scan_limit()

    if target.is_dir():
        primary, full = scan_target(target, output_dir, max_files_scanned)
    else:
        primary, full = unavailable_inventory(f"target not found or not a directory: {target}")
        primary["scan_limit"] = max_files_scanned
        full["scan_limit"] = max_files_scanned

    receipts["primary_surface_inventory"] = primary
    receipts["full_facts_inventory"] = full

    scorecard_receipts = scorecard.setdefault("receipts", {})
    scorecard_receipts["dual_inventory"] = {
        "file": "SCORECARD_RECEIPTS.json",
        "version": RECEIPT_VERSION,
        "primary_surface_inventory_status": primary["status"],
        "primary_surface_count": primary["total_unique_paths"],
        "full_facts_inventory_status": full["status"],
        "full_facts_total_files_scanned": full["total_files_scanned"],
        "non_authorization": True,
    }

    write_json(receipts_path, receipts)
    write_json(scorecard_path, scorecard)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("target_repo")
    parser.add_argument("output_dir")
    args = parser.parse_args()

    update_outputs(Path(args.target_repo).resolve(), Path(args.output_dir).resolve())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
