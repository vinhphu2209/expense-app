# PLAN — Personal Expense App ("Budget & Expense" v2)

> Source of truth for **what to build**. Only Phú (human) edits this file. Agents propose changes in a PR or an issue labelled `needs-decision`. Live task status is on the GitHub Project board ([issues conventions](conventions/issues.md)).

---

## 0. Goals

Replace the "Budget & Expense" Google Sheet with a **personal PWA** that:

1. **Logs every transaction** at the moment money is spent (almost always a MoMo transfer/payment), in ≤ 5 seconds (Quick-add).
2. Keeps the existing **percentage-of-income allocation framework** (4 groups, savings funds).
3. Tracks **balance per fund**, **BNPL debt** (Shopee Later…), and **recurring bills**.
4. **Automates the month-end rule** (leftover → EmergencyFund → once target reached, split 50-30-20 into Investment / Wedding / Sinking).
5. Makes logging on **iPhone** as frictionless as possible without a native app.

### Non-goals

- Multi-user / shared expenses.
- Native iOS/Android app, App Store distribution.
- Bank account tracking or bank integrations (SePay, open banking…).
- Any MoMo API integration (MoMo offers no personal API).
- Android-specific automation.
- Investment advice.

---

## 1. Decisions

Summary only. The full records (context, options, consequences) are ADR-0002 … ADR-0010 in [`docs/adr/`](adr/README.md). D*n* = ADR-000(*n*+1).

| # | Decision | Rationale |
| --- | --- | --- |
| D1 | **PWA + Quick-add** is the primary (and only) input method | No API/export from MoMo; fast manual entry is the foundation |
| D2 | **Envelope budgeting model** (YNAB-style) | The sheet mixes "spending" and "saving"; envelopes separate them |
| D3 | Money stored as **BIGINT VND** (no decimals) | VND has no subunit; avoids float errors |
| D4 | Fixed timezone **Asia/Ho_Chi_Minh**; month = calendar month | Matches the current sheet |
| D5 | Envelopes have **stable ids**; renaming keeps history | The sheet lost history when renaming Health → HealthFund etc. |
| D6 | Supabase (Postgres) as backend | Free tier, Auth, RLS, Power BI can connect to Postgres |
| D7 | UI text in Vietnamese; code, comments, commits and **all docs in English** | Readable for agents and portfolio |
| D8 | Primary device: **iPhone** (Safari PWA, Add to Home Screen) | No notification reading on iOS → capture helpers use iOS Shortcuts |
| D9 | Only **MoMo** is tracked (plus Cash and BNPL liabilities); no bank accounts | Matches real usage |

---

## 2. Tech stack

- **Framework:** Next.js (App Router, latest stable) + TypeScript `strict`
- **UI:** Tailwind CSS + shadcn/ui; mobile-first, designed for iPhone viewport 390×844 first
- **PWA:** web app manifest + service worker (Serwist or equivalent): installable to iPhone Home Screen, standalone display, offline queue for Quick-add
- **DB/Auth:** Supabase (Postgres, Row Level Security, Supabase Auth — magic link or Google; session must persist in the installed PWA)
- **Validation:** Zod (shared by forms and API)
- **Data fetching:** Server Actions / Route Handlers; TanStack Query if client caching is needed
- **Tests:** Vitest (unit, money logic), Playwright (e2e, run with WebKit + iPhone device profile)
- **Deploy:** Vercel (frontend) + Supabase cloud
- **Package manager:** pnpm

### iOS PWA constraints to design around

- Installed only via Safari → Share → **Add to Home Screen**; no install prompt API.
- No Web Share Target, no reading notifications from other apps, limited background execution.
- Storage can be evicted if the app is unused for a long time → server (Supabase) is the source of truth; local storage is only an offline queue.
- Respect safe areas (`env(safe-area-inset-*)`), use `inputmode="numeric"` for the amount field, avoid 100vh bugs (`dvh`).

