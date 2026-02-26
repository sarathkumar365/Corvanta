# Dev Services Script Guide

This guide is only for:
- `/Users/sarathkumar/Projects/Corvanta/scripts/dev-services.sh`
- `/Users/sarathkumar/Projects/Corvanta/scripts/corvanta`

## Preferred Command

Use `corvanta` as the primary CLI. It wraps `dev-services.sh` and provides the full runtime workflow.

```bash
corvanta start
corvanta health
corvanta logs all --follow
corvanta stop
```

If `corvanta` is not in PATH yet:

```bash
/Users/sarathkumar/Projects/Corvanta/scripts/corvanta start
```

## What this script manages

- `java` service: `docura-backend`
- `python` service: `intelligence-service`

It gives one command surface for both services with automatic stale-process cleanup built in.

## Commands

Run from repo root:

```bash
cd /Users/sarathkumar/Projects/Corvanta
```

Internal runtime script (`dev-services.sh`) commands:

```bash
scripts/dev-services.sh start
scripts/dev-services.sh stop
scripts/dev-services.sh health
```

Wrapper CLI (`corvanta`) commands:

```bash
corvanta start
corvanta stop
corvanta health
corvanta logs [all|java|python] [--follow|--no-follow]
corvanta start-with-logs
corvanta bootstrap [--clone-only]
```

Examples:

```bash
corvanta start
corvanta health
corvanta logs java --follow
corvanta logs python --follow
corvanta logs all --no-follow
corvanta start-with-logs
corvanta stop
```

## How this works in the terminal

The script uses background execution (`nohup ... &`) for each service.

That means:
- Service starts in background.
- Terminal prompt returns immediately.
- You can keep using the same terminal.
- Service output goes to log files, not to your live terminal.

## Where runtime files are stored

All runtime artifacts are under:
- `/Users/sarathkumar/Projects/Corvanta/.run/`

Files:
- `docura-backend.pid`
- `intelligence-service.pid`
- `docura-backend.log`
- `intelligence-service.log`

`.run/` is ignored by git.

## Duplicate process safety (important)

If you run `start` repeatedly, it does **not** intentionally create duplicate service processes in normal use.

Why:
- Start automatically checks and cleans stale PID files.
- Start checks for existing conflicting Java/Python processes and cleans them before launching.

## Log behavior per start

Each service log is cleared right before that service starts.

- `start` clears both Java and Python logs.
- `start-with-logs` starts services and immediately tails logs.
- `corvanta logs` is colorized by default:
  - `ERROR` and exceptions: red
  - `WARN`: yellow
  - `INFO`: green

Examples:

```bash
corvanta logs java --follow
corvanta logs python --follow
corvanta logs all --no-follow
```

## RabbitMQ credentials and env behavior

The script passes RabbitMQ env to both services using shared variables:
- `RABBITMQ_HOST` (default `localhost`)
- `RABBITMQ_PORT` (default `5672`)
- `RABBITMQ_USERNAME` (default `default`)
- `RABBITMQ_PASSWORD` (default `default`)
- `RABBITMQ_VHOST` (default `/`)

Override per run if needed:

```bash
RABBITMQ_USERNAME=guest RABBITMQ_PASSWORD=guest scripts/dev-services.sh start
```

## Python environment bootstrap

On Python start, script ensures:
- `.venv` exists (creates if missing)
- dependencies are installed if required imports are missing

This makes first-run setup easier.

## Recommended daily flow

```bash
corvanta start
corvanta health
corvanta logs all --follow
corvanta stop
```

## Troubleshooting

1. Service says started but exits soon:
- check log files under `.run/`
- check cleanup/actions in `.run/manager.log`

2. Python RabbitMQ auth error (`ACCESS_REFUSED`):
- credentials mismatch between worker/env and broker
- align `RABBITMQ_USERNAME`/`RABBITMQ_PASSWORD`

3. Java DB connection error:
- verify Postgres is running and matches backend DB config

4. Port conflict (for Java on 8080):
- rerun `corvanta start` (it auto-cleans conflicting process when possible)

## Notes

- This script is for local development process management.
- It is intentionally simple: PID files + background processes + log files.
