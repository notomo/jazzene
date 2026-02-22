import type { Page } from "@playwright/test";

export async function openJazzenePage({
  page,
  queryParams,
}: {
  page: Page;
  queryParams?: Record<string, string>;
}) {
  const params = new URLSearchParams(queryParams);
  const url = params.size > 0 ? `/?${params.toString()}` : "/";
  await page.goto(url);

  const jazzenePage = {
    // Main sections
    getLeadSheet: () => page.getByLabel("lead sheet"),
    getVisualization: () => page.getByLabel("visualization"),
    getFallingNotes: () => page.getByLabel("falling notes"),

    // Chord progression input
    getChordInput: () => page.getByPlaceholder(/Enter chord progression/),

    // Playback controls
    getPlayButton: () => page.getByRole("button", { name: "▶" }),
    getStopButton: () => page.getByRole("button", { name: "■" }),
    getPlayOrStopButton: () => page.getByRole("button", { name: /▶|■/ }),

    // Helper methods
    setChordProgression: async (chords: string) => {
      const input = jazzenePage.getChordInput();
      await input.clear();
      await input.fill(chords);
    },

    play: async () => {
      const playButton = jazzenePage.getPlayButton();
      await playButton.click();
    },

    stop: async () => {
      const stopButton = jazzenePage.getStopButton();
      await stopButton.click();
    },

    waitForPlayback: async (ms: number) => {
      await page.waitForTimeout(ms);
    },

    getMeasure: (measureNumber: number) =>
      page.getByLabel(`measure ${measureNumber}`),

    clickMeasure: async (measureNumber: number) => {
      const measure = jazzenePage.getMeasure(measureNumber);
      await measure.click();
    },

    getSettingsButton: () => page.getByRole("button", { name: "Jazz" }),
    getSettingsPanel: () => page.getByLabel("jazz settings panel"),
    openSettingsPanel: async () => {
      await jazzenePage.getSettingsButton().click();
    },

    getBpmInput: () => page.getByLabel("bpm"),
    getSeedInput: () => page.getByLabel("seed"),
    getMeasuresInput: () => page.getByLabel("measures"),
    getKeySelect: () => page.getByLabel("key", { exact: true }),
    getViewModeSelect: () => page.getByLabel("view mode"),
    getActiveViewModeButton: () =>
      page.getByLabel("view mode").locator("button.bg-blue-900"),
    getLoopAInput: () => page.getByLabel("loop_a"),
    getLoopBInput: () => page.getByLabel("loop_b"),
    getTimeSignatureSelect: () => page.getByLabel("time signature"),
  };

  return jazzenePage;
}
