# frozen_string_literal: true

class NotificationSerializer < ApplicationSerializer
  attributes :id, :kind, :data, :group_count, :created_at

  attribute(:read) { _1.read? }
  attribute(:subject_type) { _1.subject_type }
  attribute(:subject_id) { _1.subject_id }

  one :actor, resource: UserSerializer
end
