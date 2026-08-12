# == Schema Information
#
# Table name: tasks
#
#  id          :bigint           not null, primary key
#  completed   :boolean          default(FALSE), not null
#  description :text
#  due_at      :datetime
#  title       :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
#  assignee_id :bigint
#
# Indexes
#
#  index_tasks_on_account_id   (account_id)
#  index_tasks_on_assignee_id  (assignee_id)
#
class Task < ApplicationRecord
  belongs_to :account
  belongs_to :assignee, class_name: 'User', optional: true
  has_many :contact_tasks, dependent: :destroy
  has_many :contacts, through: :contact_tasks

  validates :title, presence: true
  validates :account_id, presence: true
end
