.PHONY: review audit audit-deep audit-quick audit-snapshot measure-dual-inventory-cap-curve token-efficiency-measure test validate validate-owner-convergence help install-hooks check

TARGET ?= .
OUTPUT_DIR ?= audit_output
SNAPSHOT_DIR ?= $(OUTPUT_DIR).clean-head-snapshot
SOURCE_PACK ?= tests/fixtures/token-efficiency-measurement-pilot/source-pack.json
OWNER_CONVERGENCE_BASE_REF ?= e8b42763eb3e323d0e0238e84fe81c4c87898627
CORE_BASELINE_REF ?= 9da7b41b83a10b9fd71ad24b0529a50425a8d373

help:
	@echo "repo-auditor — read-only repository health scorer"
	@echo ""
	@echo "  make audit TARGET=<path>       Standard deterministic audit"
	@echo "  make audit-snapshot TARGET=<path> OUTPUT_DIR=<dir> SNAPSHOT_DIR=<dir>"
	@echo "  make audit-quick TARGET=<path> Quick pre-scan only"
	@echo "  make audit-deep TARGET=<path>  Opt-in deep audit"
	@echo "  make check                     Pre-commit + convergence gate"
	@echo "  make test                      Run all tests"
	@echo "  make validate                  Validate schemas"
	@echo "  make validate-owner-convergence"
	@echo "  make review                    Review the staged diff"

review:
	@bash .agents/skills/reviewing-code-locally/scripts/local_review.sh

audit:
	@echo "=== repo-auditor: Standard Mode (deterministic) ==="
	@mkdir -p $(OUTPUT_DIR)
	@bash scripts/repo-auditor.sh "$(TARGET)" "$(OUTPUT_DIR)"
	@echo "=== Audit complete. Artifacts in $(OUTPUT_DIR)/ ==="

audit-snapshot:
	@echo "=== repo-auditor: Clean HEAD Snapshot Mode ==="
	@python3 scripts/audit-clean-head-snapshot.py "$(TARGET)" "$(OUTPUT_DIR)" --snapshot-dir "$(SNAPSHOT_DIR)"
	@echo "=== Snapshot audit complete. Artifacts in $(OUTPUT_DIR)/; snapshot in $(SNAPSHOT_DIR)/ ==="

measure-dual-inventory-cap-curve:
	@python3 scripts/measure-dual-inventory-cap-curve.py "$(TARGET)" "$(OUTPUT_DIR)" --caps "$${CAPS:-200,1000,2500,5000}"

audit-deep:
	@mkdir -p $(OUTPUT_DIR)
	@bash scripts/repo-auditor.sh "$(TARGET)" "$(OUTPUT_DIR)" --mode deep

audit-quick:
	@mkdir -p $(OUTPUT_DIR)
	@bash .agents/skills/pre-scanning/scripts/pre-scan-target.sh "$(TARGET)" "$(OUTPUT_DIR)"

token-efficiency-measure:
	@mkdir -p $(OUTPUT_DIR)
	@python3 scripts/token-efficiency-measure.py --source-pack "$(SOURCE_PACK)" --output-dir "$(OUTPUT_DIR)"

test:
	@echo "=== Running auditor test suite ==="
	@python3 scripts/closure_identity.py --phase "$${CLOSURE_PHASE:-test}" --parent-command "$${PARENT_COMMAND:-make test}"
	@for t in tests/test-*.sh; do \
		echo "--- $$t ---"; bash "$$t" || exit 1; \
	done
	@echo ""
	@echo "=== All tests passed ==="

validate:
	@python3 scripts/closure_identity.py --phase "$${CLOSURE_PHASE:-validate}" --parent-command "$${PARENT_COMMAND:-make validate}"
	@for s in schemas/*.schema.json; do \
		python3 -c "import json; json.load(open('$$s'))" && echo "  ✓ $$(basename $$s)" || exit 1; \
	done

validate-owner-convergence:
	@python3 scripts/validate_owner_convergence.py \
		--repo . \
		--base-ref "$(OWNER_CONVERGENCE_BASE_REF)" \
		--core-ref "$(CORE_BASELINE_REF)" \
		$(if $(CORE_REPO),--core-repo "$(CORE_REPO)",)

install-hooks:
	@bash ~/repos/repo-agent-core/scripts/install-hooks.sh .

check:
	@bash scripts/check.sh
