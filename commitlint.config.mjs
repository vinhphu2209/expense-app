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

/** @type {import("@commitlint/types").UserConfig} */
const config = {
  extends: ["@commitlint/config-conventional"],
  rules: {
    "scope-enum": [2, "always", scopes],
    "scope-empty": [2, "never"],
    "header-max-length": [2, "always", 72],
    "body-max-line-length": [2, "always", 100],
  },
};

export default config;
