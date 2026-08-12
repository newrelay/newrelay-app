# == Schema Information
#
# Table name: contact_tasks
#
#  id         :bigint           not null, primary key
#  contact_id :bigint           not null
#  task_id    :bigint           not null
#
# Indexes
#
#  index_contact_tasks_on_contact_id_and_task_id  (contact_id,task_id) UNIQUE
#
class ContactTask < ApplicationRecord
  belongs_to :contact
  belongs_to :task
end
