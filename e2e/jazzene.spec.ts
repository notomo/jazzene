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
    const paramJazzene = await openJazzenePage({ page, queryParams: params });

    await expect(paramJazzene.getTimeSignatureSelect()).toHaveValue("3/4");
    await expect(paramJazzene.getKeySelect()).toHaveValue("D");
    await expect(paramJazzene.getBpmInput()).toHaveText("140");
    await expect(paramJazzene.getSeedInput()).toHaveText("42");
    await expect(paramJazzene.getMeasuresInput()).toHaveText("16");
    await expect(paramJazzene.getChordInput()).toHaveValue("IIIm7 | VIm7");
    await expect(paramJazzene.getActiveDisplayModeButton()).toHaveText("Sheet");
    await expect(paramJazzene.getLoopAInput()).toHaveText("3");
    await expect(paramJazzene.getLoopBInput()).toHaveText("6");
  });

  test("should change playback position when clicking a measure", async () => {
    await jazzene.play();
    await jazzene.clickMeasure(5);

    await expect(jazzene.getStopButton()).toBeEnabled();
  });
});
