# == Schema Information
#
# Table name: plan_feature_limits
#
#  id          :bigint           not null, primary key
#  enabled     :boolean          default(FALSE), not null
#  feature_key :string           not null
#  limit_value :integer
#  plan_key    :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_plan_feature_limits_on_plan_key_and_feature_key  (plan_key,feature_key) UNIQUE
#
class PlanFeatureLimit < ApplicationRecord
  PLAN_KEYS = %w[hobby standard business enterprise].freeze
  # Keys stored in plan_feature_limits that represent numeric resource quotas
  # (mapped into account.limits) rather than boolean feature flags.
  RESOURCE_LIMIT_KEYS = %w[seats contacts conversations t3_subaccounts automations captain_documents captain_responses
                           data_retention_months].freeze

  validates :plan_key, presence: true, inclusion: { in: PLAN_KEYS }
  validates :feature_key, presence: true, uniqueness: { scope: :plan_key }
  validates :enabled, inclusion: { in: [true, false] }
  validates :limit_value, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  scope :feature_flags, -> { where.not(feature_key: RESOURCE_LIMIT_KEYS) }
  scope :resource_limits, -> { where(feature_key: RESOURCE_LIMIT_KEYS) }

  def self.feature_keys_for(plan_key, enabled_only: false)
    scope = feature_flags.where(plan_key: plan_key)
    scope = scope.where(enabled: true) if enabled_only
    scope.pluck(:feature_key)
  end
end
