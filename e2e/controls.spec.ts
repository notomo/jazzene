import { test, expect } from "@playwright/test";
import { openPage } from "./page";

test("should change A/B loop range", async ({ page }) => {
  const jazzene = await openPage({ page });

  // Default loop_a = 1; clicking + increments to 2
  await jazzene.incrementLoopA();
  await expect(jazzene.getLoopAInput()).toHaveText("2");
});

test("should change volume", async ({ page }) => {
  const jazzene = await openPage({ page });

  // Default volume = 50; clicking + increments by step 5 to 55
  await jazzene.incrementVolume();
  await expect(jazzene.getVolumeInput()).toHaveText("55");
});
