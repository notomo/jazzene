import { test, expect } from "@playwright/test";
import { openPage } from "./page";

test("should display chord progression as clickable badges", async ({
  page,
}) => {
  const jazzene = await openPage({ page });

  // Default progression in C: IIm7=Dm7, V7=G7, Imaj7=C△, IVmaj7=F△
  await expect(jazzene.getChordBadge("Dm7")).toBeVisible();
});

test("should open editor dialog when clicking a chord badge", async ({
  page,
}) => {
  const jazzene = await openPage({ page });

  await jazzene.getChordBadge("Dm7").click();
  await expect(jazzene.getChordEditorDialog()).toBeVisible();
});

test("should close editor dialog when clicking backdrop", async ({ page }) => {
  const jazzene = await openPage({ page });

  await jazzene.getChordBadge("Dm7").click();
  await expect(jazzene.getChordEditorDialog()).toBeVisible();

  // Click the backdrop (outside the dialog panel)
  await page.mouse.click(10, 10);
  await expect(jazzene.getChordEditorDialog()).not.toBeVisible();
});

test("should add new chord via + button", async ({ page }) => {
  const jazzene = await openPage({ page });

  const initialCount = await page.getByLabel(/^chord badge/).count();
  await jazzene.getChordBadge("Dm7").click();
  await expect(jazzene.getChordEditorDialog()).toBeVisible();
  await jazzene.getAddChordButton().click();
  await expect(page.getByLabel(/^chord badge/)).toHaveCount(initialCount + 1);
});

test("should delete chord via editor", async ({ page }) => {
  const jazzene = await openPage({ page });

  const initialCount = await page.getByLabel(/^chord badge/).count();
  await jazzene.getChordBadge("Dm7").click();
  await jazzene.getDeleteChordButton().click();
  await expect(page.getByLabel(/^chord badge/)).toHaveCount(initialCount - 1);
});
