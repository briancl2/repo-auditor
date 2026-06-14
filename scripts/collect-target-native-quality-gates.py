#!/usr/bin/env python3
"""Collect target-native quality gate evidence as an additive audit receipt."""

from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

ADAPTER_VERSION = "0.2.0"
CONTRADICTION_ENUM = {
    "target_policy_explained",
    "unresolved",
    "true_target_risk",
    "fleet_metric_stale",
    "partial_run_no_verdict",
    "no_retained_gate_no_verdict",
    "unclassified_requires_amendment",
}

GATE_CANDIDATES = (
    "system/reports/QUALITY_GATE.md",
    "system/reports/quality_gate.md",
    "system/reports/quality_gate.json",
    "reports/QUALITY_GATE.md",
    "reports/quality_gate.md",
    "reports/quality_gate.json",
    "QUALITY_GATE.md",
    "quality_gate.md",
    "quality-gate.md",
    "quality_gate.json",
    "quality-gate.json",
)

POLICY_CANDIDATES = (
    "system/policy/model_routing.json",
    "policy/model_routing.json",
    "config/model_routing.json",
    "config/policy.yaml",
    "config/policy.yml",
    "policy.yaml",
    "policy.yml",
)


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, data: dict[str, Any]) -> None:
    path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def normalize_status_text(value: str) -> str:
    lowered = value.strip().lower()
    if re.search(r"\bnot\s+(pass|passed|green|healthy|ok|success)\b", lowered):
        return "fail"
    if re.search(r"\b(pass|passed|green|healthy|ok|success)\b", lowered):
        return "pass"
    if re.search(r"\b(fail|failed|red|blocked|error)\b", lowered):
        return "fail"
    if re.search(r"\b(warn|warning|yellow|advisory)\b", lowered):
        return "warning"
    return "unknown"


def strongest_status(current: str, candidate: str) -> str:
    precedence = {"unknown": 0, "pass": 1, "warning": 2, "fail": 3}
    if precedence.get(candidate, 0) > precedence.get(current, 0):
        return candidate
    return current


def gate_kind(path: Path) -> str:
    if path.suffix.lower() == ".json":
        return "retained_quality_gate_json"
    return "retained_quality_gate_report"


def parse_text_gate(path: Path) -> dict[str, Any]:
    text = path.read_text(encoding="utf-8", errors="replace")
    state = "unknown"
    for line in text.splitlines():
        match = re.match(
            r"\s*(?:[-*+]\s*)?(?:\*\*)?\s*(status|state|verdict|result)\s*(?:\*\*)?\s*[:=-]\s*(?:\*\*)?\s*(.+?)\s*$",
            line,
            re.IGNORECASE,
        )
        if match:
            state = strongest_status(state, normalize_status_text(match.group(2)))
            if state == "fail":
                break

    lowered = text.lower()
    if state == "unknown":
        pass_seen = normalize_status_text(lowered) == "pass"
        fail_seen = bool(re.search(r"\b(fail|failed|red|blocked|error)\b", lowered))
        warning_seen = bool(re.search(r"\b(warn|warning|yellow|advisory)\b", lowered))
        if fail_seen and not pass_seen:
            state = "fail"
        elif pass_seen and not fail_seen:
            state = "pass"
        elif warning_seen and not pass_seen and not fail_seen:
            state = "warning"

    score_match = re.search(r"\bscore\b[^0-9-]*(-?[0-9]+)", lowered)

    parsed: dict[str, Any] = {
        "path": str(path),
        "kind": gate_kind(path),
        "state": state,
    }
    if score_match:
        parsed["score"] = int(score_match.group(1))
    return parsed


def normalize_state(value: object) -> str:
    normalized = str(value).strip().lower()
    if normalized in {"pass", "passed", "green", "healthy", "ok", "success"}:
        return "pass"
    if normalized in {"fail", "failed", "red", "blocked", "error"}:
        return "fail"
    if normalized in {"warn", "warning", "yellow", "advisory"}:
        return "warning"
    return "unknown"


def parse_json_gate(path: Path) -> dict[str, Any]:
    data = load_json(path)
    state = "unknown"
    if isinstance(data, dict):
        for key in ("status", "state", "verdict", "result"):
            if key in data:
                state = normalize_state(data[key])
                break
    parsed: dict[str, Any] = {
        "path": str(path),
        "kind": gate_kind(path),
        "state": state,
    }
    if isinstance(data, dict):
        for key in ("score", "quality_score"):
            if isinstance(data.get(key), (int, float)):
                parsed["score"] = data[key]
                break
    else:
        parsed["unsupported_json_root"] = type(data).__name__
    return parsed


