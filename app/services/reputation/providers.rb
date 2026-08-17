# Resolves the read/reply adapter for a reputation integration.
#
# Google reviews can come from Google directly OR from GMBapi.com (a Google-approved
# GBP reseller that skips Google's API allowlisting). Both adapters expose the same
# contract — #list_reviews and #publish_reply — so swapping them needs no job changes:
#
#   REPUTATION_GOOGLE_PROVIDER=google   # default: call Google's GBP API directly
#   REPUTATION_GOOGLE_PROVIDER=gmbapi   # route Google through GMBapi.com
module Reputation
  module Providers
    def self.adapter_for(integration)
      case integration.provider
      when 'google'   then google(integration)
      when 'facebook' then Facebook.new(integration)
      end
    end

    def self.google(integration)
      if ENV.fetch('REPUTATION_GOOGLE_PROVIDER', 'google') == 'gmbapi'
        Gmbapi.new(integration)
      else
        Google.new(integration)
      end
    end
  end
end
