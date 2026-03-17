import type { Page } from "@playwright/test";

export async function openPage({
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
    getLeadSheet: () => page.getByLabel("lead sheet"),
    getVisualization: () => page.getByLabel("visualization"),
    getFallingNotes: () => page.getByLabel("falling notes"),

    getChordInput: () => page.getByPlaceholder(/Enter chord progression/),

    getPlayButton: () => page.getByRole("button", { name: "▶" }),
    getStopButton: () => page.getByRole("button", { name: "■" }),
    getPlayOrStopButton: () => page.getByRole("button", { name: /▶|■/ }),

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

    getSettingsButton: () => page.getByRole("button", { name: "Setting" }),
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

    getLeadSheetContainer: () => page.locator("#lead-sheet-container"),
    getPianoRollCanvas: () =>
      page.getByLabel("falling notes").locator("canvas"),
    getPlaybackIndicator: () => page.locator('line[stroke="#3b82f6"]').first(),
    getMidiImportButton: () =>
      page.getByLabel("jazz settings panel").getByRole("button", { name: "Import" }),
    getMidiExportButton: () =>
      page.getByLabel("jazz settings panel").getByRole("button", { name: "Export" }),
  };

  return jazzenePage;
}
