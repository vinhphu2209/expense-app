-- Migration: create_envelopes
-- Issue: #12 (P0-03)
-- Backward compatible: yes (new tables)
-- Rollback: forward-only; to undo, create a new migration dropping the tables (no data yet).

begin;

-- Envelope groups: Fixed Expenses, Living Expenses, … (plan §3.2, ADR-0003).
create table public.envelope_groups (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users (id) on delete cascade,
  name        text not null,
  sort_order  integer not null default 0,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  constraint uq_envelope_groups_user_id_id unique (user_id, id),
  constraint ck_envelope_groups_name_length check (length(btrim(name)) between 1 and 60)
);

create unique index uq_envelope_groups_user_id_name on public.envelope_groups (user_id, lower(name));

-- Envelopes have stable ids; names are labels only (ADR-0006).
create table public.envelopes (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null default auth.uid() references auth.users (id) on delete cascade,
  group_id       uuid not null,
  name           text not null,
  -- true = fund: leftover carries over and the envelope has a running balance (plan §3.2).
  rollover       boolean not null default false,
  target_amount  bigint,
  description    text,
  icon           text,
  sort_order     integer not null default 0,
  archived_at    timestamptz,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  constraint uq_envelopes_user_id_id unique (user_id, id),
  constraint fk_envelopes_group
    foreign key (user_id, group_id) references public.envelope_groups (user_id, id),
  constraint ck_envelopes_name_length check (length(btrim(name)) between 1 and 60),
  -- Targets only make sense for funds.
  constraint ck_envelopes_target_only_for_funds
    check (target_amount is null or (rollover and target_amount between 1 and 9007199254740991)),
  constraint ck_envelopes_description_length check (description is null or length(description) <= 200)
);

create unique index uq_envelopes_user_id_name on public.envelopes (user_id, lower(name))
  where archived_at is null;
create index idx_envelopes_user_id_group_id on public.envelopes (user_id, group_id);

-- Old sheet names → envelope (Health, HealthFund, ML → Dating, …) for imports and search (plan §7).
create table public.envelope_aliases (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null default auth.uid() references auth.users (id) on delete cascade,
  envelope_id  uuid not null,
  alias        text not null,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  constraint fk_envelope_aliases_envelope
    foreign key (user_id, envelope_id) references public.envelopes (user_id, id) on delete cascade,
  constraint ck_envelope_aliases_alias_length check (length(btrim(alias)) between 1 and 60)
);

create unique index uq_envelope_aliases_user_id_alias on public.envelope_aliases (user_id, lower(alias));

create trigger trg_envelope_groups_updated_at
  before update on public.envelope_groups
  for each row execute function public.fn_set_updated_at();
create trigger trg_envelopes_updated_at
  before update on public.envelopes
  for each row execute function public.fn_set_updated_at();
create trigger trg_envelope_aliases_updated_at
  before update on public.envelope_aliases
  for each row execute function public.fn_set_updated_at();

alter table public.envelope_groups enable row level security;
alter table public.envelopes enable row level security;
alter table public.envelope_aliases enable row level security;

revoke all on table public.envelope_groups, public.envelopes, public.envelope_aliases from anon;
revoke truncate, references, trigger
  on table public.envelope_groups, public.envelopes, public.envelope_aliases from authenticated;

create policy "envelope_groups: select own rows" on public.envelope_groups
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "envelope_groups: insert own rows" on public.envelope_groups
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "envelope_groups: update own rows" on public.envelope_groups
  for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "envelope_groups: delete own rows" on public.envelope_groups
  for delete to authenticated using ((select auth.uid()) = user_id);

create policy "envelopes: select own rows" on public.envelopes
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "envelopes: insert own rows" on public.envelopes
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "envelopes: update own rows" on public.envelopes
  for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
-- Referenced envelopes cannot be deleted (foreign keys); archive them instead.
create policy "envelopes: delete own rows" on public.envelopes
  for delete to authenticated using ((select auth.uid()) = user_id);

create policy "envelope_aliases: select own rows" on public.envelope_aliases
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "envelope_aliases: insert own rows" on public.envelope_aliases
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "envelope_aliases: update own rows" on public.envelope_aliases
  for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "envelope_aliases: delete own rows" on public.envelope_aliases
  for delete to authenticated using ((select auth.uid()) = user_id);

commit;
