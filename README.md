# repo-auditor

`repo-auditor` is a read-only repository health auditor. It produces
machine-readable scorecards, deterministic detection results, and a
human-readable report without modifying the target repository.

## Use

```bash
make audit TARGET=~/repos/some-target-repo
make audit-snapshot TARGET=~/repos/some-target-repo \
  OUTPUT_DIR=./audit-output SNAPSHOT_DIR=./audit-snapshot
make audit-quick TARGET=~/repos/some-target-repo
make audit-deep TARGET=~/repos/some-target-repo
```

Standard mode is deterministic. Deep mode is opt-in. A clean-head snapshot is
explicit and carries provenance; it does not silently replace live target
truth.

## Outputs

| File | Purpose |
|---|---|
| `SCORECARD.json` | Five-dimension bounded diagnostic scorecard |
| `AUDIT_REPORT.md` | Human-readable findings and recommendations |
| `PRE_SCAN.md` | Bounded target inventory and AI-surface analysis |
| `DS-34-plus-results.json` | Deterministic DS/AS signature bundle |
| `TARGET_NATIVE_QUALITY_GATES.json` | Additive target-local gate classification |
| `AUDIT_RUN_RECEIPT.json` | Run identity, state, and bounded failure evidence |

The full output contract is in
[`docs/invocation-contract.md`](docs/invocation-contract.md).

## Owner architecture

`CONSTITUTION.md` is the shared semantic floor and `AGENTS.md` is the compact
repo-auditor bootloader. The canonical delivery path is one owner issue, one
branch, one pull request, native checks, exact-head review, merge authority, and
live readback.

The single change-delivery route is
`.agents/skills/repo-auditor-owner-settlement/SKILL.md`.
`docs/live-capability-inventory.md` classifies every retained tracked path,
retired-name successor, rollback route, and compatible repo-agent-core
caller/export. `scripts/validate_owner_convergence.py` reads the cached Git
index and blobs so unstaged working-tree bytes cannot hide a staged failure.

## Development

```bash
make check
make test
make validate
make validate-owner-convergence
make review
```

`make check` is the pre-commit gate. GitHub requires `Pre-commit gate`,
`Schema validation`, and `Test suite`. Target repositories remain read-only
through every mode and test.
