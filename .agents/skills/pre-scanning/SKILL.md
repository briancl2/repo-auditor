---
name: pre-scanning
version: 1.0.0
description: >
  Deterministic pre-scan of target repositories (0 LLM tokens).
  Produces file inventory, AI surface analysis, .gitignore audit,
  and large file detection. Foundation for all audit dimensions.
author: briancl2
tags: [audit, pre-scan, deterministic, inventory]
---

# Pre-Scanning Skill

## Purpose

Produce a deterministic snapshot of a repository's structure, AI surfaces,
and file inventory. This is the first step in every audit pipeline (standard
and deep mode) and runs with 0 LLM tokens.

## When to Use

- Before any LLM-powered audit phase
- To establish a stable baseline for score computation
- To detect AI surfaces (.agents/, skills/, agents, etc.)
- For repo health inventory (file counts, large files, .gitignore)

## Scripts

| Script | Purpose |
|---|---|
| `scripts/pre-scan-target.sh` | Main pre-scan script — produces PRE_SCAN.md + AI_SURFACES_FULL.md |

## Usage

```bash
bash .agents/skills/pre-scanning/scripts/pre-scan-target.sh <target_path> <output_dir>
```

## Outputs

| File | Description |
|---|---|
| `PRE_SCAN.md` | File inventory, directory tree, AI surface summary |
| `AI_SURFACES_FULL.md.gz` | Compressed full AI surface listing (agents, skills, configs) |

## Constraints

- Zero LLM tokens — purely deterministic bash
- Must complete in <30 seconds for repos with <500 files
- Handles repos up to 200 files by default (stop rule)
