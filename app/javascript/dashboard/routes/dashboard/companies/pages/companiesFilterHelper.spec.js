import {
  companyFieldValue,
  matchesFilter,
  filterCompaniesByConditions,
} from './companiesFilterHelper';

const buildCompany = overrides => ({
  name: 'Acme Inc',
  contactsCount: 3,
  domain: 'acme.com',
  additionalAttributes: {
    industry: 'Retail',
    phone: '+1 555 0100',
    email: 'hello@acme.com',
    website: 'https://acme.com',
    owner: 'Jane Doe',
  },
  ...overrides,
});

describe('companyFieldValue', () => {
  it('reads name directly off the company', () => {
    expect(companyFieldValue(buildCompany({ name: 'Globex' }), 'name')).toBe(
      'Globex'
    );
  });

  it('reads industry from additionalAttributes', () => {
    expect(companyFieldValue(buildCompany(), 'industry')).toBe('Retail');
  });

  it('stringifies contactsCount for the contacts property', () => {
    expect(
      companyFieldValue(buildCompany({ contactsCount: 7 }), 'contacts')
    ).toBe('7');
  });

  it('falls back to domain when website attribute is missing', () => {
    const company = buildCompany({
      additionalAttributes: { website: '' },
      domain: 'fallback.com',
    });
    expect(companyFieldValue(company, 'website')).toBe('fallback.com');
  });

  it('returns empty string for unknown properties', () => {
    expect(companyFieldValue(buildCompany(), 'unknown')).toBe('');
  });

  it('returns empty string when the attribute is missing entirely', () => {
    expect(
      companyFieldValue(buildCompany({ additionalAttributes: {} }), 'owner')
    ).toBe('');
  });
});

describe('matchesFilter', () => {
  const company = buildCompany({ name: 'Acme Inc' });

  it('equal matches case-insensitively and trims whitespace', () => {
    expect(
      matchesFilter(company, {
        property: 'name',
        operator: 'equal',
        value: '  ACME INC  ',
      })
    ).toBe(true);
    expect(
      matchesFilter(company, {
        property: 'name',
        operator: 'equal',
        value: 'Other',
      })
    ).toBe(false);
  });

  it('not_equal excludes an exact match and includes everything else', () => {
    expect(
      matchesFilter(company, {
        property: 'name',
        operator: 'not_equal',
        value: 'Acme Inc',
      })
    ).toBe(false);
    expect(
      matchesFilter(company, {
        property: 'name',
        operator: 'not_equal',
        value: 'Other',
      })
    ).toBe(true);
  });

  it('contains matches a substring anywhere in the field', () => {
    expect(
      matchesFilter(company, {
        property: 'name',
        operator: 'contains',
        value: 'cme',
      })
    ).toBe(true);
    expect(
      matchesFilter(company, {
        property: 'name',
        operator: 'contains',
        value: 'zzz',
      })
    ).toBe(false);
  });

  it('does_not_contain excludes a substring match', () => {
    expect(
      matchesFilter(company, {
        property: 'name',
        operator: 'does_not_contain',
        value: 'cme',
      })
    ).toBe(false);
    expect(
      matchesFilter(company, {
        property: 'name',
        operator: 'does_not_contain',
        value: 'zzz',
      })
    ).toBe(true);
  });

  it('starts_with matches a prefix but not a mid-string occurrence', () => {
    expect(
      matchesFilter(company, {
        property: 'name',
        operator: 'starts_with',
        value: 'acme',
      })
    ).toBe(true);
    expect(
      matchesFilter(company, {
        property: 'name',
        operator: 'starts_with',
        value: 'cme',
      })
    ).toBe(false);
  });

  it('is_present is true for a non-empty field and false for an empty one', () => {
    expect(
      matchesFilter(company, { property: 'owner', operator: 'is_present' })
    ).toBe(true);
    expect(
      matchesFilter(buildCompany({ additionalAttributes: {} }), {
        property: 'owner',
        operator: 'is_present',
      })
    ).toBe(false);
  });

  it('is_not_present is the inverse of is_present', () => {
    expect(
      matchesFilter(company, { property: 'owner', operator: 'is_not_present' })
    ).toBe(false);
    expect(
      matchesFilter(buildCompany({ additionalAttributes: {} }), {
        property: 'owner',
        operator: 'is_not_present',
      })
    ).toBe(true);
  });

  it('falls back to equal semantics for an unknown operator', () => {
    expect(
      matchesFilter(company, {
        property: 'name',
        operator: 'bogus',
        value: 'Acme Inc',
      })
    ).toBe(true);
  });
});

describe('filterCompaniesByConditions', () => {
  const acme = buildCompany({
    name: 'Acme Inc',
    additionalAttributes: { industry: 'Retail' },
  });
  const globex = buildCompany({
    name: 'Globex Corp',
    additionalAttributes: { industry: 'Tech' },
  });
  const companies = [acme, globex];

  it('returns every company when there are no filters', () => {
    expect(filterCompaniesByConditions(companies, [])).toEqual(companies);
  });

  it('ANDs adjacent filters together by default', () => {
    const result = filterCompaniesByConditions(companies, [
      {
        property: 'name',
        operator: 'contains',
        value: 'Acme',
        queryOperator: 'and',
      },
      { property: 'industry', operator: 'equal', value: 'Retail' },
    ]);
    expect(result).toEqual([acme]);
  });

  it('ANDs a contradictory pair down to zero results', () => {
    const result = filterCompaniesByConditions(companies, [
      {
        property: 'name',
        operator: 'contains',
        value: 'Acme',
        queryOperator: 'and',
      },
      { property: 'industry', operator: 'equal', value: 'Tech' },
    ]);
    expect(result).toEqual([]);
  });

  it('ORs adjacent filters when queryOperator is or', () => {
    const result = filterCompaniesByConditions(companies, [
      {
        property: 'name',
        operator: 'equal',
        value: 'Acme Inc',
        queryOperator: 'or',
      },
      { property: 'name', operator: 'equal', value: 'Globex Corp' },
    ]);
    expect(result).toEqual([acme, globex]);
  });

  it('evaluates a mix of AND/OR left-to-right across three filters', () => {
    // (name contains "Acme") OR (name contains "Globex" AND industry = "Retail")
    // -> Globex fails the second clause, only Acme should match.
    const result = filterCompaniesByConditions(companies, [
      {
        property: 'name',
        operator: 'contains',
        value: 'Acme',
        queryOperator: 'or',
      },
      {
        property: 'name',
        operator: 'contains',
        value: 'Globex',
        queryOperator: 'and',
      },
      { property: 'industry', operator: 'equal', value: 'Retail' },
    ]);
    expect(result).toEqual([acme]);
  });

  it('defaults a missing queryOperator on a filter to and', () => {
    const result = filterCompaniesByConditions(companies, [
      { property: 'name', operator: 'contains', value: 'Acme' },
      { property: 'industry', operator: 'equal', value: 'Tech' },
    ]);
    expect(result).toEqual([]);
  });
});
