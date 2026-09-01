class CommentAutomation::RateLimiter
  LIMIT_PER_SECOND = 10

  pattr_initialize [:inbox!]

  def within_limit?
    current_count < LIMIT_PER_SECOND
  rescue Redis::BaseError => e
    Rails.logger.error("[comment_automation] event=rate_limiter_redis_error error=#{e.message}")
    false # ponytail: fail-closed rate limiter, revisit if legit sends get delayed by Redis blips
  end

  def track_send
    Redis::Alfred.set(send_key, 1, ex: 1)
  end

  private

  def current_count
    Redis::Alfred.keys_count(send_key_pattern)
  end

  def send_key
    format(Redis::RedisKeys::COMMENT_AUTOMATION_SEND_KEY, inbox_id: inbox.id, token: SecureRandom.hex(4))
  end

  def send_key_pattern
    format(Redis::RedisKeys::COMMENT_AUTOMATION_SEND_KEY_PATTERN, inbox_id: inbox.id)
  end
end
