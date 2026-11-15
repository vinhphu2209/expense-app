# ADR-0003: Model budgets as envelopes

- **Status:** Accepted
- **Date:** 2026-11-15
- **Deciders:** Phú
- **Related:** formerly D2 in `docs/DECISIONS.md` / PLAN §1

## Context

The Google Sheet mixes spending categories and savings funds in one list. Funds should accumulate across months while living expenses reset monthly.

## Decision

We will use a YNAB-style **envelope model**: each envelope belongs to a group and has a `rollover` flag. Non-rollover envelopes get a fresh budget each month; rollover envelopes (funds) carry a running balance. Fund contributions are envelope movements, not transactions.

## Consequences

- ✅ Clear separation between spending and saving; month-close rule becomes automatable.
- ⚠️ Two kinds of money movement (transactions vs envelope movements) to keep apart in all views.
- 🔁 `envelope_movements` table; views must never count movements as spending.
