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
    detector_path = "scripts/as_signature_scan.py"
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
    bounded_calibration_files = rels_matching(
        texts,
        lambda path, text: path != detector_path
        and re.search(
            r"\b(external_critique_health|bounded_current_anchor|bounded_calibrated|downstream_admission\b.{0,24}\bbounded)\b",
            text,
        )
        is not None,
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
    for path, text in texts.items():
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
    for path, text in texts.items():
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
    for path, text in texts.items():
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
    for path, text in texts.items():
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


COPIED_EVIDENCE_PATTERN = re.compile(r"\b(copied evidence|copied-evidence|evidence payload|review payload|verbatim evidence)\b")
AUTHOR_BOUNDARY_PATTERN = re.compile(
    r"\b(authored claims?|author claims?|claims boundary|copied evidence boundary|"
    r"copied_evidence|authored_claims|boundary between copied evidence and authored claims)\b"
)
CLAIM_PATTERN = re.compile(r"\b(conclude|therefore|proves|shows|recommend|should|claim|finding)\b")


def copied_evidence_boundary_gap(texts: dict[str, str]) -> dict[str, Any]:
    offenders: list[str] = []
    bounded: list[str] = []
    for path, text in texts.items():
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
