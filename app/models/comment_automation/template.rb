# == Schema Information
#
# Table name: comment_automation_templates
#
#  id             :bigint           not null, primary key
#  dm_text_body   :text
#  favorite       :boolean          default(FALSE), not null
#  name           :string           not null
#  public_replies :text             default([]), not null, is an Array
#  template_type  :integer          default("message"), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  account_id     :bigint           not null
#
# Indexes
#
#  index_comment_automation_templates_on_account_id  (account_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class CommentAutomation::Template < ApplicationRecord
  belongs_to :account
  has_many :triggers, class_name: 'CommentAutomation::Trigger', dependent: :nullify, inverse_of: :template

  enum template_type: { message: 0, comment: 1 }

  validates :name, presence: true
end
