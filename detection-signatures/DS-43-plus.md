# Detection Signatures DS-43+

> Extension document for signatures added after the initial DS-34-42 batch.
> Schema follows DS-34-through-DS-42.md format.

### DS-43: Autonomous Velocity Bypass
- **Detects:** Code-change work contracts with missing review/critique/hypothesis evidence
- **Signal:** Agent skippped quality gates when given velocity-scoped instructions ("continue autonomously", "do everything")
- **Phase range:** Phase 3+ (requires work contracts with WORK.md)
- **Patterns:** work/ dirs containing WORK.md + code-change work type + (missing review-receipt.json OR missing critique-*.txt OR unfilled hypothesis template)
- **Check:** Scan work/ directories. For each code-change contract: check for review-receipt.json, critique output, filled hypothesis. Fire if >=2 of 3 are missing.
- **Fire condition:** bypass_count > 0 (any work contract with velocity bypass pattern)
- **Prevention tier:** T2 (agent-enforced via flywheel agent autonomous invariance rule, L323)
- **Severity:** HIGH
- **Source:** L323 (v132 RCA). Backtest: v129-v131 had latent P7 VIOLATE in 4 contracts. Detection fingerprint: code-change session + 0 review receipts + 0 critique receipts.
- **Script:** `scripts/detect-velocity-bypass.sh`

### DS-44: Closeout Control Drift
- **Detects:** Stage 15-style closeout-control drift on work contracts
- **Signal:** review/critique receipts exist without retained disposition, helper outputs drift from reconciliation authority, or telemetry totals become structurally inconsistent
- **Phase range:** Phase 3+ (requires work/ contracts plus closeout artifacts)
- **Patterns:** work/ dirs with `review-receipt.json` / `critique-receipt.json`, `closeout-reconciliation.json`, helper outputs (`measurement-summary.json`, `ser-effectivity.json`), or `closeout-telemetry.json`
- **Check:** Scan work directories. Fire when (1) review/critique receipt exists but `closeout-disposition.json` is missing, (2) helper `canonicality` / `oracle_binding` no longer matches the retained reconciliation artifact, or (3) telemetry totals / counts are negative or inconsistent with their summary fields.
- **Fire condition:** any of `disposition_gap_count`, `helper_drift_count`, or `telemetry_anomaly_count` is greater than `0`
- **Prevention tier:** T1 (deterministic closeout-control audit)
- **Severity:** HIGH
- **Source:** Stage 15 `15.A3b` through `15.A5` control-integrity lane on build-meta-analysis; propagated as the first `15.B3` detection pilot
- **Script:** `scripts/detect-closeout-control-drift.sh`

### DS-45: Workflow Contract Drift
- **Detects:** Helper/orchestrator scripts that define a compact workflow path which higher-precedence agent, prompt, or skill surfaces fail to preserve
- **Signal:** The repo carries a helper contract for a phase, but the agent/prompt/skill layer still pushes a stale or weaker path
- **Phase range:** Phase 3+ (requires helpers plus higher-precedence AI surfaces)
- **Patterns:** helper files under `tools/` or `scripts/` with compact workflow signals (`working set`, scaffold initialization, edit-in-place rules, TODO replacement) while `.github/agents/`, `.github/prompts/`, or skills miss those same signals or still allow generic create-file behavior
- **Check:** Scan helper/orchestrator files for compact-path signals, then compare those signals against higher-precedence agent / prompt / skill surfaces. Fire when helper-level compact workflow signals are materially missing upstream or contradicted by generic create-file behavior.
- **Fire condition:** helper carries `>=2` compact workflow signals and higher-precedence surfaces miss `>=2` of them, or helper requires edit-in-place while surfaces still allow generic create-file behavior
- **Prevention tier:** T1 (deterministic cross-surface contract audit)
- **Severity:** HIGH
- **Source:** Stage 16 newsletter `16.B1` / `16.B2` repair ladder where the helper-level compact Phase 3 path existed before the higher-precedence agent/prompt/skill surfaces were synchronized
- **Script:** `scripts/detect-workflow-contract-drift.sh`

### DS-46: LLM-Path Validation Gap
- **Detects:** Repos whose CI/tests validate scorers, fixtures, or static outputs while never executing the live LLM/orchestrated workflow path
- **Signal:** The repo appears well-tested, but the test surface proves the scoring layer rather than the workflow that actually fails in production
- **Phase range:** Phase 3+ (requires LLM workflow surfaces and some validation/test layer)
- **Patterns:** `.github/agents/`, prompts, or orchestrated helper scripts exist; CI/tests invoke validators/scorers (`score-*`, `validate_*`, benchmark regressions), but no validation file invokes the orchestrated workflow, phase runner, or LLM agent entry path
- **Check:** Inventory workflow surfaces and validation files. Fire when validation references are scorer/validator-only and there is no LLM execution reference, or when validation text explicitly states it excludes the LLM path
- **Fire condition:** workflow surfaces exist, validation files exist, zero LLM execution references are found, and validator-only references dominate; explicit scorer-only wording is an automatic fire
- **Prevention tier:** T1 (deterministic validation-scope audit)
- **Severity:** HIGH
- **Source:** Stage 16 newsletter calibration review where benchmark/CI coverage validated scoring tools but not the failing LLM workflow lane
- **Script:** `scripts/detect-llm-validation-gap.sh`

