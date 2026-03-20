.PHONY: review audit audit-deep audit-quick test validate help install-hooks check work work-close health

TARGET ?= .
OUTPUT_DIR ?= audit_output

help:
	@echo "repo-auditor — Machine-readable repository health scorer"
	@echo ""
	@echo "Targets:"
	@echo "  make audit TARGET=<path>       Standard audit (deterministic)"
	@echo "  make audit-deep TARGET=<path>  Deep audit with LLM domain agents"
	@echo "  make audit-quick TARGET=<path> Quick pre-scan only"
	@echo "  make check                     Pre-commit gate (shellcheck + inventory)"
	@echo "  make test                      Run all tests"
	@echo "  make validate                  Validate schemas"
	@echo "  make review                    Code review staged changes"
	@echo "  make work DESC=\"...\"           Open work contract"
	@echo "  make work-close WORK=<dir>     Close work contract"
	@echo "  make install-hooks             Install git hooks from core"

review:
	@bash .agents/skills/reviewing-code-locally/scripts/local_review.sh

audit:
	@echo "=== repo-auditor: Standard Mode (deterministic) ==="
	@mkdir -p $(OUTPUT_DIR)
	@bash scripts/repo-auditor.sh "$(TARGET)" "$(OUTPUT_DIR)"
	@echo "=== Audit complete. Artifacts in $(OUTPUT_DIR)/ ==="

audit-deep:
	@echo "=== repo-auditor: Deep Mode ==="
	@echo "TODO: Wire deep mode with LLM domain subagents"
	@mkdir -p $(OUTPUT_DIR)
	@bash scripts/repo-auditor.sh "$(TARGET)" "$(OUTPUT_DIR)"

audit-quick:
	@echo "=== repo-auditor: Quick Pre-Scan ==="
	@mkdir -p $(OUTPUT_DIR)
	@bash .agents/skills/pre-scanning/scripts/pre-scan-target.sh "$(TARGET)" "$(OUTPUT_DIR)"

test:
	@echo "=== Running auditor test suite ==="
	@bash tests/test-auditor-schemas.sh
	@bash tests/test-detect-closeout-control-drift.sh
	@echo ""
	@echo "=== All tests passed ==="

validate:
	@for s in schemas/*.schema.json; do \
		python3 -c "import json; json.load(open('$$s'))" && echo "  ✓ $$(basename $$s)" || echo "  ✗ $$(basename $$s)"; \
	done

install-hooks:
	@bash ~/repos/repo-agent-core/scripts/install-hooks.sh .

check:
	@bash scripts/check.sh

work:
	@bash scripts/work-init.sh "$(DESC)"

work-close:
	@bash scripts/work-close.sh "$(WORK)"

health:
	@echo "=== Operations Health (last 5 entries) ==="
	@if [ -f work/OPERATIONS_LEDGER.jsonl ]; then \
		tail -5 work/OPERATIONS_LEDGER.jsonl | python3 -c "import sys,json; entries=[json.loads(l) for l in sys.stdin]; print(f'Entries: {len(entries)}'); [print(f'  {e.get(\"timestamp\",\"?\")}: {e.get(\"event_type\",\"?\")} score={e.get(\"data\",{}).get(\"composite_score\",\"?\")}') for e in entries]" 2>/dev/null || echo "  (parse error)"; \
	else \
		echo "  No operations ledger yet (work/OPERATIONS_LEDGER.jsonl)"; \
	fi
