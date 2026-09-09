import { mount, DOMWrapper, enableAutoUnmount } from '@vue/test-utils';
import CompanyFiltersDrawer from './CompanyFiltersDrawer.vue';

// CompanyFiltersDrawer renders under <Teleport to="body">, so its content
// lands in document.body rather than under the mounted wrapper's own root.
enableAutoUnmount(afterEach);

// The drawer only copies `activeFilters` into its internal draft state when
// `open` transitions from false -> true (a plain, non-immediate watcher), so
// tests mount closed and then open to reproduce how the real drawer is used.
const mountDrawer = async ({ activeFilters = [], ...props } = {}) => {
  const wrapper = mount(CompanyFiltersDrawer, {
    props: { open: false, activeFilters, ...props },
  });
  await wrapper.setProps({ open: true });
  return wrapper;
};

const findButtonByText = text => {
  const button = Array.from(document.body.querySelectorAll('button')).find(
    btn => btn.textContent.includes(text)
  );
  return button ? new DOMWrapper(button) : undefined;
};

describe('CompanyFiltersDrawer', () => {
  it('disables Apply when the current operator requires a value and none is set', async () => {
    await mountDrawer({
      activeFilters: [
        { id: 1, property: 'name', operator: 'equal', value: '' },
      ],
    });
    expect(
      findButtonByText('Apply filters').attributes('disabled')
    ).toBeDefined();
  });

  it('does not disable Apply for is_present even without a value', async () => {
    await mountDrawer({
      activeFilters: [
        { id: 1, property: 'name', operator: 'is_present', value: '' },
      ],
    });
    expect(
      findButtonByText('Apply filters').attributes('disabled')
    ).toBeUndefined();
  });

  it('enables Apply once a value is filled in for a value-based operator', async () => {
    await mountDrawer({
      activeFilters: [
        { id: 1, property: 'name', operator: 'equal', value: 'Acme' },
      ],
    });
    expect(
      findButtonByText('Apply filters').attributes('disabled')
    ).toBeUndefined();
  });

  it('backfills a missing queryOperator to "and" when the drawer opens with existing filters', async () => {
    await mountDrawer({
      activeFilters: [
        { id: 1, property: 'name', operator: 'equal', value: 'Acme' },
        { id: 2, property: 'industry', operator: 'equal', value: 'Retail' },
      ],
    });
    // the toggle button between the two conditions reflects the backfilled 'and'
    expect(findButtonByText('AND')).toBeTruthy();
  });

  it('toggles the combiner between AND and OR when its label is clicked', async () => {
    await mountDrawer({
      activeFilters: [
        {
          id: 1,
          property: 'name',
          operator: 'equal',
          value: 'Acme',
          queryOperator: 'and',
        },
        { id: 2, property: 'industry', operator: 'equal', value: 'Retail' },
      ],
    });

    const toggleButton = findButtonByText('AND');
    expect(toggleButton).toBeTruthy();

    await toggleButton.trigger('click');
    expect(findButtonByText('OR')).toBeTruthy();

    await findButtonByText('OR').trigger('click');
    expect(findButtonByText('AND')).toBeTruthy();
  });

  it('emits apply with trimmed values when Apply is clicked', async () => {
    const wrapper = await mountDrawer({
      activeFilters: [
        { id: 1, property: 'name', operator: 'equal', value: '  Acme  ' },
      ],
    });

    await findButtonByText('Apply filters').trigger('click');

    expect(wrapper.emitted('apply')[0][0]).toEqual([
      expect.objectContaining({ value: 'Acme', queryOperator: 'and' }),
    ]);
    expect(wrapper.emitted('update:open')[0]).toEqual([false]);
  });

  it('emits clear and resets to a single blank draft when Clear is clicked', async () => {
    const wrapper = await mountDrawer({
      activeFilters: [
        { id: 1, property: 'name', operator: 'equal', value: 'Acme' },
        { id: 2, property: 'industry', operator: 'equal', value: 'Retail' },
      ],
    });

    await findButtonByText('Clear filters').trigger('click');

    expect(wrapper.emitted('clear')).toBeTruthy();
    expect(wrapper.emitted('update:open')[0]).toEqual([false]);
  });
});
