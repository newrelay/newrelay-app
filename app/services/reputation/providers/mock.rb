# Mock review provider — serves realistic fake reviews with NO external API, so the
# whole Reputation flow (sync -> DB -> UI -> reply) works end to end while Google's
# Business Profile API is pending approval (and without paying for a reseller).
#
# Same contract as the real adapters (#list_reviews / #publish_reply), so switching
# to the real thing is a one-line env change and zero job/UI changes:
#
#   REPUTATION_GOOGLE_PROVIDER=mock     # this adapter (fake data, works offline)
#   REPUTATION_GOOGLE_PROVIDER=google   # real Google GBP API (once approved)
#
# external_ids are deterministic per integration, so repeated syncs upsert the same
# rows instead of duplicating.
module Reputation
  module Providers
    class Mock
      REVIEWERS = ['Sarah Jenkins', 'Michael Chang', 'Emily Rodriguez', 'David Okafor',
                   'Priya Nair', 'Tom Becker', 'Aisha Khan', 'Liam Murphy', 'Nina Patel', 'Carlos Reyes'].freeze

      BODIES = [
        'Absolutely incredible service! The team was super responsive and resolved my issue within minutes.',
        'Good overall experience, but the onboarding could be a little smoother. Great product though.',
        "We've been using this for months and it has transformed how we handle customer engagement.",
        'Fast, friendly and professional. Would recommend to anyone looking for a solid solution.',
        'Decent, but I had to follow up twice to get a response. Ended up happy with the outcome.',
        'Top notch support and a genuinely useful product. The AI features are a game changer.',
        'Average experience. Nothing wrong, nothing outstanding. Does the job.',
        'Had a billing issue that took a while to sort out, but the team made it right in the end.',
        'Best decision we made this year. Setup was quick and the results speak for themselves.',
        'Really impressed with the response time and the quality of the replies to our reviews.'
      ].freeze

      RATINGS = [5, 5, 4, 5, 3, 4, 5, 2, 5, 4].freeze

      def initialize(integration)
        @integration = integration
      end

      # Returns normalized review hashes: { external_id:, rating:, body:, reviewer_name:, reviewed_at: }
      # Spread over the last ~6 months so the Overview trend + platform breakdown populate.
      def list_reviews
        anchor = Time.zone.today.beginning_of_month
        (0...RATINGS.length).map do |i|
          {
            external_id: "mock-#{@integration.id}-#{i}",
            rating: RATINGS[i],
            body: BODIES[i % BODIES.length],
            reviewer_name: REVIEWERS[i % REVIEWERS.length],
            reviewed_at: (anchor - (i * 18).days).to_time
          }
        end
      end

      # No external Google API — accept the reply and succeed so the reply flow
      # (status -> replied, published) works end to end. Swap to the real adapter
      # once REPUTATION_GOOGLE_PROVIDER=google is approved.
      def publish_reply(_review, _body)
        true
      end
    end
  end
end
