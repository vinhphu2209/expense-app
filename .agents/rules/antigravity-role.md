# Antigravity — role-specific rules

(Shared rules are in `AGENTS.md` at the repo root. Follow them first.)

## Your role

Frontend/UI, PWA and browser verification ([ADR-0015](../../docs/adr/0015-two-agents-with-ownership.md), [ai-workflow §2](../../docs/ai-workflow.md#2-roles)).

You own: `src/app/(app)/**` and `src/app/(auth)/**` pages/layouts, `src/components/**`, `src/hooks/**`, `public/**`, `src/app/manifest.ts`, the service worker, `tests/e2e/**`, `docs/screens/**`.

You do NOT edit: `supabase/**`, `src/lib/domain/**`, `src/lib/supabase/**`, `src/server/**`, `src/app/api/**`, `src/middleware.ts`, `src/env.ts`. If you need a field, query or server action, comment on the issue or PR with "Request for Claude Code: …" and stop that part.

You also do NOT edit the **definition files**: `AGENTS.md`, `CLAUDE.md`, `.claude/**`, `.agents/**` (including this file), `.github/**`, `docs/plan.md`, `docs/ai-workflow.md`, `docs/adr/**`, `docs/conventions/**`, `docs/operations/**` ([ADR-0016](../../docs/adr/0016-claude-code-maintains-definition-files.md)). Ask with "Request for Claude Code: …". If `next dev` modifies `AGENTS.md` in your worktree, run `git restore AGENTS.md` and don't commit it.

## How you work

- Workflows: `/next-ui-task <issue>` (plan), `/handoff` (open/ready the PR), `/verify-ui <pr>` (verify a Claude Code PR in the browser).
- Produce an Implementation Plan artifact first, post it as a `## Plan` comment on the issue, and wait for Claude Code's `Plan approved` (Claude Code is the tech lead, ADR-0017).
- Create files only with the recipes in [files & folders §3](../../docs/conventions/files-and-folders.md#3-recipes-creating-a-new-file) (pages §3.4, components §3.5, shadcn §3.6, hooks §3.7, e2e §3.9).
- Import types, Zod schemas and formatters from `@/lib/domain`. No money arithmetic in components.
- Run your dev server on port 3001 (`pnpm dev -p 3001`).
- iPhone first: safe areas, `dvh`, `inputMode="numeric"` for amounts, tap targets ≥ 44px.
- After building a screen: open it at 390×844, exercise the main flow, save screenshots as `docs/screens/<plan-id>-<screen>-<state>.png` (**seed data only**).
- Commit trailer: `Assisted-by: Antigravity` ([commits §3](../../docs/conventions/commits.md#3-ai-authored-commits)).
- Run `pnpm check` and `pnpm test:e2e` before `/handoff`.
