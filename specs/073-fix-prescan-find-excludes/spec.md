# Fix pre-scan find commands to use $FIND_EXCLUDES

> **ID:** 073-fix-prescan-find-excludes
> **Date:** 2026-03-04
> **Source:** BMA Stage 12 Phase 0 profiling (v157)
> **Target:** repo-auditor
> **Layer:** system

## Problem Statement

Three `find` commands in `pre-scan-target.sh` do not use `$FIND_EXCLUDES` despite the
comment at line 50 ("all find commands respect .auditorignore"). This causes BMA audit
to scan 23,087 files instead of 951, making pre-scan take ~236s (89% of total audit time).

**Evidence:**
- BMA audit profiling (3 runs): mean 264s, pre-scan 236s (89.4%)
- LARGE_FILES.md section: `find` at line 261 scans all files, runs `wc -l` on each
- Directory Structure (line 160): `find` uses hardcoded excludes, not `$FIND_EXCLUDES`
- File Distribution (line 166): `find` uses hardcoded excludes, not `$FIND_EXCLUDES`

## Goal

1. Apply `$FIND_EXCLUDES` to all 3 missed `find` commands
2. BMA audit drops from ~264s to <60s
3. Comment at line 50 becomes accurate

## Acceptance Criteria

1. All `find` commands in pre-scan-target.sh use `$FIND_EXCLUDES`
2. No hardcoded excludes remain outside `$FIND_EXCLUDES` definition
3. BMA audit time <120s (relaxed target; <60s expected)
4. pre-scan output still produces correct PRE_SCAN.md, LARGE_FILES.md
