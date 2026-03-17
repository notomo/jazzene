import { test, expect } from "@playwright/test";
import { openPage } from "./page";

test("should show both sheet and piano roll by default", async ({ page }) => {
  const jazzene = await openPage({ page });

  await expect(jazzene.getLeadSheetContainer()).toBeVisible();
  await expect(jazzene.getFallingNotes()).toBeVisible();
});

test("should hide sheet when sheet button toggled off", async ({ page }) => {
  const jazzene = await openPage({ page });

  await jazzene.getViewModeSelect().getByTitle("Sheet").click();

  await expect(jazzene.getLeadSheetContainer()).not.toBeVisible();
  await expect(jazzene.getFallingNotes()).toBeVisible();
});

test("should hide piano roll when piano button toggled off", async ({
  page,
}) => {
  const jazzene = await openPage({ page });

  await jazzene.getViewModeSelect().getByTitle("Piano").click();

  await expect(jazzene.getFallingNotes()).not.toBeVisible();
  await expect(jazzene.getLeadSheetContainer()).toBeVisible();
});

test("should restore sheet when sheet button toggled back on", async ({
  page,
}) => {
  const jazzene = await openPage({ page });

  await jazzene.getViewModeSelect().getByTitle("Sheet").click();
  await expect(jazzene.getLeadSheetContainer()).not.toBeVisible();

  await jazzene.getViewModeSelect().getByTitle("Sheet").click();
  await expect(jazzene.getLeadSheetContainer()).toBeVisible();
});
