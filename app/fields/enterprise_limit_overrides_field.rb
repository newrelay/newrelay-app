require 'administrate/field/base'

class EnterpriseLimitOverridesField < Administrate::Field::Base
  AVAILABLE_LIMITS = {
    'seats' => 'Seats (team members)',
    'contacts' => 'Contacts',
    'conversations' => 'Conversations/month',
    't3_subaccounts' => 'T3 reseller sub-accounts',
    'automations' => 'Automations/workflows',
    'captain_documents' => 'Captain AI documents',
    'captain_responses' => 'Captain AI credits (responses)/month',
    'data_retention_months' => 'Data retention (months)'
  }.freeze

  def self.permitted_attribute(attribute, _options = nil)
    { attribute => AVAILABLE_LIMITS.keys }
  end

  def available_limits
    AVAILABLE_LIMITS
  end

  def limit_value(key)
    (data || {})[key]
  end

  def to_s
    data
  end
end
