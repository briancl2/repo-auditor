#!/usr/bin/env bash
# Validate that one commit carries explicit spec provenance, either directly
# or on the reviewed second parent of a merge commit.
set -euo pipefail

COMMIT_REF="${1:-HEAD}"
TRAILER_PATTERN='^(Spec-ID|Spec-Exempt):'

if ! COMMIT_SHA=$(git rev-parse --verify "${COMMIT_REF}^{commit}" 2>/dev/null); then
    echo "  FAIL: commit provenance ref is not a commit: $COMMIT_REF"
    exit 1
fi

has_spec_trailer() {
    git log -1 --format=%B "$1" 2>/dev/null | grep -qE "$TRAILER_PATTERN"
}

if has_spec_trailer "$COMMIT_SHA"; then
    echo "  PASS: last commit has Spec-ID or Spec-Exempt trailer"
    exit 0
fi

PARENT_LINE=$(git rev-list --parents -n 1 "$COMMIT_SHA")
set -- $PARENT_LINE
if [ "$#" -gt 2 ]; then
    SECOND_PARENT="$3"
    if has_spec_trailer "$SECOND_PARENT"; then
        echo "  PASS: merge commit lacks trailer; second parent has Spec-ID or Spec-Exempt trailer"
        exit 0
    fi
    echo "  FAIL: merge commit and second parent lack Spec-ID or Spec-Exempt trailer"
    exit 1
fi

echo "  FAIL: last commit lacks Spec-ID or Spec-Exempt trailer"
exit 1
