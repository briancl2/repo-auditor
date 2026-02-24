# Work Contract

## Description

golden fixture + Phase B smoke test

## Hypothesis

> **Gate 1 Required.** State a testable prediction with PASS/FAIL criteria.

**Prediction:** Golden fixture validates session grader correctness. Agent smoke test on T10 produces valid SCORECARD within 180s.
**PASS:** (1) Golden fixture passes with expected score. (2) Agent audit on T10 produces SCORECARD delta <=5pt vs bash baseline.
**FAIL:** Golden fixture score doesn't match expected. Or agent audit fails/times out.

## Work Type

code-change

## Status

- [x] Hypothesis stated
- [ ] Work completed
- [ ] Learnings extracted (or --no-novel-findings)
- [ ] work-close run

