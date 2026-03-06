---
name: scoring
version: 1.0.0
description: >
  Score a repository across 5 audit dimensions, producing SCORECARD.json
  with composite score (0-100), T1/T2 tiered checks, maturity phase,
  and stall risk assessment.
author: briancl2
tags: [audit, scoring, dimensions, deterministic]
---

# Scoring Skill

## Purpose

Compute a 5-dimension score for any repository based on pre-scan output
and tool analysis results. Produces the canonical SCORECARD.json artifact
with composite scores, tiered checks, and maturity classification.

## When to Use

- After pre-scan phase completes (requires tool output files)
- To re-score a repository after changes
- For scorecard comparison (pre/post delta)

## Scripts

| Script | Purpose |
|---|---|
| `scripts/score-audit-dimensions.sh` | 5-dimension scorer, produces SCORECARD.json |
| `scripts/stall-risk-score.sh` | 6-signal stall risk predictor (0-100) |
| `scripts/classify-repo-maturity.sh` | AI maturity phase classifier |
| `scripts/compare-scorecards.sh` | Pre/post SCORECARD delta computation |

## Inputs

| Input | Required | Description |
|---|---|---|
| audit_output_dir | Yes | Directory with tool outputs (maturity.txt, stall-risk.txt, etc.) |

## Outputs

| Output | Format | Description |
|---|---|---|
| SCORECARD.json | JSON | 5-dimension scores, composite, T1/T2 checks |
| Stall risk report | Text | 6-signal stall risk assessment |
| Maturity classification | Text | Phase classification (1-5) |

## Usage

```bash
# Full scoring pipeline
bash scripts/score-audit-dimensions.sh audit_output/

# Individual tools
bash scripts/stall-risk-score.sh /path/to/repo
bash scripts/classify-repo-maturity.sh /path/to/repo
bash scripts/compare-scorecards.sh before.json after.json
```
