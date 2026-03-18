import { test, expect } from "@playwright/test";
import { openPage } from "./page";

test("should seek forward and backward when scrolling on piano roll", async ({
  page,
}) => {
  const jazzene = await openPage({ page });

  const canvas = jazzene.getPianoRollCanvas();

  const positionBefore = await jazzene.getPlaybackPosition();

  await canvas.dispatchEvent("wheel", { deltaY: 300, deltaMode: 0 });
  const positionAfterForward = await jazzene.getPlaybackPosition();
  expect(positionAfterForward).toBeGreaterThan(positionBefore);

  await canvas.dispatchEvent("wheel", { deltaY: -300, deltaMode: 0 });
  const positionAfterBackward = await jazzene.getPlaybackPosition();
  expect(positionAfterBackward).toBeLessThan(positionAfterForward);
});
