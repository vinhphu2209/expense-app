# Commit Conventions

> Related: [branching](branching.md) · [pull requests](pull-requests.md)

We use [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/). This is enforced by `commitlint` in a local git hook (lefthook) and by CI on PR titles. Because feature PRs are squash-merged, **the PR title becomes the commit on `develop`**, so the same format applies to both.

---

## 1. Format

```text
<type>(<scope>): <subject>

<body>

<footer>
```

### 1.1 Type

| Type | Use when | In CHANGELOG? |
| --- | --- | --- |
| `feat` | Adds user-visible behaviour | Added |
| `fix` | Fixes a bug | Fixed |
| `perf` | Improves performance, no behaviour change | Changed |
| `refactor` | Changes code structure, no behaviour change | — |
| `test` | Adds or changes tests only | — |
| `docs` | Documentation only (incl. ADRs) | — |
| `style` | Formatting only (Prettier, whitespace) | — |
| `build` | Build system, dependencies, `package.json` scripts | — |
| `ci` | GitHub Actions, CI config | — |
| `chore` | Anything else that is not shipped (release bumps, housekeeping) | — |
| `revert` | Reverts a previous commit | Fixed / Removed |

### 1.2 Scope (required)

Pick exactly one from this list. To add a scope, change this file in a `docs/` PR.

| Scope | Covers |
| --- | --- |
| `db` | `supabase/migrations`, seed, RLS, views |
| `domain` | `src/lib/domain/**` excluding money |
| `money` | `src/lib/domain/money/**` |
| `txn` | Transactions: server actions, list, edit (S2) |
| `quickadd` | Quick-add screen (S1), templates, chips |
| `budget` | Monthly budget (S3), new-month logic |
| `funds` | Funds (S4) |
| `accounts` | Accounts, debts, recurring bills (S5) |
| `month-close` | Month-close engine and wizard (S6) |
| `insights` | Insights (S7) |
| `settings` | Settings (S8), API tokens UI |
| `ingest` | `/api/ingest`, receipt parser, iOS Shortcuts |
| `auth` | Login, session, middleware |
| `pwa` | Manifest, icons, service worker, offline queue, push |
| `ui` | Shared components, design tokens, layout shell |
| `e2e` | Playwright tests and fixtures |
| `ci` | Workflows, repo automation |
| `deps` | Dependency updates (Dependabot uses this) |
| `docs` | General documentation |
| `adr` | Architecture Decision Records |
| `release` | Version bumps, changelog, back-merges |

### 1.3 Subject

- Imperative mood, lowercase first letter, no trailing period: `add numeric keypad`, not `Added numeric keypad.`
- At most 72 characters for the whole header line.
- English only (see [ADR-0008](../adr/0008-english-docs-vietnamese-ui.md)). Vietnamese UI strings may appear in quotes in the body.

### 1.4 Body (optional, recommended for non-trivial commits)

- Explain **why**, not what. The diff shows what.
- Wrap at 100 characters.

### 1.5 Footer

| Footer | When |
| --- | --- |
| `Refs: #14` | Commit relates to an issue (on branch commits) |
| `Closes: #14` | Only in the **PR description**, so the squash commit closes the issue |
| `BREAKING CHANGE: <what and how to migrate>` | Any breaking change (also add `!` after the scope: `feat(db)!: ...`) |
| `Co-Authored-By: <name> <email>` | Commit written by an AI agent (see §3) |

---

## 2. Examples

```text
feat(quickadd): suggest envelopes by time of day

Morning purchases are mostly Food/Transport; ranking by frequency alone
pushed Shopping to the top on weekends.

Refs: #18
```

```text
fix(money): parse "1tr2" as 1,200,000 instead of 1,000,002
```

```text
feat(db)!: store envelope split ratios in settings

BREAKING CHANGE: month_close_split moves from a constant to settings.month_close_split.
Run migration 20261120_add_month_close_split.sql before deploying.
```

```text
chore(release): 0.2.0
```

| ❌ Bad | Problem |
| --- | --- |
| `update code` | No type, no scope, says nothing |
| `feat: Quick add` | No scope; capitalised; not imperative |
| `fix(money): fixed bug in parser.` | Past tense; trailing period; vague |
| `feat(quickadd,txn): ...` | One scope only — split the commit |
| `wip` | Never push WIP commits; use a draft PR and squash before review if needed |

---

## 3. AI-authored commits

Transparency matters in a public portfolio repo: every commit made by an agent says so.

- Claude Code appends: `Co-Authored-By: Claude <noreply@anthropic.com>` (the exact model name may appear).
- Antigravity appends: `Assisted-by: Antigravity` (it has no official no-reply address, so a plain trailer is used instead of a fake email).
- The squash commit on `develop` must keep these trailers. GitHub pre-fills `Co-Authored-By` lines from branch commits; Phú copies any `Assisted-by` line into the squash message when merging.

---

## 4. Commit size

- One logical change per commit. If the subject needs "and", split it.
- Migrations: the migration, the regenerated `db.types.ts` and the matching Zod schemas go in the **same** commit (they must never drift).
- Never commit: `.env*` (except `.env.example`), real personal financial data, unredacted receipts, build output, or `node_modules`.
