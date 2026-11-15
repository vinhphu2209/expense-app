# ADR-0016: Let agents update rules and docs through pull requests

- **Status:** Accepted
- **Date:** 2026-11-15
- **Deciders:** Phú
- **Supersedes:** the "Phú only" file ownership in [ADR-0015](0015-two-agents-with-ownership.md) and [files & folders §1.1](../conventions/files-and-folders.md#11-ownership)
- **Related:** issue #55, PR #54

## Context

The first setup reserved `AGENTS.md`, `CLAUDE.md`, the agent rules, `docs/plan.md`, ADRs and conventions for Phú. Agents could only propose changes in comments, and Phú had to edit the files himself.

In practice this created friction. Answers to product questions, settings that changed, and tool-generated content (Next.js writes a managed block into `AGENTS.md`) all needed a manual step before the docs matched reality. Every change already goes through a PR that Phú reviews and merges, so the PR is already the control point.

## Decision

We will let any agent update **any** file, including rules, the plan, ADRs and conventions, **through a normal PR**, whenever something needs updating. Phú keeps the decisions that matter:

- approving plans (`Plan approved`) before work starts;
- merging every PR (which is also how an ADR becomes Accepted);
- answering `needs-decision` questions. Agents still don't invent business rules.

Path ownership **between the two agents** (Claude Code vs Antigravity code areas) is unchanged, because it prevents the agents from editing each other's work in parallel.

## Consequences

- ✅ Docs stay in sync with decisions and settings without a manual step for Phú.
- ✅ Tools that manage parts of agent files (Next.js `agentRules`) can be left enabled.
- ⚠️ Rule changes are easier to slip in. Reviewers must read changes to `AGENTS.md`, `CLAUDE.md`, `.agents/rules/**` and `docs/conventions/**` as carefully as code. The PR's *Review focus* section must call them out.
- 🔁 A rule change that reflects a decision still needs an ADR ([documentation §3.1](../conventions/documentation.md#31-when-to-write-an-adr)).
