---
description: Pick the next Antigravity UI issue (or a given issue number) and post an Implementation Plan
---

1. Read `AGENTS.md` and `.agents/rules/antigravity-role.md`.
2. Find the issue: the number given by the user, or the first open issue from `gh issue list --label agent:antigravity --state open` without `blocked`/`needs-decision` whose `Blocked by #n` dependencies are all closed.
3. Read it: `gh issue view <n> --comments`. Read the `docs/plan.md` sections it references (§2 iOS constraints, §5 screens).
4. Update the worktree: `git fetch origin && git switch -c feature/<n>-<slug> origin/develop` (docs/conventions/branching.md §4.1).
5. Read the domain contract in `src/lib/domain/` that this screen needs. If something is missing, comment "Request for Claude Code: …" on the issue and don't invent it.
6. Produce an Implementation Plan artifact in English covering:
   - components and their file paths (recipes in docs/conventions/files-and-folders.md §3.4–3.7)
   - states (loading/empty/error) and interactions
   - which domain functions and actions are used
   - the e2e scenario
   - the screenshot list
7. Post the plan as an issue comment starting with `## Plan` (`gh issue comment <n> --body-file …`). Wait for Phú's `Plan approved` before coding.
