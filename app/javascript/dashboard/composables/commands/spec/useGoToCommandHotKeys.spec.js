import { useGoToCommandHotKeys } from '../useGoToCommandHotKeys';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { usePolicy } from 'dashboard/composables/usePolicy';
import { frontendURL } from 'dashboard/helper/URLHelper';
import { MOCK_FEATURE_FLAGS } from './fixtures';

vi.mock('dashboard/composables/store');
vi.mock('vue-i18n');
vi.mock('vue-router');
vi.mock('dashboard/composables/useAdmin');
vi.mock('dashboard/composables/usePolicy');
vi.mock('dashboard/helper/URLHelper');

const mockRoutes = [
  { path: 'accounts/:accountId/dashboard', name: 'dashboard' },
  {
    path: 'accounts/:accountId/contacts',
    name: 'contacts',
    featureFlag: MOCK_FEATURE_FLAGS.CRM,
  },
  { path: 'accounts/:accountId/profile/settings', name: 'profile_settings' },
  { path: 'accounts/:accountId/notifications', name: 'notifications' },
  {
    path: 'accounts/:accountId/reports/overview',
    name: 'reports_overview',
    featureFlag: MOCK_FEATURE_FLAGS.REPORTS,
  },
];

describe('useGoToCommandHotKeys', () => {
  let store;
  let routerPush;

  beforeEach(() => {
    store = {
      getters: {
        getCurrentAccountId: 1,
        'accounts/isFeatureEnabledonAccount': vi.fn().mockReturnValue(true),
      },
    };

    routerPush = vi.fn();
    useStore.mockReturnValue(store);
    useMapGetter.mockImplementation(key => ({
      value: store.getters[key],
    }));

    useI18n.mockReturnValue({ t: vi.fn(key => key) });
    useRouter.mockReturnValue({
      push: routerPush,
      getRoutes: vi.fn(() => []),
    });
    useAdmin.mockReturnValue({ isAdmin: { value: true } });
    usePolicy.mockReturnValue({ shouldShow: vi.fn(() => true) });
    frontendURL.mockImplementation(url => url);
  });

  it('should return goToCommandHotKeys computed property', () => {
    const { goToCommandHotKeys } = useGoToCommandHotKeys();
    expect(goToCommandHotKeys.value).toBeDefined();
    expect(goToCommandHotKeys.value.length).toBeGreaterThan(0);
  });

  it('indexes settings nav entries in the command bar', () => {
    const { goToCommandHotKeys } = useGoToCommandHotKeys();
    const ids = goToCommandHotKeys.value.map(cmd => cmd.id);

    expect(ids).toEqual(
      expect.arrayContaining([
        'open_settings_workspace',
        'open_settings_branding',
        'open_settings_custom_domain',
        'open_settings_billing',
        'open_settings_macros',
        'open_settings_sla',
        'open_settings_roles',
        'open_settings_security',
        'open_settings_audit_logs',
        'open_settings_webhooks',
        'open_settings_api_keys',
        'open_settings_reputation',
      ])
    );
  });

  it('should filter commands based on feature flags', () => {
    store.getters['accounts/isFeatureEnabledonAccount'] = vi.fn(
      (accountId, flag) => flag !== MOCK_FEATURE_FLAGS.CRM
    );
    const { goToCommandHotKeys } = useGoToCommandHotKeys();

    mockRoutes.forEach(route => {
      const command = goToCommandHotKeys.value.find(cmd =>
        cmd.id.includes(route.name)
      );
      if (route.featureFlag === MOCK_FEATURE_FLAGS.CRM) {
        expect(command).toBeUndefined();
      } else if (!route.featureFlag) {
        expect(command).toBeDefined();
      }
    });
  });

  it('should filter commands for non-admin users', () => {
    useAdmin.mockReturnValue({ isAdmin: { value: false } });
    const { goToCommandHotKeys } = useGoToCommandHotKeys();

    const adminOnlyCommands = goToCommandHotKeys.value.filter(cmd =>
      cmd.id.includes('reports')
    );
    expect(adminOnlyCommands.length).toBe(0);
  });

  it('should include commands for both admin and agent roles when user is admin', () => {
    const { goToCommandHotKeys } = useGoToCommandHotKeys();
    const adminCommand = goToCommandHotKeys.value.find(cmd =>
      cmd.id.includes('open_settings_agents')
    );
    const agentCommand = goToCommandHotKeys.value.find(cmd =>
      cmd.id.includes('profile_settings')
    );
    expect(adminCommand).toBeDefined();
    expect(agentCommand).toBeDefined();
  });

  it('should translate section and title for each command', () => {
    const { goToCommandHotKeys } = useGoToCommandHotKeys();
    goToCommandHotKeys.value.forEach(command => {
      expect(command.section).toBeDefined();
      expect(command.title).toBeDefined();
    });
  });

  it('should call router.push when handler is called', () => {
    const { goToCommandHotKeys } = useGoToCommandHotKeys();
    goToCommandHotKeys.value.forEach(command => {
      command.handler();
    });
    expect(routerPush).toHaveBeenCalled();
  });

  it('should use current account ID in the path', () => {
    store.getters.getCurrentAccountId = 42;
    const { goToCommandHotKeys } = useGoToCommandHotKeys();
    const dashboard = goToCommandHotKeys.value.find(
      cmd => cmd.id === 'goto_conversation_dashboard'
    );
    dashboard.handler();
    expect(routerPush).toHaveBeenCalledWith(expect.stringContaining('42'));
  });

  it('should include icon for each command', () => {
    const { goToCommandHotKeys } = useGoToCommandHotKeys();
    goToCommandHotKeys.value.forEach(command => {
      expect(command.icon).toBeDefined();
    });
  });

  it('should return commands for all enabled features', () => {
    const { goToCommandHotKeys } = useGoToCommandHotKeys();
    const enabledFeatureCommands = goToCommandHotKeys.value.filter(cmd =>
      mockRoutes.some(route => route.featureFlag && cmd.id.includes(route.name))
    );
    expect(enabledFeatureCommands.length).toBeGreaterThan(0);
  });

  it('should not return commands for disabled features', () => {
    store.getters['accounts/isFeatureEnabledonAccount'] = vi.fn(() => false);
    const { goToCommandHotKeys } = useGoToCommandHotKeys();
    const disabledFeatureCommands = goToCommandHotKeys.value.filter(cmd =>
      mockRoutes.some(route => route.featureFlag && cmd.id.includes(route.name))
    );
    expect(disabledFeatureCommands.length).toBe(0);
  });
});
