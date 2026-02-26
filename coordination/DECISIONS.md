# Cross-Project Decisions (ADR-Style)

Use this file for important integration decisions.

## Entry Template
- ID:
- Date:
- Status: `Proposed | Accepted | Superseded`
- Context:
- Decision:
- Consequences:
- Follow-up:

---

## ADR-001
- ID: ADR-001
- Date: 2026-02-26
- Status: Accepted
- Context: Work is split across two repositories with asynchronous integration points; context can be lost between module-specific changes.
- Decision: Add a root coordination layer (`AGENTS.md` + `coordination/*`) to manage handoffs, shared message contracts, and decision history.
- Consequences: Slight documentation overhead, but clearer accountability and lower risk of contract drift.
- Follow-up: Enforce board/log updates on every cross-project change.
