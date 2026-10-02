class ReplaceRetiredDefaultBrandTheme < ActiveRecord::Migration[7.1]
  def up
    Account.reset_column_information
    Account.find_each do |account|
      # Raw column — Account#custom_attributes merges the parent and must not be written back.
      attrs = (account.read_attribute(:custom_attributes) || {}).deep_dup
      next if attrs.blank?

      colors = attrs['brand_colors']
      next unless colors.is_a?(Hash) && colors['theme_preset'] == 'default'

      kept = colors.slice('brand_name', 'layout').compact
      attrs['brand_colors'] = Account::NEWRELAY_THEME_COLORS.merge(kept)
      account.update_columns(
        custom_attributes: attrs,
        brand_primary_color: Account::NEWRELAY_THEME_COLORS['primary'],
        brand_secondary_color: Account::NEWRELAY_THEME_COLORS['background'],
        updated_at: Time.current
      )
    end
  end

  def down; end
end
