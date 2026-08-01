# Owner capability inventory

This is the single owner-designated tracked inventory for repo-auditor. The
validator reads the exact cached Git index and blobs. An unstaged working-tree
edit therefore cannot hide a staged failure.

- Owner rollback base: `e8b42763eb3e323d0e0238e84fe81c4c87898627`
- Compatible repo-agent-core baseline:
  `9da7b41b83a10b9fd71ad24b0529a50425a8d373`
- Core inventory blob:
  `03bbce3d717eaa0e9d58426e4b4e1ccf127c858f`

## Retained tracked classification

Every cached index path must match exactly one row. Evidence uses
`path::literal-token`; every row has an owner caller or owner-policy witness.

| Pattern | Classification | Owner evidence |
|---|---|---|
| `CONSTITUTION.md` | shared semantic floor | `AGENTS.md::CONSTITUTION.md` |
| `AGENTS.md` | compact owner bootloader | `README.md::AGENTS.md` |
| `README.md` | user entrypoint | `AGENTS.md::README.md` |
| `Makefile` | native command surface | `AGENTS.md::make check` |
| `LEARNINGS.md` | historical stable learning | `AGENTS.md::LEARNINGS.md` |
| `.gitignore` | generated-noise exclusion | `docs/agent-operations.md::.gitignore` |
| `.github/workflows/*.yml` | required native CI | `README.md::Pre-commit gate` |
| `.agents/*.agent.md` | bounded deep-mode audit agents | `docs/agent-operations.md::.agents/*.agent.md` |
| `.agents/skills/detection-signatures/**` | detector semantics skill | `docs/agent-operations.md::.agents/skills/detection-signatures/` |
| `.agents/skills/pre-scanning/**` | deterministic pre-scan skill | `docs/agent-operations.md::.agents/skills/pre-scanning/` |
| `.agents/skills/reviewing-code-locally/**` | staged-diff review skill | `Makefile::.agents/skills/reviewing-code-locally/scripts/local_review.sh` |
| `.agents/skills/scoring/**` | bounded audit scoring skill | `docs/agent-operations.md::.agents/skills/scoring/` |
| `.agents/skills/repo-auditor-owner-settlement/**` | one owner delivery route | `AGENTS.md::.agents/skills/repo-auditor-owner-settlement/SKILL.md` |
| `config/**` | target-policy classification input | `scripts/collect-target-native-quality-gates.py::config/policy.yaml` |
| `detection-signatures/**` | detector documentation | `docs/agent-operations.md::detection-signatures/` |
| `docs/agent-operations.md` | runtime inventory | `AGENTS.md::docs/agent-operations.md` |
| `docs/core-five-owner-surface-contract.md` | subordinate reciprocal-read contract | `AGENTS.md::docs/core-five-owner-surface-contract.md` |
| `docs/detector-graduation-ledger.md` | detector lifecycle owner decision | `AGENTS.md::docs/detector-graduation-ledger.md` |
| `docs/invocation-contract.md` | audit invocation/output contract | `README.md::docs/invocation-contract.md` |
| `docs/live-capability-inventory.md` | owner manifest | `AGENTS.md::docs/live-capability-inventory.md` |
| `docs/repo-agent-fleet-consistency-floor-receipt.md` | historical conformance receipt | `tests/test-floor-receipt-conformance.sh::docs/repo-agent-fleet-consistency-floor-receipt.md` |
| `schemas/*.schema.json` | audit output schemas | `Makefile::schemas/*.schema.json` |
| `scripts/**` | audit product and deterministic helpers | `docs/agent-operations.md::scripts/repo-auditor.sh` |
| `tests/**` | deterministic tests and detector fixtures | `Makefile::tests/test-*.sh` |

## Retained core exports

The core export blob and auditor caller come from the exact core baseline
inventory. `exact-copy` requires identical current bytes. `owner-extension`
requires the repo-auditor blob to remain identical to the rollback base while
the core caller evidence remains valid. `citation-only` has no local copy.

