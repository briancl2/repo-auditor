# Implementation Plan: Dual Inventory Receipts

## Scope

Add an additive deterministic inventory collector and wire it into the standard
audit run after `SCORECARD.json` and `SCORECARD_RECEIPTS.json` are valid.

## Touch Surface

- `scripts/collect-dual-inventory.py`
- `scripts/repo-auditor.sh`
- `schemas/SCORECARD.schema.json`
- `docs/invocation-contract.md`
- focused shell test under `tests/`

## Non-Goals

- No scoring changes.
- No target mutation.
- No optimizer changes in this repo.
- No full target-private path dump in governed receipts.

## Validation

- Focused dual-inventory test.
- `make test`.
- `make check`.
- retained local review.
