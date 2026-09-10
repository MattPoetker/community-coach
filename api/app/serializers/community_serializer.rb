# frozen_string_literal: true

class CommunitySerializer < ApplicationSerializer
  attributes :id, :slug, :name, :tagline, :description, :privacy, :currency, :timezone

  attribute(:branding) { _1.branding_with_defaults }
  attribute(:member_count) { _1.memberships.active.count }

  attribute :viewer do |_community|
    membership = params[:membership]
    if membership
      { member: true, role: membership.role, status: membership.status,
        staff: membership.staff?, plan_slug: membership.plan_slug }
    else
      { member: false }
    end
  end
end