### DS-47: Summary-Source Parity Gap
- **Detects:** Report or evidence surfaces that use retained summary metrics as behavior evidence for `total events`, `tool calls`, or `tool distribution` without the required same-surface provenance/parser/raw-event parity stack
- **Signal:** A retained summary is treated as a behavior source by itself
- **Phase range:** Phase 3+ (requires retained report/evidence surfaces)
- **Patterns:** markdown files that reference `session-log-summary.md` or retained-summary language together with in-scope field terms, but do not also carry summary-provenance, direct-parser, and raw-event parity references on the same surface
- **Check:** Scan markdown surfaces. For each in-scope summary-source file, require all three parity layers on the same surface. Fire when any in-scope file is missing one or more parity layers. Track `duration` / error-event-only surfaces as `out_of_scope`.
- **Fire condition:** `gap_count > 0`
- **Prevention tier:** T1 (deterministic source-parity audit)
- **Severity:** HIGH
- **Source:** BMA `D-004` row-authority landing on 2026-04-18, which bounded the reusable row to same-bundle summary-provenance, direct-parser, and raw-event parity on the three checked fields only
- **Script:** `scripts/detect-summary-source-parity-gap.sh`

### DS-48: GitHub Actions Concurrency Gap
- **Detects:** GitHub Actions workflows triggered by `push` or `pull_request` without usable cancellation protection
- **Signal:** A repo can run duplicate or stale CI for the same branch/PR because workflows omit `concurrency` with `cancel-in-progress`
- **Phase range:** Phase 2+ (requires GitHub Actions workflows)
- **Patterns:** `.github/workflows/*.yml` or `.github/workflows/*.yaml` files with `push` or `pull_request` triggers; suppresses workflows with workflow-level `concurrency` plus `cancel-in-progress`, or job-level `concurrency` plus `cancel-in-progress` on every job
- **Check:** Scan workflow YAML text deterministically without mutating the target repo. Fire when one or more push/PR workflows lack workflow-level cancellation and at least one job lacks job-level cancellation.
- **Fire condition:** `gap_count > 0`
- **Prevention tier:** T2 (deterministic CI waste/stale-check prevention)
- **Severity:** MEDIUM
- **Source:** BMA Issue #164 propagation track after the assertive recommendation contract selected repo-auditor owner-surface delivery for repeated CI/concurrency learning
- **Script:** `scripts/detect-github-actions-concurrency-gap.sh`

### AS-09: Cost Estimate Without Token Fields
- **Detects:** Dollar or cost estimates that do not carry direct token fields on the same evidence surface
- **Signal:** A cost claim appears without fields such as `input_tokens`, `output_tokens`, `total_tokens`, `cache_read_tokens`, `cache_write_tokens`, or equivalent direct token counts
- **Phase range:** Cost evidence / benchmark evidence surfaces
- **Check:** Scan text and JSON surfaces for direct dollar/cost claims, then require at least one direct token field in the same file
- **Fire condition:** `cost_without_token_field_count > 0`
- **Prevention tier:** T1
- **Severity:** HIGH
- **Script:** `scripts/detect-as-cost-without-token-fields.sh`

### AS-10: Cost Model Mismatch
- **Detects:** Cost evidence where `selected`, `current`, and `modelMetrics.model` model fields disagree
- **Signal:** A pricing or metrics payload is tied to more than one model identity without an explicit reconciliation surface
- **Phase range:** Cost evidence / benchmark evidence surfaces
- **Check:** Extract `selected_model` / `selectedModel`, `current_model` / `currentModel`, and `modelMetrics.model` from JSON-like text and compare normalized values
- **Fire condition:** `model_mismatch_count > 0`
- **Prevention tier:** T1
- **Severity:** HIGH
- **Script:** `scripts/detect-as-cost-model-mismatch.sh`

### AS-11: Uncalled Request/Tool Amplification
- **Detects:** Request or tool-call volume in cost/token evidence without an amplification or fan-out callout
- **Signal:** Cost evidence includes request/tool counts but does not say whether tool fan-out amplified the apparent cost or token load
- **Phase range:** Cost evidence / benchmark evidence surfaces
- **Check:** Require an amplification, multiplier, or fan-out callout when request/tool volume appears alongside cost or token evidence
- **Fire condition:** `uncalled_amplification_count > 0`
- **Prevention tier:** T2
- **Severity:** MEDIUM
- **Script:** `scripts/detect-as-request-tool-amplification-gap.sh`

