# Repo-Auditor Agent Operations

This document holds the operational inventory that used to live in `AGENTS.md`.
`AGENTS.md` remains the compact bootloader; this file is reference material.

## Agents

| Agent | Model | Purpose |
|---|---|---|
| repo-auditor | claude-opus-4.6 | Orchestrator for standard and deep audit modes |
| repo-auditor-inbound | claude-opus-4.6 | Inbound invocation |
| governance-auditor | claude-sonnet-4.5 | D1 Governance dimension |
| surface-auditor | claude-sonnet-4.5 | D2 Surface Health dimension |
| skill-auditor | claude-sonnet-4.5 | D3 Skill Maturity dimension |
| measurement-auditor | claude-sonnet-4.5 | D4 Measurement dimension |
| improvement-auditor | claude-sonnet-4.5 | D5 Self-Improvement dimension |
| theater-auditor | claude-sonnet-4.5 | Automation theater detection |
| audit-synthesis | claude-opus-4.6 | Deep-mode report synthesis |

## Skills

| Skill | Purpose |
|---|---|
| reviewing-code-locally | Pre-commit code review through Copilot CLI |
| pre-scanning | Deterministic inventory and AI-surface scan |
| detection-signatures | DS-34 through DS-48 plus AS-* signature runner |
| scoring | Five-dimension scoring, stall risk, and maturity classification |

## Core Pipeline Scripts

| Script | Purpose |
|---|---|
| `scripts/repo-auditor.sh` | Main orchestrator: pre-scan, score, report |
| `scripts/score-audit-dimensions.sh` | Five-dimension scorer |
| `scripts/replay-work-management-signatures.py` | Bounded read-only AS-20 through AS-38 replay across named targets, including core-five recovery-runtime AS-29 through AS-33 precision examples and downstream read-only pilot receipt fields |
| `scripts/detect-as-interrupted-goal-recovery-gap.sh` | AS-30 interrupted Goal recovery contract-field detector |
| `scripts/detect-as-fractured-serial-continuation.sh` | AS-31 recovery detector |
| `scripts/detect-as-unanchored-self-learning-claim.sh` | AS-32 unanchored self-learning/self-healing claim detector |
| `scripts/detect-as-foreground-failure-guidance-gap.sh` | AS-33 foreground failure guidance gap detector |
| `scripts/detect-as-closure-run-identity-gap.sh` | AS-34 closure-run identity gap detector |
| `scripts/detect-as-upstream-capability-intake-gap.sh` | AS-35 upstream capability intake evidence completeness detector |
| `scripts/detect-as-gbrain-instruction-distribution-overclaim.sh` | AS-36 GBrain instruction distribution overclaim detector |
| `scripts/detect-as-issue164-runtime-drift.sh` | AS-37 Issue #164 runtime launch discipline detector |
| `scripts/detect-as-self-authored-campaign-pause-authority.sh` | AS-38 self-authored campaign pause authority detector |
| `scripts/detect-as-external-closure-coupling.sh` | AS-56 external closure coupling detector |
| `scripts/detect-as-native-evidence-before-verdict.sh` | AS-57 native-evidence-before-verdict detector |
| `scripts/compare-scorecards.sh` | Pre/post scorecard deltas |
| `scripts/classify-repo-maturity.sh` | AI maturity phase classifier |
| `scripts/stall-risk-score.sh` | Six-signal stall risk predictor |
| `scripts/extract-repo-dna.sh` | Repo DNA fingerprint |
| `scripts/score-session.sh` | Operating-model scorecard for ordinary session-local work; for explicit GitHub issue/PR-backed work, GitHub issue/PR truth is closure authority, including check/merge truth, and `score-session.sh` is not authoritative |

## Detection Signatures

The deterministic signature family includes capability drift, automation
theater, warning noise, ceremony ratio, grader ceiling, content staleness,
feed-forward stall, measurement disconnect, stale TODOs, unused dependencies,
green-only CI, README drift, config proliferation, silent errors, commit
entropy, test theater, broken links, velocity bypass, closeout-control drift,
workflow-contract drift, LLM validation gaps, summary/source parity gaps, and
GitHub Actions concurrency gaps, and agent-surface AS-* checks for instruction root drift, docs-vs-observed host
drift, missing runtime heartbeat, validator live-path gaps, memory authority
confusion, prompt-only optimization, unused platform surfaces, critique health,
cost/token evidence boundaries, pricing provenance, copied evidence boundaries,
unauthorized default enablement, rollback proof, aggregate-only readiness,
stale direct-token evidence, forbidden public `CustomerNewsletter` mutation,
Goal-mode runtime evidence gaps, reactive self-healing loops, shell reserved
status-variable launch snippets, stale/default capability guidance, Hermes
foreground receipt adoption gaps, interruption recovery gaps, AS-31 unplanned-serial recovery gaps,
unanchored self-learning claims, foreground failure guidance gaps,
closure-run identity gaps, upstream capability intake gaps, and GBrain
instruction distribution overclaim gaps, Issue #164 runtime drift, and
self-authored campaign pause authority. The work-management replay harness emits
`AS_WORK_MANAGEMENT_REPLAY.json` for bounded AS-20 through AS-38 detector
precision checks, plus per-target
`DOWNSTREAM_READ_ONLY_RECOVERY_RUNTIME_PILOT_RECEIPT` fields that record target
identity, before/after git state, retained auditor replay artifact path, pending
advisor/optimizer artifact paths, and no-downstream-mutation non-claims.
AS-29 through AS-33
cover the core-five recovery-runtime examples and remain read-only, scan-limited,
and non-claim evidence only.

