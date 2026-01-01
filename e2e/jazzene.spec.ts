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
    const fallingNotesContainer = page.locator(".falling-notes-container");
    await expect(fallingNotesContainer).toBeVisible();

    // Check that we have 2 bordered sections: Lead sheet and notes+keyboard
    const sections = page.locator(".border-2");
    await expect(sections).toHaveCount(2); // Lead sheet, notes+keyboard (connected)
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

    // Stop button should be enabled and red
    const stopButton = page.getByRole("button", { name: "Stop" });
    await expect(stopButton).toBeEnabled();
    await expect(stopButton).toHaveClass(/bg-red-600/);
  });

  test("should have professional dark theme styling", async ({ page }) => {
    // Check gradient background
    const appContainer = page.locator(".h-screen");
    await expect(appContainer).toHaveClass(/bg-gradient-to-br/);
    await expect(appContainer).toHaveClass(/from-slate-950/);
    await expect(appContainer).toHaveClass(/to-slate-900/);

    // Check lead sheet card styling
    const leadSheet = page.locator(".lead-sheet");
    await expect(leadSheet).toHaveClass(/bg-slate-800/);
    await expect(leadSheet).toHaveClass(/rounded-xl/);
    await expect(leadSheet).toHaveClass(/shadow-2xl/);
    await expect(leadSheet).toHaveClass(/border-2/);
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
    // seek_bar should be visible (has w-full class, unlike volume slider which has flex-1)
    const seek_bar = page.locator('input[type="range"].w-full');
    await expect(seek_bar).toBeVisible();

    // Time display container should show time
    const timeDisplay = page.locator(".flex.justify-between.text-slate-400");
    await expect(timeDisplay).toBeVisible();
  });

  test("should enable seek_bar after auto-generating notes", async ({
    page,
  }) => {
    const seek_bar = page.locator('input[type="range"].w-full');

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
    const timeDisplay = page.locator(".flex.justify-between.text-slate-400");
    const totalTime = await timeDisplay.textContent();
    expect(totalTime).not.toContain("0:00 / 0:00"); // Should not be initial state
  });

  test("should allow seeking with seek_bar", async ({ page }) => {
    const seek_bar = page.locator('input[type="range"].w-full');

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
    const seek_bar = page.locator('input[type="range"].w-full');

    // Move seek_bar while stopped
    await seek_bar.fill("25");

    // Falling notes should be visible (preview mode)
    const fallingNotesContainer = page.locator(".falling-notes-container");
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
    const timeDisplay = page.locator(".flex.justify-between.text-slate-400");
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
});
