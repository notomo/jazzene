import { test, expect } from "@playwright/test";
import { openPage } from "./page";

test("should show play/stop button state changes", async ({ page }) => {
  const jazzene = await openPage({ page });

  await jazzene.play();
  await expect(jazzene.getStopButton()).toBeEnabled();

  await jazzene.stop();
  await expect(jazzene.getPlayButton()).toBeEnabled();
});

test("should seek to clicked measure position", async ({ page }) => {
  const jazzene = await openPage({ page });

  const positionBefore = await jazzene.getPlaybackPosition();

  await jazzene.play();
  await jazzene.clickMeasure(5);

  const positionAfter = await jazzene.getPlaybackPosition();
  expect(positionAfter).toBeGreaterThan(positionBefore);
  await expect(jazzene.getStopButton()).toBeEnabled();
});
