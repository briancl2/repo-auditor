#!/usr/bin/env python3
"""assemble_ds_results.py — Assemble DS-34+ results from temp dir.

Usage: python3 assemble_ds_results.py <tmpdir> <repo_name> <repo_path> [output_dir]
"""

import json
import os
import sys


GENERICITY_CLOSURE_SIGNATURES = {
    "AS-22": {
        "scope": "generic_repo_health_detector",
        "finding_signal": "github_native_closure_regrowth_count",
        "metadata_status": "closure_detector_metadata_allowed_when_zero_count",
    },
    "AS-34": {
        "scope": "generic_repo_health_detector",
        "finding_signal": "closure_run_identity_gap_count",
        "metadata_status": "closure_detector_metadata_allowed_when_zero_count",
    },
}


def classify_genericity_scope(result):
    signature_id = result.get("ds_id", "unknown")
    config = GENERICITY_CLOSURE_SIGNATURES.get(signature_id)
    if not config:
        return None

    if result.get("error"):
        return {
            "ds_id": signature_id,
            "name": result.get("name", signature_id),
            "scope": config["scope"],
            "finding_signal": config["finding_signal"],
            "target_finding_count": None,
            "status": "detector_error",
            "fired": bool(result.get("fired")),
        }

    signals = result.get("signals")
    if not isinstance(signals, dict):
        signals = {}
    finding_signal = config["finding_signal"]
    if finding_signal not in signals:
        return {
            "ds_id": signature_id,
            "name": result.get("name", signature_id),
            "scope": config["scope"],
            "finding_signal": finding_signal,
            "target_finding_count": None,
            "status": "detector_signal_missing",
            "fired": bool(result.get("fired")),
        }
    finding_count = signals.get(finding_signal, 0)
    if not isinstance(finding_count, int) or finding_count < 0:
        return {
            "ds_id": signature_id,
            "name": result.get("name", signature_id),
            "scope": config["scope"],
            "finding_signal": finding_signal,
            "target_finding_count": None,
            "status": "detector_signal_missing",
            "fired": bool(result.get("fired")),
        }

    status = (
        "target_finding"
        if bool(result.get("fired")) or finding_count > 0
        else config["metadata_status"]
    )
    return {
        "ds_id": signature_id,
        "name": result.get("name", signature_id),
        "scope": config["scope"],
        "finding_signal": finding_signal,
        "target_finding_count": finding_count,
        "status": status,
        "fired": bool(result.get("fired")),
    }


def main():
    tmpdir = sys.argv[1]
    repo_name = sys.argv[2]
    repo_path = sys.argv[3]
    output_dir = sys.argv[4] if len(sys.argv) > 4 and sys.argv[4] else ""

    results = []
    files = sorted(
        [
            name
            for name in os.listdir(tmpdir)
            if name.startswith("ds_") and name.endswith(".json")
        ],
        key=lambda name: int(name[3:-5]),
    )

    for name in files:
        fpath = os.path.join(tmpdir, name)
        try:
            with open(fpath) as f:
                result = json.load(f)
                genericity_scope = classify_genericity_scope(result)
                if genericity_scope:
                    result["repo_star_genericity_scope"] = genericity_scope
                results.append(result)
        except Exception as e:
            results.append({"error": str(e), "file": name})

    fired = sum(1 for r in results if r.get("fired"))
    total = len(results)
    family_totals = {}
    fired_signatures = []
    genericity_scope_entries = []
    for result in results:
        family = str(result.get("family") or result.get("ds_id", "unknown"))[:2]
        bucket = family_totals.setdefault(
            family,
            {"total": 0, "fired": 0, "signatures": []},
        )
        bucket["total"] += 1
        signature_id = result.get("ds_id", "unknown")
        bucket["signatures"].append(signature_id)
        if result.get("fired"):
            bucket["fired"] += 1
            fired_signatures.append(signature_id)
        genericity_scope = result.get("repo_star_genericity_scope")
        if isinstance(genericity_scope, dict):
            genericity_scope_entries.append(genericity_scope)
    genericity_seen = {str(entry.get("ds_id")) for entry in genericity_scope_entries}
    genericity_missing = sorted(set(GENERICITY_CLOSURE_SIGNATURES) - genericity_seen)
    genericity_errored = sorted(
        str(entry.get("ds_id"))
        for entry in genericity_scope_entries
        if entry.get("status") == "detector_error"
    )
    genericity_incomplete = sorted(
        str(entry.get("ds_id"))
        for entry in genericity_scope_entries
        if entry.get("status") in {"detector_error", "detector_signal_missing"}
    )
    genericity_scope_complete = not genericity_missing and not genericity_incomplete
    closure_signature_target_findings = (
        sum(
            max(
                int(entry.get("target_finding_count") or 0),
                1 if entry.get("status") == "target_finding" else 0,
            )
            for entry in genericity_scope_entries
        )
        if genericity_scope_complete
        else None
    )
    report = {
        "repo": repo_name,
        "repo_path": repo_path,
        "total_ds": total,
        "fired_count": fired,
        "detection_rate_pct": round(fired * 100 / total, 1) if total else 0.0,
        "results": results,
        "capability_metadata": {
            "family_totals": family_totals,
            "fired_signatures": fired_signatures,
            "signature_order": [r.get("ds_id", "unknown") for r in results],
            "repo_star_genericity": {
                "detector_scope": "classified" if genericity_scope_complete else "incomplete",
                "closure_signature_scope_complete": genericity_scope_complete,
                "missing_closure_signature_ids": genericity_missing,
                "errored_closure_signature_ids": genericity_errored,
                "incomplete_closure_signature_ids": genericity_incomplete,
                "closure_signature_metadata": genericity_scope_entries,
                "closure_signature_target_finding_count": closure_signature_target_findings,
                "interpretation": (
                    "AS-22/AS-34 names are generic repo-health detector metadata only "
                    "when closure_signature_scope_complete is true. For repo-star "
                    "genericity proof, treat them as target findings only when their "
                    "classified target_finding_count is nonzero or the signature fired; "
                    "an incomplete scope is not clean proof."
                ),
            },
        },
    }

    print(json.dumps(report, indent=2))

    if output_dir:
        os.makedirs(output_dir, exist_ok=True)
        with open(os.path.join(output_dir, "DS-34-plus-results.json"), "w") as f:
            json.dump(report, f, indent=2)


if __name__ == "__main__":
    main()
