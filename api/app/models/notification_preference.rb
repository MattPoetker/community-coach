# frozen_string_literal: true

class NotificationPreference < ApplicationRecord
  EMAIL_MODES = %w[off instant daily].freeze
  KINDS = %w[reply mention reaction new_post event_reminder lesson_published billing].freeze

  acts_as_tenant :community

  belongs_to :user

  validates :kind, inclusion: { in: KINDS }
  validates :email, inclusion: { in: EMAIL_MODES }

  def self.for(user:, kind:)
    find_by(user: user, kind: kind) ||
      new(user: user, kind: kind, in_app: true, email: "instant", push: false)
  end
end
