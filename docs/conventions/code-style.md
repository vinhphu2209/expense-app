# Code Style Conventions (TypeScript / React / Next.js)

> Related: [files & folders](files-and-folders.md) · [database](database.md)

Formatting is automated (Prettier + ESLint). This document covers the rules a formatter cannot enforce. When a rule is enforced by a lint rule, the rule name is given.

---

## 1. TypeScript

- `strict: true`, plus `noUncheckedIndexedAccess` and `exactOptionalPropertyTypes`.
- No `any`. Use `unknown` and narrow it. (`@typescript-eslint/no-explicit-any`)
- No non-null assertion `!` except in tests. (`@typescript-eslint/no-non-null-assertion`)
- Exported functions declare their return type.
- Prefer `type` over `interface` unless declaration merging is needed.
- Use discriminated unions over boolean flags: `{ type: "transfer"; toAccountId: string } | { type: "expense"; envelopeId: string }`.
- Don't use `enum`. Use `as const` objects or Zod enums so values match the DB enums.
- Dates: store/transport as ISO strings or `Date` in UTC. Convert to `Asia/Ho_Chi_Minh` **only** through `src/lib/domain/time/` helpers ([ADR-0005](../adr/0005-fixed-timezone-calendar-month.md)).

## 2. Money (non-negotiable)

Rules from [ADR-0004](../adr/0004-money-as-integer-vnd.md):

- Money is integer VND, typed as `Vnd` (a branded `number`, guarded with `Number.isSafeInteger`).
- All arithmetic goes through `src/lib/domain/money/` (`addVnd`, `subVnd`, `pctOfVnd`, `roundToThousand`).
- No `/`, `*`, `Math.round`, `toFixed` or `parseFloat` on money outside that folder. (Custom ESLint rule planned in P0-01.)
- Display only through `formatVnd()`.

## 3. Imports

- Absolute imports with alias `@/` → `src/`. Relative imports only inside the same module folder.
- Order (enforced by `eslint-plugin-import`/`simple-import-sort`): node built-ins → external packages → `@/` → relative → styles.
- UI never imports from `@/server/**` except server actions in Server Components or `"use client"` components calling actions.
- Client code never imports `@/lib/supabase/server`, `@/server/services/**` or anything that imports `server-only`.

## 4. React & Next.js

- Server Components by default. Add `"use client"` to the smallest interactive leaf.
- Pages and layouts use `export default` (framework requirement). Everything else uses named exports.
- Data fetching: in Server Components through `src/server/queries/`; mutations through Server Actions. TanStack Query only if a client cache is clearly needed (record the decision in the PR).
- Forms: `react-hook-form` + `zodResolver(<DomainSchema>)`, using the same Zod schema as the server.
- Every async UI has loading, empty and error states.
- Styling: Tailwind utility classes. Class order sorted by `prettier-plugin-tailwindcss`. Use `cn()` for conditional classes. Avoid arbitrary values (`w-[317px]`) unless matching an iOS constraint.
- iOS PWA: `dvh` not `vh`, `env(safe-area-inset-*)` for edges, `inputMode="numeric"` for amounts, tap targets ≥ 44px.
- Accessibility: every input has a label, icon-only buttons have `aria-label`, and colour is never the only signal (for example, overspent = red **and** icon).

## 5. Errors & logging

- Expected failures return `ActionResult` errors. Throw only for programmer errors and truly unexpected states.
- Error codes are `snake_case` strings (`invalid_input`, `month_already_closed`) defined in `src/lib/domain/errors.ts`.
- Vietnamese user-facing messages are mapped from error codes in the UI layer, never produced by the server.
- Logs: never log tokens, full request bodies, notes or receipt text. Log IDs and error codes.

## 6. Comments & TODOs

- Comment **why**, not what. Public domain functions get a short TSDoc with an example.
- `TODO(#<issue>): ...` only. A TODO without an issue number fails lint review.
- No commented-out code. Git keeps history.

## 7. Language

- Identifiers, comments, docs, commit messages: English.
- UI strings: Vietnamese, kept in the component that renders them (no i18n framework yet; revisit via ADR if a second language is ever needed).

## 8. Tests

- Arrange / Act / Assert, one behaviour per `it`.
- Money tests use explicit integers: `expect(parseVnd("1tr2")).toBe(1_200_000)`.
- Time-dependent tests inject `now`. No real clock, no `setTimeout` waits.
- E2E tests use `data-testid` only when no accessible role/label exists. Prefer `getByRole`.
