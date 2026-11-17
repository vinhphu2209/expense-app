-- Smoke test: the pgTAP toolchain works against the local database.
-- Numbering: 000–099 schema/RLS, 100–199 views, 200–299 functions (docs/conventions/database.md §7).
begin;

select plan(3);

select has_schema('public', 'public schema exists');
select has_schema('auth', 'Supabase auth schema exists');
select is(current_setting('server_version_num')::int >= 170000, true, 'Postgres 17 or newer');

select * from finish();

rollback;
