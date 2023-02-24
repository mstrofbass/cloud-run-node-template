import { configDefaults, defineConfig } from "vitest/config";

// Bumping testTimeout because if this is done against Cloud Run it may take a few seconds to spin up an instance

export default defineConfig({
  test: {
    testTimeout: 15000,
    include: [...configDefaults.exclude, "spec/e2e/**"],
    globalSetup: "spec/setup.js",
  },
});
