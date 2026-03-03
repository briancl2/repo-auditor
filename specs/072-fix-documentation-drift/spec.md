# Fix stale documentation and content drift

> **ID:** 072-fix-stale-documentation-and-content-drif
> **Date:** 2026-03-03
> **Source:** Fleet advisor (claude-opus-4.6) from DS-31 finding
> **Target:** repo-auditor
> **Layer:** system

## Problem Statement

T1-DRIFT: drift 55% > 30%. AGENTS.md capabilities diverged from scripts.

**Evidence:**
- T1-DRIFT: drift 55% > 30%. AGENTS.md capabilities diverged from scripts.

## Goal

1. Resolve DS-31 finding: Fix stale documentation and content drift
2. Verify fix with acceptance criteria
3. No regressions (make check passes)

## Acceptance Criteria

1. DS-31 no longer fires on target repo
2. make check passes
3. No regressions in SCORECARD composite
