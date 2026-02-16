.PHONY: review audit test

TARGET ?= .

review:
	@bash .agents/skills/reviewing-code-locally/scripts/local_review.sh

audit:
	@echo "Running audit on $(TARGET)..."
	@echo "TODO: Wire up auditor orchestrator"

test:
	@echo "Running tests..."
	@echo "TODO: AT-1 (SCORECARD.json), AT-4 (Mode A), AT-5 (Mode B), AT-10 (independence)"
