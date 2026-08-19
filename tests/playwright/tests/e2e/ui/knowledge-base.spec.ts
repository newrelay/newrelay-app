import { test, expect } from '@playwright/test';
import { Login, HelpCenter } from '@components/ui';

const TEST_EMAIL = process.env.TEST_USER_EMAIL || 'admin@chatwoot.com';
const TEST_PASSWORD = process.env.TEST_USER_PASSWORD || 'Password123@#';

test.describe('Knowledge Base', () => {
  let helpCenter: HelpCenter;

  test.beforeEach(async ({ page }) => {
    const login = new Login(page);
    await login.navigate();
    await login.login(TEST_EMAIL, TEST_PASSWORD);
    await expect(page).toHaveURL(/\/app\/accounts\/\d+\/dashboard/);

    helpCenter = new HelpCenter(page);
    await helpCenter.open();
  });

  test('creates a new category', async ({ page }) => {
    const name = `QA Category ${Date.now()}`;

    await helpCenter.gotoCategories();
    await helpCenter.createCategory(name);

    // Success toast confirms the category was persisted.
    await expect(
      page.getByText('Category created successfully')
    ).toBeVisible();
    // Dialog closes and the new category shows up in the list.
    await expect(
      page.getByRole('heading', { name: 'Create category' })
    ).toBeHidden();
    await expect(page.getByText(name)).toBeVisible();
  });

  test('saves portal settings', async ({ page }) => {
    await helpCenter.gotoSettings();

    const nameInput = helpCenter.portalNameInput();
    await expect(nameInput).toBeVisible();

    const newName = `QA Portal ${Date.now()}`;
    await nameInput.fill(newName);
    await helpCenter.saveChangesButton().click();

    // Success toast confirms settings persisted.
    await expect(page.getByText('Portal updated successfully')).toBeVisible();

    // Reload and confirm the change stuck — guards the "settings not saving" bug.
    await page.reload();
    await expect(helpCenter.portalNameInput()).toHaveValue(newName);
  });
});
