# Persists enterprise inquiry changes on the account JSONB column without going
# through Account#custom_attributes, which merges parent attributes for child accounts.
module Enterprise::Billing::EnterpriseInquiryAttributes
  module_function

  def stored_custom_attributes(account)
    account.read_attribute(:custom_attributes) || {}
  end

  def update_stored_custom_attributes!(account, attrs)
    account.update_column(:custom_attributes, attrs)
  end

  def enterprise_inquiry(account)
    stored_custom_attributes(account)['enterprise_inquiry']
  end

  def save_enterprise_inquiry!(account, inquiry)
    attrs = stored_custom_attributes(account).dup
    attrs['enterprise_inquiry'] = inquiry
    update_stored_custom_attributes!(account, attrs)
  end
end
