# Resolves the read/reply adapter for a reputation integration.
#
# Two modes, selected by REPUTATION_GOOGLE_PROVIDER:
#
#   REPUTATION_GOOGLE_PROVIDER=google   # default: call Google's GBP API directly
#   REPUTATION_GOOGLE_PROVIDER=mock     # offline fake data, no API / no OAuth
module Reputation::Providers
  def self.adapter_for(integration)
    # Mock mode serves every provider with fake data so the whole flow works
    # offline while the real Google API is pending approval.
    return Mock.new(integration) if mock?

    case integration.provider
    when 'google'   then google(integration)
    when 'facebook' then Facebook.new(integration)
    end
  end

  def self.google(integration)
    return Mock.new(integration) if mock?

    Google.new(integration)
  end

  # True when reviews come from the offline Mock adapter (fake data, no API).
  def self.mock?
    ENV.fetch('REPUTATION_GOOGLE_PROVIDER', 'google') == 'mock'
  end

  # Mock mode holds no Google OAuth of its own: an integration only needs a
  # location_id to connect, no OAuth redirect.
  def self.skip_oauth?
    mock?
  end
end
