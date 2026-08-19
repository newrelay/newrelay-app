class DataImport::CompanyManager
  DIRECT_KEYS = %w[name domain description].freeze
  ADDITIONAL_ATTRIBUTE_KEYS = %w[industry phone email website owner].freeze

  def initialize(account)
    @account = account
  end

  def build_company(params)
    company = find_or_initialize_company(params)
    assign_attributes(company, params)
    company
  end

  private

  def find_or_initialize_company(params)
    name = params[:name].to_s.strip
    domain = params[:domain].to_s.strip

    find_by_domain(domain) || find_by_name(name) || @account.companies.new(name: name)
  end

  def find_by_domain(domain)
    return if domain.blank?

    @account.companies.find_by(domain: domain)
  end

  def find_by_name(name)
    return if name.blank?

    @account.companies.find_by(name: name)
  end

  def assign_attributes(company, params)
    company.name = params[:name].to_s.strip if params[:name].present?
    company.domain = params[:domain].to_s.strip if params[:domain].present?
    company.description = params[:description] if params[:description].present?
    merge_jsonb_attributes(company, params)
  end

  def merge_jsonb_attributes(company, params)
    additional = params.slice(*ADDITIONAL_ATTRIBUTE_KEYS).compact_blank
    company.additional_attributes = company.additional_attributes.to_h.merge(additional) if additional.present?

    custom = params.except(*(DIRECT_KEYS + ADDITIONAL_ATTRIBUTE_KEYS)).compact_blank
    company.custom_attributes = company.custom_attributes.to_h.merge(custom) if custom.present?
  end
end
