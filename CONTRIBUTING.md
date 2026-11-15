# Contributing

This is a personal project built by one human (Phú) with two AI coding agents, Claude Code and Antigravity. The process is deliberately the same as a small professional team's. Outside contributions are welcome as issues; PRs from forks are reviewed case by case.

## The short version

1. **Issue first.** Every change starts from a GitHub issue ([issues](docs/conventions/issues.md)).
2. **Plan in the issue.** Post a `## Plan` comment; wait for `Plan approved`.
3. **Branch from `develop`:** `feature/<issue>-<slug>` ([branching](docs/conventions/branching.md)).
4. **Commit with Conventional Commits:** `feat(quickadd): add numeric keypad` ([commits](docs/conventions/commits.md)).
5. **Open a draft PR into `develop`** using the template; mark it ready when the Definition of Done is met ([pull requests](docs/conventions/pull-requests.md)).
6. **Review:** the other agent reviews, Phú reviews and merges (squash).
7. **Release:** `release/x.y.z` → UAT on iPhone → `main` + tag `vx.y.z` → prod ([branching §4.2](docs/conventions/branching.md#42-release)).

## Where things go

- New file? Follow the recipe in [files & folders](docs/conventions/files-and-folders.md#3-recipes-creating-a-new-file).
- Code style: [code-style.md](docs/conventions/code-style.md). Database: [database.md](docs/conventions/database.md).
- New decision? Write an ADR ([documentation §3](docs/conventions/documentation.md#3-architecture-decision-records)).

## Local setup

See [docs/guides/local-setup.md](docs/guides/local-setup.md).

## Public repo rules

Never commit secrets, real financial data, unredacted receipts or screenshots with real numbers. See [SECURITY.md](SECURITY.md) and [ADR-0014](docs/adr/0014-public-repository.md).