def collect_gate_sources(target: Path) -> list[dict[str, Any]]:
    sources: list[dict[str, Any]] = []
    for relpath in GATE_CANDIDATES:
        path = target / relpath
        if not path.is_file():
            continue
        try:
            parsed = parse_json_gate(path) if path.suffix.lower() == ".json" else parse_text_gate(path)
        except (OSError, json.JSONDecodeError, UnicodeDecodeError) as exc:
            parsed = {
                "path": str(path),
                "kind": gate_kind(path),
                "state": "unknown",
                "parse_error": str(exc),
            }
        parsed["path"] = relpath
        sources.append(parsed)
    return sources


def collect_policy_sources(target: Path) -> list[dict[str, str]]:
    sources: list[dict[str, str]] = []
    for relpath in POLICY_CANDIDATES:
        if (target / relpath).is_file():
            sources.append({"path": relpath, "kind": "target_policy_hint"})
    return sources


def audit_status(
    output_dir: Path,
    scorecard: dict[str, Any],
    status_override: str | None = None,
    missing_override: list[str] | None = None,
) -> tuple[str, list[str]]:
    if status_override:
        return status_override, missing_override or []

    receipt_path = output_dir / "AUDIT_RUN_RECEIPT.json"
    if receipt_path.is_file():
        receipt = load_json(receipt_path)
        missing = [str(item) for item in receipt.get("missing_required_artifacts", [])]
        status = str(receipt.get("status") or "unknown")
        return status, missing

    meta = scorecard.get("meta", {})
    if isinstance(meta, dict) and meta.get("audit_status"):
        missing = [str(item) for item in meta.get("missing_required_artifacts", [])]
        return str(meta["audit_status"]), missing

    required = ("SCORECARD.json", "SCORECARD_RECEIPTS.json", "AUDIT_REPORT.md")
    missing = [name for name in required if not (output_dir / name).is_file()]
    return ("partial" if missing else "completed"), missing


def generic_score_summary(scorecard: dict[str, Any], audit_state: str, missing: list[str]) -> dict[str, Any]:
    tier1 = scorecard.get("tier1_checks", {})
    return {
        "composite": scorecard.get("composite"),
        "tier1_failed": tier1.get("failed", 0) if isinstance(tier1, dict) else 0,
        "tier1_failures": tier1.get("failures", []) if isinstance(tier1, dict) else [],
        "audit_status": audit_state,
        "partial_artifact_contract": bool(missing) or audit_state != "completed",
        "missing_required_artifacts": missing,
    }


def raw_target_gate_state(sources: list[dict[str, Any]]) -> str:
    if not sources:
        return "no_retained_gate"
    states = [str(source.get("state", "unknown")) for source in sources]
    if "fail" in states:
        return "fail"
    if "warning" in states:
        return "warning"
    if "pass" in states:
        return "pass"
    return "unknown"


def classify_target_gate_state(
    raw_gate_state: str,
    generic_score: dict[str, Any],
    policy_sources: list[dict[str, str]],
) -> tuple[str, str]:
    if generic_score["partial_artifact_contract"]:
        return "partial_run", "partial_run_no_verdict"
    if raw_gate_state == "no_retained_gate":
        return "no_retained_gate", "no_retained_gate_no_verdict"
    if raw_gate_state == "unknown":
        return "amendment_required_unknown", "unclassified_requires_amendment"

    composite = generic_score.get("composite")
    try:
        composite_value = int(composite)
    except (TypeError, ValueError):
        composite_value = 0
    tier1_failed = int(generic_score.get("tier1_failed") or 0)

    if raw_gate_state == "pass" and (tier1_failed > 0 or composite_value < 60):
        if policy_sources:
            return "parseable_pass", "unresolved"
        return "stale_fleet_metric", "fleet_metric_stale"
    if raw_gate_state == "fail" and tier1_failed == 0 and composite_value >= 60:
        return "true_target_risk", "true_target_risk"
    if raw_gate_state == "pass":
        return "parseable_pass", "unresolved"
    if raw_gate_state == "fail":
        return "parseable_fail", "unresolved"
    if raw_gate_state == "warning":
        return "parseable_warning", "unresolved"
    return "amendment_required_unknown", "unclassified_requires_amendment"


