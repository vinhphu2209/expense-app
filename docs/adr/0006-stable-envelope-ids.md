# ADR-0006: Give envelopes stable IDs and aliases

- **Status:** Accepted
- **Date:** 2026-11-15
- **Deciders:** Phú
- **Related:** formerly D5 in `docs/DECISIONS.md` / PLAN §1

## Context

The sheet lost history when categories were renamed (Health → HealthFund, Study → StudyFund).

## Decision

We will identify envelopes by UUID; names are labels only. Old names are kept in `envelope_aliases` for imports and search.

## Consequences

- ✅ Renaming never breaks history or reports.
- 🔁 The sheet import maps old names through aliases (PLAN §7).
