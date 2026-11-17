# Local setup

## Goal

Run the app on your machine and get a green `pnpm check`, the same gate every PR must pass.

## Prerequisites

| Tool | Version | Notes |
| --- | --- | --- |
| Node.js | 22 or newer (`.nvmrc`) | `node -v` |
| pnpm | pinned in `package.json` → `packageManager` | Provided by Corepack: run `corepack enable` once (administrator shell on Windows) |
| Git | any recent | Line endings are normalised to LF by `.gitattributes` |
| GitHub CLI (`gh`) | any recent | Used by the issue/PR workflow ([ai-workflow](../ai-workflow.md)) |
| Docker + Supabase CLI | — | Needed from P0-02 (#10) for the local database |

Recommended VS Code extensions are listed in `.vscode/extensions.json` (ESLint, Prettier, Tailwind CSS).

## Steps

```bash
git clone https://github.com/vinhphu2209/expense-app.git
cd expense-app
corepack enable          # once per machine
pnpm install
cp .env.example .env.local
pnpm dev                 # http://localhost:3000
```

Antigravity's worktree runs on another port: `pnpm dev -p 3001` ([ai-workflow §3.1](../ai-workflow.md#31-repo-remote-and-worktrees)).

## Scripts

| Script | What it does |
| --- | --- |
| `pnpm dev` | Next.js dev server (Turbopack) |
| `pnpm build` / `pnpm start` | Production build / serve it |
| `pnpm typecheck` | `next typegen` (route types) + `tsc --noEmit` |
| `pnpm lint` / `pnpm lint:fix` | ESLint ([code style](../conventions/code-style.md)) |
| `pnpm format` / `pnpm format:check` | Prettier (Markdown is excluded) |
| `pnpm lint:md` | markdownlint on every `.md` file (`.markdownlint-cli2.jsonc`) |
| `pnpm test` / `pnpm test:watch` | Vitest unit tests (`src/**/*.test.ts`) |
| `pnpm check` | typecheck + lint + format:check + lint:md + test. **Must be green before a PR is marked ready.** CI runs the same command. |

## Git hooks

`pnpm install` installs [lefthook](https://lefthook.dev) hooks through the `prepare` script (`lefthook.yml`):

- **commit-msg:** commitlint checks the message against [commits](../conventions/commits.md) (types and the scope list in `commitlint.config.mjs`).
- **pre-commit:** ESLint, Prettier and markdownlint on the staged files.

CI runs the same checks (`.github/workflows/ci.yml`, `pr-title.yml`), so never bypass hooks with `--no-verify`.

## Environment variables

Defined and validated in `src/env.ts`. The app fails at start or build time if a value is invalid. To add a variable, follow [files & folders §3.10](../conventions/files-and-folders.md#310-environment-variable).

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| `pnpm: command not found` | Run `corepack enable` (administrator PowerShell on Windows), then open a new terminal. |
| `pnpm.ps1 cannot be loaded because running scripts is disabled` (PowerShell) | Run once: `Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned`, or call `pnpm.cmd` instead of `pnpm`. |
| Commit rejected by `commitlint` | Fix the message format: `<type>(<scope>): <subject>` with a scope from commits.md §1.2. |
| Git hooks don't run | Run `pnpm install` (or `pnpm exec lefthook install`) once in that worktree. |
| `❌ Invalid environment variables` | Compare `.env.local` with `.env.example`; `NEXT_PUBLIC_APP_ENV` must be `development`, `uat` or `production`. |
| `LayoutProps` / route types not found in the editor | Run `pnpm typecheck` once (it runs `next typegen`), or start `pnpm dev`. |
| `Run autofix to sort these imports!` | `pnpm lint:fix` |
| Port 3000 already in use | Stop the other dev server, or use `pnpm dev -p 3001`. |
