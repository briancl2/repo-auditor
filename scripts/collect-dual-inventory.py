#!/usr/bin/env python3
"""Add primary-surface and full-facts inventory receipts to audit outputs."""

from __future__ import annotations

import argparse
import fnmatch
import json
import math
import os
import subprocess
from pathlib import Path
from typing import Any


RECEIPT_VERSION = "1.0.0"
PATH_LIMIT = 50
DEFAULT_MAX_FILES_SCANNED = 1000
DENOMINATOR_ENV = "REPO_AUDITOR_DUAL_INVENTORY_MEASURE_DENOMINATOR"
RERUN_CAP_BUFFER_RATIO = 1.1
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
RERUN_HINT_MULTIPLIER = 10

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


def count_denominator(root: Path, output_dir_resolved: Path, auditorignore_entries: list[str]) -> dict[str, int]:
    total_files = 0
    skipped_files = 0
    for current, dirs, files in os.walk(root):
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
            rel = f"{rel_current}/{filename}".strip("/")
            if should_skip_file(rel, auditorignore_entries):
                skipped_files += 1
                continue
            total_files += 1
    return {
        "auditor_pruned_total_files": total_files,
        "auditor_pruned_skipped_files_count": skipped_files,
    }


def git_tracked_file_count(root: Path) -> int | None:
    try:
        toplevel = subprocess.run(
            ["git", "-C", str(root), "rev-parse", "--show-toplevel"],
            capture_output=True,
            text=True,
            check=False,
        )
        if toplevel.returncode != 0 or Path(toplevel.stdout.strip()).resolve() != root.resolve():
            return None
        proc = subprocess.run(
            ["git", "-C", str(root), "ls-files"],
            capture_output=True,
            text=True,
            check=False,
        )
    except OSError:
        return None
    if proc.returncode != 0:
        return None
    return len([line for line in proc.stdout.splitlines() if line.strip()])


def coverage_ratio(scanned_files: int, total_files: int | None) -> float | None:
    if total_files is None:
        return None
    if total_files == 0:
        return 1.0
    return round(scanned_files / total_files, 6)


def buffered_rerun_cap(auditor_pruned_total_files: int) -> int:
    return max(auditor_pruned_total_files, math.ceil(auditor_pruned_total_files * RERUN_CAP_BUFFER_RATIO))


def build_scan_limit_guidance(
    *,
    status: str,
    scan_limit_reached: bool,
    scan_limit: int,
    denominator_mode: str,
    auditor_pruned_total_files: int | None,
) -> dict[str, Any]:
    guidance: dict[str, Any] = {
        "version": RECEIPT_VERSION,
        "status": "not_needed",
        "reason": "inventory scan completed within the configured cap",
        "minimum_complete_cap": None,
        "recommended_rerun_cap": None,
        "recommended_rerun_cap_basis": None,
        "trusted_local_override": None,
        "denominator_measurement_override": None,
        "cap_curve_hint": None,
        "non_authorization": True,
    }
    if status == "unavailable":
        guidance["status"] = "not_applicable"
        guidance["reason"] = "inventory was unavailable, so scan-cap guidance cannot be computed"
        return guidance
    if not scan_limit_reached and status != "available_limited":
        return guidance

    if denominator_mode == "full_walk" and auditor_pruned_total_files is not None:
        if auditor_pruned_total_files >= scan_limit:
            recommended_cap = buffered_rerun_cap(auditor_pruned_total_files)
            guidance.update(
                {
                    "status": "rerun_with_higher_cap",
                    "reason": "scan limit reached and denominator measurement found more auditor-pruned files than the configured cap",
                    "minimum_complete_cap": auditor_pruned_total_files,
                    "recommended_rerun_cap": recommended_cap,
                    "recommended_rerun_cap_basis": "ceil(auditor_pruned_total_files * 1.10)",
                    "trusted_local_override": f"REPO_AUDITOR_DUAL_INVENTORY_MAX_FILES={recommended_cap}",
                    "denominator_measurement_override": f"{DENOMINATOR_ENV}=1",
                }
            )
            return guidance
        return guidance

    guidance.update(
        {
            "status": "measure_denominator",
            "reason": "scan limit reached before denominator measurement was enabled; rerun with denominator measurement or the cap-curve helper before claiming complete inventory",
            "denominator_measurement_override": f"{DENOMINATOR_ENV}=1",
            "cap_curve_hint": "make measure-dual-inventory-cap-curve TARGET=<target> OUTPUT_DIR=<output> CAPS=<cap1>,<cap2>,<cap3>",
        }
    )
    return guidance


