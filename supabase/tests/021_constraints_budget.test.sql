-- Budget check constraints (#12, plan §3.4).
begin;

select plan(7);

insert into auth.users (id, email) values ('11111111-1111-1111-1111-111111111111', 'a@example.test');
insert into public.envelope_groups (id, user_id, name) values
  ('a0000000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 'Living Expenses');
insert into public.envelopes (id, user_id, group_id, name) values
  ('a0000000-0000-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111',
   'a0000000-0000-0000-0000-000000000002', 'Food');
insert into public.budget_months (id, user_id, month, income_planned) values
  ('a0000000-0000-0000-0000-000000000004', '11111111-1111-1111-1111-111111111111', '2026-11-01', 10000000);

select throws_like(
  $$ insert into public.budget_months (user_id, month) values ('11111111-1111-1111-1111-111111111111', '2026-12-15') $$,
  '%ck_budget_months_month_first_day%', 'a budget month is stored as the first day of the month'
);
select throws_like(
  $$ insert into public.budget_months (user_id, month) values ('11111111-1111-1111-1111-111111111111', '2026-11-01') $$,
  '%uq_budget_months_user_id_month%', 'one budget per user and month'
);
select throws_like(
  $$ insert into public.budget_months (user_id, month, income_planned)
     values ('11111111-1111-1111-1111-111111111111', '2026-12-01', -1) $$,
  '%ck_budget_months_income_planned_safe%', 'planned income cannot be negative'
);
select throws_like(
  $$ insert into public.budget_lines (budget_month_id, envelope_id, user_id, pct)
     values ('a0000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000003',
             '11111111-1111-1111-1111-111111111111', 100.01) $$,
  '%ck_budget_lines_pct_range%', 'pct is at most 100'
);
select throws_like(
  $$ insert into public.budget_lines (budget_month_id, envelope_id, user_id, pct)
     values ('a0000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000003',
             '11111111-1111-1111-1111-111111111111', -0.01) $$,
  '%ck_budget_lines_pct_range%', 'pct is at least 0'
);
select throws_like(
  $$ insert into public.budget_lines (budget_month_id, envelope_id, user_id, assigned_amount)
     values ('a0000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000003',
             '11111111-1111-1111-1111-111111111111', -1000) $$,
  '%ck_budget_lines_assigned_amount_safe%', 'assigned amount cannot be negative'
);
select lives_ok(
  $$ insert into public.budget_lines (budget_month_id, envelope_id, user_id, pct, assigned_amount, is_override)
     values ('a0000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000003',
             '11111111-1111-1111-1111-111111111111', 12.50, 1250000, false) $$,
  'a valid budget line is accepted'
);

select * from finish();

rollback;
