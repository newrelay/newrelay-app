module Concerns::EnforcesAccountLimit
  extend ActiveSupport::Concern

  class LimitExceededError < StandardError
    attr_reader :limit_key

    def initialize(limit_key)
      @limit_key = limit_key
      super("Limit exceeded for #{limit_key}")
    end
  end

  def enforce_limit!(account, limit_key, current_count)
    limit = account.limits[limit_key.to_s]
    return if limit.nil? # unlimited

    raise LimitExceededError.new(limit_key) if current_count >= limit.to_i
  end
end
