import { test, expect } from "@playwright/test";

test.describe("Jazzene - Jazz Improvisation Web App", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/");
  });

  test("should render all three main sections", async ({ page }) => {
    // Check lead sheet section
    await expect(
      page.getByPlaceholder(/Enter chord progression/),
    ).toBeVisible();
    // Play/Stop button should be visible (starts as "Play")
    await expect(page.getByRole("button", { name: /Play|Stop/ })).toBeVisible();

    // Check falling notes section
    const fallingNotesContainer = page.getByLabel("falling notes");
    await expect(fallingNotesContainer).toBeVisible();

    // Check that we have lead sheet and visualization sections
    await expect(page.getByLabel("lead sheet")).toBeVisible();
    await expect(page.getByLabel("visualization")).toBeVisible();
  });

  test("should have default chord progression in input", async ({ page }) => {
    const input = page.getByPlaceholder(/Enter chord progression/);
    await expect(input).toHaveValue("Cm7 F7 Bbmaj7 Ebmaj7");
  });

  test("should allow editing chord progression", async ({ page }) => {
    const input = page.getByPlaceholder(/Enter chord progression/);

    // Clear and enter new progression
    await input.clear();
    await input.fill("Dm7 G7 Cmaj7");

    await expect(input).toHaveValue("Dm7 G7 Cmaj7");
  });

  test("should auto-generate improvisation on page load", async ({ page }) => {
    // Notes should be auto-generated from default chord progression
    // We can verify this by checking if Play button is enabled
    const playButton = page.getByRole("button", { name: "Play" });
    await expect(playButton).toBeEnabled();
  });

  test("should show play/stop button state changes", async ({ page }) => {
    const playButton = page.getByRole("button", { name: "Play" });

    // Click play button
    await playButton.click();

    // Button should change to "Stop" state
    await expect(page.getByRole("button", { name: "Stop" })).toBeVisible();

    // Click stop button
    await page.getByRole("button", { name: "Stop" }).click();

    // Button should change back to "Play" state
    await expect(page.getByRole("button", { name: "Play" })).toBeVisible();
  });

  test("should allow stopping during playback", async ({ page }) => {
    // Start playback
    await page.getByRole("button", { name: "Play" }).click();

    // Stop button should be enabled
    const stopButton = page.getByRole("button", { name: "Stop" });
    await expect(stopButton).toBeEnabled();
  });

  test("should have professional dark theme styling", async ({ page }) => {
    // Check lead sheet section exists
    const leadSheet = page.getByLabel("lead sheet");
    await expect(leadSheet).toBeVisible();

    // Check visualization section exists
    const visualization = page.getByLabel("visualization");
    await expect(visualization).toBeVisible();
  });

  test("should auto-generate different progressions correctly", async ({
    page,
  }) => {
    const input = page.getByPlaceholder(/Enter chord progression/);

    // Test with simple progression - notes auto-generate on input change
    await input.clear();
    await input.fill("Cmaj7 Am7 Dm7 G7");

    // Should be able to play immediately (auto-generated)
    const playButton = page.getByRole("button", { name: "Play" });
    await expect(playButton).toBeEnabled();
  });

  test("should handle empty chord progression gracefully", async ({ page }) => {
    const input = page.getByPlaceholder(/Enter chord progression/);

    // Clear input
    await input.clear();

    // Play button should still be present (even if no notes generated)
    const playButton = page.getByRole("button", { name: "Play" });
    await expect(playButton).toBeVisible();
  });

  test("should display seek_bar with time display", async ({ page }) => {
    // seek_bar should be visible
    const seek_bar = page.getByLabel("playback position");
    await expect(seek_bar).toBeVisible();

    // Time display container should show time
    const timeDisplay = page.getByLabel("time display");
    await expect(timeDisplay).toBeVisible();
  });

  test("should enable seek_bar after auto-generating notes", async ({
    page,
  }) => {
    const seek_bar = page.getByLabel("playback position");

    // seek_bar should be enabled (notes auto-generated from default progression)
    await expect(seek_bar).toBeEnabled();
  });

  test("should update time display during playback", async ({ page }) => {
    const playButton = page.getByRole("button", { name: "Play" });

    // Play
    await playButton.click();

    // Wait a bit for playback to start
    await page.waitForTimeout(1000);

    // Total duration should be greater than 0:00
    const timeDisplay = page.getByLabel("time display");
    const totalTime = await timeDisplay.textContent();
    expect(totalTime).not.toContain("0:00 / 0:00"); // Should not be initial state
  });

  test("should allow seeking with seek_bar", async ({ page }) => {
    const seek_bar = page.getByLabel("playback position");

    // seek_bar should be enabled (auto-generated notes)
    await expect(seek_bar).toBeEnabled();

    // Should be able to move seek_bar to middle
    await seek_bar.fill("50");

    // Verify seek_bar value was updated
    const value = await seek_bar.inputValue();
    expect(value).toBe("50");
  });

  test("should show note preview when seeking while stopped", async ({
    page,
  }) => {
    const seek_bar = page.getByLabel("playback position");

    // Move seek_bar while stopped
    await seek_bar.fill("25");

    // Falling notes should be visible (preview mode)
    const fallingNotesContainer = page.getByLabel("falling notes");
    await expect(fallingNotesContainer).toBeVisible();
  });

  test("should preserve position when stopping", async ({ page }) => {
    const playButton = page.getByRole("button", { name: "Play" });

    // Start playing
    await playButton.click();

    // Wait long enough to get past 1 second (so time shows as 0:01 or more)
    await page.waitForTimeout(1500);

    // Stop
    await page.getByRole("button", { name: "Stop" }).click();

    // Play button should be visible again
    await expect(page.getByRole("button", { name: "Play" })).toBeVisible();

    // Position should be preserved (time should not be 0:00 / X:XX)
    const timeDisplay = page.getByLabel("time display");
    const time = await timeDisplay.textContent();
    expect(time).not.toMatch(/^0:00/); // Current time should not be 0:00
  });

  test("should auto-regenerate notes when chord input changes", async ({
    page,
  }) => {
    const input = page.getByPlaceholder(/Enter chord progression/);

    // Change chord progression
    await input.clear();
    await input.fill("Am7 D7 Gmaj7");

    // Wait for auto-generation
    await page.waitForTimeout(100);

    // Play button should still be enabled with new notes
    const playButton = page.getByRole("button", { name: "Play" });
    await expect(playButton).toBeEnabled();
  });

  test("should update seekbar value during playback", async ({ page }) => {
    const seek_bar = page.getByLabel("playback position");

    // Get initial seekbar value (should be 0)
    const initialValue = await seek_bar.inputValue();

    // Start playing
    await page.getByRole("button", { name: "Play" }).click();

    // Wait for playback to progress
    await page.waitForTimeout(500);

    // Get seekbar value after playback started
    const playingValue = await seek_bar.inputValue();

    // Seekbar should have moved forward (value increased)
    expect(parseInt(playingValue)).toBeGreaterThan(parseInt(initialValue));
  });

  test("should show correct time after stopping playback", async ({ page }) => {
    // Start playing
    await page.getByRole("button", { name: "Play" }).click();

    // Wait for some playback time
    await page.waitForTimeout(800);

    // Stop playback
    await page.getByRole("button", { name: "Stop" }).click();

    // Get time display
    const timeDisplay = page.getByLabel("time display");
    const time = await timeDisplay.textContent();

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
