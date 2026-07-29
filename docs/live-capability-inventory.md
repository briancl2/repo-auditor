# Owner capability inventory

This is the single owner-designated tracked inventory for repo-auditor. The
validator reads the exact cached Git index and blobs. An unstaged working-tree
edit therefore cannot hide a staged failure.

- Owner rollback base: `174fc769c029060270eca7d405decb08c9b7919b`
- Compatible repo-agent-core baseline:
  `a93abeece9d237a2a642f96926b4590dc1a373c9`
- Core inventory blob:
  `957887e8b80fac0f9bb015528eb71ffae7a2aaa0`

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
| `AGENTS.md` | compact bootloader |
| `README.md` | compact user entrypoint |
| `Makefile` | native owner-convergence command and retired local lifecycle targets |
| `.github/workflows/ci.yml` | exact core-baseline checkout for required convergence check |
| `docs/agent-operations.md` | retained runtime description |
| `docs/detector-graduation-ledger.md` | remove one deleted retrospective pointer |
| `docs/live-capability-inventory.md` | owner manifest |
| `docs/repo-agent-fleet-consistency-floor-receipt.md` | demote prior conformance snapshot to historical evidence |
| `scripts/check.sh` | required cached-index convergence gate |
| `scripts/validate-commit-provenance.sh` | narrow commit-provenance guard |
| `.agents/skills/repo-auditor-owner-settlement/SKILL.md` | new compact owner route |
| `scripts/validate_owner_convergence.py` | new cached-index guard |
| `tests/test-commit-provenance.sh` | new focused provenance guard tests |
| `tests/test-owner-convergence.sh` | new focused guard tests |

## Removed-name successor and rollback map

Every rollback-base deletion must match exactly one row. Rollback commands are
recoverable Git operations; they are not an active rollback control plane.

| Removed pattern | Successor | Rollback |
|---|---|---|
| `.agents/speckit.*.agent.md` | `.agents/skills/repo-auditor-owner-settlement/SKILL.md` | `git restore --source 174fc769c029060270eca7d405decb08c9b7919b -- .agents/speckit.*.agent.md` |
| `.github/prompts/speckit.*.prompt.md` | `.agents/skills/repo-auditor-owner-settlement/SKILL.md` | `git restore --source 174fc769c029060270eca7d405decb08c9b7919b -- .github/prompts/speckit.*.prompt.md` |
| `.specify/**` | `AGENTS.md` | `git restore --source 174fc769c029060270eca7d405decb08c9b7919b -- .specify` |
| `.vscode/settings.json` | `README.md` | `git restore --source 174fc769c029060270eca7d405decb08c9b7919b -- .vscode/settings.json` |
| `specs/**` | `.agents/skills/repo-auditor-owner-settlement/SKILL.md` | `git restore --source 174fc769c029060270eca7d405decb08c9b7919b -- specs` |
| `work/**` | `.agents/skills/repo-auditor-owner-settlement/SKILL.md` | `git restore --source 174fc769c029060270eca7d405decb08c9b7919b -- work` |
| `docs/current-program-status.md` | `docs/live-capability-inventory.md` | `git restore --source 174fc769c029060270eca7d405decb08c9b7919b -- docs/current-program-status.md` |
| `docs/repo-health-retrospective-2026-07-09.md` | `docs/detector-graduation-ledger.md` | `git restore --source 174fc769c029060270eca7d405decb08c9b7919b -- docs/repo-health-retrospective-2026-07-09.md` |
| `scripts/work-init.sh` | `.agents/skills/repo-auditor-owner-settlement/SKILL.md` | `git restore --source 174fc769c029060270eca7d405decb08c9b7919b -- scripts/work-init.sh` |
| `scripts/work-close.sh` | `.agents/skills/repo-auditor-owner-settlement/SKILL.md` | `git restore --source 174fc769c029060270eca7d405decb08c9b7919b -- scripts/work-close.sh` |
| `scripts/score-session.sh` | `.agents/skills/scoring/SKILL.md` | `git restore --source 174fc769c029060270eca7d405decb08c9b7919b -- scripts/score-session.sh` |
| `schemas/OPERATING_MODEL_SCORECARD.schema.json` | `schemas/SCORECARD.schema.json` | `git restore --source 174fc769c029060270eca7d405decb08c9b7919b -- schemas/OPERATING_MODEL_SCORECARD.schema.json` |
| `tests/fixtures/golden-work-dir/**` | `tests/test-owner-convergence.sh` | `git restore --source 174fc769c029060270eca7d405decb08c9b7919b -- tests/fixtures/golden-work-dir` |
| `tests/test-grader-golden.sh` | `tests/test-owner-convergence.sh` | `git restore --source 174fc769c029060270eca7d405decb08c9b7919b -- tests/test-grader-golden.sh` |
| `tests/test-work-close-github-native.sh` | `tests/test-owner-convergence.sh` | `git restore --source 174fc769c029060270eca7d405decb08c9b7919b -- tests/test-work-close-github-native.sh` |

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
- Issue #204 remains deferred. This inventory neither implements nor resolves
  it.
- This package creates no controller, registry, dashboard, roadmap, execution
  ledger, updater, scheduler, queue, daemon, background process, target
  mutation, or auto-merge route.
