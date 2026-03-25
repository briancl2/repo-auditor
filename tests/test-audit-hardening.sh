#!/usr/bin/env bash
# test-audit-hardening.sh — Validate context manifest + scorer receipts hardening.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

create_fixture_repo() {
    local repo_path="$1"
    local include_local_artifacts="$2"

    mkdir -p "$repo_path/.github/agents" "$repo_path/.agents/skills/sample" \
        "$repo_path/.github/workflows" "$repo_path/specs/001-sample" \
        "$repo_path/scripts" "$repo_path/tests"

    cat > "$repo_path/AGENTS.md" <<'EOF'
# Fixture Agents
EOF
    cat > "$repo_path/LEARNINGS.md" <<'EOF'
# Fixture Learnings
EOF
    cat > "$repo_path/HYPOTHESES.md" <<'EOF'
# Fixture Hypotheses
EOF
    cat > "$repo_path/.github/agents/sample.agent.md" <<'EOF'
# sample agent
EOF
    cat > "$repo_path/.agents/skills/sample/SKILL.md" <<'EOF'
# sample skill
EOF
    cat > "$repo_path/.github/workflows/ci.yml" <<'EOF'
name: ci
on: [push]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - run: echo ok
EOF
    cat > "$repo_path/specs/001-sample/spec.md" <<'EOF'
# sample spec
EOF
    cat > "$repo_path/scripts/score-demo.sh" <<'EOF'
#!/usr/bin/env bash
echo score
EOF
    chmod +x "$repo_path/scripts/score-demo.sh"
    cat > "$repo_path/tests/test-demo.sh" <<'EOF'
#!/usr/bin/env bash
echo test
EOF
    chmod +x "$repo_path/tests/test-demo.sh"
    mkdir -p "$repo_path/deep/a/b/c/d/e/f"
    cat > "$repo_path/deep/a/b/c/d/e/f/retained.txt" <<'EOF'
deep retained file
EOF

    (
        cd "$repo_path"
        git init -q
        git config user.name fixture
        git config user.email fixture@example.com
        git add .
        git commit -qm "fixture"
    )

    if [ "$include_local_artifacts" = "yes" ]; then
        mkdir -p "$repo_path/work/session-1" "$repo_path/runs/cycle-1"
        cat > "$repo_path/work/session-1/receipt.txt" <<'EOF'
local work artifact
EOF
        cat > "$repo_path/runs/cycle-1/output.txt" <<'EOF'
local run artifact
EOF
    fi
}

