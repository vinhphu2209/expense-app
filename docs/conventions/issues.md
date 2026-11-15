# Issue & Project Board Conventions

> Decision record: [ADR-0013](../adr/0013-github-issues-and-prs.md).
> Related: [pull requests](pull-requests.md) · [plan](../plan.md)

GitHub Issues are the task list and GitHub Projects is the board. Together they replace the former `docs/TASKS.md`. [`docs/plan.md`](../plan.md) still defines **what** to build. Issues track **who, when and status**.

---

## 1. Issue types (templates)

| Template | File | Use for |
| --- | --- | --- |
| Task | `.github/ISSUE_TEMPLATE/task.yml` | Any planned work item from `plan.md` §6, or new work |
| Bug | `.github/ISSUE_TEMPLATE/bug.yml` | Something that behaves differently from the plan/acceptance criteria |

Questions and decisions use a Task with the `needs-decision` label. Blank issues are disabled.

## 2. Title

```text
[<plan-id>] <short imperative description>
```

- `<plan-id>` is the ID from `plan.md` §6 (`P1-03`). New work that is not in the plan uses `[—]` until Phú adds it to the plan.
- Bugs: `[bug] <what is wrong>`. Example: `[bug] Transactions at 23:30 on the last day land in next month`.

Examples: `[P0-01] Scaffold Next.js + tooling`, `[P1-03] Build S1 Quick-add screen`.

## 3. Labels

Each issue has exactly one `type:`, at least one `area:` and exactly one `agent:` label.

| Group | Labels |
| --- | --- |
| Type | `type:feature`, `type:bug`, `type:chore`, `type:docs`, `type:refactor`, `type:test` |
| Area | `area:db`, `area:domain`, `area:money`, `area:api`, `area:ui`, `area:pwa`, `area:auth`, `area:ci`, `area:docs` |
| Owner | `agent:claude-code`, `agent:antigravity`, `agent:human` |
| Priority | `priority:high`, `priority:normal` (default when absent), `priority:low` |
| Flow | `blocked`, `needs-decision`, `db:migration`, `do-not-merge`, `good-first-issue` |

## 4. Milestones

One milestone per roadmap phase: `Phase 0 — Foundation`, `Phase 1 — MVP`, `Phase 2 — Funds & Month close`, `Phase 3 — iPhone capture`, `Phase 4 — Insights`.
Releases are **not** milestones. A release contains whatever is on `develop` when it's cut.

## 5. Project board

Project: **Expense App Roadmap** (GitHub Projects, board view).

| Column | Meaning | Moves when |
| --- | --- | --- |
| Backlog | Exists, not ready | Issue created |
| Ready | Meets Definition of Ready (§6) | Phú moves it |
| Planning | Owner is writing the plan in the issue | Agent runs `/next-task` or `/next-ui-task` |
| In progress | Branch exists, draft PR open | Phú approves the plan |
| In review | PR ready for review | PR marked *Ready* |
| Done | PR merged | Automatic on merge |

Custom fields: `Plan ID` (text), `Phase` (milestone), `Owner` (agent).

## 6. Definition of Ready

An issue can move to **Ready** when it has:

- [ ] Acceptance criteria (copied from `plan.md` §6 or written in the issue)
- [ ] `type:`, `area:`, `agent:` labels and a milestone
- [ ] Dependencies listed as `Blocked by #<n>`. All of them done, or explicitly allowed to run in parallel
- [ ] No open `needs-decision` question that affects it

## 7. Plans live in the issue

Before coding, the owner posts its implementation plan as an **issue comment** headed `## Plan`. It covers files, signatures, test cases and risks. Phú approves by replying `Plan approved` (or edits it). This keeps the reasoning public and attached to the work.

## 8. Dependencies

Write dependencies in the issue body: `Blocked by #12`, `Blocks #20`. Use GitHub's sub-issues for features that need both agents (logic first, then UI), for example P1-04:

```text
[P1-04] Smart envelope chips            ← parent
 ├─ [P1-04a] rankEnvelopes() domain logic   agent:claude-code
 └─ [P1-04b] Envelope chips UI              agent:antigravity   Blocked by P1-04a
```