| Core export | Core blob | Auditor caller | Mode |
|---|---|---|---|
| `.agents/skills/reviewing-code-locally/scripts/local_review.sh` | `7deaec6f5a9f206cd776a2f0aa75d4694e90f567` | `Makefile::.agents/skills/reviewing-code-locally/scripts/local_review.sh` | `owner-extension:2b6a429f587381858df5d462757d418cf3748b8d` |
| `schemas/FINDINGS.schema.json` | `085a65b00aac17da563c694e2139d392732835c3` | `tests/test-auditor-schemas.sh::schemas/FINDINGS.schema.json` | `owner-extension:95e43b830f4f72cc484e9ea3ba5cd3772da7d90d` |
| `schemas/SCORECARD.schema.json` | `32cbc2fe6c6f15059829a3a58babbda86c8ebb58` | `docs/invocation-contract.md::schemas/SCORECARD.schema.json` | `owner-extension:3d89b1ed54de405482cbafa163f1562e0a50570f` |
| `scripts/validate-floor-receipt.sh` | `5dbea3ca029b1fca77844bbb01c24fe016c65f8f` | `tests/test-floor-receipt-conformance.sh::scripts/validate-floor-receipt.sh` | `exact-copy` |
| `scripts/compare-scorecards.sh` | `d57b48bcdb47f74ded922ef07ac78312fd6e56aa` | `tests/test-compare-scorecards.sh::scripts/compare-scorecards.sh` | `exact-copy` |
| `scripts/install-hooks.sh` | `aed06f2870e5b89e02484129d5be70a253617df0` | `Makefile::repo-agent-core/scripts/install-hooks.sh` | `citation-only` |

## Allowed candidate changes

Every retained rollback-base blob must remain identical unless named here.
Every new path must also be named here.

| Path | Change class |
|---|---|
| `.github/workflows/ci.yml` | exact owner/core base pins |
| `AGENTS.md` | compact ordinary-task contract |
| `Makefile` | owner/core convergence defaults |
| `detection-signatures/DS-43-plus.md` | retired and narrowed AS documentation |
| `docs/agent-operations.md` | current runtime and fixture scope |
| `docs/live-capability-inventory.md` | owner manifest |
| `scripts/as_signature_scan.py` | retired registry/evaluators and narrowed AS-43 |
| `scripts/check.sh` | current script count and convergence defaults |
| `scripts/detect-new-signatures.sh` | retired runner entries |
| `scripts/replay-work-management-signatures.py` | retained work-management runner entries |
| `scripts/validate_owner_convergence.py` | current owner/core identities |
| `tests/test-as-signatures.sh` | active family registry and smoke fixtures |
| `tests/test-capability-placement-gap.sh` | narrowed AS-43 behavior fixtures |
| `tests/test-compact-ordinary-task-signatures.sh` | compact ordinary-task and retained-risk fixtures |
| `tests/test-owner-convergence.sh` | current convergence receipts |
| `tests/test-work-management-replay.sh` | retained work-management replay fixtures |


## Removed-name successor and rollback map

Every rollback-base deletion must match exactly one row. Rollback commands are
recoverable Git operations; they are not an active rollback control plane.

| Removed pattern | Successor | Rollback |
|---|---|---|
| `scripts/detect-as-issue164-runtime-drift.sh` | `scripts/detect-as-goal-runtime-evidence-gap.sh` | `git restore --source e8b42763eb3e323d0e0238e84fe81c4c87898627 -- scripts/detect-as-issue164-runtime-drift.sh` |
| `scripts/detect-as-codex-native-runtime-readiness-evidence-gap.sh` | `scripts/detect-as-goal-runtime-evidence-gap.sh` | `git restore --source e8b42763eb3e323d0e0238e84fe81c4c87898627 -- scripts/detect-as-codex-native-runtime-readiness-evidence-gap.sh` |
| `tests/test-issue164-runtime-drift.sh` | `tests/test-compact-ordinary-task-signatures.sh` | `git restore --source e8b42763eb3e323d0e0238e84fe81c4c87898627 -- tests/test-issue164-runtime-drift.sh` |
| `tests/test-codex-native-runtime-readiness-evidence-gap.sh` | `tests/test-compact-ordinary-task-signatures.sh` | `git restore --source e8b42763eb3e323d0e0238e84fe81c4c87898627 -- tests/test-codex-native-runtime-readiness-evidence-gap.sh` |

## Boundaries

- Audit product, detector, fixture, schema, privacy, recovery, and fail-closed
  semantics are unchanged unless an allowed candidate path explicitly says
  otherwise.
- A self-learning claim requires `github_surface_or_owner_action`,
  `raw_evidence`, `gbrain_slug_or_no_capture_reason`, and
  `bounded_non_claims`: specifically a GitHub issue or owner action, raw runtime evidence,
  a GBrain slug or `no_capture_reason`, and bounded non-claims. These
  are evidence anchors only; they create no learning, mutation, or publication
  authority.
- Installed skill, custom-agent, instruction, and prompt discovery is reported
  separately by count only. Private names and contents are never emitted.
- The floor receipt, exact-copy validator, and conformance test remain because
  core `9da7b41b83a10b9fd71ad24b0529a50425a8d373` still declares Auditor's
  `scripts/validate-floor-receipt.sh` caller. This compatibility residual is
  not a second cleanup issue.
- Issue #204 remains deferred. This inventory neither implements nor resolves
  it.
- This package creates no controller, registry, dashboard, roadmap, execution
  ledger, updater, scheduler, queue, daemon, background process, target
  mutation, or auto-merge route.
