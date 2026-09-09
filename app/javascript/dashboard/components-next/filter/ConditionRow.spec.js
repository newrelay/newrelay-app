import { mount } from '@vue/test-utils';
import ConditionRow from './ConditionRow.vue';

const FilterSelectStub = {
  props: ['options'],
  template: '<div><slot name="trigger" :toggle="() => {}" /></div>',
};

const buildFilterTypes = operator => [
  {
    attributeKey: 'name',
    label: 'Name',
    inputType: 'plainText',
    filterOperators: [
      { value: 'equal_to', label: 'Equal to', hasInput: true },
      { value: 'not_equal_to', label: 'Not equal to', hasInput: true },
      { value: 'contains', label: 'Contains', hasInput: true },
      { value: 'does_not_contain', label: 'Does not contain', hasInput: true },
      operator,
    ],
  },
];

const mountConditionRow = ({ filterOperator, extraOperator } = {}) =>
  mount(ConditionRow, {
    props: {
      stacked: true,
      filterTypes: buildFilterTypes(
        extraOperator || {
          value: filterOperator,
          label: filterOperator,
          hasInput: true,
        }
      ),
      attributeKey: 'name',
      values: '',
      filterOperator,
    },
    global: {
      stubs: {
        FilterSelect: FilterSelectStub,
        RelayButton: true,
        RelayInput: true,
      },
    },
  });

describe('ConditionRow stackedOperatorLabel', () => {
  it('prefixes the contains label with the ⊃ symbol', () => {
    const wrapper = mountConditionRow({ filterOperator: 'contains' });
    expect(wrapper.text()).toContain('⊃ Contains');
  });

  it('prefixes the does_not_contain label with the ⊅ symbol', () => {
    const wrapper = mountConditionRow({ filterOperator: 'does_not_contain' });
    expect(wrapper.text()).toContain('⊅ Does not contain');
  });

  it('keeps the existing equal_to / not_equal_to symbols working', () => {
    const equalWrapper = mountConditionRow({ filterOperator: 'equal_to' });
    expect(equalWrapper.text()).toContain('= Equal to');

    const notEqualWrapper = mountConditionRow({
      filterOperator: 'not_equal_to',
    });
    expect(notEqualWrapper.text()).toContain('≠ Not equal to');
  });

  it('falls back to the plain label when the operator has no symbol mapping', () => {
    const wrapper = mountConditionRow({
      filterOperator: 'starts_with',
      extraOperator: {
        value: 'starts_with',
        label: 'Starts with',
        hasInput: true,
      },
    });
    expect(wrapper.text()).toContain('Starts with');
    expect(wrapper.text()).not.toContain('⊃');
    expect(wrapper.text()).not.toContain('⊅');
  });
});
