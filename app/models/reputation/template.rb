# == Schema Information
#
# Table name: reputation_templates
#
#  id            :bigint           not null, primary key
#  active        :boolean          default(TRUE)
#  body          :text             not null
#  channel       :string           not null
#  name          :string           not null
#  subject       :string
#  template_type :string           default("standard"), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :bigint           not null
#
# Indexes
#
#  index_reputation_templates_on_account_id              (account_id)
#  index_reputation_templates_on_account_id_and_channel  (account_id,channel)
#
class Reputation::Template < ApplicationRecord
  self.table_name = 'reputation_templates'

  belongs_to :account
  has_many :reputation_review_requests, class_name: 'Reputation::ReviewRequest',
                                        foreign_key: :reputation_template_id, dependent: :nullify

  enum :channel, { sms: 'sms', email: 'email' }
  enum :template_type, { standard: 'standard', video: 'video' }

  validates :name, :channel, :body, presence: true
  validates :subject, presence: true, if: :email?
end
