# Repo-Health Retrospective — repo-auditor (n=1 fleet dogfood)

> Date: 2026-07-09
> Repo under examination: `repo-auditor` @ `009842a` (origin/main)
> Method: `repo-agent-core` `docs/repo-health-retrospective-method-contract.md`
> + `templates/repo-health-retrospective-method.md`
> Triggering lane: BMA #1270 Track D / maintained lane #1282 item **G4** (close the
> **F3** gap — "the fleet dogfoods its output but not its own operating process")

This is the first **off-BMA** run of the repo-health retrospective method: the
fleet's repo-health *scorer* examining its own operating *process* against its
own primary evidence. It is advisory synthesis. It implements no detector, opens
no issue, and mutates no sibling repo — the candidate register is handed back
unbuilt. The only repository mutation is this report.

## Method record

```json
{
  "artifact": "REPO_HEALTH_RETROSPECTIVE_METHOD",
  "schema_version": 1,
  "repo_identity": "repo-auditor @ 009842a (origin/main)",
  "operator_intent": "Is repo-auditor's operating process healthy, and what is the highest-return next move — more detectors, or cutting/simplifying the detector lifecycle? Serves the F3 goal of the fleet dogfooding its own operating process, not only its output.",
  "thesis": "repo-auditor's highest-return next operating move is adding more detectors (AS-NN/DS-NN).",
  "evidence_hierarchy": {
    "primary": [
      "git history (git log AS-50..AS-59, DS-49; PRs #158..#208)",
      "LEARNINGS.md (L1, L7, L17, L19, L23-L30)",
      "AGENTS.md + docs/live-capability-inventory.md + docs/agent-operations.md",
      "scripts/check.sh (EXPECTED inventory gate, co-evolution guard)",
      "GitHub issue/PR/check/merge state (#199 graduation hunt, #204 open)",
      "detector inventory: 83 detect-*.sh, AS-01..AS-59, DS-8..DS-49"
    ],
    "secondary": [
      "none used; no finding rests on session-log/runtime exhaust"
    ],
    "rule": "no finding rests on secondary evidence alone"
  },
  "operating_surfaces": [
    {
      "surface": "1 - Detector authoring pipeline (how new AS/DS ship)",
      "pass_a_known": "Add-first monoculture: 58 AS + ~24 DS signatures, adds AS-50..AS-59 + DS-49 landed in a short window (PRs #158-#208). The default operating move is to add a signature.",
      "pass_b_emerging": "Precision debt ships WITH each add: new detectors are merged then corrected for false positives soon after (AS-50 #160, AS-09/42 #175, AS-54/55 #179, AS-58 #201, AS-59 #208; L27/L29/L30). The add and the FP-fix are two PRs, not one.",
      "pass_c_verdict": "SIMPLIFY: require a new detector to ship with the recurring FP negative-fixture classes (archive/log surfaces, quoted-command flags, past-tense/transition wording) so the same FP class is not re-litigated per detector -> register R-A2."
    },
    {
      "surface": "2 - Detector graduation & retirement",
      "pass_a_known": "n=1 graduation stall: a wall of keep-candidate-at-n=1 verdicts (L23, L24, L27, L28, L29); the #199 n=2 hunt graduated NEITHER AS-58 nor DS-49. Graduation requires a confirmed true-positive fire across distinct repos, which rarely happens.",
      "pass_b_emerging": "There is NO retire/CUT path. docs/live-capability-inventory.md states it 'does not authorize deleting, archiving...'; 'graduation' exists only as prose in LEARNINGS. A keep-candidate that never graduates stays permanent inventory forever. The register only grows.",
      "pass_c_verdict": "SIMPLIFY (highest-return): a graduation-or-retire discipline where a keep-candidate with >=K non-graduating fleet runs becomes a retire-candidate -> register R-A1. This attacks the stall AND the inventory inflation at once."
    },
    {
      "surface": "3 - Inventory & gate coupling",
      "pass_a_known": "Documentation drift is 100% additions, 0% deletions (L7: DS-31 drift 55% from 20 undocumented scripts; AGENTS.md documented 14 while 34 existed). Docs grow stale fastest under active detector-add development.",
      "pass_b_emerging": "Every scripts/*.sh add forces a check.sh EXPECTED bump (currently 100; scripts/check.sh:45); the count-gate is a per-add friction tax that scales with the add-first monoculture rather than with real risk.",
      "pass_c_verdict": "CONDITIONAL/keep: the EXPECTED count-gate is cheap and git-observable (KEEP), but its per-add tax is a symptom of surface 2's inflation; fixing R-A1 relieves it. Do NOT add a heavier inventory mechanism."
    },
    {
      "surface": "4 - Evidence-class / family fit",
      "pass_a_known": "Detectors get shipped into the wrong evidence class: R3 re-work recurrence was scoped as an AS content-scan detector that would have silently no-opped because AS evaluators receive only a text snapshot, not git history (L28); it was rebuilt as DS-49.",
      "pass_b_emerging": "The add-first model creates structural recall blind spots: DS-49's subject-anchored finalize classifier is blind to GitHub-native closure (Refs #N / PR-merge suffix), so it under-recalls on GitHub-native-closure repos (L29). The blind spot was discovered only after the detector shipped.",
      "pass_c_verdict": "BOUNDED-HELPER: a tiny fail-loud preflight that a signature's family (AS content-scan vs DS git-history) matches the evidence class it reads, so a mis-placed detector fails loud instead of silently no-opping -> register R-A3. Explicitly not a controller."
    },
    {
      "surface": "5 - Closure & session-scoring model",
      "pass_a_known": "Closure-ceremony regrowth: session-local scorecards re-graded GitHub-native work as if local ceremony were still truth, needing an explicit bypass receipt (L19, Issue #22).",
      "pass_b_emerging": "External closure coupling: default close hard-depended on sibling-repo home-dir paths ($HOME/repos/repo-auditor) and emitted unknown PRE/POST/DELTA when scorecards were absent (L25, AS-56, issue #182) - the default close path grew a cross-repo dependency.",
      "pass_c_verdict": "CUT: keep the GitHub-native closeout bypass (already landed), and CUT residual default-close reliance on local scorecards / sibling-repo paths -> register R-A4 candidate scope. GitHub issue/PR/check/merge truth is closure truth."
    }
  ],
  "candidate_register": [
    {
      "id": "simplify:detector-graduation-or-retire-ledger",
      "verdict": "SIMPLIFY",
      "anti_pattern": "append-only detector inventory with an n=1 graduation stall and no retire path; the register only grows",
      "evidence": "primary anchor: LEARNINGS L23/L24/L27/L28/L29 (keep-candidate-at-n=1 wall) + PR #199 (n=2 hunt graduated neither) + docs/live-capability-inventory.md ('does not authorize deleting')",
      "owner_surface": "repo-auditor owner issue (to open when operator-selected); tracked under BMA #1282",
      "acceptance_sketch": "add a graduation-or-retire convention to the capability inventory + LEARNINGS: a keep-candidate with >=K non-graduating fleet runs becomes a retire-candidate. No new schema/registry/scheduler; a documented discipline over the existing inventory."
    },
    {
      "id": "simplify:shared-fp-negative-fixture-corpus",
      "verdict": "SIMPLIFY",
      "anti_pattern": "each new detector re-discovers the same false-positive classes (archive/log surfaces, quoted-command flags, past-tense wording) as a follow-up FP-fix PR",
      "evidence": "primary anchor: PRs #160/#175/#179/#201/#208 (FP/precision fixes trailing the add) + LEARNINGS L27/L29/L30 (AS-58 archive/log/clause-grain FP class)",
      "owner_surface": "repo-auditor owner issue (to open when operator-selected); tracked under BMA #1282",
      "acceptance_sketch": "converge the recurring FP negative fixtures into a shared corpus every new AS/DS detector must pass, so precision is proven at add-time rather than repaired after merge. SIMPLIFY of the existing per-detector test pattern."
    },
    {
      "id": "bounded-helper:evidence-class-family-preflight",
      "verdict": "BOUNDED-HELPER",
      "anti_pattern": "detectors shipped into the wrong evidence class (AS content-scan needing git history) silently no-op instead of failing loud",
      "evidence": "primary anchor: LEARNINGS L28 (R3 mis-scoped as AS, rebuilt as DS-49; AS evaluators receive only text snapshot)",
      "owner_surface": "repo-auditor owner issue (to open when operator-selected)",
      "acceptance_sketch": "a small fail-loud check that a signature's declared family matches the evidence it reads. Bounded helper only; explicitly not a controller/scheduler/registry."
    },
    {
      "id": "cut:default-close-local-scorecard-and-sibling-path-reliance",
      "verdict": "CUT",
      "anti_pattern": "default closeout regrows local-scorecard ceremony and sibling-repo home-dir path dependencies over GitHub-native closure truth",
      "evidence": "primary anchor: LEARNINGS L19 (closeout-regrowth bypass, Issue #22) + L25 (external closure coupling, AS-56, issue #182)",
      "owner_surface": "repo-auditor owner issue (to open when operator-selected)",
      "acceptance_sketch": "cut residual default-close reliance on local scorecards and $HOME/repos sibling paths where GitHub issue/PR/check/merge closure is explicit; keep the already-landed GitHub-native bypass. Deletion dominates; may add one fail-loud guard."
    },
    {
      "id": "new-surface:detector-effectiveness-dashboard",
      "verdict": "DO-NOT-BUILD",
      "anti_pattern": "runtime-only detector-analytics with no git-observable structural footprint",
      "evidence": "primary anchor: the graduation-or-retire ledger (R-A1) covers the need git-observably; a dashboard would be a heavy new surface the add-lightness rule rejects",
      "owner_surface": "none",
      "acceptance_sketch": "explicitly do not build; naming what not to build is the add-lightness move."
    },
    {
      "id": "conditional:github-native-closure-aware-rework-recall",
      "verdict": "CONDITIONAL",
      "anti_pattern": "DS-49 finalize classifier under-recalls on GitHub-native-closure repos",
      "evidence": "primary anchor: LEARNINGS L29 (documented recall boundary: subject-anchored finalize blind to Refs #N / PR-merge closure)",
      "owner_surface": "repo-auditor owner issue (only if a GitHub-native-closure repo needs the rework signal)",
      "acceptance_sketch": "extend the finalize classifier to GitHub-native closure anchors only if a real target needs it; otherwise the documented recall boundary stands."
    }
  ],
  "add_lightness_ranking": {
    "rule": "CUT/SIMPLIFY first, cheap git-observable ADD next, heavy new surface last; ties broken toward deletion",
    "is_preference_not_measurement": true,
    "order": [
      "simplify:detector-graduation-or-retire-ledger",
      "cut:default-close-local-scorecard-and-sibling-path-reliance",
      "simplify:shared-fp-negative-fixture-corpus",
      "bounded-helper:evidence-class-family-preflight",
      "conditional:github-native-closure-aware-rework-recall",
      "new-surface:detector-effectiveness-dashboard"
    ]
  },
  "outcome_proxy_rerank": {
    "proxy": "raw friction frequency (how often each pattern actually bit in git history / LEARNINGS)",
    "order": [
      "simplify:shared-fp-negative-fixture-corpus",
      "simplify:detector-graduation-or-retire-ledger",
      "cut:default-close-local-scorecard-and-sibling-path-reliance",
      "bounded-helper:evidence-class-family-preflight",
      "conditional:github-native-closure-aware-rework-recall",
      "new-surface:detector-effectiveness-dashboard"
    ],
    "disagrees_with_add_lightness_ranking": true,
    "can_refute_thesis": true,
    "survives_both_orderings": "Both orderings put 'add more detectors' (the thesis move) and the heavy dashboard LAST. The two orderings disagree at the top (friction frequency ranks FP-rework #1 because it bit ~6 times: #160/#175/#179/#201/#208 + L27/L29/L30; add-lightness ranks the graduation-or-retire SIMPLIFY #1 because it is the widest cut). The single conclusion that survives both is: adding more detectors is NOT the highest-return move, and no heavy new surface is warranted."
  },
  "thesis_verdict": {
    "verdict": "partially_refuted",
    "decisive_primary_anchor": "PR #199 (n=2 graduation hunt graduated neither AS-58 nor DS-49) + the FP-fix PR chain #160/#175/#179/#201/#208 + LEARNINGS L7 ('drift is 100% additions, 0% deletions'): the biting friction is precision-rework and a graduation stall, not a shortage of detectors. Adding more detectors would deepen both."
  },
  "cut_simplify_add_tally": {
    "CUT": 1,
    "SIMPLIFY": 2,
    "ADD": 0,
    "BOUNDED-HELPER": 1,
    "DO-NOT-BUILD": 1,
    "CONDITIONAL": 1
  },
  "owner_surface": "BMA maintained lane #1282 (register hand-back tracking); per-repo owner issues open in repo-auditor only when operator-selected",
  "bounded_non_claims": [
    "does not turn its add-lightness ranking into a measured return; it is a preference cross-checked by a raw friction-frequency proxy",
    "does not rest any verdict on secondary session-log or runtime evidence alone; no secondary evidence was used",
    "does not implement detectors, open new issues, or mutate sibling repos; the candidate register is an advisory hand-back",
    "does not authorize background sync/watch, cron, autopilot, jobs worker, MCP serving, queues, daemons, schedulers, hidden registries, generated inventories, automatic updates, automatic issue/PR creation, or downstream mutation",
    "does not create a controller, scheduler, queue, registry, daemon, retry loop, hidden control plane, or retained proof ritual",
    "n=1: this is one off-BMA run proving the method generalizes, not a fleet-wide measurement"
  ]
}
```

