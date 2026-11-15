# Branching & Release Conventions (GitFlow)

> Decision record: [ADR-0011 — GitFlow branching](../adr/0011-gitflow-branching.md).
> Related: [commits](commits.md) · [pull requests](pull-requests.md) · [environments](../operations/environments.md)

This repo uses **GitFlow**. Every change reaches `main` through a pull request, and every commit on `main` is a tagged release.

---

## 1. Long-lived branches

| Branch | Purpose | Deploys to | Who merges into it | Protected |
| --- | --- | --- | --- | --- |
| `main` | Production. Every commit is a released version with a tag `vX.Y.Z`. | **prod** | Claude Code, only from `release/*` or `hotfix/*`, after Phú's UAT acceptance | Yes |
| `develop` | Integration branch. Always deployable to UAT. | **uat** | Claude Code, from short-lived branches, when [pull requests §6](pull-requests.md#6-merge-rules) is met | Yes |

Never commit directly to `main` or `develop`. Never force-push them. Never delete them.

## 2. Short-lived branches

| Prefix | Branch from | Merge into | Merge method | Use for |
| --- | --- | --- | --- | --- |
| `feature/` | `develop` | `develop` | **Squash** | New behaviour (one GitHub issue) |
| `bugfix/` | `develop` or `release/*` | the branch it came from | **Squash** | Bugs that are **not** in production yet |
| `chore/` | `develop` | `develop` | **Squash** | Tooling, deps, CI, refactors with no behaviour change |
| `docs/` | `develop` | `develop` | **Squash** | Documentation-only changes |
| `release/` | `develop` | `main`, then back-merge to `develop` | **Merge commit** | Stabilising a version |
| `hotfix/` | `main` | `main`, then back-merge to `develop` | **Merge commit** | Urgent fix for a bug in production |

`chore/` and `docs/` are not part of classic GitFlow. They follow exactly the same rules as `feature/` and exist only so the branch name says what the change is.

### 2.1 Branch names

```text
<prefix>/<issue-number>-<slug>        feature, bugfix, chore, docs
release/<major>.<minor>.<patch>       release
hotfix/<major>.<minor>.<patch>        hotfix
```

Rules:

- `<issue-number>` is the GitHub issue number. **No issue, no branch** (exceptions: `release/*` and `hotfix/*`).
- `<slug>`: lowercase ASCII, kebab-case, at most 40 characters, no Vietnamese diacritics, no task-ID prefixes.
- A branch maps to exactly one issue. If the work grows, split the issue.

| ✅ Good | ❌ Bad | Why it is bad |
| --- | --- | --- |
| `feature/14-quick-add-screen` | `feature/quick-add` | No issue number |
| `bugfix/31-month-boundary-utc` | `bugfix/31-Fix_Month` | Uppercase and underscore |
| `chore/22-add-commitlint` | `phu/test` | Unknown prefix |
| `release/0.2.0` | `release/v0.2.0` | No `v` in branch names (tags only) |
| `hotfix/0.2.1` | `hotfix/31-month-bug` | Hotfix branches are named after the version |

Agent ownership is **not** encoded in the branch name. It lives on the issue and PR as a label (`agent:claude-code`, `agent:antigravity`, `agent:human`). See [issues](issues.md#3-labels).

---

## 3. Versioning

- [Semantic Versioning 2.0.0](https://semver.org/): `MAJOR.MINOR.PATCH`.
- Phases 0–1 ship as `0.x.y`. `1.0.0` is cut when the Google Sheet is retired (PLAN §6 milestone).
- While on `0.x`: a breaking change bumps MINOR, everything else bumps PATCH.
- The version lives in `package.json` → `version`. The tag is `v` + that version (`v0.2.0`).
- Every release has a `CHANGELOG.md` entry ([Keep a Changelog](https://keepachangelog.com/en/1.1.0/)) and a GitHub Release with the same notes.

---

## 4. Workflows (step by step)

All commands assume the working tree is clean. `gh` is the GitHub CLI.

### 4.1 Feature / bugfix / chore / docs

```bash
# 1. Start from an up-to-date develop
git switch develop && git pull --ff-only
git switch -c feature/14-quick-add-screen

# 2. Work in small Conventional Commits (see commits.md)
git commit -m "feat(quickadd): add numeric keypad"

# 3. Keep the branch current (rebase is allowed while the branch is yours alone)
git fetch origin && git rebase origin/develop

# 4. Push and open a DRAFT PR early
git push -u origin feature/14-quick-add-screen
gh pr create --draft --base develop --fill --template pull_request_template.md

# 5. When the Definition of Done is met
gh pr ready
```

After merge, the head branch is deleted automatically (repo setting). Locally: `git switch develop && git pull --ff-only && git branch -d feature/14-quick-add-screen`.

**Force-push rule:** you may `--force-with-lease` your own branch **until review starts**. After the first review comment, push new commits only, so the reviewer can see what changed. The squash merge cleans up history anyway.

### 4.2 Release

A release collects everything on `develop` into a version for production.

```bash
# 1. Cut the release branch
git switch develop && git pull --ff-only
git switch -c release/0.2.0

# 2. Bump version + changelog in one commit
pnpm version 0.2.0 --no-git-tag-version
#    edit CHANGELOG.md: move "Unreleased" items under "## [0.2.0] - YYYY-MM-DD"
git commit -am "chore(release): 0.2.0"
git push -u origin release/0.2.0

# 3. Open the release PR into main
gh pr create --base main --title "chore(release): 0.2.0" --body-file CHANGELOG-excerpt.md
```

While `release/0.2.0` is open:

- UAT runs the release branch. Phú does acceptance testing on a real iPhone.
- **Only fixes** land on the release branch, via `bugfix/<issue>-<slug>` PRs targeting `release/0.2.0` (squash).
- Feature work continues on `develop`, but PRs labelled `db:migration` wait until the release is finished, because UAT shares one database. See [environments §4](../operations/environments.md#4-database-migrations).

When UAT passes:

```bash
# 4. Merge release → main with a MERGE COMMIT (Claude Code, after the reviewer subagent's APPROVE
#    and Phú's UAT acceptance comment on the release PR)
/merge <release-pr>

# 5. Tag main and publish the GitHub Release
git switch main && git pull --ff-only
git tag -a v0.2.0 -m "v0.2.0"
git push origin v0.2.0
gh release create v0.2.0 --title "v0.2.0" --notes-from-tag   # or paste the CHANGELOG section

# 6. Back-merge main → develop through a PR (merge commit)
git switch -c chore/back-merge-0.2.0 main
git push -u origin chore/back-merge-0.2.0
gh pr create --base develop --title "chore(release): back-merge v0.2.0 into develop" --body "Back-merge after release v0.2.0."
/merge <back-merge-pr>    # exempt from review when conflict-free (pull requests §6)
```

The tag push triggers the production deployment (database migrations first, then the app), gated by the `production` GitHub Environment. See [environments §3](../operations/environments.md#3-deployment-pipeline).

### 4.3 Hotfix

Only for a bug that is **already in production** and cannot wait for the next release.

```bash
git switch main && git pull --ff-only
git switch -c hotfix/0.2.1
# fix + regression test
git commit -m "fix(budget): compute month boundary in Asia/Ho_Chi_Minh"
pnpm version 0.2.1 --no-git-tag-version && # update CHANGELOG.md
git commit -am "chore(release): 0.2.1"
git push -u origin hotfix/0.2.1
gh pr create --base main --title "fix(budget): month boundary in Asia/Ho_Chi_Minh (hotfix 0.2.1)"
```

Then repeat steps 4–6 of §4.2: merge commit into `main` → tag `v0.2.1` → back-merge into `develop`.
If a `release/*` branch is open, also back-merge the hotfix into that release branch.

---

## 5. Merge methods (why they differ)

| Merge | Method | Reason |
| --- | --- | --- |
| short-lived → `develop` / `release/*` | Squash | One commit per issue on `develop`; the PR title becomes the commit message, so `develop` reads like a changelog. |
| `release/*` / `hotfix/*` → `main` | Merge commit | Keeps the release as one visible unit on `main`, and keeps commit SHAs identical so back-merging is conflict-free. |
| `main` → `develop` back-merge | Merge commit | Brings the version bump + hotfixes back without rewriting history. |

Rebase-merge is disabled in repo settings.

---

## 6. Branch → environment map

| Branch | Environment | URL |
| --- | --- | --- |
| any branch, local | **dev** (local Supabase in Docker) | `http://localhost:3000` / `:3001` |
| PR branches | **dev** preview (Vercel Preview + UAT DB, read-mostly) | per-PR Vercel URL |
| `develop` | **uat** | Vercel branch alias for `develop` |
| `release/*`, `hotfix/*` | **uat** (during stabilisation) | Vercel branch alias for the branch |
| `main` + tag `v*` | **prod** | production domain |

Full details, secrets and caveats: [operations/environments.md](../operations/environments.md).

---

## 7. Repository settings that enforce this

Configured in GitHub → Settings (record any change in the ADR log). Current state as of 2026-11-15 (issue #6):

- **Default branch:** `develop` (new PRs target it by default).
- **Merge buttons:** allow *Squash* and *Merge commit*, disable *Rebase*. Squash and merge commit message = PR title + description.
- **Automatically delete head branches:** on.
- **Ruleset `main`:** require PR (all review threads resolved); block force pushes and deletion; allowed merge method = merge commit.
- **Ruleset `develop`:** require PR (all review threads resolved); block force pushes and deletion; allowed merge methods = squash, merge commit (merge commit only for back-merges, by convention).
- **Ruleset `release and hotfix`** (`release/**`, `hotfix/**`): block force pushes. Direct pushes are allowed so the version-bump commit can be made on the branch; fixes still arrive through `bugfix/` PRs by convention.
- **Tag ruleset `version tags`** (`v*`): creation, update and deletion blocked for everyone except repository admins (Phú).
- **Required status checks:** none yet. `ci / check` and `ci / pr-title` are added to the `main` and `develop` rulesets in P0-00b, when the CI workflow exists.
- **Security:** secret scanning, push protection, Dependabot alerts + security updates, private vulnerability reporting: on.
- **Required approvals: 0.** This is a solo repo: GitHub does not let an author approve their own PR, and both agents act through Phú's account. Review is enforced by the process in [pull-requests.md](pull-requests.md#5-review-process) instead.
