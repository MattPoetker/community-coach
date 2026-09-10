# frozen_string_literal: true

ActsAsTenant.configure do |config|
  # Raise rather than silently return every community's rows when no tenant is set. A
  # missing tenant is a bug, and the version of that bug which returns other communities'
  # data is the one nobody notices.
  #
  # Lifted in the test environment because specs build fixtures across several communities
  # before any request runs. spec/models/tenancy_spec.rb re-enables it explicitly to prove
  # the production behaviour is still there.
  config.require_tenant = -> { !Rails.env.test? }
end
