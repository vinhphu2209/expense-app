-- RLS isolation (#12): user B can neither read nor write user A's data, cannot link to A's rows
-- through foreign keys, and anon has no access to any table. A can read its own rows everywhere.
begin;

select plan(48);

-- Setup as the table owner (bypasses RLS). A = 1111…, B = 2222….
insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'a@example.test'),
  ('22222222-2222-2222-2222-222222222222', 'b@example.test');

insert into public.accounts (id, user_id, name, is_default) values
  ('a0000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'MoMo', true),
  ('b0000000-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', 'MoMo', true);
insert into public.envelope_groups (id, user_id, name) values
  ('a0000000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 'Living Expenses'),
  ('b0000000-0000-0000-0000-000000000002', '22222222-2222-2222-2222-222222222222', 'Living Expenses');
insert into public.envelopes (id, user_id, group_id, name) values
  ('a0000000-0000-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111',
   'a0000000-0000-0000-0000-000000000002', 'Food'),
  ('b0000000-0000-0000-0000-000000000003', '22222222-2222-2222-2222-222222222222',
   'b0000000-0000-0000-0000-000000000002', 'Food');
insert into public.envelope_aliases (id, user_id, envelope_id, alias) values
  ('a0000000-0000-0000-0000-000000000006', '11111111-1111-1111-1111-111111111111',
   'a0000000-0000-0000-0000-000000000003', 'An uong');
insert into public.budget_months (id, user_id, month, income_planned) values
  ('a0000000-0000-0000-0000-000000000004', '11111111-1111-1111-1111-111111111111', '2026-11-01', 10000000),
  ('b0000000-0000-0000-0000-000000000004', '22222222-2222-2222-2222-222222222222', '2026-11-01', 10000000);
insert into public.budget_lines (budget_month_id, envelope_id, user_id, pct, assigned_amount) values
  ('a0000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000003',
   '11111111-1111-1111-1111-111111111111', 30, 3000000);
insert into public.transactions (id, user_id, type, amount, account_id, envelope_id, note, client_id) values
  ('a0000000-0000-0000-0000-000000000005', '11111111-1111-1111-1111-111111111111', 'expense', 45000,
   'a0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000003', 'pho', gen_random_uuid()),
  ('b0000000-0000-0000-0000-000000000005', '22222222-2222-2222-2222-222222222222', 'expense', 30000,
   'b0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000003', 'com', gen_random_uuid());
insert into public.envelope_movements (user_id, month, to_envelope_id, amount, reason) values
  ('11111111-1111-1111-1111-111111111111', '2026-11-01', 'a0000000-0000-0000-0000-000000000003', 1000, 'manual');
insert into public.settings (user_id, default_account_id, overspend_alert_pct) values
  ('11111111-1111-1111-1111-111111111111', 'a0000000-0000-0000-0000-000000000001', 80);
-- Creates an audit_log row for A.
update public.transactions set merchant = 'Pho 24' where id = 'a0000000-0000-0000-0000-000000000005';

-- ===== Act as user B =====
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}', true);

select is_empty($$ select 1 from public.accounts where user_id = '11111111-1111-1111-1111-111111111111' $$, 'B cannot read A''s accounts');
select is_empty($$ select 1 from public.envelope_groups where user_id = '11111111-1111-1111-1111-111111111111' $$, 'B cannot read A''s envelope groups');
select is_empty($$ select 1 from public.envelopes where user_id = '11111111-1111-1111-1111-111111111111' $$, 'B cannot read A''s envelopes');
select is_empty($$ select 1 from public.envelope_aliases where user_id = '11111111-1111-1111-1111-111111111111' $$, 'B cannot read A''s aliases');
select is_empty($$ select 1 from public.budget_months where user_id = '11111111-1111-1111-1111-111111111111' $$, 'B cannot read A''s budget months');
select is_empty($$ select 1 from public.budget_lines where user_id = '11111111-1111-1111-1111-111111111111' $$, 'B cannot read A''s budget lines');
select is_empty($$ select 1 from public.transactions where user_id = '11111111-1111-1111-1111-111111111111' $$, 'B cannot read A''s transactions');
select is_empty($$ select 1 from public.envelope_movements where user_id = '11111111-1111-1111-1111-111111111111' $$, 'B cannot read A''s envelope movements');
select is_empty($$ select 1 from public.settings where user_id = '11111111-1111-1111-1111-111111111111' $$, 'B cannot read A''s settings');
select is_empty($$ select 1 from public.audit_log where user_id = '11111111-1111-1111-1111-111111111111' $$, 'B cannot read A''s audit log');
select isnt_empty($$ select 1 from public.transactions $$, 'B can read B''s own transactions');

-- Writes against A's rows silently affect nothing (verified as owner below).
update public.transactions set note = 'hacked', deleted_at = now() where id = 'a0000000-0000-0000-0000-000000000005';
update public.accounts set name = 'hacked' where id = 'a0000000-0000-0000-0000-000000000001';
update public.budget_lines set pct = 99 where budget_month_id = 'a0000000-0000-0000-0000-000000000004';
delete from public.budget_lines where budget_month_id = 'a0000000-0000-0000-0000-000000000004';
update public.envelope_aliases set alias = 'hacked' where id = 'a0000000-0000-0000-0000-000000000006';
delete from public.envelope_aliases where id = 'a0000000-0000-0000-0000-000000000006';
update public.settings set overspend_alert_pct = 1 where user_id = '11111111-1111-1111-1111-111111111111';

select throws_ok(
  $$ insert into public.accounts (user_id, name) values ('11111111-1111-1111-1111-111111111111', 'Injected') $$,
  '42501', null, 'B cannot insert a row owned by A'
);
select throws_ok(
  $$ update public.transactions set user_id = '11111111-1111-1111-1111-111111111111'
      where id = 'b0000000-0000-0000-0000-000000000005' $$,
  '42501', null, 'B cannot hand B''s own row over to A (update policy with check)'
);
select throws_ok(
  $$ delete from public.transactions where id = 'b0000000-0000-0000-0000-000000000005' $$,
  '42501', null, 'B cannot hard-delete even B''s own transaction'
);
select throws_ok(
  $$ insert into public.transactions (type, amount, account_id, envelope_id, client_id)
     values ('expense', 1000, 'a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000003', gen_random_uuid()) $$,
  '23503', null, 'B cannot book on A''s account'
);
select throws_ok(
  $$ insert into public.transactions (type, amount, account_id, envelope_id, client_id)
     values ('expense', 1000, 'b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000003', gen_random_uuid()) $$,
  '23503', null, 'B cannot use A''s envelope'
);
select throws_ok(
  $$ insert into public.transactions (type, amount, account_id, to_account_id, client_id)
     values ('transfer', 1000, 'b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', gen_random_uuid()) $$,
  '23503', null, 'B cannot transfer into A''s account'
);
select throws_ok(
  $$ insert into public.envelopes (group_id, name) values ('a0000000-0000-0000-0000-000000000002', 'Sneaky') $$,
  '23503', null, 'B cannot put an envelope into A''s group'
);
select throws_ok(
  $$ insert into public.budget_lines (budget_month_id, envelope_id)
     values ('a0000000-0000-0000-0000-000000000004', 'b0000000-0000-0000-0000-000000000003') $$,
  '23503', null, 'B cannot add a line to A''s budget month'
);
select throws_ok(
  $$ insert into public.budget_lines (budget_month_id, envelope_id)
     values ('b0000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000003') $$,
  '23503', null, 'B cannot budget A''s envelope'
);
select throws_ok(
  $$ insert into public.envelope_movements (month, to_envelope_id, amount, reason)
     values ('2026-11-01', 'a0000000-0000-0000-0000-000000000003', 1000, 'manual') $$,
  '23503', null, 'B cannot move budget into A''s envelope'
);
select throws_ok(
  $$ insert into public.settings (default_account_id) values ('a0000000-0000-0000-0000-000000000001') $$,
  '23503', null, 'B cannot point settings at A''s account'
);
select throws_ok(
  $$ insert into public.envelope_aliases (envelope_id, alias) values ('a0000000-0000-0000-0000-000000000003', 'Sneaky') $$,
  '23503', null, 'B cannot alias A''s envelope'
);

-- ===== Owner: nothing of A's changed =====
reset role;

select is((select note from public.transactions where id = 'a0000000-0000-0000-0000-000000000005'),
  'pho', 'A''s transaction was not modified by B');
select is((select name from public.accounts where id = 'a0000000-0000-0000-0000-000000000001'),
  'MoMo', 'A''s account was not modified by B');
select is((select pct from public.budget_lines where budget_month_id = 'a0000000-0000-0000-0000-000000000004'),
  30.00::numeric, 'A''s budget line was neither modified nor deleted by B');
select is((select alias from public.envelope_aliases where id = 'a0000000-0000-0000-0000-000000000006'),
  'An uong', 'A''s alias was neither modified nor deleted by B');
select is((select overspend_alert_pct from public.settings where user_id = '11111111-1111-1111-1111-111111111111'),
  80, 'A''s settings were not modified by B');

-- ===== Act as user A: every select policy works =====
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}', true);

