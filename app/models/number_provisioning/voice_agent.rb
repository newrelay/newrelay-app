# == Schema Information
#
# Table name: number_provisioning_voice_agents
#
#  id                         :bigint           not null, primary key
#  failure_code               :string
#  previous_sip_target        :string
#  status                     :string           default("saved"), not null
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  account_id                 :bigint           not null
#  elevenlabs_phone_number_id :string
#  order_id                   :bigint           not null
#  public_id                  :string           not null
#
# Indexes
#
#  index_number_provisioning_voice_agents_on_account_id  (account_id)
#  index_number_provisioning_voice_agents_on_order_id    (order_id) UNIQUE
#  index_number_provisioning_voice_agents_on_public_id   (public_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (order_id => number_provisioning_orders.id)
#
class NumberProvisioning::VoiceAgent < ApplicationRecord
  STATUSES = %w[saved failed].freeze

  belongs_to :account
  belongs_to :order, class_name: 'NumberProvisioning::Order'

  validates :public_id, :status, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :order_id, uniqueness: true

  before_validation :assign_public_id, on: :create

  private

  def assign_public_id
    self.public_id ||= SecureRandom.uuid
  end
end
