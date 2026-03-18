import { test, expect } from "@playwright/test";
import { openPage } from "./page";

test("should toggle visualizations and settings panel", async ({ page }) => {
  const jazzene = await openPage({ page });

  await expect(jazzene.getLeadSheetContainer()).toBeVisible();
  await expect(jazzene.getFallingNotes()).toBeVisible();
  await expect(jazzene.getSettingsPanel()).not.toBeVisible();

  await jazzene.getViewModeSelect().getByTitle("Sheet").click();
  await expect(jazzene.getLeadSheetContainer()).not.toBeVisible();
  await jazzene.getViewModeSelect().getByTitle("Sheet").click();
  await expect(jazzene.getLeadSheetContainer()).toBeVisible();

  await jazzene.getViewModeSelect().getByTitle("Settings").click();
  await expect(jazzene.getSettingsPanel()).toBeVisible();

  await jazzene.getViewModeSelect().getByTitle("Piano").click();
  await expect(jazzene.getFallingNotes()).not.toBeVisible();
});
