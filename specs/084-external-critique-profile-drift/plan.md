# Implementation Plan: External Critique Profile Drift

1. Add AS-08 constants and helpers for live mechanism-path filtering and
   configured slot extraction.
2. Add profile evidence classes and signals without changing AS-08's existing
   health semantics.
3. Extend the focused shell fixture suite with the required positive and
   negative cases.
4. Run focused, repository, and read-only real-tree precision gates; retain raw
   target outputs outside target repositories.
5. Close the native work contract and land through issue/PR/check/merge truth.
