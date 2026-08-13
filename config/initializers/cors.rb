# config/initializers/cors.rb
# ref: https://github.com/cyu/rack-cors

# font cors issue with CDN
# Ref: https://stackoverflow.com/questions/56960709/rails-font-cors-policy
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'
    resource '/packs/*', headers: :any, methods: [:get, :options]
    resource '/audio/*', headers: :any, methods: [:get, :options]
    # Make the public endpoints accessible to the frontend
    resource '/public/api/*', headers: :any, methods: :any
  end

  allow do
    origins do |source, _env|
      # Allow all origins in development / API mode, or match FRONTEND_URL
      frontend_url = ENV.fetch('FRONTEND_URL', '')
      allowed_origins = [frontend_url, 'http://localhost:3000', 'http://localhost:3036', 'http://localhost:5173', 'http://127.0.0.1:3000', 'http://127.0.0.1:3036'].compact_blank

      Rails.env.development? ||
        ActiveModel::Type::Boolean.new.cast(ENV.fetch('CW_API_ONLY_SERVER', false)) ||
        ActiveModel::Type::Boolean.new.cast(ENV.fetch('ENABLE_API_CORS', false)) ||
        allowed_origins.include?(source) ||
        source == frontend_url
    end

    resource '*',
             headers: :any,
             methods: %i[get post put patch delete options head],
             expose: %w[access-token client uid expiry Content-Disposition],
             credentials: true
  end
end

################################################
######### Action Cable Related Config ##########
################################################

# To Enable connecting to the API channel public APIs
# ref : https://medium.com/@emikaijuin/connecting-to-action-cable-without-rails-d39a8aaa52d5
Rails.application.config.action_cable.disable_request_forgery_protection = true
