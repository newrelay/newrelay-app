# Inherits from ActionController::Base to skip all middleware,
# authentication, and callbacks. Used for health checks
class HealthController < ActionController::Base # rubocop:disable Rails/ApplicationController
  def show
    render json: { status: 'woot' }
  end

  # Liveness stays at GET /health (no deps). This endpoint is for readiness:
  # page when Postgres or Redis cannot be reached.
  def ready
    checks = { database: database_up?, redis: redis_up? }
    ok = checks.values.all?
    render json: { status: ok ? 'ready' : 'degraded', checks: checks },
           status: ok ? :ok : :service_unavailable
  end

  private

  def database_up?
    ActiveRecord::Base.connection.active?
  rescue StandardError
    false
  end

  def redis_up?
    Redis::Alfred.with { |conn| conn.ping } == 'PONG'
  rescue StandardError
    false
  end
end
