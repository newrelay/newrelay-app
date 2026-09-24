module SuperAdmin::UiHelper
  # Administrate's helper uses Rails.application.module_parent_name ("Chatwoot").
  def application_title
    'NewRelay'
  end

  def super_admin_feature_icon(feature_key)
    inner = SuperAdmin::AccountFeaturesHelper.icon_inner_html(feature_key)
    %(<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">#{inner}</svg>).html_safe
  end

  def super_admin_blank_value?(value)
    return false if value.is_a?(FalseClass) || value.is_a?(Numeric)

    value.blank?
  end
end
