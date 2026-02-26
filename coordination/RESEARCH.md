# Internet Research and Applied Patterns

Date: 2026-02-26

## Problem
How to keep two repos (Java orchestrator + Python worker) synchronized when integration changes cross the RabbitMQ boundary.

## Patterns Used

1. Decision log via ADR-style records
- Source: https://adr.github.io/
- Source: https://adr.github.io/madr/
- Why used: Keeps non-obvious cross-project integration decisions explicit with context and consequences.
- Applied as: `coordination/DECISIONS.md`

2. Curated change logging (not raw git log)
- Source: https://keepachangelog.com/en/1.1.0/
- Why used: Cross-service changes need curated, human-readable impact notes.
- Applied as: `coordination/CROSS_PROJECT_LOG.md`

3. Consumer-driven contract testing mindset for service boundaries
- Source: https://docs.pact.io/implementation_guides/python/docs/consumer
- Why used: Reinforces that boundary contracts should be explicit, tested, and version-aware.
- Applied as: `coordination/RABBIT_CONTRACT.md` and required handoff workflow.

4. Standardized PR metadata/checklists
- Source: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/about-issue-and-pull-request-templates
- Why used: Ensures contributors include contract and validation details.
- Applied as: `.github/pull_request_template.md`

5. Optional ownership enforcement
- Source: https://docs.github.com/articles/about-codeowners
- Why noted: CODEOWNERS can enforce reviewer routing later if desired.
- Applied as: Not implemented yet (optional future step).

6. Externalized environment configuration
- Source: https://12factor.net/config
- Why used: Cross-service topology/config belongs in env settings, not hardcoded values.
- Applied as: Captured in contract expectations and module AGENTS alignment.

## Selected System for This Repo
- Root governance: `AGENTS.md`
- Active handoffs: `coordination/HANDOFF_BOARD.md`
- Historical integration changes: `coordination/CROSS_PROJECT_LOG.md`
- Boundary contract baseline: `coordination/RABBIT_CONTRACT.md`
- Decision trail: `coordination/DECISIONS.md`

## Why this is practical
- Lightweight markdown files, no new dependencies.
- Works with current two-repo structure.
- Gives agents one place to coordinate cross-project tasks while preserving module-level coding standards.
