class Pipeline < ApplicationRecord
  belongs_to :account
  has_many :pipeline_stages, -> { order(:position) }, dependent: :destroy_async, inverse_of: :pipeline
  has_many :deals, dependent: :destroy_async

  validates :name, presence: true, uniqueness: { scope: :account_id }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