select isnt_empty($$ select 1 from public.accounts $$, 'A can read A''s accounts');
select isnt_empty($$ select 1 from public.envelope_groups $$, 'A can read A''s envelope groups');
select isnt_empty($$ select 1 from public.envelopes $$, 'A can read A''s envelopes');
select isnt_empty($$ select 1 from public.envelope_aliases $$, 'A can read A''s aliases');
select isnt_empty($$ select 1 from public.budget_months $$, 'A can read A''s budget months');
select isnt_empty($$ select 1 from public.budget_lines $$, 'A can read A''s budget lines');
select isnt_empty($$ select 1 from public.transactions $$, 'A can read A''s transactions');
select isnt_empty($$ select 1 from public.envelope_movements $$, 'A can read A''s envelope movements');
select isnt_empty($$ select 1 from public.settings $$, 'A can read A''s settings');
select isnt_empty($$ select 1 from public.audit_log $$, 'A can read A''s audit log');

-- ===== anon: no access to any table =====
reset role;
set local role anon;

select throws_ok($$ select * from public.accounts $$, '42501', null, 'anon cannot read accounts');
select throws_ok($$ select * from public.envelope_groups $$, '42501', null, 'anon cannot read envelope groups');
select throws_ok($$ select * from public.envelopes $$, '42501', null, 'anon cannot read envelopes');
select throws_ok($$ select * from public.envelope_aliases $$, '42501', null, 'anon cannot read aliases');
select throws_ok($$ select * from public.budget_months $$, '42501', null, 'anon cannot read budget months');
select throws_ok($$ select * from public.budget_lines $$, '42501', null, 'anon cannot read budget lines');
select throws_ok($$ select * from public.transactions $$, '42501', null, 'anon cannot read transactions');
select throws_ok($$ select * from public.envelope_movements $$, '42501', null, 'anon cannot read envelope movements');
select throws_ok($$ select * from public.settings $$, '42501', null, 'anon cannot read settings');
select throws_ok($$ select * from public.audit_log $$, '42501', null, 'anon cannot read the audit log');

reset role;

select * from finish();

rollback;
