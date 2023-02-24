import { configDefaults, defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    exclude: [...configDefaults.exclude, "spec/e2e/**"],
    globalSetup: "spec/setup.js",
  },
});
