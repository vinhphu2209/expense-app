import { defineConfig } from "vitest/config";

// Unit tests: docs/conventions/files-and-folders.md §3.9 (colocated *.test.ts).
export default defineConfig({
  resolve: { tsconfigPaths: true },
  test: {
    environment: "node",
    include: ["src/**/*.test.ts"],
    restoreMocks: true,
  },
});
