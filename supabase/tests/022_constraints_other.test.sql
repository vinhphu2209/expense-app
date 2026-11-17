-- Accounts, envelopes, aliases, movements and settings constraints (#12).
begin;

select plan(12);

insert into auth.users (id, email) values ('11111111-1111-1111-1111-111111111111', 'a@example.test');
insert into public.accounts (id, user_id, name, is_default) values
  ('a0000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'MoMo', true),
  ('a0000000-0000-0000-0000-000000000011', '11111111-1111-1111-1111-111111111111', 'Cash', false);
insert into public.envelope_groups (id, user_id, name) values
  ('a0000000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 'Living Expenses');
insert into public.envelopes (id, user_id, group_id, name, rollover) values
  ('a0000000-0000-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111',
   'a0000000-0000-0000-0000-000000000002', 'Food', false),
  ('a0000000-0000-0000-0000-000000000013', '11111111-1111-1111-1111-111111111111',
   'a0000000-0000-0000-0000-000000000002', 'Emergency', true);
insert into public.envelope_aliases (user_id, envelope_id, alias) values
  ('11111111-1111-1111-1111-111111111111', 'a0000000-0000-0000-0000-000000000013', 'EmergencyFund');
insert into public.settings (user_id, default_account_id, emergency_envelope_id) values
  ('11111111-1111-1111-1111-111111111111', 'a0000000-0000-0000-0000-000000000011',
   'a0000000-0000-0000-0000-000000000013');

select throws_like(
  $$ insert into public.accounts (user_id, name, is_default)
     values ('11111111-1111-1111-1111-111111111111', 'Shopee Later', true) $$,
  '%uq_accounts_user_id_default%', 'at most one default account per user'
);
select throws_like(
  $$ insert into public.accounts (user_id, name) values ('11111111-1111-1111-1111-111111111111', 'momo') $$,
  '%uq_accounts_user_id_name%', 'active account names are unique per user, case-insensitively'
);
select lives_ok(
  $$ insert into public.accounts (user_id, name, archived_at)
     values ('11111111-1111-1111-1111-111111111111', 'MoMo', now()) $$,
  'an archived account may reuse a name'
);
select throws_like(
  $$ update public.envelopes set target_amount = 1000000 where id = 'a0000000-0000-0000-0000-000000000003' $$,
  '%ck_envelopes_target_only_for_funds%', 'only funds (rollover) have a target'
);
select lives_ok(
  $$ update public.envelopes set target_amount = 60000000 where id = 'a0000000-0000-0000-0000-000000000013' $$,
  'a fund may have a positive target'
);
select throws_like(
  $$ insert into public.envelope_aliases (user_id, envelope_id, alias)
     values ('11111111-1111-1111-1111-111111111111', 'a0000000-0000-0000-0000-000000000003', 'emergencyfund') $$,
  '%uq_envelope_aliases_user_id_alias%', 'an alias maps to one envelope per user, case-insensitively'
);
select throws_like(
  $$ insert into public.envelope_movements (user_id, month, amount, reason)
     values ('11111111-1111-1111-1111-111111111111', '2026-11-01', 1000, 'manual') $$,
  '%ck_envelope_movements_has_envelope%', 'a movement touches at least one envelope'
);
select throws_like(
  $$ insert into public.envelope_movements (user_id, month, from_envelope_id, to_envelope_id, amount, reason)
     values ('11111111-1111-1111-1111-111111111111', '2026-11-01',
             'a0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000003', 1000, 'manual') $$,
  '%ck_envelope_movements_distinct_envelopes%', 'a movement cannot go to the same envelope'
);
select throws_like(
  $$ insert into public.envelope_movements (user_id, month, to_envelope_id, amount, reason)
     values ('11111111-1111-1111-1111-111111111111', '2026-11-01',
             'a0000000-0000-0000-0000-000000000013', 0, 'month_close') $$,
  '%ck_envelope_movements_amount_positive%', 'a movement amount is positive'
);
select throws_like(
  $$ update public.settings set overspend_alert_pct = 0 where user_id = '11111111-1111-1111-1111-111111111111' $$,
  '%ck_settings_overspend_alert_pct_range%', 'overspend alert is between 1 and 100 percent'
);
select throws_like(
  $$ update public.settings set emergency_target_months = 25 where user_id = '11111111-1111-1111-1111-111111111111' $$,
  '%ck_settings_emergency_target_months_range%', 'emergency target months is between 1 and 24'
);

-- Deleting the default account clears only that setting, not the user_id of the settings row.
delete from public.accounts where id = 'a0000000-0000-0000-0000-000000000011';
select is(
  (select default_account_id from public.settings where user_id = '11111111-1111-1111-1111-111111111111'),
  null, 'deleting the default account sets settings.default_account_id to null'
);

select * from finish();

rollback;
