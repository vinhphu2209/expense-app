-- Migration: create_budget
-- Issue: #12 (P0-03)
-- Backward compatible: yes (new tables)
-- Rollback: forward-only; to undo, create a new migration dropping the tables (no data yet).

begin;

-- One budget per calendar month (Asia/Ho_Chi_Minh, ADR-0005); income_planned = Net (plan §3.4, #4).
create table public.budget_months (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null default auth.uid() references auth.users (id) on delete cascade,
  month           date not null,
  income_planned  bigint not null default 0,
  income_gross    bigint,
  bhxh_salary     bigint,
  closed_at       timestamptz,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  constraint uq_budget_months_user_id_id unique (user_id, id),
  constraint uq_budget_months_user_id_month unique (user_id, month),
  constraint ck_budget_months_month_first_day check (month = date_trunc('month', month)::date),
  constraint ck_budget_months_income_planned_safe
    check (income_planned between 0 and 9007199254740991),
  constraint ck_budget_months_income_gross_safe
    check (income_gross is null or income_gross between 0 and 9007199254740991),
  constraint ck_budget_months_bhxh_salary_safe
    check (bhxh_salary is null or bhxh_salary between 0 and 9007199254740991)
);

-- Per envelope and month: percentage and assigned amount (plan §3.4).
create table public.budget_lines (
  budget_month_id  uuid not null,
  envelope_id      uuid not null,
  user_id          uuid not null default auth.uid() references auth.users (id) on delete cascade,
  pct              numeric(5, 2) not null default 0,
  assigned_amount  bigint not null default 0,
  is_override      boolean not null default false,
  note             text,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  constraint pk_budget_lines primary key (budget_month_id, envelope_id),
  constraint fk_budget_lines_budget_month
    foreign key (user_id, budget_month_id) references public.budget_months (user_id, id) on delete cascade,
  constraint fk_budget_lines_envelope
    foreign key (user_id, envelope_id) references public.envelopes (user_id, id),
  constraint ck_budget_lines_pct_range check (pct between 0 and 100),
  constraint ck_budget_lines_assigned_amount_safe check (assigned_amount between 0 and 9007199254740991),
  constraint ck_budget_lines_note_length check (note is null or length(note) <= 200)
);

create index idx_budget_lines_user_id_envelope_id on public.budget_lines (user_id, envelope_id);

create trigger trg_budget_months_updated_at
  before update on public.budget_months
  for each row execute function public.fn_set_updated_at();
create trigger trg_budget_lines_updated_at
  before update on public.budget_lines
  for each row execute function public.fn_set_updated_at();

alter table public.budget_months enable row level security;
alter table public.budget_lines enable row level security;

revoke all on table public.budget_months, public.budget_lines from anon;
revoke truncate, references, trigger on table public.budget_months, public.budget_lines from authenticated;

create policy "budget_months: select own rows" on public.budget_months
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "budget_months: insert own rows" on public.budget_months
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "budget_months: update own rows" on public.budget_months
  for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
-- No delete policy: budget months are history.

create policy "budget_lines: select own rows" on public.budget_lines
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "budget_lines: insert own rows" on public.budget_lines
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "budget_lines: update own rows" on public.budget_lines
  for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "budget_lines: delete own rows" on public.budget_lines
  for delete to authenticated using ((select auth.uid()) = user_id);

commit;
