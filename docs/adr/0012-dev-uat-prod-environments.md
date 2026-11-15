# ADR-0012: Run dev / uat / prod on free tiers

- **Status:** Accepted
- **Date:** 2026-11-15
- **Deciders:** Phú
- **Related:** [environments](../operations/environments.md), [ADR-0007](0007-supabase-backend.md), [ADR-0011](0011-gitflow-branching.md)

## Context

We want three environments, but the budget is zero:

- The Supabase free plan allows two active projects, pauses inactive projects and has no point-in-time recovery.
- Vercel Hobby offers one Production environment plus Preview deployments.
- Production holds real personal financial data.

## Decision

We will run:

- **dev**: local Supabase in Docker, ephemeral Supabase in CI, and Vercel PR previews that read the UAT database.
- **uat**: Supabase project `expense-uat`, plus Vercel Preview deployments of `develop`, `release/*` and `hotfix/*`.
- **prod**: Supabase project `expense-prod` and Vercel Production. GitHub Actions deploys it on a `v*` tag after manual approval in the `production` GitHub Environment, and migrates the database before deploying the app.

## Options considered

| Option | Pros | Cons |
| --- | --- | --- |
| **Local dev + 2 hosted projects (chosen)** | Free; prod data is fully isolated | No hosted dev DB; previews and releases share the UAT DB |
| 3 hosted Supabase projects | Clean separation | Exceeds the free plan |
| Supabase Branching | Per-PR databases | Paid feature |

## Consequences

- ✅ Prod data never leaves prod; UAT uses fictional seed data only.
- ✅ Migrations are tested three times (local, CI, UAT) before prod.
- ⚠️ Migrations must be backward compatible (expand/contract).
- ⚠️ UAT pauses after inactivity; resume it before testing.
- ⚠️ We own backups: nightly encrypted `pg_dump`.
- 🔁 If the project moves to paid plans, revisit this ADR and consider a hosted dev database or Supabase Branching.
