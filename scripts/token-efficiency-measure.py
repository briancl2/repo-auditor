#!/usr/bin/env python3
"""Replay the retained BMA token-efficiency corpus into additive pilot artifacts.

This script is intentionally additive: it does not touch SCORECARD semantics.
It replays a bounded source pack into four measurement-mode artifacts and fails
closed when attribution or required measurement fields are unavailable.
"""

from __future__ import annotations

import argparse
import copy
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


ALLOWED_JOIN_CONFIDENCE = {"direct", "derived", "portable"}
EXIT_MEASUREMENT_BLOCKED = 2


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-pack", required=True, help="Path to source-pack JSON")
    parser.add_argument("--output-dir", required=True, help="Directory for output artifacts")
    return parser.parse_args()


def load_json(path: Path) -> Any:
    with path.open() as handle:
        return json.load(handle)


def resolve_path(base: Path, raw_path: str) -> Path:
    path = Path(raw_path)
    if path.is_absolute():
        return path
    return (base / path).resolve()


def append_gap(
    gaps: list[dict[str, Any]],
    code: str,
    detail: str,
    *,
    hotspot_id: str | None = None,
    path: Path | None = None,
) -> None:
    gap: dict[str, Any] = {"code": code, "detail": detail}
    if hotspot_id is not None:
        gap["hotspot_id"] = hotspot_id
    if path is not None:
        gap["path"] = str(path)
    if gap not in gaps:
        gaps.append(gap)


def safe_load_json(
    path: Path,
    gaps: list[dict[str, Any]],
    *,
    missing_code: str,
    invalid_code: str,
    missing_detail: str,
) -> Any | None:
    if not path.exists():
        append_gap(gaps, missing_code, missing_detail, path=path)
        return None
    try:
        return load_json(path)
    except json.JSONDecodeError as exc:
        append_gap(
            gaps,
            invalid_code,
            f"Invalid JSON blocked replay: {exc}",
            path=path,
        )
        return None


def build_measurement_summary(
    source_pack_path: Path,
    source_pack: dict[str, Any],
    summary: dict[str, Any],
    hotspots: list[dict[str, Any]],
    gaps: list[dict[str, Any]],
) -> dict[str, Any]:
    topline = summary.get("topline_metrics", {})
    return {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "schema_version": "1.0.0",
        "artifact": "TOKEN_MEASUREMENT_SUMMARY",
        "measurement_mode": "token_efficiency_pilot",
        "source_pack": {
            "path": str(source_pack_path),
            "fixture_name": source_pack.get("fixture_name"),
        },
        "measurement_status": "measurement_blocked" if gaps else "pass",
        "decision_readiness": topline.get("decision_readiness"),
        "proxy_rows": topline.get("proxy_rows"),
        "proxy_share_pct": topline.get("proxy_share_pct"),
        "unlinked_rows": topline.get("unlinked_rows"),
        "unlinked_share_pct": topline.get("unlinked_share_pct"),
        "benchmark_reliability": topline.get("benchmark_reliability"),
        "hotspots": [
            {
                "hotspot_id": hotspot.get("hotspot_id"),
                "impact_rank": hotspot.get("impact_rank"),
                "classification_confidence": hotspot.get("classification_confidence"),
                "classification_confidence_score": hotspot.get("classification_confidence_score"),
                "actionability_status": hotspot.get("actionability_status"),
                "actionability_summary": hotspot.get("actionability_summary"),
                "blocked_hotspot": hotspot.get("blocked_hotspot"),
                "provisional_candidate": hotspot.get("provisional_candidate"),
                "deterministic_evidence_ready": hotspot.get("deterministic_evidence_ready"),
                "labeled_session_count": hotspot.get("labeled_session_count"),
            }
            for hotspot in hotspots
        ],
        "instrumentation_gaps": gaps,
        "exact_attribution_policy": "fail_closed",
        "non_claims": [
            "This additive pilot does not reinterpret SCORECARD.json as token-efficiency evidence.",
            "This output does not authorize advisory remediation without a bounded consumer.",
            "No proxy downgrade is applied when exact attribution is unavailable.",
        ],
    }


