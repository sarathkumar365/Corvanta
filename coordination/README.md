# Coordination Workspace

This folder is the shared orchestration layer for multi-repo changes.

## Files
- `HANDOFF_BOARD.md`: active cross-project tasks and status.
- `CROSS_PROJECT_LOG.md`: append-only log of meaningful integration changes.
- `RABBIT_CONTRACT.md`: current message contract and topology baseline.
- `DECISIONS.md`: ADR-style decisions affecting both modules.
- `templates/HANDOFF_ENTRY_TEMPLATE.md`: reusable handoff entry format.

## Update Rules
1. Update `HANDOFF_BOARD.md` when work is planned or status changes.
2. Update `CROSS_PROJECT_LOG.md` for each completed cross-boundary change.
3. Update `RABBIT_CONTRACT.md` whenever queue, exchange, routing key, or payload contract changes.
4. Add `DECISIONS.md` entries for non-trivial tradeoffs.
