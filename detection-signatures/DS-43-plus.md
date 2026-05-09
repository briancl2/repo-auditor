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

### AS-19: Model/Effort Claim Binding Gap
- **Detects:** Model or reasoning-effort outcome claims that lack exact prompt/session binding
- **Signal:** A model/effort cell is credited with cost, token, quality, pass, routing, or qualification evidence without same-surface exact binding
- **Phase range:** Model comparison, reasoning-effort, benchmark, and cost evidence surfaces
- **Check:** Scan model/effort outcome claims and require exact model/effort, prompt/session, or bound-candidate binding markers on the same surface
- **Fire condition:** `model_effort_binding_gap_count > 0`
- **Prevention tier:** T1
- **Severity:** HIGH
- **Script:** `scripts/detect-as-model-effort-binding-gap.sh`

### AS-20: Stale Copilot Reporting Reuse
- **Detects:** Copilot report, summary, or scorecard reuse across model/version/effort cells without current per-cell binding
- **Signal:** A stale or reused Copilot reporting surface is carried across matrix cells that differ by model, Copilot version, or effort setting
- **Phase range:** Copilot CLI benchmark, matrix, model-routing, and reasoning-effort evidence surfaces
- **Check:** Scan Copilot reporting reuse language with model/version/effort cell terms and require current per-cell receipts, current Copilot version, or exact cell binding
- **Fire condition:** `stale_copilot_reporting_reuse_count > 0`
- **Prevention tier:** T1
- **Severity:** HIGH
- **Script:** `scripts/detect-as-stale-copilot-reporting-reuse.sh`

### AS-21: Promotion Without Current Control Noise Floor
- **Detects:** Promotion, adoption, readiness, or recommendation claims without a current `n>=3` control noise floor
- **Signal:** A benchmark route is promoted from single-row or stale control evidence instead of a current three-or-more-run control baseline
- **Phase range:** Promotion, adoption, production-readiness, model-routing, and benchmark evidence surfaces
- **Check:** Scan promotion/noise-floor surfaces and require both a current/fresh marker and a control noise-floor count of at least three on the same surface
- **Fire condition:** `promotion_without_current_n3_noise_floor_count > 0`
- **Prevention tier:** T1
- **Severity:** HIGH
- **Script:** `scripts/detect-as-promotion-without-control-noise-floor.sh`

### AS-22: Model Recommendation Before Production Confirmation
- **Detects:** Model recommendations that appear before retained production confirmation
- **Signal:** A surface recommends or standardizes on a model while production confirmation is missing, blocked, or absent
- **Phase range:** Model-routing, recommendation, production confirmation, and publication evidence surfaces
- **Check:** Scan recommendation language and require a retained/passed production confirmation marker on the same surface; explicit non-claims suppress the signature
- **Fire condition:** `model_recommendation_before_confirmation_count > 0`
- **Prevention tier:** T1
- **Severity:** HIGH
- **Script:** `scripts/detect-as-model-recommendation-before-production-confirmation.sh`

### AS-23: Phase Attribution Alias Gap
- **Detects:** Phase/token attribution claims that rely on risky receipt labels without explaining command-boundary or alias semantics
- **Signal:** A cost or token-growth surface credits a phase label such as `phase1b_xcode` while that label may be a last-receipt alias for a broader multi-artifact command
- **Phase range:** Cost attribution, canary attribution, pre-Phase context/source growth, and phase metrics evidence surfaces
- **Check:** Scan phase-attribution claims with alias-risk markers and require same-surface `phase_label_semantics`, command-boundary, multi-artifact, or receipt-alias grounding
- **Fire condition:** `phase_attribution_alias_gap_count > 0`
- **Prevention tier:** T2
- **Severity:** MEDIUM
- **Script:** `scripts/detect-as-phase-attribution-alias-gap.sh`
