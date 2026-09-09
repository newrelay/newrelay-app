export const companyFieldValue = (company, property) => {
  const attrs = company.additionalAttributes || {};
  switch (property) {
    case 'name':
      return company.name || '';
    case 'industry':
      return attrs.industry || '';
    case 'contacts':
      return String(company.contactsCount || 0);
    case 'phone':
      return attrs.phone || '';
    case 'email':
      return attrs.email || '';
    case 'website':
      return attrs.website || company.domain || '';
    case 'owner':
      return attrs.owner || '';
    default:
      return '';
  }
};

export const matchesFilter = (company, filter) => {
  const field = String(companyFieldValue(company, filter.property))
    .toLowerCase()
    .trim();
  const value = String(filter.value || '')
    .toLowerCase()
    .trim();
  const present = field.length > 0;

  switch (filter.operator) {
    case 'not_equal':
      return field !== value;
    case 'contains':
      return field.includes(value);
    case 'does_not_contain':
      return !field.includes(value);
    case 'starts_with':
      return field.startsWith(value);
    case 'is_present':
      return present;
    case 'is_not_present':
      return !present;
    case 'equal':
    default:
      return field === value;
  }
};

export const filterCompaniesByConditions = (companies, filters) => {
  if (!filters.length) return companies;
  return companies.filter(company => {
    let result = matchesFilter(company, filters[0]);
    for (let i = 1; i < filters.length; i += 1) {
      const matches = matchesFilter(company, filters[i]);
      const combiner = filters[i - 1].queryOperator || 'and';
      result = combiner === 'or' ? result || matches : result && matches;
    }
    return result;
  });
};
