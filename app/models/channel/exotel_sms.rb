# == Schema Information
#
# Table name: channel_exotel_sms
#
#  id           :integer          not null, primary key
#  phone_number :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :integer          not null
#
# Indexes
#
#  index_channel_exotel_sms_on_account_id    (account_id)
#  index_channel_exotel_sms_on_phone_number  (phone_number) UNIQUE
#
class Channel::ExotelSms < ApplicationRecord
  include Channelable

  self.table_name = 'channel_exotel_sms'

  validates :phone_number, presence: true, uniqueness: true

  def name
    'Exotel SMS'
  end
end
