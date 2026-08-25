class PipelineStage < ApplicationRecord
  belongs_to :account
  belongs_to :pipeline
  has_many :deals, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { scope: :pipeline_id }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :color, presence: true
  validate :won_and_lost_exclusive

  private

  def won_and_lost_exclusive
    return unless is_won? && is_lost?

    errors.add(:base, 'stage cannot be both won and lost')
  end
end
