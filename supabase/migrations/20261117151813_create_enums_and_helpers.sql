-- Migration: create_enums_and_helpers
-- Issue: #12 (P0-03)
-- Backward compatible: yes (new objects only)
-- Rollback: forward-only; to undo, create a new migration dropping these objects (no data yet).

begin;

create type public.account_type as enum ('asset', 'liability');
create type public.txn_type as enum ('expense', 'income', 'transfer');
create type public.txn_source as enum ('quickadd', 'manual', 'shortcut', 'import', 'system');
-- pending = inbox: an expense captured without an envelope yet (plan §4).
create type public.txn_status as enum ('confirmed', 'pending');
create type public.movement_reason as enum ('month_close', 'manual');
create type public.audit_action as enum ('insert', 'update', 'delete');

-- Shared trigger function for `updated_at` (database conventions §2.7).
create function public.fn_set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- Trigger functions are not meant to be called directly (e.g. through PostgREST RPC).
revoke all on function public.fn_set_updated_at() from public, anon, authenticated;

commit;
