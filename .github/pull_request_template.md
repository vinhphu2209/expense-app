<!--
Title = Conventional Commit header, e.g. `feat(quickadd): add S1 quick-add screen` (it becomes the squash commit).
Guide: docs/conventions/pull-requests.md. Fill every section; write "N/A — <reason>" instead of deleting one.
-->

## Summary

<!-- 1–3 sentences: what changed and why. -->

## Linked issue

Closes #

## Author

- **Agent:** claude-code | antigravity | human
- **Plan ID:** P_-__

## Changes

<!-- Bullets grouped by area (db / domain / server / ui / pwa / docs / ci). -->

-

## How to verify

<!-- Exact commands and click paths. Mention if verification must be local (migration not on UAT yet). -->

1. `pnpm check`
2. <!-- next step -->

## Screenshots (UI only, 390×844, seed data only)

| Before | After |
| --- | --- |
| | |

## Database

- Migrations: <!-- file names, or N/A -->
- Backward compatible with the currently deployed app: yes / no
- Rollback plan: <!-- forward fix / N/A -->
- [ ] `pnpm db:types` regenerated and Zod schemas updated in the same commit
- [ ] pgTAP tests added/updated

## Security & privacy

- [ ] No secrets, tokens or real personal/financial data in code, tests, screenshots or logs (public repo)
- [ ] RLS covers every new table/view (`security_invoker = true` on views)
- [ ] No new server-only value reachable from client bundles
- Notes: <!-- new env vars, auth changes, or N/A -->

## Review focus

<!-- Where should the reviewer look hardest? Which reviewer (docs/conventions/pull-requests.md §5.1)? -->

## Definition of Done

- [ ] `pnpm check` green (typecheck, lint, unit tests)
- [ ] Money logic has unit tests; no floating-point money
- [ ] UI works at 390×844 and in iPhone standalone mode where relevant
- [ ] `.env.example` + `src/env.ts` updated for new variables
- [ ] Docs updated in this PR (README / guides / architecture / ADR)
- [ ] `CHANGELOG.md` → `Unreleased` updated (feat/fix only)
- [ ] Reviewed per docs/conventions/pull-requests.md §5.1
