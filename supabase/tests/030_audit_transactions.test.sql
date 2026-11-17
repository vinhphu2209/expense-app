-- Audit trail and no hard deletes for transactions (#12, plan §3.7).
begin;

select plan(10);

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'a@example.test'),
  ('22222222-2222-2222-2222-222222222222', 'b@example.test');
insert into public.accounts (id, user_id, name) values
  ('a0000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'MoMo');
insert into public.envelope_groups (id, user_id, name) values
  ('a0000000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 'Living Expenses');
insert into public.envelopes (id, user_id, group_id, name) values
  ('a0000000-0000-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111',
   'a0000000-0000-0000-0000-000000000002', 'Food');
insert into public.transactions (id, user_id, type, amount, account_id, envelope_id, note) values
  ('a0000000-0000-0000-0000-000000000005', '11111111-1111-1111-1111-111111111111', 'expense', 45000,
   'a0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000003', 'pho');

-- Act as user A.
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}', true);

update public.transactions set note = 'bun bo', amount = 50000
  where id = 'a0000000-0000-0000-0000-000000000005';

select is(
  (select count(*) from public.audit_log where row_id = 'a0000000-0000-0000-0000-000000000005'),
  1::bigint, 'an update writes one audit row the owner can read'
);
select is(
  (select before ->> 'note' || ' -> ' || (after ->> 'note') from public.audit_log
    where row_id = 'a0000000-0000-0000-0000-000000000005'),
  'pho -> bun bo', 'the audit row holds the before and after values'
);
select is(
  (select (before ->> 'amount')::bigint from public.audit_log
    where row_id = 'a0000000-0000-0000-0000-000000000005'),
  45000::bigint, 'money is preserved exactly in the audit snapshot'
);

-- Soft delete is an update and is audited too.
update public.transactions set deleted_at = now() where id = 'a0000000-0000-0000-0000-000000000005';
select is(
  (select count(*) from public.audit_log
    where row_id = 'a0000000-0000-0000-0000-000000000005' and after ->> 'deleted_at' is not null),
  1::bigint, 'a soft delete is audited'
);

-- Hard delete has no policy: it removes nothing.
delete from public.transactions where id = 'a0000000-0000-0000-0000-000000000005';
select isnt_empty(
  $$ select 1 from public.transactions where id = 'a0000000-0000-0000-0000-000000000005' $$,
  'a client cannot hard-delete a transaction'
);

select throws_ok(
  $$ insert into public.audit_log (user_id, table_name, row_id, action)
     values ('11111111-1111-1111-1111-111111111111', 'transactions',
             'a0000000-0000-0000-0000-000000000005', 'update') $$,
  '42501', null, 'clients cannot write audit rows'
);
select throws_ok(
  $$ update public.audit_log set after = null $$,
  '42501', null, 'clients cannot alter audit rows'
);

-- User B cannot see A's audit trail.
select set_config('request.jwt.claims', '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}', true);
select is_empty($$ select 1 from public.audit_log $$, 'other users cannot read the audit trail');

-- Privileged hard delete (service role / maintenance) is still audited.
reset role;
delete from public.transactions where id = 'a0000000-0000-0000-0000-000000000005';
select is(
  (select action::text from public.audit_log
    where row_id = 'a0000000-0000-0000-0000-000000000005' order by id desc limit 1),
  'delete', 'a privileged hard delete is audited'
);
select is(
  (select count(*) from public.audit_log where row_id = 'a0000000-0000-0000-0000-000000000005'),
  3::bigint, 'two updates and one delete were audited'
);

select * from finish();

rollback;
