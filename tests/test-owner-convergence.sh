#!/usr/bin/env bash
# Focused cached-index, deletion-map, core-identity, and privacy tests.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VALIDATOR="$ROOT/scripts/validate_owner_convergence.py"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/repo-auditor-owner-convergence.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

PASS=0
FAIL=0

pass() {
    PASS=$((PASS + 1))
    echo "  PASS: $1"
}

fail() {
    FAIL=$((FAIL + 1))
    echo "  FAIL: $1"
}

if python3 "$VALIDATOR" \
    --repo "$ROOT" \
    --base-ref e8b42763eb3e323d0e0238e84fe81c4c87898627 \
    --core-ref 9da7b41b83a10b9fd71ad24b0529a50425a8d373 \
    > "$TMP_ROOT/actual.json"
then
    pass "actual cached candidate passes"
else
    fail "actual cached candidate passes"
fi

CI_BASE_COUNT=$(
    git -C "$ROOT" show :.github/workflows/ci.yml \
        | grep -c 'e8b42763eb3e323d0e0238e84fe81c4c87898627' \
        || true
)
if [ "$CI_BASE_COUNT" -eq 2 ]; then
    pass "CI PR-base invariant is pinned to settled main"
else
    fail "CI PR-base invariant is pinned to settled main"
fi

for expected in \
    '"deleted_paths": 4' \
    '"rollback_paths": 4' \
    '"changed_retained_paths": 17' \
    '"new_paths": 2' \
    '"core_export_rows": 6' \
    '"core_caller_checks": 6' \
    '"orphan_active_exports": 0' \
    '"unclassified_index_paths": 0'
do
    if grep -Fq "$expected" "$TMP_ROOT/actual.json"; then
        pass "actual receipt contains $expected"
    else
        fail "actual receipt contains $expected"
    fi
done

FIXTURE="$TMP_ROOT/index-fixture"
mkdir -p "$FIXTURE"
git -C "$FIXTURE" init -q
git -C "$FIXTURE" config user.email "owner-convergence@example.invalid"
git -C "$FIXTURE" config user.name "Owner Convergence Test"
printf '%s\n' \
    '# Bootloader' \
    '.agents/skills/repo-auditor-owner-settlement/SKILL.md' \
    > "$FIXTURE/AGENTS.md"
printf '%s\n' \
    '# Entrypoint' \
    '.agents/skills/repo-auditor-owner-settlement/SKILL.md' \
    > "$FIXTURE/README.md"
git -C "$FIXTURE" add AGENTS.md README.md
git -C "$FIXTURE" commit -qm "clean authority fixture"

PYTHONPATH="$ROOT/scripts" python3 - "$FIXTURE" <<'PY'
import sys
from pathlib import Path

from validate_owner_convergence import (
    ConvergenceError,
    index_entries,
    validate_active_authority,
)

repo = Path(sys.argv[1])
validate_active_authority(repo, index_entries(repo))

(repo / "AGENTS.md").write_text(
    "# Bootloader\n"
    ".agents/skills/repo-auditor-owner-settlement/SKILL.md\n"
    "make work\n",
    encoding="utf-8",
)
validate_active_authority(repo, index_entries(repo))
PY
if [ "$?" -eq 0 ]; then
    pass "unstaged bad authority cannot override clean cached index"
else
    fail "unstaged bad authority cannot override clean cached index"
fi

git -C "$FIXTURE" add AGENTS.md
if PYTHONPATH="$ROOT/scripts" python3 - "$FIXTURE" 2>/dev/null <<'PY'
import sys
from pathlib import Path

from validate_owner_convergence import index_entries, validate_active_authority

repo = Path(sys.argv[1])
validate_active_authority(repo, index_entries(repo))
PY
then
    fail "staged retired authority fails closed"
else
    pass "staged retired authority fails closed"
fi

git -C "$FIXTURE" restore --source=HEAD --staged --worktree AGENTS.md README.md
printf '\377\n' > "$FIXTURE/README.md"
git -C "$FIXTURE" add README.md
if PYTHONPATH="$ROOT/scripts" python3 - "$FIXTURE" 2>/dev/null <<'PY'
import sys
from pathlib import Path

from validate_owner_convergence import index_entries, validate_active_authority

repo = Path(sys.argv[1])
validate_active_authority(repo, index_entries(repo))
PY
then
    fail "staged non-UTF-8 authority fails closed"
else
    pass "staged non-UTF-8 authority fails closed"
fi

INSTALLED="$TMP_ROOT/installed"
mkdir -p \
    "$INSTALLED/.agents/skills/private-skill" \
    "$INSTALLED/.github/agents" \
    "$INSTALLED/.github/instructions" \
    "$INSTALLED/.github/prompts"
printf '%s\n' private > "$INSTALLED/.agents/skills/private-skill/SKILL.md"
printf '%s\n' private > "$INSTALLED/.github/agents/private.agent.md"
printf '%s\n' private > "$INSTALLED/.github/instructions/private.instructions.md"
printf '%s\n' private > "$INSTALLED/.github/prompts/private.prompt.md"
PYTHONPATH="$ROOT/scripts" python3 - "$INSTALLED" > "$TMP_ROOT/installed.json" <<'PY'
import json
import sys
from pathlib import Path

from validate_owner_convergence import installed_counts

print(json.dumps(installed_counts(Path(sys.argv[1]), set()), sort_keys=True))
PY
if grep -Fq "private" "$TMP_ROOT/installed.json"; then
    fail "installed discovery exposes no private names"
else
    pass "installed discovery exposes no private names"
fi
for expected in \
    '"skills": 1' \
    '"custom_agents": 1' \
    '"instructions": 1' \
    '"prompts": 1'
do
    if grep -Fq "$expected" "$TMP_ROOT/installed.json"; then
        pass "installed count receipt contains $expected"
    else
        fail "installed count receipt contains $expected"
    fi
done

CORE_REPO="${CORE_REPO:-/Users/briancl/repos/repo-agent-core}"
if [ -d "$CORE_REPO" ] && git -C "$CORE_REPO" cat-file -e \
    9da7b41b83a10b9fd71ad24b0529a50425a8d373^{commit} 2>/dev/null
then
    if python3 "$VALIDATOR" \
        --repo "$ROOT" \
        --base-ref e8b42763eb3e323d0e0238e84fe81c4c87898627 \
        --core-ref 9da7b41b83a10b9fd71ad24b0529a50425a8d373 \
        --core-repo "$CORE_REPO" \
        > "$TMP_ROOT/core-live.json"
    then
        pass "exact core tree and auditor caller evidence pass"
    else
        fail "exact core tree and auditor caller evidence pass"
    fi
    if grep -Fq '"core_live_baseline_checks": 13' "$TMP_ROOT/core-live.json"; then
        pass "core live receipt contains 13 exact checks"
    else
        fail "core live receipt contains 13 exact checks"
    fi
fi

echo ""
echo "=== test-owner-convergence.sh: $PASS pass, $FAIL fail ==="
[ "$FAIL" -eq 0 ] || exit 1
