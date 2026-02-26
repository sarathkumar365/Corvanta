# Developer Gate

This guide is for engineers who want to run and manage Corvanta locally from the root workspace.

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
corvanta start all
```

Check status:

```bash
corvanta status all
```

Restart only what changed:

```bash
corvanta restart java
corvanta restart python
```

Stop one or all:

```bash
corvanta stop java
corvanta stop python
corvanta stop all
```

## 5) Logs and Visibility

Live logs:

```bash
corvanta logs all --follow
```

App-focused logs:

```bash
corvanta logs java --app --follow
corvanta logs python --app --follow
```

Errors/warnings only:

```bash
corvanta logs all --errors --follow
```

## 6) Command Reference

```bash
corvanta start [all|java|python]
corvanta stop [all|java|python]
corvanta restart [all|java|python]
corvanta status [all|java|python]
corvanta logs [all|java|python] [--follow] [--app] [--errors]
corvanta bootstrap [--clone-only]
```

## 7) Notes

- Runtime files are written under `.run/`.
- Repeated `start all` does not intentionally create duplicate service processes.
- Each service log is cleared when that service is started/restarted.

For deeper script internals and behavior details:

- `scripts/DEV_SERVICES.md`
