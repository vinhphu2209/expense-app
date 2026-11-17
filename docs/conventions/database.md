# Database Conventions (Supabase / Postgres)

> Owner: Claude Code. Related: [files & folders §3.8](files-and-folders.md#38-database-migration) · [ADR-0007](../adr/0007-supabase-backend.md) · [environments](../operations/environments.md)

---

## 1. Naming

| Object | Rule | Example |
| --- | --- | --- |
| Tables | snake_case, **plural** | `transactions`, `budget_lines` |
| Columns | snake_case, singular | `occurred_at`, `envelope_id` |
| Primary key | `id uuid default gen_random_uuid()`; pure link tables may use a composite key named `pk_<table>` | `pk_budget_lines` |
| Foreign key column | `<singular_table>_id` | `account_id` |
| Foreign key constraint | `fk_<table>_<referenced>` (composite same-user FKs) | `fk_transactions_account` |
| Timestamps | `<verb>_at timestamptz` | `created_at`, `closed_at`, `deleted_at` |
| Booleans | `is_` / `has_` prefix, or an adjective | `is_default`, `rollover` |
| Money | `bigint`, name says what it is | `amount`, `target_amount`, `income_planned` |
| Enums | snake_case type, lowercase values | `txn_type` → `'expense'` |
| Views | `v_<name>` | `v_envelope_month` |
| Functions | `fn_<verb>_<object>` | `fn_close_month` |
| Triggers | `trg_<table>_<event>` | `trg_transactions_audit` |
| Indexes | `idx_<table>_<columns>` | `idx_transactions_user_id_occurred_at` |
| Unique constraints | `uq_<table>_<columns>` | `uq_transactions_user_id_client_id` |
| Check constraints | `ck_<table>_<rule>` | `ck_transactions_amount_positive` |
| RLS policies | `"<table>: <action> own rows"` | `"transactions: select own rows"` |

## 2. Table rules

1. **Every user-owned table has `user_id uuid not null default auth.uid() references auth.users on delete cascade`**, including child tables (`budget_lines`, `transaction_splits`, `envelope_aliases`). This keeps RLS policies simple and uniform.
2. **RLS is enabled in the same migration that creates the table.** A table without RLS fails review.
3. Cross-table references must stay within one user. Use composite foreign keys `(user_id, account_id) → accounts(user_id, id)` (requires `unique (user_id, id)` on the parent) or a check trigger.
4. Money is `bigint`. Never `numeric`, `real`, `double precision` or `money`. Percentages may be `numeric(5,2)`.
5. All timestamps are `timestamptz`. Month keys are `date` set to day 1, computed in `Asia/Ho_Chi_Minh`.
6. Transactions are never hard-deleted: `deleted_at` + `audit_log` row ([ADR-0004](../adr/0004-money-as-integer-vnd.md) consequences, PLAN §3.7).
7. `created_at default now()` on every table. `updated_at` is maintained by the shared trigger `trg_<table>_updated_at` (which also pins `created_at`). Insert-only tables (`envelope_movements`, `audit_log`) have no `updated_at`.
8. Secure defaults are set once in the first migration: `anon` gets nothing on new `public` objects, clients get no `TRUNCATE`/`REFERENCES`/`TRIGGER`, and new functions are executable by nobody until a migration grants `EXECUTE` explicitly. Tables that must never be deleted by clients also revoke `DELETE` (not only omit the policy).

## 3. Migration file template

```sql
-- Migration: create_transactions
-- Issue: #23 (P0-03)
-- Backward compatible: yes
-- Rollback: forward-only; to undo, create a new migration dropping the table (no data yet).

begin;

create table public.transactions (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users on delete cascade,
  amount      bigint not null,
  -- ...
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  deleted_at  timestamptz,
  constraint ck_transactions_amount_positive check (amount > 0)
);

create index idx_transactions_user_id_occurred_at on public.transactions (user_id, occurred_at desc);

alter table public.transactions enable row level security;

create policy "transactions: select own rows" on public.transactions
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "transactions: insert own rows" on public.transactions
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "transactions: update own rows" on public.transactions
  for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
-- no delete policy: soft delete only

commit;
```

`(select auth.uid())` instead of `auth.uid()` lets Postgres cache the value per statement (Supabase RLS performance guidance).

## 4. Migration rules

1. Create migrations only with `supabase migration new <name>` ([naming](files-and-folders.md#38-database-migration)).
2. **Never edit a migration once it is merged into `develop`.** Fix forward with a new migration.
3. **Expand → migrate → contract.** Every migration must be backward compatible with the currently deployed app, because the database is migrated before the app deploys ([environments §4](../operations/environments.md#4-database-migrations)). Breaking changes take two releases:
   - Release N: add new column/table, dual-write, backfill.
   - Release N+1: switch reads, drop old column.
4. One concern per migration. Schema and large data backfills go in separate migrations.
5. Migration + `pnpm db:types` output + Zod schema changes go in one commit.
6. Destructive statements (`drop`, `alter type ... drop`, `truncate`) require a `-- DESTRUCTIVE:` comment explaining why, and, if they can lose existing real data, Phú's explicit answer on a `needs-decision` question.
7. PRs with migrations get the `db:migration` label and are not merged into `develop` while a `release/*` branch is open.

## 5. Views & functions

- Views: `create view ... with (security_invoker = true)`, so RLS of the querying user applies. Without it, a view runs as its owner and leaks other users' rows.
- Every view filters `deleted_at is null` and excludes `status = 'pending'` from spending (PLAN §4).
- Functions default to `security invoker`. `security definer` requires a comment explaining why, `set search_path = ''`, fully qualified names (`public.transactions`), and an explicit `auth.uid()` check inside. **Exception:** trigger functions that only copy `old`/`new` and take `user_id` from that row (e.g. `fn_audit_transaction`) have no `auth.uid()` check, because they must also run for service-role writes and cascades; their `EXECUTE` is revoked from clients.
- Business rules that must be atomic (month close) are a pure TS function (tested) **plus** one Postgres function that applies the result in one transaction.

## 6. Seed data

- `supabase/seed.sql` is idempotent (`on conflict do nothing`) and contains **only** fictional data: the November envelope template with round numbers, no real balances.
- UAT uses the same seed. Production is never seeded except reference data created through the app.

## 7. Tests (pgTAP)

Location `supabase/tests/`, run with `supabase test db`. Required for each table:

- RLS: user A cannot select/insert/update user B's rows; anon has no access.
- Constraints: each `check` constraint rejects an invalid row.
- Views: numbers match a hand-calculated fixture month.

Numbering: `000–099` schema/RLS, `100–199` views, `200–299` functions.
