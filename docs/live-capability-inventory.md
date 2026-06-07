# Live Capability Inventory

> Owner: repo-auditor
> Scope: human-readable live capability tracking surface for calibrated capability-drift checks

This document tracks the repo-auditor live capability surfaces that are intentionally present on disk. It closes the tracking-surface gap raised by Issue #80 without adding a schema, generated registry, runtime API, scheduler, controller, queue, watcher, daemon, retry loop, or background sync.

The calibrated detector separates live surfaces from retained, archive, test-fixture, and generated paths. This inventory records owner intent for the live paths; it does not authorize deleting, archiving, enabling, or mutating target repositories.

## Triage Summary

| Field | Value |
|---|---|
| Calibrated detector live paths | 115 |
| Additional active helpers tracked by owner review | 3 |
| Calibrated tracking-surface gaps closed by this PR | 98 |
| Delete/archive candidates selected here | 0 |
| Generated registry or runtime dependency added | no |
| Target-repo mutation authorized | no |

## Live Paths

| Path | Classification | Tracking status | Owner decision |
|---|---|---|---|
| `.agents/audit-synthesis.agent.md` | owner-owned agent surface | tracking-surface gap closed by this PR | Keep tracked as an owner-owned agent or skill surface. |
| `.agents/governance-auditor.agent.md` | owner-owned agent surface | tracking-surface gap closed by this PR | Keep tracked as an owner-owned agent or skill surface. |
| `.agents/improvement-auditor.agent.md` | owner-owned agent surface | tracking-surface gap closed by this PR | Keep tracked as an owner-owned agent or skill surface. |
| `.agents/measurement-auditor.agent.md` | owner-owned agent surface | tracking-surface gap closed by this PR | Keep tracked as an owner-owned agent or skill surface. |
| `.agents/repo-auditor-inbound.agent.md` | owner-owned agent surface | tracking-surface gap closed by this PR | Keep tracked as an owner-owned agent or skill surface. |
| `.agents/repo-auditor.agent.md` | owner-owned agent surface | already tracked before Issue #164 replay | Keep tracked as an owner-owned agent or skill surface. |
| `.agents/skill-auditor.agent.md` | owner-owned agent surface | tracking-surface gap closed by this PR | Keep tracked as an owner-owned agent or skill surface. |
| `.agents/skills/detection-signatures/SKILL.md` | owner-owned agent surface | already tracked before Issue #164 replay | Keep tracked as an owner-owned agent or skill surface. |
| `.agents/skills/pre-scanning/SKILL.md` | owner-owned agent surface | already tracked before Issue #164 replay | Keep tracked as an owner-owned agent or skill surface. |
| `.agents/skills/pre-scanning/scripts/pre-scan-target.sh` | owner-owned agent surface | already tracked before Issue #164 replay | Keep tracked as an owner-owned agent or skill surface. |
| `.agents/skills/reviewing-code-locally/SKILL.md` | owner-owned agent surface | already tracked before Issue #164 replay | Keep tracked as an owner-owned agent or skill surface. |
| `.agents/skills/reviewing-code-locally/references/review-prompt.md` | owner-owned skill reference prompt | owner review addition | Keep tracked as an active reviewing-code-locally prompt surface. |
| `.agents/skills/reviewing-code-locally/scripts/local_review.sh` | owner-owned agent surface | already tracked before Issue #164 replay | Keep tracked as an owner-owned agent or skill surface. |
| `.agents/skills/scoring/SKILL.md` | owner-owned agent surface | already tracked before Issue #164 replay | Keep tracked as an owner-owned agent or skill surface. |
| `.agents/speckit.analyze.agent.md` | dormant Speckit helper | tracking-surface gap closed by this PR | Keep tracked pending a later Speckit owner decision. |
| `.agents/speckit.checklist.agent.md` | dormant Speckit helper | tracking-surface gap closed by this PR | Keep tracked pending a later Speckit owner decision. |
| `.agents/speckit.clarify.agent.md` | dormant Speckit helper | tracking-surface gap closed by this PR | Keep tracked pending a later Speckit owner decision. |
| `.agents/speckit.constitution.agent.md` | dormant Speckit helper | tracking-surface gap closed by this PR | Keep tracked pending a later Speckit owner decision. |
| `.agents/speckit.implement.agent.md` | dormant Speckit helper | tracking-surface gap closed by this PR | Keep tracked pending a later Speckit owner decision. |
| `.agents/speckit.plan.agent.md` | dormant Speckit helper | tracking-surface gap closed by this PR | Keep tracked pending a later Speckit owner decision. |
| `.agents/speckit.specify.agent.md` | dormant Speckit helper | tracking-surface gap closed by this PR | Keep tracked pending a later Speckit owner decision. |
| `.agents/speckit.tasks.agent.md` | dormant Speckit helper | tracking-surface gap closed by this PR | Keep tracked pending a later Speckit owner decision. |
| `.agents/speckit.taskstoissues.agent.md` | dormant Speckit helper | tracking-surface gap closed by this PR | Keep tracked pending a later Speckit owner decision. |
| `.agents/surface-auditor.agent.md` | owner-owned agent surface | tracking-surface gap closed by this PR | Keep tracked as an owner-owned agent or skill surface. |
| `.agents/theater-auditor.agent.md` | owner-owned agent surface | tracking-surface gap closed by this PR | Keep tracked as an owner-owned agent or skill surface. |
| `.specify/scripts/bash/check-prerequisites.sh` | dormant Speckit helper | tracking-surface gap closed by this PR | Keep tracked pending a later Speckit owner decision. |
| `.specify/scripts/bash/common.sh` | dormant Speckit helper | tracking-surface gap closed by this PR | Keep tracked pending a later Speckit owner decision. |
| `.specify/scripts/bash/create-new-feature.sh` | dormant Speckit helper | tracking-surface gap closed by this PR | Keep tracked pending a later Speckit owner decision. |
| `.specify/scripts/bash/setup-plan.sh` | dormant Speckit helper | tracking-surface gap closed by this PR | Keep tracked pending a later Speckit owner decision. |
| `.specify/scripts/bash/update-agent-context.sh` | dormant Speckit helper | tracking-surface gap closed by this PR | Keep tracked pending a later Speckit owner decision. |
| `scripts/as_signature_scan.py` | runtime-loaded script | tracking-surface gap closed by this PR | Keep tracked as an owner-owned script surface. |
| `scripts/assemble_ds_results.py` | runtime-loaded script | tracking-surface gap closed by this PR | Keep tracked as an owner-owned script surface. |
| `scripts/audit-clean-head-snapshot.py` | runtime-loaded clean-head snapshot helper | owner review addition | Keep tracked as an active clean-head snapshot helper. |
| `scripts/backtest_ds34_42.py` | runtime-loaded script | tracking-surface gap closed by this PR | Keep tracked as an owner-owned script surface. |
| `scripts/check-coevolution.sh` | runtime-loaded script | tracking-surface gap closed by this PR | Keep tracked as an owner-owned script surface. |
| `scripts/check.sh` | runtime-loaded script | already tracked before Issue #164 replay | Keep tracked as an owner-owned script surface. |
| `scripts/classify-repo-maturity.sh` | runtime-loaded script | tracking-surface gap closed by this PR | Keep tracked as an owner-owned script surface. |
| `scripts/closure_identity.py` | runtime-loaded script | already tracked before Issue #164 replay | Keep tracked as an owner-owned script surface. |
| `scripts/collect-dual-inventory.py` | runtime-loaded script | already tracked before Issue #164 replay | Keep tracked as an owner-owned script surface. |
| `scripts/collect-target-native-quality-gates.py` | runtime-loaded script | tracking-surface gap closed by this PR | Keep tracked as an owner-owned script surface. |
| `scripts/compare-scorecards.sh` | runtime-loaded script | tracking-surface gap closed by this PR | Keep tracked as an owner-owned script surface. |
| `scripts/deep-audit.py` | runtime-loaded script | tracking-surface gap closed by this PR | Keep tracked as an owner-owned script surface. |
| `scripts/detect-as-aggregate-only-readiness.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-as-closure-run-identity-gap.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-as-copied-evidence-boundary-gap.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-as-cost-model-mismatch.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-as-cost-without-token-fields.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-as-docs-vs-observed-host-drift.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-as-forbidden-public-customernewsletter-mutation.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-as-foreground-failure-guidance-gap.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-as-fractured-serial-continuation.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-as-gbrain-instruction-distribution-overclaim.sh` | runtime-loaded deterministic detector | Issue #164 owner-route addition for GBrain repo-local instruction distribution overclaims | Keep tracked as an existing deterministic detector. |
| `scripts/detect-as-github-native-closure-regrowth.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-as-goal-runtime-evidence-gap.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-as-hermes-foreground-receipt-adoption-gap.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-as-instruction-root-drift.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-as-interrupted-goal-recovery-gap.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-as-memory-authority-confusion.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-as-missing-rollback-control-proof.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-as-missing-runtime-heartbeat.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-as-owner-surface-ambiguity.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-as-pricing-provenance-gap.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-as-prompt-only-optimization-surface.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-as-reactive-self-healing-loop.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-as-reciprocal-proving-ground-gap.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-as-request-tool-amplification-gap.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-as-selection-handback-recommendation.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-as-shell-reserved-status-variable.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-as-source-intelligence-intake-gap.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-as-stale-default-capability-guidance.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-as-stale-direct-token-evidence.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-as-too-small-goal-mode-episode.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-as-unanchored-self-learning-claim.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-as-upstream-capability-intake-gap.sh` | runtime-loaded deterministic detector | Issue #164 owner-route addition for repo-agent-core upstream capability intake contract | Keep tracked as an existing deterministic detector. |
| `scripts/detect-as-unauthorized-production-default-enablement.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-as-unused-platform-surface.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-as-validator-live-path-gap.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-automation-theater.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-broken-links.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-capability-drift.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-ceremony-ratio.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-closeout-control-drift.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-commit-entropy.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-config-proliferation.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-content-staleness.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-external-critique-health.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-feed-forward-stall.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-github-actions-concurrency-gap.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-grader-ceiling.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-green-only-ci.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-llm-validation-gap.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-measurement-disconnect.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-new-signatures.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-readme-drift.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-silent-errors.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-stale-todos.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-summary-source-parity-gap.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-test-theater.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-unused-deps.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-velocity-bypass.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-warning-noise.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/detect-workflow-contract-drift.sh` | runtime-loaded deterministic detector | tracking-surface gap closed by this PR | Keep tracked as an existing deterministic detector. |
| `scripts/ds_json_helper.py` | runtime-loaded script | tracking-surface gap closed by this PR | Keep tracked as an owner-owned script surface. |
| `scripts/extract-repo-dna.sh` | runtime-loaded script | tracking-surface gap closed by this PR | Keep tracked as an owner-owned script surface. |
| `scripts/measure-dual-inventory-cap-curve.py` | runtime-loaded script | already tracked before Issue #164 replay | Keep tracked as an owner-owned script surface. |
| `scripts/operation-guard.sh` | runtime-loaded script | tracking-surface gap closed by this PR | Keep tracked as an owner-owned script surface. |
| `scripts/prepare-clean-audit-snapshot.py` | runtime-loaded clean-head snapshot helper | owner review addition | Keep tracked as an active clean-head snapshot helper. |
| `scripts/pre-commit-hook.sh` | runtime-loaded script | tracking-surface gap closed by this PR | Keep tracked as an owner-owned script surface. |
| `scripts/pre-push-hook.sh` | runtime-loaded script | tracking-surface gap closed by this PR | Keep tracked as an owner-owned script surface. |
| `scripts/replay-work-management-signatures.py` | runtime-loaded script | tracking-surface gap closed by this PR | Keep tracked as an owner-owned script surface. |
| `scripts/repo-auditor.sh` | runtime-loaded script | already tracked before Issue #164 replay | Keep tracked as an owner-owned script surface. |
| `scripts/score-audit-dimensions.sh` | runtime-loaded script | tracking-surface gap closed by this PR | Keep tracked as an owner-owned script surface. |
| `scripts/score-operation.sh` | runtime-loaded script | tracking-surface gap closed by this PR | Keep tracked as an owner-owned script surface. |
| `scripts/score-session.sh` | runtime-loaded script | already tracked before Issue #164 replay | Keep tracked as an owner-owned script surface. |
| `scripts/stall-risk-score.sh` | runtime-loaded script | tracking-surface gap closed by this PR | Keep tracked as an owner-owned script surface. |
| `scripts/token-efficiency-measure.py` | runtime-loaded script | already tracked before Issue #164 replay | Keep tracked as an owner-owned script surface. |
| `scripts/work-close.sh` | runtime-loaded script | already tracked before Issue #164 replay | Keep tracked as an owner-owned script surface. |
| `scripts/work-init.sh` | runtime-loaded script | already tracked before Issue #164 replay | Keep tracked as an owner-owned script surface. |
| `scripts/write_context_score_manifest.py` | runtime-loaded script | tracking-surface gap closed by this PR | Keep tracked as an owner-owned script surface. |

## Non-Claims

- This inventory is documentation for existing calibrated repo-auditor drift semantics, not a separate inventory registry.
- This inventory does not add a schema, runtime API, generated catalog, scheduler, controller, queue, watcher, daemon, retry loop, or background sync.
- This inventory does not authorize target repo mutation, component upgrades, deletion, archive moves, or default enablement of dormant helpers.
