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
//   Bump <pkg> from <x> to <y>[ in the <group> group][ across <n> director(y|ies)][ in <dir>]
//   Bump the <group> group[ in <dir>][ across <n> director(y|ies)] with <n> update(s)
//   Bump <a>[, <b>] and <c>[ in <dir>]
const across = String.raw`( across \d+ director(?:y|ies))?`;
const dependabotHeader = new RegExp(
  String.raw`^(build|ci)\(deps\): Bump (` +
    String.raw`\S+ from \S+ to \S+( in the \S+ group)?${across}( in \S+)?` +
    String.raw`|the \S+ group( in \S+)?${across} with \d+ updates?` +
    String.raw`|\S+(, \S+)* and \S+( in \S+)?` +
    ")$",
);

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
