# frozen_string_literal: true

class JoinRequestSerializer < ApplicationSerializer
  attributes :id, :answers, :state, :created_at, :reviewed_at

  one :user, resource: UserSerializer
end
