---
description: Verify a Claude Code pull request by running the real app in the browser and post the review on GitHub
---

1. Identify the PR: from the user's message, or the oldest ready PR from `gh pr list --label agent:claude-code --state open`. Read its description, especially "How to verify" and "Review focus": `gh pr view <n> --comments`.
2. Commit or stash your own work first. Then check out the PR detached: `gh pr checkout <n> --detach`.
   - Run `pnpm install` if the lockfile changed.
   - If the PR has `db:migration`, verify **locally** (the preview URL reads UAT, which doesn't have the migration yet). Run `supabase db reset`, coordinating with Claude Code because the local DB is shared.
   - Otherwise you may use the PR's Vercel preview URL.
3. Start `pnpm dev -p 3001` (when verifying locally). Open the browser at viewport 390×844.
4. Exercise: the happy path, the empty state, large amounts (1.250.000.000), invalid input ("abc", negative), a quick double-submit, a refresh mid-flow, and offline (if relevant).
5. Take screenshots of anything wrong, saved to `docs/screens/verify-<plan-id>-*.png`. Attach them to the review comment; don't commit them to the PR branch.
6. Write the review in the format from docs/conventions/pull-requests.md §5.2: header `## Review — Antigravity — <VERDICT>`, then numbered findings, each with steps to reproduce, expected vs actual, and severity. Post it with `gh pr review <n> --comment --body-file <tmp-review.md>`.
7. Don't modify backend code. Switch back to your own branch when done.
