# frozen_string_literal: true

# Request-scoped context. `community` is set by CommunityResolver middleware from the host,
# and acts_as_tenant reads it to scope every query.
class Current < ActiveSupport::CurrentAttributes
  attribute :session, :community, :request_id, :user_agent, :ip_address

  def user = session&.user
  def membership
    return nil unless user && community

    @membership ||= user.membership_in(community)
  end

  def reset_membership = @membership = nil
end
