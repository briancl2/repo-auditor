#!/bin/bash
# pre-commit hook — Run `make check` before allowing commits
#
# Install: ln -sf ../../scripts/pre-commit-hook.sh .git/hooks/pre-commit
#
# Runs shellcheck + inventory + trailer validation on every commit.
# IMPORTANT: --no-verify is NEVER permitted (L102, Principle 12).

set -euo pipefail

# Nothing staged — skip
if git diff --staged --quiet 2>/dev/null; then
  exit 0
fi

echo "=== Pre-commit: Running make check ==="
if make check; then
  echo "=== Check passed ==="
  exit 0
else
  echo ""
  echo "╔══════════════════════════════════════════════════════════╗"
  echo "║  COMMIT BLOCKED — make check failed                     ║"
  echo "╚══════════════════════════════════════════════════════════╝"
  echo ""
  exit 1
fi
