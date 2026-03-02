#!/usr/bin/env python3
"""assemble_ds_results.py — Assemble DS-34-42 results from temp dir.

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
    for i in range(9):
        fpath = os.path.join(tmpdir, f"ds_{i}.json")
        try:
            with open(fpath) as f:
                results.append(json.load(f))
        except Exception as e:
            results.append({"error": str(e), "index": i})

    fired = sum(1 for r in results if r.get("fired"))
    report = {
        "repo": repo_name,
        "repo_path": repo_path,
        "total_ds": 9,
        "fired_count": fired,
        "detection_rate_pct": round(fired * 100 / 9, 1),
        "results": results,
    }

    print(json.dumps(report, indent=2))

    if output_dir:
        os.makedirs(output_dir, exist_ok=True)
        with open(os.path.join(output_dir, "DS-34-42-results.json"), "w") as f:
            json.dump(report, f, indent=2)


if __name__ == "__main__":
    main()
