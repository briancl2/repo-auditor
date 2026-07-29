# Detector Graduation Ledger

Single machine-checkable record of the **graduation status** of repo-auditor's
graduation-tracked detectors, so the append-only detector inventory
(`docs/live-capability-inventory.md`) becomes **prunable**.

This is a git-observable ledger, **not** a runtime dashboard (the
the historical R-A1 "do-not-build" owner decision).
It is maintained by hand during each n=2 graduation hunt and the standing
repo-health retrospective; `tests/test-detector-graduation-ledger.sh` guards its
internal integrity so the retire arithmetic cannot silently drift.

## Scope

Only detectors that flow through the **n=1 → n=2 graduation model** are tracked
here (the assimilation-family + operating-friction detectors **AS-51..AS-59** and
**DS-49**). Established/stable detectors (AS-1..AS-50, DS-1..DS-48) are not in the
graduation-tracking regime and are inventoried in
`docs/live-capability-inventory.md` only.

## Graduation rule

A detector **graduates** only when **confirmed true-positive fires span ≥2
distinct repos** (LEARNINGS L23, L24). Counting is by **distinct repos, not
runs**: repeated runs on one repo do not graduate a detector. A **correct
silence** (a true-negative on a clean repo) proves *no-false-positive* and is a
valid data point on the negative axis — it is **not** graduation (LEARNINGS L23,
L29). A **false positive** is a detector bug routed to an owner fix; it neither
graduates nor, by itself, retires the detector (LEARNINGS L29, L30).

## Retire rule

- **K = 2.** A **keep-candidate** with **≥ K distinct-repo graduation attempts
  that produced no confirmed true-positive fire** (only correct-silence and/or
  false-positive outcomes) becomes a **retire-candidate**.
- K=2 mirrors the graduation threshold: a detector given two real cross-repo
  chances that still catches nothing has not earned its append-only inventory
  slot. Making a detector a retire-candidate is an **owner decision surfaced by
  this ledger**, not an automatic deletion.
- **`Retire-eligible` is a pure function of the table:** it is `Y` **iff**
  `Status == keep-candidate` **and** `Non-graduating attempts ≥ K`, else `N`.
  `tests/test-detector-graduation-ledger.sh` recomputes and asserts this for
  every row.

At today's baseline **no detector is retire-eligible** — the ledger installs the
counting + rule and baselines the attempt counts so future stalls become visible
and prunable.

## Definitions

- **Confirmed fires (distinct repos):** count of distinct real repos with a
  manually-verified **true-positive** fire (fixtures are unit evidence, not repo
  fires).
- **Non-graduating attempts:** count of distinct-repo graduation attempts that
  did **not** yield a confirmed true-positive (correct-silence or false-positive
  outcomes).

## Ledger

| Detector | Family | Status | Confirmed fires (distinct repos) | Non-graduating attempts | Retire-eligible | Evidence |
|---|---|---|---|---|---|---|
| AS-51 | AS | graduated | 2 | 0 | N | L23 — anchor fired HIGH true-gap on transcript_processor (n=2 vs build repo). |
| AS-52 | AS | graduated | 2 | 0 | N | L23 — repo-anthropology-surface fired MEDIUM true-gap on transcript_processor (n=2). |
| AS-53 | AS | keep-candidate | 1 | 1 | N | L23 — positive catch n=1; correct true-negative on transcript_processor (1 non-graduating attempt, no false positive). |
| AS-54 | AS | keep-candidate | 1 | 0 | N | L24 — closure-signal-integrity D1/D2 fires on one repo (n=2 runs, n=1 repo); no 2nd-repo attempt yet. |
| AS-55 | AS | keep-candidate | 1 | 0 | N | L24 — review-ergonomics-working-memory-lightness D1/D2/D3 fires on one repo (n=3 runs, n=1 repo). |
| AS-56 | AS | keep-candidate | 1 | 0 | N | L25 — external-closure-coupling root-cause catch n=1 (issue #182); n=1 distinct-repo until confirmed elsewhere. |
| AS-57 | AS | keep-candidate | 1 | 0 | N | L26 context / issue #171 — native-evidence-before-verdict, n=1; no 2nd-repo graduation attempt yet. |
| AS-58 | AS | keep-candidate | 0 | 1 | N | L27/L29/L30 — instruction-contradiction; the one real BMA fire (#198) was verified FALSE POSITIVE and the archive/log FP class was fixed (#200). 1 non-graduating attempt; fresh n=2 re-hunt pending; true-positive evidence is fixtures only. |
| AS-59 | AS | keep-candidate | 1 | 0 | N | issue #205 — assimilation GitHub work-management-gap catch n=1; permission-insufficient readback is access/owner routing, not a repo-quality gap. |
| DS-49 | DS | keep-candidate | 1 | 1 | N | L28/L29/L31 — rework-recurrence; 0-FP on live repo-auditor (n=1 origin); correct SILENCE on BMA (#199, 1 non-graduating attempt); recall boundary on GitHub-native-closure repos ACCEPTED (#202), stays n=1. |

## How this stays current

When a graduation-tracked detector is added, changed, or run against a new repo:

1. Add or update its row here **and** its id in the required-set list in
   `tests/test-detector-graduation-ledger.sh` (one line each).
2. Record the outcome: a confirmed true-positive on a new distinct repo →
   increment **Confirmed fires** (graduate at 2); a correct-silence or
   false-positive → increment **Non-graduating attempts**.
3. Recompute **Retire-eligible** by the retire rule (the test enforces it).
4. Surface any new **retire-candidate** to an owner issue — this ledger records
   the signal; deletion is a separate operator-gated decision.
