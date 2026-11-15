# ADR-0013: Track work in GitHub Issues and review in pull requests

- **Status:** Accepted
- **Date:** 2026-11-15
- **Deciders:** Phú
- **Supersedes:** the file-based workflow (`docs/TASKS.md`, `docs/HANDOFF.md`, `docs/DECISIONS.md`)
- **Amended by:** [ADR-0017](0017-claude-code-as-tech-lead.md) (plan approval and merging)
- **Related:** [issues](../conventions/issues.md), [pull requests](../conventions/pull-requests.md)

## Context

The first setup tracked tasks in `docs/TASKS.md` and handoffs/reviews in `docs/HANDOFF.md`. Both agents edited these files on separate branches, so almost every merge would conflict. Reviews inside a markdown file are also invisible to GitHub: they aren't linked to commits, don't show CI status and can't gate a merge. The process should look like a real team's.

## Decision

We will track tasks in **GitHub Issues** (with templates, labels and milestones) and on a **GitHub Project** board. Handoff, review and merge happen in **pull requests**.

- Implementation plans are posted as issue comments.
- Reviews are posted as PR review comments in a fixed format.
- `docs/TASKS.md`, `docs/HANDOFF.md` and `docs/DECISIONS.md` are removed. Decisions move to ADRs.

## Consequences

- ✅ No merge conflicts on shared tracking files.
- ✅ Reviews sit next to the diff and the CI results, and the history is public for the portfolio.
- ⚠️ Agents need the `gh` CLI and network access to read tasks.
- ⚠️ GitHub doesn't let an account approve its own PR, so the review verdict is a convention, not a GitHub status (see [pull requests §5.2](../conventions/pull-requests.md#52-how-a-review-is-posted)).
