import type { NextConfig } from "next";

// Validate environment variables at build/dev start (src/env.ts).
import "./src/env";

const nextConfig: NextConfig = {
  cacheComponents: true,
  partialPrefetching: true,
  // AGENTS.md is owned by Phú (docs/conventions/files-and-folders.md §1.1); don't let `next dev` rewrite it.
  agentRules: false,
  turbopack: {
    rules: {
      "*.css": {
        loaders: ["@tailwindcss/turbopack"],
        as: "*.css",
      },
    },
  },
};

export default nextConfig;
