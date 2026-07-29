#!/usr/bin/env python3
"""Fail-closed cached-index validation for repo-auditor owner convergence."""

from __future__ import annotations

import argparse
import fnmatch
import json
import os
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path


INVENTORY_PATH = "docs/live-capability-inventory.md"
CORE_INVENTORY_PATH = "docs/live-capability-inventory.md"
EXPECTED_BASE = "174fc769c029060270eca7d405decb08c9b7919b"
EXPECTED_CORE = "a93abeece9d237a2a642f96926b4590dc1a373c9"
EXPECTED_CORE_INVENTORY_BLOB = "957887e8b80fac0f9bb015528eb71ffae7a2aaa0"
OWNER_ROUTE = ".agents/skills/repo-auditor-owner-settlement/SKILL.md"
ACTIVE_AUTHORITY = ("AGENTS.md", "README.md")
RETIRED_ACTIVE_TOKENS = (
    ".specify",
    "Speckit",
    "Spec Kit",
    "make work",
    "make work-close",
    "score-session",
    "current-program-status",
)


class ConvergenceError(RuntimeError):
    """A deterministic owner-convergence failure."""


@dataclass(frozen=True)
class IndexEntry:
    mode: str
    sha: str
    path: str


@dataclass(frozen=True)
class Evidence:
    path: str
    token: str


@dataclass(frozen=True)
class CoreExport:
    path: str
    core_blob: str
    caller: Evidence
    mode: str


