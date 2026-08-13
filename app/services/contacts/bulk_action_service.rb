class Contacts::BulkActionService
  def initialize(account:, user:, params:)
    @account = account
    @user = user
    @params = params.deep_symbolize_keys
  end

  def perform
    audit = create_audit_record
    begin
      audit&.processing!
      result = execute_action
      success_count = result[:updated_contact_ids]&.size || ids.size
      audit&.update!(
        status: :completed,
        completed_at: Time.zone.now,
        statistics: { total: ids.size, success: success_count }
      )
      result
    rescue StandardError => e
      audit&.failed!
      raise e
    end
  end

  private

  def execute_action
    return delete_contacts if delete_requested?
    return assign_labels if labels_to_add.any?
    return remove_labels if labels_to_remove.any?

    Rails.logger.warn("Unknown contact bulk operation payload: #{@params.keys}")
    { success: false, error: 'unknown_operation' }
  end

  def create_audit_record
    op_type = operation_type
    return if op_type.blank?

    @account.bulk_action_audits.create!(
      user: @user,
      operation_type: op_type,
      action_label: action_label_name,
      status: :pending,
      statistics: { total: ids.size, success: 0 }
    )
  rescue StandardError => e
    Rails.logger.error("Failed to create BulkActionAudit: #{e.message}")
    nil
  end

  def operation_type
    return 'delete' if delete_requested?
    return 'add_tag' if labels_to_add.any?
    return 'remove_tag' if labels_to_remove.any?

    nil
  end

  def action_label_name
    case operation_type
    when 'add_tag'
      "Add label (#{labels_to_add.join(', ')})"
    when 'remove_tag'
      "Remove label (#{labels_to_remove.join(', ')})"
    when 'delete'
      "Delete #{ids.size} contacts"
    else
      'Bulk contact action'
    end
  end

  def assign_labels
    Contacts::BulkAssignLabelsService.new(
      account: @account,
      contact_ids: ids,
      labels: labels_to_add
    ).perform
  end

  def remove_labels
    Contacts::BulkRemoveLabelsService.new(
      account: @account,
      contact_ids: ids,
      labels: labels_to_remove
    ).perform
  end

  def delete_contacts
    Contacts::BulkDeleteService.new(
      account: @account,
      contact_ids: ids
    ).perform
  end

  def ids
    Array(@params[:ids]).compact
  end

  def labels_to_add
    @labels_to_add ||= Array(@params.dig(:labels, :add)).reject(&:blank?)
  end

  def labels_to_remove
    @labels_to_remove ||= Array(@params.dig(:labels, :remove)).reject(&:blank?)
  end

  def delete_requested?
    @params[:action_name] == 'delete'
  end
end