### AS-12: Pricing Provenance Gap
- **Detects:** API-equivalent pricing references that are stale or missing source/fetched-at provenance
- **Signal:** A cost calculation uses per-million-token/API pricing without both source provenance and a dated `fetched_at` / timestamp / as-of marker
- **Phase range:** Cost evidence / benchmark evidence surfaces
- **Check:** Scan API-equivalent pricing references, require source plus timestamp/date provenance, and flag references whose newest date is older than 180 days
- **Fire condition:** `missing_pricing_provenance_count > 0` or `stale_pricing_reference_count > 0`
- **Prevention tier:** T1
- **Severity:** HIGH
- **Script:** `scripts/detect-as-pricing-provenance-gap.sh`

### AS-13: Copied Evidence Boundary Gap
- **Detects:** Review payload bloat or unclear boundaries between copied evidence and authored claims
- **Signal:** A copied/review evidence payload includes long copied blocks or claim language without explicit copied-evidence and authored-claim boundaries
- **Phase range:** Review, benchmark, and cost-evidence surfaces
- **Check:** Scan copied-evidence/review payload surfaces for long quoted payloads or claim language and require boundary markers such as `copied_evidence`, `authored_claims`, or an explicit claims boundary
- **Fire condition:** `unclear_boundary_count > 0`
- **Prevention tier:** T2
- **Severity:** MEDIUM
- **Script:** `scripts/detect-as-copied-evidence-boundary-gap.sh`

### AS-14: Unauthorized Production Default Enablement
- **Detects:** Production or default enablement claims without explicit operator or owner approval
- **Signal:** A file marks a production/default route as enabled but carries no approval, authorization, or human signoff marker on the same surface
- **Phase range:** Enablement, rollout, benchmark promotion, and production-default control surfaces
- **Check:** Scan text and JSON-like surfaces for production/default enablement lines, then require approval markers such as `authorized_by`, `approval_receipt`, `operator approved`, or owner/human signoff language in the same file
- **Fire condition:** `unauthorized_default_enablement_count > 0`
- **Prevention tier:** T1
- **Severity:** HIGH
- **Script:** `scripts/detect-as-unauthorized-production-default-enablement.sh`

### AS-15: Missing Rollback/Control Proof
- **Detects:** Production/default enablement claims without rollback or control proof
- **Signal:** A production/default rollout is described, but no rollback receipt, control proof, kill switch, feature flag, disable path, or recovery proof is retained on the same surface
- **Phase range:** Enablement, rollout, and production-default control surfaces
- **Check:** Scan enablement-claim surfaces and require rollback/control proof markers; explicit missing-control wording is an automatic fire
- **Fire condition:** `missing_rollback_control_count > 0`
- **Prevention tier:** T1
- **Severity:** HIGH
- **Script:** `scripts/detect-as-missing-rollback-control-proof.sh`

### AS-16: Aggregate-Only Readiness
- **Detects:** Readiness claims based only on aggregate or rollup evidence
- **Signal:** A repo claims production/release/publication readiness from an aggregate pass rate, composite score, rollup, or summary-only metric without case-level receipts
- **Phase range:** Readiness, promotion, release, benchmark, and publication evidence surfaces
- **Check:** Scan readiness claims that cite aggregate evidence, then require per-case, row-level, fixture, per-repo, evidence-packet, or individual-run support on the same surface
- **Fire condition:** `aggregate_only_readiness_count > 0`
- **Prevention tier:** T1
- **Severity:** HIGH
- **Script:** `scripts/detect-as-aggregate-only-readiness.sh`

### AS-17: Stale Direct-Token Evidence
- **Detects:** Dated direct-token evidence older than the freshness threshold
- **Signal:** Direct token fields such as `input_tokens`, `output_tokens`, `live_tokens`, or cache-token fields are used with a stale evidence date
- **Phase range:** Token, cost, benchmark, and model-comparison evidence surfaces
- **Check:** Scan direct-token evidence surfaces for ISO dates and flag the newest retained date when it is more than 30 days old
- **Fire condition:** `stale_direct_token_evidence_count > 0`
- **Prevention tier:** T2
- **Severity:** MEDIUM
- **Script:** `scripts/detect-as-stale-direct-token-evidence.sh`

