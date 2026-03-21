import { test, expect } from "@playwright/test";
import { openPage } from "./page";

test("should reflect query parameters in controls", async ({ page }) => {
  const jazzene = await openPage({
    page,
    queryParams: {
      key: "D",
      time: "3/4",
      bpm: "140",
      seed: "42",
      measures: "16",
      chords: "IIIm7 | VIm7",
      view: "sheet",
      loop_a: "3",
      loop_b: "6",
    },
  });

  await expect(jazzene.getTimeSignatureSelect()).toHaveValue("3/4");
  await expect(jazzene.getKeySelect()).toHaveValue("D");
  await expect(jazzene.getBpmInput()).toHaveText("140");
  await expect(jazzene.getSeedInput()).toHaveText("42");
  await expect(jazzene.getMeasuresInput()).toHaveText("16");
  // IIIm7 in D = F#m7, VIm7 in D = Bm7
  await expect(jazzene.getChordBadge("F#m7")).toBeVisible();
  await expect(jazzene.getChordBadge("Bm7")).toBeVisible();
  await expect(jazzene.getLeadSheetContainer()).toBeVisible();
  await expect(jazzene.getFallingNotes()).not.toBeVisible();
  await expect(jazzene.getLoopAInput()).toHaveText("3");
  await expect(jazzene.getLoopBInput()).toHaveText("6");
});

test("should persist jazz style to URL when changed", async ({ page }) => {
  const jazzene = await openPage({ page, view: ["sheet", "pianoroll", "setting"] });

  const panel = jazzene.getSettingsPanel();

  await panel.getByRole("button", { name: "Straight" }).click();

  await page.waitForFunction(() =>
    new URLSearchParams(window.location.search).has("swing"),
  );
  const url = new URL(page.url());
  expect(url.searchParams.get("swing")).toBe("straight");
  expect(url.searchParams.get("comping")).toBe("off");
  expect(url.searchParams.get("drums")).toBe("off");
  expect(url.searchParams.get("bass")).toBe("off");
});

test("should restore jazz style from URL query parameters", async ({
  page,
}) => {
  const jazzene = await openPage({
    page,
    queryParams: {
      swing: "hard",
      melody: "off",
      comping: "off",
      bass: "root",
    },
    view: ["sheet", "pianoroll", "setting"],
  });

  const panel = jazzene.getSettingsPanel();
  await expect(
    panel
      .getByLabel("swing")
      .getByRole("button", { name: "Hard", pressed: true }),
  ).toBeVisible();
  await expect(
    panel
      .getByLabel("melody")
      .getByRole("button", { name: "Off", pressed: true }),
  ).toBeVisible();
  await expect(
    panel
      .getByLabel("comping")
      .getByRole("button", { name: "Off", pressed: true }),
  ).toBeVisible();
});