---

## 3. Domain model

### 3.1 Account (where the money physically is)

Seed accounts: `MoMo` (default, asset), `Cash` (asset), `Shopee Later` (liability). Optional: `MoMo Ví Trả Sau` (liability) if used.
No bank accounts (D9). Money arriving from outside (salary into MoMo) is an `income` transaction on MoMo.

### 3.2 Envelope (what the money is for)

| Group | Envelope | `rollover` | Notes |
| --- | --- | --- | --- |
| Fixed Expenses | Home, Bills, Family | false | Family = former FamilyFund |
| Living Expenses | Food, Groceries, Transport | false | |
| Incidental Expenses | Entertainment, Shopping, Beauty, Miscellaneous | false | |
| Incidental Expenses | Health | **true** | Was renamed HealthFund → accumulates |
| Investment - Saving | Emergency, Investment, Sinking, Wedding, Dating, Study | **true** | Accumulating funds, optional `target_amount` |

- `rollover = false`: gets a fresh budget each month; **leftover at month end goes through the Month-close rule**.
- `rollover = true` (fund): leftover **carries over** → the envelope has a running **balance**. Spending from a fund (Dating, Study, Health) reduces its balance.

### 3.3 Transaction (money event)

- `expense`: money spent. Requires `account_id` + `envelope_id`.
- `income`: money in (salary, freelance). Has `account_id`, no envelope (goes to "To be assigned").
- `transfer`: between two accounts (MoMo → Cash withdrawal, MoMo → pay Shopee Later). **Does not touch envelopes**, is not spending.

> Buying with Shopee Later = `expense` (envelope Shopping, account Shopee Later) **at purchase time**. Paying it off later = `transfer` MoMo → Shopee Later. Spending lands in the right month, and the debt shows as the negative balance of the Shopee Later account.

### 3.4 Monthly budget

Per month: `income_planned` (net) and, per envelope, `pct` + `assigned_amount`.

- Default `assigned_amount = round(income_planned * pct, -3)` (round to thousands).
- Manual **override** allowed, but the UI must show an "overridden" badge (the November sheet had InvestmentFund at 10% but planned 4,218,000 — a silent mismatch).
- Constraint: sum of `pct` should be 100% → UI warns otherwise.

### 3.5 Month-close rule (automates the note at the bottom of the sheet)

Runs when the user taps **"Close month"**:

1. `leftover = Σ max(assigned − spent, 0)` over envelopes with `rollover = false`. Overspent envelopes are shown as warnings.
2. If `Emergency.balance < Emergency.target` → move leftover into Emergency, up to the target; any overflow continues to step 3.
3. Once Emergency is full → split the remainder **50% Investment / 30% Wedding / 20% Sinking**.
4. Record as `envelope_movements` rows (auditable). **No money transactions are created** (money does not physically move).
5. Create next month's budget by copying the closed month's percentages.

Split ratios and destinations come from `settings`, never hard-coded. A month can only be closed once.

### 3.6 Income: Gross → Net

MVP: user enters **Net** (optionally Gross and BHXH salary, for reference). A Gross → Net calculator (BHXH, personal income tax, deductions) is Phase 4, with its own tests and a cited source for the rules.

### 3.7 Audit trail

Every update/delete of a transaction writes to `audit_log` (before/after JSON). No hard deletes — use `deleted_at`.

---

## 4. Database schema (draft — Claude Code turns this into migrations)

