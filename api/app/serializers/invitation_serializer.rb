# frozen_string_literal: true

class InvitationSerializer < ApplicationSerializer
  attributes :id, :email_address, :role, :expires_at, :created_at

  attribute(:accepted) { _1.accepted? }
  one :invited_by, resource: UserSerializer
end
