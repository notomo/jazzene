import { test, expect } from "@playwright/test";
import { openPage } from "./page";

test("should show play/stop button state changes", async ({ page }) => {
  const jazzene = await openPage({ page });

  await jazzene.play();
  await expect(jazzene.getStopButton()).toBeEnabled();

  await jazzene.stop();
  await expect(jazzene.getPlayButton()).toBeEnabled();
});

test("should change playback position when clicking a measure", async ({
  page,
}) => {
  const jazzene = await openPage({ page });

  await jazzene.play();
  await jazzene.clickMeasure(5);

  await expect(jazzene.getStopButton()).toBeEnabled();
});
