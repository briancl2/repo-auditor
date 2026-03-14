# Implementation Plan: Port zero-match counting guardrails from harvested fleet learning

**Spec:** 074-port-zero-match-counting-guardrails | **Date:** 2026-03-14 | **Layer:** system

## Summary

Port the zero-match shell-counting guardrail proven in `repo-upgrade-advisor:L6`
into `repo-auditor`, then cover the fix with deterministic regression fixtures that
exercise the exact failure shapes.

## Approach

1. Replace the fragile self-audit agent count in `classify-repo-maturity.sh` with a
   zero-match-safe loop.
2. Rework DS-32 recent-window counting so it inspects the last `N` commits overall,
   not the last `N` commits touching `LEARNINGS.md`.
3. Add a regression test that proves both the pre-fix failure shape and the intended
   post-fix behavior.

## Verification

```bash
make check
make test
```
