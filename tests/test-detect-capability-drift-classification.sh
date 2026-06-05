#!/usr/bin/env bash
# test-detect-capability-drift-classification.sh — classified live/non-live drift scope.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

FIXTURE="$TMP_ROOT/capability-drift-classification"
mkdir -p \
  "$FIXTURE/scripts" \
  "$FIXTURE/scripts/archive" \
  "$FIXTURE/work/20260605T000000Z/.target-snapshot/scripts" \
  "$FIXTURE/runs/20260605T000000Z/tools" \
  "$FIXTURE/research/evidence/package/scripts" \
  "$FIXTURE/targets/example/scripts" \
  "$FIXTURE/audit-output.clean-head-snapshot/scripts" \
  "$FIXTURE/tests/fixtures/demo/scripts" \
  "$FIXTURE/examples/tools" \
  "$FIXTURE/node_modules/pkg/scripts" \
  "$FIXTURE/build/tools"

cat > "$FIXTURE/AGENTS.md" <<'EOF'
# AGENTS

- Live tool: scripts/live.sh
EOF

cat > "$FIXTURE/scripts/live.sh" <<'EOF'
#!/usr/bin/env bash
echo live
EOF

cat > "$FIXTURE/scripts/archive/old-tool.sh" <<'EOF'
#!/usr/bin/env bash
echo archive
EOF

cat > "$FIXTURE/work/20260605T000000Z/.target-snapshot/scripts/snapshot-tool.sh" <<'EOF'
#!/usr/bin/env bash
echo retained
EOF

cat > "$FIXTURE/runs/20260605T000000Z/tools/run-tool.py" <<'EOF'
print("retained")
EOF

cat > "$FIXTURE/research/evidence/package/scripts/evidence-helper.sh" <<'EOF'
#!/usr/bin/env bash
echo retained
EOF

cat > "$FIXTURE/targets/example/scripts/target-helper.sh" <<'EOF'
#!/usr/bin/env bash
echo retained
EOF

cat > "$FIXTURE/audit-output.clean-head-snapshot/scripts/snapshot-helper.sh" <<'EOF'
#!/usr/bin/env bash
echo retained
EOF

cat > "$FIXTURE/tests/fixtures/demo/scripts/fixture-helper.sh" <<'EOF'
#!/usr/bin/env bash
echo fixture
EOF

cat > "$FIXTURE/examples/tools/example-tool.py" <<'EOF'
print("fixture")
EOF

cat > "$FIXTURE/node_modules/pkg/scripts/generated.sh" <<'EOF'
#!/usr/bin/env bash
echo generated
EOF

cat > "$FIXTURE/build/tools/build-tool.py" <<'EOF'
print("generated")
EOF

PASS_JSON="$TMP_ROOT/pass.json"
if ! bash "$REPO_ROOT/scripts/detect-capability-drift.sh" "$FIXTURE" --threshold 20 --json > "$PASS_JSON"; then
  echo "FAIL: detector counted classified non-live tools as live drift" >&2
  cat "$PASS_JSON" >&2
  exit 1
fi

python3 - "$PASS_JSON" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1], encoding="utf-8"))
assert data["scope_version"] == "capability-drift-classified-v1", data
assert data["total_disk"] == 1, data
assert data["total_tracked"] == 1, data
assert data["drift_count"] == 0, data
assert data["drift_pct"] == 0, data
assert data["pass"] is True, data
assert data["undocumented"] == [], data
counts = data["scope_counts"]
assert counts["live"] == 1, counts
assert counts["retained"] == 5, counts
assert counts["archive"] == 1, counts
assert counts["test_fixture"] == 2, counts
assert counts["generated"] == 2, counts
paths = data["scope_paths"]
assert paths["live"] == ["scripts/live.sh"], paths
assert "work/20260605T000000Z/.target-snapshot/scripts/snapshot-tool.sh" in paths["retained"], paths
assert "scripts/archive/old-tool.sh" in paths["archive"], paths
assert "tests/fixtures/demo/scripts/fixture-helper.sh" in paths["test_fixture"], paths
assert "node_modules/pkg/scripts/generated.sh" in paths["generated"], paths
PY

cat > "$FIXTURE/scripts/undocumented.sh" <<'EOF'
#!/usr/bin/env bash
echo undocumented
EOF

FAIL_JSON="$TMP_ROOT/fail.json"
set +e
bash "$REPO_ROOT/scripts/detect-capability-drift.sh" "$FIXTURE" --threshold 20 --json > "$FAIL_JSON"
status=$?
set -e

if [ "$status" -eq 0 ]; then
  echo "FAIL: detector passed with a real undocumented live script" >&2
  cat "$FAIL_JSON" >&2
  exit 1
fi

python3 - "$FAIL_JSON" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1], encoding="utf-8"))
assert data["total_disk"] == 2, data
assert data["total_tracked"] == 1, data
assert data["drift_count"] == 1, data
assert data["drift_pct"] == 50, data
assert data["pass"] is False, data
assert data["undocumented"] == ["scripts/undocumented.sh"], data
for bucket in ("retained", "archive", "test_fixture", "generated"):
    assert "scripts/undocumented.sh" not in data["scope_paths"][bucket], data
PY

echo "PASS: detect-capability-drift classified inventory"
