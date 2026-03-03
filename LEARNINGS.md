# LEARNINGS — repo-auditor

| # | Learning | Source |
|---|---|---|
| L1 | Tool-level determinism observation (pre-scan bash > LLM for file discovery) was over-generalized to repo-level constitutional prohibition, structurally preventing self-improvement infrastructure | spec 052 RCA, L271 |
| L2 | Every repo-agent needs a build spec. repo-upgrade-advisor had 5-version iterative spec with competitive planning and 17 quality test runs. repo-auditor had zero. | spec 052 RCA, L272 |
| L3 | Session grader scripts grow 3x planned size because evidence collection + JSON output + edge cases dominate. Plan ~100 lines, deliver ~300. Account for this in future estimates. | spec 052 Phase A review, score-session.sh 308 vs ~100 plan |
| L4 | Pre-commit hooks installed to .git/hooks/ are NOT updated when scripts/pre-commit-hook.sh changes. Must re-run make install-hooks after every hook edit. | spec 052 Phase A, stale hook blocked commit |
| L5 | Competitive 2-model planning works: Opus focused on architecture/risks, Sonnet on minimal path. Synthesis produced better plan than either alone (4-dim grader vs A's 5 or B's 3). | spec 052 competitive planning, v90 |
| L6 | Agent scoring divergence (10 vs 59/100) caused by path convention mismatch: agent dispatched tools individually to flat output dir, but score-audit-dimensions.sh expects nested pre-scan/ subdir created by repo-auditor.sh. Fix: agent must call repo-auditor.sh directly (single command) to preserve directory structure, not dispatch individual tools. | spec 052 Phase B smoke test, T10 |
| L7 | Fleet-generated spec cycle proof: DS-31 drift (55% > 30%) caused by 20 undocumented scripts added during Stage 9 (DS-34 through DS-43 detection signatures + helpers). AGENTS.md documented 14 scripts but 34 existed. Fix: restructured Scripts section into 4 subsections (Core, Detection, Helpers, Gates) with DS traceability column. Drift is 100% additions, 0% deletions. Documents grow stale fastest on repos under active development. | v142: fleet audit on repo-auditor, generate-fleet-spec.sh DS-31, spec 072 dispatched, AGENTS.md 14->34 scripts documented. Drift: 55%->expected <20%. |
