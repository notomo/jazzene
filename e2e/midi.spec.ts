import { test, expect } from "@playwright/test";
import { openPage } from "./page";

// Minimal valid SMF0 MIDI file: format 0, 1 track, 480 tpq, end-of-track only.
// Equivalent to smf0(480, [0, 255, 47, 0]) from the MoonBit decoder tests.
const MINIMAL_MIDI_BYTES = Buffer.from([
  77, 84, 104, 100, // MThd magic
  0, 0, 0, 6, // header length
  0, 0, // format 0
  0, 1, // 1 track
  1, 224, // 480 tpq
  77, 84, 114, 107, // MTrk magic
  0, 0, 0, 4, // track data length
  0, 255, 47, 0, // delta=0, end-of-track
]);

test("should trigger download with .mid extension when Export clicked", async ({
  page,
}) => {
  const jazzene = await openPage({ page });
  await jazzene.openSettingsPanel();

  const [download] = await Promise.all([
    page.waitForEvent("download"),
    jazzene.getMidiExportButton().click(),
  ]);

  expect(download.suggestedFilename()).toMatch(/jazzene_\d{8}_\d{6}\.mid$/);
});

test("should open file chooser when Import clicked", async ({ page }) => {
  const jazzene = await openPage({ page });
  await jazzene.openSettingsPanel();

  const [fileChooser] = await Promise.all([
    page.waitForEvent("filechooser"),
    jazzene.getMidiImportButton().click(),
  ]);

  expect(fileChooser.isMultiple()).toBe(false);
});

test("should clear chord progression after importing a MIDI file", async ({
  page,
}) => {
  const jazzene = await openPage({ page });

  // Default chord progression should be non-empty
  await expect(jazzene.getChordInput()).not.toHaveValue("");

  await jazzene.openSettingsPanel();

  const [fileChooser] = await Promise.all([
    page.waitForEvent("filechooser"),
    jazzene.getMidiImportButton().click(),
  ]);

  await fileChooser.setFiles({
    name: "test.mid",
    mimeType: "audio/midi",
    buffer: MINIMAL_MIDI_BYTES,
  });

  await expect(jazzene.getChordInput()).toHaveValue("");
});