### AS-35 Upstream Capability Intake Record

This record is the bounded owner-surface intake for upstream capability advice
that reaches repo-auditor operations documentation.

- `component_identity` (Component identity): AS-35 upstream capability intake
  evidence completeness detector, exposed by
  `scripts/detect-as-upstream-capability-intake-gap.sh` and evaluated through
  `scripts/as_signature_scan.py`.
- `local_version` (Local version): repo-auditor clean-head replay evidence at
  git head `f534548b612bd73658767d45b909872f00418261` from the Issue #164
  owner-repair evidence bundle.
- `upstream_reference` (Upstream reference): repo-agent-core downstream
  read-only recovery runtime pilot contract referenced by
  `AS_WORK_MANAGEMENT_REPLAY.json` as
  `repo-agent-core/docs/downstream-read-only-recovery-runtime-pilot-contract.md`.
- `behindness_signal` (Behindness signal): AS-35 fired with
  `upstream_intake_gap_count=2`, `missing_field_record_count=2`, and
  `adoption_without_owner_or_nonclaims_count=1` against
  `docs/agent-operations.md` and `docs/live-capability-inventory.md`.
- `source_refs` (Source refs): owner issue
  `https://github.com/briancl2/repo-auditor/issues/118`; carrier issue
  `https://github.com/briancl2/build-meta-analysis/issues/760`; replay
  artifact
  `/tmp/issue164-repo-auditor-closure-family-owner-repair-20260613T224503Z/as-replay/repo_auditor_after_as22_goal_wording/AS_WORK_MANAGEMENT_REPLAY.json`;
  advisor artifact
  `/tmp/issue164-repo-auditor-closure-family-owner-repair-20260613T224503Z/advisor/repo_auditor_after_as22_goal_wording/OPPORTUNITIES.json`.
- `delta_clusters` (Delta clusters): documentation-only intake completion for
  AS-35; owner-surface/non-claim bounding for repo-auditor operations guidance;
  no script, schema, CI, Makefile, target-repo, BMA, or downstream mutation.
- `capability_decisions` (Capability decisions): retain the existing AS-35
  detector and backfill only the two owner documentation surfaces named by the
  replay evidence.
- `update_action` (Update action): bounded docs patch only; no package manager
  execution, generated registry, controller, scheduler, queue, daemon, retry
  loop, dashboard, background behavior, issue creation, PR creation, push, merge,
  or Campaign Sync.
- `validation` (Validation): focused local detector replay with
  `bash scripts/detect-as-upstream-capability-intake-gap.sh
  /Users/briancl/repos/repo-auditor` and detector unit coverage with
  `bash tests/test-upstream-capability-intake-gap.sh`.
- `adoption_plan_refs` (Adoption-plan refs): Issue #164 closure-family
  owner-repair carrier instructions for AS-35, owner issue #118, and carrier
  issue #760.
- `owner_routes` (Owner routes / owner surface): repo-auditor owns this
  documentation record through `docs/agent-operations.md` and
  `docs/live-capability-inventory.md`; Codex remains responsible for review,
  validation, commit, publication, merge/block, and next owner action.
- `non_claims` (Bounded non-claims): this intake record is scan-limited
  field-signal repair evidence only; it does not prove exhaustive repository
  health, closure, production readiness, cleanup/archive readiness, or safe
  downstream action.
- `out_of_bounds_surfaces` (Out-of-bounds surfaces): scripts, tests, schemas,
  CI, `AGENTS.md`, `LEARNINGS.md`, `Makefile`, BMA, downstream target repos,
  and any automation machinery remain outside this patch.

### Goal Runtime And Recovery Contract

Any Goal-mode runtime improvement claim about autonomy, continuity, operator
steering, runtime health, reduced burden, or self-healing must cite raw runtime
evidence before it is presented as a claim. Acceptable evidence includes retained
Goal metadata, a command transcript, a run-root `progress-ledger.jsonl`, a CI run
or check run, a replay log or replay receipt, a runtime ledger, session logs, a
Goal receipt, or another raw runtime receipt. When those artifacts cannot be
produced, the statement must be demoted to a bounded non-claim that describes only
the episode shape or intended doctrine, not observed runtime improvement.

Interrupted Goal recovery and batch reconstitution records must include these
fields before continuing after a blocker:

- `original_objective` (Original objective): the approved Goal episode objective.
- `blocker_class` (Blocker class): upstream, tool runtime, CI, permission,
  validation, owner-surface blocker, timeout, hang, or other exact blocker class.
- `goal_state` (Goal state): whether the Goal episode is stopped, partially
  complete, needs replacement, or can safely continue inside the approved
  boundary.
