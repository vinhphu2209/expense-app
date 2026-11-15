# ADR-0004: Store money as integer VND

- **Status:** Accepted
- **Date:** 2026-11-15
- **Deciders:** Phú
- **Related:** formerly D3 in `docs/DECISIONS.md` / PLAN §1

## Context

VND has no subunit in practice. Floating-point arithmetic produces rounding errors; decimals add complexity without value.

## Decision

We will store all money as `bigint` VND in Postgres and handle it as safe-integer `number` (branded `Vnd`) in TypeScript. All money arithmetic lives in `src/lib/domain/money/` with unit tests; the UI only formats.

## Consequences

- ✅ Exact arithmetic, simple comparisons, no currency library.
- ⚠️ Percent-of-income calculations need an explicit rounding rule (round to thousands, PLAN §3.4).
- ⚠️ Multi-currency would require a new ADR.
- 🔁 Lint rule against float operations on money outside the money module.
