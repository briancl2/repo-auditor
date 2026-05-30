# Core-Five Owner-Surface Contract

> Copy-synced from repo-agent-core `docs/core-five-owner-surface-contract.md`
> for Issue #164 detector guidance. This is documentation, not a runtime
> dependency or background sync.

## Purpose

The core five are reciprocal proving grounds:

- build-meta-analysis
- repo-agent-core
- repo-auditor
- repo-upgrade-advisor
- repo-optimizer

Any core-five repo may be used as a read-only validation target by another
core-five repo. Mutation is allowed only when that repo is the named owner
surface and the work lands through its own issue, branch, PR, checks, and merge.

## Capability Homes

| Capability family | Owner surface | First deliverable shape |
|---|---|---|
| Outer-loop campaign console | build-meta-analysis | Issue #164 child issue and GitHub-native PR |
| Shared repo-agent contracts | repo-agent-core | Copy-synced contract, schema, template, or hook with repo-native tests |
| Audit and signature detection | repo-auditor | Detector signature, fixture, registration, and repo-native test |
| Recommendation packaging | repo-upgrade-advisor | Recommendation template, scorer rule, prompt/schema update, and packaging fixture |
| Patch-pack materialization | repo-optimizer | Deterministic patch materializer plus `git apply --check` fixture |

## Detector Consumption

AS-23 treats this document as grounded owner-surface guidance because it names
owner surfaces and first deliverable shapes. AS-24 treats this document as
grounded reciprocal proving-ground guidance because it states the read-only
target rule and owner-repo mutation boundary.

Do not convert this copy into an import, generated registry, scheduler, queue,
controller, daemon, or background sync.
