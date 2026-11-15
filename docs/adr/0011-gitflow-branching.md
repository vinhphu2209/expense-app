# ADR-0011: Use GitFlow for branching and releases

- **Status:** Accepted
- **Date:** 2026-11-15
- **Deciders:** Phú
- **Related:** [branching conventions](../conventions/branching.md), [ADR-0012](0012-dev-uat-prod-environments.md)

## Context

The project should follow a professional, visible development process with separate dev, UAT and production environments. Phú wants an explicit acceptance step (UAT on a real iPhone) before anything reaches the production app that holds real financial data. Two AI agents produce work in parallel; one human releases.

## Decision

We will use **GitFlow**:

- Long-lived branches: `main` (production, tagged releases) and `develop` (integration, deployed to UAT).
- Short-lived `feature/`, `bugfix/`, `chore/` and `docs/` branches are squash-merged into `develop`.
- `release/x.y.z` and `hotfix/x.y.z` are merged into `main` with a merge commit, then back-merged into `develop`.

Versions follow SemVer.

## Options considered

| Option | Pros | Cons |
| --- | --- | --- |
| **GitFlow (chosen)** | Explicit release/UAT stage maps 1:1 to environments; familiar to reviewers; hotfix path for prod | More branches and back-merges; slower than trunk-based |
| Trunk-based (`main` = UAT, tags = prod) | Simplest, fastest feedback | No separate stabilisation branch; UAT and new work mix |
| GitHub Flow | Very simple | No UAT stage at all |

## Consequences

- ✅ Each environment has a branch: `develop` and `release/*` go to UAT, `main` goes to prod.
- ✅ Production history on `main` reads as a list of releases.
- ⚠️ Every release/hotfix needs a back-merge; forgetting one causes drift.
- ⚠️ There is one shared UAT database, so `db:migration` PRs are frozen while a release is open.
- 🔁 Repo rulesets, PR-title lint and release steps are documented in the branching conventions.
