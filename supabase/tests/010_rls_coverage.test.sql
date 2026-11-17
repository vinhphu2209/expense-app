-- RLS and privilege coverage (#12). Pins the exact tables, policies, policy expressions, client
-- privileges and check constraints, so a missing, extra or over-permissive one fails CI.
begin;

select plan(19);

select tables_are(
  'public',
  array[
    'accounts', 'audit_log', 'budget_lines', 'budget_months', 'envelope_aliases',
    'envelope_groups', 'envelope_movements', 'envelopes', 'settings', 'transactions'
  ],
  'public has exactly the expected tables (a new table must be added here with RLS tests)'
);

select is(
  (select coalesce(array_agg(c.relname::text order by c.relname), '{}')
     from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relkind = 'r' and not c.relrowsecurity),
  '{}'::text[],
  'every public table has row level security enabled'
);

-- Exact policy sets: a missing select policy, an extra delete policy, etc. all fail here.
select policies_are('public', 'accounts', array[
  'accounts: select own rows', 'accounts: insert own rows', 'accounts: update own rows', 'accounts: delete own rows']);
select policies_are('public', 'envelope_groups', array[
  'envelope_groups: select own rows', 'envelope_groups: insert own rows',
  'envelope_groups: update own rows', 'envelope_groups: delete own rows']);
select policies_are('public', 'envelopes', array[
  'envelopes: select own rows', 'envelopes: insert own rows', 'envelopes: update own rows', 'envelopes: delete own rows']);
select policies_are('public', 'envelope_aliases', array[
  'envelope_aliases: select own rows', 'envelope_aliases: insert own rows',
  'envelope_aliases: update own rows', 'envelope_aliases: delete own rows']);
select policies_are('public', 'budget_months', array[
  'budget_months: select own rows', 'budget_months: insert own rows', 'budget_months: update own rows']);
select policies_are('public', 'budget_lines', array[
  'budget_lines: select own rows', 'budget_lines: insert own rows',
  'budget_lines: update own rows', 'budget_lines: delete own rows']);
select policies_are('public', 'transactions', array[
  'transactions: select own rows', 'transactions: insert own rows', 'transactions: update own rows']);
select policies_are('public', 'envelope_movements', array[
  'envelope_movements: select own rows', 'envelope_movements: insert own rows']);
select policies_are('public', 'settings', array[
  'settings: select own rows', 'settings: insert own rows', 'settings: update own rows']);
select policies_are('public', 'audit_log', array['audit_log: select own rows']);

-- Every policy applies only to authenticated users and only to their own rows.
select is(
  (select coalesce(array_agg(tablename || ' / ' || policyname order by tablename, policyname), '{}')
     from pg_policies
    where schemaname = 'public'
      and (roles <> '{authenticated}'::name[]
           or coalesce(qual, '(( SELECT auth.uid() AS uid) = user_id)') <> '(( SELECT auth.uid() AS uid) = user_id)'
           or coalesce(with_check, '(( SELECT auth.uid() AS uid) = user_id)') <> '(( SELECT auth.uid() AS uid) = user_id)')),
  '{}'::text[],
  'every policy is "to authenticated" with exactly (select auth.uid()) = user_id'
);

select is(
  (select coalesce(array_agg(distinct table_name::text), '{}')
     from information_schema.role_table_grants
    where table_schema = 'public' and grantee = 'anon'),
  '{}'::text[],
  'anon has no table privileges in public'
);

select is(
  (select coalesce(array_agg(c.relname::text order by c.relname), '{}')
     from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relkind = 'S'
      and (has_sequence_privilege('anon', c.oid, 'usage') or has_sequence_privilege('anon', c.oid, 'select'))),
  '{}'::text[],
  'anon cannot use any sequence in public'
);

select is(
  (select coalesce(array_agg(p.proname::text order by p.proname), '{}')
     from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and (has_function_privilege('anon', p.oid, 'execute')
           or has_function_privilege('authenticated', p.oid, 'execute'))),
  '{}'::text[],
  'no function in public is executable by clients unless a migration grants it explicitly'
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

-- History tables: no client delete privilege at all; audit_log read-only; movements insert-only.
select is(
  (select coalesce(array_agg(table_name::text || ':' || privilege_type order by table_name, privilege_type), '{}')
     from information_schema.role_table_grants
    where table_schema = 'public' and grantee = 'authenticated'
      and (privilege_type = 'DELETE'
           or (table_name = 'audit_log' and privilege_type <> 'SELECT')
           or (table_name = 'envelope_movements' and privilege_type = 'UPDATE'))),
  array[
    'accounts:DELETE', 'budget_lines:DELETE', 'envelope_aliases:DELETE',
    'envelope_groups:DELETE', 'envelopes:DELETE'
  ]::text[],
  'clients may delete only configuration rows; history tables are protected by privileges'
);

-- Pin every check constraint so a dropped or renamed one fails CI (each is tested in 02x).
select is(
  (select array_agg(c.conrelid::regclass::text || '.' || c.conname order by c.conrelid::regclass::text, c.conname)
     from pg_constraint c join pg_namespace n on n.oid = c.connamespace
    where n.nspname = 'public' and c.contype = 'c'),
  array[
    'accounts.ck_accounts_name_length', 'accounts.ck_accounts_opening_balance_safe',
    'accounts.ck_accounts_opening_balance_sign',
    'budget_lines.ck_budget_lines_assigned_amount_safe', 'budget_lines.ck_budget_lines_note_length',
    'budget_lines.ck_budget_lines_pct_range',
    'budget_months.ck_budget_months_bhxh_salary_safe', 'budget_months.ck_budget_months_income_gross_safe',
    'budget_months.ck_budget_months_income_planned_safe', 'budget_months.ck_budget_months_month_first_day',
    'envelope_aliases.ck_envelope_aliases_alias_length',
    'envelope_groups.ck_envelope_groups_name_length',
    'envelope_movements.ck_envelope_movements_amount_positive',
    'envelope_movements.ck_envelope_movements_distinct_envelopes',
    'envelope_movements.ck_envelope_movements_has_envelope',
    'envelope_movements.ck_envelope_movements_month_first_day',
    'envelope_movements.ck_envelope_movements_note_length',
    'envelopes.ck_envelopes_description_length', 'envelopes.ck_envelopes_name_length',
    'envelopes.ck_envelopes_target_only_for_funds',
    'settings.ck_settings_emergency_target_months_range', 'settings.ck_settings_overspend_alert_pct_range',
    'transactions.ck_transactions_amount_positive', 'transactions.ck_transactions_client_id_required',
    'transactions.ck_transactions_envelope_only_on_expense', 'transactions.ck_transactions_expense_has_envelope',
    'transactions.ck_transactions_merchant_length', 'transactions.ck_transactions_note_length',
    'transactions.ck_transactions_pending_only_expense', 'transactions.ck_transactions_transfer_distinct_accounts',
    'transactions.ck_transactions_transfer_has_to_account'
  ]::text[],
  'the set of check constraints is exactly the tested one'
);

select * from finish();

rollback;
