import { mount } from '@vue/test-utils';
import CompanyHeader from './CompanyHeader.vue';

const SlotStub = { template: '<div><slot /></div>' };

const mountHeader = props =>
  mount(CompanyHeader, {
    props: {
      headerTitle: 'Companies',
      ...props,
    },
    global: {
      stubs: {
        RelayButton: SlotStub,
        RelayBadge: SlotStub,
        RelayInput: true,
        Popover: SlotStub,
        CompanyColumnManager: true,
      },
    },
  });

const filter = overrides => ({
  id: 1,
  property: 'name',
  operator: 'equal',
  value: 'Acme',
  ...overrides,
});

describe('CompanyHeader filter chips', () => {
  it.each([
    ['equal', 'is'],
    ['not_equal', 'is not'],
    ['contains', 'contains'],
    ['does_not_contain', 'does not contain'],
    ['starts_with', 'starts with'],
    ['is_present', 'is present'],
    ['is_not_present', 'is not present'],
  ])('renders the correct label for the %s operator', (operator, label) => {
    const wrapper = mountHeader({ activeFilters: [filter({ operator })] });
    expect(wrapper.text()).toContain(label);
  });

  it('falls back to the equal label for an unrecognized operator', () => {
    const wrapper = mountHeader({
      activeFilters: [filter({ operator: 'bogus' })],
    });
    expect(wrapper.text()).toContain('is');
  });

  it('shows the filter value for value-based operators', () => {
    const wrapper = mountHeader({
      activeFilters: [filter({ operator: 'contains', value: 'Acme' })],
    });
    expect(wrapper.text()).toContain('Acme');
  });

  it('hides the value for is_present and is_not_present chips', () => {
    const wrapper = mountHeader({
      activeFilters: [
        filter({ operator: 'is_present', value: 'should-not-render' }),
      ],
    });
    expect(wrapper.text()).not.toContain('should-not-render');
  });

  it('separates chips with AND when the previous filter combines with and', () => {
    const wrapper = mountHeader({
      activeFilters: [
        filter({ id: 1, queryOperator: 'and' }),
        filter({ id: 2, property: 'industry', value: 'Retail' }),
      ],
    });
    expect(wrapper.text()).toContain('AND');
    expect(wrapper.text()).not.toContain('OR');
  });

  it('separates chips with OR when the previous filter combines with or', () => {
    const wrapper = mountHeader({
      activeFilters: [
        filter({ id: 1, queryOperator: 'or' }),
        filter({ id: 2, property: 'industry', value: 'Retail' }),
      ],
    });
    expect(wrapper.text()).toContain('OR');
  });

  it('emits removeFilter with the chip index when its remove button is clicked', async () => {
    const wrapper = mountHeader({
      activeFilters: [filter({ id: 1 }), filter({ id: 2 })],
    });
    // chip remove buttons are the only ones carrying the "x" icon
    const removeButtons = wrapper
      .findAll('button')
      .filter(btn => btn.find('.i-lucide-x').exists());
    expect(removeButtons).toHaveLength(2);

    await removeButtons[0].trigger('click');
    expect(wrapper.emitted('removeFilter')[0]).toEqual([0]);
  });
});
