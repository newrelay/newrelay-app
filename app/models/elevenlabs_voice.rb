# == Schema Information
#
# Table name: elevenlabs_voices
#
#  id                    :bigint           not null, primary key
#  consent_accepted_at   :datetime         not null
#  consent_statement     :string           not null
#  error_message         :string
#  name                  :string           not null
#  preview_url           :string
#  requires_verification :boolean          default(FALSE), not null
#  status                :integer          default("pending"), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  account_id            :bigint           not null
#  voice_id              :string
#
# Indexes
#
#  index_elevenlabs_voices_on_account_and_voice_id  (account_id,voice_id) UNIQUE WHERE (voice_id IS NOT NULL)
#  index_elevenlabs_voices_on_account_id            (account_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class ElevenlabsVoice < ApplicationRecord
  CONSENT_SENTENCE = 'I have the right to clone this voice.'.freeze

  belongs_to :account
  has_one_attached :clip

  enum :status, { pending: 0, ready: 1, failed: 2 }

  validates :name, presence: true
  validates :consent_statement, presence: true
  validates :consent_accepted_at, presence: true
end