def build_receipt(
    target: Path,
    output_dir: Path,
    scorecard: dict[str, Any],
    status_override: str | None = None,
    missing_override: list[str] | None = None,
) -> dict[str, Any]:
    gate_sources = collect_gate_sources(target)
    policy_sources = collect_policy_sources(target)
    audit_state, missing = audit_status(output_dir, scorecard, status_override, missing_override)
    generic_score = generic_score_summary(scorecard, audit_state, missing)
    raw_gate_state = raw_target_gate_state(gate_sources)
    gate_state, contradiction = classify_target_gate_state(raw_gate_state, generic_score, policy_sources)
    if contradiction not in CONTRADICTION_ENUM:
        contradiction = "unclassified_requires_amendment"
        gate_state = "amendment_required_unknown"

    status = "present"
    if generic_score["partial_artifact_contract"]:
        status = "partial"
    elif not gate_sources:
        status = "no_retained_gate"

    return {
        "adapter_version": ADAPTER_VERSION,
        "status": status,
        "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "sources": gate_sources,
        "policy_sources": policy_sources,
        "raw_target_gate_state": raw_gate_state,
        "target_gate_state": gate_state,
        "generic_score": generic_score,
        "contradiction": contradiction,
        "contradiction_enum_status": "provisional_research",
        "amendment_required": contradiction == "unclassified_requires_amendment",
        "bounded_non_claim": (
            "Target-native quality gate evidence is parallel truth; it does not replace "
            "the generic fleet score or turn partial diagnostics into target-quality verdicts."
        ),
    }


def update_scorecard_pointer(scorecard_path: Path, receipt: dict[str, Any]) -> None:
    scorecard = load_json(scorecard_path)
    receipts = scorecard.setdefault("receipts", {})
    receipts["target_native_quality_gates"] = {
        "file": "TARGET_NATIVE_QUALITY_GATES.json",
        "version": receipt["adapter_version"],
        "status": receipt["status"],
        "target_gate_state": receipt["target_gate_state"],
        "contradiction": receipt["contradiction"],
    }
    write_json(scorecard_path, scorecard)


def update_receipts(receipts_path: Path, receipt: dict[str, Any]) -> None:
    receipts = load_json(receipts_path)
    if not isinstance(receipts, dict):
        raise ValueError("SCORECARD_RECEIPTS.json root must be an object")
    receipts["target_native_quality_gates"] = receipt
    write_json(receipts_path, receipts)


def clear_previous_output(output_dir: Path) -> None:
    target_native_path = output_dir / "TARGET_NATIVE_QUALITY_GATES.json"
    target_native_path.unlink(missing_ok=True)

    scorecard_path = output_dir / "SCORECARD.json"
    if scorecard_path.is_file():
        scorecard = load_json(scorecard_path)
        if isinstance(scorecard, dict):
            receipts = scorecard.get("receipts")
            if isinstance(receipts, dict) and receipts.pop("target_native_quality_gates", None) is not None:
                write_json(scorecard_path, scorecard)

    receipts_path = output_dir / "SCORECARD_RECEIPTS.json"
    if receipts_path.is_file():
        receipts = load_json(receipts_path)
        if isinstance(receipts, dict) and receipts.pop("target_native_quality_gates", None) is not None:
            write_json(receipts_path, receipts)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("target_repo")
    parser.add_argument("audit_output_dir")
    parser.add_argument("--audit-status", choices=("completed", "partial", "failed"))
    parser.add_argument("--missing-required-artifacts", default="")
    args = parser.parse_args()

    target = Path(args.target_repo).resolve()
    output_dir = Path(args.audit_output_dir).resolve()
    scorecard_path = output_dir / "SCORECARD.json"
    receipts_path = output_dir / "SCORECARD_RECEIPTS.json"

    scorecard: dict[str, Any] = {}
    if scorecard_path.is_file():
        loaded_scorecard = load_json(scorecard_path)
        if not isinstance(loaded_scorecard, dict):
            print("target-native: SCORECARD.json root is not an object", file=sys.stderr)
            return 2
        scorecard = loaded_scorecard
    missing_override = [item for item in args.missing_required_artifacts.split() if item]
    receipt = build_receipt(target, output_dir, scorecard, args.audit_status, missing_override)

    write_json(output_dir / "TARGET_NATIVE_QUALITY_GATES.json", receipt)
    if scorecard_path.is_file():
        update_scorecard_pointer(scorecard_path, receipt)
    if receipts_path.is_file():
        update_receipts(receipts_path, receipt)
    print(
        "target-native: emitted TARGET_NATIVE_QUALITY_GATES.json "
        f"({receipt['target_gate_state']}; {receipt['contradiction']})"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
