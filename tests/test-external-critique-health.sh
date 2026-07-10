#!/usr/bin/env bash
# Validate AS-08 external-critique capability semantics and drift classes.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

MISSING_REPO="$TMPDIR/missing-capability"
CLEAN_REPO="$TMPDIR/clean-capability"
DRIFT_REPO="$TMPDIR/drift-capability"
ROLE_REPO="$TMPDIR/role-capability"
PROMPT_ONLY_DRIFT_REPO="$TMPDIR/prompt-only-drift"
MODEL_RUNTIME_REPO="$TMPDIR/model-runtime-evidence"
CURRENT_PROFILE_REPO="$TMPDIR/current-profile"
BMA_LEGACY_PROFILE_REPO="$TMPDIR/bma-legacy-profile"
VAULT_LEGACY_PROFILE_REPO="$TMPDIR/vault-legacy-profile"
UNRELATED_XHIGH_REPO="$TMPDIR/unrelated-xhigh"
HISTORICAL_PROFILE_REPO="$TMPDIR/historical-profile"
UNRELATED_GPT_REPO="$TMPDIR/unrelated-gpt"
PROFILE_PROSE_REPO="$TMPDIR/profile-prose"

mkdir -p "$MISSING_REPO/docs"
mkdir -p "$CLEAN_REPO/.github/prompts"
mkdir -p "$DRIFT_REPO/docs"
mkdir -p "$PROMPT_ONLY_DRIFT_REPO/.github/prompts" "$PROMPT_ONLY_DRIFT_REPO/.agents/skills/owner-review"
mkdir -p "$MODEL_RUNTIME_REPO/docs" "$MODEL_RUNTIME_REPO/.agents/skills/external-critique"
mkdir -p "$CURRENT_PROFILE_REPO/.agents/skills/external-critique"
mkdir -p "$BMA_LEGACY_PROFILE_REPO/.agents/skills/external-critique/scripts"
mkdir -p "$VAULT_LEGACY_PROFILE_REPO/.github/skills/seeking-external-critique/scripts"
mkdir -p "$UNRELATED_XHIGH_REPO/.agents/skills/external-critique"
mkdir -p "$HISTORICAL_PROFILE_REPO/.agents/skills/external-critique" "$HISTORICAL_PROFILE_REPO/docs/history"
mkdir -p "$UNRELATED_GPT_REPO/.agents/skills/external-critique" "$UNRELATED_GPT_REPO/.agents/skills/hermes" "$UNRELATED_GPT_REPO/docs" "$UNRELATED_GPT_REPO/scripts"
mkdir -p "$PROFILE_PROSE_REPO/.agents/skills/external-critique" "$PROFILE_PROSE_REPO/docs"
mkdir -p \
  "$ROLE_REPO/scripts" \
  "$ROLE_REPO/.github/prompts" \
  "$ROLE_REPO/.agents/skills/external-critique" \
  "$ROLE_REPO/docs" \
  "$ROLE_REPO/.github/workflows" \
  "$ROLE_REPO/.github/agents"

cat > "$MISSING_REPO/docs/notes.md" <<'EOF'
# Ordinary Notes

This repository has local tests and review notes, but no retained external
critique capability or admission rule.
EOF

cat > "$CLEAN_REPO/.github/prompts/external-critique.prompt.md" <<'EOF'
# External Critique Capability

Version: 1.2
artifact: EXTERNAL_CRITIQUE_CAPABILITY

Use one critic by default when context support shows a bounded external risk
read may change the owner action. Panel/latest-panel requires named
high-stakes context before invocation.

authority refs: AGENTS.md, GitHub issue/PR/check/merge truth, and independent
owner evidence outrank critic output. Target repo principles outrank imported
BMA phrasing and external phrasing.

privacy/redaction boundaries: omit credentials, account details, customer
details, private URLs, and internal text outside the approved summary.

finding quota: none; no-finding results are valid. Blocker findings require
independent owner evidence; advisory findings do not block by themselves.
pass budget: one initial pass plus one follow-up pass unless explicitly
approved with a stopping condition.

receipt_output runtime truth records requested_path, requested_model,
actual_responding_path, actual_responding_model when known, and
unavailable_disposition without a model probe program.

BMA seed evidence, if any, is provenance only and non-canonical. Fleet findings
are advisory until owner evidence exists and owner routing is recorded.
EOF

cat > "$DRIFT_REPO/docs/external-critique.md" <<'EOF'
# BMA External Critique

Version: 0.5
artifact: EXTERNAL_CRITIQUE_CAPABILITY

