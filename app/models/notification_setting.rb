# == Schema Information
#
# Table name: notification_settings
#
#  id                      :bigint           not null, primary key
#  email_flags             :integer          default(0), not null
#  push_flags              :integer          default(0), not null
#  quiet_hours_days        :integer          default(0), not null
#  quiet_hours_enabled     :boolean          default(FALSE), not null
#  quiet_hours_from_hour   :integer
#  quiet_hours_from_minute :integer
#  quiet_hours_timezone    :string
#  quiet_hours_to_hour     :integer
#  quiet_hours_to_minute   :integer
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  account_id              :integer
#  user_id                 :integer
#
# Indexes
#
#  by_account_user  (account_id,user_id) UNIQUE
#

class NotificationSetting < ApplicationRecord
  # used for single column multi flags
  include FlagShihTzu

  belongs_to :account
  belongs_to :user

  DEFAULT_QUERY_SETTING = {
    flag_query_mode: :bit_operator,
    check_for_column: false
  }.freeze

  EMAIL_NOTIFICATION_FLAGS = ::Notification::NOTIFICATION_TYPES.transform_keys { |key| "email_#{key}".to_sym }.invert.freeze
  PUSH_NOTIFICATION_FLAGS = ::Notification::NOTIFICATION_TYPES.transform_keys { |key| "push_#{key}".to_sym }.invert.freeze
  QUIET_HOURS_DAYS = { 1 => :monday, 2 => :tuesday, 3 => :wednesday, 4 => :thursday, 5 => :friday, 6 => :saturday, 7 => :sunday }.freeze

  has_flags EMAIL_NOTIFICATION_FLAGS.merge(column: 'email_flags').merge(DEFAULT_QUERY_SETTING)
  has_flags PUSH_NOTIFICATION_FLAGS.merge(column: 'push_flags').merge(DEFAULT_QUERY_SETTING)
  has_flags QUIET_HOURS_DAYS.merge(column: 'quiet_hours_days').merge(DEFAULT_QUERY_SETTING)

  validates :quiet_hours_from_hour, inclusion: 0..23, allow_nil: true
  validates :quiet_hours_to_hour, inclusion: 0..23, allow_nil: true
  validates :quiet_hours_from_minute, inclusion: 0..59, allow_nil: true
  validates :quiet_hours_to_minute, inclusion: 0..59, allow_nil: true

  def quiet_hours_now?
    return false unless quiet_hours_configured?

    now = Time.zone.now.in_time_zone(quiet_hours_timezone)
    return false unless public_send("#{now.strftime('%A').downcase}?")

    minutes_within_quiet_range?(now)
  end

  private

  def quiet_hours_configured?
    quiet_hours_enabled? && quiet_hours_timezone.present? && quiet_hours_from_hour.present? && quiet_hours_to_hour.present?
  end

  def minutes_within_quiet_range?(now)
    from_minutes = (quiet_hours_from_hour * 60) + quiet_hours_from_minute.to_i
    to_minutes = (quiet_hours_to_hour * 60) + quiet_hours_to_minute.to_i
    now_minutes = (now.hour * 60) + now.min

    return now_minutes >= from_minutes || now_minutes < to_minutes if from_minutes > to_minutes

    now_minutes >= from_minutes && now_minutes < to_minutes
  end
end
