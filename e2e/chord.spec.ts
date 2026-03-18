import { test, expect } from "@playwright/test";
import { openPage } from "./page";

test("should show error for invalid chord and clear on valid input", async ({
  page,
}) => {
  const jazzene = await openPage({ page });

  await jazzene.setChordProgression("INVALID");
  await expect(page.getByLabel("chord parse error")).toBeVisible();

  await jazzene.setChordProgression("IIm7 V7 Imaj7");
  await expect(page.getByLabel("chord parse error")).not.toBeVisible();
});
