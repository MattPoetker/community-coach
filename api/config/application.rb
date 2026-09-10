require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require_relative "../app/middleware/community_resolver"

module CommunityCoach
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    config.autoload_paths << Rails.root.join("app/middleware")
    config.eager_load_paths << Rails.root.join("app/middleware")

    # API-only mode drops the cookie middleware. Session auth is cookie-based here — same
    # origin behind Caddy, no JWT — so it has to be put back explicitly.
    config.middleware.use ActionDispatch::Cookies

    # Resolves the tenant from the request host before anything queries the database.
    config.middleware.use CommunityResolver
    config.middleware.use Rack::Attack

    config.active_job.queue_adapter = :solid_queue

    # SQL rather than Ruby schema format: this schema uses generated tsvector columns,
    # ltree, GIN indexes and check constraints, and schema.rb cannot express all of them
    # faithfully. structure.sql is the honest representation.
    config.active_record.schema_format = :sql

    config.generators do |g|
      g.test_framework :rspec
      g.orm :active_record, primary_key_type: :bigint
    end
  end
end
