# RabbitMQ Contract Baseline

This is the shared interface reference between `docura-backend` and `intelligence-service`.

## Command Flow (Java -> Python)
- Exchange: `wf.task.command.exchange`
- Queue: `wf.task.command.queue`
- Routing key: `task.execute`
- Required payload fields:
  - `taskId`
  - `runId`
  - `stepIndex`
  - `taskType`
  - `traceId`
  - `payload`

## Result Flow (Python -> Java)
- Exchange: `wf.task.result.exchange`
- Queue: `wf.task.result.queue`
- Routing key: `task.result`
- Required payload fields:
  - `taskId`
  - `runId`
  - `stepIndex`
  - `nodeName`
  - `status`
  - `traceId`
  - `result`
  - `error`

## Correlation Rules
- `taskId` and `runId` are mandatory for resume correlation.
- `traceId` must be preserved end-to-end.
- `stepIndex` must remain stable between command and result for the same task execution.

## Change Policy
- Any field add/remove/rename requires:
  1. `HANDOFF_BOARD.md` update
  2. `DECISIONS.md` entry
  3. Coordinated implementation in both modules