```sql
-- Money is BIGINT VND. All timestamps timestamptz. RLS on every table: user_id = auth.uid().

create type account_type as enum ('asset','liability');
create type txn_type as enum ('expense','income','transfer');
create type txn_source as enum ('quickadd','manual','shortcut','import','system');
create type txn_status as enum ('confirmed','pending');  -- pending = inbox, needs envelope

create table accounts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users,
  name text not null,
  type account_type not null default 'asset',
  opening_balance bigint not null default 0,
  is_default boolean not null default false,
  archived_at timestamptz
);

create table envelope_groups (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  name text not null,
  sort_order int not null default 0
);

create table envelopes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  group_id uuid not null references envelope_groups,
  name text not null,
  rollover boolean not null default false,
  target_amount bigint,              -- funds only
  description text,
  icon text,
  sort_order int not null default 0,
  archived_at timestamptz
);

create table envelope_aliases (       -- old sheet names -> envelope (Health, HealthFund, ...)
  envelope_id uuid references envelopes,
  alias text not null
);

create table budget_months (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  month date not null,               -- always day 1
  income_planned bigint not null default 0,
  income_gross bigint,
  bhxh_salary bigint,
  closed_at timestamptz,
  unique (user_id, month)
);

create table budget_lines (
  budget_month_id uuid references budget_months on delete cascade,
  envelope_id uuid references envelopes,
  pct numeric(5,2) not null default 0,
  assigned_amount bigint not null default 0,
  is_override boolean not null default false,
  note text,
  primary key (budget_month_id, envelope_id)
);

create table transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  occurred_at timestamptz not null default now(),
  type txn_type not null,
  amount bigint not null check (amount > 0),
  account_id uuid not null references accounts,
  to_account_id uuid references accounts,     -- transfer only
  envelope_id uuid references envelopes,      -- expense only
  note text,
  merchant text,                               -- payee / recipient label
  tags text[] default '{}',
  source txn_source not null default 'quickadd',
  status txn_status not null default 'confirmed',
  client_id uuid,                              -- idempotency key from offline queue / Shortcut
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (user_id, client_id),
  check ((type = 'transfer') = (to_account_id is not null)),
  check (type <> 'expense' or envelope_id is not null or status = 'pending')
);

create table transaction_splits (            -- Phase 2: one bill across envelopes
  transaction_id uuid references transactions on delete cascade,
  envelope_id uuid references envelopes,
  amount bigint not null check (amount > 0)
);

create table envelope_movements (            -- month close, manual re-allocation
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  month date not null,
  from_envelope_id uuid references envelopes, -- null = "To be assigned"
  to_envelope_id uuid references envelopes,
  amount bigint not null,
  reason text not null,                       -- 'month_close' | 'manual'
  created_at timestamptz default now()
);

create table recurring_bills (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  name text not null,
  envelope_id uuid references envelopes,
  account_id uuid references accounts,
  expected_amount bigint,
  due_day int check (due_day between 1 and 31),
  active boolean default true
);

create table debts (                          -- BNPL installments
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  account_id uuid references accounts,        -- liability account
  name text not null,
  amount bigint not null,
  due_date date not null,
  paid_txn_id uuid references transactions,
  status text not null default 'open'         -- open | paid
);

create table quick_templates (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  label text not null,                        -- "Coffee", "Grab home"
  amount bigint,
  envelope_id uuid references envelopes,
  account_id uuid references accounts,
  usage_count int default 0
);

create table categorize_rules (               -- suggest envelope from note/merchant
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  pattern text not null,                      -- case-insensitive substring
  envelope_id uuid references envelopes,
  priority int default 0
);

create table api_tokens (                     -- personal token for iOS Shortcuts (Phase 3)
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  token_hash text not null,
  label text,
  created_at timestamptz default now(),
  revoked_at timestamptz
);

create table settings (
  user_id uuid primary key,
  default_account_id uuid references accounts,
  month_close_split jsonb not null default '{"Investment":50,"Wedding":30,"Sinking":20}',
  emergency_envelope_id uuid references envelopes,
  overspend_alert_pct int default 80
);

create table audit_log (
  id bigserial primary key,
  user_id uuid not null,
  table_name text not null,
  row_id uuid not null,
  action text not null,                       -- insert | update | delete
  before jsonb,
  after jsonb,
  at timestamptz default now()
);
```

Required views (SQL views or functions):

