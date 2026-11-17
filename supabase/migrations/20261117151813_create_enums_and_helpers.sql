-- Migration: create_enums_and_helpers
-- Issue: #12 (P0-03)
-- Backward compatible: yes (new objects only)
-- Rollback: forward-only; to undo, create a new migration dropping these objects (no data yet).

begin;

-- Secure defaults for every object this project creates in `public` (owned by postgres):
-- anon gets nothing; clients get no TRUNCATE (it bypasses RLS), REFERENCES or TRIGGER;
-- functions are not executable by anyone until a migration grants EXECUTE explicitly.
-- RLS policies stay the primary guard; these defaults close the gaps a missed revoke would leave.
alter default privileges for role postgres in schema public revoke all on tables from anon;
alter default privileges for role postgres in schema public revoke all on sequences from anon;
alter default privileges for role postgres in schema public revoke all on functions from anon;
alter default privileges for role postgres in schema public
  revoke truncate, references, trigger on tables from authenticated;
alter default privileges for role postgres in schema public revoke execute on functions from public;
alter default privileges for role postgres in schema public revoke execute on functions from authenticated;

create type public.account_type as enum ('asset', 'liability');
create type public.txn_type as enum ('expense', 'income', 'transfer');
create type public.txn_source as enum ('quickadd', 'manual', 'shortcut', 'import', 'system');
-- pending = inbox: an expense captured without an envelope yet (plan §4).
create type public.txn_status as enum ('confirmed', 'pending');
create type public.movement_reason as enum ('month_close', 'manual');
create type public.audit_action as enum ('insert', 'update', 'delete');

-- Shared trigger function for `updated_at` (database conventions §2.7). Also pins `created_at`
-- so clients cannot rewrite when a row was created.
create function public.fn_set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.created_at := old.created_at;
  new.updated_at := now();
  return new;
end;
$$;

-- Trigger functions are not meant to be called directly (e.g. through PostgREST RPC).
revoke all on function public.fn_set_updated_at() from public, anon, authenticated;

commit;