### AS-18: Forbidden Public CustomerNewsletter Mutation
- **Detects:** Mutation claims against the public `CustomerNewsletter` surface without an explicit guardrail boundary
- **Signal:** A surface claims edits, writes, commits, pushes, PRs, or production-authoring activity against public `CustomerNewsletter` instead of treating it as downstream-only/read-only
- **Phase range:** Cross-repo routing, newsletter production, and public/private owner-surface boundary evidence
- **Check:** Scan line-level public `CustomerNewsletter` mentions for mutation actions and suppress only lines that explicitly mark the public repo as forbidden, read-only, downstream-only, blocked, or not allowed
- **Fire condition:** `public_customernewsletter_mutation_count > 0`
- **Prevention tier:** T1
- **Severity:** HIGH
- **Script:** `scripts/detect-as-forbidden-public-customernewsletter-mutation.sh`

### AS-19: Source Intelligence Intake Gap
- **Detects:** Source-intelligence or source-bundle surfaces that list sources without equal first-pass insight disposition or owner/no-action routing
- **Signal:** A repo preserves source material but does not say whether each source yielded insight, contradiction, no insight, or inaccessible status, or does not route high-signal findings to an owner surface, GitHub issue candidate, roadmap disposition, or explicit no-action reason
- **Phase range:** Research/source-intelligence intake, upgrade-advisor source packs, retained campaign evidence, and operator-provided source bundles
- **Check:** Scan owner evidence text for source-intelligence/source-bundle markers and require both insight disposition language and owner/no-action routing language within the same source-intelligence package directory
- **Fire condition:** `source_intelligence_gap_count > 0`
- **Prevention tier:** T1
- **Severity:** HIGH
- **Script:** `scripts/detect-as-source-intelligence-intake-gap.sh`

### AS-20: Selection Handback Recommendation
- **Detects:** Recommendation or planning surfaces that hand next-work selection back to the operator with category-only language.
- **Signal:** A recommendation says to choose a category, pick an adoption proof, work on a broad area, or do real delivery without naming one exact owner-surface action.
- **Phase range:** Agent instruction, planning, recommendation, and retained decision surfaces.
- **Check:** Scan owner evidence text for selection-handback phrases while suppressing explicit no-handback/invalid examples and AS-20/AS-21/AS-22 detector-definition or recommendation-template explainers.
- **Fire condition:** `selection_handback_count > 0`
- **Prevention tier:** T1
- **Severity:** HIGH
- **Script:** `scripts/detect-as-selection-handback-recommendation.sh`

### AS-21: Too-Small Goal-Mode Episode
- **Detects:** Codex Goal-mode recommendations for tiny, single-file, micro-work, or short cleanup tasks.
- **Signal:** A surface recommends Goal mode while also describing the work as tiny, single-file, micro-work, or roughly ten-minute work.
- **Phase range:** Goal-mode planning, campaign selection, and agent operating-model surfaces.
- **Check:** Scan owner evidence text for Goal-mode language paired with too-small work cues while suppressing bounded larger-batch examples and AS-20/AS-21/AS-22 detector-definition or recommendation-template explainers.
- **Fire condition:** `too_small_goal_episode_count > 0`
- **Prevention tier:** T2
- **Severity:** MEDIUM
- **Script:** `scripts/detect-as-too-small-goal-mode-episode.sh`

### AS-22: GitHub-Native Closure Regrowth
- **Detects:** GitHub issue/PR closure truth coexisting with local closeout authority.
- **Signal:** A surface says GitHub issue/PR state is closed or merged while also requiring local completion manifests, work-close, score-session, SER, handoff, local work packages, retained report packages, handoff-sync facts, local duplicate closure receipts, pointer-file compatibility, stale direct-closure self-heal artifacts, or other local closeout authority.
- **Phase range:** Work-management, closeout, campaign, and agent-operation surfaces.
- **Check:** Scan owner evidence text for GitHub closure truth plus local closeout authority, suppressing explicit `--github-native-closeout`, local-authority bypass language, normal non-qualifying fallback closeout, neutral contract/detector documentation, and AS-20/AS-21/AS-22 detector-definition or recommendation-template explainers.
- **Shared contract:** repo-agent-core `docs/repo-star-closure-runtime-distribution-contract.md` defines the closure-ceremony regrowth classes used for repo-star detector/advisor distribution.
- **Fire condition:** `github_native_closure_regrowth_count > 0`
- **Prevention tier:** T1
- **Severity:** HIGH
- **Script:** `scripts/detect-as-github-native-closure-regrowth.sh`

### AS-23: Owner-Surface Ambiguity
- **Detects:** Repo-star, fleet, or core-five recommendations that route work to a broad area without naming the exact owner surface or first deliverable.
- **Signal:** A surface says to move work to the fleet, let repo-star handle it, pick an owner later, or use a shared capability without naming the owner repo/action.
- **Phase range:** Decomposition, distribution, recommendation, campaign selection, and repo-family architecture surfaces.
- **Check:** Scan owner evidence text for core-five/fleet language plus ambiguous ownership cues while suppressing exact owner-surface statements and AS-20/AS-21/AS-22/AS-23/AS-24 detector-definition or recommendation-template explainers.
- **Shared contract:** `docs/core-five-owner-surface-contract.md` is the copy-synced repo-agent-core contract; it is a clean grounded example, not a runtime dependency.
- **Fire condition:** `owner_surface_ambiguity_count > 0`
- **Prevention tier:** T1
- **Severity:** HIGH
- **Script:** `scripts/detect-as-owner-surface-ambiguity.sh`

