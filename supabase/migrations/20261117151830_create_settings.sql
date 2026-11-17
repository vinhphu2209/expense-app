-- Migration: create_settings
-- Issue: #12 (P0-03)
-- Backward compatible: yes (new table)
-- Rollback: forward-only; to undo, create a new migration dropping the table (no data yet).

begin;

-- One row per user. Month-close split ratios/destinations and the essential groups for the
-- Emergency target are designed in P2-02 (#32), keyed by ids (ADR-0006), not names.
create table public.settings (
  user_id                  uuid primary key default auth.uid() references auth.users (id) on delete cascade,
  default_account_id       uuid,
  emergency_envelope_id    uuid,
  -- Emergency target = N × planned essential expenses (plan §3.5, #3).
  emergency_target_months  integer not null default 6,
  overspend_alert_pct      integer not null default 80,
  created_at               timestamptz not null default now(),
  updated_at               timestamptz not null default now(),
  constraint fk_settings_default_account
    foreign key (user_id, default_account_id) references public.accounts (user_id, id)
    on delete set null (default_account_id),
  constraint fk_settings_emergency_envelope
    foreign key (user_id, emergency_envelope_id) references public.envelopes (user_id, id)
    on delete set null (emergency_envelope_id),
  constraint ck_settings_emergency_target_months_range check (emergency_target_months between 1 and 24),
  constraint ck_settings_overspend_alert_pct_range check (overspend_alert_pct between 1 and 100)
);

create trigger trg_settings_updated_at
  before update on public.settings
  for each row execute function public.fn_set_updated_at();

alter table public.settings enable row level security;
revoke all on table public.settings from anon;
revoke truncate, references, trigger on table public.settings from authenticated;

create policy "settings: select own rows" on public.settings
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "settings: insert own rows" on public.settings
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "settings: update own rows" on public.settings
  for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

commit;
