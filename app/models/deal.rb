# == Schema Information
#
# Table name: deals
#
#  id                :bigint           not null, primary key
#  amount_cents      :bigint           default(0), not null
#  close_on          :date
#  currency          :string           default("USD"), not null
#  name              :string           not null
#  priority          :integer          default("medium"), not null
#  probability       :integer          default(0), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :bigint           not null
#  company_id        :bigint
#  contact_id        :bigint
#  owner_id          :bigint
#  pipeline_id       :bigint           not null
#  pipeline_stage_id :bigint           not null
#
# Indexes
#
#  index_deals_on_account_id           (account_id)
#  index_deals_on_account_id_and_name  (account_id,name)
#  index_deals_on_company_id           (company_id)
#  index_deals_on_contact_id           (contact_id)
#  index_deals_on_owner_id             (owner_id)
#  index_deals_on_pipeline_id          (pipeline_id)
#  index_deals_on_pipeline_stage_id    (pipeline_stage_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (contact_id => contacts.id)
#  fk_rails_...  (owner_id => users.id)
#  fk_rails_...  (pipeline_id => pipelines.id)
#  fk_rails_...  (pipeline_stage_id => pipeline_stages.id)
#
class Deal < ApplicationRecord
  belongs_to :account
  belongs_to :pipeline
  belongs_to :pipeline_stage
  belongs_to :contact, optional: true
  belongs_to :owner, class_name: 'User', optional: true, inverse_of: false
  belongs_to :company, optional: true if ChatwootApp.enterprise?

  validates :name, presence: true
  validates :amount_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :currency, presence: true
  validates :probability, numericality: { only_integer: true, in: 0..100 }
  validate :stage_belongs_to_pipeline
  validate :contact_belongs_to_account
  validate :owner_belongs_to_account
  validate :company_belongs_to_account

  enum :priority, { low: 0, medium: 1, high: 2 }, default: :medium

  before_validation :sync_account_from_pipeline, on: :create

  private

  def sync_account_from_pipeline
    self.account_id ||= pipeline&.account_id
  end

  def stage_belongs_to_pipeline
    return if pipeline_stage.blank? || pipeline.blank?
    return if pipeline_stage.pipeline_id == pipeline_id

    errors.add(:pipeline_stage_id, 'must belong to the selected pipeline')
  end

  def contact_belongs_to_account
    return if contact.blank?
    return if contact.account_id == account_id

    errors.add(:contact_id, 'must belong to the same account')
  end

  def owner_belongs_to_account
    return if owner.blank?
    return if account.users.exists?(owner.id)

    errors.add(:owner_id, 'must belong to the same account')
  end

  def company_belongs_to_account
    return if company_id.blank?
    return unless defined?(Company)
    return if account.companies.exists?(company_id)

    errors.add(:company_id, 'must belong to the same account')
  end
end
