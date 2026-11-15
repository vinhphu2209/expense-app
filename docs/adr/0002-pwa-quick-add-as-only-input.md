# ADR-0002: Use a PWA with Quick-add as the only input method

- **Status:** Accepted
- **Date:** 2026-11-15
- **Deciders:** Phú
- **Related:** formerly D1 in `docs/DECISIONS.md` / PLAN §1

## Context

Almost all spending goes through MoMo, which offers no personal API, no export and no webhook. Any automated import is therefore impossible; the only reliable data source is the user logging each payment.

## Decision

We will build a Progressive Web App whose primary screen is **Quick-add**, optimised to log one expense in ≤ 5 seconds. All other capture paths (iOS Shortcuts, deep links, receipt OCR) feed the same ingest path.

## Consequences

- ✅ No dependency on third-party financial APIs.
- ✅ Speed of Quick-add becomes the main product metric.
- ⚠️ Data completeness depends on habit; reminders and Shortcuts (Phase 3) mitigate this.
- 🔁 Offline queue with idempotency (`client_id`) is required so no entry is lost.
