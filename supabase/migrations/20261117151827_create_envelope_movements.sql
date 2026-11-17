-- Migration: create_envelope_movements
-- Issue: #12 (P0-03)
-- Backward compatible: yes (new table)
-- Rollback: forward-only; to undo, create a new migration dropping the table (no data yet).

begin;

-- Moving budget between envelopes (month close, manual re-allocation). Not money transactions:
-- money does not physically move (plan §3.5, ADR-0003). Immutable history: insert-only.
create table public.envelope_movements (
  id                uuid primary key default gen_random_uuid(),
  user_id           uuid not null default auth.uid() references auth.users (id) on delete cascade,
  month             date not null,
  -- null on either side = "To be assigned".
  from_envelope_id  uuid,
  to_envelope_id    uuid,
  amount            bigint not null,
  reason            public.movement_reason not null,
  note              text,
  created_at        timestamptz not null default now(),
  constraint fk_envelope_movements_from_envelope
    foreign key (user_id, from_envelope_id) references public.envelopes (user_id, id),
  constraint fk_envelope_movements_to_envelope
    foreign key (user_id, to_envelope_id) references public.envelopes (user_id, id),
  constraint ck_envelope_movements_month_first_day check (month = date_trunc('month', month)::date),
  constraint ck_envelope_movements_amount_positive check (amount between 1 and 9007199254740991),
  constraint ck_envelope_movements_has_envelope
    check (from_envelope_id is not null or to_envelope_id is not null),
  constraint ck_envelope_movements_distinct_envelopes
    check (from_envelope_id is null or to_envelope_id is null or from_envelope_id <> to_envelope_id),
  constraint ck_envelope_movements_note_length check (note is null or length(note) <= 200)
);

create index idx_envelope_movements_user_id_month on public.envelope_movements (user_id, month);

alter table public.envelope_movements enable row level security;
revoke all on table public.envelope_movements from anon;
revoke update, delete, truncate, references, trigger on table public.envelope_movements from authenticated;

create policy "envelope_movements: select own rows" on public.envelope_movements
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "envelope_movements: insert own rows" on public.envelope_movements
  for insert to authenticated with check ((select auth.uid()) = user_id);
-- No update/delete: corrections are new opposite movements.

commit;
