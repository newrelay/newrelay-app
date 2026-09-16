module Enterprise::Concerns::Conversation
  extend ActiveSupport::Concern

  included do
    attr_accessor :skip_resolution_attribute_check

    belongs_to :sla_policy, optional: true
    has_one :applied_sla, dependent: :destroy_async
    has_many :sla_events, dependent: :destroy_async
    has_many :calls, dependent: :destroy_async
    has_many :captain_responses, class_name: 'Captain::AssistantResponse', dependent: :nullify, as: :documentable
    before_validation :validate_sla_policy, if: -> { sla_policy_id_changed? }
    around_save :ensure_applied_sla_is_created, if: -> { sla_policy_id_changed? }

    validate :enforce_monthly_conversations_limit, on: :create
    validate :enforce_required_attributes_on_resolution,
             if: -> { status_changed? && status == 'resolved' && !skip_resolution_attribute_check }
  end

  private

  def enforce_required_attributes_on_resolution
    return unless account&.feature_enabled?('conversation_required_attributes')

    required_keys = account.conversation_required_attributes || []
    return if required_keys.empty?

    definitions = account.custom_attribute_definitions
                         .where(attribute_model: :conversation_attribute, attribute_key: required_keys)
                         .index_by(&:attribute_key)

    missing = required_keys.select { |key| required_attribute_missing?(definitions[key], key) }

    errors.add(:custom_attributes, "missing required attributes: #{missing.join(', ')}") if missing.any?
  end

  def required_attribute_missing?(definition, key)
    return false unless definition

    definition.checkbox? ? !custom_attributes.key?(key) : custom_attributes[key].blank?
  end

  def enforce_monthly_conversations_limit
    return unless account

    limit = account.limits['conversations']
    return if limit.nil? # unlimited

    current_count = account.conversations.where('created_at > ?', 30.days.ago).count
    return unless current_count >= limit.to_i

    errors.add(:base, "Monthly conversation limit of #{limit} has been reached for this account")
  end

  def validate_sla_policy
    # TODO: remove these validations once we figure out how to deal with these cases
    if sla_policy_id.nil? && changes[:sla_policy_id].first.present?
      errors.add(:sla_policy, 'cannot remove sla policy from conversation')
      return
    end

    if changes[:sla_policy_id].first.present?
      errors.add(:sla_policy, 'conversation already has a different sla')
      return
    end

    errors.add(:sla_policy, 'sla policy account mismatch') if sla_policy&.account_id != account_id
  end

  # handling inside a transaction to ensure applied sla record is also created
  def ensure_applied_sla_is_created
    ActiveRecord::Base.transaction do
      yield
      create_applied_sla(sla_policy_id: sla_policy_id) if applied_sla.blank?
    end
  rescue ActiveRecord::RecordInvalid
    raise ActiveRecord::Rollback
  end
end
