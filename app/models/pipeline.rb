# == Schema Information
#
# Table name: pipelines
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  position   :integer          default(0), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#
# Indexes
#
#  index_pipelines_on_account_id           (account_id)
#  index_pipelines_on_account_id_and_name  (account_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class Pipeline < ApplicationRecord
  belongs_to :account
  has_many :pipeline_stages, -> { order(:position) }, dependent: :destroy_async, inverse_of: :pipeline
  has_many :deals, dependent: :destroy_async

  validates :name, presence: true, uniqueness: { scope: :account_id }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
