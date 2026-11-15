# ADR-0014: Develop in a public repository

- **Status:** Accepted
- **Date:** 2026-11-15
- **Deciders:** Phú
- **Related:** [ADR-0012](0012-dev-uat-prod-environments.md), [ADR-0013](0013-github-issues-and-prs.md), [SECURITY.md](../../SECURITY.md)

## Context

The project doubles as a portfolio. Public repositories also get some GitHub features for free that private repositories would need a paid plan for, such as required reviewers on deployment environments. However, the app handles personal financial data.

## Decision

We will make the GitHub repository **public**. Everything committed to it, logged by CI or uploaded by CI is treated as public.

## Consequences

- ✅ Portfolio visibility, plus free environment protection rules, rulesets, secret scanning and push protection.
- ⚠️ No real financial data anywhere in the repo: seed data is fictional, screenshots use UAT/seed data, receipts are redacted.
- ⚠️ CI logs and artifacts are public: never print secrets, and encrypt backups before upload.
- ⚠️ Workflows never use `pull_request_target`; fork PRs run without secrets.
- 🔁 On day one, enable secret scanning, push protection, Dependabot alerts and private vulnerability reporting.
- 🔁 License: proprietary, "All rights reserved" (see `LICENSE`). Code is public to read, not to use. It can be relaxed later (the sole author can relicense); it cannot be tightened for copies already taken.
