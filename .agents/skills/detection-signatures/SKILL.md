---
name: detection-signatures
version: 1.0.0
description: >
  Run detection signature scripts (DS-34 through DS-43) against a target
  repository. Produces a combined JSON report with per-signature results
  including fired/not-fired status, counts, and evidence.
author: briancl2
tags: [audit, detection, signatures, deterministic]
---

# Detection Signatures Skill

## Purpose

Execute the full suite of detection signature scripts against a target
repository and produce a consolidated JSON report. Each signature tests
for a specific anti-pattern (stale TODOs, unused deps, test theater, etc.).

## When to Use

- During standard or deep audit pipeline (Phase 1 detection)
- For targeted anti-pattern scanning of any repository
- To validate fixes to previously-detected issues

## Scripts

| Script | DS | Purpose |
|---|---|---|
| `scripts/detect-new-signatures.sh` | -- | Unified runner for DS-34 through DS-43 |
| `scripts/detect-stale-todos.sh` | DS-34 | Stale TODO/FIXME detection |
| `scripts/detect-unused-deps.sh` | DS-35 | Unused dependency detection |
| `scripts/detect-green-only-ci.sh` | DS-36 | Green-only CI detection |
| `scripts/detect-readme-drift.sh` | DS-37 | README capability drift |
| `scripts/detect-config-proliferation.sh` | DS-38 | Config format proliferation |
| `scripts/detect-silent-errors.sh` | DS-39 | Silent error handling detection |
| `scripts/detect-commit-entropy.sh` | DS-40 | Commit message entropy |
| `scripts/detect-test-theater.sh` | DS-41 | Test theater detection |
| `scripts/detect-broken-links.sh` | DS-42 | Broken internal link detection |
| `scripts/detect-velocity-bypass.sh` | DS-43 | Autonomous velocity bypass |

## Inputs

| Input | Required | Description |
|---|---|---|
| repo_path | Yes | Path to target repository |
| output_dir | No | Directory for JSON output |

## Outputs

| Output | Format | Description |
|---|---|---|
| Combined JSON report | JSON | Per-signature results with fired status |
| Per-signature JSON | JSON | Individual DS result files |

## Usage

```bash
bash scripts/detect-new-signatures.sh /path/to/repo [output_dir]
```
