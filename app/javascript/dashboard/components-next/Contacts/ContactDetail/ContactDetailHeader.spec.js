import { mount } from '@vue/test-utils';
import { createRouter, createWebHistory } from 'vue-router';
import ContactDetailHeader from './ContactDetailHeader.vue';

vi.mock('dashboard/composables/usePolicy', () => ({
  usePolicy: () => ({ checkPermissions: () => false }),
}));

const SlotStub = { template: '<div><slot /></div>' };

const buildRouter = async () => {
  const router = createRouter({
    history: createWebHistory(),
    routes: [
      {
        path: '/accounts/:accountId',
        name: 'home',
        component: { template: '<div />' },
      },
      {
        path: '/accounts/:accountId/companies/:companyId',
        name: 'companies_dashboard_show',
        component: { template: '<div />' },
      },
    ],
  });
  router.push('/accounts/1');
  await router.isReady();
  return router;
};

const mountHeader = async contact => {
  const router = await buildRouter();
  return mount(ContactDetailHeader, {
    props: { contact },
    global: {
      plugins: [router],
      stubs: {
        RelayButton: SlotStub,
        RelayActionDropdown: SlotStub,
        ComposeConversation: SlotStub,
        Avatar: true,
      },
    },
  });
};

describe('ContactDetailHeader company display', () => {
  it('shows the real linked company name when present', async () => {
    const wrapper = await mountHeader({
      id: 1,
      name: 'Jane Doe',
      companyId: 9,
      company: { id: 9, name: 'Acme Inc' },
      additionalAttributes: { description: 'Manager', companyName: 'Stale Co' },
    });

    expect(wrapper.text()).toContain('Acme Inc');
    expect(wrapper.text()).not.toContain('Stale Co');
  });

  it('links to the company page when a real company is linked', async () => {
    const wrapper = await mountHeader({
      id: 1,
      name: 'Jane Doe',
      companyId: 9,
      company: { id: 9, name: 'Acme Inc' },
      additionalAttributes: { description: 'Manager' },
    });

    const link = wrapper.find('a');
    expect(link.exists()).toBe(true);
    expect(link.text()).toBe('Acme Inc');
  });

  it('falls back to the legacy free-text company name when no real link exists', async () => {
    const wrapper = await mountHeader({
      id: 1,
      name: 'Jane Doe',
      additionalAttributes: {
        description: 'Manager',
        companyName: 'Legacy Co',
      },
    });

    expect(wrapper.text()).toContain('Legacy Co');
    expect(wrapper.find('a').exists()).toBe(false);
  });

  it('shows nothing company-related when neither is present', async () => {
    const wrapper = await mountHeader({ id: 1, name: 'Jane Doe' });

    expect(wrapper.find('a').exists()).toBe(false);
  });
});