def git(repo: Path, *args: str, ok_no_match: bool = False) -> bytes:
    proc = subprocess.run(
        ["git", "-C", str(repo), *args],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if proc.returncode == 0:
        return proc.stdout
    if ok_no_match and proc.returncode == 1:
        return b""
    detail = proc.stderr.decode("utf-8", "replace").strip()
    raise ConvergenceError(
        f"git {' '.join(args)} failed with exit {proc.returncode}: {detail}"
    )


def index_entries(repo: Path) -> dict[str, IndexEntry]:
    raw = git(repo, "ls-files", "--stage", "-z")
    result: dict[str, IndexEntry] = {}
    for record in raw.split(b"\0"):
        if not record:
            continue
        try:
            metadata, encoded_path = record.split(b"\t", 1)
            mode, sha, stage = metadata.decode("ascii").split()
            path = encoded_path.decode("utf-8")
        except (UnicodeDecodeError, ValueError) as exc:
            raise ConvergenceError("malformed or non-UTF-8 Git index entry") from exc
        if stage != "0":
            raise ConvergenceError(f"unmerged Git index entry: {path}")
        if path in result:
            raise ConvergenceError(f"duplicate Git index entry: {path}")
        result[path] = IndexEntry(mode=mode, sha=sha, path=path)
    if not result:
        raise ConvergenceError("Git index is empty")
    return result


def tree_entries(repo: Path, ref: str) -> dict[str, str]:
    raw = git(repo, "ls-tree", "-r", "-z", "--full-tree", ref)
    result: dict[str, str] = {}
    for record in raw.split(b"\0"):
        if not record:
            continue
        try:
            metadata, encoded_path = record.split(b"\t", 1)
            _, object_type, sha = metadata.decode("ascii").split()
            path = encoded_path.decode("utf-8")
        except (UnicodeDecodeError, ValueError) as exc:
            raise ConvergenceError(f"malformed tree entry at {ref}") from exc
        if object_type == "blob":
            result[path] = sha
    if not result:
        raise ConvergenceError(f"tree is empty at {ref}")
    return result


def blob(repo: Path, sha: str) -> bytes:
    return git(repo, "cat-file", "blob", sha)


def text_blob(repo: Path, sha: str, path: str) -> str:
    try:
        return blob(repo, sha).decode("utf-8")
    except UnicodeDecodeError as exc:
        raise ConvergenceError(f"cached blob is not UTF-8: {path}") from exc


def cached_text(repo: Path, index: dict[str, IndexEntry], path: str) -> str:
    entry = index.get(path)
    if entry is None:
        raise ConvergenceError(f"missing cached index path: {path}")
    return text_blob(repo, entry.sha, path)


def section_table(text: str, heading: str) -> list[list[str]]:
    lines = text.splitlines()
    try:
        start = lines.index(heading) + 1
    except ValueError as exc:
        raise ConvergenceError(f"inventory missing section: {heading}") from exc
    rows: list[list[str]] = []
    started = False
    for line in lines[start:]:
        if line.startswith("## "):
            break
        if not line.startswith("|"):
            if started and line.strip():
                break
            continue
        cells = [cell.strip().strip("`") for cell in line.strip().strip("|").split("|")]
        if not started:
            started = True
            continue
        if all(set(cell) <= {"-", ":"} for cell in cells):
            continue
        rows.append(cells)
    if not rows:
        raise ConvergenceError(f"inventory section has no rows: {heading}")
    return rows


def matching(paths: set[str], pattern: str) -> list[str]:
    return sorted(path for path in paths if fnmatch.fnmatchcase(path, pattern))


def parse_evidence(value: str) -> Evidence:
    if value.count("::") != 1:
        raise ConvergenceError(f"evidence must use path::literal-token: {value}")
    path, token = (part.strip().strip("`") for part in value.split("::", 1))
    if not path or not token:
        raise ConvergenceError(f"empty evidence path or token: {value}")
    return Evidence(path=path, token=token)


def validate_evidence(
    repo: Path,
    blobs: dict[str, str],
    evidence: Evidence,
    label: str,
) -> None:
    sha = blobs.get(evidence.path)
    if sha is None:
        raise ConvergenceError(f"{label} evidence path missing: {evidence.path}")
    content = text_blob(repo, sha, evidence.path)
    if evidence.token not in content:
        raise ConvergenceError(
            f"{label} evidence token missing: {evidence.path}::{evidence.token}"
        )


def parse_classification(
    repo: Path,
    index: dict[str, IndexEntry],
    inventory: str,
) -> dict[str, int]:
    rows = section_table(inventory, "## Retained tracked classification")
    paths = set(index)
    assignments: dict[str, list[str]] = {path: [] for path in paths}
    owner_checks = 0
    orphan_rows = 0
    for row in rows:
        if len(row) != 3:
            raise ConvergenceError("retained classification row must have three columns")
        pattern, _, evidence_text = row
        expanded = matching(paths, pattern)
        if not expanded:
            raise ConvergenceError(
                f"retained classification pattern matches no cached path: {pattern}"
            )
        evidence = parse_evidence(evidence_text)
        validate_evidence(
            repo,
            {path: entry.sha for path, entry in index.items()},
            evidence,
            f"classification {pattern}",
        )
        owner_checks += 1
        if not evidence_text:
            orphan_rows += 1
        for path in expanded:
            assignments[path].append(pattern)
    unclassified = sorted(path for path, rules in assignments.items() if not rules)
    overlaps = sorted(path for path, rules in assignments.items() if len(rules) > 1)
    if unclassified:
        raise ConvergenceError(
            f"unclassified cached index paths ({len(unclassified)}): "
            + ", ".join(unclassified[:10])
        )
    if overlaps:
        raise ConvergenceError(
            f"multiply classified cached index paths ({len(overlaps)}): "
            + ", ".join(overlaps[:10])
        )
    return {
        "classification_rows": len(rows),
        "classified_index_paths": len(assignments),
        "unclassified_index_paths": len(unclassified),
        "classification_overlap_paths": len(overlaps),
        "owner_evidence_checks": owner_checks,
        "orphan_active_exports": orphan_rows,
    }


def parse_allowed_changes(inventory: str) -> set[str]:
    rows = section_table(inventory, "## Allowed candidate changes")
    allowed: set[str] = set()
    for row in rows:
        if len(row) != 2:
            raise ConvergenceError("allowed candidate change row must have two columns")
        path, _ = row
        if path in allowed:
            raise ConvergenceError(f"duplicate allowed candidate path: {path}")
        allowed.add(path)
    return allowed


def parse_removed_rules(inventory: str) -> list[tuple[str, str, str]]:
    rows = section_table(inventory, "## Removed-name successor and rollback map")
    result: list[tuple[str, str, str]] = []
    for row in rows:
        if len(row) != 3:
            raise ConvergenceError("removed-name rule must have three columns")
        pattern, successor, rollback = row
        if any(pattern == existing for existing, _, _ in result):
            raise ConvergenceError(f"duplicate removed pattern: {pattern}")
        result.append((pattern, successor, rollback))
    return result


def validate_base_delta(
    repo: Path,
    index: dict[str, IndexEntry],
    inventory: str,
    base_ref: str,
) -> dict[str, int]:
    if base_ref != EXPECTED_BASE:
        raise ConvergenceError(
            f"owner rollback base must be {EXPECTED_BASE}, got {base_ref}"
        )
    base = tree_entries(repo, base_ref)
    base_paths = set(base)
    index_paths = set(index)
    deleted = sorted(base_paths - index_paths)
    retained = sorted(base_paths & index_paths)
    added = sorted(index_paths - base_paths)
    changed = sorted(path for path in retained if base[path] != index[path].sha)

    allowed = parse_allowed_changes(inventory)
    actual_candidate = set(changed) | set(added)
    if actual_candidate != allowed:
        unexpected = sorted(actual_candidate - allowed)
        unused = sorted(allowed - actual_candidate)
        raise ConvergenceError(
            f"allowed candidate mismatch: unexpected={unexpected}, unused={unused}"
        )

    rules = parse_removed_rules(inventory)
    assignments: dict[str, list[str]] = {path: [] for path in deleted}
    for pattern, successor, rollback in rules:
        base_matches = matching(base_paths, pattern)
        if not base_matches:
            raise ConvergenceError(f"removed pattern matches no rollback path: {pattern}")
        retained_matches = matching(index_paths, pattern)
        if retained_matches:
            raise ConvergenceError(
                f"removed pattern still matches cached path: {pattern} -> "
                f"{retained_matches[0]}"
            )
        if successor not in index:
            raise ConvergenceError(
                f"removed-name successor missing from cached index: {successor}"
            )
        if EXPECTED_BASE not in rollback or "git restore --source" not in rollback:
            raise ConvergenceError(f"rollback is not exact and recoverable: {pattern}")
        if "/Users/" in rollback or "/home/" in rollback:
            raise ConvergenceError(f"rollback contains a host-private path: {pattern}")
        for path in base_matches:
            if path in assignments:
                assignments[path].append(pattern)
    bad = {path: rows for path, rows in assignments.items() if len(rows) != 1}
    if bad:
        path = sorted(bad)[0]
        raise ConvergenceError(
            f"deleted path must match exactly one removed rule: {path} -> {bad[path]}"
        )

    unchanged = len(retained) - len(changed)
    schema_paths = sorted(
        path
        for path in index_paths
        if path.startswith("schemas/") and path.endswith(".schema.json")
    )
    for path in schema_paths:
        if base.get(path) != index[path].sha:
            raise ConvergenceError(f"retained schema bytes changed: {path}")
    if base.get("CONSTITUTION.md") != index["CONSTITUTION.md"].sha:
        raise ConvergenceError("CONSTITUTION.md bytes changed from rollback base")
    return {
        "base_paths": len(base),
        "deleted_paths": len(deleted),
        "removed_rules": len(rules),
        "rollback_paths": len(assignments),
        "changed_retained_paths": len(changed),
        "new_paths": len(added),
        "unchanged_retained_blobs": unchanged,
        "unchanged_schema_blobs": len(schema_paths),
    }


def parse_core_exports(inventory: str) -> list[CoreExport]:
    rows = section_table(inventory, "## Retained core exports")
    result: list[CoreExport] = []
    for row in rows:
        if len(row) != 4:
            raise ConvergenceError("retained core export row must have four columns")
        path, core_blob, caller, mode = row
        if len(core_blob) != 40:
            raise ConvergenceError(f"invalid core blob identity: {path}")
        if any(path == item.path for item in result):
            raise ConvergenceError(f"duplicate retained core export: {path}")
        result.append(
            CoreExport(
                path=path,
                core_blob=core_blob,
                caller=parse_evidence(caller),
                mode=mode,
            )
        )
    return result


def core_inventory_auditor_callers(text: str) -> dict[str, str]:
    rows = section_table(text, "## Active exports")
    result: dict[str, str] = {}
    for row in rows:
        if len(row) != 6:
            raise ConvergenceError("core active export row must have six columns")
        path, _, _, auditor, _, _ = row
        if auditor != "-":
            result[path] = auditor
    return result


def validate_core_exports(
    repo: Path,
    index: dict[str, IndexEntry],
    inventory: str,
    base_ref: str,
    core_ref: str,
    core_repo: Path | None,
) -> dict[str, int]:
    if core_ref != EXPECTED_CORE:
        raise ConvergenceError(
            f"compatible core baseline must be {EXPECTED_CORE}, got {core_ref}"
        )
    base = tree_entries(repo, base_ref)
    current = {path: entry.sha for path, entry in index.items()}
    exports = parse_core_exports(inventory)
    exact = 0
    extensions = 0
    citations = 0
    for export in exports:
        validate_evidence(repo, current, export.caller, f"core caller {export.path}")
        if export.mode == "exact-copy":
            if current.get(export.path) != export.core_blob:
                raise ConvergenceError(f"core exact-copy drift: {export.path}")
            exact += 1
        elif export.mode.startswith("owner-extension:"):
            expected = export.mode.split(":", 1)[1]
            if current.get(export.path) != expected or base.get(export.path) != expected:
                raise ConvergenceError(f"owner-extended core export drift: {export.path}")
            extensions += 1
        elif export.mode == "citation-only":
            if export.path in current:
                raise ConvergenceError(
                    f"citation-only core export unexpectedly copied locally: {export.path}"
                )
            citations += 1
        else:
            raise ConvergenceError(f"unknown retained core mode: {export.mode}")

    live_checks = 0
    if core_repo is not None:
        if not core_repo.is_dir():
            raise ConvergenceError(f"core repository is not a directory: {core_repo}")
        resolved = git(core_repo, "rev-parse", f"{core_ref}^{{commit}}").decode().strip()
        if resolved != core_ref:
            raise ConvergenceError(
                f"core repository resolved {core_ref} to unexpected {resolved}"
            )
        core_tree = tree_entries(core_repo, core_ref)
        if core_tree.get(CORE_INVENTORY_PATH) != EXPECTED_CORE_INVENTORY_BLOB:
            raise ConvergenceError("core inventory blob does not match frozen baseline")
        core_inventory = text_blob(
            core_repo,
            core_tree[CORE_INVENTORY_PATH],
            CORE_INVENTORY_PATH,
        )
        auditor_callers = core_inventory_auditor_callers(core_inventory)
        for export in exports:
            if core_tree.get(export.path) != export.core_blob:
                raise ConvergenceError(f"core baseline export identity drift: {export.path}")
            rendered = f"{export.caller.path}::{export.caller.token}"
            if auditor_callers.get(export.path) != rendered:
                raise ConvergenceError(
                    f"core baseline auditor caller drift: {export.path}"
                )
            live_checks += 2
        live_checks += 1
    return {
        "core_export_rows": len(exports),
        "core_caller_checks": len(exports),
        "core_exact_copy_blobs": exact,
        "core_owner_extension_blobs": extensions,
        "core_citation_only_exports": citations,
        "core_live_baseline_checks": live_checks,
    }


def validate_active_authority(
    repo: Path,
    index: dict[str, IndexEntry],
) -> dict[str, int]:
    for path in ACTIVE_AUTHORITY:
        text = cached_text(repo, index, path)
        if text.count(OWNER_ROUTE) != 1:
            raise ConvergenceError(
                f"{path} must name the one owner route exactly once"
            )
        for token in RETIRED_ACTIVE_TOKENS:
            if token.casefold() in text.casefold():
                raise ConvergenceError(
                    f"retired authority token remains active in {path}: {token}"
                )
    return {"active_authority_files": len(ACTIVE_AUTHORITY)}


def harness_counts(paths: set[str]) -> dict[str, int]:
    return {
        "skills": sum(path.endswith("/SKILL.md") for path in paths),
        "custom_agents": sum(path.endswith(".agent.md") for path in paths),
        "instructions": sum(Path(path).name == "AGENTS.md" for path in paths),
        "prompts": sum(path.endswith(".prompt.md") for path in paths),
    }


def installed_counts(root: Path, tracked: set[str]) -> dict[str, int]:
    counts = {"skills": 0, "custom_agents": 0, "instructions": 0, "prompts": 0}
    if not root.is_dir():
        raise ConvergenceError(f"installed discovery root is not a directory: {root}")
    for directory, subdirs, files in os.walk(root):
        relative_dir = Path(directory).relative_to(root)
        if relative_dir.parts and relative_dir.parts[0] not in {
            ".agents",
            ".github",
            ".claude",
        }:
            subdirs[:] = []
            continue
        subdirs[:] = sorted(
            name
            for name in subdirs
            if name not in {".git", "node_modules", "__pycache__"}
        )
        for filename in sorted(files):
            path = Path(directory, filename).relative_to(root).as_posix()
            if path in tracked:
                continue
            if filename == "SKILL.md":
                counts["skills"] += 1
            elif filename.endswith(".agent.md"):
                counts["custom_agents"] += 1
            elif filename == "AGENTS.md" or filename.endswith(".instructions.md"):
                counts["instructions"] += 1
            elif filename.endswith(".prompt.md"):
                counts["prompts"] += 1
    return counts


def manifest_registry_count(paths: set[str]) -> int:
    return sum(
        "manifest" in Path(path).name.casefold()
        or "registry" in Path(path).name.casefold()
        or path == INVENTORY_PATH
        for path in paths
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", default=".")
    parser.add_argument("--base-ref", default=EXPECTED_BASE)
    parser.add_argument("--core-ref", default=EXPECTED_CORE)
    parser.add_argument("--core-repo")
    parser.add_argument("--installed-root")
    args = parser.parse_args()

    repo = Path(args.repo).resolve()
    if not repo.is_dir():
        raise ConvergenceError(f"repository is not a directory: {repo}")
    index = index_entries(repo)
    inventory = cached_text(repo, index, INVENTORY_PATH)
    result = {
        "verdict": "PASS",
        "owner_base": args.base_ref,
        "core_baseline": args.core_ref,
        "inventory": INVENTORY_PATH,
        "index_paths": len(index),
        **parse_classification(repo, index, inventory),
        **validate_active_authority(repo, index),
        **validate_base_delta(repo, index, inventory, args.base_ref),
        **validate_core_exports(
            repo,
            index,
            inventory,
            args.base_ref,
            args.core_ref,
            Path(args.core_repo).resolve() if args.core_repo else None,
        ),
        "tracked_manifest_registry_paths": manifest_registry_count(set(index)),
        "active_owner_manifests": 1,
        "harness_counts": harness_counts(set(index)),
        "installed_counts": installed_counts(
            Path(args.installed_root).resolve()
            if args.installed_root
            else repo,
            set(index),
        ),
    }
    print(json.dumps(result, sort_keys=True))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ConvergenceError as exc:
        print(
            json.dumps({"verdict": "FAIL", "error": str(exc)}, sort_keys=True),
            file=sys.stderr,
        )
        raise SystemExit(1)
