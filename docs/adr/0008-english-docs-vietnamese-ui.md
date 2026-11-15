# ADR-0008: Write code and docs in English, UI in Vietnamese

- **Status:** Accepted
- **Date:** 2026-11-15
- **Deciders:** Phú
- **Related:** formerly D7 in `docs/DECISIONS.md` / PLAN §1

## Context

Docs are read by two coding agents and by portfolio visitors. The only end user is Vietnamese.

## Decision

We will write code, identifiers, comments, commit messages and **all documentation** in English. UI text is Vietnamese. Agents talk to Phú in Vietnamese in chat.

## Consequences

- ✅ Agents and international readers understand the repo.
- ⚠️ UI strings and docs use different languages; route names stay English.
