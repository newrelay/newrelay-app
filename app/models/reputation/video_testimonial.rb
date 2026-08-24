# == Schema Information
#
# Table name: reputation_video_testimonials
#
#  id                :bigint           not null, primary key
#  approved_at       :datetime
#  company           :string
#  consented_at      :datetime
#  customer_name     :string
#  duration_seconds  :integer
#  email             :string
#  platform          :string
#  published_at      :datetime
#  rating            :integer
#  rejected_at       :datetime
#  status            :string           default("pending")
#  title             :string
#  token             :string           not null
#  views             :integer          default(0), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :bigint           not null
#  contact_id        :bigint
#  review_request_id :bigint
#
# Indexes
#
#  index_reputation_video_testimonials_on_account_id             (account_id)
#  index_reputation_video_testimonials_on_account_id_and_status  (account_id,status)
#  index_reputation_video_testimonials_on_contact_id             (contact_id)
#  index_reputation_video_testimonials_on_token                  (token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class Reputation::VideoTestimonial < ApplicationRecord
  # Moderation lifecycle: a submission lands `pending` and is never public until
  # staff approve it (consent + brand safety). Public read endpoints must serve
  # only `approved`/`published` (see .publicly_visible).
  #
  #   pending ──approve──> approved ──publish──> published
  #      └──────reject──────> rejected
  STATUSES = %w[pending approved published rejected].freeze

  belongs_to :account
  belongs_to :contact, optional: true
  belongs_to :reputation_review_request,
             class_name: 'Reputation::ReviewRequest',
             foreign_key: :review_request_id,
             inverse_of: :video_testimonial,
             optional: true

  has_secure_token
  has_one_attached :video
  has_one_attached :thumbnail

  enum status: STATUSES.index_by(&:itself), _default: 'pending'

  # Consent is a hard gate: a video may not be stored without rights-to-use
  # (the public record page checkbox alone is bypassable — enforce server-side).
  validates :consented_at, presence: true

  scope :publicly_visible, -> { where(status: %w[approved published]) }
end
