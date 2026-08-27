import { test } from '@playwright/test';
import path from 'path';
import { Login } from '../../../components/ui/login.component';

const SETTINGS_SECTIONS = [
  'profile',
  'reports',
  'settings/agent-bots',
  'settings/agents',
  'settings/assignment-policy',
  'settings/audit-logs',
  'settings/automation',
  'settings/billing',
  'settings/branding',
  'settings/canned-response',
  'settings/captain',
  'settings/conversation-workflow',
  'settings/custom-attributes',
  'settings/custom-domain',
  'settings/custom-roles',
  'settings/general',
  'settings/inboxes',
  'settings/integrations',
  'settings/labels',
  'settings/macros',
  'settings/notifications',
  'settings/security',
  'settings/sla',
  'settings/teams',
];

const OUT_DIR = path.resolve(__dirname, '../../../screenshots/settings');

test.use({ headless: true });

test.describe('Design audit: settings screenshots', () => {
  test('capture every settings section', async ({ page }) => {
    test.setTimeout(5 * 60 * 1000);

    const login = new Login(page);
    await page.goto('/', { waitUntil: 'domcontentloaded', timeout: 30000 });
    await login.login(
      process.env.TEST_USER_EMAIL as string,
      process.env.TEST_USER_PASSWORD as string
    );
    await page.waitForURL(/\/app\/accounts\/\d+/, { timeout: 30000 });

    const accountId = page.url().match(/\/accounts\/(\d+)/)?.[1];
    if (!accountId) throw new Error('Could not resolve accountId after login');

    for (const section of SETTINGS_SECTIONS) {
      const url = `/app/accounts/${accountId}/${section}`;
      await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 30000 });
      await page.waitForLoadState('networkidle', { timeout: 10000 }).catch(() => {});
      await page.waitForTimeout(500);
      const fileName = section.replace(/\//g, '__') + '.png';
      await page.screenshot({
        path: path.join(OUT_DIR, fileName),
        fullPage: true,
      });
    }
  });
});
