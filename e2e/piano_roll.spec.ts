import { test, expect } from "@playwright/test";
import { openPage } from "./page";

test("should seek forward when scrolling down on piano roll", async ({
  page,
}) => {
  const jazzene = await openPage({ page });

  const indicator = jazzene.getPlaybackIndicator();
  await indicator.waitFor({ state: "attached" });
  const x1Before = await indicator.getAttribute("x1");

  const canvas = jazzene.getPianoRollCanvas();
  await canvas.dispatchEvent("wheel", { deltaY: 300, deltaMode: 0 });

  const x1After = await indicator.getAttribute("x1");
  expect(Number(x1After)).toBeGreaterThan(Number(x1Before));
});

test("should seek backward when scrolling up on piano roll", async ({
  page,
}) => {
  const jazzene = await openPage({ page });

  // First scroll forward to get some position
  const canvas = jazzene.getPianoRollCanvas();
  await canvas.dispatchEvent("wheel", { deltaY: 300, deltaMode: 0 });

  const indicator = jazzene.getPlaybackIndicator();
  const x1Before = await indicator.getAttribute("x1");

  await canvas.dispatchEvent("wheel", { deltaY: -300, deltaMode: 0 });

  const x1After = await indicator.getAttribute("x1");
  expect(Number(x1After)).toBeLessThan(Number(x1Before));
});

test("should not seek below zero when scrolling up from start", async ({
  page,
}) => {
  const jazzene = await openPage({ page });

  const indicator = jazzene.getPlaybackIndicator();
  const x1Start = await indicator.getAttribute("x1");

  const canvas = jazzene.getPianoRollCanvas();
  await canvas.dispatchEvent("wheel", { deltaY: -300, deltaMode: 0 });

  const x1After = await indicator.getAttribute("x1");
  expect(Number(x1After)).toBeGreaterThanOrEqual(Number(x1Start));
});
