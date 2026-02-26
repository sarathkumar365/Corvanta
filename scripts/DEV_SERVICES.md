# Dev Services Script Guide

This guide is only for:
- `/Users/sarathkumar/Projects/Corvanta/scripts/dev-services.sh`
- `/Users/sarathkumar/Projects/Corvanta/scripts/corvanta`

## Preferred Command

Use `corvanta` as the primary CLI. It wraps `dev-services.sh` and adds better log views.

```bash
corvanta start all
corvanta status all
corvanta logs java --app --follow
corvanta stop all
```

If `corvanta` is not in PATH yet:

```bash
/Users/sarathkumar/Projects/Corvanta/scripts/corvanta start all
```

## What this script manages

- `java` service: `docura-backend`
- `python` service: `intelligence-service`

It gives one command surface for both services, while still letting you restart only one service after changes.

## Commands

Run from repo root:

```bash
cd /Users/sarathkumar/Projects/Corvanta
```

Start/stop/restart/status:

```bash
scripts/dev-services.sh start [all|java|python]
scripts/dev-services.sh stop [all|java|python]
scripts/dev-services.sh restart [all|java|python]
scripts/dev-services.sh status [all|java|python]
```

Logs:

```bash
scripts/dev-services.sh logs [all|java|python]
scripts/dev-services.sh logs [all|java|python] --follow
```

Wrapper CLI (`corvanta`) commands:

```bash
corvanta start [all|java|python]
corvanta stop [all|java|python]
corvanta restart [all|java|python]
corvanta status [all|java|python]
corvanta logs [all|java|python] [--follow] [--app] [--errors]
corvanta bootstrap [--clone-only]
```

Common examples:

```bash
scripts/dev-services.sh start all
scripts/dev-services.sh restart java
scripts/dev-services.sh restart python
scripts/dev-services.sh stop all
scripts/dev-services.sh status all
scripts/dev-services.sh logs java --follow

corvanta start all
corvanta restart java
corvanta logs java --app --follow
corvanta logs all --errors --follow
corvanta stop all
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

If you run `start all` multiple times, it does **not** create duplicate processes in normal use.

Why:
- Before start, script checks PID file + live process (`kill -0`).
- If already running, it prints `already running` and skips launching another process.

So 2-3 repeated `start all` calls should still leave one Java process and one Python process.

## Per-service control (important)

- `stop java` stops only Java.
- `stop python` stops only Python.
- `restart java` restarts only Java.
- `restart python` restarts only Python.
- `stop all` / `restart all` manage both.

Use this for fast dev loop:
- Change Java -> `restart java`
- Change Python -> `restart python`

## Log behavior per start/restart

Each service log is cleared right before that service starts.

So:
- `start all` clears both logs.
- `restart java` clears only Java log.
- `restart python` clears only Python log.

This keeps logs easy to map to the latest launch attempt.

## Log view improvements with `corvanta`

`corvanta logs` adds readability helpers:

- `--app`: app-focused logs (reduces framework noise)
  - Java: suppresses common Spring/Hibernate/Hikari/Flyway noise patterns
  - Python: highlights app/task flow lines
- `--errors`: show only `ERROR`/`WARN`/exception-like lines
- colorized output:
  - `ERROR` and exceptions: red
  - `WARN`: yellow
  - `INFO`: green

Examples:

```bash
corvanta logs java --app --follow
corvanta logs python --app --follow
corvanta logs all --errors --follow
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
RABBITMQ_USERNAME=guest RABBITMQ_PASSWORD=guest scripts/dev-services.sh start all
```

## Python environment bootstrap

On Python start, script ensures:
- `.venv` exists (creates if missing)
- dependencies are installed if required imports are missing

This makes first-run setup easier.

## Recommended daily flow

```bash
scripts/dev-services.sh start all
scripts/dev-services.sh status all

# after code change
scripts/dev-services.sh restart java
# or
scripts/dev-services.sh restart python

# debug
scripts/dev-services.sh logs java --follow
scripts/dev-services.sh logs python --follow

# end session
scripts/dev-services.sh stop all
```

## Troubleshooting

1. Service says started but exits soon:
- check `scripts/dev-services.sh logs <service>`

2. Python RabbitMQ auth error (`ACCESS_REFUSED`):
- credentials mismatch between worker/env and broker
- align `RABBITMQ_USERNAME`/`RABBITMQ_PASSWORD`

3. Java DB connection error:
- verify Postgres is running and matches backend DB config

4. Port conflict (for Java on 8080):
- stop existing process using 8080 or change server port

## Notes

- This script is for local development process management.
- It is intentionally simple: PID files + background processes + log files.
