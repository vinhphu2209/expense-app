import { describe, expect, it } from "vitest";

import { createAppEnv, type RuntimeEnv } from "@/env";

const valid: RuntimeEnv = {
  NEXT_PUBLIC_APP_ENV: "development",
  NEXT_PUBLIC_SUPABASE_URL: "http://127.0.0.1:54321",
  NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: "sb_publishable_test",
  SUPABASE_SECRET_KEY: "sb_secret_test",
};

describe("createAppEnv", () => {
  it("accepts a complete, valid environment", () => {
    const env = createAppEnv(valid);

    expect(env.NEXT_PUBLIC_SUPABASE_URL).toBe("http://127.0.0.1:54321");
    expect(env.SUPABASE_SECRET_KEY).toBe("sb_secret_test");
  });

  describe("NEXT_PUBLIC_APP_ENV", () => {
    it.each(["development", "uat", "production"] as const)("accepts %s", (value) => {
      const env = createAppEnv({ ...valid, NEXT_PUBLIC_APP_ENV: value });

      expect(env.NEXT_PUBLIC_APP_ENV).toBe(value);
    });

    it("defaults to development when missing", () => {
      const env = createAppEnv({ ...valid, NEXT_PUBLIC_APP_ENV: undefined });

      expect(env.NEXT_PUBLIC_APP_ENV).toBe("development");
    });

    it("defaults to development when empty", () => {
      const env = createAppEnv({ ...valid, NEXT_PUBLIC_APP_ENV: "" });

      expect(env.NEXT_PUBLIC_APP_ENV).toBe("development");
    });

    it("rejects an unknown environment name", () => {
      expect(() => createAppEnv({ ...valid, NEXT_PUBLIC_APP_ENV: "staging" })).toThrow(
        "Invalid environment variables",
      );
    });
  });

  describe("Supabase", () => {
    it("rejects a missing Supabase URL", () => {
      expect(() => createAppEnv({ ...valid, NEXT_PUBLIC_SUPABASE_URL: undefined })).toThrow(
        "Invalid environment variables",
      );
    });

    it("rejects a Supabase URL that is not a URL", () => {
      expect(() => createAppEnv({ ...valid, NEXT_PUBLIC_SUPABASE_URL: "localhost-54321" })).toThrow(
        "Invalid environment variables",
      );
    });

    it("rejects an empty publishable key", () => {
      expect(() => createAppEnv({ ...valid, NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: "" })).toThrow(
        "Invalid environment variables",
      );
    });

    it("rejects a missing secret key on the server", () => {
      expect(() => createAppEnv({ ...valid, SUPABASE_SECRET_KEY: undefined })).toThrow(
        "Invalid environment variables",
      );
    });
  });
});