- `replacement_objective` (Replacement objective): the reconstituted objective
  chosen after the blocker.
- `first_owner_pr` (First owner PR or owner issue): the first owner-surface PR or
  issue that will carry the repair.
- Intentional serial/parallel plan: whether the replacement proceeds as one PR,
  parallel owner PRs, or an intentionally serial batch, with the reason.
- Learning trigger: the exact condition that would require a durable learning
  capture, or a no-capture reason.
- Fallback: the owner-surface fallback if the replacement objective is blocked.
- Validation: the focused detector, replay, check run, or local gate that proves
  the replacement did not regress the original boundary.

A blocker recovery must be a batch reconstitution, not a silent one-off drift.
When a blocker would otherwise cause unplanned serial continuation, the recovery
note must name the replacement objective, first owner PR or owner issue,
intentional serial/parallel plan, fallback, and validation. No retained report
package is required. This contract does not authorize controllers, schedulers,
queues, daemons, registries, dashboards, retry loops, background behavior,
downstream mutation, or automatic GitHub issue creation.

Repo-star genericity proofs should read the DS bundle's
`capability_metadata.repo_star_genericity` classification instead of treating
AS-22 or AS-34 detector names as target closure semantics. AS-22 and AS-34 are
generic repo-health detectors; they count against a strict genericity proof only
when their classified `target_finding_count` is nonzero or the signature fires.
Zero-count closure detector metadata is classified as allowed auditor metadata
only when `closure_signature_scope_complete` is `true`; missing or errored
closure detectors, or closure detectors missing their expected count signal,
make the genericity scope incomplete.

### AS-46 Deep Research Source-Intelligence Native Corpus Detector

AS-46 is the Issue #164 Arc 4 detector for the portable Deep Research/source-
intelligence native corpus contract. It scans owner evidence for
`DEEP_RESEARCH_SOURCE_INTELLIGENCE_NATIVE_CORPUS`, manual Deep Research sidecar,
and source-intelligence native corpus surfaces, then requires
`SOURCE_INSIGHT_PACKET` composition, source count/corpus scope, source IDs,
public/no-auth then exact-url authenticated access order, manual sidecar/API
disposition, equal-insight disposition, claim/effect routing, evidence tier,
owner/no-action routing, bounded non-claims, GitHub issue/PR/check/merge truth,
and next owner action.

The detector also flags live Deep Research API, Codex Cloud/remote, crawler,
watcher, source registry, control-plane, raw authenticated capture retention,
automatic GitHub mutation, retained closeout truth, and downstream-mutation
overclaims. It suppresses detector docs/tests and shared repo-agent-core
contract/template surfaces. It is detector evidence only: it does not authorize
live Deep Research API use, Codex Cloud/remote execution, crawler behavior,
background automation, automatic issue/PR creation, auto-merge, retained
closeout truth, or downstream mutation.

## Helper Scripts

| Script | Purpose |
|---|---|
| `scripts/assemble_ds_results.py` | Assemble DS-34+ results and repo-star genericity detector-scope metadata |
| `scripts/audit-clean-head-snapshot.py` | Clean-HEAD snapshot wrapper |
| `scripts/as_signature_scan.py` | Shared AS-* evaluator |
| `scripts/backtest_ds34_42.py` | Backtest deterministic signatures |
| `scripts/collect-dual-inventory.py` | Primary-surface and full-facts inventory receipt |
| `scripts/collect-target-native-quality-gates.py` | Target-local quality-gate receipt |
| `scripts/deep-audit.py` | Deep-audit known-defect validation |
| `scripts/ds_json_helper.py` | Safe JSON output helper |
| `scripts/prepare-clean-audit-snapshot.py` | Clean snapshot helper |
| `scripts/token-efficiency-measure.py` | Token-efficiency replay pilot |
| `scripts/write_context_score_manifest.py` | Context, git, and artifact preflight manifest |

## Gates And Hooks

| Script | Purpose |
|---|---|
| `scripts/check.sh` | Gate 2: shellcheck, inventory, co-evolution, trailers |
| `scripts/check-coevolution.sh` | Governed-surface co-evolution guard |
| `scripts/work-init.sh` | Gate 1 work-contract init |
| `scripts/work-close.sh` | Gate 3 ordinary local closeout path for non-GitHub-backed work; runs the session grader by default. For explicit GitHub issue/PR-backed work, use `--github-native-closeout`; it writes `score-session-bypass.json`, and GitHub issue/PR/check/merge truth remains closure authority while `score-session.sh` is not authoritative |
| `scripts/pre-commit-hook.sh` | Runs `make check` |
| `scripts/pre-push-hook.sh` | Additional validation |

## Modes And Budgets

| Mode | Token posture | Description |
|---|---|---|
| Standard | 0 | Deterministic pre-scan and scoring |
| Deep | about 30K | Pre-scan plus domain subagents and synthesis |

## Operator Notes

- `AGENTS.md` is the canonical startup surface.
- `LEARNINGS.md` is append-only operational memory.
- `.specify/memory/constitution.md` carries governance principles.
- Scan caps, timeouts, and target-read-only boundaries are safety controls, not
  suggestions.
