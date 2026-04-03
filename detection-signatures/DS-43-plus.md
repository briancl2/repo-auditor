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
