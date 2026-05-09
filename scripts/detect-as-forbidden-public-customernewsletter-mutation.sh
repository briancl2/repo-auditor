#!/usr/bin/env bash
# detect-as-forbidden-public-customernewsletter-mutation.sh - AS-18: forbidden public CustomerNewsletter mutation
set -euo pipefail

REPO="${1:?Usage: detect-as-forbidden-public-customernewsletter-mutation.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-18" "$REPO"
