-- Migration: create_audit_log
-- Issue: #12 (P0-03)
-- Backward compatible: yes (new table, function and trigger)
-- Rollback: forward-only; to undo, create a new migration dropping the trigger, function and table.

begin;

-- Before/after snapshot of every change to a transaction (plan §3.7). Written only by the
-- trigger below; clients can read their own rows but never write.
create table public.audit_log (
  id          bigint generated always as identity primary key,
  user_id     uuid not null references auth.users (id) on delete cascade,
  table_name  text not null,
  row_id      uuid not null,
  action      public.audit_action not null,
  before      jsonb,
  after       jsonb,
  created_at  timestamptz not null default now()
);

create index idx_audit_log_user_id_table_name_row_id on public.audit_log (user_id, table_name, row_id);

alter table public.audit_log enable row level security;
revoke all on table public.audit_log from anon;
revoke insert, update, delete, truncate, references, trigger on table public.audit_log from authenticated;

create policy "audit_log: select own rows" on public.audit_log
  for select to authenticated using ((select auth.uid()) = user_id);

-- SECURITY DEFINER because authenticated users have no insert privilege on audit_log.
-- It only copies the row being changed (which already passed RLS) and takes user_id from that row,
-- so it cannot write audit rows for another user. No auth.uid() check on purpose: it must also audit
-- service-role writes, where auth.uid() is null (database §5 exception for row-copying triggers).
-- Empty search_path + qualified names.
create function public.fn_audit_transaction()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  -- The owner is being deleted (auth.users cascade): their audit rows go too, so writing one more
  -- would violate audit_log_user_id_fkey and abort the account deletion.
  if tg_op = 'DELETE' and not exists (select 1 from auth.users u where u.id = old.user_id) then
    return old;
  end if;

  -- No-op updates (only updated_at changed, e.g. a retried request) are not audited.
  if tg_op = 'UPDATE' and (to_jsonb(old) - 'updated_at') = (to_jsonb(new) - 'updated_at') then
    return new;
  end if;

  if tg_op = 'UPDATE' then
    insert into public.audit_log (user_id, table_name, row_id, action, before, after)
    values (old.user_id, 'transactions', old.id, 'update', to_jsonb(old), to_jsonb(new));
    return new;
  elsif tg_op = 'DELETE' then
    insert into public.audit_log (user_id, table_name, row_id, action, before, after)
    values (old.user_id, 'transactions', old.id, 'delete', to_jsonb(old), null);
    return old;
  end if;
  return null;
end;
$$;

revoke all on function public.fn_audit_transaction() from public, anon, authenticated;

create trigger trg_transactions_audit
  after update or delete on public.transactions
  for each row execute function public.fn_audit_transaction();

commit;
