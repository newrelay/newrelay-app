class CommentAutomation::Template < ApplicationRecord
  belongs_to :account
  has_many :triggers, class_name: 'CommentAutomation::Trigger', dependent: :nullify, inverse_of: :template

  enum template_type: { message: 0, comment: 1 }

  validates :name, presence: true
end
