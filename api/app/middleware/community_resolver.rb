# frozen_string_literal: true

# Resolves the tenant from the request host before anything else runs:
#   {slug}.example.com  → Community#slug
#   a verified custom domain → its community
#   ?community= or X-Community-Slug in development, so the frontend dev server works
#
# Setting Current.community here rather than in a controller filter means acts_as_tenant is
# already scoping by the time any query runs, including in middleware further down.
class CommunityResolver
  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)
    community = resolve(request)

    if community
      Current.community = community
      ActsAsTenant.current_tenant = community
    end

    @app.call(env)
  ensure
    ActsAsTenant.current_tenant = nil
    Current.reset
  end

  private

  def resolve(request)
    by_header(request) || by_custom_domain(request.host) || by_subdomain(request.host)
  end

  def by_header(request)
    return nil unless Rails.env.local?

    slug = request.get_header("HTTP_X_COMMUNITY_SLUG").presence || request.params["community"]
    slug && Community.find_by(slug: slug)
  end

  def by_custom_domain(host)
    CustomDomain.verified.find_by(hostname: host)&.community
  end

  def by_subdomain(host)
    parts = host.to_s.split(".")
    return nil if parts.size < 3

    slug = parts.first
    return nil if %w[www api app].include?(slug)

    Community.find_by(slug: slug)
  end
end
