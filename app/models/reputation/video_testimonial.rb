# == Schema Information
#
# Table name: reputation_video_testimonials
#
#  id         :bigint           not null, primary key
#  email      :string
#  status     :string           default("pending")
#  title      :string
#  token      :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#
# Indexes
#
#  index_reputation_video_testimonials_on_account_id  (account_id)
#  index_reputation_video_testimonials_on_token       (token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class Reputation::VideoTestimonial < ApplicationRecord
  belongs_to :account
  has_secure_token
  has_one_attached :video
end
