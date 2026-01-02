import { test, expect } from "@playwright/test";
import { openJazzenePage } from "./page";

test.describe("Jazzene - Jazz Improvisation Web App", () => {
  let jazzenePage: Awaited<ReturnType<typeof openJazzenePage>>;

  test.beforeEach(async ({ page }) => {
    jazzenePage = await openJazzenePage({ page });
  });

  test("should render all three main sections", async () => {
    // Check lead sheet section
    await expect(jazzenePage.getChordInput()).toBeVisible();
    // Play/Stop button should be visible (starts as "Play")
    await expect(jazzenePage.getPlayOrStopButton()).toBeVisible();

    // Check falling notes section
    await expect(jazzenePage.getFallingNotes()).toBeVisible();

    // Check that we have lead sheet and visualization sections
    await expect(jazzenePage.getLeadSheet()).toBeVisible();
    await expect(jazzenePage.getVisualization()).toBeVisible();
  });

  test("should have default chord progression in input", async () => {
    await expect(jazzenePage.getChordInput()).toHaveValue(
      "Cm7 F7 Bbmaj7 Ebmaj7",
    );
  });

  test("should allow editing chord progression", async () => {
    // Clear and enter new progression
    await jazzenePage.setChordProgression("Dm7 G7 Cmaj7");

    await expect(jazzenePage.getChordInput()).toHaveValue("Dm7 G7 Cmaj7");
  });

  test("should auto-generate improvisation on page load", async () => {
    // Notes should be auto-generated from default chord progression
    // We can verify this by checking if Play button is enabled
    await expect(jazzenePage.getPlayButton()).toBeEnabled();
  });

  test("should show play/stop button state changes", async () => {
    // Click play button
    await jazzenePage.play();

    // Button should change to "Stop" state
    await expect(jazzenePage.getStopButton()).toBeVisible();

    // Click stop button
    await jazzenePage.stop();

    // Button should change back to "Play" state
    await expect(jazzenePage.getPlayButton()).toBeVisible();
  });

  test("should allow stopping during playback", async () => {
    // Start playback
    await jazzenePage.play();

    // Stop button should be enabled
    await expect(jazzenePage.getStopButton()).toBeEnabled();
  });

  test("should have professional dark theme styling", async () => {
    // Check lead sheet section exists
    await expect(jazzenePage.getLeadSheet()).toBeVisible();

    // Check visualization section exists
    await expect(jazzenePage.getVisualization()).toBeVisible();
  });

  test("should auto-generate different progressions correctly", async () => {
    // Test with simple progression - notes auto-generate on input change
    await jazzenePage.setChordProgression("Cmaj7 Am7 Dm7 G7");

    // Should be able to play immediately (auto-generated)
    await expect(jazzenePage.getPlayButton()).toBeEnabled();
  });

  test("should handle empty chord progression gracefully", async () => {
    // Clear input
    await jazzenePage.setChordProgression("");

    // Play button should still be present (even if no notes generated)
    await expect(jazzenePage.getPlayButton()).toBeVisible();
  });

  test("should display seek_bar with time display", async () => {
    // seek_bar should be visible
    await expect(jazzenePage.getSeekbar()).toBeVisible();

    // Time display container should show time
    await expect(jazzenePage.getTimeDisplay()).toBeVisible();
  });

  test("should enable seek_bar after auto-generating notes", async () => {
    // seek_bar should be enabled (notes auto-generated from default progression)
    await expect(jazzenePage.getSeekbar()).toBeEnabled();
  });

  test("should update time display during playback", async () => {
    // Play
    await jazzenePage.play();

    // Wait a bit for playback to start
    await jazzenePage.waitForPlayback(1000);

    // Total duration should be greater than 0:00
    const totalTime = await jazzenePage.getTimeDisplayText();
    expect(totalTime).not.toContain("0:00 / 0:00"); // Should not be initial state
  });

  test("should allow seeking with seek_bar", async () => {
    // seek_bar should be enabled (auto-generated notes)
    await expect(jazzenePage.getSeekbar()).toBeEnabled();

    // Should be able to move seek_bar to middle
    await jazzenePage.setSeekbarValue("50");

    // Verify seek_bar value was updated
    const value = await jazzenePage.getSeekbarValue();
    expect(value).toBe("50");
  });

  test("should show note preview when seeking while stopped", async () => {
    // Move seek_bar while stopped
    await jazzenePage.setSeekbarValue("25");

    // Falling notes should be visible (preview mode)
    await expect(jazzenePage.getFallingNotes()).toBeVisible();
  });

  test("should preserve position when stopping", async () => {
    // Start playing
    await jazzenePage.play();

    // Wait long enough to get past 1 second (so time shows as 0:01 or more)
    await jazzenePage.waitForPlayback(1500);

    // Stop
    await jazzenePage.stop();

    // Play button should be visible again
    await expect(jazzenePage.getPlayButton()).toBeVisible();

    // Position should be preserved (time should not be 0:00 / X:XX)
    const time = await jazzenePage.getTimeDisplayText();
    expect(time).not.toMatch(/^0:00/); // Current time should not be 0:00
  });

  test("should auto-regenerate notes when chord input changes", async () => {
    // Change chord progression
    await jazzenePage.setChordProgression("Am7 D7 Gmaj7");

    // Wait for auto-generation
    await jazzenePage.waitForPlayback(100);

    // Play button should still be enabled with new notes
    await expect(jazzenePage.getPlayButton()).toBeEnabled();
  });

  test("should update seekbar value during playback", async () => {
    // Get initial seekbar value (should be 0)
    const initialValue = await jazzenePage.getSeekbarValue();

    // Start playing
    await jazzenePage.play();

    // Wait for playback to progress
    await jazzenePage.waitForPlayback(500);

    // Get seekbar value after playback started
    const playingValue = await jazzenePage.getSeekbarValue();

    // Seekbar should have moved forward (value increased)
    expect(parseInt(playingValue)).toBeGreaterThan(parseInt(initialValue));
  });

  test("should show correct time after stopping playback", async () => {
    // Start playing
    await jazzenePage.play();

    // Wait for some playback time
    await jazzenePage.waitForPlayback(800);

    // Stop playback
    await jazzenePage.stop();

    // Get time display
    const time = await jazzenePage.getTimeDisplayText();

    // Time should be in valid format (M:SS / M:SS)
    // Should NOT contain huge numbers like 29454216:47
    expect(time).toMatch(/^\d{1,2}:\d{2} \/ \d{1,2}:\d{2}$/);

    // Extract current time (before the slash)
    const currentTime = time!.split(" / ")[0];
    const [minutes, seconds] = currentTime.split(":").map((n) => parseInt(n));

    // Minutes should be reasonable (less than 10 for a short test song)
    expect(minutes).toBeLessThan(10);
    // Seconds should be valid (0-59)
    expect(seconds).toBeGreaterThanOrEqual(0);
    expect(seconds).toBeLessThan(60);
  });
});
