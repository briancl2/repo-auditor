# Tasks: Clean HEAD Snapshot Audit

1. Add the clean-HEAD snapshot wrapper with explicit caller-owned snapshot and output directories.
2. Retain snapshot provenance in `CLEAN_HEAD_SNAPSHOT_RECEIPT.json` and compact scorecard receipt pointers.
3. Add a Makefile target for explicit snapshot audit invocation.
4. Document invocation and non-claims in the README and invocation contract.
5. Add focused tests for default dirty-target failure, snapshot success, source non-mutation, and provenance receipt fields.
6. Run focused test, `make test`, `make check`, and retained review.
