require 'administrate/base_dashboard'

class CaptainActivityLogDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    account: Field::BelongsTo,
    user: Field::BelongsTo,
    action: Field::String,
    status: Field::String,
    error_class: Field::String,
    message: Field::Text,
    metadata_preview: Field::Text.with_options(searchable: false),
    notified_at: Field::DateTime,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    account
    action
    status
    message
    notified_at
    created_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    account
    user
    action
    status
    error_class
    message
    metadata_preview
    notified_at
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[].freeze

  COLLECTION_FILTERS = {
    status: ->(resources, value) { resources.where(status: value) },
    action: ->(resources, value) { resources.where(action: value) }
  }.freeze

  def display_resource(log)
    "#{log.action} (#{log.status}) ##{log.id}"
  end
end