- `v_envelope_month` — per envelope × month: assigned, spent, available, carried_in.
- `v_fund_balance` — current balance of `rollover = true` envelopes.
- `v_account_balance` — balance per account (opening + income − expense ± transfers).
- `v_month_summary` — income, total assigned, total spent, leftover, saving rate.

All views must exclude `deleted_at is not null` and `status = 'pending'` from spending.

---

## 5. Screens

| # | Screen | Content |
| --- | --- | --- |
| S1 | **Quick-add** (default screen on launch) | Numeric keypad auto-focused; envelope chips (top 6 by frequency + time of day); account defaults to MoMo; optional note; Save; template strip ("Coffee 25k"…). Supports URL params `?amount=&envelope=&note=` for Shortcut deep links |
| S2 | **Transactions** | List grouped by day; filter by month/envelope/account/source; tap to edit, swipe to delete; **Inbox** tab (status pending) |
| S3 | **Monthly budget** | Same layout as the sheet: group → envelope: %, Assigned, Spent, Available, progress bar; header: Income, Assigned, Spent, Leftover; warning if Σ% ≠ 100 |
| S4 | **Funds** | Per fund: balance, target, % reached, history of movements and spending |
| S5 | **Accounts & Debts** | MoMo / Cash / BNPL balances; BNPL due soon; this month's recurring bills (checkbox paid) |
| S6 | **Month close** | Wizard: leftover → preview allocation by rule → Confirm |
| S7 | **Insights** | Spending by envelope (this month vs 3-month avg), burn rate, saving rate |
| S8 | **Settings** | Envelopes/groups, accounts, templates, rules, API token for Shortcuts, export CSV |

---

## 6. Roadmap & tasks

Owner key: **CC** = Claude Code (VS Code), **AG** = Antigravity, **P** = Phú. Owners are suggestions. Each row becomes one GitHub issue titled `[<ID>] …`. Live status is on the Project board.

### Phase 0 — Foundation (target: one weekend)

#### P0-00 Engineering foundation (before any app code)

