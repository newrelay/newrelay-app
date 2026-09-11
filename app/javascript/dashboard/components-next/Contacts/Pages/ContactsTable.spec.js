import { mount } from '@vue/test-utils';
import { createRouter, createWebHistory } from 'vue-router';
import ContactsTable from './ContactsTable.vue';

const storeGettersStub = new Proxy(
  {},
  {
    get: () => undefined,
  }
);

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
        path: '/accounts/:accountId/contacts/:contactId',
        name: 'contacts_edit',
        component: { template: '<div />' },
      },
    ],
  });
  router.push('/accounts/1');
  await router.isReady();
  return router;
};

const mountTable = async contacts => {
  const router = await buildRouter();
  return mount(ContactsTable, {
    props: { contacts, visibleColumns: ['company'] },
    global: {
      plugins: [router],
      mocks: { $store: { getters: storeGettersStub } },
      stubs: {
        Avatar: true,
        RelayButton: true,
        RelayCheckbox: true,
        ComposeConversation: true,
      },
    },
  });
};

describe('ContactsTable select all checkbox', () => {
  it('emits toggleAll false when the header checkbox is clicked while every row is selected', async () => {
    const router = await buildRouter();
    const wrapper = mount(ContactsTable, {
      props: {
        contacts: [
          { id: 1, name: 'Ada' },
          { id: 2, name: 'Grace' },
        ],
        selectedContactIds: [1, 2],
        visibleColumns: ['company'],
      },
      global: {
        plugins: [router],
        mocks: { $store: { getters: storeGettersStub } },
        stubs: {
          Avatar: true,
          RelayButton: true,
          ComposeConversation: true,
        },
      },
    });

    const headerCheckbox = wrapper.get('thead [role="checkbox"]');
    expect(headerCheckbox.attributes('aria-checked')).toBe('true');
    await headerCheckbox.trigger('click');

    expect(wrapper.emitted('toggleAll')).toEqual([[false]]);
  });
});

describe('ContactsTable company column', () => {
  it('shows the real linked company name when present', async () => {
    const wrapper = await mountTable([
      {
        id: 1,
        name: 'Jane Doe',
        company: { id: 9, name: 'Acme Inc' },
        additionalAttributes: { companyName: 'Stale Co' },
      },
    ]);

    expect(wrapper.text()).toContain('Acme Inc');
    expect(wrapper.text()).not.toContain('Stale Co');
  });

  it('falls back to the legacy free-text company name when no real link exists', async () => {
    const wrapper = await mountTable([
      {
        id: 1,
        name: 'Jane Doe',
        additionalAttributes: { companyName: 'Legacy Co' },
      },
    ]);

    expect(wrapper.text()).toContain('Legacy Co');
  });

  it('shows a placeholder when neither is present', async () => {
    const wrapper = await mountTable([{ id: 1, name: 'Jane Doe' }]);

    expect(wrapper.text()).toContain('—');
  });
});
