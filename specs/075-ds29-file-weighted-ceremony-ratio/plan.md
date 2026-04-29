# Plan

1. Add file-level delivery/ceremony classification helpers to
   `scripts/detect-ceremony-ratio.sh`.
2. Preserve the existing commit-level counters and JSON keys.
3. Add mode selection for `commit`, `file`, and `combined`, defaulting to
   `combined`.
4. Add deterministic shell fixtures that create temporary Git repositories for
   BMA-shaped positive, near-miss, and healthy negative cases.
5. Run focused DS-29 tests, `make check`, and `make test`.
