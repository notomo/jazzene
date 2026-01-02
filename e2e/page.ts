import type { Page } from "@playwright/test";

export async function openJazzenePage({ page }: { page: Page }) {
  await page.goto("/");

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

    // Seekbar and time display
    getSeekbar: () => page.getByLabel("playback position"),
    getTimeDisplay: () => page.getByLabel("time display"),

    // Helper methods
    setChordProgression: async (chords: string) => {
      const input = jazzenePage.getChordInput();
      await input.clear();
      await input.fill(chords);
    },

    getSeekbarValue: async () => {
      const seekbar = jazzenePage.getSeekbar();
      return await seekbar.inputValue();
    },

    setSeekbarValue: async (value: string) => {
      const seekbar = jazzenePage.getSeekbar();
      await seekbar.fill(value);
    },

    play: async () => {
      const playButton = jazzenePage.getPlayButton();
      await playButton.click();
    },

    stop: async () => {
      const stopButton = jazzenePage.getStopButton();
      await stopButton.click();
    },

    getTimeDisplayText: async () => {
      const timeDisplay = jazzenePage.getTimeDisplay();
      return await timeDisplay.textContent();
    },

    waitForPlayback: async (ms: number) => {
      await page.waitForTimeout(ms);
    },
  };

  return jazzenePage;
}
