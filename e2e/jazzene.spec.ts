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
    await expect(jazzene.getSeekbar()).toBeEnabled();
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

  test("should update time display during playback", async () => {
    await jazzene.play();

    await jazzene.waitForPlayback(200);

    const totalTime = await jazzene.getTimeDisplayText();
    expect(totalTime).not.toContain("0:00 / 0:00"); // Should not be initial state
  });

  test("should update seekbar value during playback", async () => {
    const initialValue = await jazzene.getSeekbarValue();

    await jazzene.play();
    await jazzene.waitForPlayback(100);

    expect(parseInt(await jazzene.getSeekbarValue())).toBeGreaterThan(
      parseInt(initialValue),
    );
  });

  test("should restart from beginning when play is pressed after playback finishes", async () => {
    await jazzene.setSeekbarValue("100");

    await jazzene.play();
    await jazzene.waitForPlayback(100);
    await expect(jazzene.getStopButton()).toBeEnabled();
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
      loop: "false",
      loop_a: "0:05",
      loop_b: "0:10",
    };
    const paramJazzene = await openJazzenePage({ page, queryParams: params });

    await expect(paramJazzene.getTimeSignatureSelect()).toHaveValue("3/4");
    await expect(paramJazzene.getKeySelect()).toHaveValue("D");
    await expect(paramJazzene.getBpmInput()).toHaveText("140");
    await expect(paramJazzene.getSeedInput()).toHaveText("42");
    await expect(paramJazzene.getMeasuresInput()).toHaveText("16");
    await expect(paramJazzene.getChordInput()).toHaveValue("IIIm7 | VIm7");
    await expect(paramJazzene.getDisplayModeSelect()).toHaveValue("Sheet");
    await expect(paramJazzene.getLoopCheckbox()).not.toBeChecked();
    await expect(paramJazzene.getLoopAInput()).toHaveValue("0:05");
    await expect(paramJazzene.getLoopBInput()).toHaveValue("0:10");
  });

  test("should change playback position when clicking a measure", async () => {
    const initialValue = parseInt(await jazzene.getSeekbarValue());

    await jazzene.clickMeasure(5);

    const newValue = parseInt(await jazzene.getSeekbarValue());
    expect(newValue).toBeGreaterThan(initialValue);
  });
});
