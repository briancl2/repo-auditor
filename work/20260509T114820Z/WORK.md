# Work Contract

## Description

cap curve receipt measurement fields

## Hypothesis

**Prediction:** Repo-auditor can expose cap-curve measurement fields without
changing default scoring or weakening dirty-target guardrails by adding
run-level elapsed time and an opt-in dual-inventory denominator mode.
**PASS:** Focused tests prove default limited receipts remain non-authorizing,
opt-in denominator mode reports auditor-pruned total files and coverage ratio,
`AUDIT_RUN_RECEIPT.json` reports elapsed time, and `make test` plus `make check`
pass.
**FAIL:** Default scoring changes, dirty-target guard behavior changes, limited
inventory becomes cleanup authorization, or denominator measurement requires
target mutation.

## Work Type

code-change

## Status

- [x] Hypothesis stated
- [ ] Work completed
- [ ] Learnings extracted (or --no-novel-findings)
- [ ] work-close run
