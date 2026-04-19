#!/usr/bin/env python3
"""Shared AS-* signature evaluator for repo-auditor."""

from __future__ import annotations

import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any


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
}


INSTRUCTION_FILES = {
    "AGENTS.md",
    "README.md",
    "LEARNINGS.md",
    "docs/invocation-contract.md",
    ".specify/memory/constitution.md",
}

TEXT_EXTENSIONS = {".md", ".txt", ".json", ".yml", ".yaml", ".sh", ".py", ".prompt"}
SKIP_PARTS = {".git", "node_modules", "vendor", "__pycache__", "work", "audit_output", ".tmp"}


def parse_args() -> tuple[str, Path]:
    if len(sys.argv) != 3:
        raise SystemExit("Usage: as_signature_scan.py <AS-id> <repo_path>")
    return sys.argv[1], Path(sys.argv[2]).resolve()


def load_texts(repo: Path) -> dict[str, str]:
    texts: dict[str, str] = {}
    for path in sorted(repo.rglob("*")):
        if len(texts) >= 200:
            break
        if not path.is_file():
            continue
        rel = path.relative_to(repo)
        if any(part in SKIP_PARTS for part in rel.parts):
            continue
        if path.suffix.lower() not in TEXT_EXTENSIONS and path.name not in INSTRUCTION_FILES:
            continue
        try:
            texts[str(rel)] = path.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
    return texts


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


def external_critique_health(texts: dict[str, str]) -> dict[str, Any]:
    responder_truth_files = rels_matching(
        texts,
        lambda path, text: re.search(r"\b(responder truth|responder-truth|truth.*output|output.*truth)\b", text) is not None,
    )
    receipt_output_files = rels_matching(
        texts,
        lambda path, text: re.search(r"\b(receipt-output|receipt.*output|output.*receipt|receipt.*mismatch)\b", text) is not None,
    )
    helper_only_files = rels_matching(
        texts,
        lambda path, text: re.search(r"\b(helper-only|helper only|helper-only misclassification)\b", text) is not None,
    )
    validation_files = rels_matching(
        texts,
        lambda path, text: (
            path.endswith(".sh")
            or path.endswith(".py")
            or path.endswith(".md")
        )
        and re.search(r"\b(test|validate|assert|receipt)\b", text) is not None,
    )

    observed_classes = sum(bool(bucket) for bucket in (responder_truth_files, receipt_output_files, helper_only_files))
    fired = observed_classes >= 2 and len(validation_files) >= 1
    details = [
        f"responder_truth=>{','.join(responder_truth_files[:4]) or 'none'}",
        f"receipt_output=>{','.join(receipt_output_files[:4]) or 'none'}",
        f"helper_only=>{','.join(helper_only_files[:4]) or 'none'}",
        f"validation=>{','.join(validation_files[:4]) or 'none'}",
    ]
    return {
        "fired": fired,
        "signals": {
            "responder_truth_file_count": len(responder_truth_files),
            "receipt_output_file_count": len(receipt_output_files),
            "helper_only_file_count": len(helper_only_files),
            "validation_file_count": len(validation_files),
        },
        "evidence": evidence_join(details),
        "reason": "critique-health vocabulary appears without a validated mismatch surface" if fired else "critique-health mismatch is absent or explicitly grounded",
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

    texts = load_texts(repo)
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
    }
    print(json.dumps(payload, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