| ID | Task | Owner | Acceptance criteria |
| --- | --- | --- | --- |
| P0-00a | GitHub repo (public), `main` + `develop`, rulesets, merge settings, labels, milestones, Project board, security features, LICENSE, real username in CODEOWNERS | P + CC | Settings match [branching §7](conventions/branching.md#7-repository-settings-that-enforce-this) and [ADR-0014](adr/0014-public-repository.md); issues created for every row of §6 |
| P0-00b | CI: `ci.yml` (typecheck, lint, unit, pgTAP, e2e) + PR-title lint; commitlint + lefthook locally | CC | A PR with a bad title or failing test cannot merge (needs P0-01) |
| P0-00c | Environments: Supabase `expense-uat` + `expense-prod`, Vercel project, GitHub Environments `uat`/`production`, `deploy-uat.yml`, `deploy-prod.yml`, `backup.yml`, restore runbook | CC + P | Tag `v0.1.0` deploys to prod after approval; restore tested on UAT ([environments](operations/environments.md)) |
| P0-00d | Architecture docs: C4 context + container, deployment, data model (ERD), security model, API | CC | Mermaid diagrams render on GitHub; linked from `docs/README.md` |

#### P0 app foundation

| ID | Task | Owner | Acceptance criteria |
| --- | --- | --- | --- |
| P0-01 | Scaffold Next.js + TS strict + Tailwind + shadcn + pnpm + ESLint/Prettier + Vitest | CC | `pnpm dev`, `pnpm test`, `pnpm lint` green |
| P0-02 | Supabase project, Supabase CLI, `.env.example` | CC | `supabase db reset` works locally |
| P0-03 | Migrations for §4 schema + RLS on every table | CC | Test: user A cannot read user B's data |
| P0-04 | Generate DB types → `src/lib/db.types.ts`; domain types + Zod schemas in `src/lib/domain/` | CC | This is the **contract** for UI; AG imports it, never redefines |
| P0-05 | Seed: groups, envelopes, aliases, accounts (MoMo default, Cash, Shopee Later) from the November template | CC | Seed is idempotent |
| P0-06 | Auth + mobile app shell + bottom nav; session persists in installed PWA (parent of 06a/06b) | CC + AG | Can log in on a real iPhone from the Home Screen icon and stay logged in after closing the app |
| P0-06a | Supabase auth clients (`src/lib/supabase/`), `src/middleware.ts`, magic-link callback route | CC | Session persists in the installed PWA; unauthenticated `(app)` routes redirect to login |
| P0-06b | Login screen, app shell, bottom nav (on top of P0-06a) | AG | Works at 390×844 with safe areas; screenshots attached |
| P0-07 | PWA manifest, icons (incl. `apple-touch-icon`), standalone mode, safe areas | AG | Add to Home Screen on iPhone opens full-screen with correct icon and status bar |

### Phase 1 — MVP that replaces the sheet (1–2 weeks)

| ID | Task | Owner | Acceptance criteria |
| --- | --- | --- | --- |
| P1-01 | Money utils: format VND; parse "45k" / "1tr2" / "1.250.000" → integer | CC | ≥ 15 unit test cases |
| P1-02 | Server actions: create/update/soft-delete transaction + audit_log; idempotent by `client_id` | CC | Unit + integration tests; double submit → one row |
| P1-03 | **S1 Quick-add** | AG | Log one expense in ≤ 5 s and ≤ 3 taps after typing the amount, on iPhone |
| P1-04 | Smart envelope chips (frequency + time of day) | CC (logic) + AG (UI) | `rankEnvelopes(history, now)` has tests |
| P1-05 | **S2 Transactions** list + edit | AG | Filter by month/envelope; edits write audit |
| P1-06 | Views `v_envelope_month`, `v_month_summary` | CC | Numbers match a hand-calculated sample month |
| P1-07 | **S3 Monthly budget** + edit pct/override | AG | Warns when Σ% ≠ 100; override badge visible |
| P1-08 | Create new month from previous | CC | |
| P1-09 | Import Sep–Nov history from the sheet (CSV) as **monthly aggregates** (one transaction per envelope per month, `source=import`) + fund opening balances | CC | Monthly Actual totals match the sheet |
| P1-10 | E2E: login → quick-add → visible in Budget (Playwright, WebKit iPhone profile) | AG | Green |

**Milestone:** run the app in parallel with the sheet for **2 weeks**, reconcile weekly. If numbers match, retire the sheet.

### Phase 2 — Funds, Debts, Month close (1 week)

| ID | Task | Owner | Acceptance criteria |
| --- | --- | --- | --- |
| P2-01 | `v_fund_balance`, `v_account_balance` | CC | Tests cover transfers + BNPL |
| P2-02 | **Month-close engine** (pure function + DB transaction) | CC | Tests: negative leftover, Emergency partially filled (overflow → 50-30-20), Emergency full, custom split, double close rejected |
| P2-03 | **S6 Month close wizard** | AG | Preview before confirm; cannot close twice |
| P2-04 | **S4 Funds** | AG | |
| P2-05 | BNPL debts + recurring bills (**S5**) | CC (model) + AG (UI) | Bills appear every month; marking paid creates a transaction |
| P2-06 | Quick templates + split transaction | AG | |
| P2-07 | Overspend alert (≥ 80% of envelope) shown on Quick-add after saving | AG | |

### Phase 3 — iPhone capture helpers (1 week)

Goal: make logging happen *right after* paying in MoMo, without leaving the PWA-only approach.

| ID | Task | Owner | Acceptance criteria |
| --- | --- | --- | --- |
| P3-01 | Offline queue for Quick-add (save locally when offline, sync with `client_id`) | AG | Airplane mode → save → reconnect → exactly one row |
| P3-02 | Quick-add deep link: `/add?amount=45000&envelope=food&note=...` prefills and focuses Save | AG | Works from a Home Screen bookmark and from Shortcuts "Open URL" |
| P3-03 | Personal API token (S8) + `POST /api/ingest` (token auth, Zod-validated, idempotent by `client_id`, lands in Inbox if envelope missing) | CC | Same request twice → one row; revoked token → 401 |
| P3-04 | **iOS Shortcut "Log expense"**: asks amount + picks envelope → calls `/api/ingest`. Document setup steps in `docs/guides/ios-shortcuts.md` | CC (API + doc) | Phú can log from the Shortcut / Siri / Action Button without opening the PWA |
| P3-05 | **iOS Personal Automation**: "When MoMo is closed" → run "Log expense" (or open the deep link). Documented, optional | CC (doc) | Documented with screenshots; Phú tests on device |
| P3-06 | Receipt-screenshot flow (optional): Shortcut takes a MoMo receipt screenshot → "Extract Text from Image" → sends raw text to `/api/ingest` → server parses amount/recipient → Inbox | CC | Parser tested on ≥ 10 real (redacted) MoMo receipts |
| P3-07 | Suggest envelope from `categorize_rules` + **Inbox UI** to confirm pending items, create a rule from one item | CC (logic) + AG (UI) | |
| P3-08 | Daily reminder via Web Push (installed PWA) if nothing logged today | AG + CC | Opt-in; can be disabled in Settings |

### Phase 4 — Insights & polish (ongoing)

- S7 Insights: 6-month trend, burn rate ("Food runs out on day X"), saving rate.
- Gross → Net calculator (BHXH, PIT) with tests and cited rules.
- CSV export; Power BI connection to Postgres (read-only role).
- Weekly digest (email or Telegram).
- LLM-assisted categorization for ambiguous notes.

---

## 7. Migration from the Google Sheet

1. Export each tab (2026-09, 2026-10, 2026-11) to CSV.
2. Map old category names → new envelopes via `envelope_aliases`:
   - `Health`, `HealthFund` → Health
   - `Study`, `StudyFund` → Study
   - `Sinking Fund`, `SinkingFund` → Sinking
   - `Emergency Fund`, `EmergencyFund` → Emergency
   - `Investment`, `InvestmentFund` → Investment
   - `Family`, `FamilyFund` → Family
   - `ML` → **to decide** (see §9)
3. Each month × envelope with Actual > 0 → one transaction `source=import`, `occurred_at` = last day of month, note "Imported from sheet".
4. Budget lines from the Allocation % / Planned columns.
5. Fund opening balances: **Phú enters actual current balances manually**.

---

## 8. Definition of Done (every task)

The canonical checklist lives in [pull requests §7](conventions/pull-requests.md#7-definition-of-done-pr-checklist) and is copied into every PR by the template. In short: CI green, money logic tested, RLS + pgTAP for new tables, works at 390×844, no secrets or real data, docs + CHANGELOG updated, reviewed by the other agent and Phú.

---

## 9. Open questions

Each question becomes an issue labelled `needs-decision`. Product rules are answered in this file; decisions with lasting architectural impact also get an ADR.

1. What was the `ML` envelope (September)? Merge into Study or drop?
2. The numbers in the sheet's notes column (15, 25, 100, 40, 20) — fund targets in millions VND? If yes → `target_amount`.
3. Exact Emergency target (3 or 6 months of expenses → amount)?
4. Which income drives the budget: actual Net, or "Net – full BHXH"? (November uses both.)
5. ~~Primary phone~~ → iPhone ([ADR-0009](adr/0009-iphone-primary-device.md)).
6. ~~Primary bank~~ → not tracked; MoMo only ([ADR-0010](adr/0010-track-momo-only.md)).
7. Does the iPhone have an Action Button (iPhone 15 Pro or later)? If yes, bind the "Log expense" Shortcut to it.
