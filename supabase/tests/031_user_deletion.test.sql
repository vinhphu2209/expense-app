-- Deleting an account (auth.users) removes all of the user's data, including audited
-- transactions, and leaves other users untouched (#12, money-logic review blocker on #68).
begin;

select plan(6);

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'a@example.test'),
  ('22222222-2222-2222-2222-222222222222', 'b@example.test');
insert into public.accounts (id, user_id, name) values
  ('a0000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'MoMo'),
  ('b0000000-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', 'MoMo');
insert into public.envelope_groups (id, user_id, name) values
  ('a0000000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 'Living Expenses');
insert into public.envelopes (id, user_id, group_id, name) values
  ('a0000000-0000-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111',
   'a0000000-0000-0000-0000-000000000002', 'Food');
insert into public.settings (user_id, default_account_id) values
  ('11111111-1111-1111-1111-111111111111', 'a0000000-0000-0000-0000-000000000001');
insert into public.transactions (id, user_id, type, amount, account_id, envelope_id, client_id) values
  ('a0000000-0000-0000-0000-000000000005', '11111111-1111-1111-1111-111111111111', 'expense', 45000,
   'a0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000003', gen_random_uuid());
insert into public.transactions (user_id, type, amount, account_id, client_id) values
  ('22222222-2222-2222-2222-222222222222', 'income', 1000, 'b0000000-0000-0000-0000-000000000001', gen_random_uuid());
-- Give A audit history.
update public.transactions set note = 'edited' where id = 'a0000000-0000-0000-0000-000000000005';

select lives_ok(
  $$ delete from auth.users where id = '11111111-1111-1111-1111-111111111111' $$,
  'a user with audited transactions can be deleted'
);
select is_empty(
  $$ select 1 from public.transactions where user_id = '11111111-1111-1111-1111-111111111111' $$,
  'the user''s transactions are gone'
);
select is_empty(
  $$ select 1 from public.audit_log where user_id = '11111111-1111-1111-1111-111111111111' $$,
  'the user''s audit trail is gone'
);
select is_empty(
  $$ select 1 from public.accounts where user_id = '11111111-1111-1111-1111-111111111111' $$,
  'the user''s accounts are gone'
);
select is_empty(
  $$ select 1 from public.settings where user_id = '11111111-1111-1111-1111-111111111111' $$,
  'the user''s settings are gone'
);
select is(
  (select count(*) from public.transactions where user_id = '22222222-2222-2222-2222-222222222222'),
  1::bigint, 'other users'' data is untouched'
);

select * from finish();

rollback;
