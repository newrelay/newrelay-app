class CommentAutomation::MatchEngine
  pattr_initialize [:campaign!, :comment!]

  def match
    return nil if self_comment?

    campaign.triggers.detect { |trigger| matches?(trigger) }
  end

  private

  def self_comment?
    comment.dig(:from, :id) == campaign.inbox.channel.instagram_id
  end

  def matches?(trigger)
    return true if trigger.keyword.blank?

    normalized_text = comment[:text].to_s.downcase
    normalized_keyword = trigger.keyword.to_s.downcase

    trigger.exact? ? normalized_text == normalized_keyword : normalized_text.include?(normalized_keyword)
  end
end
