import { test, expect } from "@playwright/test";
import { openPage } from "./page";

test("should allow editing chord progression", async ({ page }) => {
  const jazzene = await openPage({ page });

  await jazzene.setChordProgression("Dm7 G7 Cmaj7");

  await expect(jazzene.getChordInput()).toHaveValue("Dm7 G7 Cmaj7");
});
