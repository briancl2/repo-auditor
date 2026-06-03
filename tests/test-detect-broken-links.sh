#!/usr/bin/env bash
# test-detect-broken-links.sh — Validate DS-42 markdown-link scope.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DS42="$REPO_ROOT/scripts/detect-broken-links.sh"

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/ds42-fixture.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

echo "=== DS-42 Broken Internal Link Fixtures ==="

FENCED_ONLY="$TMP_ROOT/fenced-only"
mkdir -p "$FENCED_ONLY/docs"
cat > "$FENCED_ONLY/docs/examples.md" <<'EOF'
# Fenced Example

```markdown
See [example guide](references/guide.md) for a hypothetical generated skill.
```

~~~markdown
See [tilde guide](references/tilde-guide.md) for another generated example.
~~~
EOF

fenced_json=$(bash "$DS42" "$FENCED_ONLY")
printf '%s' "$fenced_json" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data["ds_id"] == "DS-42"
assert data["fired"] is False
assert data["broken_count"] == 0
assert data["total_links"] == 0
'
echo "  ✓ fenced example links are ignored"

LIVE_BROKEN="$TMP_ROOT/live-broken"
mkdir -p "$LIVE_BROKEN/docs"
cat > "$LIVE_BROKEN/docs/examples.md" <<'EOF'
# Live Link Fixture

```markdown
See [example guide](references/guide.md) for a hypothetical generated skill.
```

The real missing link is [missing](missing.md).
EOF

live_json=$(bash "$DS42" "$LIVE_BROKEN")
printf '%s' "$live_json" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data["ds_id"] == "DS-42"
assert data["fired"] is True
assert data["broken_count"] == 1
assert data["total_links"] == 1
assert "missing.md" in data["evidence"]
assert "references/guide.md" not in data["evidence"]
'
echo "  ✓ live missing links still fire"

echo "  VERDICT: PASS"