copy_without_git() {
    local source_repo="$1"
    local dest_repo="$2"
    local entry

    mkdir -p "$dest_repo"
    for entry in "$source_repo"/* "$source_repo"/.[!.]* "$source_repo"/..?*; do
        [ -e "$entry" ] || continue
        if [ "$(basename "$entry")" = ".git" ]; then
            continue
        fi
        cp -R "$entry" "$dest_repo/"
    done
}

echo "=== Auditor Hardening Validation ==="

PORTABLE_FIXTURE="$TMP_ROOT/portable-fixture"
LIVE_FIXTURE="$TMP_ROOT/live-fixture"
PARENT_GIT="$TMP_ROOT/parent-git"
BORROWED_FIXTURE="$PARENT_GIT/copied-snapshot"

create_fixture_repo "$PORTABLE_FIXTURE" "no"
create_fixture_repo "$LIVE_FIXTURE" "yes"

mkdir -p "$PARENT_GIT"
(
    cd "$PARENT_GIT"
    git init -q
    git config user.name parent
    git config user.email parent@example.com
    echo parent > README.md
    git add README.md
    git commit -qm "parent"
)
copy_without_git "$PORTABLE_FIXTURE" "$BORROWED_FIXTURE"
(
    cd "$PARENT_GIT"
    git add copied-snapshot
    git commit -qm "copied snapshot"
)

PORTABLE_OUTPUT="$TMP_ROOT/portable-output"
LIVE_OUTPUT="$TMP_ROOT/live-output"
BORROWED_OUTPUT="$TMP_ROOT/borrowed-output"

mkdir -p "$LIVE_OUTPUT"
python3 "$REPO_ROOT/scripts/write_context_score_manifest.py" \
    "$LIVE_FIXTURE" "$LIVE_OUTPUT/CONTEXT_SCORE_MANIFEST.json" \
    --context-id live_root

python3 - "$LIVE_OUTPUT" <<'PY'
import json
import pathlib
import sys

out = pathlib.Path(sys.argv[1])
manifest = json.load(open(out / "CONTEXT_SCORE_MANIFEST.json"))

assert manifest["audit_context_id"] == "live_root"
assert manifest["portable_authority"]["ready"] is False
assert "counted_local_artifact_inflation_possible" in manifest["portable_authority"]["risks"]
assert manifest["local_artifact_counts"]["work"]["files"] >= 1
assert manifest["local_artifact_counts"]["runs"]["files"] >= 1
assert manifest["local_artifact_counts"]["counted_local_only_files_total"] >= 2
PY
echo "  ✓ dirty live-root local artifacts are retained as a manifest risk"

if bash "$REPO_ROOT/scripts/repo-auditor.sh" "$LIVE_FIXTURE" "$TMP_ROOT/live-fail-output" \
    --context-id live_root --require-portable-context > /dev/null 2>&1; then
    echo "  ✗ require-portable-context should fail on dirty live-root local artifacts"
    exit 1
fi
echo "  ✓ require-portable-context fails closed on dirty live-root local artifacts"

bash "$REPO_ROOT/scripts/repo-auditor.sh" "$BORROWED_FIXTURE" "$BORROWED_OUTPUT" \
    --context-id copied_snapshot

python3 - "$BORROWED_OUTPUT" <<'PY'
import json
import pathlib
import sys

out = pathlib.Path(sys.argv[1])
manifest = json.load(open(out / "CONTEXT_SCORE_MANIFEST.json"))
scorecard = json.load(open(out / "SCORECARD.json"))
receipts = json.load(open(out / "SCORECARD_RECEIPTS.json"))

assert manifest["audit_context_id"] == "copied_snapshot"
assert manifest["git"]["borrowed_parent_git_root"] is True
assert manifest["portable_authority"]["ready"] is False
assert "borrowed_parent_git_root" in manifest["portable_authority"]["risks"]
assert "spec_bonus" in receipts["dimensions"]["D5_self_improvement"]["fields"]
assert scorecard["dimensions"]["D5_self_improvement"]["components"]["spec_bonus"] == 1
assert scorecard["meta"]["context_manifest"] == "CONTEXT_SCORE_MANIFEST.json"
assert scorecard["receipts"]["file"] == "SCORECARD_RECEIPTS.json"
assert scorecard["receipts"]["count_reconciliation_status"] == "aligned"
assert receipts["count_reconciliation"]["status"] == "aligned"
assert receipts["count_reconciliation"]["authoritative_total_files"] == receipts["count_reconciliation"]["pre_scan_total_files"]
assert receipts["count_reconciliation"]["authoritative_total_files"] == receipts["count_reconciliation"]["maturity_total_files"]
assert receipts["count_reconciliation"]["authoritative_total_files"] == receipts["count_reconciliation"]["dna_total_files"]
PY
echo "  ✓ borrowed parent git root is rejected as portable authority with visible receipts"

if bash "$REPO_ROOT/scripts/repo-auditor.sh" "$BORROWED_FIXTURE" "$TMP_ROOT/borrowed-fail-output" \
    --context-id copied_snapshot --require-portable-context > /dev/null 2>&1; then
    echo "  ✗ require-portable-context should fail on borrowed parent git root"
    exit 1
fi
echo "  ✓ require-portable-context fails closed on borrowed parent git root"

echo "  VERDICT: PASS"
