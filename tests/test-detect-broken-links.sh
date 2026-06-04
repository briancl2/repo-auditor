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
assert data["active_doc_broken_count"] == 0
assert data["total_links"] == 0
assert data["target_actionability"] == "none"
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
assert data["active_doc_broken_count"] == 1
assert data["archive_doc_broken_count"] == 0
assert data["total_links"] == 1
assert data["target_actionability"] == "live_doc_repair"
assert "missing.md" in data["evidence"]
assert "references/guide.md" not in data["evidence"]
'
echo "  ✓ live missing links still fire"

ARCHIVE_ONLY="$TMP_ROOT/archive-only"
mkdir -p "$ARCHIVE_ONLY/system/plans/archive" "$ARCHIVE_ONLY/docs/archived"
cat > "$ARCHIVE_ONLY/system/plans/archive/old-plan.md" <<'EOF'
# Archived Plan Fixture

The historical missing link is [old target](old-target.md).
EOF
cat > "$ARCHIVE_ONLY/docs/archived/old-note.md" <<'EOF'
# Archived Note Fixture

The archived note link is [old note target](old-note-target.md).
EOF

archive_json=$(bash "$DS42" "$ARCHIVE_ONLY")
printf '%s' "$archive_json" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data["ds_id"] == "DS-42"
assert data["fired"] is False
assert data["broken_count"] == 0
assert data["active_doc_broken_count"] == 0
assert data["archive_broken_count"] == 2
assert data["archive_doc_broken_count"] == 2
assert data["total_links"] == 2
assert data["evidence"] == ""
assert data["target_actionability"] == "archive_triage_only"
assert "old-target.md" in data["archive_evidence"]
assert "old-note-target.md" in data["archive_evidence"]
'
echo "  ✓ archive-only missing links are scoped separately"

MIXED_SCOPE="$TMP_ROOT/mixed-scope"
mkdir -p "$MIXED_SCOPE/docs/archive" "$MIXED_SCOPE/docs/live"
cat > "$MIXED_SCOPE/docs/archive/old-plan.md" <<'EOF'
# Archived Plan Fixture

The historical missing link is [old target](old-target.md).
EOF
cat > "$MIXED_SCOPE/docs/live/current.md" <<'EOF'
# Live Fixture

The live missing link is [current target](current-target.md).
EOF

mixed_json=$(bash "$DS42" "$MIXED_SCOPE")
printf '%s' "$mixed_json" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data["ds_id"] == "DS-42"
assert data["fired"] is True
assert data["broken_count"] == 1
assert data["active_doc_broken_count"] == 1
assert data["archive_broken_count"] == 1
assert data["archive_doc_broken_count"] == 1
assert data["total_links"] == 2
assert data["target_actionability"] == "mixed_live_and_archive_repair"
assert "current-target.md" in data["evidence"]
assert "old-target.md" not in data["evidence"]
assert "old-target.md" in data["archive_evidence"]
'
echo "  ✓ mixed scope fires only for live missing links"

echo "  VERDICT: PASS"
