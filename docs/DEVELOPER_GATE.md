# Developer Gate

This guide is for engineers who want to run and manage Corvanta locally from the root workspace.

`docura-backend` and `intelligence-service` are external repositories managed from this root workspace via `corvanta bootstrap`.

## 1) Prerequisites

Corvanta has two modules, each with its own setup requirements.

Check prerequisites in:

- `docura-backend` module docs/README
- `intelligence-service` module docs/README

You must also start required local infrastructure (RabbitMQ, Postgres) as described in module docs.

## 2) Clone and Bootstrap

```bash
git clone git@github.com:sarathkumar365/Corvanta.git
cd Corvanta
```

Fetch both module repositories from root:

```bash
./scripts/corvanta bootstrap
```

## 3) CLI Setup (Optional but Recommended)

To run `corvanta` from anywhere:

```bash
echo "export PATH=\"$(pwd)/scripts:\$PATH\"" >> ~/.zshrc
source ~/.zshrc
```

If you skip PATH setup, use full path commands:

```bash
./scripts/corvanta <command>
```

## 4) Service Lifecycle (From Root)

Start everything:

```bash
corvanta start
```

Check health:

```bash
corvanta health
```

Stop services:

```bash
corvanta stop
```

## 5) Logs and Visibility

Live logs:

```bash
corvanta logs all --follow
```

Service-specific logs:

```bash
corvanta logs java --follow
corvanta logs python --follow
```

Start and immediately stream logs:

```bash
corvanta start-with-logs
```

## 6) Command Reference

```bash
corvanta start
corvanta stop
corvanta health
corvanta logs [all|java|python] [--follow|--no-follow]
corvanta start-with-logs
corvanta bootstrap [--clone-only]
```

## 7) Notes

- Runtime files are written under `.run/`.
- `start/stop/health` automatically clean stale PID files and conflicting old processes.
- Logs are colorized by default in `corvanta logs`.
- Internal cleanup actions are tracked in `.run/manager.log`.

For deeper script internals and behavior details:

- `scripts/DEV_SERVICES.md`
