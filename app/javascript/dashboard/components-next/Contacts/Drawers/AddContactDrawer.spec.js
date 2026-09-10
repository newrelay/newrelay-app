import {
  mount,
  flushPromises,
  DOMWrapper,
  enableAutoUnmount,
} from '@vue/test-utils';
import AddContactDrawer from './AddContactDrawer.vue';
import CompanyAPI from 'dashboard/api/companies';

vi.mock('dashboard/api/companies', () => ({
  default: { search: vi.fn() },
}));

// AddContactDrawer renders under <Teleport to="body">, so its content lands
// in document.body rather than under the mounted wrapper's own root. The
// company field is a real reka-ui dropdown menu (stubbing it by component
// name doesn't take, same as elsewhere in this codebase's specs), so tests
// drive it for real: click the trigger to open it before finding its content.
enableAutoUnmount(afterEach);

const storeGettersStub = new Proxy({}, { get: () => [] });

const mountDrawer = () =>
  mount(AddContactDrawer, {
    global: { mocks: { $store: { getters: storeGettersStub } } },
  });

const bodyText = () => document.body.textContent;

const find = selector => {
  const el = document.body.querySelector(selector);
  return el ? new DOMWrapper(el) : undefined;
};

const findAll = selector =>
  Array.from(document.body.querySelectorAll(selector)).map(
    el => new DOMWrapper(el)
  );

const findButtonByText = text =>
  findAll('button').find(btn => btn.text().includes(text));

const findMenuItemByText = text =>
  findAll('[role="menuitem"]').find(item => item.text().includes(text));

const openCompanyDropdown = async () => {
  await findButtonByText('Search existing company...').trigger('click');
};

describe('AddContactDrawer company field', () => {
  beforeEach(() => {
    CompanyAPI.search.mockResolvedValue({
      data: { payload: [{ id: 5, name: 'Acme Inc' }] },
    });
  });

  it('searches companies as the user types and lists results', async () => {
    mountDrawer().vm.open();
    await flushPromises();
    await openCompanyDropdown();

    await find('input[placeholder="Type to search..."]').setValue('Acme');
    await new Promise(resolve => {
      setTimeout(resolve, 350);
    });
    await flushPromises();

    expect(CompanyAPI.search).toHaveBeenCalledWith('Acme');
    expect(bodyText()).toContain('Acme Inc');
  });

  it('selects a company and includes its id when creating the contact', async () => {
    const wrapper = mountDrawer();
    wrapper.vm.open();
    await flushPromises();
    await openCompanyDropdown();

    await find('input[placeholder="Type to search..."]').setValue('Acme');
    await new Promise(resolve => {
      setTimeout(resolve, 350);
    });
    await flushPromises();

    await findMenuItemByText('Acme Inc').trigger('click');
    expect(bodyText()).toContain('Acme Inc');

    const inputs = findAll('input[type="text"], input[type="email"]');
    await inputs[0].setValue('Jane');
    await inputs[1].setValue('Doe');
    await inputs[2].setValue('jane@doe.com');

    await findButtonByText('Create Contact').trigger('click');

    const emitted = wrapper.emitted('create');
    expect(emitted).toBeTruthy();
    expect(emitted[0][0]).toMatchObject({ companyId: 5 });
  });

  it('clears the selected company when the remove button is clicked', async () => {
    mountDrawer().vm.open();
    await flushPromises();
    await openCompanyDropdown();

    await find('input[placeholder="Type to search..."]').setValue('Acme');
    await new Promise(resolve => {
      setTimeout(resolve, 350);
    });
    await flushPromises();
    await findMenuItemByText('Acme Inc').trigger('click');
    expect(bodyText()).toContain('Acme Inc');

    await find('button[aria-label="Remove company"]').trigger('click');

    expect(bodyText()).not.toContain('Acme Inc');
  });

  it('prefills the selected company when editing an existing contact', async () => {
    mountDrawer().vm.open({
      id: 42,
      name: 'Jane Doe',
      email: 'jane@doe.com',
      company: { id: 5, name: 'Acme Inc' },
    });
    await flushPromises();

    expect(bodyText()).toContain('Acme Inc');
  });

  it('emits update with companyId null and the previous id when the company is removed', async () => {
    const wrapper = mountDrawer();
    wrapper.vm.open({
      id: 42,
      name: 'Jane Doe',
      email: 'jane@doe.com',
      company: { id: 5, name: 'Acme Inc' },
    });
    await flushPromises();

    await find('button[aria-label="Remove company"]').trigger('click');
    await findButtonByText('Update Contact').trigger('click');

    const emitted = wrapper.emitted('update');
    expect(emitted).toBeTruthy();
    expect(emitted[0][0]).toMatchObject({
      id: 42,
      companyId: null,
      previousCompanyId: 5,
    });
  });
});
