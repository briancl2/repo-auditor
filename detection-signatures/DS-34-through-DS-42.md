# Detection Signatures — DS-34 through DS-42

> Stage 9 Phase 1 detection signatures.
> Each signature identifies a specific code health, process, or maintenance gap.
> Source: L-to-DS conversion ledger Priority A candidates + Stage 6-8 retrospective findings.
> Spec: 067-detection-signatures-ds34-42

---

## Track A: Grep-Only (Pure Text Search)

### DS-34: Stale TODO/FIXME
- **Detects:** >10 TODO/FIXME markers in source files
- **Signal:** Accumulated technical debt markers without resolution tracking
- **Phase range:** Any (universal stale indicator)
- **Check:** `grep -rn 'TODO|FIXME' --include='*.sh' --include='*.py' --include='*.js' --include='*.md' | wc -l`
- **Fire condition:** count > 10
- **Prevention tier:** T3 (advisory — tracked in recommendation)
- **Severity:** LOW
- **Source:** Common software hygiene. Pre-flywheel patterns.

### DS-38: Config Format Proliferation
- **Detects:** >2 distinct config file formats in the same repo
- **Signal:** Mixed configuration approaches increase cognitive load and tooling requirements
- **Phase range:** Phase 2+ (after repo has multiple config files)
- **Check:** Count distinct formats among .json, .yaml/.yml, .toml, .env, .ini, .cfg, .conf
- **Fire condition:** formats_found > 2
- **Prevention tier:** T3 (advisory)
- **Severity:** LOW
- **Source:** Config standardization Best practice.

### DS-40: Commit Message Entropy
- **Detects:** No structured commit convention in repo
- **Signal:** Unstructured commit history impedes automated changelog, bisect, and blame analysis
- **Phase range:** Phase 2+ (after repo has active development)
- **Check with git:** Analyze last 50 commits for conventional format, trailers, issue refs. Fire if all <10%.
- **Check without git:** Look for convention config (.commitlintrc, hooks, CONTRIBUTING docs, Spec-ID trailers in .md files)
- **Fire condition:** No convention evidence found
- **Prevention tier:** T3 (advisory)
- **Severity:** LOW
- **Source:** L235 (--no-verify rate), L292 (trailer format).

---

## Track B: Language-Aware (File/Import Resolution)

### DS-35: Unused Dependencies
- **Detects:** Dependency manifest entries not imported in source code
- **Signal:** Dependency bloat increases attack surface, build time, and confusion
- **Phase range:** Phase 2+ (requires dependency manifest)
- **Check:** Parse requirements.txt or package.json. For each dep, grep for import/require in source.
- **Fire condition:** Any unused dep found
- **Prevention tier:** T2 (skill — auto-prune unused deps)
- **Severity:** MEDIUM
- **Manifests supported:** requirements.txt (Python), package.json (Node.js)
- **Source:** L303 (shallow validation). General best practice.

### DS-37: README Capability Drift
- **Detects:** README.md references files, scripts, or Makefile targets that don't exist
- **Signal:** Documentation promises features/commands the repo can't deliver
- **Phase range:** Phase 2+
- **Check:** Extract `make <target>` refs, script path refs, file path refs from README. Verify each exists.
- **Fire condition:** >=2 broken claims AND >=20% broken
- **Prevention tier:** T3 (advisory)
- **Severity:** MEDIUM
- **Source:** DS-31 content staleness extension. L312 (instruction surface drift).

### DS-41: Test Theater
- **Detects:** Test files exist but no test runner configured
- **Signal:** Tests present but never executed — automation theater (DS-21 variant)
- **Phase range:** Phase 2+
- **Check:** Find test files in tests/, test/, spec/. Check CI workflows and Makefile for test runner commands.
- **Fire condition:** has_tests AND NOT has_runner_ci AND NOT has_runner_make
- **Prevention tier:** T2 (CI fix skill — add test runner to CI)
- **Severity:** HIGH
- **Source:** L303 (shallow validation), DS-21 S2 variant.

---

## Track C: Cross-File Analysis

### DS-36: Green-Only CI
- **Detects:** CI configuration with no failure handling or test commands
- **Signal:** CI may be cosmetic if it has never been designed to fail
- **Phase range:** Phase 3+ (requires CI config)
- **Check:** Scan CI workflow files for failure() handlers, retry logic, test commands
- **Fire condition:** has_ci AND failure_handling == 0 AND test_commands == 0 (or just failure_handling == 0)
- **Prevention tier:** T3 (advisory)
- **Severity:** MEDIUM
- **Source:** L29 (confirmatory critic), L298 (impossible success criteria).

### DS-39: Silent Error Handling
- **Detects:** Error suppression patterns in non-test source files
- **Signal:** Errors silently ignored on critical paths hide failures
- **Phase range:** Any
- **Patterns:** `catch {}`, `except: pass`, `|| true`, `|| :`, `2>/dev/null`, `rescue => nil`
- **Check:** Grep for patterns in source files (excluding test dirs)
- **Fire condition:** count > 5 suppression patterns
- **Prevention tier:** T3 (advisory)
- **Severity:** MEDIUM
- **Source:** General robustness. High counts indicate systemic error suppression.

### DS-42: Broken Internal Links
- **Detects:** Markdown files with links to non-existent files
- **Signal:** Documentation link rot — readers follow dead links
- **Phase range:** Any
- **Check:** Extract `[text](path)` links from .md files. Resolve relative and repo-root paths. Check existence.
- **Fire condition:** broken_count > 0
- **Prevention tier:** T1 (make check integration — can be deterministically enforced)
- **Severity:** HIGH
- **Performance:** Caps at 200 markdown files per repo for speed
- **Source:** L35 (dead script references), DS-31 content staleness.
