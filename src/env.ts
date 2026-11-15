import { createEnv } from "@t3-oss/env-nextjs";
import { z } from "zod";

/**
 * Environment variables, validated at startup and at build time (imported by next.config.ts).
 * Every variable here is also listed in `.env.example` and in docs/operations/environments.md §2.
 * Never read `process.env` elsewhere — import `env` from "@/env" (docs/conventions/files-and-folders.md §3.10).
 */

/** Browser-safe variables. Values are inlined into client bundles at build time. */
const client = {
  NEXT_PUBLIC_APP_ENV: z.enum(["development", "uat", "production"]).default("development"),
};

/** Server-only variables. Added when first needed (Supabase keys arrive in P0-02). */
const server = {};

type RuntimeEnv = {
  NEXT_PUBLIC_APP_ENV: string | undefined;
};

/** Builds and validates the env object. Exported for tests; app code uses `env`. */
export function createAppEnv(runtimeEnv: RuntimeEnv) {
  return createEnv({
    server,
    client,
    runtimeEnv,
    emptyStringAsUndefined: true,
  });
}

export const env = createAppEnv({
  NEXT_PUBLIC_APP_ENV: process.env.NEXT_PUBLIC_APP_ENV,
});