BMA Issue #164 coordinator prompt text is canonical for this repo. Use
latest-panel for every review. The critic must return at least three findings,
and critique approves closure. Send full transcripts to reviewers.

Fleet findings are owner binding across repos.
EOF

cat > "$PROMPT_ONLY_DRIFT_REPO/.agents/skills/owner-review/SKILL.md" <<'EOF'
# Owner Review Skill

This repo uses a skill system for review capabilities.
EOF

cat > "$PROMPT_ONLY_DRIFT_REPO/.github/prompts/external-critique.prompt.md" <<'EOF'
# External Critique Capability

Version: 1.2
artifact: EXTERNAL_CRITIQUE_CAPABILITY

Use one critic by default when context support shows a bounded external risk
read may change the owner action. Panel/latest-panel requires named
high-stakes context before invocation.

authority refs: AGENTS.md, GitHub issue/PR/check/merge truth, and independent
owner evidence outrank critic output. Target repo principles outrank imported
BMA phrasing and external phrasing.

privacy/redaction boundaries: omit credentials, account details, customer
details, private URLs, and internal text outside the approved summary.

finding quota: none; no-finding results are valid. Blocker findings require
independent owner evidence; advisory findings do not block by themselves.
pass budget: one initial pass plus one follow-up pass unless explicitly
approved with a stopping condition.

receipt_output runtime truth records requested_path, requested_model,
actual_responding_path, actual_responding_model when known, and
unavailable_disposition without a model probe program.

BMA seed evidence, if any, is provenance only and non-canonical. Fleet findings
are advisory until owner evidence exists and owner routing is recorded.
EOF

cat > "$MODEL_RUNTIME_REPO/.agents/skills/external-critique/SKILL.md" <<'EOF'
# External Critique Skill

EXTERNAL_CRITIQUE_CAPABILITY Version: 1.2 context support; panel/latest-panel
requires named high-stakes context before invocation; finding quota: none;
no-finding results are valid; blocker findings and advisory findings are
separated; pass budget one initial pass plus one follow-up pass with a stopping
condition; authority refs AGENTS.md and GitHub issue/PR/check/merge truth;
privacy/redaction boundaries; fleet findings advisory until owner evidence
exists.
EOF

cat > "$MODEL_RUNTIME_REPO/docs/external-critique-runtime-receipt.md" <<'EOF'
# External Critique Runtime Receipt

receipt_output: external critique run retained receipt/output truth.
requested_path: external-critic
requested_model: claude-sonnet-4
actual_responding_path: hermes-copilot
actual_responding_model: gpt-5.5
unavailable_disposition: requested model unavailable; used available foreground model recorded by receipt.
EOF

role_rule='EXTERNAL_CRITIQUE_CAPABILITY Version: 1.2 context support; panel/latest-panel requires named high-stakes context before invocation; finding quota: none; no-finding results are valid; blocker findings and advisory findings are separated; pass budget one initial pass plus one follow-up pass with a stopping condition; authority refs AGENTS.md and GitHub issue/PR/check/merge truth; privacy/redaction boundaries; fleet findings advisory until owner evidence exists; receipt_output runtime truth records requested_path, requested_model, actual_responding_path, actual_responding_model when known, and unavailable_disposition without a model probe program.'

write_current_profile() {
  local repo="$1"
  mkdir -p "$repo/.agents/skills/external-critique"
  cat > "$repo/.agents/skills/external-critique/SKILL.md" <<EOF
# External Critique Skill

$role_rule

The external-critique-profile default configured slot is claude-opus-4.8|max.
The latest-panel configured profile runs:
- claude-opus-4.8|max
- gemini-3.1-pro-preview|high
- gpt-5.6-sol|max
EOF
}

write_current_profile "$CURRENT_PROFILE_REPO"
write_current_profile "$UNRELATED_XHIGH_REPO"
write_current_profile "$HISTORICAL_PROFILE_REPO"
write_current_profile "$UNRELATED_GPT_REPO"
write_current_profile "$PROFILE_PROSE_REPO"

cat > "$BMA_LEGACY_PROFILE_REPO/.agents/skills/external-critique/scripts/external_critique.sh" <<EOF
#!/usr/bin/env bash
# $role_rule
append_run "claude-opus-4.8" "max"
append_run "gemini-3.1-pro-preview" "high"
append_run "gpt-5.5" "xhigh"
EOF

cat > "$VAULT_LEGACY_PROFILE_REPO/.github/skills/seeking-external-critique/scripts/external_critique.sh" <<EOF
#!/usr/bin/env bash
# $role_rule
select_cross_model() {
  echo "gpt-5.5"
}
CROSS_MODEL=\$(select_cross_model)
EOF

