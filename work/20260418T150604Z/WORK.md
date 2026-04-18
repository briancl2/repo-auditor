# Work Contract

## Description

bounded D-004 repo-auditor starter package on exact checked-field boundary

## Hypothesis

> **Gate 1 Required.** State a testable prediction with PASS/FAIL criteria.

**Prediction:** If I encode the newly landed BMA `D-004` boundary as one
bounded `repo-auditor` starter detector, then the repo can support a
deterministic DS-47-style signature plus three tiny fixtures that distinguish
`hit`, `non_hit`, and `out_of_scope` without widening into `duration`,
error-event parity, or broader newsletter readiness.
**PASS:** One starter package lands that (a) adds one bounded detector script
for the exact `D-004` parity-gap boundary, (b) wires it into the DS runner and
docs, (c) adds fixture-backed tests for `hit`, `non_hit`, and `out_of_scope`,
and (d) passes `make test` plus `make check`.
**FAIL:** The package widens beyond the three-field boundary, cannot classify
the starter fixtures deterministically, or lands docs without executable
detector coverage.

## Work Type

code-change

## Status

- [x] Hypothesis stated
- [x] Work completed
- [x] Learnings extracted (or --no-novel-findings)
- [x] work-close run
