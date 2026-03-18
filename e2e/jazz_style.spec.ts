import { test, expect } from "@playwright/test";
import { openPage } from "./page";

test("should update jazz style via settings panel controls", async ({
  page,
}) => {
  const jazzene = await openPage({ page, view: ["sheet", "pianoroll", "setting"] });
  const panel = jazzene.getSettingsPanel();

  await panel.getByLabel("melody").getByRole("button", { name: "Off" }).click();
  await panel.getByLabel("swing").getByRole("button", { name: "Hard" }).click();
  await panel.getByLabel("comping").getByRole("button", { name: "Off" }).click();

  await page.waitForFunction(() =>
    new URLSearchParams(window.location.search).has("melody"),
  );

  const url = new URL(page.url());
  expect(url.searchParams.get("melody")).toBe("off");
  expect(url.searchParams.get("swing")).toBe("hard");
  expect(url.searchParams.get("comping")).toBe("off");
});
