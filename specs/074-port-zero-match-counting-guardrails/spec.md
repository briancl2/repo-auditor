# Port zero-match counting guardrails from harvested fleet learning

> **ID:** 074-port-zero-match-counting-guardrails
> **Date:** 2026-03-14
> **Source:** BMA Stage 14 `14.1.3` self-improvement cycle, using deferred harvested learning `repo-upgrade-advisor:L6`
> **Target:** repo-auditor
> **Layer:** system

## Problem Statement

`repo-auditor` still has live zero-match counting and recent-window edge cases in
deterministic shell paths:

1. `scripts/classify-repo-maturity.sh` aborts under `set -euo pipefail` when a repo
   has agent files but none of them match the `"audit|optimize|critic|diagnostic"`
   pattern used for self-audit detection.
2. `scripts/detect-feed-forward-stall.sh` counts L-number additions from the last
   `N` commits touching `LEARNINGS.md`, not from the last `N` commits overall, so
   old learning additions can keep the detector firing long after they are outside
   the intended review window.

This is the exact operational class surfaced in `repo-upgrade-advisor:L6`: shell
counting paths need explicit zero-match handling and deterministic regression tests
before their results can be trusted in scoring and governance flows.

## Goal

1. Make self-audit agent detection safe when zero files match the audit keywords.
2. Make DS-32 evaluate the recent overall commit window rather than stale historical
   `LEARNINGS.md` edits.
3. Add deterministic regression coverage for both behaviors.

## Acceptance Criteria

1. `classify-repo-maturity.sh` returns a valid classification for a fixture repo
   containing non-audit agent files instead of exiting early.
2. `detect-feed-forward-stall.sh` reports `new_lnumbers=0` when the recent overall
   commit window does not include LEARNINGS additions, even if older commits do.
3. `detect-feed-forward-stall.sh` still fires when the recent window includes new
   learnings with no structural follow-through.
4. `make check` and `make test` pass in `repo-auditor`.
