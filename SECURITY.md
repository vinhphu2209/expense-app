# Security Policy

## Reporting a vulnerability

Please **do not open a public issue**. Use GitHub's private vulnerability reporting: *Security* tab → *Report a vulnerability*. You will get a reply within 7 days.

## Supported versions

Only the latest release on `main` is supported.

## How this project protects data

This is a personal finance app in a **public** repository ([ADR-0014](docs/adr/0014-public-repository.md)).

| Area | Measure |
| --- | --- |
| Data isolation | Row Level Security on every table (`user_id = auth.uid()`); views use `security_invoker = true` ([database conventions](docs/conventions/database.md)) |
| Secrets | Only in `.env.local` (git-ignored), Vercel env vars and GitHub Environment secrets; validated by `src/env.ts`; GitHub secret scanning + push protection enabled |
| Server-only code | `import "server-only"` guard; service-role key never reaches client bundles |
| API tokens (iOS Shortcuts) | Stored as hashes, revocable, scoped to one user |
| Environments | Production data never copied to dev/UAT; UAT uses fictional seed data ([environments](docs/operations/environments.md)) |
| CI | No secrets in logs; no `pull_request_target`; fork PRs run without secrets; backups encrypted before upload |
| Audit | Transactions are soft-deleted; every update/delete is written to `audit_log` |
| Dependencies | Dependabot weekly updates and alerts |
