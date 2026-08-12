json.settings resource.settings
json.created_at resource.created_at
if resource.custom_attributes.present?
  json.custom_attributes do
    json.plan_name resource.custom_attributes['plan_name']
    json.subscribed_quantity resource.custom_attributes['subscribed_quantity']
    json.subscription_status resource.custom_attributes['subscription_status']
    json.subscription_ends_on resource.custom_attributes['subscription_ends_on']
    json.website resource.custom_attributes['website'] if resource.custom_attributes['website'].present?
    json.industry resource.custom_attributes['industry'] if resource.custom_attributes['industry'].present?
    json.company_size resource.custom_attributes['company_size'] if resource.custom_attributes['company_size'].present?
    json.timezone resource.custom_attributes['timezone'] if resource.custom_attributes['timezone'].present?
    json.logo resource.custom_attributes['logo'] if resource.custom_attributes['logo'].present?
    json.referral_source resource.custom_attributes['referral_source'] if resource.custom_attributes['referral_source'].present?
    json.brand_info resource.custom_attributes['brand_info'] if resource.custom_attributes['brand_info'].present?
    json.brand_colors resource.custom_attributes['brand_colors'] if resource.custom_attributes['brand_colors'].present?
    json.onboarding_step resource.onboarding_step if resource.onboarding_step.present?
    json.marked_for_deletion_at resource.custom_attributes['marked_for_deletion_at'] if resource.custom_attributes['marked_for_deletion_at'].present?
    if resource.custom_attributes['marked_for_deletion_reason'].present?
      json.marked_for_deletion_reason resource.custom_attributes['marked_for_deletion_reason']
    end
  end
end
json.domain @account.domain
json.custom_domain @account.custom_domain
json.ssl_settings @account.ssl_settings
json.server_ip ENV.fetch('SERVER_IP', nil)
json.brand_name @account.brand_name
json.brand_logo_url @account.brand_logo_url
json.brand_primary_color @account.brand_primary_color
json.brand_secondary_color @account.brand_secondary_color
json.logo_url @account.logo_url
json.dark_logo_url @account.dark_logo_url
json.favicon_url @account.favicon_url
json.features @account.enabled_features
json.id @account.id
json.locale @account.locale
json.name @account.name
json.support_email @account.support_email
json.status @account.status
json.cache_keys @account.cache_keys
json.parent_id @account.parent_id
json.is_reseller @account.is_reseller
