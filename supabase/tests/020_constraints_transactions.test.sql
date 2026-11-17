-- Transaction check constraints (#12, plan §3.3, ADR-0004).
begin;

select plan(14);

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'a@example.test'),
  ('22222222-2222-2222-2222-222222222222', 'b@example.test');
insert into public.accounts (id, user_id, name) values
  ('a0000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'MoMo'),
  ('a0000000-0000-0000-0000-000000000011', '11111111-1111-1111-1111-111111111111', 'Cash'),
  ('b0000000-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', 'MoMo');
insert into public.envelope_groups (id, user_id, name) values
  ('a0000000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 'Living Expenses');
insert into public.envelopes (id, user_id, group_id, name) values
  ('a0000000-0000-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111',
   'a0000000-0000-0000-0000-000000000002', 'Food');

-- Shorthand ids in the statements below:
--   A = 1111…, A's MoMo = a…01, A's Cash = a…11, A's Food = a…03, B = 2222…, B's MoMo = b…01

select throws_like(
  $$ insert into public.transactions (user_id, type, amount, account_id, envelope_id)
     values ('11111111-1111-1111-1111-111111111111', 'expense', 0,
             'a0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000003') $$,
  '%ck_transactions_amount_positive%', 'amount must be positive'
);
select throws_like(
  $$ insert into public.transactions (user_id, type, amount, account_id, envelope_id)
     values ('11111111-1111-1111-1111-111111111111', 'expense', 9007199254740992,
             'a0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000003') $$,
  '%ck_transactions_amount_positive%', 'amount must fit in a JS safe integer'
);
select throws_like(
  $$ insert into public.transactions (user_id, type, amount, account_id)
     values ('11111111-1111-1111-1111-111111111111', 'transfer', 1000,
             'a0000000-0000-0000-0000-000000000001') $$,
  '%ck_transactions_transfer_has_to_account%', 'a transfer needs a destination account'
);
select throws_like(
  $$ insert into public.transactions (user_id, type, amount, account_id, to_account_id, envelope_id)
     values ('11111111-1111-1111-1111-111111111111', 'expense', 1000,
             'a0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000011',
             'a0000000-0000-0000-0000-000000000003') $$,
  '%ck_transactions_transfer_has_to_account%', 'only transfers have a destination account'
);
select throws_like(
  $$ insert into public.transactions (user_id, type, amount, account_id, to_account_id)
     values ('11111111-1111-1111-1111-111111111111', 'transfer', 1000,
             'a0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001') $$,
  '%ck_transactions_transfer_distinct_accounts%', 'a transfer cannot go to the same account'
);
select throws_like(
  $$ insert into public.transactions (user_id, type, amount, account_id, envelope_id)
     values ('11111111-1111-1111-1111-111111111111', 'income', 1000,
             'a0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000003') $$,
  '%ck_transactions_envelope_only_on_expense%', 'income has no envelope (goes to To be assigned)'
);
select throws_like(
  $$ insert into public.transactions (user_id, type, amount, account_id, to_account_id, envelope_id)
     values ('11111111-1111-1111-1111-111111111111', 'transfer', 1000,
             'a0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000011',
             'a0000000-0000-0000-0000-000000000003') $$,
  '%ck_transactions_envelope_only_on_expense%', 'transfers never touch envelopes'
);
select throws_like(
  $$ insert into public.transactions (user_id, type, amount, account_id)
     values ('11111111-1111-1111-1111-111111111111', 'expense', 1000,
             'a0000000-0000-0000-0000-000000000001') $$,
  '%ck_transactions_expense_has_envelope%', 'a confirmed expense needs an envelope'
);
select lives_ok(
  $$ insert into public.transactions (user_id, type, amount, account_id, status)
     values ('11111111-1111-1111-1111-111111111111', 'expense', 1000,
             'a0000000-0000-0000-0000-000000000001', 'pending') $$,
  'a pending expense (inbox) may lack an envelope'
);
select throws_like(
  $$ insert into public.transactions (user_id, type, amount, account_id, status)
     values ('11111111-1111-1111-1111-111111111111', 'income', 1000,
             'a0000000-0000-0000-0000-000000000001', 'pending') $$,
  '%ck_transactions_pending_only_expense%', 'only expenses can be pending'
);
select lives_ok(
  $$ insert into public.transactions (user_id, type, amount, account_id, to_account_id, client_id)
     values ('11111111-1111-1111-1111-111111111111', 'transfer', 500000,
             'a0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000011',
             'c0000000-0000-0000-0000-000000000001') $$,
  'a valid transfer between two own accounts is accepted'
);
select throws_like(
  $$ insert into public.transactions (user_id, type, amount, account_id, envelope_id, client_id)
     values ('11111111-1111-1111-1111-111111111111', 'expense', 1000,
             'a0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000003',
             'c0000000-0000-0000-0000-000000000001') $$,
  '%uq_transactions_user_id_client_id%', 'client_id is an idempotency key per user'
);
select lives_ok(
  $$ insert into public.transactions (user_id, type, amount, account_id, client_id)
     values ('22222222-2222-2222-2222-222222222222', 'income', 1000,
             'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001') $$,
  'the same client_id is allowed for a different user'
);
select throws_like(
  format(
    $$ insert into public.transactions (user_id, type, amount, account_id, envelope_id, note)
       values ('11111111-1111-1111-1111-111111111111', 'expense', 1000,
               'a0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000003', %L) $$,
    repeat('x', 201)
  ),
  '%ck_transactions_note_length%', 'note is at most 200 characters'
);

select * from finish();

rollback;
