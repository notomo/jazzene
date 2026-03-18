import { test, expect } from "@playwright/test";
import { openPage } from "./page";

test("should toggle sheet view", async ({ page }) => {
  const jazzene = await openPage({ page });

  await expect(jazzene.getLeadSheetContainer()).toBeVisible();

  await jazzene.getViewModeSelect().getByTitle("Sheet").click();
  await expect(jazzene.getLeadSheetContainer()).not.toBeVisible();

  await jazzene.getViewModeSelect().getByTitle("Sheet").click();
  await expect(jazzene.getLeadSheetContainer()).toBeVisible();
});

test("should toggle piano roll view", async ({ page }) => {
  const jazzene = await openPage({ page });

  await expect(jazzene.getFallingNotes()).toBeVisible();

  await jazzene.getViewModeSelect().getByTitle("Piano").click();
  await expect(jazzene.getFallingNotes()).not.toBeVisible();

  await jazzene.getViewModeSelect().getByTitle("Piano").click();
  await expect(jazzene.getFallingNotes()).toBeVisible();
});

test("should toggle settings panel", async ({ page }) => {
  const jazzene = await openPage({ page });

  await expect(jazzene.getSettingsPanel()).not.toBeVisible();

  await jazzene.getViewModeSelect().getByTitle("Settings").click();
  await expect(jazzene.getSettingsPanel()).toBeVisible();

  await jazzene.getViewModeSelect().getByTitle("Settings").click();
  await expect(jazzene.getSettingsPanel()).not.toBeVisible();
});
