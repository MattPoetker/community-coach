# frozen_string_literal: true

class MembershipSerializer < ApplicationSerializer
  attributes :id, :role, :status, :joined_at, :last_seen_at

  one :user, resource: UserSerializer

  attribute(:staff) { _1.staff? }
  attribute(:plan_slug) { _1.plan_slug }
end
