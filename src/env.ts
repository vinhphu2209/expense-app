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
  /** Supabase API URL (local: `pnpm db:status` → API_URL). */
  NEXT_PUBLIC_SUPABASE_URL: z.url(),
  /** Supabase publishable key (`sb_publishable_…`). Safe in the browser: RLS protects data. */
  NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: z.string().min(1),
};

/** Server-only variables. Never reachable from client bundles or logs. */
const server = {
  /** Supabase secret key (`sb_secret_…`). Bypasses RLS: use only in src/server/services/. */
  SUPABASE_SECRET_KEY: z.string().min(1),
};

export type RuntimeEnv = {
  NEXT_PUBLIC_APP_ENV: string | undefined;
  NEXT_PUBLIC_SUPABASE_URL: string | undefined;
  NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: string | undefined;
  SUPABASE_SECRET_KEY: string | undefined;
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
  NEXT_PUBLIC_SUPABASE_URL: process.env.NEXT_PUBLIC_SUPABASE_URL,
  NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY,
  SUPABASE_SECRET_KEY: process.env.SUPABASE_SECRET_KEY,
});
