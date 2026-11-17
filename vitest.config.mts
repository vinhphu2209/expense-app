import { defineConfig } from "vitest/config";

// Unit tests: docs/conventions/files-and-folders.md §3.9 (colocated *.test.ts).
export default defineConfig({
  resolve: { tsconfigPaths: true },
  test: {
    environment: "node",
    include: ["src/**/*.test.ts"],
    restoreMocks: true,
    // Placeholders so importing "@/env" validates in unit tests. Unit tests never reach Supabase;
    // integration tests (*.int.test.ts, #20) will use the local stack's real values.
    env: {
      NEXT_PUBLIC_SUPABASE_URL: "http://127.0.0.1:54321",
      NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: "test-placeholder",
      SUPABASE_SECRET_KEY: "test-placeholder",
    },
  },
});
