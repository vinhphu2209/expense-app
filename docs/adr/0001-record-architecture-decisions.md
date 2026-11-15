# ADR-0001: Record architecture decisions

- **Status:** Accepted
- **Date:** 2026-11-15
- **Deciders:** Phú

## Context

Two AI agents and one human build this app. Decisions made in chat are lost between sessions, and agents re-open settled questions. The repo is also a public portfolio: readers should be able to see *why* the system looks the way it does.

## Decision

We will record every significant decision as an Architecture Decision Record in `docs/adr/`, one file per decision, following [`template.md`](template.md) and the rules in [documentation conventions §3](../conventions/documentation.md#3-architecture-decision-records).

## Consequences

- ✅ Decisions are discoverable, reviewable in PRs, and linkable from code and docs.
- ✅ Agents can be told "read ADR-0004" instead of re-explaining rules.
- ⚠️ Small writing overhead per decision.
- 🔁 The former `docs/DECISIONS.md` (D1–D9) is migrated into ADR-0002 … ADR-0010.
