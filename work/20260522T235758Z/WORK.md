# Work Contract

## Description

Burst 175 repo-auditor action tuple schema prompt fixture patch

## Operator Ask

Execute the Burst 174 decision as a narrow repo-auditor owner-surface patch:
add optional action tuple fields to findings, update deep-mode prompts, add
schema fixtures/tests, validate, close, commit, push, PR, and merge if clean.

## Boundary

- Keep `verification`; do not add `verify_command`.
- Do not change deterministic emitters in this burst.
- Do not mutate target repositories.
- Do not make public/fleet adoption, newsletter, live spend, billing, durable
  savings, model recommendation, controller, scheduler, or lane registry claims.

## Hypothesis

> **Gate 1 Required.** State a testable prediction with PASS/FAIL criteria.

**Prediction:** Optional `edit_surface`, `patch_shape`, and `owner_blocker`
fields can make findings more patch-ready while preserving legacy seven-column
findings and keeping `verification` as the command field.
**PASS:** Legacy fixture validates, action-tuple fixture validates, invalid
non-string action-tuple fixture fails, deep-mode prompts mention optional action
tuple columns, and repo-native checks pass.
**FAIL:** Legacy findings become invalid, optional tuple fields require emitter
changes, or validation needs unapproved target mutation.

## Work Type

code-change

## Status

- [x] Hypothesis stated
- [x] Work completed
- [x] Learnings extracted (or --no-novel-findings)
- [x] work-close run

## Validation Summary

- `python3 -m json.tool schemas/FINDINGS.schema.json`
- `bash tests/test-auditor-schemas.sh`
- `bash tests/test-check-coevolution.sh`
- `bash tests/test-deep-audit.sh`
- `make test`
- `make check`

All passed before closeout.

## Closeout Summary

`make work-close WORK=work/20260522T235758Z` passed. Pre-score was 54,
post-score was 60, delta was +6, and one learning was added.
