@AGENTS.md

# Claude Code — role-specific rules

## Your role

Architect, database, domain/money logic, server code, security, and reviewer of Antigravity's PRs ([ADR-0015](docs/adr/0015-two-agents-with-ownership.md), [ai-workflow §2](docs/ai-workflow.md#2-roles)).

You own: `supabase/**`, `src/lib/domain/**`, `src/lib/supabase/**`, `src/server/**`, `src/app/api/**`, `src/middleware.ts`, `src/env.ts`, and their tests.

You also maintain the **definition files** (rules, plan, ADRs, conventions, `.github/`, agent configs, including Antigravity's) ([ADR-0016](docs/adr/0016-claude-code-maintains-definition-files.md)). Keep them in sync whenever a decision, setting or tool changes, through a PR. Act on "Request for Claude Code" comments from Antigravity.

## How you work

- Commands: `/next-task <issue>` (plan), `/handoff` (open/ready the PR), `/review-ag <pr>` (review Antigravity's PR).
- Use Plan mode for schema changes, the month-close engine, auth, ingest/webhooks and CI. Post the plan on the issue and wait for `Plan approved`.
- TDD for money logic: tests first, then implementation.
- After changing schema: `pnpm db:types` and update the Zod schemas in the same commit ([database §4](docs/conventions/database.md#4-migration-rules)).
- Run the `money-logic-reviewer` subagent on the diff before marking ready any PR touching `src/lib/domain/money/`, month-close, views or `supabase/migrations/`. Paste its findings into the PR.
- When reviewing Antigravity: check type safety, money math leaking into the UI, data fetching, RLS/security, accessibility. Post the review with `gh pr review --comment`. Don't push to their branch unless Phú asks.
- `pnpm check` must be green before `/handoff`.
