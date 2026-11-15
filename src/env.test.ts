import { describe, expect, it } from "vitest";

import { createAppEnv } from "@/env";

describe("createAppEnv", () => {
  it.each(["development", "uat", "production"] as const)(
    "accepts NEXT_PUBLIC_APP_ENV=%s",
    (value) => {
      const env = createAppEnv({ NEXT_PUBLIC_APP_ENV: value });

      expect(env.NEXT_PUBLIC_APP_ENV).toBe(value);
    },
  );

  it("defaults to development when the variable is missing", () => {
    const env = createAppEnv({ NEXT_PUBLIC_APP_ENV: undefined });

    expect(env.NEXT_PUBLIC_APP_ENV).toBe("development");
  });

  it("defaults to development when the variable is an empty string", () => {
    const env = createAppEnv({ NEXT_PUBLIC_APP_ENV: "" });

    expect(env.NEXT_PUBLIC_APP_ENV).toBe("development");
  });

  it("rejects an unknown environment name", () => {
    expect(() => createAppEnv({ NEXT_PUBLIC_APP_ENV: "staging" })).toThrow(
      "Invalid environment variables",
    );
  });
});