def validate_summary(
    source_pack: dict[str, Any],
    summary: dict[str, Any],
    gaps: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    topline = summary.get("topline_metrics", {})
    for field in source_pack.get("required_topline_fields", []):
        if field not in topline:
            append_gap(
                gaps,
                "missing_required_topline_field",
                f"Required measurement field '{field}' is absent from summary_production.",
            )
    hotspots = summary.get("hotspots")
    if not isinstance(hotspots, list) or not hotspots:
        append_gap(
            gaps,
            "missing_hotspots",
            "summary_production does not expose hotspot rows to replay.",
        )
        return []

    for hotspot in hotspots:
        hotspot_id = hotspot.get("hotspot_id", "<missing-hotspot-id>")
        for field in source_pack.get("required_hotspot_fields", []):
            if field not in hotspot:
                append_gap(
                    gaps,
                    "missing_required_hotspot_field",
                    f"Hotspot field '{field}' is absent from summary_production.",
                    hotspot_id=hotspot_id,
                )
    return hotspots


def select_replay_hotspots(
    source_pack: dict[str, Any],
    summary_hotspots: list[dict[str, Any]],
    gaps: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    requested = source_pack.get("replay_hotspots")
    if not requested:
        return summary_hotspots

    hotspot_index = {
        hotspot.get("hotspot_id"): hotspot
        for hotspot in summary_hotspots
        if hotspot.get("hotspot_id")
    }
    selected: list[dict[str, Any]] = []
    for hotspot_id in requested:
        hotspot = hotspot_index.get(hotspot_id)
        if hotspot is None:
            append_gap(
                gaps,
                "missing_replay_hotspot",
                "The source pack requested a hotspot that is absent from summary_production.",
                hotspot_id=hotspot_id,
            )
            continue
        selected.append(hotspot)
    return selected


def validate_labels(
    labels_path: Path | None,
    labels: Any | None,
    gaps: list[dict[str, Any]],
    strict_checks: dict[str, Any],
) -> None:
    if not strict_checks.get("require_benchmark_labels", False):
        return
    if not isinstance(labels, dict) or not labels.get("labels"):
        append_gap(
            gaps,
            "missing_benchmark_labels",
            "Benchmark labels are required for the replay pilot and were missing or empty.",
            path=labels_path,
        )


def require_source_path(
    sources: dict[str, Path],
    key: str,
    gaps: list[dict[str, Any]],
    *,
    code: str,
    detail: str,
) -> Path | None:
    path = sources.get(key)
    if path is None:
        append_gap(gaps, code, detail)
    return path


def build_packet_index(
    packet_root: dict[str, Any],
    gaps: list[dict[str, Any]],
) -> dict[str, dict[str, Any]]:
    index: dict[str, dict[str, Any]] = {}
    for packet in packet_root.get("packets", []):
        hotspot_id = packet.get("hotspot_id")
        if not hotspot_id:
            append_gap(
                gaps,
                "missing_packet_hotspot_id",
                "A source packet is missing hotspot_id.",
            )
            continue
        index[hotspot_id] = packet
    return index


def build_brief_index(
    brief_root: dict[str, Any],
    gaps: list[dict[str, Any]],
) -> dict[str, dict[str, Any]]:
    index: dict[str, dict[str, Any]] = {}
    for brief in brief_root.get("briefs", []):
        hotspot_id = brief.get("hotspot_id")
        if not hotspot_id:
            append_gap(
                gaps,
                "missing_brief_hotspot_id",
                "A source brief is missing hotspot_id.",
            )
            continue
        index[hotspot_id] = brief
    return index


def enrich_packets(
    summary_hotspots: list[dict[str, Any]],
    packet_root: dict[str, Any],
    strict_checks: dict[str, Any],
    gaps: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    packet_index = build_packet_index(packet_root, gaps)
    ordered_packets: list[dict[str, Any]] = []

    for hotspot in summary_hotspots:
        hotspot_id = hotspot.get("hotspot_id")
        source_packet = copy.deepcopy(packet_index.get(hotspot_id))
        packet_gap_codes: list[str] = []

        if source_packet is None:
            append_gap(
                gaps,
                "missing_evidence_packet",
                "Source pack does not provide an evidence packet for a replayed hotspot.",
                hotspot_id=hotspot_id,
            )
            source_packet = {
                "hotspot_id": hotspot_id,
                "intended_audience": "repo-auditor measurement pilot",
                "scope": hotspot.get("scope", {}),
                "spend": {
                    "live_tokens": hotspot.get("live_tokens"),
                    "share_pct": hotspot.get("share_pct"),
                    "session_count": hotspot.get("session_count"),
                },
                "current_state": {
                    "classification": hotspot.get("classification"),
                    "classification_recommendation": hotspot.get("recommended_next_move"),
                    "user_facing_outcome": hotspot.get("user_facing_outcome"),
                    "internal_measurement_status": "measurement_blocked",
                    "next_step": "Restore the missing source packet before replay.",
                },
                "benchmark_context": {
                    "decision_readiness": hotspot.get("readiness"),
                },
                "linkage_state": {
                    "gate_pass": False,
                    "failed_reasons": ["missing_evidence_packet"],
                    "instrumentation_gap_reasons": ["missing_evidence_packet"],
                },
                "known_ambiguities": ["The source evidence packet was missing from the pilot corpus."],
                "retained_evidence": {
                    "artifact_refs": [],
                    "session_refs": [],
                    "linked_work_dirs": [],
                    "evidence_receipts": {},
                },
                "agentic_analysis_ready": False,
            }
            packet_gap_codes.append("missing_evidence_packet")

        retained_evidence = source_packet.get("retained_evidence", {})
        session_refs = retained_evidence.get("session_refs", [])
        if strict_checks.get("require_session_join_confidence", False):
            if not isinstance(session_refs, list) or not session_refs:
                packet_gap_codes.append("missing_session_attribution")
            else:
                for session_ref in session_refs:
                    if session_ref.get("join_confidence") not in ALLOWED_JOIN_CONFIDENCE:
                        packet_gap_codes.append("missing_session_join_confidence")
                        break

        if not isinstance(source_packet.get("linkage_state"), dict):
            packet_gap_codes.append("missing_linkage_state")

        for code in sorted(set(packet_gap_codes)):
            append_gap(
                gaps,
                code,
                "Exact attribution is unavailable for this packet, so the pilot must fail closed.",
                hotspot_id=hotspot_id,
            )

        existing_gap_reasons = []
        if isinstance(source_packet.get("linkage_state"), dict):
            existing_gap_reasons = source_packet["linkage_state"].get("instrumentation_gap_reasons", []) or []

        source_packet["impact_rank"] = hotspot.get("impact_rank")
        source_packet["classification_confidence"] = hotspot.get("classification_confidence")
        source_packet["classification_confidence_score"] = hotspot.get("classification_confidence_score")
        source_packet["actionability_status"] = hotspot.get("actionability_status")
        source_packet["actionability_summary"] = hotspot.get("actionability_summary")
        source_packet["blocked_hotspot"] = hotspot.get("blocked_hotspot")
        source_packet["provisional_candidate"] = hotspot.get("provisional_candidate")
        source_packet["instrumentation_gap_reasons"] = sorted(
            set(existing_gap_reasons + packet_gap_codes)
        )
        source_packet["instrumentation_gap"] = bool(source_packet["instrumentation_gap_reasons"])
        source_packet["measurement_status"] = (
            "measurement_blocked" if source_packet["instrumentation_gap"] else "replay_ready"
        )
        ordered_packets.append(source_packet)

    return ordered_packets


def enrich_briefs(
    summary_hotspots: list[dict[str, Any]],
    brief_root: dict[str, Any],
    gaps: list[dict[str, Any]],
) -> dict[str, Any]:
    brief_index = build_brief_index(brief_root, gaps)
    ordered_briefs: list[dict[str, Any]] = []

    for hotspot in summary_hotspots:
        hotspot_id = hotspot.get("hotspot_id")
        source_brief = brief_index.get(hotspot_id)
        if source_brief is None:
            append_gap(
                gaps,
                "missing_root_cause_brief",
                "Source pack does not provide a rooted brief for a replayed hotspot.",
                hotspot_id=hotspot_id,
            )
            continue

        brief = copy.deepcopy(source_brief)
        brief["measurement_context"] = {
            "impact_rank": hotspot.get("impact_rank"),
            "classification_confidence": hotspot.get("classification_confidence"),
            "actionability_status": hotspot.get("actionability_status"),
            "blocked_hotspot": hotspot.get("blocked_hotspot"),
            "provisional_candidate": hotspot.get("provisional_candidate"),
        }
        ordered_briefs.append(brief)

    enriched_root = copy.deepcopy(brief_root)
    enriched_root["briefs"] = ordered_briefs
    return enriched_root


def enrich_workflows(
    workflow_root: dict[str, Any],
    strict_checks: dict[str, Any],
    gaps: list[dict[str, Any]],
) -> dict[str, Any]:
    enriched_root = copy.deepcopy(workflow_root)
    workflows = enriched_root.get("workflows", [])
    if not isinstance(workflows, list):
        append_gap(
            gaps,
            "missing_workflow_rows",
            "workflow_investigations does not expose a workflows list.",
        )
        enriched_root["workflows"] = []
        return enriched_root

    if strict_checks.get("require_workflow_measurement_validity", False):
        for workflow in workflows:
            workflow_family = workflow.get("workflow_family", "<missing-workflow-family>")
            if "measurement_validity" not in workflow:
                append_gap(
                    gaps,
                    "missing_workflow_measurement_validity",
                    "Workflow replay requires measurement_validity to stay explicit.",
                    hotspot_id=workflow_family,
                )
            if "decision_readiness" not in workflow:
                append_gap(
                    gaps,
                    "missing_workflow_decision_readiness",
                    "Workflow replay requires decision_readiness to stay explicit.",
                    hotspot_id=workflow_family,
                )
    return enriched_root


def write_json(path: Path, payload: Any) -> None:
    path.write_text(json.dumps(payload, indent=2) + "\n")


def main() -> int:
    args = parse_args()
    source_pack_path = Path(args.source_pack).resolve()
    output_dir = Path(args.output_dir).resolve()
    output_dir.mkdir(parents=True, exist_ok=True)

    source_pack = load_json(source_pack_path)
    strict_checks = source_pack.get("strict_attribution_checks", {})
    source_base = source_pack_path.parent
    sources = {
        label: resolve_path(source_base, raw_path)
        for label, raw_path in source_pack.get("sources", {}).items()
    }

    gaps: list[dict[str, Any]] = []

    labels_path = sources.get("benchmark_labels")
    summary_path = require_source_path(
        sources,
        "summary_production",
        gaps,
        code="missing_summary_source_path",
        detail="source-pack.sources does not define summary_production.",
    )
    packet_path = require_source_path(
        sources,
        "hotspot_evidence_packets",
        gaps,
        code="missing_hotspot_packets_source_path",
        detail="source-pack.sources does not define hotspot_evidence_packets.",
    )
    brief_path = require_source_path(
        sources,
        "agentic_root_cause_briefs",
        gaps,
        code="missing_root_cause_briefs_source_path",
        detail="source-pack.sources does not define agentic_root_cause_briefs.",
    )
    workflow_path = require_source_path(
        sources,
        "workflow_investigations",
        gaps,
        code="missing_workflow_investigations_source_path",
        detail="source-pack.sources does not define workflow_investigations.",
    )

    labels = safe_load_json(
        labels_path,
        gaps,
        missing_code="missing_benchmark_labels",
        invalid_code="invalid_benchmark_labels",
        missing_detail="Benchmark labels are required for the replay pilot and the source file was missing.",
    ) if labels_path else None
    summary = safe_load_json(
        summary_path,
        gaps,
        missing_code="missing_summary_production",
        invalid_code="invalid_summary_production",
        missing_detail="summary_production is required for the replay pilot and the source file was missing.",
    ) if summary_path else None
    packet_root = safe_load_json(
        packet_path,
        gaps,
        missing_code="missing_hotspot_packets",
        invalid_code="invalid_hotspot_packets",
        missing_detail="hotspot_evidence_packets is required for the replay pilot and the source file was missing.",
    ) if packet_path else None
    brief_root = safe_load_json(
        brief_path,
        gaps,
        missing_code="missing_root_cause_briefs",
        invalid_code="invalid_root_cause_briefs",
        missing_detail="agentic_root_cause_briefs is required for the replay pilot and the source file was missing.",
    ) if brief_path else None
    workflow_root = safe_load_json(
        workflow_path,
        gaps,
        missing_code="missing_workflow_investigations",
        invalid_code="invalid_workflow_investigations",
        missing_detail="workflow_investigations is required for the replay pilot and the source file was missing.",
    ) if workflow_path else None

    validate_labels(labels_path, labels, gaps, strict_checks)

    summary = summary or {}
    packet_root = packet_root or {"generated_at": None, "intended_audience": None, "packets": []}
    brief_root = brief_root or {"generated_at": None, "briefs": []}
    workflow_root = workflow_root or {"generated_at": None, "workflows": []}

    summary_hotspots = validate_summary(source_pack, summary, gaps)
    summary_hotspots = select_replay_hotspots(source_pack, summary_hotspots, gaps)
    enriched_packets = enrich_packets(summary_hotspots, packet_root, strict_checks, gaps)
    enriched_briefs = enrich_briefs(summary_hotspots, brief_root, gaps)
    enriched_workflows = enrich_workflows(workflow_root, strict_checks, gaps)

    measurement_summary = build_measurement_summary(
        source_pack_path,
        source_pack,
        summary,
        summary_hotspots,
        gaps,
    )

    packet_output = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "schema_version": "1.0.0",
        "measurement_status": measurement_summary["measurement_status"],
        "source_pack": measurement_summary["source_pack"],
        "instrumentation_gaps": gaps,
        "packets": enriched_packets,
    }

    brief_output = copy.deepcopy(enriched_briefs)
    brief_output["generated_at"] = datetime.now(timezone.utc).isoformat()
    brief_output["measurement_status"] = measurement_summary["measurement_status"]
    brief_output["instrumentation_gaps"] = gaps

    workflow_output = copy.deepcopy(enriched_workflows)
    workflow_output["generated_at"] = datetime.now(timezone.utc).isoformat()
    workflow_output["measurement_status"] = measurement_summary["measurement_status"]
    workflow_output["instrumentation_gaps"] = gaps

    write_json(output_dir / "TOKEN_MEASUREMENT_SUMMARY.json", measurement_summary)
    write_json(output_dir / "HOTSPOT_EVIDENCE_PACKETS.json", packet_output)
    write_json(output_dir / "AGENTIC_ROOT_CAUSE_BRIEFS.json", brief_output)
    write_json(output_dir / "WORKFLOW_INVESTIGATIONS.json", workflow_output)

    return 0 if not gaps else EXIT_MEASUREMENT_BLOCKED


if __name__ == "__main__":
    raise SystemExit(main())
