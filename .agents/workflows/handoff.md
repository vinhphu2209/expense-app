---
description: Finish the current UI task — run checks, screenshots, open or update the PR, mark it ready for review
---

1. Run `pnpm check` and `pnpm test:e2e`. Don't hand off red.
2. Make sure the screenshots exist: `docs/screens/<plan-id>-<screen>-<state>.png` at 390×844, **seed data only**.
3. Rebase on `origin/develop` and push the branch.
4. Open or update the PR into `develop`:
   - Title: a Conventional Commit header (docs/conventions/commits.md), e.g. `feat(quickadd): add S1 quick-add screen`.
   - Body: fill every section of `.github/pull_request_template.md`. Add screenshots to the Screenshots table.
   - "Review focus": list the exact files that contain data fetching or state logic for Claude Code to check.
   - Labels: copy from the issue.
   - Commands: `gh pr create --draft --base develop --title "<title>" --body-file <tmp-body.md>`, then `gh pr ready <n>`.
5. Add a `CHANGELOG.md` line under `Unreleased` for `feat`/`fix`.
6. Tell Phú in Vietnamese: what was done, the PR link, the screenshots, and the exact prompt for Claude Code: `/review-ag <pr-number>`.