cat >> "$UNRELATED_XHIGH_REPO/.agents/skills/external-critique/SKILL.md" <<'EOF'

Review depth may use xhigh when separately approved.
EOF
cat > "$UNRELATED_XHIGH_REPO/.agents/skills/external-critique/commented-example.sh" <<'EOF'
#!/usr/bin/env bash
# Compatibility example only:
# append_run "gpt-5.5" "xhigh"
EOF

cat > "$HISTORICAL_PROFILE_REPO/docs/history/external-critique-receipt.json" <<'EOF'
{
  "artifact": "EXTERNAL_CRITIQUE_CAPABILITY",
  "requested_model": "gpt-5.5",
  "requested_effort": "xhigh",
  "runtime_state": "success"
}
EOF

cat > "$UNRELATED_GPT_REPO/scripts/review.sh" <<'EOF'
REVIEW_MODEL="gpt-5.5"
REVIEW_EFFORT="xhigh"
EOF
cat > "$UNRELATED_GPT_REPO/.agents/skills/hermes/SKILL.md" <<'EOF'
# Hermes
The foreground Hermes model is gpt-5.5|high.
EOF
cat > "$UNRELATED_GPT_REPO/docs/P11.md" <<'EOF'
# P11
The P11 judge may use gpt-5.5|xhigh.
EOF

cat > "$PROFILE_PROSE_REPO/docs/model-policy.md" <<'EOF'
# Model Policy

Historical prose says the external critique profile once used gpt-5.5|xhigh.
This file is not a mechanism and carries no capability token.
EOF

cat > "$ROLE_REPO/scripts/external-critique.sh" <<EOF
#!/usr/bin/env bash
# $role_rule
echo external-critique
EOF

cat > "$ROLE_REPO/.github/prompts/external-critique.prompt.md" <<EOF
# Prompt

$role_rule
EOF

cat > "$ROLE_REPO/.agents/skills/external-critique/SKILL.md" <<EOF
# External Critique Skill

$role_rule
EOF

cat > "$ROLE_REPO/Makefile" <<EOF
external-critique:
	@echo "$role_rule"
EOF

cat > "$ROLE_REPO/docs/external-critique.md" <<EOF
# External Critique

$role_rule
EOF

cat > "$ROLE_REPO/.github/workflows/external-critique.yml" <<EOF
name: external-critique
on: [workflow_dispatch]
jobs:
  note:
    runs-on: ubuntu-latest
    steps:
      - run: 'echo "$role_rule"'
EOF

cat > "$ROLE_REPO/.github/agents/external-critic.agent.md" <<EOF
# External Critic Agent

$role_rule
EOF

python3 - "$REPO_ROOT" "$MISSING_REPO" "$CLEAN_REPO" "$DRIFT_REPO" "$ROLE_REPO" "$PROMPT_ONLY_DRIFT_REPO" "$MODEL_RUNTIME_REPO" "$CURRENT_PROFILE_REPO" "$BMA_LEGACY_PROFILE_REPO" "$VAULT_LEGACY_PROFILE_REPO" "$UNRELATED_XHIGH_REPO" "$HISTORICAL_PROFILE_REPO" "$UNRELATED_GPT_REPO" "$PROFILE_PROSE_REPO" <<'PY'
import json
import subprocess
import sys

(
    repo_root,
    missing_repo,
    clean_repo,
    drift_repo,
    role_repo,
    prompt_only_drift_repo,
    model_runtime_repo,
    current_profile_repo,
    bma_legacy_profile_repo,
    vault_legacy_profile_repo,
    unrelated_xhigh_repo,
    historical_profile_repo,
    unrelated_gpt_repo,
    profile_prose_repo,
) = sys.argv[1:15]


def run(repo):
    completed = subprocess.run(
        ["bash", f"{repo_root}/scripts/detect-external-critique-health.sh", repo],
        check=True,
        text=True,
        stdout=subprocess.PIPE,
    )
    return json.loads(completed.stdout)


missing = run(missing_repo)
assert missing["ds_id"] == "AS-08", missing
assert missing["fired"] is True, missing
assert missing["signals"]["external_critique_capability_present"] is False, missing
assert missing["signals"]["evidence_class_counts"]["missing_capability"] == 1, missing

