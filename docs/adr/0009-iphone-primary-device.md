# ADR-0009: Target iPhone Safari PWA first

- **Status:** Accepted
- **Date:** 2026-11-15
- **Deciders:** Phú
- **Related:** formerly D8 in `docs/DECISIONS.md` / PLAN §1

## Context

iOS does not let apps read other apps' notifications, PWAs have no Web Share Target, and installation only happens via Safari → Add to Home Screen.

## Decision

We will design and test for an **installed iPhone Safari PWA** first (390×844, standalone, safe areas). Capture helpers use iOS Shortcuts (deep link, API token, automation, receipt OCR).

## Consequences

- ✅ Clear device constraints for every UI decision.
- ⚠️ Android notification listeners and bank webhooks are dropped from the roadmap.
- 🔁 Playwright runs WebKit with an iPhone profile; real-device checks by Phú.
