-- Migration: create_transactions
-- Issue: #12 (P0-03)
-- Backward compatible: yes (new table)
-- Rollback: forward-only; to undo, create a new migration dropping the table (no data yet).

begin;

-- Money events (plan §3.3). Transfers are not spending and never touch envelopes (ADR-0003).
-- Never hard-deleted: soft delete via deleted_at; every update is audited (create_audit_log).
create table public.transactions (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null default auth.uid() references auth.users (id) on delete cascade,
  occurred_at    timestamptz not null default now(),
  type           public.txn_type not null,
  amount         bigint not null,
  account_id     uuid not null,
  to_account_id  uuid,
  envelope_id    uuid,
  note           text,
  merchant       text,
  tags           text[] not null default '{}',
  source         public.txn_source not null default 'quickadd',
  status         public.txn_status not null default 'confirmed',
  -- Idempotency key from the offline queue / Shortcuts (P1-02, P3-01, P3-03).
  client_id      uuid,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  deleted_at     timestamptz,
  constraint uq_transactions_user_id_id unique (user_id, id),
  constraint uq_transactions_user_id_client_id unique (user_id, client_id),
  constraint fk_transactions_account
    foreign key (user_id, account_id) references public.accounts (user_id, id),
  constraint fk_transactions_to_account
    foreign key (user_id, to_account_id) references public.accounts (user_id, id),
  constraint fk_transactions_envelope
    foreign key (user_id, envelope_id) references public.envelopes (user_id, id),
  -- Amounts are positive integer VND within JS safe integers (ADR-0004, code style §2).
  constraint ck_transactions_amount_positive check (amount between 1 and 9007199254740991),
  -- A transfer has exactly one destination account, and only transfers have one.
  constraint ck_transactions_transfer_has_to_account check ((type = 'transfer') = (to_account_id is not null)),
  constraint ck_transactions_transfer_distinct_accounts
    check (to_account_id is null or to_account_id <> account_id),
  -- Only expenses use envelopes; a confirmed expense must have one (pending = inbox).
  constraint ck_transactions_envelope_only_on_expense check (type = 'expense' or envelope_id is null),
  constraint ck_transactions_expense_has_envelope
    check (type <> 'expense' or envelope_id is not null or status = 'pending'),
  constraint ck_transactions_pending_only_expense check (status = 'confirmed' or type = 'expense'),
  constraint ck_transactions_note_length check (note is null or length(note) <= 200),
  constraint ck_transactions_merchant_length check (merchant is null or length(merchant) <= 120)
);

create index idx_transactions_user_id_occurred_at on public.transactions (user_id, occurred_at desc)
  where deleted_at is null;
create index idx_transactions_user_id_envelope_id on public.transactions (user_id, envelope_id)
  where envelope_id is not null;
create index idx_transactions_user_id_account_id on public.transactions (user_id, account_id);
create index idx_transactions_user_id_to_account_id on public.transactions (user_id, to_account_id)
  where to_account_id is not null;

create trigger trg_transactions_updated_at
  before update on public.transactions
  for each row execute function public.fn_set_updated_at();

alter table public.transactions enable row level security;
revoke all on table public.transactions from anon;
revoke truncate, references, trigger on table public.transactions from authenticated;

create policy "transactions: select own rows" on public.transactions
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "transactions: insert own rows" on public.transactions
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "transactions: update own rows" on public.transactions
  for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
-- No delete policy: soft delete only (set deleted_at).

commit;
