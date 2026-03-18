import type { Page } from "@playwright/test";

export type ViewName = "sheet" | "pianoroll" | "setting";

export async function openPage({
  page,
  queryParams,
  view,
}: {
  page: Page;
  queryParams?: Record<string, string>;
  view?: ViewName[];
}) {
  const allParams: Record<string, string> = { ...queryParams };
  if (view !== undefined) {
    allParams["view"] = view.join(",");
  }
  const params = new URLSearchParams(allParams);
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

    getSettingsPanel: () => page.getByLabel("jazz settings panel"),

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
    getPlaybackIndicator: () =>
      page.locator('line[aria-label="playback indicator"]').first(),
    getPlaybackPosition: async () => {
      const indicator = page
        .locator('line[aria-label="playback indicator"]')
        .first();
      await indicator.waitFor({ state: "attached" });
      return Number(await indicator.getAttribute("x1"));
    },
    getMidiImportButton: () =>
      page.getByLabel("jazz settings panel").getByRole("button", { name: "Import" }),
    getMidiExportButton: () =>
      page.getByLabel("jazz settings panel").getByRole("button", { name: "Export" }),
  };

  return jazzenePage;
}
