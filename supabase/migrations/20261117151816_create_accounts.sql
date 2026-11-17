-- Migration: create_accounts
-- Issue: #12 (P0-03)
-- Backward compatible: yes (new table)
-- Rollback: forward-only; to undo, create a new migration dropping the table (no data yet).

begin;

-- Where the money physically is: MoMo, Cash, BNPL liabilities (plan §3.1, ADR-0010).
create table public.accounts (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null default auth.uid() references auth.users (id) on delete cascade,
  name             text not null,
  type             public.account_type not null default 'asset',
  opening_balance  bigint not null default 0,
  is_default       boolean not null default false,
  archived_at      timestamptz,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  -- Target of same-user composite foreign keys (database conventions §2.3).
  constraint uq_accounts_user_id_id unique (user_id, id),
  constraint ck_accounts_name_length check (length(btrim(name)) between 1 and 60),
  -- Bounded to JS safe integers (code style §2).
  constraint ck_accounts_opening_balance_safe
    check (opening_balance between -9007199254740991 and 9007199254740991),
  -- Sign convention (plan §3.3): assets hold money (≥ 0); a liability's balance is the debt as a
  -- negative number (≤ 0), e.g. Shopee Later −1,200,000.
  constraint ck_accounts_opening_balance_sign
    check ((type = 'asset' and opening_balance >= 0) or (type = 'liability' and opening_balance <= 0))
);

-- At most one default account (MoMo) per user.
create unique index uq_accounts_user_id_default on public.accounts (user_id) where is_default;
-- Active account names are unique per user, case-insensitively.
create unique index uq_accounts_user_id_name on public.accounts (user_id, lower(name))
  where archived_at is null;

create trigger trg_accounts_updated_at
  before update on public.accounts
  for each row execute function public.fn_set_updated_at();

alter table public.accounts enable row level security;
revoke all on table public.accounts from anon;
revoke truncate, references, trigger on table public.accounts from authenticated;

create policy "accounts: select own rows" on public.accounts
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "accounts: insert own rows" on public.accounts
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "accounts: update own rows" on public.accounts
  for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
-- Delete is allowed for unused accounts; foreign keys block deleting referenced ones (use archived_at).
create policy "accounts: delete own rows" on public.accounts
  for delete to authenticated using ((select auth.uid()) = user_id);

commit;
