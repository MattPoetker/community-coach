# frozen_string_literal: true

require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"

# The local video provider signs URLs through the S3 client. Tests never reach a real
# bucket, but the client is constructed eagerly, so give it something to construct with.
ENV["S3_ACCESS_KEY_ID"] ||= "test"
ENV["S3_SECRET_ACCESS_KEY"] ||= "test"
ENV["S3_BUCKET"] ||= "test-bucket"
ENV["S3_ENDPOINT"] ||= "http://localhost:9000"

Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.fixture_paths = [Rails.root.join("spec/fixtures")]
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.include FactoryBot::Syntax::Methods
  config.include RequestHelpers, type: :request

  # Tenancy is request-scoped in production; tests must not leak it between examples.
  config.after { ActsAsTenant.current_tenant = nil }

end

Shoulda::Matchers.configure do |config|
  config.integrate { |with| with.test_framework :rspec; with.library :rails }
end
