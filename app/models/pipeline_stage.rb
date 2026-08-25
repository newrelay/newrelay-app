# == Schema Information
#
# Table name: pipeline_stages
#
#  id          :bigint           not null, primary key
#  color       :string           default("primary"), not null
#  is_lost     :boolean          default(FALSE), not null
#  is_won      :boolean          default(FALSE), not null
#  name        :string           not null
#  position    :integer          default(0), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
#  pipeline_id :bigint           not null
#
# Indexes
#
#  index_pipeline_stages_on_account_id                (account_id)
#  index_pipeline_stages_on_pipeline_id               (pipeline_id)
#  index_pipeline_stages_on_pipeline_id_and_name      (pipeline_id,name) UNIQUE
#  index_pipeline_stages_on_pipeline_id_and_position  (pipeline_id,position)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (pipeline_id => pipelines.id)
#
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
