# ADR-0005: Use Asia/Ho_Chi_Minh and calendar months

- **Status:** Accepted
- **Date:** 2026-11-15
- **Deciders:** Phú
- **Related:** formerly D4 in `docs/DECISIONS.md` / PLAN §1

## Context

Budgets are monthly. Timestamps are stored in UTC; a payment at 23:30 on the last day of the month in Vietnam is already the next day in some timezones, and `00:30` local is the previous day in UTC.

## Decision

We will compute every month boundary and "today" in the fixed timezone **Asia/Ho_Chi_Minh**, and a budget month is a calendar month. Conversion happens only through `src/lib/domain/time/` helpers.

## Consequences

- ✅ Matches the existing sheet and the user's real life.
- ⚠️ Travelling abroad still books in Vietnam time (accepted).
- 🔁 Tests for transactions at 23:30 / 00:30 around month ends.
