# Corvanta

Corvanta is the root workspace that coordinates two services:

- `docura-backend` (Java 17 + Spring Boot): orchestration API, workflow engine, RabbitMQ producer/consumer
- `intelligence-service` (Python 3.12+): async worker that consumes task commands and publishes task results

RabbitMQ is the handoff boundary between the two services.

## Repository Structure

- Root repository: `git@github.com:sarathkumar365/Corvanta.git`
- Module repository (backend): `git@github.com:sarathkumar365/docura-backend.git`
- Module repository (worker): `git@github.com:sarathkumar365/intelligence-service.git`

## Quick Start

1. Clone the root repository.

```bash
git clone git@github.com:sarathkumar365/Corvanta.git
cd Corvanta
```

2. Fetch module repositories (clone missing modules, update existing modules).

```bash
scripts/bootstrap-modules.sh
```

3. Start local services.

```bash
scripts/dev-services.sh start all
```

4. Check status and logs.

```bash
scripts/dev-services.sh status all
scripts/dev-services.sh logs all
```

## Bootstrap Script

Script: `/Users/sarathkumar/Projects/Corvanta/scripts/bootstrap-modules.sh`

Behavior:
- If `docura-backend` or `intelligence-service` is missing, it clones that repo.
- If module repo exists, it fetches and pulls `main` with `--ff-only`.
- If an existing module is not on `main`, it skips auto-pull and prints what to run manually.

Optional mode:

```bash
scripts/bootstrap-modules.sh --clone-only
```

This mode clones missing repos and does not update already existing repos.

## Run/Restart Services During Development

Script: `/Users/sarathkumar/Projects/Corvanta/scripts/dev-services.sh`

- Start both: `scripts/dev-services.sh start all`
- Restart Java only: `scripts/dev-services.sh restart java`
- Restart Python only: `scripts/dev-services.sh restart python`
- Stop one: `scripts/dev-services.sh stop java` or `stop python`
- Stop both: `scripts/dev-services.sh stop all`

Logs are written in `.run/` and each service log is cleared on every start/restart of that service.

## Notes

- Root coordination docs are under `coordination/`.
- Module-specific standards are in each module's `AGENTS.md`.
- See script-level details in `scripts/DEV_SERVICES.md`.
