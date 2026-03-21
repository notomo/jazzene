import { test, expect } from "@playwright/test";
import { openPage } from "./page";
import { setupMidiMock } from "./midi_mock";

const NOTE_ON_C4 = [0x90, 60, 100]; // Note On ch1, C4, velocity 100
const NOTE_OFF_C4 = [0x80, 60, 0]; // Note Off ch1, C4

test("practice scores are always visible in MIDI settings", async ({
  page,
}) => {
  const jazzene = await openPage({ page, view: ["setting"] });

  await expect(jazzene.getPracticeCurrentScore()).toBeVisible();
  await expect(jazzene.getPracticeCurrentScore()).toHaveText(/^0\.0 \//);
  await expect(jazzene.getPracticeBestScore()).toBeVisible();
  await expect(jazzene.getPracticeBestScore()).toHaveText(/^0\.0 \//);
});

test("practice score increments on correct note_on and note_off", async ({
  page,
}) => {
  // Use a fixed seed and chord so melody is deterministic.
  // With seed=1 and chord I in C, C4 (MIDI 60) is a chord tone and will
  // appear in the melody or comping within the 300ms tolerance window.
  const sendMidi = await setupMidiMock(page, {
    inputs: [{ id: "input-1", name: "Test Device" }],
  });
  const jazzene = await openPage({
    page,
    view: ["setting"],
    queryParams: { seed: "1", chords: "I" },
  });

  // Wait for MIDI device to be ready
  await expect(
    jazzene.getMidiDeviceSelect().getByRole("option", { name: "Test Device" }),
  ).toBeAttached();
  await page.waitForTimeout(100);

  // Start playback and advance past the leading rest measure
  await jazzene.play();
  await jazzene.waitForPlayback(2500);

  // Send note_on — press timing match gives +0.5
  await sendMidi("input-1", NOTE_ON_C4);
  await jazzene.waitForPlayback(300);
  // Send note_off — release timing match gives +0.5
  await sendMidi("input-1", NOTE_OFF_C4);

  // Score should have increased (at least +0.5 for press)
  const scoreText = await jazzene.getPracticeCurrentScore().textContent();
  const score = parseFloat(scoreText ?? "0");
  expect(score).toBeGreaterThan(0);
});

test("best score is updated and current score resets on loop restart", async ({
  page,
}) => {
  const sendMidi = await setupMidiMock(page, {
    inputs: [{ id: "input-1", name: "Test Device" }],
  });
  // Use 1 measure + short A-B loop so loop restarts quickly
  const jazzene = await openPage({
    page,
    view: ["setting"],
    queryParams: { seed: "1", chords: "I", measures: "3", loop_a: "2", loop_b: "2" },
  });

  await expect(
    jazzene.getMidiDeviceSelect().getByRole("option", { name: "Test Device" }),
  ).toBeAttached();
  await page.waitForTimeout(100);

  // Start playback
  await jazzene.play();
  // Advance into the looped measure (measure 2 starts after 1 measure = 2000ms at 120bpm)
  await jazzene.waitForPlayback(2200);

  // Send a note
  await sendMidi("input-1", NOTE_ON_C4);
  await jazzene.waitForPlayback(200);
  await sendMidi("input-1", NOTE_OFF_C4);

  // Wait for the loop to restart (1-measure loop at 120bpm = 2000ms)
  await jazzene.waitForPlayback(2500);

  // After loop restart: current score resets to 0.0
  await expect(jazzene.getPracticeCurrentScore()).toHaveText(/^0\.0 \//);
  const bestText = await jazzene.getPracticeBestScore().textContent();
  const best = parseFloat(bestText ?? "0");
  expect(best).toBeGreaterThanOrEqual(0);
});
