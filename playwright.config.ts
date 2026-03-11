import { defineConfig, devices } from "@playwright/test";

const isCI = !!process.env.CI;
const usePreview = isCI || !!process.env.E2E_PREVIEW;
const port = usePreview ? 4173 : 5173;
const baseURL = `http://localhost:${port}`;

/**
 * See https://playwright.dev/docs/test-configuration.
 */
export default defineConfig({
  testDir: "./e2e",
  fullyParallel: true,
  forbidOnly: isCI,
  retries: isCI ? 2 : 0,
  workers: isCI ? 1 : undefined,
  reporter: "html",
  use: {
    baseURL,
    trace: "on-first-retry",
  },

  projects: [
    {
      name: "chromium",
      use: {
        ...devices["Desktop Chrome"],
        launchOptions: {
          args: ["--window-position=3520,0", "--window-size=1920,1080"],
        },
      },
    },
  ],

  webServer: {
    command: usePreview ? "npm run preview" : "npm run dev",
    url: baseURL,
    reuseExistingServer: !isCI,
  },
});
