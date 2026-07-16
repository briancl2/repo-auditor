---
description: Preserve the ratified shared constitution and its non-divergent Spec Kit pointer.
handoffs: 
  - label: Build Specification
    agent: speckit.specify
    prompt: Implement the feature specification under the ratified shared constitution. I want to build...
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Shared Constitution Guard

1. Read root `CONSTITUTION.md`, `AGENTS.md`, and
   `.specify/memory/constitution.md`.
2. Treat root `CONSTITUTION.md` as exact ratified authority. This agent MUST NOT
   edit, overwrite, reformat, regenerate, version, or amend it.
3. Keep `.specify/memory/constitution.md` as a concise pointer. This agent MUST
   NOT replace it with doctrine or create another constitution, universal or
   core-principle authority, compliance score, or checklist.
4. If the request would change shared constitutional meaning, make no mutation.
   Explain that explicit operator ratification of exact, hash-identified bytes
   is required on the owning shared-constitution surface, then stop.
5. Route stricter repo-local policy requests to the ordinary owner-local
   workflow and an existing subordinate policy surface such as `AGENTS.md`.
   Do not use this command to implement them. Repo-local policy may not weaken
   the shared floor; unresolved conflicts stop for explicit resolution.

Report whether the request was stopped or routed. Do not emit a version bump or
sync-impact report for the pointer.
