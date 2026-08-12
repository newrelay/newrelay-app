# == Schema Information
#
# Table name: processed_webhook_events
#
#  id              :bigint           not null, primary key
#  event_type      :string           not null
#  processed_at    :datetime         not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  stripe_event_id :string           not null
#
# Indexes
#
#  index_processed_webhook_events_on_stripe_event_id  (stripe_event_id) UNIQUE
#
class ProcessedWebhookEvent < ApplicationRecord
  validates :stripe_event_id, presence: true, uniqueness: true
  validates :event_type, presence: true
  validates :processed_at, presence: true
end
