# AGENTS.md — Shared rules for all AI agents (Claude Code, Antigravity)

Only Claude Code edits this file and the other definition files, through a PR ([ADR-0016](docs/adr/0016-claude-code-maintains-definition-files.md)). Antigravity requests changes with "Request for Claude Code: …".
This file is short on purpose: it points to the conventions instead of copying them ([documentation §5](docs/conventions/documentation.md#5-agent-context-files)).

## Project

Personal expense-tracking PWA for iPhone, replacing the "Budget & Expense" Google Sheet. **Public repository** ([ADR-0014](docs/adr/0014-public-repository.md)).

Read before any task:

1. The GitHub issue for the task (`gh issue view <n> --comments`), including the approved `## Plan`.
2. The `docs/plan.md` sections the issue references.
3. The ADRs and conventions linked below that relate to the files you will touch.

## Language

- App UI text: Vietnamese.
- Code, identifiers, comments, commit messages, PRs, issues, reviews and ALL documentation: English.
- Chat replies to Phú: Vietnamese, keeping technical terms in English.

## Target platform

iPhone Safari PWA installed via Add to Home Screen; design for 390×844 first ([ADR-0009](docs/adr/0009-iphone-primary-device.md)). Only MoMo, Cash and BNPL accounts ([ADR-0010](docs/adr/0010-track-momo-only.md)).

## Stack

Next.js (App Router) + TypeScript strict, Tailwind + shadcn/ui, Supabase (Postgres + RLS + Auth), Zod, Vitest, Playwright, pnpm, Vercel, GitHub Actions.

## Commands

- `pnpm dev` (Claude Code worktree: port 3000; Antigravity worktree: `pnpm dev -p 3001`)
- `pnpm check` = typecheck + lint + unit tests. Must pass before a PR is marked ready.
- `pnpm test:e2e` = Playwright (WebKit, iPhone profile)
- `supabase db reset` = re-apply migrations + seed (local)
- `pnpm db:types` = regenerate `src/lib/db.types.ts`

## Non-negotiable rules

- **Money:** integer VND only; all arithmetic in `src/lib/domain/money/` ([ADR-0004](docs/adr/0004-money-as-integer-vnd.md), [code style §2](docs/conventions/code-style.md#2-money-non-negotiable)).
- **Time:** month boundaries in `Asia/Ho_Chi_Minh` ([ADR-0005](docs/adr/0005-fixed-timezone-calendar-month.md)).
- **Domain:** transfers are not expenses; fund contributions are envelope movements, not transactions ([ADR-0003](docs/adr/0003-envelope-budgeting-model.md)).
- **Data:** never hard-delete transactions; RLS on every table ([database](docs/conventions/database.md)).
- **Public repo:** no secrets, no real financial data, no unredacted receipts, no real numbers in screenshots.
- **Contract:** UI imports types/Zod/functions from `@/lib/domain`; it never redefines them.

## Process (GitFlow + PRs)

- Ownership by path: [files & folders §1.1](docs/conventions/files-and-folders.md#11-ownership). Don't edit paths you don't own; request the change in the issue or PR.
- Branches: [branching](docs/conventions/branching.md). Work only on your own `feature/|bugfix/|chore/|docs/<issue>-<slug>` branch from `develop`. Never commit to `develop`/`main`, never merge, never tag, never force-push after review started.
- Commits: [commits](docs/conventions/commits.md). Conventional Commits with a scope from the list, plus the AI trailer.
- New files: follow the matching recipe in [files & folders §3](docs/conventions/files-and-folders.md#3-recipes-creating-a-new-file).
- PRs and reviews: [pull requests](docs/conventions/pull-requests.md). Fill every template section; post reviews in the fixed format.
- Start every task by posting a `## Plan` comment on the issue. **Claude Code is the tech lead** ([ADR-0017](docs/adr/0017-claude-code-as-tech-lead.md)): it proceeds with its own plans and approves Antigravity's plans (Antigravity waits for Claude Code's `Plan approved`). Claude Code merges PRs once the merge rules are met.
- Ask Phú **only** for the items in the table in [ADR-0017](docs/adr/0017-claude-code-as-tech-lead.md): business rules, information only he has, accounts/secrets, UAT on his iPhone, production approval, destructive changes to real data, starting Antigravity sessions. Everything technical is decided by Claude Code.
- Don't change tests to make them pass unless the test is provably wrong; say so in the PR.
- If blocked or unsure about a business rule, stop and ask (label `needs-decision`). Don't invent rules.

<!-- BEGIN:nextjs-agent-rules -->

## This is NOT the Next.js you know

This version has breaking changes — APIs, conventions, and file structure may all differ from your training data. Read the relevant guide in `node_modules/next/dist/docs/` (resolved from this file's directory; in monorepos the `next` package may not be visible from the repo root) before writing any code. Heed deprecation notices.

This block is written and re-added by `next dev` — verify at `node_modules/next/dist/server/lib/generate-agent-files.js`. Removing it from a diff only re-creates the uncommitted change; committing it with your work keeps the tree clean.

<!-- END:nextjs-agent-rules -->
