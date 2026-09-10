# frozen_string_literal: true

class UserSerializer < ApplicationSerializer
  attributes :id, :name
  attribute(:initials) { _1.initials }
end
