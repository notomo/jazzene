import { test, expect } from "@playwright/test";
import { openPage } from "./page";

test("should render all three main sections", async ({ page }) => {
  const jazzene = await openPage({ page });

  await expect(jazzene.getChordInput()).toBeVisible();
  await expect(jazzene.getPlayButton()).toBeEnabled();
  await expect(jazzene.getFallingNotes()).toBeVisible();
  await expect(jazzene.getLeadSheet()).toBeVisible();
});
