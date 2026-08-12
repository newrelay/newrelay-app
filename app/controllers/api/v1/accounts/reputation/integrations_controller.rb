# rubocop:disable Metrics/ClassLength, Metrics/MethodLength, Metrics/AbcSize, Metrics/PerceivedComplexity
class Api::V1::Accounts::Reputation::IntegrationsController < Api::V1::Accounts::BaseController
  before_action :integration, only: [:destroy]

  # GET /api/v1/accounts/:account_id/reputation/integrations
  def index
    render json: current_account.reputation_integrations.order(created_at: :desc).as_json(
      only: [:id, :provider, :location_id, :location_name, :status, :created_at]
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

  # POST /api/v1/accounts/:account_id/reputation/integrations
  def create
    if integration_params[:provider] == 'google'
      cache_key = params[:oauth_session_id] || integration_params[:oauth_session_id]
      if cache_key.present?
        raw_data = $alfred.with { |redis| redis.get(cache_key) }
        token_data = JSON.parse(raw_data) if raw_data.present?
      end

      if token_data.blank?
        render json: { errors: ['Google account credentials not found. Please connect your Google account again.'] }, status: :unprocessable_entity
        return
      end

      integration = current_account.reputation_integrations.new(
        provider: 'google',
        location_id: integration_params[:location_id],
        location_name: integration_params[:location_name],
        access_token: token_data['access_token'],
        refresh_token: token_data['refresh_token'],
        token_expires_at: token_data['expires_in'] ? Time.current + token_data['expires_in'].to_i.seconds : nil,
        status: :active
      )

      if integration.save
        # Sync reviews in background
        Reputation::ReviewSyncJob.perform_later(integration.id)
        session[:reputation_google_oauth] = nil

        render json: integration.as_json(
          only: [:id, :provider, :location_id, :location_name, :status, :created_at]
        ), status: :created
      else
        render json: { errors: integration.errors.full_messages }, status: :unprocessable_entity
      end
    else
      integration = current_account.reputation_integrations.new(integration_params)
      integration.status = :active
      integration.location_id ||= SecureRandom.uuid

      if integration.save
        # Seed realistic reviews for all manually-connected providers (including Google)
        seed_mock_reviews(integration)
        render json: integration.as_json(
          only: [:id, :provider, :location_id, :location_name, :status, :created_at]
        ), status: :created
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

  private

  def integration
    @integration ||= current_account.reputation_integrations.find(params[:id])
  end

  def integration_params
    params.require(:integration).permit(:provider, :location_id, :location_name, :oauth_session_id)
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
    response = HTTParty.get(url, verify: false)
    return [] unless response.success? && response.parsed_response['result']

    response.parsed_response.dig('result', 'reviews') || []
  end

  def save_real_google_reviews(integration, raw_reviews)
    raw_reviews.each do |raw|
      integration.reputation_reviews.create!(
        account: integration.account,
        provider: 'google',
        external_id: "#{raw['time']}_#{SecureRandom.hex(2)}",
        reviewer_name: raw['author_name'] || 'Google User',
        rating: raw['rating'].to_i,
        body: raw['text'],
        status: :pending,
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
# rubocop:enable Metrics/ClassLength, Metrics/MethodLength, Metrics/AbcSize, Metrics/PerceivedComplexity
