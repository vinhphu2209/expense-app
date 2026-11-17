-- RLS isolation: user B can neither read nor write user A's data; anon has no access (#12).
begin;

select plan(18);

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
insert into public.envelope_aliases (user_id, envelope_id, alias) values
  ('11111111-1111-1111-1111-111111111111', 'a0000000-0000-0000-0000-000000000003', 'An uong');
insert into public.budget_months (id, user_id, month, income_planned) values
  ('a0000000-0000-0000-0000-000000000004', '11111111-1111-1111-1111-111111111111', '2026-11-01', 10000000);
insert into public.budget_lines (budget_month_id, envelope_id, user_id, pct, assigned_amount) values
  ('a0000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000003',
   '11111111-1111-1111-1111-111111111111', 30, 3000000);
insert into public.transactions (id, user_id, type, amount, account_id, envelope_id, note) values
  ('a0000000-0000-0000-0000-000000000005', '11111111-1111-1111-1111-111111111111', 'expense', 45000,
   'a0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000003', 'pho');
insert into public.envelope_movements (user_id, month, to_envelope_id, amount, reason) values
  ('11111111-1111-1111-1111-111111111111', '2026-11-01', 'a0000000-0000-0000-0000-000000000003', 1000, 'manual');
insert into public.settings (user_id, default_account_id) values
  ('11111111-1111-1111-1111-111111111111', 'a0000000-0000-0000-0000-000000000001');
-- Creates an audit_log row for A.
update public.transactions set merchant = 'Pho 24' where id = 'a0000000-0000-0000-0000-000000000005';

-- Act as user B.
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
select isnt_empty($$ select 1 from public.accounts $$, 'B can read B''s own accounts');

-- Writes against A's rows silently affect nothing.
update public.transactions set note = 'hacked', deleted_at = now()
  where id = 'a0000000-0000-0000-0000-000000000005';
update public.accounts set name = 'hacked' where id = 'a0000000-0000-0000-0000-000000000001';

select throws_ok(
  $$ insert into public.accounts (user_id, name) values ('11111111-1111-1111-1111-111111111111', 'Injected') $$,
  '42501', null, 'B cannot insert a row owned by A'
);
select throws_ok(
  $$ insert into public.transactions (type, amount, account_id, envelope_id)
     values ('expense', 1000, 'a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000003') $$,
  '23503', null, 'B cannot book on A''s account (same-user composite foreign key)'
);
select throws_ok(
  $$ insert into public.transactions (type, amount, account_id, envelope_id)
     values ('expense', 1000, 'b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000003') $$,
  '23503', null, 'B cannot use A''s envelope (same-user composite foreign key)'
);
select throws_ok(
  $$ insert into public.envelopes (group_id, name) values ('a0000000-0000-0000-0000-000000000002', 'Sneaky') $$,
  '23503', null, 'B cannot put an envelope into A''s group'
);

-- Back to the owner to check that nothing of A's changed.
reset role;

select is(
  (select note from public.transactions where id = 'a0000000-0000-0000-0000-000000000005'),
  'pho', 'A''s transaction was not modified by B'
);
select is(
  (select name from public.accounts where id = 'a0000000-0000-0000-0000-000000000001'),
  'MoMo', 'A''s account was not modified by B'
);

-- anon has no access at all.
set local role anon;
select throws_ok($$ select * from public.transactions $$, '42501', null, 'anon cannot read transactions');
reset role;

select * from finish();

rollback;