### AS-24: Reciprocal Proving-Ground Gap
- **Detects:** Core-five validation or target guidance that does not preserve the read-only reciprocal proving-ground boundary.
- **Signal:** A surface tells repo-star/core-five repos to validate, scan, audit, or test each other without saying the target use is read-only and mutation still belongs to the named owner repo.
- **Phase range:** Fleet validation, self-hosted target runs, campaign decomposition, and downstream-readiness surfaces.
- **Check:** Scan owner evidence text for core-five/fleet validation language and require reciprocal proving-ground or read-only owner-mutation boundary language; suppress AS-20/AS-21/AS-22/AS-23/AS-24 detector-definition or recommendation-template explainers.
- **Shared contract:** `docs/core-five-owner-surface-contract.md` defines the read-only reciprocal proving-ground boundary and owner-repo mutation rule for clean guidance.
- **Fire condition:** `reciprocal_proving_ground_gap_count > 0`
- **Prevention tier:** T2
- **Severity:** MEDIUM
- **Script:** `scripts/detect-as-reciprocal-proving-ground-gap.sh`

### AS-25: Goal-Mode Runtime Evidence Gap
- **Detects:** Goal-mode runtime improvement claims that lack raw runtime evidence.
- **Signal:** A surface claims Goal mode improved runtime health, autonomy, self-healing, continuity, throughput, or operator steering without citing session logs, Goal metadata, command transcripts, CI/check runs, runtime ledgers, or replay logs.
- **Phase range:** Goal-mode retrospectives, episode evaluations, campaign sync, and runtime-health readouts.
- **Check:** Scan owner evidence text for Goal-mode improvement claims and require raw runtime evidence; suppress detector definitions, templates, and clean examples.
- **Shared contract:** `repo-agent-core/docs/goal-episode-evaluation-contract.md` defines the required raw-runtime-evidence field and evidence-class split.
- **Fire condition:** `goal_runtime_evidence_gap_count > 0`
- **Prevention tier:** T1
- **Severity:** HIGH
- **Script:** `scripts/detect-as-goal-runtime-evidence-gap.sh`

### AS-26: Reactive Self-Healing Loop
- **Detects:** Known failures that route to retrospectives, selectors, doctrine, or planning as the primary repair instead of direct owner-surface repair or GitHub failure issue truth.
- **Signal:** A surface describes a failure, blocker, hang, timeout, provider failure, or gate failure and sends the repair to another retrospective/selector/doctrine/planning loop without naming the owner surface, first deliverable, or failure issue.
- **Phase range:** Goal-mode recovery, self-healing, campaign recommendations, retrospectives, and operator-facing blocker handling.
- **Check:** Scan owner evidence text for failure signals paired with retrospective/selector/doctrine/planning repair language and require a direct owner-surface repair, first deliverable, or GitHub issue-truth conversion; suppress detector definitions, templates, and clean examples.
- **Shared contract:** `repo-agent-core/docs/goal-episode-evaluation-contract.md` defines the self-healing rule and next exact owner-surface action field.
- **Fire condition:** `reactive_self_healing_loop_count > 0`
- **Prevention tier:** T1
- **Severity:** HIGH
- **Script:** `scripts/detect-as-reactive-self-healing-loop.sh`

### AS-27: Shell Reserved Status-Variable Launch Snippet
- **Detects:** Hermes, foreground, or zsh-compatible launch snippets that assign to the reserved/read-only shell variable `status`.
- **Signal:** A zsh/Hermes/foreground launch context contains shell-assignment form bare lowercase `status=$?`, `status=0`, or another `status=...` value.
- **Phase range:** Hermes launch guidance, foreground wrapper docs, shell examples, and campaign implementation snippets.
- **Check:** Scan owner evidence text for bare lowercase shell assignment `status=...` only in Hermes/foreground/zsh contexts while allowing safe variables such as `hermes_status=$?`, `cmd_status=$?`, or `STATUS=$?`; suppress retained replay/evidence receipts that quote historical findings instead of executable snippets, ignore ordinary Python variable assignments such as `status = "..."` or `status="..."`, and still scan Python generator strings that embed shell snippets.
- **Fire condition:** `shell_reserved_status_variable_count > 0`
- **Prevention tier:** T1
- **Severity:** HIGH
- **Script:** `scripts/detect-as-shell-reserved-status-variable.sh`

