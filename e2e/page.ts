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

    getChordBadge: (label: string) =>
      page.getByLabel(`chord badge ${label}`),
    getChordEditorDialog: () => page.getByLabel("chord editor dialog"),
    getAddChordButton: () => page.getByLabel("add chord"),
    getDeleteChordButton: () =>
      page.getByLabel("chord editor dialog").getByLabel("delete chord"),
    getDiatonicShortcutButton: (label: string) =>
      page
        .getByLabel("chord editor dialog")
        .getByTitle(`Set to ${label}`),

    getPlayButton: () => page.getByRole("button", { name: "▶" }),
    getStopButton: () => page.getByRole("button", { name: "■" }),
    getPlayOrStopButton: () => page.getByRole("button", { name: /▶|■/ }),

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
    getLoopAInput: () => page.getByLabel("loop_a", { exact: true }),
    getLoopBInput: () => page.getByLabel("loop_b", { exact: true }),
    incrementLoopA: async () => {
      await page
        .getByLabel("loop_a control")
        .getByRole("button", { name: "+" })
        .click();
    },
    getVolumeInput: () => page.getByLabel("Volume", { exact: true }),
    incrementVolume: async () => {
      await page
        .getByLabel("volume control")
        .getByRole("button", { name: "+" })
        .click();
    },
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
      page
        .getByLabel("jazz settings panel")
        .getByRole("button", { name: "Import" }),
    getMidiExportButton: () =>
      page
        .getByLabel("jazz settings panel")
        .getByRole("button", { name: "Export" }),

    getMidiDeviceSelect: () => page.getByLabel("MIDI input device"),
    getMidiDeviceSelectNotSupported: () =>
      page.getByLabel("MIDI input device (not supported)"),
    getRecordToggleButton: () =>
      page.getByRole("button", { name: "toggle recording" }),
    getRecordedLine: (n: number) => page.getByText(`● Rec ${n}`),
    getDeleteRecordedLineButton: () =>
      page.getByRole("button", { name: "delete recorded line" }),

    getPracticeCurrentScore: () =>
      page.getByLabel("practice current score"),
    getPracticeBestScore: () => page.getByLabel("practice best score"),
  };

  return jazzenePage;
}
