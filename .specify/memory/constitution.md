# repo-auditor Constitution

## Purpose

repo-auditor is a **deterministic health scorer** that evaluates AI-native
repositories across 5 dimensions, producing SCORECARD.json and AUDIT_REPORT.md.
All analysis is pattern-matching and heuristic scoring.

## Non-Goals

- Domain tools are deterministic (no LLM required for standard mode).
- No recommendations (that's the advisor's job).
- No modifications to target repos (read-only analysis).
- No subjective judgments — all scores derive from countable signals.

## Core Principles

### 1. Deterministic-First Tools
Domain tools (pre-scan, maturity, stall-risk, dna, drift, scoring) MUST produce
identical output regardless of LLM availability. All checks are deterministic:
file existence, pattern matching, line counting, git log analysis. The agent
orchestrates these tools and synthesizes results. If a check requires judgment,
it belongs in deep mode or in the advisor.

### 2. 5-Dimension Scoring Model
All repos are scored on 5 orthogonal dimensions (D1-D5), each 0-20 points,
composited to 0-100. Dimensions must not overlap in what they measure.
New checks must declare which dimension they contribute to.

### 3. Tier 1 / Tier 2 Check Architecture
- **Tier 1**: File-existence and pattern checks (cheap, fast, deterministic).
- **Tier 2**: Cross-file analysis, git history, statistical checks (more expensive).
- T2 checks always run after T1 and may reference T1 results.
- T2 warnings are advisory, not dimension-scoring.

### 4. Evidence-Based Only
Every score point awarded must trace to a specific file, pattern, or git artifact.
The AUDIT_REPORT.md must include evidence citations for every score. "Vibes-based"
scoring is a violation. **Grader accuracy is a first-class metric (P3v2):** ground-truth
test on >=3 targets, golden fixture baseline, recalibrate scoring at stage boundaries.
Scorer stalls require measurement investigation before product investigation.

### 5. Detection Signatures (DS-1 through DS-21)
Detection signatures are named, versioned patterns that identify specific
anti-patterns in target repos. Each DS has: ID, name, detection logic,
severity, evidence format. New signatures must be validated against known
positive and negative examples before merge.

### 6. Bounded Execution
Scan budget: max 200 files per target. Check timeout: 5 minutes total.
If a target exceeds these bounds, the auditor reports partial results with
a coverage warning, not a failure.

## Spec-Kit Operating Rules

### Required Workflow (features >160 lines)
1. /speckit.specify → /speckit.plan → /speckit.tasks → implement
2. Every spec includes acceptance scenarios
3. New detection signatures require GT validation

### Definition of Done
- All existing tests pass (`make test`)
- Self-audit produces valid SCORECARD.json (`make audit TARGET=.`)
- No duplicate detection signatures
- AUDIT_REPORT.md format unchanged (or migration applied)

## Governance

This constitution supersedes informal practices. Amendments require
documented rationale and review.

### Universal Principle Amendments (Stage 11.6)

The following amendments from the 12 Universal Principles are binding:

- **P3v2 (Fix Measurement First):** Grader accuracy is a first-class metric.
  Ground-truth test on >=3 targets, golden fixture baseline, recalibrate at
  stage boundaries. Reflected in §4 above.
- **P6v5 (Enforced Over Advisory):** T1.5 tier recognized: mechanical triggers
  that invoke behavioral checks (e.g., auto-SER at work-close). score-operation.sh
  and operation-guard.sh are T1.5 mechanisms.
- **P7v3 (Feed Forward Automatically):** work-close REFUSES without learning
  extraction or explicit `--no-novel-findings <rationale>`. Learning-to-DS
  propagation rate tracked (target >=30%).
- **P11v3 (Seek Adversarial Counsel):** Mandatory critique triggers: (1) new spec,
  (2) principle revision, (3) >200 new lines across ALL modified repos,
  (4) handoff with >3 deliverables, (5) stage gate. Critique-Status header
  required on triggered commits. Skip-with-rationale allowed.

**Version**: 3.0 | **Ratified**: 2026-03-04 | **Amendment**: §4 P3v2 calibration + UA Stage 11.6 (P6v5, P7v3, P11v3)
