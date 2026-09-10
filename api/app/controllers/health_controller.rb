# frozen_string_literal: true

# Readiness, as distinct from liveness. /up says the process is running; this says it can
# actually serve traffic, which is what a load balancer needs before sending any.
class HealthController < ApplicationController
  skip_before_action :authenticate!
  skip_before_action :require_community!
  skip_after_action :verify_authorized

  def ready
    checks = { database: database_ok?, migrations: migrations_current? }
    status = checks.values.all? ? :ok : :service_unavailable
    render json: { status: status == :ok ? "ready" : "degraded", checks: checks }, status: status
  end

  private

  def database_ok?
    ActiveRecord::Base.connection.select_value("SELECT 1") == 1
  rescue StandardError
    false
  end

  def migrations_current?
    !ActiveRecord::Migration.check_all_pending!
  rescue ActiveRecord::PendingMigrationError
    false
  rescue StandardError
    true
  end
end