clean = run(clean_repo)
assert clean["ds_id"] == "AS-08", clean
assert clean["fired"] is False, clean
assert clean["signals"]["contract_semantics_source"].startswith(
    "repo-agent-core/docs/external-critique-capability-contract.md@"
), clean
assert clean["signals"]["contract_source_version"] == "1.2", clean
assert clean["signals"]["external_critique_capability_present"] is True, clean
assert clean["signals"]["external_critique_mechanism_count"] == 1, clean
assert clean["signals"]["mechanism_roles"] == ["prompt"], clean
assert clean["signals"]["skill_or_capability_convention_present"] is False, clean
assert clean["signals"]["prompt_only_external_critique_count"] == 1, clean
assert clean["signals"]["prompt_only_external_critique_drift_count"] == 0, clean
assert clean["signals"]["model_runtime_truth_file_count"] == 1, clean
assert clean["signals"]["model_runtime_truth_complete_file_count"] == 1, clean
assert clean["signals"]["model_runtime_truth_missing_count"] == 0, clean
assert clean["signals"]["context_support_count"] == 1, clean
assert clean["signals"]["named_high_stakes_context_count"] == 1, clean
assert clean["signals"]["no_forced_finding_quota_count"] == 1, clean
assert clean["signals"]["blocker_advisory_support_count"] == 1, clean
assert clean["signals"]["loop_cap_support_count"] == 1, clean
assert clean["signals"]["local_authority_ref_count"] == 1, clean
assert clean["signals"]["privacy_boundary_count"] == 1, clean
assert clean["signals"]["bma_translation_count"] == 1, clean
assert clean["signals"]["fleet_advisory_until_owner_evidence_count"] == 1, clean
assert not any(clean["signals"]["evidence_class_counts"].values()), clean
assert not any(clean["signals"]["extra_drift_counts"].values()), clean

prompt_only = run(prompt_only_drift_repo)
assert prompt_only["fired"] is True, prompt_only
assert prompt_only["signals"]["external_critique_capability_present"] is True, prompt_only
assert prompt_only["signals"]["mechanism_roles"] == ["prompt"], prompt_only
assert prompt_only["signals"]["skill_or_capability_convention_present"] is True, prompt_only
assert prompt_only["signals"]["skill_or_capability_convention_paths"] == [
    ".agents/skills/owner-review/SKILL.md"
], prompt_only
assert prompt_only["signals"]["prompt_only_external_critique_count"] == 1, prompt_only
assert prompt_only["signals"]["prompt_only_external_critique_drift_count"] == 1, prompt_only
assert prompt_only["signals"]["model_runtime_truth_missing_count"] == 0, prompt_only
assert prompt_only["signals"]["extra_drift_counts"]["prompt_only_external_critique"] == 1, prompt_only
assert "prompt_only_external_critique" in prompt_only["signals"]["active_evidence_classes"], prompt_only

drift = run(drift_repo)
assert drift["fired"] is True, drift
counts = drift["signals"]["evidence_class_counts"]
extra = drift["signals"]["extra_drift_counts"]
for key in (
    "stale_bma_copy",
    "local_principle_drift",
    "panel_without_context",
    "forced_finding_quota",
    "no_loop_cap",
    "no_local_authority_refs",
    "privacy_boundary_missing",
):
    assert counts[key] == 1, (key, drift)
assert counts["missing_capability"] == 0, drift
assert extra["contract_version_drift"] == 1, drift
assert extra["blocker_advisory_missing"] == 1, drift
assert extra["fleet_advisory_missing"] == 1, drift
assert extra["model_runtime_truth_missing"] == 1, drift
assert "docs/external-critique.md=>0.5" in drift["signals"]["local_version_records"], drift

model_runtime = run(model_runtime_repo)
assert model_runtime["fired"] is False, model_runtime
assert model_runtime["signals"]["model_runtime_truth_file_count"] == 1, model_runtime
assert model_runtime["signals"]["model_runtime_truth_complete_file_count"] == 1, model_runtime
assert model_runtime["signals"]["model_runtime_truth_missing_count"] == 0, model_runtime
assert model_runtime["signals"]["requested_model_evidence_count"] == 1, model_runtime
assert model_runtime["signals"]["actual_responding_model_evidence_count"] == 1, model_runtime
assert model_runtime["signals"]["unavailable_disposition_evidence_count"] == 1, model_runtime
assert model_runtime["signals"]["model_runtime_truth_paths"] == [
    "docs/external-critique-runtime-receipt.md"
], model_runtime
assert not any(model_runtime["signals"]["evidence_class_counts"].values()), model_runtime
assert not any(model_runtime["signals"]["extra_drift_counts"].values()), model_runtime

