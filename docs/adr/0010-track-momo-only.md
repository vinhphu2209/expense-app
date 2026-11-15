# ADR-0010: Track MoMo, Cash and BNPL only

- **Status:** Accepted
- **Date:** 2026-11-15
- **Deciders:** Phú
- **Related:** formerly D9 in `docs/DECISIONS.md` / PLAN §1

## Context

Real spending goes through MoMo; bank accounts are not used for day-to-day spending.

## Decision

We will track only the accounts **MoMo** (default), **Cash** and **BNPL liabilities** (e.g. Shopee Later). No bank integrations.

## Consequences

- ✅ Smaller scope; Quick-add defaults to MoMo.
- ⚠️ All capture is manual or Shortcut-assisted.
- 🔁 Adding banks later requires a new ADR.
