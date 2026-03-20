import { test, expect } from "@playwright/test";
import { openPage } from "./page";
import { setupMidiMock } from "./midi_mock";

// MIDI message constants
const NOTE_ON_C4 = [0x90, 60, 100]; // Note On ch1, C4, velocity 100
const NOTE_OFF_C4 = [0x80, 60, 0]; // Note Off ch1, C4

test("shows disabled select when Web MIDI API is not supported", async ({
  page,
}) => {
  await setupMidiMock(page, { supported: false });
  const jazzene = await openPage({ page, view: ["setting"] });

  await expect(jazzene.getMidiDeviceSelectNotSupported()).toBeVisible();
  await expect(jazzene.getMidiDeviceSelectNotSupported()).toBeDisabled();
});

test("shows disabled MIDI device select when no devices are available", async ({
  page,
}) => {
  await setupMidiMock(page, { inputs: [] });
  const jazzene = await openPage({ page, view: ["setting"] });

  await expect(jazzene.getMidiDeviceSelect()).toBeVisible();
  await expect(jazzene.getMidiDeviceSelect()).toBeDisabled();
});

test("shows available MIDI input devices in dropdown", async ({ page }) => {
  await setupMidiMock(page, {
    inputs: [
      { id: "input-1", name: "Virtual Keyboard" },
      { id: "input-2", name: "MIDI Controller" },
    ],
  });
  const jazzene = await openPage({ page, view: ["setting"] });

  const select = jazzene.getMidiDeviceSelect();
  await expect(select).toBeVisible();
  await expect(
    select.getByRole("option", { name: "Virtual Keyboard" }),
  ).toBeAttached();
  await expect(
    select.getByRole("option", { name: "MIDI Controller" }),
  ).toBeAttached();
});

test("record toggle button switches between Start and Stop Recording", async ({
  page,
}) => {
  await setupMidiMock(page, {
    inputs: [{ id: "input-1", name: "Test Device" }],
  });
  const jazzene = await openPage({ page, view: ["setting"] });

  const recordButton = jazzene.getRecordToggleButton();
  await expect(recordButton).toContainText("Start Recording");

  await recordButton.click();
  await expect(recordButton).toContainText("Stop Recording");

  await recordButton.click();
  await expect(recordButton).toContainText("Start Recording");
});

test("creates a recorded line after recording MIDI input during playback", async ({
  page,
}) => {
  const sendMidi = await setupMidiMock(page, {
    inputs: [{ id: "input-1", name: "Test Device" }],
  });
  const jazzene = await openPage({
    page,
    view: ["sheet", "pianoroll", "setting"],
  });

  // Wait for device option to appear — confirms requestMIDIAccess resolved
  const select = jazzene.getMidiDeviceSelect();
  await expect(
    select.getByRole("option", { name: "Test Device" }),
  ).toBeAttached();
  // Allow open().then() microtask to settle so the message handler is registered
  await page.waitForTimeout(100);

  // Start playback so playback_position advances
  await jazzene.play();
  await jazzene.waitForPlayback(200);

  // Start recording
  await jazzene.getRecordToggleButton().click();

  // Send note on, wait for position to advance, then send note off
  await sendMidi("input-1", NOTE_ON_C4);
  await jazzene.waitForPlayback(300);
  await sendMidi("input-1", NOTE_OFF_C4);

  // Stop recording — commits the non-empty buffer as a new RecordedLine
  await jazzene.getRecordToggleButton().click();

  await expect(jazzene.getRecordedLine(1)).toBeVisible();
});

test("can delete a recorded line", async ({ page }) => {
  const sendMidi = await setupMidiMock(page, {
    inputs: [{ id: "input-1", name: "Test Device" }],
  });
  const jazzene = await openPage({
    page,
    view: ["sheet", "pianoroll", "setting"],
  });

  const select = jazzene.getMidiDeviceSelect();
  await expect(
    select.getByRole("option", { name: "Test Device" }),
  ).toBeAttached();
  await page.waitForTimeout(100);

  await jazzene.play();
  await jazzene.waitForPlayback(200);

  await jazzene.getRecordToggleButton().click();
  await sendMidi("input-1", NOTE_ON_C4);
  await jazzene.waitForPlayback(300);
  await sendMidi("input-1", NOTE_OFF_C4);
  await jazzene.getRecordToggleButton().click();

  await expect(jazzene.getRecordedLine(1)).toBeVisible();

  await jazzene.getDeleteRecordedLineButton().click();
  await expect(jazzene.getRecordedLine(1)).not.toBeVisible();
});
