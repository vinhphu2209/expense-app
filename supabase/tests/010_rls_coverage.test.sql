-- RLS coverage: every table is protected, anon has nothing, clients can't bypass RLS (#12).
begin;

select plan(7);

select tables_are(
  'public',
  array[
    'accounts', 'audit_log', 'budget_lines', 'budget_months', 'envelope_aliases',
    'envelope_groups', 'envelope_movements', 'envelopes', 'settings', 'transactions'
  ],
  'public has exactly the expected tables (new tables must be added here with RLS tests)'
);

select is(
  (select coalesce(array_agg(c.relname::text order by c.relname), '{}')
     from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relkind = 'r' and not c.relrowsecurity),
  '{}'::text[],
  'every public table has row level security enabled'
);

select is(
  (select coalesce(array_agg(c.relname::text order by c.relname), '{}')
     from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relkind = 'r'
      and not exists (select 1 from pg_policy p where p.polrelid = c.oid)),
  '{}'::text[],
  'every public table has at least one policy'
);

select is(
  (select coalesce(array_agg(distinct table_name::text), '{}')
     from information_schema.role_table_grants
    where table_schema = 'public' and grantee = 'anon'),
  '{}'::text[],
  'anon has no table privileges in public'
);

-- TRUNCATE is not subject to RLS, so clients must never hold it.
select is(
  (select coalesce(array_agg(distinct table_name::text || ':' || privilege_type), '{}')
     from information_schema.role_table_grants
    where table_schema = 'public' and grantee = 'authenticated'
      and privilege_type in ('TRUNCATE', 'REFERENCES', 'TRIGGER')),
  '{}'::text[],
  'authenticated cannot truncate, reference or add triggers to public tables'
);

select is(
  (select coalesce(array_agg(distinct table_name::text || ':' || privilege_type), '{}')
     from information_schema.role_table_grants
    where table_schema = 'public' and grantee = 'authenticated'
      and (table_name, privilege_type) in (
        ('audit_log', 'INSERT'), ('audit_log', 'UPDATE'), ('audit_log', 'DELETE'),
        ('envelope_movements', 'UPDATE'), ('envelope_movements', 'DELETE'))),
  '{}'::text[],
  'audit_log is read-only and envelope_movements is insert-only for clients'
);

select ok(
  not has_function_privilege('authenticated', 'public.fn_audit_transaction()', 'execute')
    and not has_function_privilege('anon', 'public.fn_audit_transaction()', 'execute')
    and not has_function_privilege('authenticated', 'public.fn_set_updated_at()', 'execute'),
  'trigger functions cannot be called directly by clients'
);

select * from finish();

rollback;
