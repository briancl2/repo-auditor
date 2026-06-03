#!/usr/bin/env python3
"""Shared AS-* signature evaluator for repo-auditor."""

from __future__ import annotations

import json
import re
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass
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
    "AS text scan is bounded to 200 files after prioritizing owner guidance, "
    "instruction, and operation surfaces (root instruction files, AGENTS.md, "
    "README.md, docs, .github, .agents, scripts, schemas, tests) before the "
    "general sorted file walk."
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
    "work",
    "audit_output",
    ".tmp",
}
SYNTHETIC_EVIDENCE_PARTS = {"fixture", "fixtures", "__fixtures__", "testdata", "test-data"}
SYNTHETIC_EVIDENCE_ROOTS = {"test", "tests"}
SELF_INSTRUMENTATION_PATHS = {"scripts/as_signature_scan.py"}


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

    @property
    def scan_limited(self) -> bool:
        return self.eligible_files > self.scan_limit


def is_eligible_text_path(repo: Path, path: Path) -> bool:
    if not path.is_file():
        return False
    rel = path.relative_to(repo)
    if any(part.lower() in SKIP_PARTS for part in rel.parts):
        return False
    rel_str = rel.as_posix()
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
    if parts:
        first = parts[0].lower()
        if first in PRIORITY_DIR_RANKS:
            return (PRIORITY_DIR_RANKS[first], rel_str)
    return (100, rel_str)


def load_text_scan(repo: Path) -> TextScan:
    eligible_paths = sorted(
        (path for path in repo.rglob("*") if is_eligible_text_path(repo, path)),
        key=lambda path: scan_priority_key(repo, path),
    )
    texts: dict[str, str] = {}
    for path in eligible_paths:
        if len(texts) >= SCAN_LIMIT:
            break
        rel = path.relative_to(repo).as_posix()
        try:
            texts[rel] = path.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
    return TextScan(texts=texts, eligible_files=len(eligible_paths))


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

    observed_classes = sum(
        bool(bucket)
        for bucket in (
            responder_truth_files,
            receipt_output_files,
            helper_only_files,
            bounded_calibration_files,
        )
    )
    fired = observed_classes >= 2 and len(validation_files) >= 1
    details = [
        f"responder_truth=>{','.join(responder_truth_files[:4]) or 'none'}",
        f"receipt_output=>{','.join(receipt_output_files[:4]) or 'none'}",
        f"helper_only=>{','.join(helper_only_files[:4]) or 'none'}",
        f"bounded_calibration=>{','.join(bounded_calibration_files[:4]) or 'none'}",
        f"validation=>{','.join(validation_files[:4]) or 'none'}",
    ]
    return {
        "fired": fired,
        "signals": {
            "responder_truth_file_count": len(responder_truth_files),
            "receipt_output_file_count": len(receipt_output_files),
            "helper_only_file_count": len(helper_only_files),
            "bounded_calibration_file_count": len(bounded_calibration_files),
            "validation_file_count": len(validation_files),
        },
        "evidence": evidence_join(details),
        "reason": "repo exposes two or more critique-health evidence classes with validation support" if fired else "critique-health mismatch is absent or explicitly grounded",
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
DIRECT_COST_CLAIM_PATTERN = re.compile(
    r"(\$[0-9][0-9,]*(?:\.[0-9]+)?|usd\s*[0-9][0-9,]*(?:\.[0-9]+)?|"
    r"\b(estimated|estimate|cost|spend)\b.{0,80}\$)"
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
    r"\b(category[- ]?only|selection handback|hand back selection|operator (?:choose|pick|select))\b",
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
    r"closure authority)\b",
    re.IGNORECASE,
)
LOCAL_CLOSEOUT_BYPASS_PATTERN = re.compile(
    r"\b(github-native-closeout|github[- ]native closeout|bypass(?:ed)?|"
    r"explicitly bypass(?:ed)?|not re-graded|no local completion authority|"
    r"no local closeout authority|no new local closeout|issue/pr truth is closure authority|"
    r"except for qualifying|do not run|do not add|not required|not authoritative|not used|"
    r"no new.{0,80}local closeout|not for.{0,80}direct closure|"
    r"instead of [`'\"]?(?:make )?work-close|"
    r"score[_-]session[_-]not[_-]authoritative|session grader skipped)\b",
    re.IGNORECASE,
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
    r"\b(AS-2[0-9]|AS-3[0-3]|selection handback|too-small goal|too small goal|"
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
    r"foreground recovery runtime contract)\b",
    re.IGNORECASE,
)
SIGNATURE_DEFINITION_MARKER_PATTERN = re.compile(
    r"\b(detects:|signal:|fire condition:|prevention tier:|severity:|script:|"
    r"triggers?:|recommendation template|detection signature)\b",
    re.IGNORECASE,
)


def is_work_management_signature_explainer(path: str, text: str) -> bool:
    """Suppress detector docs/templates that define AS-20/21/22 themselves."""

    lowered_path = path.lower()
    if not WORK_MANAGEMENT_SIGNATURE_REFERENCE_PATTERN.search(text):
        return False
    if lowered_path.startswith("detection-signatures/"):
        return True
    if "template" in lowered_path and SIGNATURE_DEFINITION_MARKER_PATTERN.search(text):
        return True
    return "signature" in lowered_path and SIGNATURE_DEFINITION_MARKER_PATTERN.search(text)


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
            if not LOCAL_CLOSEOUT_AUTHORITY_PATTERN.search(lowered):
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
    r"foreground recovery runtime contract)\b",
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
    r"mutate target repos?|target repos?|Hermes internals|automatic GitHub issue creation)\b",
    re.IGNORECASE,
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

        has_guidance_consumption = FOREGROUND_FAILURE_GUIDANCE_CONSUMPTION_PATTERN.search(text) is not None
        has_github_owner_truth = ROUTE_CHANGING_GITHUB_OWNER_TRUTH_PATTERN.search(text) is not None
        has_failed_receipt_evidence = FAILED_FOREGROUND_RECEIPT_EVIDENCE_PATTERN.search(text) is not None
        control_term_count = sum(1 for pattern in NO_REGROWTH_CONTROL_TERMS.values() if pattern.search(text))
        has_no_regrowth_boundaries = (
            NO_REGROWTH_BOUNDARY_PATTERN.search(text) is not None
            and control_term_count >= 3
            and NO_REGROWTH_MUTATION_BOUNDARY_PATTERN.search(text) is not None
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
