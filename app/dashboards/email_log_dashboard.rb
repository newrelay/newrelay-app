require 'administrate/base_dashboard'

class EmailLogDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    mailer_class: Field::String,
    to: Field::String.with_options(searchable: true),
    from: Field::String,
    subject: Field::String.with_options(searchable: true),
    body: Field::Text,
    created_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    mailer_class
    to
    subject
    created_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    mailer_class
    to
    from
    subject
    body
    created_at
  ].freeze

  FORM_ATTRIBUTES = %i[].freeze

  COLLECTION_FILTERS = {
    mailer_class: ->(resources, value) { resources.where(mailer_class: value) }
  }.freeze

  def display_resource(email_log)
    "#{email_log.mailer_class} ##{email_log.id}"
  end
end
