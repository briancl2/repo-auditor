# DS-29 file-weighted ceremony ratio

> **ID:** 075-ds29-file-weighted-ceremony-ratio
> **Date:** 2026-04-29
> **Source:** BMA selector `HANDOFF-SESSION-v530`
> **Target:** repo-auditor
> **Layer:** detection-signature

## Problem Statement

DS-29 currently classifies recent commits as ceremony, substantive, or mixed,
then fires from that commit-level ratio. The BMA post-v523 retained baseline
showed a different failure mode: mixed delivery commits can contain a small
code/test payload surrounded by a much larger retained ceremony/evidence
payload. The current commit-ratio detector can report healthy even when the
changed-file mix is dominated by process artifacts.

## Goal

Add a distinct file-weighted delivery-to-ceremony signal to DS-29 while
preserving the existing commit-ratio output for callers that already consume it.

## Acceptance Criteria

1. Existing commit-ratio JSON fields remain present.
2. DS-29 reports separate commit and file-weighted fire decisions.
3. A BMA-shaped mixed-commit fixture fires only because of the file-weighted
   signal.
4. An independent near-miss fixture stays below threshold.
5. A healthy mixed-commit fixture stays quiet.
6. `make check` and `make test` pass.
