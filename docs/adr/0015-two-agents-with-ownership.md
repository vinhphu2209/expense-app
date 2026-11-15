# ADR-0015: Split work between two AI agents by ownership boundaries

- **Status:** Accepted
- **Date:** 2026-11-15
- **Deciders:** Phú
- **Related:** [ai-workflow.md](../ai-workflow.md), [files & folders §1.1](../conventions/files-and-folders.md#11-ownership)

## Context

Development uses Claude Code (in VS Code) and Antigravity. Money logic must be exactly right and consistently tested. UI work benefits from fast iteration with a built-in browser. When two agents edit the same files, they create conflicts and contradictory designs.

## Decision

We will split work by area:

- **Claude Code** owns architecture, the database, domain/money logic, server code, security and code review.
- **Antigravity** owns UI, the PWA and browser verification.

Ownership is defined by path. Work is contract-first: domain types and Zod schemas are merged before the UI that uses them. Each agent reviews the other's PRs. Phú approves plans and merges.

## Consequences

- ✅ Clear accountability; the money logic has one owner end to end.
- ✅ Cross-review catches issues each agent alone would miss.
- ⚠️ Features that span both sides take two PRs (logic first, then UI).
- 🔁 Roles can be swapped through a new ADR.
