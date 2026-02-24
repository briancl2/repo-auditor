# Feature Spec: Automated Testing for repo-auditor

> **ID:** 001-automated-testing
> **Date:** 2026-02-16
> **Author:** build-meta-analysis pipeline (spec 009 fleet dispatch)
> **Constitution check:** ✅ §1 (deterministic-first), §2 (5-dimension scoring), §3 (tier architecture)

## Problem Statement

repo-auditor has 14 scripts (10 domain + 4 infrastructure) that produce SCORECARD.json and AUDIT_REPORT.md but
no automated test suite to verify correctness. The Makefile has test targets
(`make audit`) but no regression tests that verify dimension scores against
known-good baselines for fixture repos.

## Goal

1. Create a test fixture repo with known characteristics so dimension scores are predictable
2. Add a `make test` target that runs the auditor against the fixture and verifies SCORECARD.json
3. Verify each of the 5 dimensions produces expected scores for the fixture

## Non-Goals

- Testing LLM components (auditor is deterministic by design)
- Testing against live target repos (fixture only)
- Performance benchmarking

## Hypotheses

| ID | Hypothesis | Test Method | PASS Criterion | Status |
|---|---|---|---|---|
| AT-1 | Fixture repo with known structure produces repeatable scores | Run auditor 3x on fixture, compare SCORECARD.json | All 3 runs produce identical composite score | NOT STARTED |
| AT-2 | Test suite catches regression in dimension scoring | Modify a scorer, run tests | Test fails when score formula changes | NOT STARTED |

## Success Criteria

| ID | Criterion | Status |
|---|---|---|
| SC-001 | `make test` target exists and runs without errors | NOT STARTED |
| SC-002 | Test fixture repo has known D1-D5 characteristics | NOT STARTED |
| SC-003 | SCORECARD.json validation checks dimension ranges | NOT STARTED |
