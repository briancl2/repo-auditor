# Implementation Plan: Fix stale documentation and content drift

**Spec:** 072-fix-stale-documentation-and-content-drif | **Date:** 2026-03-03 | **Layer:** system

## Summary

Fix DS-31 (Fix stale documentation and content drift) by following the standard spec-kit approach for fix-broken issues in the system layer.

## Approach

1. Audit documentation references against filesystem
2. Fix broken links and stale references
3. Update capability documentation
4. Verify drift <=20%

## Verification

```bash
make check
```

```bash
# Re-run DS detection to verify fix
```

