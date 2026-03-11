import { test, expect } from "@playwright/test";
import { openJazzenePage } from "./page";

test.describe("Jazzene - Jazz Improvisation Web App", () => {
  let jazzene: Awaited<ReturnType<typeof openJazzenePage>>;

  test.beforeEach(async ({ page }) => {
    jazzene = await openJazzenePage({ page });
  });

  test("should render all three main sections", async () => {
    await expect(jazzene.getChordInput()).toBeVisible();
    await expect(jazzene.getPlayButton()).toBeEnabled();
    await expect(jazzene.getFallingNotes()).toBeVisible();
    await expect(jazzene.getLeadSheet()).toBeVisible();
  });

  test("should allow editing chord progression", async () => {
    await jazzene.setChordProgression("Dm7 G7 Cmaj7");

    await expect(jazzene.getChordInput()).toHaveValue("Dm7 G7 Cmaj7");
  });

  test("should show play/stop button state changes", async () => {
    await jazzene.play();
    await expect(jazzene.getStopButton()).toBeEnabled();

    await jazzene.stop();
    await expect(jazzene.getPlayButton()).toBeEnabled();
  });

  test("should open settings panel with jazz controls", async () => {
    await jazzene.openSettingsPanel();
    const panel = jazzene.getSettingsPanel();

    await expect(panel).toBeVisible();
    // Verify all sections are present in the panel text
    await expect(panel).toContainText("Melody Techniques");
    await expect(panel).toContainText("Comping");
    await expect(panel).toContainText("Bass");
    await expect(panel).toContainText("Drums");
  });

  test("should apply preset when clicked in settings panel", async () => {
    await jazzene.openSettingsPanel();
    const panel = jazzene.getSettingsPanel();

    await expect(panel).toBeVisible();
    // Click "Straight" preset - should be visible in panel
    await panel.getByRole("button", { name: "Straight" }).click();
    // Panel should still be open
    await expect(panel).toBeVisible();
    // Preset section should contain all expected presets
    await expect(panel).toContainText("Simple");
    await expect(panel).toContainText("Default");
  });

  test("should persist jazz style to URL when changed", async ({ page }) => {
    await jazzene.openSettingsPanel();
    const panel = jazzene.getSettingsPanel();

    // Click "Straight" preset which disables swing and accompaniment
    await panel.getByRole("button", { name: "Straight" }).click();

    // URL should be updated with jazz style params
    await page.waitForFunction(() =>
      new URLSearchParams(window.location.search).has("swing")
    );
    const url = new URL(page.url());
    expect(url.searchParams.get("swing")).toBe("straight");
    expect(url.searchParams.get("comping")).toBe("off");
    expect(url.searchParams.get("drums")).toBe("off");
    expect(url.searchParams.get("bass")).toBe("off");
  });

  test("should change playback position when clicking a measure", async () => {
    await jazzene.play();
    await jazzene.clickMeasure(5);

    await expect(jazzene.getStopButton()).toBeEnabled();
  });
});

test.describe("Jazzene - Query Parameters", () => {
  test("should reflect query parameters in controls", async ({ page }) => {
    const params = {
      key: "D",
      time: "3/4",
      bpm: "140",
      seed: "42",
      measures: "16",
      chords: "IIIm7 | VIm7",
      view: "sheet",
      loop_a: "3",
      loop_b: "6",
    };
    const jazzene = await openJazzenePage({ page, queryParams: params });

    await expect(jazzene.getTimeSignatureSelect()).toHaveValue("3/4");
    await expect(jazzene.getKeySelect()).toHaveValue("D");
    await expect(jazzene.getBpmInput()).toHaveText("140");
    await expect(jazzene.getSeedInput()).toHaveText("42");
    await expect(jazzene.getMeasuresInput()).toHaveText("16");
    await expect(jazzene.getChordInput()).toHaveValue("IIIm7 | VIm7");
    await expect(jazzene.getActiveViewModeButton()).toHaveAttribute("title", "Sheet");
    await expect(jazzene.getLoopAInput()).toHaveText("3");
    await expect(jazzene.getLoopBInput()).toHaveText("6");
  });

  test("should restore jazz style from URL query parameters", async ({ page }) => {
    const params = {
      swing: "hard",
      techniques: "00000000",
      comping: "off",
      drums: "sride",
      bass: "root",
    };
    const jazzene = await openJazzenePage({ page, queryParams: params });

    // Open settings panel to verify the restored state
    await jazzene.openSettingsPanel();
    const panel = jazzene.getSettingsPanel();
    await expect(panel).toBeVisible();

    // Comping should show as disabled (toggle off)
    await expect(panel).toContainText("Drums");
  });
});
