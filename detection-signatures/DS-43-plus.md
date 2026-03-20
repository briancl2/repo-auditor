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
