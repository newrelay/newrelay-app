# == Schema Information
#
# Table name: email_logs
#
#  id           :bigint           not null, primary key
#  body         :text
#  from         :string
#  mailer_class :string           not null
#  subject      :string
#  to           :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class EmailLog < ApplicationRecord
  validates :mailer_class, :to, presence: true

  scope :recent_first, -> { order(created_at: :desc) }

  def body_preview
    body.to_s.truncate(200)
  end
end
