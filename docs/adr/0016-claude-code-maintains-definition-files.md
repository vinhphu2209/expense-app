# ADR-0016: Claude Code maintains the definition files

- **Status:** Accepted
- **Date:** 2026-11-15
- **Deciders:** Phú
- **Supersedes:** the "Phú only" file ownership in [ADR-0015](0015-two-agents-with-ownership.md) and [files & folders §1.1](../conventions/files-and-folders.md#11-ownership)
- **Related:** issue #55, PR #54

## Context

The first setup reserved the files that define how the project works for Phú: agent rules, plan, ADRs and conventions. Agents could only propose changes, and Phú had to edit the files himself. In practice this created friction. Answers to product questions, settings that changed, and tool-generated content (Next.js writes a managed block into `AGENTS.md`) all needed a manual step before the docs matched reality.

The opposite extreme, letting every agent edit these files, risks the two agents rewriting each other's rules. Every change already goes through a PR that Phú reviews and merges.

## Decision

We will make **Claude Code the only agent that edits the definition files**, always through a normal PR that Phú merges:

| Definition files |
| --- |
| `AGENTS.md`, `CLAUDE.md`, `.claude/**`, `.agents/**` (including Antigravity's own rules and workflows) |
| `.github/**` (templates, CODEOWNERS, workflows, Dependabot) |
| `docs/plan.md`, `docs/ai-workflow.md`, `docs/adr/**`, `docs/conventions/**`, `docs/operations/**` |

Antigravity never edits these files. When it needs a change, it comments `Request for Claude Code: …` on the issue or PR.

Phú keeps the decisions that matter:

- approving plans (`Plan approved`);
- answering `needs-decision` questions (agents don't invent business rules);
- merging every PR, which is also how an ADR becomes Accepted.

Code ownership between the two agents is unchanged.

## Consequences

- ✅ Docs stay in sync with decisions and settings without a manual step for Phú.
- ✅ One agent is responsible for the consistency of all rules, so the two agents can't drift apart.
- ✅ Tools that manage parts of these files (Next.js `agentRules`) can stay enabled. If `next dev` changes the managed block in Antigravity's worktree, Antigravity discards the change (`git restore AGENTS.md`) and Claude Code commits it.
- ⚠️ Rule changes are easier to slip in. A PR that touches definition files must call them out in *Review focus*, and Phú reads them as carefully as code.
- 🔁 A rule change that reflects a decision still needs an ADR ([documentation §3.1](../conventions/documentation.md#31-when-to-write-an-adr)).
