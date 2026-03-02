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
