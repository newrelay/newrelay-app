import { Page, expect } from '@playwright/test';

// Page object for the Knowledge Base (Help Center / Portals) section.
// The KB pages carry no data-testid, so selectors use the rendered
// i18n labels, placeholders, and toast messages from the app.
export class HelpCenter {
  private page: Page;

  accountId = '';
  portalSlug = '';
  locale = '';

  constructor(page: Page) {
    this.page = page;
  }

  // Reads accountId from the dashboard URL (must be logged in first),
  // opens the portal, and captures the active portalSlug + locale from
  // the redirect to the articles page.
  async open() {
    const accountMatch = this.page.url().match(/accounts\/(\d+)/);
    if (!accountMatch) {
      throw new Error(`Expected a logged-in dashboard URL, got: ${this.page.url()}`);
    }
    this.accountId = accountMatch[1];

    await this.page.goto(`/app/accounts/${this.accountId}/portals`);
    // portals_index redirects to <portalSlug>/<locale>/articles
    await this.page.waitForURL(/\/portals\/[^/]+\/[^/]+\//, { timeout: 30000 });

    const m = this.page.url().match(/\/portals\/([^/]+)\/([^/?#]+)/);
    if (!m) {
      throw new Error(
        `No portal found. Create a portal first. URL: ${this.page.url()}`
      );
    }
    [, this.portalSlug, this.locale] = m;
  }

  async gotoCategories() {
    await this.page.goto(
      `/app/accounts/${this.accountId}/portals/${this.portalSlug}/${this.locale}/categories`
    );
  }

  async gotoSettings() {
    await this.page.goto(
      `/app/accounts/${this.accountId}/portals/${this.portalSlug}/settings`
    );
  }

  // ----- Categories -----
  newCategoryButton() {
    return this.page.getByRole('button', { name: 'New category' });
  }

  categoryNameInput() {
    return this.page.getByPlaceholder('Category name');
  }

  createCategorySubmit() {
    return this.page.getByRole('button', { name: 'Create', exact: true });
  }

  async createCategory(name: string) {
    await this.newCategoryButton().click();
    await expect(
      this.page.getByRole('heading', { name: 'Create category' })
    ).toBeVisible();
    // Slug auto-fills from the name.
    await this.categoryNameInput().fill(name);
    await this.createCategorySubmit().click();
  }

  // ----- Settings -----
  portalNameInput() {
    return this.page.getByPlaceholder('Portal name');
  }

  saveChangesButton() {
    return this.page.getByRole('button', { name: 'Save changes' });
  }
}
