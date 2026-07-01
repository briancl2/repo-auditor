#!/usr/bin/env bash
# Verify AS-56 detects default closure paths hard-coupled to sibling repo paths.
# Read-only; targets are never modified.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

EXTERNAL_REPO="$TMPDIR/external-closure-coupling"
SELF_CONTAINED_REPO="$TMPDIR/self-contained-closure"
NEGATED_DOC_REPO="$TMPDIR/negated-external-closure-doc"
mkdir -p "$EXTERNAL_REPO/scripts" "$SELF_CONTAINED_REPO/scripts" "$NEGATED_DOC_REPO/docs"

cat > "$EXTERNAL_REPO/scripts/work-close.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

WORK_DIR="${1:?work dir required}"
echo "Running post-audit..."
AUDITOR="$HOME/repos/repo-auditor/scripts/repo-auditor.sh"
mkdir -p "$WORK_DIR/post-audit"
if [ -f "$AUDITOR" ]; then
    timeout 300 bash "$AUDITOR" "$PWD" "$WORK_DIR/post-audit" > /dev/null 2>&1 || echo "WARNING: Post-audit failed"
fi
EOF

cat > "$SELF_CONTAINED_REPO/scripts/work-close.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

WORK_DIR="${1:?work dir required}"
echo "Running repo-local closeout checks..."
bash scripts/check.sh
printf 'closure complete: %s\n' "$WORK_DIR"
EOF

cat > "$NEGATED_DOC_REPO/docs/closure-integrity.md" <<'EOF'
# Closure integrity

The default closure gate must not hard-depend on $HOME/repos/repo-auditor or any
other sibling repo path. Reciprocal audit remains opt-in advisory evidence only.
EOF

python3 - "$REPO_ROOT" "$EXTERNAL_REPO" "$SELF_CONTAINED_REPO" "$NEGATED_DOC_REPO" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

repo_root, external_repo, self_contained_repo, negated_doc_repo = map(Path, sys.argv[1:])


def run(repo: Path) -> dict:
    completed = subprocess.run(
        ["bash", str(repo_root / "scripts/detect-as-external-closure-coupling.sh"), str(repo)],
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        raise SystemExit(completed.stderr or completed.stdout)
    return json.loads(completed.stdout)


external = run(external_repo)
assert external["ds_id"] == "AS-56", external
assert external["family"] == "AS", external
assert external["name"] == "external-closure-coupling", external
assert external["severity"] == "HIGH", external
assert external["fired"] is True, external
assert external["signals"]["external_closure_coupling_count"] == 1, external
assert external["signals"]["external_repo_path_surface_count"] == 1, external
assert "scripts/work-close.sh=>external_repo_path" in external["evidence"], external

self_contained = run(self_contained_repo)
assert self_contained["ds_id"] == "AS-56", self_contained
assert self_contained["fired"] is False, self_contained
assert self_contained["signals"]["external_closure_coupling_count"] == 0, self_contained

negated = run(negated_doc_repo)
assert negated["ds_id"] == "AS-56", negated
assert negated["fired"] is False, negated
assert negated["signals"]["external_closure_coupling_count"] == 0, negated
PY

echo "PASS: AS-56 external closure coupling detector covered"
