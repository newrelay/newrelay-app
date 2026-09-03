module CommentAutomation
  def self.table_name_prefix
    'comment_automation_'
  end

  # Offline Instagram Graph calls — same idea as REPUTATION_GOOGLE_PROVIDER=mock.
  # Connect with a post URL, seed comments into the DB, no Meta API.
  def self.mock?
    ENV.fetch('COMMENT_AUTOMATION_PROVIDER', '') == 'mock'
  end

  def self.mock_channel?(channel)
    channel.respond_to?(:mock_credentials?) && channel.mock_credentials?
  end
end
