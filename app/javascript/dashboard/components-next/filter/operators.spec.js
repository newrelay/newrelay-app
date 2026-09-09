import { useOperators } from './operators';

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

describe('useOperators', () => {
  it('includes is_present and is_not_present in containmentOperators', () => {
    const { containmentOperators } = useOperators();
    const values = containmentOperators.value.map(op => op.value);

    expect(values).toEqual([
      'equal_to',
      'not_equal_to',
      'contains',
      'does_not_contain',
      'is_present',
      'is_not_present',
    ]);
  });

  it('marks is_present and is_not_present as not requiring input', () => {
    const { operators } = useOperators();

    expect(operators.value.is_present.hasInput).toBe(false);
    expect(operators.value.is_not_present.hasInput).toBe(false);
  });

  it('still requires input for contains and does_not_contain', () => {
    const { operators } = useOperators();

    expect(operators.value.contains.hasInput).toBe(true);
    expect(operators.value.does_not_contain.hasInput).toBe(true);
  });
});
