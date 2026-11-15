---
description: Review an Antigravity pull request (UI work) and post the review on GitHub
argument-hint: [pr-number, default = oldest ready PR labelled agent:antigravity]
---

1. PR to review: `$ARGUMENTS`, or the oldest non-draft PR from `gh pr list --label agent:antigravity --state open --json number,title,isDraft`.
2. Read the PR description, the linked issue and its `## Plan`, and the task in `docs/plan.md` §6: `gh pr view <n> --comments`.
3. Inspect the diff: `gh pr diff <n>`. Check, in this order:
   - Ownership: no edits outside Antigravity's paths (docs/conventions/files-and-folders.md §1.1).
   - Domain contract: types/Zod imported from `@/lib/domain`, not redefined.
   - No money arithmetic in UI; VND shown through `formatVnd()`.
   - Data fetching and server actions used correctly; loading, empty and error states exist.
   - Security: no secrets client-side, no server-only imports in client components, no RLS bypass, no real data in screenshots.
   - File names/locations follow the recipes (docs/conventions/files-and-folders.md §2–3).
   - Acceptance criteria from the issue are met.
   - Accessibility: labels, tap targets ≥ 44px; works at 390px width.
   - Tests: e2e covers the main flow; CI is green (`gh pr checks <n>`).
4. Optional: check it out in a temporary worktree and run it: `git worktree add ../expense-app-review origin/<head-branch>`, then `pnpm install && pnpm check`. Remove the worktree afterwards.
5. Write the review in the fixed format from docs/conventions/pull-requests.md §5.2 (header `## Review — Claude Code — <VERDICT>`, numbered findings with severity and `file:line`). Post it with `gh pr review <n> --comment --body-file <tmp-review.md>`.
6. Don't push to the PR branch.
7. Summarise to Phú in Vietnamese: verdict, number of blockers, PR link.
