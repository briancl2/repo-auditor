# Work Contract

## Description

Calibrate DS-29 delivery-to-ceremony detection with file-weighted signal

## Hypothesis

> **Gate 1 Required.** State a testable prediction with PASS/FAIL criteria.

**Prediction:** DS-29 can keep its existing commit-ratio output while adding a
distinct file-weighted delivery-to-ceremony signal that catches mixed commits
where most changed files are process/evidence artifacts.
**PASS:** `detect-ceremony-ratio.sh` exposes separate commit and file ratios,
fires on a BMA-shaped file-heavy mixed-commit fixture, stays quiet on a healthy
mixed-commit fixture, and passes focused DS-29 tests plus repo gates.
**FAIL:** The detector only re-thresholds the old commit ratio, loses existing
JSON fields, lacks a negative fixture, or cannot pass `make check` and `make
test`.

## Work Type

code-change

## Status

- [x] Hypothesis stated
- [x] Work completed
- [x] Learnings extracted (or --no-novel-findings)
- [x] work-close run
