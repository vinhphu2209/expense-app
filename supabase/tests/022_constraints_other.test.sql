-- Accounts, envelope groups, envelopes, aliases, movements and settings constraints (#12).
begin;

select plan(27);

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

-- Accounts
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
  $$ insert into public.accounts (user_id, name) values ('11111111-1111-1111-1111-111111111111', '   ') $$,
  '%ck_accounts_name_length%', 'an account name cannot be blank'
);
select throws_like(
  $$ insert into public.accounts (user_id, name, type, opening_balance)
     values ('11111111-1111-1111-1111-111111111111', 'Wallet', 'asset', -1) $$,
  '%ck_accounts_opening_balance_sign%', 'an asset account cannot start negative'
);
select throws_like(
  $$ insert into public.accounts (user_id, name, type, opening_balance)
     values ('11111111-1111-1111-1111-111111111111', 'Shopee Later', 'liability', 1) $$,
  '%ck_accounts_opening_balance_sign%', 'a liability (debt) cannot start positive'
);
select lives_ok(
  $$ insert into public.accounts (user_id, name, type, opening_balance)
     values ('11111111-1111-1111-1111-111111111111', 'Shopee Later', 'liability', -1200000) $$,
  'a liability starts at its debt as a negative balance'
);
select throws_like(
  $$ insert into public.accounts (user_id, name, type, opening_balance)
     values ('11111111-1111-1111-1111-111111111111', 'Huge debt', 'liability', -9007199254740992) $$,
  '%ck_accounts_opening_balance_safe%', 'opening balance is bounded to a JS safe integer'
);

-- Envelope groups and envelopes
select throws_like(
  $$ insert into public.envelope_groups (user_id, name) values ('11111111-1111-1111-1111-111111111111', '') $$,
  '%ck_envelope_groups_name_length%', 'a group name cannot be empty'
);
select throws_like(
  $$ insert into public.envelope_groups (user_id, name) values ('11111111-1111-1111-1111-111111111111', 'living expenses') $$,
  '%uq_envelope_groups_user_id_name%', 'group names are unique per user, case-insensitively'
);
select throws_like(
  $$ insert into public.envelopes (user_id, group_id, name)
     values ('11111111-1111-1111-1111-111111111111', 'a0000000-0000-0000-0000-000000000002', ' ') $$,
  '%ck_envelopes_name_length%', 'an envelope name cannot be blank'
);
select throws_like(
  $$ insert into public.envelopes (user_id, group_id, name)
     values ('11111111-1111-1111-1111-111111111111', 'a0000000-0000-0000-0000-000000000002', 'FOOD') $$,
  '%uq_envelopes_user_id_name%', 'active envelope names are unique per user, case-insensitively'
);
select throws_like(
  format(
    $$ update public.envelopes set description = %L where id = 'a0000000-0000-0000-0000-000000000003' $$,
    repeat('x', 201)
  ),
  '%ck_envelopes_description_length%', 'an envelope description is at most 200 characters'
);
select throws_like(
  $$ update public.envelopes set target_amount = 1000000 where id = 'a0000000-0000-0000-0000-000000000003' $$,
  '%ck_envelopes_target_only_for_funds%', 'only funds (rollover) have a target'
);
select throws_like(
  $$ update public.envelopes set target_amount = 9007199254740992 where id = 'a0000000-0000-0000-0000-000000000013' $$,
  '%ck_envelopes_target_only_for_funds%', 'a fund target is bounded to a JS safe integer'
);
select lives_ok(
  $$ update public.envelopes set target_amount = 60000000 where id = 'a0000000-0000-0000-0000-000000000013' $$,
  'a fund may have a positive target'
);

-- Aliases
select throws_like(
  $$ insert into public.envelope_aliases (user_id, envelope_id, alias)
     values ('11111111-1111-1111-1111-111111111111', 'a0000000-0000-0000-0000-000000000003', 'emergencyfund') $$,
  '%uq_envelope_aliases_user_id_alias%', 'an alias maps to one envelope per user, case-insensitively'
);
select throws_like(
  $$ insert into public.envelope_aliases (user_id, envelope_id, alias)
     values ('11111111-1111-1111-1111-111111111111', 'a0000000-0000-0000-0000-000000000003', ' ') $$,
  '%ck_envelope_aliases_alias_length%', 'an alias cannot be blank'
);

-- Envelope movements
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
  $$ insert into public.envelope_movements (user_id, month, to_envelope_id, amount, reason)
     values ('11111111-1111-1111-1111-111111111111', '2026-11-01',
             'a0000000-0000-0000-0000-000000000013', 9007199254740992, 'manual') $$,
  '%ck_envelope_movements_amount_positive%', 'a movement amount is bounded to a JS safe integer'
);
select throws_like(
  $$ insert into public.envelope_movements (user_id, month, to_envelope_id, amount, reason)
     values ('11111111-1111-1111-1111-111111111111', '2026-11-30',
             'a0000000-0000-0000-0000-000000000013', 1000, 'manual') $$,
  '%ck_envelope_movements_month_first_day%', 'a movement month is the first day of the month'
);
select throws_like(
  format(
    $$ insert into public.envelope_movements (user_id, month, to_envelope_id, amount, reason, note)
       values ('11111111-1111-1111-1111-111111111111', '2026-11-01',
               'a0000000-0000-0000-0000-000000000013', 1000, 'manual', %L) $$,
    repeat('x', 201)
  ),
  '%ck_envelope_movements_note_length%', 'a movement note is at most 200 characters'
);

-- Settings
select throws_like(
  $$ update public.settings set overspend_alert_pct = 0 where user_id = '11111111-1111-1111-1111-111111111111' $$,
  '%ck_settings_overspend_alert_pct_range%', 'overspend alert is between 1 and 100 percent'
);
select throws_like(
  $$ update public.settings set emergency_target_months = 25 where user_id = '11111111-1111-1111-1111-111111111111' $$,
  '%ck_settings_emergency_target_months_range%', 'emergency target months is between 1 and 24'
);

-- Deleting the default account clears only that setting, not the settings row's user_id.
delete from public.accounts where id = 'a0000000-0000-0000-0000-000000000011';
select is(
  (select default_account_id from public.settings where user_id = '11111111-1111-1111-1111-111111111111'),
  null, 'deleting the default account sets settings.default_account_id to null'
);

select * from finish();

rollback;
