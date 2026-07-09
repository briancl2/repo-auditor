#!/usr/bin/env bash
# detect-as-assimilation-github-work-management-gap.sh - AS-59: Assimilation GitHub work-management gap
set -euo pipefail
REPO="${1:?Usage: detect-as-assimilation-github-work-management-gap.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-59" "$REPO"
