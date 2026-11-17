# Pull Request & Code Review Conventions

> Decision record: [ADR-0013 — GitHub Issues and PRs replace task files](../adr/0013-github-issues-and-prs.md).
> Related: [branching](branching.md) · [commits](commits.md) · [issues](issues.md)

Every change to `develop`, `release/*` and `main` goes through a pull request. The PR is the single place for: what changed, how to verify it, the review, and the decision to merge. (This replaces the former `docs/HANDOFF.md`.)

---

## 1. Before opening a PR

- [ ] There is an issue, and the branch is named after it ([branching §2.1](branching.md#21-branch-names)).
- [ ] The branch is rebased on the current target branch.
- [ ] `pnpm check` passes locally (typecheck + lint + unit tests).
- [ ] UI changes: `pnpm test:e2e` passes and screenshots at 390×844 exist.
- [ ] Migrations: `supabase db reset` works and `pnpm db:types` output is committed.

## 2. Title

The title **is** the squash commit message, so it must be a valid Conventional Commit header ([commits §1](commits.md#1-format)). The required check `pr-title` (`.github/workflows/pr-title.yml`) enforces this and re-runs when the title is edited.

```text
feat(quickadd): add S1 quick-add screen
```

Do not put the issue number in the title. Put `Closes #14` in the description.

## 3. Description

`.github/pull_request_template.md` is filled automatically. Every section is required. Write `N/A` with a reason instead of deleting a section.

| Section | What to write |
| --- | --- |
| **Summary** | 1–3 sentences: what and why |
| **Linked issue** | `Closes #14` (or `Refs #14` for partial work) |
| **Changes** | Bullet list of notable changes, grouped by area |
| **How to verify** | Exact commands and click paths a reviewer can follow |
| **Screenshots** | UI only: before/after at 390×844, using **seed data only** |
| **Database** | Migration file names, backward-compatible yes/no, rollback plan |
| **Security & privacy** | New secrets, RLS changes, data exposure, public-repo check |
| **Review focus** | Where the reviewer should look hardest |
| **Author** | `claude-code`, `antigravity` or `human`, plus the issue's plan ID |
| **Checklist** | Definition of Done (§7) |

## 4. Size and scope

- One issue per PR. One concern per PR.
- Target **≤ 400 changed lines** (lockfiles, generated `db.types.ts` and snapshots excluded).
- More than 800 lines: split the PR, or explain in the Summary why it can't be split.
- Refactors and behaviour changes go in separate PRs.
- Keep the PR as **Draft** while work is in progress. Mark it *Ready for review* only when the checklist is done.

## 5. Review process

### 5.1 Who reviews

| PR contains | Primary reviewer | Additional required check |
| --- | --- | --- |
| UI by Antigravity | Claude Code (`/review-ag <pr>`) | — |
| Anything by Claude Code | Fresh-context reviewer subagent (always) | Antigravity `/verify-ui <pr>` when the change is visible in the app |
| `src/lib/domain/money/**`, month-close, views | `money-logic-reviewer` subagent | Unclear business rules behind the tests go to Phú (`needs-decision`) |
| `supabase/migrations/**`, RLS, auth, API tokens | `money-logic-reviewer` subagent | Destructive changes to real data: `needs-decision` |
| Docs, ADRs, conventions | Fresh-context reviewer subagent | Rule changes summarised to Phú in chat |
| `release/*`, `hotfix/*` into `main` | Reviewer subagent | Phú's UAT acceptance comment on the PR; Phú approves the production deployment |
| Back-merge (`main` or `chore/back-merge-*` → `develop` or `release/*`) | — (exempt when conflict-free) | A back-merge with conflicts needs the reviewer subagent |

**Claude Code merges** (tech lead, [ADR-0017](../adr/0017-claude-code-as-tech-lead.md)). It never merges its own PR without an independent reviewer's `APPROVE` / `APPROVE WITH NITS`.

### 5.2 How a review is posted

Both agents act through Phú's GitHub account. GitHub won't let an author approve their own PR, so reviews are posted as **review comments** with a fixed header:

```bash
gh pr review 42 --comment --body-file review.md
```

`review.md` format:

```markdown
## Review — Claude Code — REQUEST CHANGES

**Scope checked:** domain contract, money math, data fetching, security, a11y, tests.

1. **[blocker]** `src/app/(app)/add/page.tsx:58` — amount is summed in the component (`a + b`).
   → Use `addVnd()` from `@/lib/domain/money`.
2. **[should]** `src/components/quick-add/envelope-chips.tsx:21` — no empty state when the user has no envelopes.
   → Render `<EmptyEnvelopes />` with a link to Settings.
3. **[nit]** `...` — ...

**Verdict:** REQUEST CHANGES (1 blocker).
```

- Reviewer names in the header: `Claude Code`, `Antigravity`, `Reviewer subagent` (a fresh-context Claude reviewer that has not seen the author's session), or `money-logic-reviewer`.
- Verdict is one of `APPROVE`, `APPROVE WITH NITS`, `REQUEST CHANGES`.
- Severity: **blocker** (must fix before merge), **should** (fix now, or open a follow-up issue and link it), **nit** (optional).
- Each finding gives `file:line`, the problem, and a concrete fix.
- For line-specific comments the reviewer may also use inline review comments; the summary comment above is still required.

### 5.3 Responding to a review

- Reply to every finding: `Fixed in <short-sha>` or `Won't fix: <reason>` or `Follow-up: #<issue>`.
- Push new commits. Do not force-push after review started.
- Re-request review by commenting `@reviewer: ready for re-review` with a summary of changes. (Use the agent name, not a GitHub handle.)
- Never change a test only to make it pass, unless the test is provably wrong. If you do, say so explicitly in the reply.

### 5.4 Disagreements

1. Both sides state their reasoning in the PR thread, under a comment starting with `### Disagreement`.
2. Claude Code decides technical disagreements in the thread; business questions go to Phú (`needs-decision`).
3. If the decision is a lasting rule, it becomes an ADR ([documentation §3](documentation.md#3-architecture-decision-records)).
4. An agent never "wins" by overwriting the other's code.

## 6. Merge rules

A PR may be merged only when **all** of these are true:

- [ ] CI is green: the required checks `check`, `db` and `pr-title` (plus e2e for UI changes once it exists, #30).
- [ ] For **each** required reviewer in §5.1, that reviewer's **latest** verdict is `APPROVE` or `APPROVE WITH NITS`, and no required reviewer is the PR's author agent. (Conflict-free back-merges are exempt.)
- [ ] Every `blocker` and `should` finding has a reply.
- [ ] All conversations are resolved.
- [ ] The PR is not labelled `blocked`, `do-not-merge` or `needs-decision`.
- [ ] `db:migration` PRs into `develop`: no `release/*` branch is open.
- [ ] PRs into `main`: Phú has posted his UAT acceptance on the PR.

`/merge <pr>` (`.claude/commands/merge.md`) checks exactly this list.

Merge method depends on the target ([branching §5](branching.md#5-merge-methods-why-they-differ)). With squash, the squash commit message is the PR title plus `Closes #<issue>` and the `Co-Authored-By` / `Assisted-by` trailers.

After merge: the issue closes automatically and the Project card moves to *Done*. The other agent's worktree runs `git rebase origin/develop` before continuing.

## 7. Definition of Done (PR checklist)

Copied into every PR by the template:

- [ ] `pnpm check` green (typecheck, lint, unit tests)
- [ ] Money logic has unit tests; no floating-point money anywhere
- [ ] New/changed tables have RLS and pgTAP tests
- [ ] UI works at 390×844 and in iPhone standalone mode where relevant; screenshots attached
- [ ] No secrets, no real personal data, no unredacted receipts (public repo)
- [ ] `.env.example` and `src/env.ts` updated for new variables
- [ ] Docs updated in the same PR (README, guides, ADR if a decision was made)
- [ ] `CHANGELOG.md` → `Unreleased` updated for `feat`/`fix`
- [ ] Reviewed according to §5.1

## 8. Labels used on PRs

Same labels as issues ([issues §3](issues.md#3-labels)). Additionally:

| Label | Meaning |
| --- | --- |
| `db:migration` | Contains a migration. Triggers extra review and the release-freeze rule. |
| `do-not-merge` | Hard stop, with a comment explaining why. |
| `needs-decision` | Waiting for Phú: a business rule or information only he has. |
