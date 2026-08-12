# == Schema Information
#
# Table name: reputation_widgets
#
#  id             :bigint           not null, primary key
#  active         :boolean          default(TRUE)
#  hide_watermark :boolean          default(FALSE), not null
#  min_rating     :integer          default(4)
#  name           :string           not null
#  style          :string           default("carousel")
#  token          :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  account_id     :bigint           not null
#
# Indexes
#
#  index_reputation_widgets_on_account_id  (account_id)
#  index_reputation_widgets_on_token       (token) UNIQUE
#
class Reputation::Widget < ApplicationRecord
  self.table_name = 'reputation_widgets'

  belongs_to :account

  enum :style, { carousel: 'carousel', grid: 'grid', badge: 'badge' }

  validates :name, :token, presence: true
  validates :token, uniqueness: true
  validates :min_rating, inclusion: { in: 1..5 }

  before_validation :set_token, on: :create

  private

  def set_token
    self.token ||= SecureRandom.urlsafe_base64(12)
  end
end
