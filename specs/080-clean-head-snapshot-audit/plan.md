# Implementation Plan: Clean HEAD Snapshot Audit

## Scope

Add an opt-in wrapper around the existing standard auditor that prepares a clean
HEAD snapshot of a dirty git target, invokes the unchanged auditor against the
snapshot, and writes provenance receipts that clearly separate snapshot evidence
from live-target evidence.

## Touch Surface

- `scripts/audit-clean-head-snapshot.py`
- `Makefile`
- `tests/test-clean-head-snapshot-audit.sh`
- `docs/invocation-contract.md`
- `README.md`
- `AGENTS.md`

## Non-Goals

- No changes to the default dirty-target guard.
- No silent fallback from standard audit to snapshot audit.
- No inclusion of untracked or modified source worktree files in the snapshot.
- No scan-cap behavior changes.
- No optimizer/advisor consumer changes in this repo.

## Validation

- Focused clean-HEAD snapshot test.
- `make test`.
- `make check`.
- retained local review.