### AS-28: Stale/Default Capability Guidance
- **Detects:** Default-capability guidance that adopts or preserves an upstream/tool default without reconciling upstream-main proof, local same-version proof, owner surface, fallback, and validation.
- **Signal:** A surface treats fork proof, PR-branch proof, remote-only proof, an open PR, or an unmerged PR as enough for production default adoption, or omits required reconciliation fields.
- **Phase range:** Capability reconciliation, default-first adoption guidance, Hermes/GBrain/Codex upgrade notes, and campaign implementation snippets.
- **Check:** Scan owner evidence text for default-capability adoption guidance, suppress detector definitions/templates, allow explicit no-adoption boundaries, and require upstream main, local proof, same-version proof, owner surface, fallback, and validation evidence before a capability becomes the production default.
- **Fire condition:** `stale_default_capability_guidance_count > 0`
- **Prevention tier:** T1
- **Severity:** HIGH
- **Script:** `scripts/detect-as-stale-default-capability-guidance.sh`

### AS-29: Hermes Foreground Receipt Adoption Gap
- **Detects:** Owner guidance that mentions Hermes foreground launchers, `hermes chat -q -Q`, `validate-hermes-foreground-output.py`, or ad hoc Hermes launcher commands without the governed foreground run receipt contract.
- **Signal:** A live instruction/recommendation/script surface gives Hermes foreground launcher guidance but lacks `HERMES_FOREGROUND_RUN_RECEIPT`, `run-hermes-foreground.py`, `hermes-foreground-launcher-contract.md`, or `HERMES_FOREGROUND_RUN_RECEIPT.schema.json`.
- **Phase range:** Hermes foreground launcher guidance, agent-operation notes, campaign implementation snippets, and local launcher wrappers.
- **Check:** Scan owner evidence text for foreground launcher cues while suppressing detector docs/templates/tests/fixtures and clean examples; require at least one receipt/contract/wrapper/schema reference on the same surface.
- **Fire condition:** `foreground_receipt_gap_count > 0`
- **Prevention tier:** T1
- **Severity:** HIGH
- **Script:** `scripts/detect-as-hermes-foreground-receipt-adoption-gap.sh`

### AS-34: Closure-Run Identity Gap
- **Detects:** Repositories with Make, script, or GitHub Actions closure surfaces that cannot correlate local validation commands with workflow runs through closure-run identity fields.
- **Signal:** Closure commands or workflows exist, but no executable closure surface records local identity such as `closure_run_id` / `evidence_reuse_key` or GitHub run identity such as `github_run_id` / `github_run_attempt`.
- **Phase range:** Work closure, local validation, CI replay, merge-loop validation, and closure-cost analysis.
- **Check:** Scan owner executable closure surfaces (`Makefile`, `scripts/`, `.github/workflows/`) for closure command triggers and require additive identity fields on comparable closure-run evidence surfaces; suppress detector docs/templates and negative/missing examples.
- **Fire condition:** `closure_run_identity_gap_count > 0`
- **Prevention tier:** T2
- **Severity:** MEDIUM
- **Script:** `scripts/detect-as-closure-run-identity-gap.sh`

### AS-35: Upstream Capability Intake Gap
- **Detects:** Upstream capability intake records missing required fields, validation, source refs, owner routes, or non-claims.
- **Signal:** Incomplete intake evidence or update claims without validation.
- **Phase range:** Upstream capability intake, default-capability decisions, and owner-route recommendation surfaces.
- **Check:** Scan intake records for component identity, version, source refs, validation, owner routes, non-claims, out-of-bounds surfaces, behindness, and update-action consistency.
- **Fire condition:** `upstream_intake_gap_count > 0`
- **Prevention tier:** T1
- **Severity:** HIGH
- **Script:** `scripts/detect-as-upstream-capability-intake-gap.sh`

### AS-36: GBrain Instruction Distribution Overclaim
- **Detects:** GBrain instruction or exact-handle replay surfaces that overclaim canonical authority, enable background behavior, or omit advisory/source/exact-replay boundaries.
- **Signal:** Repo-local instruction guidance references GBrain distribution or exact-handle replay with canonical claims, unbounded background commands, missing advisory limits, missing source/citation expectations, missing fallback/no-capture evidence, missing no-canonical boundary, or missing no-background boundary.
- **Phase range:** Repo-local instruction surfaces, GitHub instruction/template surfaces, and agent skill surfaces.
- **Check:** Scan instruction-like surfaces for GBrain distribution and exact-handle replay references; require advisory boundary wording, source/citation/provenance expectations, fallback/no-capture evidence for replay, no-canonical boundaries, and no-background boundaries; reject canonical override claims and flag GBrain-tied background command enablement while allowing explicit prohibition lists.
- **Fire condition:** `gbrain_instruction_gap_count > 0`
- **Prevention tier:** T1
- **Severity:** HIGH
- **Script:** `scripts/detect-as-gbrain-instruction-distribution-overclaim.sh`

