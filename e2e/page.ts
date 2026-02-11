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

    getBpmInput: () => page.getByLabel("bpm"),
    getSeedInput: () => page.getByLabel("seed"),
    getMeasuresInput: () => page.getByLabel("measures"),
    getKeySelect: () => page.getByLabel("key", { exact: true }),
    getDisplayModeSelect: () => page.getByLabel("display mode"),
    getLoopCheckbox: () => page.getByLabel("enable A-B loop"),
    getLoopAInput: () => page.getByLabel("A loop time"),
    getLoopBInput: () => page.getByLabel("B loop time"),
    getTimeSignatureSelect: () => page.getByLabel("time signature"),
  };

  return jazzenePage;
}
