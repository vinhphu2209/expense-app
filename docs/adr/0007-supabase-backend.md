# ADR-0007: Use Supabase (Postgres, Auth, RLS) as the backend

- **Status:** Accepted
- **Date:** 2026-11-15
- **Deciders:** Phú
- **Related:** formerly D6 in `docs/DECISIONS.md` / PLAN §1

## Context

A solo project needs a relational database, authentication and per-user security with almost no ops work and zero cost. Postgres also allows a later Power BI connection.

## Decision

We will use **Supabase**: Postgres with Row Level Security on every table, Supabase Auth, and the Supabase CLI for local development and migrations.

## Consequences

- ✅ Free tier, real Postgres, SQL views, RLS enforced in the database.
- ⚠️ Free-tier limits (2 projects, pausing, no PITR) shape the environment design (ADR-0012).
- ⚠️ Vendor coupling for Auth; data itself stays portable Postgres.
