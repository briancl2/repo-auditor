# DS-29 File-Weighted Assessment

## Source Evidence

This package implements the owner-side repair selected by BMA
`HANDOFF-SESSION-v530`: repo-auditor DS-29 calibration plus a file-weighted
delivery-to-ceremony detector upgrade. The BMA selector found that the old
commit-ratio signal returned healthy on a post-v523 BMA case even though the
changed-file mix was dominated by ceremony/evidence surfaces.

## Implementation

- Preserved the original commit-ratio counters and JSON fields:
  `ceremony`, `substantive`, `mixed`, `classified`, `ceremony_pct`,
  `threshold`, and `commits_analyzed`.
- Added `--mode commit|file|combined`; default is `combined`.
- Added distinct file-weighted fields: `file_ceremony`, `file_delivery`,
  `file_other`, `file_classified`, `file_ceremony_pct`, `file_threshold`, plus
  `commit_fires` and `file_fires`.
- Kept `--mode commit` available for callers that need the legacy decision path
  while exposing the file-weighted evidence in the same JSON output.

## Current-File Proof

Focused fixture proof:

- BMA-shaped mixed commits: `--mode commit` does not fire; default combined mode
  fires by `file-ratio`.
- Independent near-miss baseline: `file_ceremony_pct=60` at threshold `65`, no
  fire.
- Healthy mixed-commit baseline: `file_ceremony_pct=25`, no fire.

Live sanity proof:

- BMA current `main`, 20 commits, commit mode:
  `fires=false`, `commit_fires=false`, `ceremony_pct=5`, `file_fires=true`,
  `file_ceremony_pct=93`.
- BMA current `main`, 20 commits, combined mode:
  `fires=true`, `fire_reason=file-ratio`, `commit_fires=false`,
  `file_fires=true`, `file_ceremony_pct=93`.
- repo-auditor current `main`, 20 commits, combined mode:
  `fires=false`, `ceremony_pct=50`, `file_ceremony_pct=35`.

## Non-Claims

- This package does not remove truth gates or say all ceremony/evidence files
  are waste.
- This package does not implement a BMA package-class rule or revive a BMA
  `AGENTS.md` doctrine note.
- This package does not claim a fleet-wide threshold is final; `65` remains
  provisional and per-repo baselines may still be needed.

## CI Follow-Up

The first pushed run for this package failed in the existing CI `Test suite`
job before reaching any DS-29-specific failure because `tests/test-deep-audit.sh`
required a sibling BMA checkout that GitHub-hosted runners do not have. This
package now keeps the test active in CI by synthesizing the retained BMA known-
defect fixture when no implicit sibling checkout exists, while explicit bad or
empty paths still fail.
