# Implementation Plan: Target-Native Quality Gate Receipts

**Branch**: `078-target-native-quality-gates` | **Date**: 2026-05-08 | **Spec**: `specs/078-target-native-quality-gates/spec.md`
**Input**: Feature specification from `/specs/078-target-native-quality-gates/spec.md`

## Summary

Add a deterministic, additive adapter that inspects retained target-local
quality-gate artifacts and writes parallel target-native receipts without
changing the generic repo-auditor score. The adapter is admitted by a
research-mode partial proof and therefore must label partial diagnostics as
non-verdict evidence.

## Technical Context

**Language/Version**: Bash 3.2-compatible orchestration plus Python 3 helper  
**Primary Dependencies**: Python standard library, existing shell scripts  
**Storage**: Audit output directory artifacts  
**Testing**: Existing shell test suite plus targeted fixture test  
**Target Platform**: macOS/Linux shell environments  
**Performance Goals**: Deterministic retained-artifact scan; no target command execution  
**Constraints**: Preserve generic score fields; no Vault mutation; no target-local command execution; provisional enums only  
**Scale/Scope**: One helper, one orchestrator hook, docs/schema/tests

## Constitution Check

- Deterministic-first: PASS. The adapter uses only file reads and pattern
  parsing.
- 5-dimension scoring model: PASS. No dimension or composite scoring changes.
- Tier architecture: PASS. Target-native evidence is a receipt, not a new score.
- Evidence-based only: PASS. Every emitted status includes source paths.
- Bounded execution: PASS. Candidate paths are finite and no recursive broad
  target scan is introduced.

## Project Structure

### Documentation (this feature)

```text
specs/078-target-native-quality-gates/
├── spec.md
├── plan.md
└── tasks.md
```

### Source Code (repository root)

```text
scripts/
├── collect-target-native-quality-gates.py
└── repo-auditor.sh

tests/
└── test-target-native-quality-gates.sh

docs/
└── invocation-contract.md

schemas/
└── SCORECARD.schema.json
```

**Structure Decision**: Keep the adapter as an additive Python helper invoked by
the existing bash orchestrator after the generic scorecard/report surfaces are
available.

## Complexity Tracking

No constitution violations.

## Implementation Notes

1. Parse a finite set of retained quality-gate artifact names.
2. Write `TARGET_NATIVE_QUALITY_GATES.json` only when local gate evidence is
   found or a gate-like artifact requires amendment.
3. Update `SCORECARD_RECEIPTS.json.target_native_quality_gates` with detailed
   receipt data and `SCORECARD.json.receipts.target_native_quality_gates` with a
   small pointer.
4. Append a short report section when target-native evidence exists.
5. Keep all contradiction labels provisional and bounded.