roles = run(role_repo)
assert roles["fired"] is False, roles
assert set(roles["signals"]["mechanism_roles"]) == {
    "runner",
    "prompt",
    "skill",
    "make_target",
    "docs",
    "workflow",
    "agent_instruction",
}, roles
for role, expected_path in {
    "runner": "scripts/external-critique.sh",
    "prompt": ".github/prompts/external-critique.prompt.md",
    "skill": ".agents/skills/external-critique/SKILL.md",
    "make_target": "Makefile",
    "docs": "docs/external-critique.md",
    "workflow": ".github/workflows/external-critique.yml",
    "agent_instruction": ".github/agents/external-critic.agent.md",
}.items():
    assert expected_path in roles["signals"]["mechanism_paths_by_role"][role], (role, roles)

current_profile = run(current_profile_repo)
assert current_profile["fired"] is False, current_profile
assert current_profile["signals"]["external_critique_profile_pointer"] == "external-critique-profile", current_profile
assert current_profile["signals"]["canonical_model_effort_pairs"] == [
    "claude-opus-4.8|max",
    "gemini-3.1-pro-preview|high",
    "gpt-5.6-sol|max",
], current_profile
assert current_profile["signals"]["detected_model_effort_pairs"] == [
    ".agents/skills/external-critique/SKILL.md=>claude-opus-4.8|max",
    ".agents/skills/external-critique/SKILL.md=>gemini-3.1-pro-preview|high",
    ".agents/skills/external-critique/SKILL.md=>gpt-5.6-sol|max",
], current_profile
assert current_profile["signals"]["evidence_class_counts"]["stale_critique_profile"] == 0, current_profile

bma_legacy = run(bma_legacy_profile_repo)
bma_counts = bma_legacy["signals"]["evidence_class_counts"]
assert bma_legacy["fired"] is True, bma_legacy
assert bma_counts["stale_critique_profile"] == 1, bma_legacy
assert bma_counts["legacy_gpt_critique_slot"] == 1, bma_legacy
assert bma_counts["missing_explicit_critique_effort"] == 0, bma_legacy
assert bma_legacy["signals"]["legacy_gpt_critique_slot_evidence"] == [
    ".agents/skills/external-critique/scripts/external_critique.sh=>gpt-5.5|xhigh"
], bma_legacy

vault_legacy = run(vault_legacy_profile_repo)
vault_counts = vault_legacy["signals"]["evidence_class_counts"]
assert vault_legacy["fired"] is True, vault_legacy
assert vault_counts["stale_critique_profile"] == 1, vault_legacy
assert vault_counts["legacy_gpt_critique_slot"] == 1, vault_legacy
assert vault_counts["missing_explicit_critique_effort"] == 1, vault_legacy
assert vault_legacy["signals"]["legacy_gpt_critique_slot_evidence"] == [
    ".github/skills/seeking-external-critique/scripts/external_critique.sh=>gpt-5.5|implicit"
], vault_legacy
assert vault_legacy["signals"]["missing_explicit_critique_effort_evidence"] == [
    ".github/skills/seeking-external-critique/scripts/external_critique.sh=>gpt-5.5|implicit"
], vault_legacy

unrelated_xhigh = run(unrelated_xhigh_repo)
assert unrelated_xhigh["fired"] is False, unrelated_xhigh
assert unrelated_xhigh["signals"]["evidence_class_counts"]["stale_critique_profile"] == 0, unrelated_xhigh

historical = run(historical_profile_repo)
assert historical["signals"]["evidence_class_counts"]["legacy_gpt_critique_slot"] == 0, historical
assert not any("gpt-5.5" in pair for pair in historical["signals"]["detected_model_effort_pairs"]), historical
assert "docs/history/external-critique-receipt.json" not in historical["signals"]["live_external_critique_mechanism_paths"], historical

unrelated_gpt = run(unrelated_gpt_repo)
assert unrelated_gpt["fired"] is False, unrelated_gpt
assert unrelated_gpt["signals"]["evidence_class_counts"]["legacy_gpt_critique_slot"] == 0, unrelated_gpt
assert not any("gpt-5.5" in pair for pair in unrelated_gpt["signals"]["detected_model_effort_pairs"]), unrelated_gpt

profile_prose = run(profile_prose_repo)
assert profile_prose["fired"] is False, profile_prose
assert profile_prose["signals"]["evidence_class_counts"]["legacy_gpt_critique_slot"] == 0, profile_prose
assert "docs/model-policy.md" not in profile_prose["signals"]["live_external_critique_mechanism_paths"], profile_prose

print("External critique health detector semantics passed.")
PY
