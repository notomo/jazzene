import { test, expect } from "@playwright/test";
import { openPage } from "./page";

test("should open settings panel with jazz controls", async ({ page }) => {
  const jazzene = await openPage({ page });

  await jazzene.openSettingsPanel();
  const panel = jazzene.getSettingsPanel();

  await expect(panel).toBeVisible();
  await expect(panel).toContainText("Melody Techniques");
  await expect(panel).toContainText("Comping");
  await expect(panel).toContainText("Bass");
  await expect(panel).toContainText("Drums");
});

test("should apply preset when clicked in settings panel", async ({ page }) => {
  const jazzene = await openPage({ page });

  await jazzene.openSettingsPanel();
  const panel = jazzene.getSettingsPanel();

  await expect(panel).toBeVisible();
  await panel.getByRole("button", { name: "Straight" }).click();
  await expect(panel).toBeVisible();
  await expect(panel).toContainText("Simple");
  await expect(panel).toContainText("Default");
});