def scan_limited_rerun_hint(
    limit_reached: bool,
    max_files_scanned: int,
    auditor_pruned_total_files: int | None,
) -> dict[str, Any] | None:
    if not limit_reached:
        return None
    if auditor_pruned_total_files is not None and auditor_pruned_total_files > max_files_scanned:
        suggested_cap = auditor_pruned_total_files
        basis = "measured_auditor_pruned_total_files"
    else:
        suggested_cap = max_files_scanned * RERUN_HINT_MULTIPLIER
        basis = "heuristic_10x_current_limit_without_denominator"
    return {
        "reason": "scan_limit_reached",
        "suggested_max_files": suggested_cap,
        "suggested_env": {
            "REPO_AUDITOR_DUAL_INVENTORY_MAX_FILES": str(suggested_cap),
            DENOMINATOR_ENV: "1",
        },
        "basis": basis,
        "message": (
            "Dual inventory scan stopped at "
            f"{max_files_scanned} files; rerun with "
            f"REPO_AUDITOR_DUAL_INVENTORY_MAX_FILES={suggested_cap} "
            f"and {DENOMINATOR_ENV}=1 for complete-vs-limited evidence."
        ),
    }


def scan_target(
    root: Path,
    output_dir: Path,
    max_files_scanned: int,
    measure_denominator: bool,
) -> tuple[dict[str, Any], dict[str, Any]]:
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
    denominator = None
    if measure_denominator:
        denominator = count_denominator(root, output_dir_resolved, auditorignore_entries)
    auditor_pruned_total_files = None if denominator is None else denominator["auditor_pruned_total_files"]
    auditor_pruned_skipped_files_count = (
        None if denominator is None else denominator["auditor_pruned_skipped_files_count"]
    )
    tracked_file_count = git_tracked_file_count(root) if measure_denominator else None
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
        "denominator_mode": "full_walk" if measure_denominator else "not_measured",
        "auditor_pruned_total_files": auditor_pruned_total_files,
        "auditor_pruned_skipped_files_count": auditor_pruned_skipped_files_count,
        "scan_coverage_ratio": coverage_ratio(scanned_files, auditor_pruned_total_files),
        "git_tracked_file_count": tracked_file_count,
        "scan_limited_rerun_hint": scan_limited_rerun_hint(
            limit_reached,
            max_files_scanned,
            auditor_pruned_total_files,
        ),
        "non_authorization_statement": "Full-facts inventory is evidence context only; it does not authorize deleting, archiving, compressing, or rewriting target files.",
    }
    full_inventory["scan_limit_guidance"] = build_scan_limit_guidance(
        status=full_status,
        scan_limit_reached=limit_reached,
        scan_limit=max_files_scanned,
        denominator_mode=full_inventory["denominator_mode"],
        auditor_pruned_total_files=auditor_pruned_total_files,
    )
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
        "denominator_mode": "unavailable",
        "auditor_pruned_total_files": None,
        "auditor_pruned_skipped_files_count": None,
        "scan_coverage_ratio": None,
        "git_tracked_file_count": None,
        "scan_limited_rerun_hint": None,
        "unavailable_reason": reason,
        "non_authorization_statement": "Full-facts inventory is evidence context only; it does not authorize deleting, archiving, compressing, or rewriting target files.",
    }
    full["scan_limit_guidance"] = build_scan_limit_guidance(
        status=full["status"],
        scan_limit_reached=full["scan_limit_reached"],
        scan_limit=full["scan_limit"],
        denominator_mode=full["denominator_mode"],
        auditor_pruned_total_files=full["auditor_pruned_total_files"],
    )
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


def parse_measure_denominator() -> bool:
    raw = os.environ.get(DENOMINATOR_ENV, "0").strip().lower()
    if raw in {"1", "true", "yes", "on"}:
        return True
    if raw in {"0", "false", "no", "off", ""}:
        return False
    raise ValueError(f"{DENOMINATOR_ENV} must be a boolean value")


def update_outputs(target: Path, output_dir: Path) -> None:
    scorecard_path = output_dir / "SCORECARD.json"
    receipts_path = output_dir / "SCORECARD_RECEIPTS.json"
    scorecard = load_json(scorecard_path)
    receipts = load_json(receipts_path)
    max_files_scanned = parse_scan_limit()
    measure_denominator = parse_measure_denominator()

    if target.is_dir():
        primary, full = scan_target(target, output_dir, max_files_scanned, measure_denominator)
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
        "full_facts_scan_limit": full["scan_limit"],
        "full_facts_scan_limit_reached": full["scan_limit_reached"],
        "full_facts_denominator_mode": full["denominator_mode"],
        "full_facts_auditor_pruned_total_files": full["auditor_pruned_total_files"],
        "full_facts_scan_coverage_ratio": full["scan_coverage_ratio"],
        "full_facts_scan_limit_guidance_status": full["scan_limit_guidance"]["status"],
        "full_facts_minimum_complete_cap": full["scan_limit_guidance"]["minimum_complete_cap"],
        "full_facts_recommended_rerun_cap": full["scan_limit_guidance"]["recommended_rerun_cap"],
        "full_facts_trusted_local_override": full["scan_limit_guidance"]["trusted_local_override"],
        "git_tracked_file_count": full["git_tracked_file_count"],
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