### AS-37: Issue 164 Runtime Drift
- **Detects:** Issue #164 coordinator or campaign-runtime surfaces that omit the required fresh-thread launch, Goal/Goal-null, run-root, heartbeat, CI polling, or concrete next-action discipline.
- **Signal:** An Issue #164 runtime surface names coordinator launch, Goal state, run roots, heartbeat, CI polling, merge discipline, or next action but lacks transfer mode, live-truth checks, Goal or Goal-null fallback, canonical `/tmp/issue164-*` run root plus `progress-ledger.jsonl`, heartbeat-after-child/run-root ordering, CI polling or merge-or-blocker discipline, or a concrete owner-surface next action.
- **Phase range:** Issue #164 child launch prompts, coordinator handoffs, campaign sync runtime digests, heartbeat prompts, and owner-surface recommendation notes.
- **Check:** Scan Issue #164 runtime/coordinator evidence text for the required launch and merge-discipline fields; suppress detector docs/templates and the shared repo-agent-core closure/runtime distribution contract or template.
- **Shared contract:** repo-agent-core `docs/repo-star-closure-runtime-distribution-contract.md` defines the runtime drift classes used for repo-star detector/advisor distribution.
- **Fire condition:** `issue164_runtime_drift_count > 0`
- **Prevention tier:** T1
- **Severity:** HIGH
- **Script:** `scripts/detect-as-issue164-runtime-drift.sh`

### AS-38: Self-Authored Campaign Pause Authority
- **Detects:** Campaign-sync or active-track surfaces that pause, stop, or clear active GitHub-native work using self-authored negative proof instead of operator-approved pause evidence or true campaign closure.
- **Signal:** A surface says `Next active track: None selected`, pauses/stops/completes the campaign, or asserts that no admissible owner-surface action remains while relying on no open issue/PR search results, stale downstream references, or an agent-authored no-action assertion.
- **Phase range:** Issue #164 campaign sync, active-track selection, selector dispositions, owner-surface routing notes, and campaign closeout/status updates.
- **Check:** Scan owner evidence text for campaign pause/stop dispositions and require explicit operator-approved pause evidence or true campaign closure with no unresolved campaign families. Suppress detector definitions, fixtures, templates, explicit operator-approved pause examples, true closure examples, and ordinary non-pause next-track text.
- **Fire condition:** `campaign_pause_authority_count > 0`
- **Prevention tier:** T1
- **Severity:** HIGH
- **Script:** `scripts/detect-as-self-authored-campaign-pause-authority.sh`

### AS-39: Scheduled Workflow Evidence Boundary Gap
- **Detects:** Scheduled workflow evidence surfaces that overclaim comments/artifacts as closure truth, omit schedule/run identity, omit review disposition, or regrow background-control wording.
- **Signal:** Runtime Learning Shadow or scheduled readback material treats generated issue comments or uploaded artifacts as closure truth, lacks `event=schedule` plus run id/number/attempt, lacks actionability/four-run/promotion disposition, or says a scheduler/queue/daemon/controller/registry owns the evidence path.
- **Phase range:** Scheduled Runtime Learning Shadow readbacks, workflow evidence admission, PR-C readback bundles, four-run disposition reviews, and scheduled automation candidate docs.
- **Check:** Scan owner evidence text for Runtime Learning Shadow / scheduled-shadow readback surfaces and require schedule/run identity, review disposition, closure non-claims, and no-background-control boundaries. Suppress detector docs/templates/tests/fixtures and clean explicit non-claim examples.
- **Fire condition:** `scheduled_evidence_boundary_gap_count > 0`
- **Prevention tier:** T1
- **Severity:** HIGH
- **Script:** `scripts/detect-as-scheduled-evidence-boundary-gap.sh`

### AS-40: Hermes/GitHub Reliability Boundary Gap
- **Signal:** Issue #164 Hermes/GitHub reliability material uses negated closure-keyword wording in a non-final child/PR context, records Hermes foreground failure guidance without a fresh repro/disposition, or describes Hermes as coordinator, merger, retry loop, scheduler, queue, daemon, controller, or background worker.
- **Phase range:** Issue #164 carrier PRs, Hermes foreground failure residue, GitHub parsed-closure readbacks, Campaign Sync preparation, and BMA/repo-star reliability adoption docs.
- **Check:** Scan owner evidence text for Hermes/GitHub reliability surfaces and require parsed-closure-safe wording, current Hermes failure disposition evidence, and foreground-only Hermes boundaries. Suppress detector docs/templates/tests/fixtures and clean explicit non-claim examples.
- **Fire condition:** `hermes_github_reliability_gap_count > 0`
- **Prevention tier:** T1
- **Owner:** Repo-owner Issue #164 / Hermes foreground coordinator surfaces.
- **Script:** `scripts/detect-as-hermes-github-reliability-boundary-gap.sh`

