if ENV['SENTRY_DSN'].present?
  Sentry.init do |config|
    config.dsn = ENV['SENTRY_DSN']
    config.environment = Rails.env
    config.release = ENV.fetch('SENTRY_RELEASE') { defined?(GIT_HASH) ? GIT_HASH : 'unknown' }
    config.enabled_environments = %w[staging production]

    # To activate performance monitoring, set one of these options.
    # We recommend adjusting the value in production:
    config.traces_sample_rate = 0.1 if ENV['ENABLE_SENTRY_TRANSACTIONS']

    config.excluded_exceptions += ['Rack::Timeout::RequestTimeoutException', 'MutexApplicationJob::LockAcquisitionError']

    # to track post data in sentry
    config.send_default_pii = true unless ENV['DISABLE_SENTRY_PII']
  end
elsif Rails.env.production?
  Rails.logger.warn('[observability] SENTRY_DSN is not set; exceptions will not be reported to Sentry')
end
