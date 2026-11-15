# ADR-0017: Claude Code acts as tech lead (approves plans, merges PRs)

- **Status:** Accepted
- **Date:** 2026-11-15
- **Deciders:** Phú
- **Supersedes:** the "Phú approves plans / Phú merges" rules in [ADR-0013](0013-github-issues-and-prs.md), [ADR-0015](0015-two-agents-with-ownership.md) and [ADR-0016](0016-claude-code-maintains-definition-files.md)
- **Related:** issue #57

## Context

Until now Phú approved every plan and merged every PR. For a solo project this made him the bottleneck for purely technical choices (tooling, file layout, review findings) that he doesn't want to make. He wants to be involved only where his input is actually needed: business rules and things only he can answer or do.

The review process stays valuable. It's what keeps quality up when no human reads every diff.

## Decision

**Claude Code is the tech lead.** It decides technical questions, approves plans, and merges PRs. Phú is involved only for the items in the table below.

### What Claude Code decides and does

| Area | Rule |
| --- | --- |
| Plans | Claude Code posts its own `## Plan` on the issue and proceeds, unless the plan contains an open business question (then `needs-decision`). It approves Antigravity's plans by commenting `Plan approved`. |
| Reviews | Every PR still gets an independent review before merge ([pull requests §5.1](../conventions/pull-requests.md#51-who-reviews)). Claude Code's own PRs are reviewed by a fresh-context reviewer subagent, plus `money-logic-reviewer` for money/DB, plus Antigravity `/verify-ui` when the change is visible in the app. |
| Merging | Claude Code merges into `develop`, `release/*` and `hotfix/*` when the merge rules are met ([pull requests §6](../conventions/pull-requests.md#6-merge-rules)). |
| Releases | Claude Code cuts `release/x.y.z`, writes the changelog, merges into `main`, tags, and back-merges, **after** Phú's UAT acceptance. |
| Disagreements | Claude Code decides technical disagreements and records lasting ones as ADRs. |

### What still needs Phú

| Needs Phú | Why | How Claude Code asks |
| --- | --- | --- |
| Business rules and product decisions | Only Phú knows how his money should be handled | Issue/PR comment, label `needs-decision` |
| Information only Phú has | Real balances, receipts, preferences, device facts | `needs-decision` |
| Accounts, billing, secrets | Creating Supabase/Vercel projects, adding secrets | Checklist in the issue; tell Phú in chat |
| UAT acceptance on the real iPhone before a release | Only Phú has the device and the real-life context | Release PR + chat message |
| Approving the production deployment | It touches his real financial data; GitHub requires a human approval on the `production` environment | GitHub deployment review request |
| Destructive changes to existing real data | Data loss can't be undone | `needs-decision` |
| Starting Antigravity sessions | Claude Code can't operate Antigravity | Exact prompt to paste, in chat |

Phú can still comment on or veto anything at any time. Every merge, review and decision is visible on GitHub.

## Consequences

- ✅ Phú's time goes only to decisions that need him; work no longer waits on routine approvals.
- ✅ The audit trail stays complete: plans on issues, reviews on PRs, decisions in ADRs.
- ⚠️ Claude Code can merge its own PRs. The safeguards are: CI must be green, an independent reviewer must approve, and rule changes must be called out in *Review focus* and summarised to Phú in chat.
- ⚠️ A wrong technical call can reach `develop`/UAT without a human seeing it. It can't reach production without Phú's UAT acceptance and deployment approval.
- 🔁 Revisit if a merged change causes a production incident.
