---
description: Merge a pull request as tech lead after checking every merge rule (ADR-0017)
argument-hint: <pr-number>
---

You are the tech lead (docs/adr/0017-claude-code-as-tech-lead.md). Merge PR `$ARGUMENTS` only if **every** check passes. If one fails, say which one and stop.

1. Read the PR: `gh pr view $ARGUMENTS --json title,state,isDraft,mergeable,baseRefName,headRefName,labels,author,closingIssuesReferences --comments` and `gh pr checks $ARGUMENTS`.
2. Check the merge rules (docs/conventions/pull-requests.md §6):
   - [ ] Open, not draft, `mergeable` is `MERGEABLE`.
   - [ ] All CI checks pass. If no checks are configured yet (before P0-00b), run `pnpm check` on the PR head locally and say so.
   - [ ] The latest review comment (`## Review — <reviewer> — <VERDICT>`) is `APPROVE` or `APPROVE WITH NITS`, written by a reviewer that is **not** the PR's author agent. For Claude Code PRs: the fresh-context reviewer subagent (plus Antigravity when the change is visible in the app).
   - [ ] Every `blocker` and `should` finding has a reply (`Fixed in …`, `Won't fix: …` or `Follow-up: #…`).
   - [ ] No label `blocked`, `do-not-merge` or `needs-decision`.
   - [ ] `db:migration` into `develop`: no open `release/*` branch (`git ls-remote --heads origin "release/*"`).
   - [ ] Base `main`: Phú has accepted the release on his iPhone (comment on the release PR). Never merge into `main` without it.
3. Merge with the method for the base branch (docs/conventions/branching.md §5):
   - `develop`, `release/*`, `hotfix/*` as the target of a short-lived branch → **squash**:
     `gh pr merge $ARGUMENTS --squash --subject "<PR title> (#$ARGUMENTS)" --body "<Closes #n lines>\n\n<Co-Authored-By / Assisted-by trailers from the branch commits>"`
   - `main`, and back-merges into `develop` → **merge commit**: `gh pr merge $ARGUMENTS --merge`
4. Afterwards: `git fetch --prune`, switch to `develop`, `git pull --ff-only`, delete the local branch. Check that the linked issue closed and its card is in *Done*.
5. Tell Phú in Vietnamese in 1–3 lines what was merged. Call out any change to rules or definition files.
