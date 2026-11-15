---
description: Pick the next Claude Code issue (or a given issue number), read context, and post a plan, then start implementing unless a business question is open
argument-hint: [issue-number]
---

1. Find the issue:
   - If `$ARGUMENTS` is given, use that issue number.
   - Otherwise list ready issues: `gh issue list --label agent:claude-code --state open --json number,title,labels`. Pick the first one without `blocked`/`needs-decision` whose `Blocked by #n` dependencies are all closed.
2. Read the issue and its comments: `gh issue view <n> --comments`. Read the `docs/plan.md` sections it references and any related ADRs.
3. Check for open requests addressed to Claude Code in recent PRs: `gh pr list --search "Request for Claude Code in:comments" --state open`.
4. Write the plan in English and post it as an issue comment starting with `## Plan`:
   - Goal + acceptance criteria (from the issue)
   - Branch name: `feature/<n>-<slug>` (or `bugfix/` `chore/` `docs/`), per docs/conventions/branching.md
   - Files to create/modify, each with the recipe from docs/conventions/files-and-folders.md §3
   - Function signatures / SQL objects
   - Test cases (list them)
   - Risks / questions for Phú
   Command: `gh issue comment <n> --body-file <tmp-plan.md>`.
5. Summarise the plan to Phú in Vietnamese in chat in 2–4 lines, with the issue link (for information, not approval).
6. If the plan has an open business question, label the issue `needs-decision`, ask Phú in chat and STOP. Otherwise move the card to *In progress* and start: create the branch and implement (you are the tech lead, ADR-0017).
