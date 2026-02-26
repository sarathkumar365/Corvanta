# Corvanta Root Agent Guide

## 0. Scope and Intent
- This file governs work started from repository root: `/Users/sarathkumar/Projects/Corvanta`.
- Root-level guidance coordinates changes across two separate codebases.
- Module-specific coding standards remain inside each module's own AGENTS file:
  - `/Users/sarathkumar/Projects/Corvanta/docura-backend/AGENTS.md`
  - `/Users/sarathkumar/Projects/Corvanta/intelligence-service/AGENTS.md`

## 1. Project Map
- `docura-backend` (Java 17 + Spring Boot): workflow orchestrator, API, and RabbitMQ task command publisher/task result consumer.
- `intelligence-service` (Python 3.12+): worker service that consumes task commands, executes processors, and publishes task results.

## 2. Runtime Integration Contract (High-Level)
1. Java publishes `task command` message to RabbitMQ.
2. Python consumes command and executes task logic.
3. Python publishes `task result` message.
4. Java consumes result and resumes workflow.

Critical invariant:
- No direct Java-to-Python calls. RabbitMQ is the handoff boundary.

## 3. Where Agents Must Look First
Before any implementation, read in this order:
1. This file (`/Users/sarathkumar/Projects/Corvanta/AGENTS.md`)
2. `/Users/sarathkumar/Projects/Corvanta/coordination/RABBIT_CONTRACT.md`
3. `/Users/sarathkumar/Projects/Corvanta/coordination/HANDOFF_BOARD.md`
4. Module AGENTS for the target module(s)

## 4. Required Cross-Project Workflow
Use this when a change in one module may require a matching change in the other module.

1. Define scope
- Identify if change touches: message schema, routing/topology, correlation IDs, processor/task type naming, or failure semantics.

2. Log intent
- Add an item in `coordination/HANDOFF_BOARD.md` with status `Proposed` and the date and time.

3. Implement first-side change
- Apply changes in the source module.
- Add entry to `coordination/CROSS_PROJECT_LOG.md` with what changed and why.

4. Create counterpart task
- In `coordination/HANDOFF_BOARD.md`, add or update counterpart task for the second module.
- Set status `Blocked` only with explicit blocker and owner.

5. Finalize contract state
- If message contract changed, update `coordination/RABBIT_CONTRACT.md` and append a decision in `coordination/DECISIONS.md`.

6. Close loop
- Mark board item `Done` only after both modules are updated and validated.

## 5. Ownership and Truth Sources
- Coding style and architecture rules: each module's own `AGENTS.md`.
- Cross-project status: `coordination/HANDOFF_BOARD.md`.
- Cross-project change history: `coordination/CROSS_PROJECT_LOG.md`.
- Message contract baseline: `coordination/RABBIT_CONTRACT.md`.
- Decisions and tradeoffs: `coordination/DECISIONS.md`.

## 6. Minimum Definition of Done for Cross-Project Changes
- Both impacted modules updated, or explicit open handoff item exists with owner/date.
- Handoff board item is not left ambiguous (`Proposed`, `In Progress`, `Blocked`, or `Done`).
- Contract doc updated for any message/topology change.
- Validation commands from impacted module AGENTS have been run and recorded in PR/task notes.
