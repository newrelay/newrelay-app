import { useContactFilterContext } from './contactProvider';
import { useMapGetter } from 'dashboard/composables/store.js';

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

vi.mock('dashboard/composables/store.js');

describe('useContactFilterContext', () => {
  beforeEach(() => {
    useMapGetter.mockImplementation(getter => {
      const getters = {
        'attributes/getContactAttributes': { value: [] },
        'labels/getLabels': { value: [] },
      };
      return getters[getter];
    });
  });

  it('exposes containment operators (not just equality) for the name filter', () => {
    const { filterTypes } = useContactFilterContext();
    const nameFilter = filterTypes.value.find(f => f.attributeKey === 'name');

    const operatorValues = nameFilter.filterOperators.map(op => op.value);
    expect(operatorValues).toContain('contains');
    expect(operatorValues).toContain('does_not_contain');
    expect(operatorValues.length).toBeGreaterThan(2);
  });
});
