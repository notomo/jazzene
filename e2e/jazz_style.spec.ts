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

  await page.waitForFunction(() => {
    const params = new URLSearchParams(window.location.search);
    return params.has("melody") && params.has("swing") && params.has("comping");
  });

  const url = new URL(page.url());
  expect(url.searchParams.get("melody")).toBe("off");
  expect(url.searchParams.get("swing")).toBe("hard");
  expect(url.searchParams.get("comping")).toBe("off");
});

test("should update comping, bass, and drum style selections", async ({
  page,
}) => {
  const jazzene = await openPage({ page, view: ["sheet", "pianoroll", "setting"] });
  const panel = jazzene.getSettingsPanel();

  // Default: comping=WithTensions, bass=WalkingBass, drums=SwingRide
  await panel.getByLabel("comping").getByRole("button", { name: "Full" }).click();
  await panel.getByLabel("bass").getByRole("button", { name: "Root" }).click();
  await panel.getByLabel("drums").getByRole("button", { name: "Brush" }).click();

  await page.waitForFunction(() => {
    const params = new URLSearchParams(window.location.search);
    return (
      params.has("comping_style") &&
      params.has("bass") &&
      params.has("drums")
    );
  });

  const url = new URL(page.url());
  expect(url.searchParams.get("comping_style")).toBe("full");
  expect(url.searchParams.get("bass")).toBe("root");
  expect(url.searchParams.get("drums")).toBe("brush");
});

test("should apply Simple preset and restore with Default preset", async ({
  page,
}) => {
  const jazzene = await openPage({ page, view: ["sheet", "pianoroll", "setting"] });
  const panel = jazzene.getSettingsPanel();

  // Simple preset changes comping_style to GuideTones and bass_style to RootOnly
  await panel.getByRole("button", { name: "Simple" }).click();
  await page.waitForFunction(() =>
    new URLSearchParams(window.location.search).has("comping_style"),
  );
  expect(new URL(page.url()).searchParams.get("comping_style")).toBe("guide");
  expect(new URL(page.url()).searchParams.get("bass")).toBe("root");

  // Default preset restores defaults (params disappear from URL)
  await panel.getByRole("button", { name: "Default" }).click();
  await page.waitForFunction(() =>
    !new URLSearchParams(window.location.search).has("comping_style"),
  );
  expect(new URL(page.url()).searchParams.get("comping_style")).toBeNull();
  expect(new URL(page.url()).searchParams.get("bass")).toBeNull();
});

test("should toggle technique hints", async ({ page }) => {
  const jazzene = await openPage({ page, view: ["sheet", "pianoroll", "setting"] });
  const panel = jazzene.getSettingsPanel();

  // Technique hints are on by default; turning off sets hint=off in URL
  await panel.locator("label", { hasText: "Technique Hints" }).click();
  await page.waitForFunction(() =>
    new URLSearchParams(window.location.search).has("hint"),
  );
  expect(new URL(page.url()).searchParams.get("hint")).toBe("off");
});
