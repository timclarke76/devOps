import { test, expect } from '@playwright/test';

const APP_URL = process.env.APP_URL

test.describe('Vue App Tests', () => {

  test('should load the homepage and show correct title', async ({ page }) => {
    await page.goto(APP_URL);
    await expect(page).toHaveTitle(/Boardroom Collective/);
  });

  /*
  test('should register a new user and then login', async ({ page }) => {
    const randomId = Math.random().toString(36).substring(7);
    const email = `test-${randomId}@example.com`;
    const password = 'TestPassword123!';

    await page.goto(APP_URL);
    await page.getByRole('link', { name: /register/i }).click();
    await page.locator('input[placeholder="Enter your full name"]').fill("Playwright Test User");
    await page.locator('input[placeholder="Enter your email"]').fill(email);
    await page.locator('input[placeholder="Create a password"]').fill(password);
    await page.locator('input[placeholder="Confirm your password"]').fill(password);
    await page.getByRole('button', { name: /register/i }).click();
    await expect(page).toHaveURL(/\/login/);
    await page.locator('input[placeholder="Enter your email"]').fill(email);
    await page.locator('input[placeholder="Enter your password"]').fill(password);
    await page.getByRole('button', { name: /login/i }).click();

    const logoutBtn = page.getByRole('button', { class: /logout/i });
    await expect(logoutBtn).toBeVisible({ timeout: 10000 });
  });
  */
});
