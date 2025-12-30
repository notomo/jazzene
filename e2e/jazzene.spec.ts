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
    await expect(
      page.getByRole("button", { name: "Generate Improvisation" }),
    ).toBeVisible();
    // Play/Pause button should be visible (starts as "Play")
    await expect(
      page.getByRole("button", { name: /Play|Pause|Resume/ }),
    ).toBeVisible();

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

  test("should generate improvisation on button click", async ({ page }) => {
    const generateButton = page.getByRole("button", {
      name: "Generate Improvisation",
    });

    // Click generate button
    await generateButton.click();

    // The application should generate notes (internal state change)
    // We can verify this by checking if Play button remains enabled
    const playButton = page.getByRole("button", { name: "Play" });
    await expect(playButton).toBeEnabled();
  });

  test("should show play/pause button state changes", async ({ page }) => {
    const generateButton = page.getByRole("button", {
      name: "Generate Improvisation",
    });
    const playButton = page.getByRole("button", { name: "Play" });

    // Generate notes first
    await generateButton.click();

    // Click play button
    await playButton.click();

    // Button should change to "Pause" state
    await expect(page.getByRole("button", { name: "Pause" })).toBeVisible();

    // Click pause button
    await page.getByRole("button", { name: "Pause" }).click();

    // Button should change to "Resume" state
    await expect(page.getByRole("button", { name: "Resume" })).toBeVisible();
  });

  test("should allow pausing during playback", async ({ page }) => {
    const generateButton = page.getByRole("button", {
      name: "Generate Improvisation",
    });

    // Generate notes first
    await generateButton.click();

    // Start playback
    await page.getByRole("button", { name: "Play" }).click();

    // Pause button should be enabled and yellow
    const pauseButton = page.getByRole("button", { name: "Pause" });
    await expect(pauseButton).toBeEnabled();
    await expect(pauseButton).toHaveClass(/bg-yellow-600/);
  });

  test("should have professional dark theme styling", async ({ page }) => {
    // Check gradient background
    const body = page.locator("body");
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

  test("should generate different progressions correctly", async ({ page }) => {
    const input = page.getByPlaceholder(/Enter chord progression/);
    const generateButton = page.getByRole("button", {
      name: "Generate Improvisation",
    });

    // Test with simple progression
    await input.clear();
    await input.fill("Cmaj7 Am7 Dm7 G7");
    await generateButton.click();

    // Should be able to play
    const playButton = page.getByRole("button", { name: "Play" });
    await expect(playButton).toBeEnabled();
  });

  test("should handle empty chord progression gracefully", async ({ page }) => {
    const input = page.getByPlaceholder(/Enter chord progression/);
    const generateButton = page.getByRole("button", {
      name: "Generate Improvisation",
    });

    // Clear input
    await input.clear();
    await generateButton.click();

    // Play button should still be present (even if no notes generated)
    const playButton = page.getByRole("button", { name: "Play" });
    await expect(playButton).toBeVisible();
  });

  test("should display seekbar with time display", async ({ page }) => {
    // Seekbar should be visible (has w-full class, unlike volume slider which has flex-1)
    const seekbar = page.locator('input[type="range"].w-full');
    await expect(seekbar).toBeVisible();

    // Time display container should show 0:00 / 0:00 initially
    const timeDisplay = page.locator(".flex.justify-between.text-slate-400");
    await expect(timeDisplay).toContainText("0:00");
  });

  test("should disable seekbar when no notes generated", async ({ page }) => {
    const seekbar = page.locator('input[type="range"].w-full');

    // Seekbar should be disabled initially (no notes)
    await expect(seekbar).toBeDisabled();
  });

  test("should enable seekbar after generating notes", async ({ page }) => {
    const generateButton = page.getByRole("button", {
      name: "Generate Improvisation",
    });
    const seekbar = page.locator('input[type="range"].w-full');

    // Generate notes
    await generateButton.click();

    // Seekbar should now be enabled
    await expect(seekbar).toBeEnabled();
  });

  test("should update time display during playback", async ({ page }) => {
    const generateButton = page.getByRole("button", {
      name: "Generate Improvisation",
    });
    const playButton = page.getByRole("button", { name: "Play" });

    // Generate and play
    await generateButton.click();
    await playButton.click();

    // Wait a bit for playback to start
    await page.waitForTimeout(1000);

    // Total duration should be greater than 0:00
    const timeDisplay = page.locator(".flex.justify-between.text-slate-400");
    const totalTime = await timeDisplay.textContent();
    expect(totalTime).not.toContain("0:00 / 0:00"); // Should not be initial state
  });

  test("should allow seeking with seekbar", async ({ page }) => {
    const generateButton = page.getByRole("button", {
      name: "Generate Improvisation",
    });
    const seekbar = page.locator('input[type="range"].w-full');

    // Generate notes
    await generateButton.click();

    // Seekbar should be enabled
    await expect(seekbar).toBeEnabled();

    // Should be able to move seekbar to middle
    await seekbar.fill("50");

    // Verify seekbar value was updated
    const value = await seekbar.inputValue();
    expect(value).toBe("50");
  });
});
