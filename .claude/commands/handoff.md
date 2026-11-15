---
description: Finish the current task — run checks, open or update the PR from the template, mark it ready for review
---

1. Run `pnpm check` (and `supabase db reset` + `supabase test db` if migrations changed). If anything fails, fix it or report clearly why. Don't hand off red.
2. If the diff touches `src/lib/domain/money/`, month-close, views or `supabase/migrations/`, run the `money-logic-reviewer` subagent on `git diff origin/develop...HEAD` and fix its blockers.
3. Make sure the branch is rebased on `origin/develop` and pushed.
4. Open or update the PR into `develop`:
   - Title: a Conventional Commit header (docs/conventions/commits.md).
   - Body: fill **every** section of `.github/pull_request_template.md`. Write "N/A — reason" where a section doesn't apply.
   - In "Review focus", tell Antigravity exactly what to verify in the browser and on which URL (local or the preview URL; local if the migration isn't on UAT).
   - Paste the `money-logic-reviewer` summary under "Review focus" if it ran.
   - Labels: copy from the issue and add `db:migration` if relevant.
   - Commands: `gh pr create --draft --base develop --title "<title>" --body-file <tmp-body.md>`, then `gh pr ready <n>`.
5. Add a `CHANGELOG.md` line under `Unreleased` for `feat`/`fix` PRs (commit `docs(release): update changelog`, or include it in the last commit).
6. Tell Phú in Vietnamese, in 3–5 lines: what was done, the PR link, how to test, and the exact prompt for Antigravity: `/verify-ui <pr-number>`.
