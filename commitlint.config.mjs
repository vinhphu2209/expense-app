// Conventional Commits with this repo's scope list: docs/conventions/commits.md §1.2.
// Keep `scopes` in sync with that table (change both in the same PR).
const scopes = [
  "db",
  "domain",
  "money",
  "txn",
  "quickadd",
  "budget",
  "funds",
  "accounts",
  "month-close",
  "insights",
  "settings",
  "ingest",
  "auth",
  "pwa",
  "ui",
  "e2e",
  "ci",
  "deps",
  "docs",
  "adr",
  "release",
];

// Dependabot always writes "Bump" with a capital B, which fails `subject-case`, and it cannot be
// configured. Skip only its exact generated headers (scope fixed in .github/dependabot.yml):
//   build(deps): Bump <pkg> from <x> to <y>    build(deps): Bump the <group> group with <n> updates
//   ci(deps): Bump <action> from <x> to <y>
const dependabotHeader =
  /^(build|ci)\(deps\): Bump (\S+ from \S+ to \S+|the \S+ group( across \d+ directories?)? with \d+ updates?)( in \S+)?$/;

/** @type {import("@commitlint/types").UserConfig} */
const config = {
  extends: ["@commitlint/config-conventional"],
  ignores: [(message) => dependabotHeader.test(message.split("\n")[0] ?? "")],
  rules: {
    "scope-enum": [2, "always", scopes],
    "scope-empty": [2, "never"],
    "header-max-length": [2, "always", 72],
    "body-max-line-length": [2, "always", 100],
  },
};

export default config;