## Operating surfaces x passes grid

Pass A = known anti-pattern still exhibited · Pass B = emerging/unnamed ·
Pass C = detection/add-lightness verdict.

| Surface | A (known) | B (emerging) | C (verdict -> register id) |
|---|---|---|---|
| 1 - Detector authoring pipeline | Add-first monoculture (58 AS + ~24 DS; AS-50..AS-59, DS-49) | Precision debt ships with each add (FP-fix trails the add: #160/#175/#179/#201/#208) | SIMPLIFY -> `simplify:shared-fp-negative-fixture-corpus` |
| 2 - Detector graduation & retirement | n=1 graduation stall (L23/L24/L27/L28/L29; #199 graduated neither) | No retire/CUT path; inventory is append-only ("does not authorize deleting") | SIMPLIFY -> `simplify:detector-graduation-or-retire-ledger` |
| 3 - Inventory & gate coupling | Doc drift 100% additions / 0% deletions (L7) | EXPECTED count-gate is a per-add friction tax (check.sh:45) | CONDITIONAL/keep gate; relieved by R-A1 |
| 4 - Evidence-class / family fit | Detector shipped to wrong evidence class silently no-ops (L28) | Add-first creates structural recall blind spots (DS-49 vs GitHub-native closure, L29) | BOUNDED-HELPER -> `bounded-helper:evidence-class-family-preflight` |
| 5 - Closure & session-scoring | Closure-ceremony regrowth needs bypass receipt (L19) | External closure coupling to sibling-repo home paths (L25/AS-56) | CUT -> `cut:default-close-local-scorecard-and-sibling-path-reliance` |

## Candidate-detector register (ranked by add-lightness, handed back UNBUILT)

| Rank | ID | Verdict | Anti-pattern | Evidence (primary anchor) | Owner surface | Acceptance sketch |
|---|---|---|---|---|---|---|
| 1 | simplify:detector-graduation-or-retire-ledger | SIMPLIFY | Append-only inventory + n=1 stall, no retire path | L23/L24/L27/L28/L29 + #199 + live-capability-inventory.md | repo-auditor issue (operator-selected); BMA #1282 | Graduation-or-retire convention over existing inventory; no new schema/registry |
| 2 | cut:default-close-local-scorecard-and-sibling-path-reliance | CUT | Default close regrows local ceremony + sibling-repo path deps | L19 (#22) + L25 (AS-56 #182) | repo-auditor issue (operator-selected) | Cut residual local-scorecard/$HOME-path reliance; keep GitHub-native bypass |
| 3 | simplify:shared-fp-negative-fixture-corpus | SIMPLIFY | Each detector re-discovers the same FP classes as a follow-up PR | #160/#175/#179/#201/#208 + L27/L29/L30 | repo-auditor issue (operator-selected) | Shared FP negative-fixture corpus new detectors must pass at add-time |
| 4 | bounded-helper:evidence-class-family-preflight | BOUNDED-HELPER | Mis-placed detector silently no-ops | L28 (R3 mis-scoped as AS -> DS-49) | repo-auditor issue (operator-selected) | Fail-loud family-vs-evidence preflight; not a controller |
| 5 | conditional:github-native-closure-aware-rework-recall | CONDITIONAL | DS-49 under-recalls on GitHub-native-closure repos | L29 (documented recall boundary) | repo-auditor issue (only if a target needs it) | Extend finalize classifier only on demand |
| 6 | new-surface:detector-effectiveness-dashboard | DO-NOT-BUILD | Runtime-only analytics, no git-observable footprint | R-A1 covers the need git-observably | none | Explicitly do not build |

## Falsifiability re-rank block

- **Add-lightness ranking (preference):** graduation-or-retire SIMPLIFY -> default-close CUT -> shared-FP-corpus SIMPLIFY -> family preflight BOUNDED-HELPER -> recall CONDITIONAL -> dashboard DO-NOT-BUILD.
- **Independent outcome-proxy re-rank (friction frequency):** shared-FP-corpus (bit ~6x) -> graduation-or-retire (bit ~5x) -> default-close (bit ~2x) -> family preflight (bit ~2x) -> recall CONDITIONAL (1x) -> dashboard (0x).
- **Do the two orderings disagree?** Yes — at the top. Friction frequency ranks the FP-rework fix #1 (it bit most often: #160/#175/#179/#201/#208 + L27/L29/L30); the add-lightness rule ranks the graduation-or-retire SIMPLIFY #1 (widest cut, attacks two surfaces). This disagreement is what keeps the thesis falsifiable — a preference ranking alone could self-justify.
- **What survives both orderings:** Adding more detectors is NOT the highest-return next move, and no heavy new surface (the dashboard) is warranted. That rejection is the only non-preference-driven conclusion, and it partially refutes the thesis.

## CUT/SIMPLIFY/ADD tally

| Verdict | Count |
|---|---|
| CUT | 1 |
| SIMPLIFY | 2 |
| ADD | 0 |
| BOUNDED-HELPER | 1 |
| DO-NOT-BUILD | 1 |
| CONDITIONAL | 1 |

## What this n=1 dogfood found (3-line summary)

1. **Thesis PARTIALLY REFUTED.** repo-auditor's biting operating friction is not a
   shortage of detectors but **precision-rework** on freshly-added detectors and an
   **n=1 graduation stall with no retire path** — adding more detectors deepens both.
2. **Highest-return next move is CUT/SIMPLIFY** (tally: 1 CUT · 2 SIMPLIFY · 0 ADD ·
   1 bounded-helper · 1 do-not-build · 1 conditional), led by a **graduation-or-retire
   ledger discipline** that makes the append-only detector inventory prunable.
3. The method **generalizes off BMA**: run against repo-auditor's own git/LEARNINGS/gate
   evidence with zero secondary-evidence dependence, it reproduced the same
   add-lightness / falsifiable-thesis shape BMA's own retrospective found — closing F3
   with a real dogfood, not a doc claim.

## Provenance & bounded non-claims

- Advisory hand-back only. No detector implemented, no issue opened, no sibling repo
  mutated by this retrospective; the only mutation is this report.
- All findings rest on primary canonical evidence (git history, LEARNINGS, AGENTS/docs,
  check.sh, GitHub PR/issue state). No finding rests on secondary session-log/runtime
  evidence.
- n=1: one off-BMA run proving genericity, not a fleet-wide measurement. Register rows
  are candidates for operator-selected owner-surface batches in repo-auditor, tracked
  under BMA lane #1282; each lands (if selected) through repo-auditor's own
  issue -> PR -> required checks -> merge.
- No controller, scheduler, queue, daemon, registry, cron, dashboard, or background
  process is proposed or created.
