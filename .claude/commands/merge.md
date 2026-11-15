---
description: Merge a pull request as tech lead after checking every merge rule (ADR-0017)
argument-hint: <pr-number>
---

You are the tech lead (docs/adr/0017-claude-code-as-tech-lead.md). Merge PR `$ARGUMENTS` only if **every** rule below passes. If one fails, say which one and stop. This list mirrors docs/conventions/pull-requests.md §6 exactly; if they ever differ, §6 wins and this file must be fixed.

1. Read the PR: `gh pr view $ARGUMENTS --json title,state,isDraft,mergeable,baseRefName,headRefName,labels,closingIssuesReferences,reviewDecision --comments`, `gh pr checks $ARGUMENTS`, and the review threads (`gh api repos/{owner}/{repo}/pulls/$ARGUMENTS/comments`). Determine the author agent from the `agent:` label.
2. Check the rules of §6:
   - [ ] Open, not draft, `mergeable` is `MERGEABLE`.
   - [ ] CI is green. Until CI exists (P0-00b), run `pnpm check` on the PR head locally and post the result as a PR comment.
   - [ ] For **each** required reviewer in §5.1 (reviewer subagent; `money-logic-reviewer` for money/DB/migrations; Antigravity when the change is visible in the app), that reviewer's **latest** `## Review — <reviewer> — <VERDICT>` comment is `APPROVE` or `APPROVE WITH NITS`, and no required reviewer is the author agent. Conflict-free back-merges are exempt.
   - [ ] Every `blocker` and `should` finding has a reply (`Fixed in …`, `Won't fix: …` or `Follow-up: #…`).
   - [ ] All conversations are resolved.
   - [ ] No label `blocked`, `do-not-merge` or `needs-decision`.
   - [ ] `db:migration` into `develop`: no open `release/*` branch (`git ls-remote --heads origin "release/*"`).
   - [ ] Base `main`: Phú has posted his UAT acceptance on the PR.
3. Merge with the method for the base branch (docs/conventions/branching.md §5):
   - Short-lived branch into `develop`, `release/*` or `hotfix/*` → **squash**. Write the body to a temp file (`Closes #<n>` lines, a blank line, then every `Co-Authored-By` / `Assisted-by` trailer from the branch commits), then run:
     `gh pr merge $ARGUMENTS --squash --subject "<PR title> (#$ARGUMENTS)" --body-file <tmp-body.txt>`
   - `release/*` / `hotfix/*` into `main`, and back-merges into `develop` → **merge commit**: `gh pr merge $ARGUMENTS --merge`
4. Afterwards: `git fetch --prune`, switch to `develop`, `git pull --ff-only`, delete the local branch. Check that the linked issue closed and its card is in *Done*.
5. Tell Phú in Vietnamese in 1–3 lines what was merged. Call out any change to rules or definition files.
