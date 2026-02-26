# Corvanta

## The Autonomous HR Operations Agent for Real Estate Brokerages

Corvanta helps brokerages automate HR operations that usually consume time, create compliance risk, and slow growth.

It turns complex HR workflows into intelligent, goal-driven automation across onboarding, compliance, and day-to-day HR execution.

## ✨ Positioning

**Corvanta is the autonomous HR agent that streamlines hiring, compliance, and operations for real estate brokerages, turning complex HR workflows into intelligent automation.**

## 🎯 Why Corvanta Exists

Real estate brokerages face a unique operations problem:

- High agent turnover and frequent onboarding cycles
- Licensing and compliance requirements that change by market
- Manual HR tasks spread across tools, docs, and teams
- Time lost on repetitive coordination instead of strategic HR work

## ⚙️ What Corvanta Does

Corvanta acts like an execution layer for brokerage HR teams.

It helps automate and coordinate:

- New agent onboarding workflows
- Licensing and compliance checks
- Contract and document handling
- HR task scheduling and follow-through
- Operational visibility and reporting

## 🚀 What Makes It Different

- **Built for real estate brokerages:** Designed around brokerage-specific HR and compliance realities
- **Autonomous workflow behavior:** Handles task flow intelligently, including exceptions and handoffs
- **End-to-end operational scope:** Covers onboarding through ongoing compliance operations
- **Scales with brokerage growth:** Supports both smaller teams and multi-office organizations

## 🧠 Product Structure

Corvanta runs with two core backend services:

- **Orchestration Backend (`docura-backend`)**
  - Coordinates workflows, tracks progress, and drives execution
- **Intelligence Backend (`intelligence-service`)**
  - Executes specialized task processing and returns results to orchestration

In simple terms: one service manages workflow decisions, the other executes specialized work.

## 🏷️ Tagline

**Corvanta — your brokerage HR, automated, intelligent, and compliant.**

## 🧭 Get Started

For full setup, local run commands, and service lifecycle operations (`start`, `stop`, `health`, `logs`), go to:

- If you are evaluating Corvanta, this README is enough for product context.
- If you are running Corvanta locally, start with Developer Gate.

- 📘 [Developer Gate](docs/DEVELOPER_GATE.md)

## 🔗 Repositories

- Root workspace: `git@github.com:sarathkumar365/Corvanta.git`
- Orchestration backend: `git@github.com:sarathkumar365/docura-backend.git`
- Intelligence backend: `git@github.com:sarathkumar365/intelligence-service.git`

Note: backend repositories are external module repos and are fetched locally via `corvanta bootstrap`.
