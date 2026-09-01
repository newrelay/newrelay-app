# rubocop:disable Metrics/ClassLength, Metrics/MethodLength, Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
class Api::V1::Accounts::Reputation::IntegrationsController < Api::V1::Accounts::Reputation::BaseController
  before_action :integration, only: [:destroy, :sync]
  before_action :assert_assignable_listing!, only: [:create]

  # GET /api/v1/accounts/:account_id/reputation/integrations
  # GET /api/v1/accounts/:account_id/reputation/integrations?listing_id=X
  def index
    integrations = scoped_integrations.order(created_at: :desc)
    integrations = integrations.where(reputation_listing_id: params[:listing_id]) if params[:listing_id].present?

    render json: integrations.as_json(
      only: [:id, :provider, :location_id, :location_name, :status, :created_at, :reputation_listing_id]
    )
  end

  # GET /api/v1/accounts/:account_id/reputation/integrations/google_locations
  def google_locations
    cache_key = params[:oauth_session_id]
    if cache_key.present?
      raw_data = $alfred.with { |redis| redis.get(cache_key) }
      token_data = JSON.parse(raw_data) if raw_data.present?
    end

    if token_data.blank?
      render json: { errors: ['Google account credentials not found or expired. Please authenticate again.'] }, status: :unprocessable_entity
      return
    end

    options = { headers: { 'Authorization' => "Bearer #{token_data['access_token']}" } }
    options[:verify] = false if Rails.env.development?

    resp = HTTParty.get(
      'https://mybusinessbusinessinformation.googleapis.com/v1/accounts/-/locations',
      options
    )

    if resp.success?
      locations = resp.parsed_response['locations'] || []
      formatted_locations = locations.map do |loc|
        {
          location_id: loc['name'],
          location_name: loc['title']
        }
      end
      render json: formatted_locations
    else
      render json: { errors: ["Failed to fetch Google locations: #{resp.body}"] }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/accounts/:account_id/reputation/integrations/oauth_state
  # Returns a signed, expiring state for the OAuth redirect. The callback verifies
  # it to learn which account initiated the flow, instead of trusting a raw
  # account_id param (which allowed cross-account integration hijack).
  def oauth_state
    state = Rails.application.message_verifier('reputation_oauth')
                 .generate(current_account.id, purpose: :reputation_oauth, expires_in: 15.minutes)
    render json: { state: state }
  end

  # POST /api/v1/accounts/:account_id/reputation/integrations
  def create
    if integration_params[:provider] == 'google'
      # Mock mode holds no Google OAuth, so connect with just a location_id
      # (any value in mock mode) and let reviews sync in.
      return create_google_without_oauth if Reputation::Providers.skip_oauth?

      cache_key = params[:oauth_session_id] || integration_params[:oauth_session_id]
      if cache_key.present?
        raw_data = $alfred.with { |redis| redis.get(cache_key) }
        token_data = JSON.parse(raw_data) if raw_data.present?
      end

      if token_data.blank?
        render json: { errors: ['Google account credentials not found. Please connect your Google account again.'] }, status: :unprocessable_entity
        return
      end

      integration = build_or_relink('google', integration_params[:location_id])
      was_new = integration.new_record?
      integration.assign_attributes(
        location_name: integration_params[:location_name],
        access_token: token_data['access_token'],
        refresh_token: token_data['refresh_token'],
        token_expires_at: token_data['expires_in'] ? Time.current + token_data['expires_in'].to_i.seconds : nil
      )

      if integration.save
        # Sync reviews in background — only needed for a genuinely new connection,
        # a relinked one already has its reviews.
        Reputation::ReviewSyncJob.perform_later(integration.id) if was_new
        session[:reputation_google_oauth] = nil

        render json: integration.as_json(
          only: [:id, :provider, :location_id, :location_name, :status, :created_at, :reputation_listing_id]
        ), status: was_new ? :created : :ok
      else
        render json: { errors: integration.errors.full_messages }, status: :unprocessable_entity
      end
    else
      location_id = integration_params[:location_id].presence || SecureRandom.uuid
      integration = build_or_relink(integration_params[:provider], location_id)
      was_new = integration.new_record?
      integration.location_name = integration_params[:location_name] if integration_params[:location_name].present?

      if integration.save
        # Seed realistic reviews for all manually-connected providers (including Google) —
        # only for a genuinely new connection, a relinked one already has its reviews.
        seed_mock_reviews(integration) if was_new
        render json: integration.as_json(
          only: [:id, :provider, :location_id, :location_name, :status, :created_at, :reputation_listing_id]
        ), status: was_new ? :created : :ok
      else
        render json: { errors: integration.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end

  # DELETE /api/v1/accounts/:account_id/reputation/integrations/:id
  def destroy
    @integration.destroy!
    head :no_content
  end

  # POST /api/v1/accounts/:account_id/reputation/integrations/:id/sync
  def sync
    enqueue_sync(@integration.id)
    render json: @integration.as_json(
      only: [:id, :provider, :location_id, :location_name, :status, :created_at, :reputation_listing_id]
    )
  end

  # POST /api/v1/accounts/:account_id/reputation/integrations/sync_all
  # POST /api/v1/accounts/:account_id/reputation/integrations/sync_all?listing_id=X
  def sync_all
    integrations = scoped_integrations.active
    integrations = integrations.where(reputation_listing_id: params[:listing_id]) if params[:listing_id].present?
    ids = integrations.pluck(:id)
    ids.each { |id| enqueue_sync(id) }
    render json: { synced: ids.size }
  end

  private

  # Mock mode has no network, so run inline for instant feedback; real providers
  # sync in the background via the same job the hourly scheduler uses.
  def enqueue_sync(integration_id)
    if Reputation::Providers.mock?
      Reputation::ReviewSyncJob.perform_now(integration_id)
    else
      Reputation::ReviewSyncJob.perform_later(integration_id)
    end
  end

  # Mock mode holds no Google OAuth, so a Google integration connects with just a
  # location_id — no OAuth session. Reviews arrive via ReviewSyncJob using the Mock adapter.
  def create_google_without_oauth
    integration = build_or_relink('google', integration_params[:location_id])
    was_new = integration.new_record?
    integration.location_name = integration_params[:location_name]

    if integration.save
      # Mock mode seeds fake reviews with no network, so run it inline — the reviews
      # are then visible the instant the user opens the Reviews page (matching the
      # synchronous seeding of manually-connected providers). Only for a genuinely
      # new connection — a relinked one already has its reviews.
      if was_new
        if Reputation::Providers.mock?
          Reputation::ReviewSyncJob.perform_now(integration.id)
        else
          Reputation::ReviewSyncJob.perform_later(integration.id)
        end
      end
      render json: integration.as_json(
        only: [:id, :provider, :location_id, :location_name, :status, :created_at, :reputation_listing_id]
      ), status: was_new ? :created : :ok
    else
      render json: { errors: integration.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def integration
    @integration ||= scoped_integrations.find(params[:id])
  end

  def assert_assignable_listing!
    id = integration_params[:listing_id]
    return if id.blank?
    raise ActiveRecord::RecordNotFound unless scoped_listings.exists?(id)
  end

  # Finds an already-connected integration for this account+provider+location and
  # relinks it to the requesting listing instead of failing on the uniqueness
  # constraint — the same physical platform connection can only exist once per
  # account, so reconnecting it from a different listing means "this listing owns
  # it now," not "create a duplicate."
  def build_or_relink(provider, location_id)
    integration = current_account.reputation_integrations.find_or_initialize_by(provider: provider, location_id: location_id)
    integration.status = :active
    integration.reputation_listing_id = integration_params[:listing_id]
    integration
  end

  def integration_params
    params.require(:integration).permit(:provider, :location_id, :location_name, :oauth_session_id, :listing_id)
  end

  def seed_mock_reviews(integration)
    if integration.provider == 'google' && ENV.fetch('GOOGLE_MAPS_API_KEY', nil).present?
      fetch_and_create_real_google_reviews(integration)
    else
      seed_mock_templates(integration)
    end
  end

  def fetch_and_create_real_google_reviews(integration)
    raw_reviews = fetch_google_reviews_from_api(integration.location_id)
    if raw_reviews.any?
      save_real_google_reviews(integration, raw_reviews)
    else
      seed_mock_templates(integration)
    end
  rescue StandardError => e
    Rails.logger.error "Failed to fetch real Google reviews: #{e.message}"
    seed_mock_templates(integration)
  end

  def fetch_google_reviews_from_api(place_id)
    api_key = ENV.fetch('GOOGLE_MAPS_API_KEY', nil)
    url = "https://maps.googleapis.com/maps/api/place/details/json?place_id=#{place_id}&fields=reviews,name,rating&key=#{api_key}"
    options = {}
    options[:verify] = false if Rails.env.development?
    response = HTTParty.get(url, options)
    return [] unless response.success? && response.parsed_response['result']

    response.parsed_response.dig('result', 'reviews') || []
  end

  def save_real_google_reviews(integration, raw_reviews)
    raw_reviews.each do |raw|
      # Places reviews have no stable id; key on author + time so re-imports dedupe.
      external_id = "places_#{raw['time']}_#{Digest::SHA256.hexdigest(raw['author_name'].to_s)[0, 8]}"
      review = integration.reputation_reviews.find_or_initialize_by(external_id: external_id)
      review.status = :pending if review.new_record?
      review.update!(
        account: integration.account,
        provider: 'google',
        reviewer_name: raw['author_name'] || 'Google User',
        rating: raw['rating'].to_i,
        body: raw['text'],
        reviewed_at: Time.zone.at(raw['time'].to_i)
      )
    end
  end

  def seed_mock_templates(integration)
    templates = review_templates_for(integration.provider)
    templates.each do |t|
      integration.reputation_reviews.create!(
        account: integration.account,
        provider: integration.provider,
        external_id: "mock_#{integration.provider}_#{SecureRandom.hex(4)}",
        reviewer_name: t[:reviewer_name],
        rating: t[:rating],
        body: t[:body],
        status: :pending,
        reviewed_at: t[:reviewed_at]
      )
    end
  end

  def review_templates_for(provider)
    case provider
    when 'google'
      [
        { reviewer_name: 'Sarah Jenkins', rating: 5,
          body: 'Absolutely wonderful experience! The team was prompt, professional, and went above and beyond. Highly recommend to everyone.',
          reviewed_at: 1.day.ago },
        { reviewer_name: 'Michael Chen', rating: 4,
          body: 'Very satisfied with the quality of service and overall communication. Will be back and will definitely recommend!',
          reviewed_at: 3.days.ago },
        { reviewer_name: 'Priya Sharma', rating: 5,
          body: 'Five stars all the way! Easy to work with, honest pricing, and results that exceeded expectations.',
          reviewed_at: 5.days.ago },
        { reviewer_name: 'James O\'Brien', rating: 3,
          body: 'Good service overall, though the wait time was a bit longer than expected. Staff was friendly and helpful.',
          reviewed_at: 8.days.ago },
        { reviewer_name: 'Fatima Al-Hassan', rating: 5,
          body: 'Outstanding from start to finish. I will definitely be a repeat customer. Excellent communication throughout.',
          reviewed_at: 12.days.ago }
      ]
    when 'facebook'
      [
        { reviewer_name: 'Tom Richards', rating: 5,
          body: 'Great experience from start to finish. Found them via Facebook and couldn\'t be happier!',
          reviewed_at: 2.days.ago },
        { reviewer_name: 'Maria Gonzalez', rating: 4,
          body: 'Really good service. The staff were kind and the process was smooth. Will recommend!',
          reviewed_at: 6.days.ago }
      ]
    else
      [
        { reviewer_name: 'Sarah Jenkins', rating: 5,
          body: 'Absolutely wonderful experience! The service was prompt, professional, and went above and beyond my expectations.',
          reviewed_at: 1.day.ago },
        { reviewer_name: 'Michael Chen', rating: 4,
          body: 'Very satisfied with the quality of the listing and overall communication. Will recommend it to everyone.',
          reviewed_at: 3.days.ago },
        { reviewer_name: 'David K.', rating: 5,
          body: 'Fantastic! Easy to use and got exactly what I needed. Five stars all the way.',
          reviewed_at: 5.days.ago }
      ]
    end
  end
end
# rubocop:enable Metrics/ClassLength, Metrics/MethodLength, Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