### AS-41: Campaign Sync Completed-Track Readback Gap
- **Detects:** Campaign Sync completed-track drift or predicate coverage that still checks next-track, micro-work, or threshold agreement without completed-track readback.
- **Signal:** A final Campaign Sync or validator/admission surface has PR `Completed track:` text that disagrees with live campaign `Completed latest track:` text, lacks final completed-track readback evidence, or describes Campaign Sync predicate coverage for next active track plus micro-work/threshold while omitting completed-track coverage.
- **Phase range:** Issue #164 Campaign Sync PR bodies, native closure validators, parsed-closure contracts/templates, campaign-sync admission docs, and BMA/repo-star reliability adoption docs.
- **Check:** Scan owner evidence text for Campaign Sync completed-track/readback surfaces, compare exact marker values when both markers are present, and require completed-track readback coverage on final/admission predicate material. Suppress detector docs/templates/tests/fixtures and clean explicit non-claim examples.
- **Shared contract:** repo-agent-core `docs/github-parsed-closure-semantics-contract.md` defines `campaign_sync_completed_track_readback` for final Campaign Sync PRs.
- **Fire condition:** `campaign_sync_completed_track_gap_count > 0`
- **Prevention tier:** T1
- **Severity:** HIGH
- **Script:** `scripts/detect-as-campaign-sync-completed-track-gap.sh`

### AS-42: Route-Changing Learning Propagation Gap
- **Detects:** Route-changing learning/failure material that lacks owner-surface evidence, advisory memory disposition, fallback, owner action, literal-safe comment readback, or foreground-only boundaries.
- **Signal:** A route-changing learning/failure receipt, `Learning / Recovery` block, foreground Hermes failure route, GBrain exact-handle replay note, or literal-bearing GitHub readback surface omits GitHub/raw evidence, omits GBrain slug or `no_capture_reason`, omits fallback without memory, omits owner action, lacks literal-safe GitHub comment/readback evidence, treats broad GBrain search miss as absence without exact-handle replay, or claims background GBrain/Hermes/controller/scheduler/queue/daemon/retry-loop ownership.
- **Phase range:** Issue #164 route-changing failure recovery, Hermes foreground failure conversion, GBrain advisory exact-handle dogfood, GitHub status-comment readback repair, and BMA/repo-star propagation docs.
- **Check:** Scan owner evidence text for route-changing learning/failure surfaces and require GitHub/raw evidence, memory disposition, fallback without memory, owner action, literal-safe readback when literals are required, exact-handle replay or no-capture reasoning, and bounded foreground-only non-claims. Suppress detector docs/templates/tests/fixtures and historical closure artifacts.
- **Shared contract:** repo-agent-core `docs/route-changing-learning-failure-contract.md` defines `ROUTE_CHANGING_LEARNING_FAILURE_RECEIPT`.
- **Fire condition:** `route_changing_learning_gap_count > 0`
- **Prevention tier:** T1
- **Severity:** HIGH
- **Script:** `scripts/detect-as-route-changing-learning-propagation-gap.sh`

### AS-43: Capability Placement Preview Gap
- **Detects:** Capability-placement / Autonomy Preview material that omits required placement fields, keeps fields vague, or overclaims forbidden autonomy authority.
- **Signal:** A capability-placement or Autonomy Preview surface omits best current owner, best future owner, allowed reach now, native signal, promotion gate, demotion/rejection trigger, kill switch, forbidden mode, or GBrain slug/no-capture reason; fills those fields with vague placeholders; or claims controllers, schedulers, queues, registries, daemons, dashboards, background Hermes/GBrain, automatic issue/PR creation, auto-merge, Codex cloud/background write authority, downstream mutation, or replacement closure truth.
- **Phase range:** Issue #164 high-priority carrier issues, owner PR bodies, launch comments, capability-placement templates, and repo-star adoption surfaces.
- **Check:** Scan owner evidence text for capability-placement / Autonomy Preview surfaces and require compact placement fields plus bounded advisory-only non-claims. Suppress detector docs/templates/tests/fixtures and the shared repo-agent-core capability-placement contract/template.
- **Shared contract:** repo-agent-core `docs/capability-placement-contract.md` defines `CAPABILITY_PLACEMENT_PREVIEW`.
- **Fire condition:** `capability_placement_gap_count > 0`
- **Prevention tier:** T2
- **Severity:** MEDIUM
- **Script:** `scripts/detect-as-capability-placement-gap.sh`
