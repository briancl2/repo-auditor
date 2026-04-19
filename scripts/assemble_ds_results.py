#!/usr/bin/env python3
"""assemble_ds_results.py — Assemble DS-34+ results from temp dir.

Usage: python3 assemble_ds_results.py <tmpdir> <repo_name> <repo_path> [output_dir]
"""

import json
import os
import sys


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
                results.append(json.load(f))
        except Exception as e:
            results.append({"error": str(e), "file": name})

    fired = sum(1 for r in results if r.get("fired"))
    total = len(results)
    family_totals = {}
    fired_signatures = []
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
        },
    }

    print(json.dumps(report, indent=2))

    if output_dir:
        os.makedirs(output_dir, exist_ok=True)
        with open(os.path.join(output_dir, "DS-34-plus-results.json"), "w") as f:
            json.dump(report, f, indent=2)


if __name__ == "__main__":
    main()
